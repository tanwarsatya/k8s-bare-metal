#!/bin/sh
# ******************************************************************************************************

FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

 echo "^^^^^^^^^^^^^^^^^^^^Generate config files for worker-plane^^^^^^^^^^^^^^^^^^^^^^^"

# create output directory
mkdir -p worker-plane/output

LOAD_BALANCER_IP=( $(host $CLUSTER_API_LOAD_BALANCER | head -1 | grep -o '[^ ]\+$') )
echo "Load Balancer - $CLUSTER_API_LOAD_BALANCER ip is $LOAD_BALANCER_IP"
# ________________________________________________________________________________________________________
echo "1. Generating kube-proxy.kubeconfig and kube-proxy-config.yaml"
# generate kube-proxy.kubeconfig 
# ----------------------------------------



{
  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://${LOAD_BALANCER_IP}:6443 \
    --kubeconfig=worker-plane/output/kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=worker-plane/output/kube-proxy.pem \
    --client-key=worker-plane/output/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=worker-plane/output/kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:kube-proxy \
    --kubeconfig=worker-plane/output/kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=worker-plane/output/kube-proxy.kubeconfig
}

# generate kube-proxy-config.yaml 
# ----------------------------------------
cat > worker-plane/output/kube-proxy-config.yaml <<EOF 
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "${CLUSTER_CIDR}"
EOF

# _____________________________________________________________________________________________________________


# _____________________________________________________________________________________________________________
if [ "$CLUSTER_TLS_BOOTSTRAPING" = true ] ; then
echo "TLS bootstrapping is set to true for worker"
echo "2. Generating bootstrap-kubeconfig"
#---------------------------------------------------------------------



cat > worker-plane/output/bootstrap-kubeconfig <<EOF 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.crt
    server: https://$LOAD_BALANCER_IP:6443
  name: bootstrap
contexts:
- context:
    cluster: bootstrap
    user: kubelet-bootstrap
  name: bootstrap
current-context: bootstrap
kind: Config
preferences: {}
users:
- name: kubelet-bootstrap
  user:
    token: $CERT_AUTH_BOOTSTRAP_TOKEN_ID.$CERT_AUTH_BOOTSTRAP_TOKEN_SECRET
EOF
#-------------------------------------------------------------------------------
echo "3. Generating bootstrap-token-${CERT_AUTH_BOOTSTRAP_TOKEN_ID}.yaml"

cat > worker-plane/output/bootstrap-token-${CERT_AUTH_BOOTSTRAP_TOKEN_ID}.yaml <<EOF 
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-$CERT_AUTH_BOOTSTRAP_TOKEN_ID
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "The default bootstrap token generated by 'kubeadm init'."

  # Token ID and secret. Required.
  token-id: $CERT_AUTH_BOOTSTRAP_TOKEN_ID
  token-secret: $CERT_AUTH_BOOTSTRAP_TOKEN_SECRET
 
  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"

  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker
EOF

fi
# ______________________________________________________________________________________________________________

# ______________________________________________________________________________________________________________
echo "3. Generating kubelet-config.yaml"

cat > worker-plane/output/kubelet-config.yaml <<EOF 
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF
# ________________________________________________________________________________________________________________


# ________________________________________________________________________________________________________________

if [ "$CLUSTER_TLS_BOOTSTRAPING" = false ] ; then
echo "TLS bootstrapping is set to false for worker"
echo "4. Generating kubelet.kubeconfig for nodes"

# generate csr json files for worker nodes
for i in "${WORKER_PLANE_NODES[@]}"
do
echo "generating csr json file for $i node"  
  # NODE_IPS+=( "$(host $i | grep -oP "192.168.*.*")" )
  # echo "Node: $i : $(host $i | grep -oP "192.168.*.*")"
{
 kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://${LOAD_BALANCER_IP}:6443 \
    --kubeconfig=worker-plane/output/${i}.kubeconfig

  kubectl config set-credentials system:node:${i} \
    --client-certificate=worker-plane/output/${i}.pem \
    --client-key=worker-plane/output/${i}-key.pem \
    --embed-certs=true \
    --kubeconfig=worker-plane/output/${i}.kubeconfig

  kubectl config set-context default \
    --cluster=${CLUSTER_NAME} \
    --user=system:node:${i} \
    --kubeconfig=worker-plane/output/${i}.kubeconfig

  kubectl config use-context default --kubeconfig=worker-plane/output/${i}.kubeconfig
}

done

fi



# ****************************************************************************************************************