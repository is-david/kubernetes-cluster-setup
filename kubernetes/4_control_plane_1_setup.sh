#!/usr/bin/env bash

LB_IP="10.0.1.5"
API_PORT=6443

etcd1_ip=10.0.1.21
etcd2_ip=10.0.1.22
etcd3_ip=10.0.1.23

SHARED_DIR="/Shared/kubernetes/etcd-certs"

PKI_DIR="/etc/kubernetes/pki"
sudo mkdir -p $PKI_DIR || true
cp $SHARED_DIR/etcd1/apiserver-etcd-client.crt $PKI_DIR/
cp $SHARED_DIR/etcd1/apiserver-etcd-client.key $PKI_DIR/

sudo chmod 600 "$PKI_DIR/apiserver-etcd-client.key"
sudo chown root:root "$PKI_DIR/apiserver-etcd-client.key" "$PKI_DIR/apiserver-etcd-client.crt"

PKI_DIR="/etc/kubernetes/pki/etcd"
sudo mkdir -p $PKI_DIR || true
sudo cp $SHARED_DIR/ca.crt $PKI_DIR/ca.crt
sudo cp $SHARED_DIR/ca.key $PKI_DIR/ca.key

sudo chmod 600 "$PKI_DIR/ca.key"
sudo chown root:root "$PKI_DIR/ca.key" "$PKI_DIR/ca.crt"

OUTPUT_FILE="${OUTPUT_FILE:-/root/kubeadm-config.yaml}"

sudo bash -c "cat > $OUTPUT_FILE" <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: cluster1
kubernetesVersion: v1.35.1
controlPlaneEndpoint: "${LB_IP}:6443"

etcd:
  external:
    endpoints:
      - https://${etcd1_ip}:2379
      - https://${etcd2_ip}:2379
      - https://${etcd3_ip}:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key

networking:
  podSubnet: "192.168.0.0/16"
EOF

sudo kubeadm init --config ${OUTPUT_FILE} --upload-certs --ignore-preflight-errors=Mem

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
