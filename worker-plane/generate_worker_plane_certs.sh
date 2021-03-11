#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate certs"
echo "--------------------------------"
echo "1. Generating kube-proxy client cert"
echo "--------------------------------"
cfssl gencert \
  -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -profile=default \
  config/kube-proxy-csr.json | cfssljson -bare certs/kube-proxy


echo "**********************************"
echo "2. Generating kubelet certs"
echo "--------------------------------"

# Set host names to be used
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

# get public ip address for control plane nodes
# Get nodes list from the file
mapfile -t NODE_HOSTNAMES < control-plane-nodes.txt
#declare a node-ips array
declare -a NODE_IPS=()

# Get the ip address of nodes 
for i in "${NODE_HOSTNAMES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes

  NODE_IPS+=( "$(host $i | grep -oP "192.168.*.*")" )
  echo "Node: $i : $(host $i | grep -oP "192.168.*.*")"
done

# convert to a comma seperated IP string
CONTROL_PLANE_NODE_IPS=$(IFS=,; echo "{${NODE_IPS[*]}}")

#declare - a NODE_IPS 

cfssl gencert \
 -ca=../cert-authority/certs/ca.pem \
  -ca-key=../cert-authority/certs/ca-key.pem \
  -config=../cert-authority/config/ca-config.json \
  -hostname=10.32.0.1,127.0.0.1,${KUBERNETES_HOSTNAMES},${CONTROL_PLANE_NODE_IPS} \
  -profile=default \
  config/kube-api-server-csr.json | cfssljson -bare certs/kubernetes
echo "**********************************"
