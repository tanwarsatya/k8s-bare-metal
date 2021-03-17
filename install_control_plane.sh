#!/bin/sh
source variables.sh

echo "k8s-bare-metal"
echo "control plane installation"

#generate root cert if not available 
CA_PEM_FILE=cert-authority/certs/ca.pem
CA_KEY_FILE=cert-authority/certs/ca-key.pem

if [ -f "$CA_PEM_FILE" ] && [ -f "$CA_KEY_FILE" ]; then 
echo " Root CA File exists : ca.pem and ca-key.pem exists, using existing root ca files."
else
echo " No Root CA file found generating new ca files."
sudo mkdir -p cert-authority/certs
cfssl gencert -initca cert-authority/config/ca-csr.json | cfssljson -bare cert-authority/certs/ca
fi

# Generate control plane certs
#sudo bash control-plane/generate_control_plane_certs.sh

# Generate config files
#sudo bash control-plane/generate_control_plane_configs.sh

# generate service files
#sudo bash control-plane/generate_control_plane_services.sh


# Install Etcd
sudo bash control-plane/install_etcd.sh

# Install HaProxy
sudo bash control-plane/install_haproxy.sh

# Install K8s control plane components
sudo bash control-plane/install_k8s.sh


