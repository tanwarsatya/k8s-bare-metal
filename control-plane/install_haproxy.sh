#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE
echo "--------------------------------"
echo "Install HA Proxy as loadbalancer for api server "
echo "--------------------------------"

LOAD_BALANCER_IP=( $(host $CLUSTER_API_LOAD_BALANCER | grep -oP "192.168.*.*")  )

# if the load balancer name is same as of control plane node don't install
# if IP address can't be found don't install
if [[ ! " ${CONTROL_PLANE_NODES[@]} " =~ " ${CLUSTER_API_LOAD_BALANCER} " ]] && [ LOAD_BALANCER_IP != "" ] ; then

echo "installing ha proxy on node $CLUSTER_API_LOAD_BALANCER : $LOAD_BALANCER_IP"
#copy the k8s-bare-metal folder
echo "sync the k8s_bare_metal folder to the node"
rsync -avzq  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal/cert-authority $SSH_USER@$CLUSTER_API_LOAD_BALANCER:/home/$SSH_USER/k8s-bare-metal
rsync -avzq  -e "ssh -o StrictHostKeyChecking=no -i $SSH_CERT" ../k8s-bare-metal/control-plane $SSH_USER@$CLUSTER_API_LOAD_BALANCER:/home/$SSH_USER/k8s-bare-metal


echo "executing remote shell commands"
ssh-keygen -q -f "/home/$USER/.ssh/known_hosts" -R $CLUSTER_API_LOAD_BALANCER    
ssh -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$CLUSTER_API_LOAD_BALANCER /bin/bash << EOF 



echo "Stop and disable ha proxy.."

sudo systemctl stop haproxy
sudo systemctl disable haproxy


echo "Install ha proxy  "
sudo apt-get update && sudo apt-get install -y haproxy

echo "Copy ha proxy config and start service"
sudo cp /home/$SSH_USER/k8s-bare-metal/control-plane/output/haproxy.cfg /etc/haproxy
sudo systemctl enable haproxy
sudo systemctl start haproxy

EOF

else

echo "skipping installing ha proxy on node $CLUSTER_API_LOAD_BALANCER"

fi