#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

echo "--------------------------------"
echo "post install for network, rbac and other configurations"
echo "--------------------------------"

# Add the config file for the current user
echo "copy admin.kubeconfig to /home/$USER/.kube/config for local kubectl"
mkdir -p /home/$USER/.kube
cp  control-plane/output/$CLUSTER_NAME.kubeconfig /home/$USER/.kube/config
chmod 777 /home/$USER/.kube/config

# RBAC and other related confiurations
echo "apply rbac role and rolebinding for kubelet"
kubectl apply -f control-plane/config/kubelet-auth-role.yaml                 
kubectl apply -f control-plane/config/kubelet-auth-role-binding.yaml
echo "apply tls boot straping token"
kubectl apply -f control-plane/output/bootstrap-token-${BOOTSTRAP_TOKEN_ID}.yaml

# Network configuraiton
case $CLUSTER_CNI_PROVIDER in

  kube-router)
    echo "applying kube-router cni plugin"
    kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/generic-kuberouter.yaml
    ;;

  calico)
    echo "applying calico cni plugin"
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    ;;
esac