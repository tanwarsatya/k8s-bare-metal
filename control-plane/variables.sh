#!/bin/sh
# control plane variables
# -----------------------------------------------------------
# Node variables
declare -a CONTROL_PLANE_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")
declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")

CONTROL_PLANE_API_LOAD_BALANCER_NODE="k8s-master-lb"
CONTROL_PLANE_CLUSTER_CIDR="10.200.0.0/16"
CONTROL_PLANE_SERVICE_IP_RANGE="10.32.0.0/16"

# SSH Variables
CONTROL_PLANE_SSH_USER="stanwar"
CONTROL_PLANE_SSH_CERT="/home/stanwar/.ssh/id_rsa"

# -----------------------------------------------------------

