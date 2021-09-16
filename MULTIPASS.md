# mulitpass vms

https://github.com/arashkaffamanesh/kubeadm-multipass

https://discourse.ubuntu.com/t/multipass-exec-command/10851

## Multipass vms on Windows 10
1. Enable Hyper-V in Windows 10
   
   https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v

2. Install mulitpass on Windows 10 
   
    https://multipass.run/

3. Enable external Switch in Hyper-V with name multipass, this will allow the vms to be visible on local network
   
  https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines

  - Name the external virtual switch to 'multipass'

4. Generate openssh priavate/public keypair to be used for login via ssh

    - run ssh-keygen from the multipass folder generate private/public key pair 
    - generate user-key and user-key.pub file inside the multipass folder

5. Update the cloud-init.yaml file correct ssh key by replacing the ssh_authroized_key value to user-key.pub file content


Example: cloud-init.yaml

users:
  - default
  - name: k8suser
    passwd: 
    sudo:  ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYw0zOlluBA2v0XxniLOYCiZ3iTqzFkiEa0uSGMfjHvjnstTO+2XN1/8tThoJLB33LO0YGO3djwUkb66bBmgYVj13PCR5aURXM9pZrvQxvokFx1TDLTuw2bkAoZzryug0oEkLYNMCFJeZ7EuPqLpAtQLkHFbsHGafyFp7Eaah2w5hM9iRqKdvLel+XbL+lNnHirfZ8yzhZTgf21YVX3fICkH7H6Nfuv7fWTjgFIeMstYiyUgS7jf8392jmVW62bjCATcrmeIm/gFLoJCn77hi27ufSm6MCH56Jn5qvFRWbQ8TiWoQDfB9z8xjbogtd+0CcjbR3G1KOmw9DBrYUaQrbUSd1W2jvbdfJKd6xeSfza6G/I1y91/ctMEZNCFh51YIJl6ie/2kFFjJjPMDC/oy/dbpi/ehoG+GbXfSYox18H61hA1lAQnCNmJHm4eYQ3D4RjshHmd49MQByfBU4vwjeEBnLnNpgorMc80rC4Didoa9Hu4bflJBluqKsby5634c= stanwar@stanwar-laptop


6. Provision 3 machines as following by running this command from the multipass folder

multipass launch -n=local-k8s-master --network name=multipass,mode=auto -c=1 -m=8G -d=20G --cloud-init=cloud-init.yaml

multipass launch -n=local-k8s-node1 --network name=multipass,mode=auto -c=1 -m=8G -d=20G --cloud-init=cloud-init.yaml

multipass launch -n=local-k8s-node2 --network name=multipass,mode=auto -c=1 -m=8G -d=20G --cloud-init=cloud-init.yaml




