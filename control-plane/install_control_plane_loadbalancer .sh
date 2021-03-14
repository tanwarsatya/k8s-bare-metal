#!/bin/sh

# import the variables source file
source variables.sh

echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane k8s - installation"

# Set the load balancer node for api server
LOAD_BALANCER_NODE="k8s-master-lb"
LOAD_BALANCER_IP=( $(host ${LOAD_BALANCER_NODE} | grep -oP "192.168.*.*")  )

if [ "LOAD_BALANCER_IP" != "" ]; then

echo "--------------------------------"
echo "0. disable ha proxy  "
echo "--------------------------------"

echo "Stop and disable etcd..."
# stop and disable etcd services if running
sudo systemctl stop haproxy
sudo systemctl disable haproxy

echo "--------------------------------"
echo "1. Install ha proxy  "
echo "--------------------------------"

sudo apt-get update && sudo apt-get install -y haproxy

echo "--------------------------------"
echo "2. Copy ha proxy config  and start service"
echo "--------------------------------"

# move the haproxy config from output to /etc/haproxy
sudo cp output/haproxy.cfg /etc/haproxy

sudo service haproxy restart
echo "--------------------------------"
echo "3. Validate ha proxy forwarding request"
echo "--------------------------------"

curl  https://${LOAD_BALANCER_IP}:6443/version -k

else

 echo "Node: $LOAD_BALANCER_NODE  is down and haproxy can't be installed."

fi