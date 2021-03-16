#!/bin/sh
# ******************************************************************************************************
echo "worker plane - generate configuration files"


FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

# create output directory
sudo mkdir -p worker-plane/output

# _____________________________________________________________________________________________________________
echo "1. Generating kube-proxy client cert"

cfssl gencert \
  -ca=cert-authority/certs/ca.pem \
  -ca-key=cert-authority/certs/ca-key.pem \
  -config=cert-authority/config/ca-config.json \
  -profile=default \
  worker-plane/config/kube-proxy-csr.json | cfssljson -bare worker-plane/output/kube-proxy
# ________________________________________________________________________________________________________________

# ________________________________________________________________________________________________________________
if [ "$WORKER_PLANE_TLS_BOOTSTRAPING" = false ] ; then

echo "1. Generating kubelet cert"




#_____________________________________________________
# generate csr json files for worker nodes

for i in "${WORKER_PLANE_NODES[@]}"
do
echo "generating csr json file for $i node"  
  # NODE_IPS+=( "$(host $i | grep -oP "192.168.*.*")" )
  # echo "Node: $i : $(host $i | grep -oP "192.168.*.*")"

cat > worker-plane/output/${i}-csr.json <<EOF
{
  "CN": "system:node:${i}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
       "C": "US",
       "L": "Boston",
       "O": "system:nodes",
       "OU": "K8S BARE METAL",
       "ST": "Massachusetts"
    }
  ]
}
EOF

done
#________________________________________________________


# # convert to a comma seperated IP string
# CONTROL_PLANE_NODE_IPS=$(IFS=,; echo "{${NODE_IPS[*]}}")

# #declare - a NODE_IPS 

# cfssl gencert \
#  -ca=../cert-authority/certs/ca.pem \
#   -ca-key=../cert-authority/certs/ca-key.pem \
#   -config=../cert-authority/config/ca-config.json \
#   -hostname=10.32.0.1,127.0.0.1,${KUBERNETES_HOSTNAMES},${CONTROL_PLANE_NODE_IPS} \
#   -profile=default \
#   config/kube-api-server-csr.json | cfssljson -bare output/kubernetes

fi

# ________________________________________________________________________________________________________________
# ****************************************************************************************************************
