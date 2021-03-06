
#!/bin/sh
FILE=../variables.sh && test -f $FILE && source $FILE
FILE=variables.sh && test -f $FILE && source $FILE



 echo "^^^^^^^^^^^^^^^^^^^^Generate service files for worker-plane^^^^^^^^^^^^^^^^^^^^^^^"

# create control-plane/output directory
mkdir -p worker-plane/output
# ________________________________________________________________________________________________________________
echo "1. Generating kube-proxy.service "

cat > worker-plane/output/kube-proxy.service  <<EOF 
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# ________________________________________________________________________________________________________________


# ________________________________________________________________________________________________________________
echo "2. Generating kubelet.service "
if [[ "$CLUSTER_TLS_BOOTSTRAPING" = true ]] ; then

cat > worker-plane/output/kubelet.service <<EOF 

[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --cert-dir=/var/lib/kubelet/ \\
  --rotate-certificates=true \\
  --rotate-server-certificates=true \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

else 

cat > worker-plane/output/kubelet.service <<EOF 
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --max-pods=$WORKER_PLANE_MAX_PODS \\
  --register-node=true \\
  --tls-cert-file=/var/lib/kubelet/kubelet.pem \\
  --tls-private-key-file=/var/lib/kubelet/kubelet-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

fi

# ________________________________________________________________________________________________________________


echo "3. Generating containerd.service "

cat > worker-plane/output/containerd.service  <<EOF 
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# ****************************************************************************************************************