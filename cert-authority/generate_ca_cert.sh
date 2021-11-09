#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "cert-authority - generate certs"
echo "--------------------------------"

mkdir -p certs

bin/cfssl gencert -initca config/ca-csr.json | bin/cfssljson -bare cert/ca