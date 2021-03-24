# k8s-bare-metal
Step-by-step install guide and helper scripts to provision k8s on bare metal or VMs. 

Note: This is no where for production usage, enjoy the script change it and learn from it.


# Requirments
Following are the requirments to run the scripts for creating k8s cluster
1. Minimum install machine requirments
    - 1 Node  ( 1 vcpu - 1 gig ram - 10 gb disk) - Single node for worker / master / etcd  etc.
    
2. Optional requirments
    - 1 Load Balancer Node if using more than 1 master node -  ( 1 vcpu - 1 gig ram - 10 gb disk)
    - N ETCD Node for installing etcd seperate from master nodes  - ( 1 vcpu - 1 gig ram - 10 gb disk)
2. OS and other requirments
    - Ubuntu 18.4 LTS tested
4. SSH Configuration
    - RSA Key based authentication with userid  (with Password auth set to false)
5. IPv4 IP Address and ability to ssh and ping to the nodes from the local network
6. Local machine require following client tools in order to run the scripts
    - cfssljson , cfssl and kubectl ( install them under /usr/local/bin )


# Steps to execute  

Note: Sripts need to be run from a local machine. This machine should be able to ping and ssh k8s install machines as specified in variables.sh file. This way we need not to ssh and login on any k8s machine for install.


PreReq -  Install cfssljson , cfssl and kubectl on local machine.  Install them under /usr/local/bin folder.
la
1. Clone the repository on a local machine (Windows WSL or Linux) this is a different machine than specified in variables.sh for k8s cluster.
2. CD to k8s-bare-metal directory
3. Verify the variables.sh file and update variables for following
    - Cluster name
    - Control Plane Nodes
    - Load Balancer Node
    - ETCD Node
    - Worker Plane Node
4. Save the variables file after updating
5. Make sure you are able to ssh to the nodes used in variables file from the local shell, if any issues resolve it.
6. Run the scripts in following order from inside k8s-bare-metal directory
    - bash 1_install_control_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 2_install_worker_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 3_install_network_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 4_verify_cluster.sh ( verify the log output to make sure there is no critical error)
7. You should be able to use now kubectl from your local shell, (It will remove the existing kubeconfig , please back it up)
