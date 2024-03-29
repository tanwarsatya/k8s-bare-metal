#!/bin/sh

#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "*********************verify cluster components************************"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


# Check etcd cluster components
# -----------------------------------------------------------------
echo "____________________________________________________________________________"
echo "verifying etcd cluster"
echo "____________________________________________________________________________"
# use the first node of etcd cluster
NODE_NAME=${CONTROL_PLANE_ETCD_NODES[0]}

# remove the node from host to avoid warning
ssh-keygen -q -f "/home/$USER/.ssh/known_hosts" -R $NODE_NAME

ssh -i $SSH_CERT -o StrictHostKeyChecking=no $SSH_USER@$NODE_NAME /bin/bash << EOF 

sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem

EOF

# Check k8s cluster components
# -----------------------------------------------------------------
echo "____________________________________________________________________________"
echo "verifying k8s componentstatus of cluster"
echo "____________________________________________________________________________"

kubectl get componentstatuses



echo "____________________________________________________________________________"
echo "verifying worker nodes "
echo "____________________________________________________________________________"
# use the first node of etcd cluster
sleep 3
kubectl get nodes -o wide


echo "____________________________________________________________________________"
echo "verifying system pods "
echo "____________________________________________________________________________"
# use the first node of etcd cluster
kubectl get pods -n kube-system -o wide




echo "____________________________________________________________________________"
echo "Deploy nginx pods  "
echo "____________________________________________________________________________"
# use the first node of etcd cluster
echo  "remove existing nginx deployment"
kubectl delete deployment ngx 

echo  "create nginx"
kubectl create deployment ngx --image=nginx

POD_NUM=$(shuf -i1-30 -n1)
echo  "scale the deployment to $POD_NUM pods"

kubectl scale deployment ngx --replicas=$POD_NUM

echo  "wait 10 seconds for pods to start"
sleep 10

kubectl get pods -o wide
kubectl get deployment ngx
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


