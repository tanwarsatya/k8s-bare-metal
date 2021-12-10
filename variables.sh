#!/bin/sh

# ***************************************************************************
# common variables
# ***************************************************************************
# User name and key file for remote login on vms for deploying cluster component
SSH_USER="k8suser"
SSH_CERT="k8suser"

# Cluster Name
CLUSTER_NAME="stanwar-cluster"

#VM and Node Name
#############################################
declare -a CONTROL_PLANE_NODES=("k8s-master")
declare -a CONTROL_PLANE_ETCD_NODES=("k8s-master")
declare -a WORKER_PLANE_NODES=("node-1" "node-2")
CLUSTER_API_LOAD_BALANCER="k8s-master"

#Network Range and CNI
#############################################
# Cluster cidr
CLUSTER_CIDR="10.32.0.0/12"
# Cluster Service CIDR
CLUSTER_SVC_CIDR="10.32.0.0/16"
# choose a provide from list [kube-router , calico , cilium ]
CLUSTER_CNI_PROVIDER="cilium"

# Version 
##############################################
# CFSSL Version
CFSSL_VERSION="1.6.1"
# ETCD Version
CONTROL_PLANE_ETCD_VERSION="v3.4.16" 
# Cluster Version
CLUSTER_VERSION="v1.21.0"
# Containerd Version
WORKER_PLANE_CONTAINERD_VERSION="v1.5.5"
# Runc version
WORKER_PLANE_RUNC_VERSION="v1.0.2"
# CNI Plugin Version
WORKER_PLANE_CNI_PLUGIN_VERSION="v1.0.1"
# CRI Tools Version
WORKER_PLANE_CRI_TOOLS_VERSION="v1.22.0"

# max number of pods to run on a node -default is 110
WORKER_PLANE_MAX_PODS=200
# Cluster TLS BOOT STRAPPING ALLOWED FOR WORKER NODES ( NOT TESTED YET - keep it false for now)
CLUSTER_TLS_BOOTSTRAPING=false
# NOT tested yet keep it as it is
# The token-id must be 6 characters and the token-secret must be 16 characters.
# They must be lower case ASCII letters and numbers. Specifically it must match the regular expression: [a-z0-9]{6}\.[a-z0-9]{16}. 
# TLS boot strapping secret and i
BOOTSTRAP_TOKEN_ID="07401b"
BOOTSTRAP_TOKEN_SECRET="f395accd246ae52d"

