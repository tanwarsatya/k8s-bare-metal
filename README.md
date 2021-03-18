# k8s-bare-metal
Step-by-step install guide and helper scripts to provision k8s on bare metal or VMs. 

# Some Helpful commands
# 1. Check the content of certs
openssl x509 -in ca.pem -text -noout

# 2. Create an encryption key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
