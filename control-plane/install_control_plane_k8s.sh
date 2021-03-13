#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane k8s - installation"


# set default variables
SSH_USER="stanwar"
SSH_CERT="/home/stanwar/.ssh/id_rsa"


echo "Stop and disable installed services"
# stop and disable etcd services if running
#sudo systemctl stop etcd kube-apiserver kube-scheduler kube-controller-manager
#sudo systemctl disable etcd kube-apiserver kube-scheduler kube-controller-manager

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

# Generate conro
sudo bash generate_control_plane_configs.sh


echo "--------------------------------"
echo "Downlaod binaries "
echo "--------------------------------"

#echo "Download and extract etcd binaries - etcd v3.4.10"
#mkdir -p binaries

# wget -q --show-progress --https-only --timestamping -P binaries \
#   "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

# sudo tar -C binaries -xvf binaries/etcd-v3.4.10-linux-amd64.tar.gz

echo "--------------------------------"
echo "Install ETCD service remotely on all master nodes"
echo "--------------------------------"

mapfile -t NODE_HOSTNAMES < control-plane-nodes.txt

for i in "${NODE_HOSTNAMES[@]}"
do
   
    
    NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

    echo "Installation running on Node : ${NODE_NAME}"
    echo "________________________________________________________"
    
    echo "sync the k8s_bare_metal folder to the node"
    sudo rsync -avz  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../../k8s-bare-metal $SSH_USER@$NODE_NAME:/home/$SSH_USER

    echo "executing remote shell commands"
    
    ssh -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$NODE_NAME /bin/bash << EOF 
    
   

    # echo "download the
    # sudo mkdir -p /home/$SSH_USER/k8s_bare_metal
    # sudo chmod -R 777 /home/$SSH_USER/k8s_bare_metal; 
    # sudo mkdir -p /home/$SSH_USER/k8s_bare_metal


    # Disale existing services
     echo "stop and disable etcd service";
     sudo systemctl stop etcd 
     sudo systemctl disable etcd 
    
    # Create directories for etcd
      echo "Creating etcd directories"
      sudo mkdir -p /etc/etcd /var/lib/etcd;
      sudo chmod 700 /etc/etcd; 
      sudo chmod 700 /var/lib/etcd; 

    # copy etcd,etcdctl to /usr/local/bin
      sudo cp /home/$SSH_USER/k8s-bare-metal/control-plane/binaries/etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin 

    
EOF


done
