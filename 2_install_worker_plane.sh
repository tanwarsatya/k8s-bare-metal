#!/bin/sh
source variables.sh

echo "k8s-bare-metal"
echo "worker plane installation"
rm -rf worker-plane/output
mkdir -p worker-plane/output

#generate root cert if not available 
CA_PEM_FILE=cert-authority/certs/ca.pem
CA_KEY_FILE=cert-authority/certs/ca-key.pem

if [ -f "$CA_PEM_FILE" ] && [ -f "$CA_KEY_FILE" ]; then 
echo " Root CA File exists : ca.pem and ca-key.pem exists, using existing root ca files."
else
echo " No Root CA file found generating new ca files."
mkdir -p cert-authority/certs
cfssl gencert -initca cert-authority/config/ca-csr.json | cfssljson -bare cert-authority/certs/ca
fi

# Generate control plane certs
bash worker-plane/generate_worker_plane_certs.sh

# Generate config files
bash worker-plane/generate_worker_plane_configs.sh

# generate service files
bash worker-plane/generate_worker_plane_services.sh


# Install K8s worker plane components
bash worker-plane/install_k8s.sh


