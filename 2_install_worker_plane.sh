#!/bin/sh
source variables.sh

echo "k8s-bare-metal"
echo "worker plane installation"
rm -rf worker-plane/output
mkdir -p worker-plane/output


# Generate control plane certs
bash worker-plane/generate_worker_plane_certs.sh

# Generate config files
bash worker-plane/generate_worker_plane_configs.sh

# generate service files
bash worker-plane/generate_worker_plane_services.sh


# Install K8s worker plane components
bash worker-plane/install_k8s.sh


