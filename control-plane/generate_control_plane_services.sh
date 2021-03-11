#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate service files"
echo "--------------------------------"
echo "1. Generating etcd.service for nodes"
echo "--------------------------------"


#etcd service is installed on master nodes only along with api, scheduler and controller
# get public ip address for control plane nodes
# Get nodes list from the file
mapfile -t NODE_HOSTNAMES < control-plane-nodes.txt

# Loop to create a cluster string used in etcd.service  
for i in "${NODE_HOSTNAMES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes

   CLUSTER_STRING+="${i}=$(host $i | grep -oP "192.168.*.*"):2380,"
 
done
# generate a cluster stirng to be used , remove the last ',' from the string
#$CLUSTER_STRING=`echo $CLUSTER_STRING | sed 's/.$//'`

#---- Actual File Geenration for all the etcd nodes -------------------

for i in "${NODE_HOSTNAMES[@]}"
do
    FILE_NAME=( "$i.etcd.service" )
    ETCD_NAME=( $i )
    ETCD_IP=( $(host $i | grep -oP "192.168.*.*")  )


    cat > config/${FILE_NAME}  <<EOF 
    [Unit]
    Description=etcd
    Documentation=https://github.com/coreos

    [Service]
    Type=notify
    ExecStart=/usr/local/bin/etcd \\
      --name ${ETCD_NAME} \\
      --cert-file=/etc/etcd/kubernetes.pem \\
      --key-file=/etc/etcd/kubernetes-key.pem \\
      --peer-cert-file=/etc/etcd/kubernetes.pem \\
      --peer-key-file=/etc/etcd/kubernetes-key.pem \\
      --trusted-ca-file=/etc/etcd/ca.pem \\
      --peer-trusted-ca-file=/etc/etcd/ca.pem \\
      --peer-client-cert-auth \\
      --client-cert-auth \\
      --initial-advertise-peer-urls https://${ETCD_IP}:2380 \\
      --listen-peer-urls https://${ETCD_IP}:2380 \\
      --listen-client-urls https://${ETCD_IP}:2379,https://127.0.0.1:2379 \\
      --advertise-client-urls https://${ETCD_IP}:2379 \\
      --initial-cluster-token etcd-cluster-0 \\
      --initial-cluster ${CLUSTER_STRING::-1} \\ 
      --initial-cluster-state new \\
      --data-dir=/var/lib/etcd 
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF
done