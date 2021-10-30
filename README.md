# k8s-bare-metal on Windows 10
Step-by-step install guide and helper scripts to provision k8s on local vms using multipass. 
This is based on kubernetes hard way, but provide automation using pure shell scripts to reduce effort in provisoning cluster from scratch.

The cluster provisioned only for purpose of learning and practicing scenarios for CKA/CKAD/CKS exams.

This will provison a simple cluster with 1 master node and 2 worker nodes

Note: Scripts need to be run from devloper laptop/machine. 

# Steps to Perform


1. Install the WSL2 on Windows 10 and use Ubuntu Distro (18.04 or 20.04), follow the steps as per the given link

    https://docs.microsoft.com/en-us/windows/wsl/install-win10#manual-installation-steps
   
2. Start WSL Session and Clone the repository to a k8s-bare-metal folder.
3. CD to k8s-bare-metal directory
4. Create vms on laptop/desktop or use physical machines in local network.
5. Verify the variables.sh file and update based on the vms created using multipass, make sure to save the file after changes 
    - Cluster name - local-k8s-cluster
    - Control Plane Nodes - {local-k8s-master}
    - Load Balancer Node  - {local-k8s-master}
    - ETCD Node           - {local-k8s-master}
    - Worker Plane Node   - {local-k8s-node1,local-k8s-node2}
    - SSH_USER            - "k8suser"
    - SSH_KEY             - "k8suser-key"  

6. Run the scripts in following order from inside k8s-bare-metal directory
    - bash 1_install_control_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 2_install_worker_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 3_install_network_plane.sh ( verify the log output to make sure there is no critical error)
    - bash 4_verify_cluster.sh ( verify the log output to make sure there is no critical error)
  
7. You should be able to use now kubectl from your local shell (WSL/LINUX)