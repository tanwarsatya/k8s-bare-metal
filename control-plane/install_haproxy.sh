#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE


 LOAD_BALANCER_IP=( $(host $CLUSTER_API_LOAD_BALANCER | grep -oP "192.168.*.*")  )

echo "--------------------------------"
echo "Install HA Proxy as loadbalancer for api server "
echo "--------------------------------"
if [ LOAD_BALANCER_IP != "" ]; then

#copy the k8s-bare-metal folder
echo "sync the k8s_bare_metal folder to the node"
sudo rsync -avzq  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal $SSH_USER@$CLUSTER_API_LOAD_BALANCER:/home/$SSH_USER


echo "executing remote shell commands"
    
ssh -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$CLUSTER_API_LOAD_BALANCER /bin/bash << EOF 



echo "Stop and disable ha proxy.."

sudo systemctl stop haproxy
sudo systemctl disable haproxy


echo "Install ha proxy  "
sudo apt-get update && sudo apt-get install -y haproxy

echo "Copy ha proxy config and start service"
sudo cp /home/$SSH_USER/k8s-bare-metal/control-plane/output/haproxy.cfg /etc/haproxy
sudo service haproxy restart

EOF

else

 echo "Node: $CLUSTER_API_LOAD_BALANCER  is not running and haproxy can't be installed."

fi