#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

# create control-plane/output directory
sudo mkdir -p control-plane/output

echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate configuration files"
echo "--------------------------------"

echo "0. Generating bootstratper-token-${BOOTSTRAP_TOKEN_ID}.yaml for TLS Bootstrapping"

cat > control-plane/output/bootstrap-token-${BOOTSTRAP_TOKEN_ID}.yaml <<EOF 
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-$BOOTSTRAP_TOKEN_ID
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "The default bootstrap token generated by 'kubeadm init'."

  # Token ID and secret. Required.
  token-id: $BOOTSTRAP_TOKEN_ID
  token-secret: $BOOTSTRAP_TOKEN_SECRET

  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"

  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker,system:bootstrappers:ingress
EOF


echo "1. Generating kube-controller-manager.kubeconfig"
echo "--------------------------------"



{
  kubectl config set-cluster  ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=control-plane/output/kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=control-plane/output/kube-controller-manager.pem \
    --client-key=control-plane/output/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=control-plane/output/kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:kube-controller-manager \
    --kubeconfig=control-plane/output/kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=control-plane/output/kube-controller-manager.kubeconfig
}
echo "**********************************"
echo "2. Generating kube-scheduler.kubeconfig and kube-scheduler.yaml"
echo "--------------------------------"
{
  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=control-plane/output/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=control-plane/output/kube-scheduler.pem \
    --client-key=control-plane/output/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=control-plane/output/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:kube-scheduler \
    --kubeconfig=control-plane/output/kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=control-plane/output/kube-scheduler.kubeconfig
}

cat > control-plane/output/kube-scheduler.yaml <<EOF 
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
  kubectl config set-cluster  ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=control-plane/output/admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=control-plane/output/admin.pem \
    --client-key=control-plane/output/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=control-plane/output/admin.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=admin \
    --kubeconfig=control-plane/output/admin.kubeconfig

  kubectl config use-context default --kubeconfig=control-plane/output/admin.kubeconfig
}

echo "**********************************"
echo "4. Generating haproxy.config"
echo "--------------------------------"

LOAD_BALANCER_IP=( $(host ${CLUSTER_API_LOAD_BALANCER} | grep -oP "192.168.*.*")  )

# Loop to create a api server cluster strings 
for i in "${CONTROL_PLANE_NODES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes
   API_SERVER_STRING+="\tserver $i $(host $i | grep -oP "192.168.*.*") check fall 3 rise 2\n"
done

PROXY_CONFIG=$(cat << EOF  
frontend kubernetes
    bind ${LOAD_BALANCER_IP}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    ${API_SERVER_STRING:2}
EOF
)
printf "${PROXY_CONFIG}" > control-plane/output/haproxy.cfg
echo "**********************************"

echo "**********************************"
echo "3. Generating remote.kubeconfig"
echo "--------------------------------"
{
  kubectl config set-cluster  ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://${LOAD_BALANCER_IP}:6443 \
    --kubeconfig=control-plane/output/${CLUSTER_NAME}.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=control-plane/output/admin.pem \
    --client-key=control-plane/output/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=control-plane/output/${CLUSTER_NAME}.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=admin \
    --kubeconfig=control-plane/output/${CLUSTER_NAME}.kubeconfig

  kubectl config use-context default --kubeconfig=control-plane/output/${CLUSTER_NAME}.kubeconfig
}

