#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

echo "--------------------------------"
echo "Install k8s services remotely on all worker nodes"
echo "--------------------------------"


for i in "${WORKER_PLANE_NODES[@]}"
do
   
    
    NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

    echo "________________________________________________________"
    echo "Installation running on Node : ${NODE_NAME}"
    echo "________________________________________________________"
    
    echo "sync the k8s-bare-metal folder to the node"
    sudo rsync -avz  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal $SSH_USER@$NODE_NAME:/home/$SSH_USER

    echo "executing remote shell commands"
    echo "#######################################################################################################"
    ssh -t -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$NODE_NAME /bin/bash << EOF 
    
    # Disable swap off
    echo "disabling swapoff -a"
    sudo swapoff -a

    # Install socat conntrack and ipset
    echo "installing socat conntrack and ipset"
    sudo apt-get update
    sudo apt-get -y install socat conntrack ipset

    # Disale existing services
     echo "stop and disable containerd kubelet and kube-proxy services if running";
     sudo systemctl stop kubelet kube-proxy containerd 
     sudo systemctl disable kubelet kube-proxy containerd

     #Create directories for k8s
      echo "Creating k8s directories"
      sudo mkdir -p /etc/cni/net.d \
                    /etc/containerd \
                    /opt/cni/bin \
                    /var/lib/kubelet \
                    /var/lib/kube-proxy \
                    /var/lib/kubernetes \
                    /var/run/kubernetes
                
   
     #download k8s binaries
     #_________________________________________________________________________________
     echo "download k8s - ${CLUSTER_VERSION} binaries" 
     wget -q --show-progress --timestamping -P /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries \
     https://github.com/kubernetes-sigs/cri-tools/releases/download/${WORKER_PLANE_CRI_TOOLS_VERSION}/crictl-${WORKER_PLANE_CRI_TOOLS_VERSION}-linux-amd64.tar.gz \
     https://github.com/opencontainers/runc/releases/download/${WORKER_PLANE_RUNC_VERSION}/runc.amd64 \
     https://github.com/containernetworking/plugins/releases/download/${WORKER_PLANE_CNI_PLUGIN_VERSION}/cni-plugins-linux-amd64-${WORKER_PLANE_CNI_PLUGIN_VERSION}.tgz \
     https://github.com/containerd/containerd/releases/download/${WORKER_PLANE_CONTAINERD_VERSION}/containerd-${WORKER_PLANE_CONTAINERD_VERSION:1}-linux-amd64.tar.gz \
     https://storage.googleapis.com/kubernetes-release/release/${CLUSTER_VERSION}/bin/linux/amd64/kubectl \
     https://storage.googleapis.com/kubernetes-release/release/${CLUSTER_VERSION}/bin/linux/amd64/kube-proxy \
     https://storage.googleapis.com/kubernetes-release/release/${CLUSTER_VERSION}/bin/linux/amd64/kubelet

    
     # Install the binaries
     # _________________________________________________________________________________
     echo "unzip containerd to binaries folder and copy to correct folder"
     #---------- Containerd --------------------------
     sudo mkdir -p /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/containerd
     sudo tar -xvf /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/containerd-${WORKER_PLANE_CONTAINERD_VERSION:1}-linux-amd64.tar.gz -C /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/containerd 
     sudo chmod 755 /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/containerd/bin/*
     sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/containerd/bin/* /bin/
     
     # ----------- kubectl kube-proxy kubelet crictl runc ------------------------------
     echo "unzip crictl and move crictl runc kubelet kube-proxy kubelet to correct folder"
     sudo tar -xvf /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/crictl-${WORKER_PLANE_CRI_TOOLS_VERSION}-linux-amd64.tar.gz -C /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries
     sudo chmod 755 /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/*
     sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/kube* /usr/local/bin
     sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/crictl /usr/local/bin
     sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/runc.amd64 /usr/local/bin/runc
     

     #---------- cni-plugins ------------------------------
     sudo mkdir -p /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/cni-plugins
     sudo tar -xvf /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/cni-plugins-linux-amd64-${WORKER_PLANE_CNI_PLUGIN_VERSION}.tgz -C /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/cni-plugins
     sudo chmod 755 /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/cni-plugins/*
     sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/binaries/cni-plugins/* /opt/cni/bin

               
    # copy cert-auth required certs
    # _____________________________________________________________________________________
      echo "copy cert-auth certs to /var/lib/kubernetes directory"
      sudo cp /home/$SSH_USER/k8s-bare-metal/cert-authority/certs/ca.pem \
              /home/$SSH_USER/k8s-bare-metal/cert-authority/certs/ca-key.pem \
              /var/lib/kubernetes 

     # copy k8s service config files to /etc/systemd/system directory
     # _____________________________________________________________________________________
      echo "copy service files to /etc/systemd/system"
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/kubelet.service /etc/systemd/system/kubelet.service
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/kube-proxy.service /etc/systemd/system/kube-proxy.service
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/containerd.service /etc/systemd/system/containerd.service
      
       
      # copy required config files
      # _____________________________________________________________________________________ 
      echo "copy k8s configs to /var/lib/kubernetes directory"
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/kube-proxy-config.yaml /var/lib/kube-proxy
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/kubelet-config.yaml /var/lib/kubelet
      
      echo "copy containerd and cni config files - conf.toml 10-bridge.conf and 99-loopback.conf"
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/${NODE_NAME}.10-bridge.conf /etc/cni/net.d/10-bridge.conf
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/config/99-loopback.conf /etc/cni/net.d/99-loopback.conf
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/config/config.toml /etc/containerd/config.toml
              
    
      #-------------- TLS BOOTSTRAPPING OPTIONS  ----------------------------
      if [ "$CLUSTER_TLS_BOOTSTRAPING" = false ] ; then
      
      echo "TLS bootstrapping is set to false for worker"

      echo "copy node kubelet certs to /var/lib/kubelet directory"
      #------- node's kubelet cert
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/${NODE_NAME}.pem \
              /home/$SSH_USER/k8s-bare-metal/worker-plane/output/${NODE_NAME}-key.pem \
              /var/lib/kubelet 
      echo "copy ${NODE_NAME}.kubeconfig to /var/lib/kubelet/kubeconfig directory"
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/${NODE_NAME}.kubeconfig /var/lib/kubelet/kubeconfig

      else

      echo "TLS bootstrapping is set to true for worker"
      echo "copy bootstrap-kubeconfig file"
      sudo cp /home/$SSH_USER/k8s-bare-metal/worker-plane/output/bootstrap-kubeconfig /var/lib/kubelet


      fi
      #--------------------------------------------------------------------------
      
     
    
    # start the service
      echo "enable and start the k8s services" 
      sudo systemctl daemon-reload
      sudo systemctl enable containerd kubelet kube-proxy 
      sudo systemctl start containerd kubelet kube-proxy

    #                                                             
     
   echo "#######################################################################################################"
EOF


done