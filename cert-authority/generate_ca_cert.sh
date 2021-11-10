#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "cert-authority - generate certs"
echo "--------------------------------"

CURRENT_DIR=cert-authority

FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE
#generate root cert if not available 
CA_PEM_FILE=cert-authority/certs/ca.pem
CA_KEY_FILE=cert-authority/certs/ca-key.pem

if [ -f "$CA_PEM_FILE" ] && [ -f "$CA_KEY_FILE" ]; then 
echo " Root CA File exists : ca.pem and ca-key.pem exists, using existing root ca files."
else
echo " No Root CA file found generating new ca files."
mkdir -p certs

# Download cfssl and cfsjson
echo "Downloading cfssl and cfsljson"
wget -q --show-progress --https-only --timestamping \
  https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssl_${CFSSL_VERSION}_linux_amd64 \
  https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssljson_${CFSSL_VERSION}_linux_amd64

#allow execute and copy to /usr/local/bin
echo "moving to /usr/local/bin"
chmod +x cfssl_${CFSSL_VERSION}_linux_amd64
chmod +x cfssljson_${CFSSL_VERSION}_linux_amd64 

sudo mv cfssl_${CFSSL_VERSION}_linux_amd64 /usr/local/bin/cfssl
sudo mv cfssljson_${CFSSL_VERSION}_linux_amd64 /usr/local/bin/cfssljson


cfssl gencert -initca cert-authority/config/ca-csr.json | cfssljson -bare cert-authority/certs/ca
fi