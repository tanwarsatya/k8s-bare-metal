#!/bin/sh

# import vairables
source variables.sh


 LOAD_BALANCER_NODE_IP=( $(host $CONTROL_PLANE_API_LOAD_BALANCER_NODE | grep -oP "192.168.*.*")  )

echo "--------------------------------"
echo "Install HA Proxy as loadbalancer for api server "
echo "--------------------------------"
if [ "LOAD_BALANCER_NODE_IP" != "" ]; then

echo "--------------------------------"
echo "0. disable ha proxy  "
echo "--------------------------------"


echo "executing remote shell commands"
    
ssh -i $CONTROL_PLANE_SSH_CERT -o StrictHostKeyChecking=no $CONTROL_PLANE_SSH_USER@$CONTROL_PLANE_API_LOAD_BALANCER_NODE /bin/bash << EOF 


echo "Stop and disable ha proxy.."

sudo systemctl stop haproxy
sudo systemctl disable haproxy


echo "Install ha proxy  "
sudo apt-get update && sudo apt-get install -y haproxy

echo "Copy ha proxy config and start service"
sudo cp /home/$CONTROL_PLANE_SSH_USER/k8s-bare-metal/control-plane/output/haproxy.cfg /etc/haproxy
sudo service haproxy restart

EOF

else

 echo "Node: $LOAD_BALANCER_NODE  is not running and haproxy can't be installed."

fi