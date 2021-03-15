#!/bin/sh
# control plane variables
# -----------------------------------------------------------
# k8s variables
CONTROL_PLANE_K8S_VERSION="v1.18.6" 
#declare -a CONTROL_PLANE_NODES=("k8s-master-1")
declare -a CONTROL_PLANE_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")
CONTROL_PLANE_CLUSTER_CIDR="10.200.0.0/16"
CONTROL_PLANE_SERVICE_IP_RANGE="10.32.0.0/16"
CONTROL_PLANE_API_LOAD_BALANCER_NODE="k8s-master-lb"

#etcd variables
CONTROL_PLANE_ETCD_VERSION="v3.4.10" 
declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")




# SSH Variables
CONTROL_PLANE_SSH_USER="stanwar"
CONTROL_PLANE_SSH_CERT="/home/stanwar/.ssh/id_rsa"

# -----------------------------------------------------------

# Helper Funtions
color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1