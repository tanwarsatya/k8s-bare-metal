#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE



 echo "^^^^^^^^^^^^^^^^^^^^Install ETCD service remotely on all etcd nodes^^^^^^^^^^^^^^^^^^^^^^^"


for i in "${CONTROL_PLANE_ETCD_NODES[@]}"
do
   
    
    NODE_NAME=( $i )
    NODE_IP=( $(host $i  | head -1 | grep -o '[^ ]\+$')  )

    echo "________________________________________________________"
    echo "Installation running on Node : ${NODE_NAME}"
    echo "________________________________________________________"


    echo "sync the k8s_bare_metal folder to the node"
      rsync -avzq  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal/cert-authority $SSH_USER@$NODE_NAME:/home/$SSH_USER/k8s-bare-metal
    rsync -avzq  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal/control-plane $SSH_USER@$NODE_NAME:/home/$SSH_USER/k8s-bare-metal

    echo "executing remote shell commands"
    echo "#######################################################################################################"
    ssh-keygen -q -f "/home/$USER/.ssh/known_hosts" -R $NODE_NAME
    ssh -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$NODE_NAME /bin/bash << EOF 
      
    # download etcd binaries
     echo "download etcd - ${CONTROL_PLANE_ETCD_VERSION} binaies" 
     wget -q --https-only --timestamping -P /home/$SSH_USER/k8s-bare-metal/control-plane/binaries \
       "https://github.com/etcd-io/etcd/releases/download/${CONTROL_PLANE_ETCD_VERSION}/etcd-${CONTROL_PLANE_ETCD_VERSION}-linux-amd64.tar.gz"

     echo "expand etcd files "
     sudo tar  -xf /home/$SSH_USER/k8s-bare-metal/control-plane/binaries/etcd-${CONTROL_PLANE_ETCD_VERSION}-linux-amd64.tar.gz \
                -C /home/$SSH_USER/k8s-bare-metal/control-plane/binaries

    # Disale existing services
     echo "stop and disable etcd service";
     sudo systemctl stop etcd 
     sudo systemctl disable etcd 

    # Clean all data
      sudo rm -rf /var/lib/etcd 
    
    # Create directories for etcd
      echo "Creating etcd directories"
      sudo mkdir -p /etc/etcd /var/lib/etcd;
      sudo chmod 700 /etc/etcd; 
      sudo chmod 700 /var/lib/etcd; 

    # copy required certs
      echo "copy ca.pem etcd.pem and etcd-key.pem to /etcd/etcd directory"
      sudo cp /home/$SSH_USER/k8s-bare-metal/cert-authority/certs/ca.pem \
              /home/$SSH_USER/k8s-bare-metal/control-plane/output/etcd.pem \
              /home/$SSH_USER/k8s-bare-metal/control-plane/output/etcd-key.pem \
              /etc/etcd 

    # copy etcd,etcdctl to /usr/local/bin
      echo "copy etcd binaries to /usr/local/bin"
      sudo cp /home/$SSH_USER/k8s-bare-metal/control-plane/binaries/etcd-${CONTROL_PLANE_ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin 
    
    # copy etcd.service to /etc/systemd/system directory
      echo "copy $NODE_NAME.etcd.service to /etc/systemd/system"
      sudo cp /home/$SSH_USER/k8s-bare-metal/control-plane/output/${NODE_NAME}.etcd.service /etc/systemd/system/etcd.service

    # start the service
      echo "enable and start the etcd" 
      sudo systemctl daemon-reload
      sudo systemctl enable etcd
      sudo systemctl start etcd
    
   echo "#######################################################################################################"
EOF


done