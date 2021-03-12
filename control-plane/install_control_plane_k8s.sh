#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane k8s - installation"


# set default variables
SSH_USER="stanwar"
SSH_CERT=""


echo "--------------------------------"
echo "0. disable control plane services  "
echo "--------------------------------"

echo "Stop and disable etcd..."
# stop and disable etcd services if running
sudo systemctl stop etcd
sudo systemctl disable etcd

echo "Stop and disable kube-apiserver..."
# stop and disable etcd services if running
sudo systemctl stop kube-apiserver
sudo systemctl disable kube-apiserver

echo "Stop and disable kube-scheduler..."
# stop and disable etcd services if running
sudo systemctl stop kube-scheduler
sudo systemctl disable kube-scheduler

echo "Stop and disable kube-controller-manager..."
# stop and disable etcd services if running
sudo systemctl stop kube-controller-manager
sudo systemctl disable kube-controller-manager

echo "--------------------------------"
echo "1. Generate root cert "
echo "--------------------------------"
CA_PEM_FILE=../cert-authority/certs/ca.pem
CA_KEY_FILE=../cert-authority/certs/ca-key.pem

if [ -f "$CA_PEM_FILE" ] && [ -f "$CA_KEY_FILE" ]; then 
echo " Root CA File exists : ca.pem and ca-key.pem exists, using existing root ca files."
else
echo " No Root CA file found generating new ca files."
sudo mkdir -p ../cert-authority/certs
cfssl gencert -initca ../cert-authority/config/ca-csr.json | cfssljson -bare ../cert-authority/certs/ca
fi

echo "--------------------------------"
echo "2. Downlaod ETCD binaries "
echo "--------------------------------"

# echo "Download and extract etcd binaries - etcd v3.4.10"
# mkdir -p binaries

# wget -q --show-progress --https-only --timestamping -P binaries \
#   "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

# sudo tar -C binaries -xvf binaries/etcd-v3.4.10-linux-amd64.tar.gz

echo "--------------------------------"
echo "2. Install ETCD service remotely on all master nodes"
echo "--------------------------------"

mapfile -t NODE_HOSTNAMES < control-plane-nodes.txt

for i in "${NODE_HOSTNAMES[@]}"
do
   
    
    NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

    echo "Installation running on Node : ${NODE_NAME}"

    echo "Creating etcd directories"
    ssh -i /home/stanwar/.ssh/id_rsa -o StrictHostKeyChecking=no $SSH_USER@${NODE_NAME} 'sudo mkdir -p /etc/etcd /var/lib/etcd' 
    
    #sudo mkdir -p /etc/etcd /var/lib/etcd;
    #sudo chmod 700 /var/lib/etcd

    

    #echo "Copy certs"
   # scp -i ~/.ssh/id_rsa ../cert-authority/certs/ca.pem output/etcd.pem output/etcd-key.pem ${SSH_USER}@${NODE_NAME}:/etc/etcd

    #echo "Copy etcd binaries"
   # scp -i ~/.ssh/id_rsa binaries/etcd-v3.4.10-linux-amd64/etcd*  ${SSH_USER}@${NODE_NAME}:/usr/local/bin

    #echo "Copy etcd.service file"
   # scp -i ~/.ssh/id_rsa output/etcd.service ${SSH_USER}@${NODE_NAME}:/etc/systemd/system

done
