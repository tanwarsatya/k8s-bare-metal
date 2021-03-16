#!/bin/sh

# ***************************************************************************
# common variables
# ***************************************************************************
# Cluster Name
CLUSTER_NAME="k8s-bare-metal"
# Cluster cidr
CLUSTER_CIDR="10.200.0.0/16"
# SSH user name and cert file
SSH_USER="stanwar"
SSH_CERT="/home/stanwar/.ssh/id_rsa"

# The token-id must be 6 characters and the token-secret must be 16 characters.
# They must be lower case ASCII letters and numbers. Specifically it must match the regular expression: [a-z0-9]{6}\.[a-z0-9]{16}. 
# TLS boot strapping secret and i
BOOTSTRAP_TOKEN_ID="07401b"
BOOTSTRAP_TOKEN_SECRET="f395accd246ae52d"



# ***************************************************************************
# control plane variables
# ***************************************************************************
CONTROL_PLANE_K8S_VERSION="v1.18.6" 
#declare -a CONTROL_PLANE_NODES=("k8s-master-1")
declare -a CONTROL_PLANE_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")
CLUSTER_CIDR="10.200.0.0/16"
CONTROL_PLANE_SERVICE_IP_RANGE="10.32.0.0/16"
CONTROL_PLANE_API_LOAD_BALANCER_NODE="k8s-master-lb"

#etcd variables
CONTROL_PLANE_ETCD_VERSION="v3.4.10" 
#declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master-1")
declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")



# ***************************************************************************
# worker plane variables
# ***************************************************************************
WORKER_PLANE_TLS_BOOTSTRAPING=false
declare -a WORKER_PLANE_NODES=("k8s-worker-1" "k8s-worker-2" "k8s-worker-3")
