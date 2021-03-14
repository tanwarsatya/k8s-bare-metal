#!/bin/sh


# import vairables
source variables.sh



echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane k8s - installation"




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

for i in "${CONTROL_PLANE_ETCD_NODES[@]}"
do
   
    
    NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

    echo "Installation running on Node : ${NODE_NAME}"
    echo "________________________________________________________"
    
    echo "sync the k8s_bare_metal folder to the node"
    sudo rsync -avz  -e "ssh -o StrictHostKeyChecking=no -i $CONTROL_PLANE_SSH_CERT" ../../k8s-bare-metal $CONTROL_PLANE_SSH_USER@$NODE_NAME:/home/$CONTROL_PLANE_SSH_USER

    echo "executing remote shell commands"
    
    ssh -i $CONTROL_PLANE_SSH_CERT -o StrictHostKeyChecking=no $CONTROL_PLANE_SSH_USER@$NODE_NAME /bin/bash << EOF 
    
   

    # echo "download the
    # sudo mkdir -p /home/$CONTROL_PLANE_SSH_USER/k8s_bare_metal
    # sudo chmod -R 777 /home/$CONTROL_PLANE_SSH_USER/k8s_bare_metal; 
    # sudo mkdir -p /home/$CONTROL_PLANE_SSH_USER/k8s_bare_metal


    # Disale existing services
     echo "stop and disable etcd service";
     sudo systemctl stop etcd 
     sudo systemctl disable etcd 
    
    # Create directories for etcd
      echo "Creating etcd directories"
      sudo mkdir -p /etc/etcd /var/lib/etcd;
      sudo chmod 700 /etc/etcd; 
      sudo chmod 700 /var/lib/etcd; 

    # copy required certs
      echo "copy ca.pem etcd.pem and etcd-key.pem to /etcd/etcd directory"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/cert-authority/certs/ca.pem \
              /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/etcd.pem \
              /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/etcd-key.pem \
              /etc/etcd 

    # copy etcd,etcdctl to /usr/local/bin
      echo "copy etcd binaries to /usr/local/bin"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/binaries/etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin 
    
    # copy etcd.service to /etc/systemd/system directory
      echo "copy $NODE_NAME.etcd.service to /etc/systemd/system"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/${NODE_NAME}.etcd.service /etc/systemd/system/etcd.service

    # start the service
      echo "enable and start the etcd" 
      sudo systemctl daemon-reload
      sudo systemctl enable etcd
      sudo systemctl start etcd
    

EOF


done
