#!/bin/sh

# ***************************************************************************
# common variables
# ***************************************************************************
# Cluster Name
CLUSTER_NAME="k8s-bare-metal"
# Cluster Version
CLUSTER_VERSION="v1.18.6"
# Cluster cidr
CLUSTER_CIDR="10.32.0.0/12"
# Cluster Service CIDR
CLUSTER_SVC_CIDR="10.32.0.0/16"
# Cluster TLS BOOT STRAPPING ALLOWED FOR WORKER NODES ( NOT TESTED YET - keep it false for now)
CLUSTER_TLS_BOOTSTRAPING=false
# cluster api load balancer
CLUSTER_API_LOAD_BALANCER="k8s-master-lb"
# choose a provide from kube-router , calico , cillium or weavenet. ( only tested kube-router keep it to kube-router)
CLUSTER_CNI_PROVIDER="kube-router"
# SSH user name and cert file to connect to the nodes (master, load balancer, etcd, and worker - for now only one key is allowed to be used by all configure ssh with a single key)
SSH_USER="stanwar"
SSH_CERT="/home/stanwar/.ssh/id_rsa"

# NOT tested yet keep it as it is
# The token-id must be 6 characters and the token-secret must be 16 characters.
# They must be lower case ASCII letters and numbers. Specifically it must match the regular expression: [a-z0-9]{6}\.[a-z0-9]{16}. 
# TLS boot strapping secret and i
BOOTSTRAP_TOKEN_ID="07401b"
BOOTSTRAP_TOKEN_SECRET="f395accd246ae52d"



# ***************************************************************************
# control plane variables
# ***************************************************************************

#declare -a CONTROL_PLANE_NODES=("k8s-tester-node")
declare -a CONTROL_PLANE_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")
#etcd variables
CONTROL_PLANE_ETCD_VERSION="v3.4.10" 
#declare -a CONTROL_PLANE_ETCD_NODES=("k8s-tester-node")
declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master-1" "k8s-master-2" "k8s-master-3")



# ***************************************************************************
# worker plane variables
# ***************************************************************************
WORKER_PLANE_CONTAINERD_VERSION="v1.3.6"
WORKER_PLANE_RUNC_VERSION="v1.0.0-rc91"
WORKER_PLANE_CNI_PLUGIN_VERSION="v0.8.6"
WORKER_PLANE_CRI_TOOLS_VERSION="v1.18.0"
declare -a WORKER_PLANE_NODES=("k8s-worker-1" "k8s-worker-2" "k8s-worker-3")
#declare -a WORKER_PLANE_NODES=("k8s-tester-node")
# max number of pods to run on a node -default is 110
WORKER_PLANE_MAX_PODS=200



