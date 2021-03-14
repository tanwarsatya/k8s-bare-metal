#!/bin/sh

# import vairables
source variables.sh


echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate certs"
echo "--------------------------------"
echo "1. Generating admin client cert"


# pre steps
# create output directory
sudo mkdir -p output

# get public ip address for control plane nodes
# Get nodes list from the file
mapfile -t NODE_HOSTNAMES < control-plane-nodes.txt
#declare a node-ips array






cfssl gencert \
  -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -profile=default \
   config/admin-csr.json | cfssljson -bare output/admin


echo "2. Generating kube-controller-manager cert"

cfssl gencert \
  -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -profile=default \
  config/kube-controller-manager-csr.json | cfssljson -bare output/kube-controller-manager


echo "3. Generating kube-scheduler cert "

cfssl gencert \
  -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -profile=default \
  config/kube-scheduler-csr.json | cfssljson -bare output/kube-scheduler




echo "4. Generating kube-apiserver cert"

# Get the ip address of nodes 
declare -a CONTROL_PLANE_NODE_IPS=()
for i in "${CONTROL_PLANE_NODES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes

  CONTROL_PLANE_NODE_IPS+=( "$(host $i | grep -oP "192.168.*.*")" )
 
done
# convert to a comma seperated IP string
CONTROL_PLANE_NODE_IPS_STRING=$(IFS=,; echo "${CONTROL_PLANE_NODE_IPS[*]}")
# Set host names to be used
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cfssl gencert \
 -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -hostname=10.32.0.1,127.0.0.1,${KUBERNETES_HOSTNAMES},${CONTROL_PLANE_NODE_IPS_STRING} \
  -profile=default \
  config/kube-apiserver-csr.json | cfssljson -bare output/kub-apiserver




echo "4. Generating etcd cert"

# Get the ip address of nodes 
declare -a ETCD_NODE_IPS=()
for i in "${CONTROL_PLANE_NODES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes

  ETCD_NODE_IPS+=( "$(host $i | grep -oP "192.168.*.*")" )
 
done
# convert to a comma seperated IP string
ETCD_NODE_IPS_STRING=$(IFS=,; echo "${ETCD_NODE_IPS[*]}")

# Set host names to be used
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cfssl gencert \
 -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -hostname=10.32.0.1,127.0.0.1,${KUBERNETES_HOSTNAMES},${ETCD_NODE_IPS_STRING} \
  -profile=default \
  config/etcd-csr.json | cfssljson -bare output/etcd




echo "5. Generating service-account cert -----------------------------"

cfssl gencert \
  -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -profile=default \
  config/service-account-csr.json | cfssljson -bare output/service-account
