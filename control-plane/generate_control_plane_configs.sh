#!/bin/sh


# import vairables
source variables.sh


echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate configuration files"
echo "--------------------------------"
echo "1. Generating kube-controller-manager.kubeconfig"
echo "--------------------------------"

# create output directory
sudo mkdir -p output

{
  kubectl config set-cluster k8s-bare-metal \
    --certificate-authority=../cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=output/kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=output/kube-controller-manager.pem \
    --client-key=output/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=output/kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-bare-metal \
    --user=system:kube-controller-manager \
    --kubeconfig=output/kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=output/kube-controller-manager.kubeconfig
}
echo "**********************************"
echo "2. Generating kube-scheduler.kubeconfig and kube-scheduler.yaml"
echo "--------------------------------"
{
  kubectl config set-cluster k8s-bare-metal \
    --certificate-authority=../cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=output/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=output/kube-scheduler.pem \
    --client-key=output/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=output/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-bare-metal \
    --user=system:kube-scheduler \
    --kubeconfig=output/kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=output/kube-scheduler.kubeconfig
}

cat > output/kube-scheduler.yaml <<EOF 
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

echo "**********************************"
echo "3. Generating admin.kubeconfig"
echo "--------------------------------"
{
  kubectl config set-cluster k8s-bare-metal \
    --certificate-authority=../cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=output/admin.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=output/admin.pem \
    --client-key=output/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=output/admin.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-bare-metal \
    --user=admin \
    --kubeconfig=output/admin.kubeconfig

  kubectl config use-context default --kubeconfig=output/admin.kubeconfig
}
echo "**********************************"
echo "4. Generating encryption-config.yaml"
echo "--------------------------------"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > output/encryption-config.yaml <<EOF
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
echo "5. Generating haproxy.config"
echo "--------------------------------"
LOAD_BALANCER_NODE="k8s-master-lb"
LOAD_BALANCER_IP=( $(host ${LOAD_BALANCER_NODE} | grep -oP "192.168.*.*")  )

cat > output/haproxy.cfg <<EOF  
frontend kubernetes
    bind ${LOAD_BALANCER_IP}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-1 192.168.1.19:6443 check fall 3 rise 2
    server k8s-master-2 192.168.1.22:6443 check fall 3 rise 2
    server k8s-master-3 192.168.1.21:6443 check fall 3 rise 2
EOF
echo "**********************************"
