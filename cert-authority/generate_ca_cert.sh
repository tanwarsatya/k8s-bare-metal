#!/bin/sh
echo "k8s-bare-metal"
echo "--------------------------------"
echo "cert-authority - generate certs"
echo "--------------------------------"
cfssl gencert -initca config/ca-csr.json | cfssljson -bare cert/ca