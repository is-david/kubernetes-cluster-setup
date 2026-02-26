#!/usr/bin/env bash

LB_IP="10.0.1.5"
LOCAL_IP=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
LOCAL_NAME=$(hostname)
API_PORT=6443

token="abcdef.123456"
discovery_token_ca_cert_hash="sha256:abc..."

OUTPUT_FILE="${OUTPUT_FILE:-/root/join-config.yaml}"

sudo bash -c "cat > $OUTPUT_FILE" <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: "$LB_IP:$API_PORT"
    token: "$token"
    caCertHashes: 
    - "$discovery_token_ca_cert_hash"
nodeRegistration:
  name: "$LOCAL_NAME"
  kubeletExtraArgs:
    node-ip: "$LOCAL_IP"
EOF

sudo kubeadm join --config ${OUTPUT_FILE} --ignore-preflight-errors=Mem

sudo rm -f $OUTPUT_FILE