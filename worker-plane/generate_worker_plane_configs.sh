#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "worker plane - generate configuration files"
echo "--------------------------------"
echo "1. Generating kube-proxy.kubeconfig"
echo "--------------------------------"

# KUBE_MASTER_LB using HA PROXY
KUBE_MASTER_LB = "k8s-master-lb"
KUBE_API_MASTER_LB_IP_ADDRESS = $(host $KUBE_MASTER_LB | grep -oP "192.168.*.*")

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBE_API_MASTER_LB_IP_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
echo "**********************************"
echo "2. Generating kube-scheduler.kubeconfig"
echo "--------------------------------"
{
  kubectl config set-cluster k8s-bare-metal \
    --certificate-authority=../cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=config/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=certs/kube-scheduler.pem \
    --client-key=certs/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=config/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-bare-metal \
    --user=system:kube-scheduler \
    --kubeconfig=config/kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=config/kube-scheduler.kubeconfig
}
echo "**********************************"
echo "3. Generating admin.kubeconfig"
echo "--------------------------------"
{
  kubectl config set-cluster k8s-bare-metal \
    --certificate-authority=../cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=config/admin.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=certs/admin.pem \
    --client-key=certs/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=config/admin.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-bare-metal \
    --user=admin \
    --kubeconfig=config/admin.kubeconfig

  kubectl config use-context default --kubeconfig=config/admin.kubeconfig
}
echo "**********************************"
echo "4. Generating encryption-config.yaml"
echo "--------------------------------"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > config/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
echo "**********************************"
