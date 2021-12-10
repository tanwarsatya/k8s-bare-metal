#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE

echo "--------------------------------"
echo "post install for network, rbac and other configurations"
echo "--------------------------------"


# Install Krew plugins
bash install_krew_plugins.sh
echo "merge $CLUSTER_NAME.kubeconfig to /home/$USER/.kube/config for local kubectl"
mkdir -p /home/$USER/.kube
echo "import kubeconfig via konfig plugin"
kubectl konfig import --save control-plane/output/$CLUSTER_NAME.kubeconfig
echo "change context of the kubectl to $CLUSTER_NAME"
kubectl config use-context $CLUSTER_NAME


# RBAC and other related confiurations
echo "apply rbac role and rolebinding for kubelet"
kubectl apply -f control-plane/config/kubelet-auth-role.yaml                 
kubectl apply -f control-plane/config/kubelet-auth-role-binding.yaml
echo "apply tls boot straping token"
kubectl apply -f control-plane/output/bootstrap-token-${BOOTSTRAP_TOKEN_ID}.yaml


echo "--------------------Remove CNI ----------------------------"
echo "reset existing kube-router cni plugin"
echo "--------------------------------------------------"
kubectl delete -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/generic-kuberouter.yaml

echo "reset existing calico cni plugin"
echo "--------------------------------------------------"
kubectl delete -f https://docs.projectcalico.org/manifests/calico.yaml

echo "reset existing cilium cni plugin"
echo "--------------------------------------------------"
cilium uninstall 

  

echo "--------------------Apply CNI ----------------------------"
    
# Network configuraiton
case $CLUSTER_CNI_PROVIDER in

  kube-router)
    echo "applying kube-router cni plugin"
    echo "--------------------------------------------------"
    #kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/generic-kuberouter.yaml
    ;;

  calico)

    
    echo "applying calico cni plugin"
    echo "--------------------------------------------------"
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    ;;
    
  cilium)
    
    echo "download cilium cli"
    
    curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
    
    sha256sum --check cilium-linux-amd64.tar.gz.sha256sum

    sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin

    rm cilium-linux-amd64.tar.gz{,.sha256sum}

    
    echo "apply cilium cni plugin"
    echo "--------------------------------------------------"
    cilium install
    
    
    ;;  

   
esac