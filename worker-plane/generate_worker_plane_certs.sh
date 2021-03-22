#!/bin/sh
# ******************************************************************************************************
echo "worker plane - generate cert files"


FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

mkdir -p worker-plane/output
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
if [ "$CLUSTER_TLS_BOOTSTRAPING" = false ] ; then
echo "TLS bootstrapping is set to false for worker"
echo "1. Generating kubelet cert"

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

# generate cert files for worker nodes
for i in "${WORKER_PLANE_NODES[@]}"
do
echo "generating cert and key file for $i node"  
  NODE_IP=( "$(host $i | grep -oP "192.168.*.*")" )
  
cfssl gencert \
  -ca=cert-authority/certs/ca.pem \
  -ca-key=cert-authority/certs/ca-key.pem \
  -config=cert-authority/config/ca-config.json \
  -hostname=${i},${NODE_IP} \
  -profile=default \
  worker-plane/output/${i}-csr.json | cfssljson -bare worker-plane/output/$i

done

# ---- TLS bootstrapping check done
fi

# ________________________________________________________________________________________________________________
# ****************************************************************************************************************
