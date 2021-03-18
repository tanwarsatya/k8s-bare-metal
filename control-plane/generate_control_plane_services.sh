
#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE


echo "k8s-bare-metal"
echo "--------------------------------"
echo "control plane - generate service files"

# create control-plane/output directory
sudo mkdir -p control-plane/output

# Prep Steps
#------------------------------------------------------------------------------------
#etcd service is installed on master nodes only along with api, scheduler and controller


# Loop to create a api server cluster strings 
for i in "${CONTROL_PLANE_NODES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes
   API_SERVER_SVC_ETCD_CLUSTER_STRING+="https://$(host $i | grep -oP "192.168.*.*"):2379,"
done

#loop to create etcd server cluster strings
for i in "${CONTROL_PLANE_ETCD_NODES[@]}"
do
   # Change the pattern of ip address on basis of DHCP address assigned for your nodes
   ETCD_SVC_INITIAL_CLUSTER_STRING+="${i}=https://$(host $i | grep -oP "192.168.*.*"):2380,"
   
done

#-----------------------------------------------------------------------------------

echo "--------------------------------"
echo "1. Generating multiple etcd.service for nodes"
echo "--------------------------------"

for i in "${CONTROL_PLANE_ETCD_NODES[@]}"
do
    FILE_NAME=( "$i.etcd.service" )
    ETCD_NAME=( $i )
    ETCD_IP=( $(host $i | grep -oP "192.168.*.*")  )

if [ "$ETCD_IP" != "" ]; then
   
    cat > control-plane/output/${FILE_NAME}  <<EOF 
    [Unit]
    Description=etcd
    Documentation=https://github.com/coreos

    [Service]
    Type=notify
    ExecStart=/usr/local/bin/etcd \\
      --name ${ETCD_NAME} \\
      --cert-file=/etc/etcd/etcd.pem \\
      --key-file=/etc/etcd/etcd-key.pem \\
      --peer-cert-file=/etc/etcd/etcd.pem \\
      --peer-key-file=/etc/etcd/etcd-key.pem \\
      --trusted-ca-file=/etc/etcd/ca.pem \\
      --peer-trusted-ca-file=/etc/etcd/ca.pem \\
      --peer-client-cert-auth \\
      --client-cert-auth \\
      --initial-advertise-peer-urls https://${ETCD_IP}:2380 \\
      --listen-peer-urls https://${ETCD_IP}:2380 \\
      --listen-client-urls https://${ETCD_IP}:2379,https://127.0.0.1:2379 \\
      --advertise-client-urls https://${ETCD_IP}:2379 \\
      --initial-cluster-token etcd-cluster-0 \\
      --initial-cluster ${ETCD_SVC_INITIAL_CLUSTER_STRING::-1} \\
      --initial-cluster-state new \\
      --data-dir=/var/lib/etcd 
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
EOF
else
      echo "Node: $i : is down and etcd.service file can't be generated."
fi
done


echo "********************************"
echo "2. Generating kube-apiserver.service "
echo "--------------------------------"

for i in "${CONTROL_PLANE_NODES[@]}"
do
    FILE_NAME=( "$i.kube-apiserver.service" )
    NODE_NAME=( $i )
    NODE_IP=( $(host $i | grep -oP "192.168.*.*")  )

if [ "$NODE_IP" != "" ]; then
cat > control-plane/output/${FILE_NAME}  <<EOF 
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${NODE_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-bootstrap-token-auth=true \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kube-apiserver.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kube-apiserver-key.pem \\
  --etcd-servers=${API_SERVER_SVC_ETCD_CLUSTER_STRING::-1} \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kube-apiserver.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kube-apiserver-key.pem \\
  --kubelet-https=true \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/16 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kube-apiserver.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kube-apiserver-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

else
      echo "Node: $i : is down and kube-apiserver.service file can't be generated."
fi
done

echo "********************************"
echo "3. Generating kube-controller-manager.service "
echo "--------------------------------"

cat > control-plane/output/kube-controller-manager.service  <<EOF 
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=${CLUSTER_CIDR} \\
  --cluster-name=${CLUSTER_NAME} \\
  --allocate-node-cidrs \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=${CONTROL_PLANE_SERVICE_IP_RANGE} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


echo "********************************"
echo "4. Generating kube-schduler.service "
echo "--------------------------------"



cat > control-plane/output/kube-scheduler.service <<EOF 
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/var/lib/kubernetes/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF