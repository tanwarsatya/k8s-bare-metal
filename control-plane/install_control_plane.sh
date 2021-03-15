#!/bin/sh

echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane k8s - installation"

# import vairables
source variables.sh


#generate root cert if not available 
CA_PEM_FILE=../cert-authority/certs/ca.pem
CA_KEY_FILE=../cert-authority/certs/ca-key.pem

if [ -f "$CA_PEM_FILE" ] && [ -f "$CA_KEY_FILE" ]; then 
echo " Root CA File exists : ca.pem and ca-key.pem exists, using existing root ca files."
else
echo " No Root CA file found generating new ca files."
sudo mkdir -p ../cert-authority/certs
cfssl gencert -initca ../cert-authority/config/ca-csr.json | cfssljson -bare ../cert-authority/certs/ca
fi

# Generate control plane certs
sudo bash generate_control_plane_certs.sh

# Generate config files
sudo bash generate_control_plane_configs.sh

# generate service files
sudo bash generate_control_plane_services.sh


# Install Etcd
sudo bash install_etcd.sh

# Install HaProxy
sudo bash install_haproxy.sh