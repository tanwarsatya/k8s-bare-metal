#!/bin/sh
# ******************************************************************************************************
echo "worker plane - generate configuration files"


FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

# create output directory
sudo mkdir -p worker-plane/output


# ________________________________________________________________________________________________________
echo "1. Generating kube-proxy.kubeconfig and kube-proxy-config.yaml"
# generate kube-proxy.kubeconfig 
# ----------------------------------------

LOAD_BALANCER_IP=( $(host ${CONTROL_PLANE_API_LOAD_BALANCER_NODE} | grep -oP "192.168.*.*") )
echo "Load Balancer - $CONTROL_PLANE_API_LOAD_BALANCER_NODE ip is $LOAD_BALANCER_IP"
{
  kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=cert-authority/certs/ca.pem \
    --embed-certs=true \
    --server=https://${LOAD_BALANCER_API}:6443 \
    --kubeconfig=worker-plane/output/kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=worker-plane/output/kube-proxy.pem \
    --client-key=worker-plane/output/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=worker-plane/output/kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
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
echo "2. Generating bootstrap-kubeconfig"

LOAD_BALANCER_IP=( $(host ${CONTROL_PLANE_API_LOAD_BALANCER_NODE} | grep -oP "192.168.*.*") )

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
    clientCAFile: "/var/lib/kubernetes/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF
# ________________________________________________________________________________________________________________
# ****************************************************************************************************************