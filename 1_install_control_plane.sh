#!/bin/sh
source variables.sh

echo $CLUSTER_NAME
echo "control plane installation"

# pre steps
# create output directory
rm -rf control-plane/output
mkdir -p control-plane/output

# Generate root certs
bash cert-authority/generate_ca_cert.sh


# Generate control plane certs
bash control-plane/generate_control_plane_certs.sh

#Generate config files
bash control-plane/generate_control_plane_configs.sh

#generate service files
bash control-plane/generate_control_plane_services.sh


#Install Etcd
bash control-plane/install_etcd.sh

#Install HaProxy
bash control-plane/install_haproxy.sh

#Install K8s control plane components
bash control-plane/install_k8s.sh