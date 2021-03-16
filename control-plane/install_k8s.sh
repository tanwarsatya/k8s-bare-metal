#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

echo "--------------------------------"
echo "Install k8sd services remotely on all master nodes"
echo "--------------------------------"


for i in "${CONTROL_PLANE_NODES[@]}"
do
   
    
     NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

    echo "________________________________________________________"
    echo "Installation running on Node : ${NODE_NAME}"
    echo "________________________________________________________"
    
    echo "sync the k8s-bare-metal folder to the node"
    sudo rsync -avz  -e "ssh -o StrictHostKeyChecking=no -i $CONTROL_PLANE_SSH_CERT" ../k8s-bare-metal $CONTROL_PLANE_SSH_USER@$NODE_NAME:/home/$CONTROL_PLANE_SSH_USER

    echo "executing remote shell commands"
    echo "#######################################################################################################"
    ssh -t -i $CONTROL_PLANE_SSH_CERT -o StrictHostKeyChecking=no $CONTROL_PLANE_SSH_USER@$NODE_NAME /bin/bash << EOF 
    
     # Disale existing services
     echo "stop and disable kube-apiserver, kube-controller-manager, kube-scheduler service";
     sudo systemctl stop kube-apiserver kube-controller-manager kube-scheduler 
     sudo systemctl disable kube-apiserver kube-controller-manager kube-scheduler 

     #Create directories for k8s
      echo "Creating k8s directories"
      sudo mkdir -p /etc/kubernetes/config
      sudo mkdir -p /var/lib/kubernetes/
      sudo chmod 700 /etc/kubernetes/config; 
      sudo chmod 700 /var/lib/kubernetes; 
   
     #download k8s binaries
     echo "download k8s - ${CONTROL_PLANE_K8S_VERSION} binaries" 
     wget -q --https-only --timestamping -P /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/binaries \
      "https://storage.googleapis.com/kubernetes-release/release/${CONTROL_PLANE_K8S_VERSION}/bin/linux/amd64/kube-apiserver" \
      "https://storage.googleapis.com/kubernetes-release/release/${CONTROL_PLANE_K8S_VERSION}/bin/linux/amd64/kube-controller-manager" \
      "https://storage.googleapis.com/kubernetes-release/release/${CONTROL_PLANE_K8S_VERSION}/bin/linux/amd64/kube-scheduler" \
      "https://storage.googleapis.com/kubernetes-release/release/${CONTROL_PLANE_K8S_VERSION}/bin/linux/amd64/kubectl"
   
    
      sudo chmod 755 /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/binaries/*

      # copy binaries to /usr/local/bin
      echo "copy kube-apiserver kube-controller-manager and kube-scheduler binaries to /usr/local/bin"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/binaries/kube* /usr/local/bin  
      sudo  chmod 755 /usr/local/bin/* 

    # copy required certs
      echo "copy k8s certs to /var/lib/kubernetes directory"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/cert-authority/certs/ca.pem \
              /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/cert-authority/certs/ca-key.pem \
              /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/*.pem \
              /var/lib/kubernetes 
    # copy required config files
      echo "copy k8s configs to /var/lib/kubernetes directory"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/*.kubeconfig \
              /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/*.yaml \
              /var/lib/kubernetes 
        
      
    # copy k8s service config files to /etc/systemd/system directory
      echo "copy service files to /etc/systemd/system"
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/${NODE_NAME}.kube-apiserver.service /etc/systemd/system/kube-apiserver.service
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/kube-scheduler.service /etc/systemd/system/kube-scheduler.service
      sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/kube-controller-manager.service /etc/systemd/system/kube-controller-manager.service
    
    # start the service
      echo "enable and start the k8s services" 
      sudo systemctl daemon-reload
      sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler 
      sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler 

    #                                                             
     

     # Install the http health checkpoint based on ngnix
       echo "installing nginx based health checkpoint" 
        sudo apt-get update && sudo apt-get install -y nginx
        
       
       
       echo "copy kubernetes.default.svc.cluster.local to /etc/nginx/sites-available"
       sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/config/kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
        
       sudo ln -sfn /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

       sudo systemctl restart nginx
       sudo systemctl enable nginx 


      #Add the cluster role and role binding

      echo "sleep 10 sec before applying rbac role and bindings"
      sudo sleep 10 
      sudo kubectl apply -f /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/config/kube-apiserver-clusterrole.yaml                 
      sudo kubectl apply -f /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/config/kube-apiserver-clusterrole-binding.yaml
       
    
   echo "#######################################################################################################"
EOF


done