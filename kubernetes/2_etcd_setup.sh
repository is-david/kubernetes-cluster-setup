#!/usr/bin/env bash

etcd1_ip=10.0.1.21
etcd2_ip=10.0.1.22
etcd3_ip=10.0.1.23

currentvm=$(hostname)

# currentvm_ip based on the currentvm variable
eval currentvm_ip=\${${currentvm}_ip}
echo "Current VM: $currentvm ($currentvm_ip)"

ETCD_DIR="/var/lib/etcd"
ETCD_SERVICE="/etc/systemd/system/etcd.service"
SHARED_DIR="/Shared/kubernetes/etcd-certs"
PKI_DIR="/etc/kubernetes/pki"
ETCD_VER=v3.6.8

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download

# clenup any existing etcd setup
sudo systemctl stop etcd || true
sudo systemctl disable etcd || true
sudo rm -f $ETCD_SERVICE || true
sudo rm -rf $ETCD_DIR || true
sudo rm -fr /etc/kubernetes/pki/* || true

# setup etcd user and directories
sudo mkdir -p $ETCD_DIR
sudo groupadd -f -g 1501 etcd
sudo useradd -c "etcd user" -d $ETCD_DIR -s /bin/false -g etcd -u 1501 etcd
sudo chown -R etcd:etcd $ETCD_DIR

# Output file
kube_config_file="${ETCD_DIR}/etcd-config-${currentvm}.yaml"

sudo tee $kube_config_file > /dev/null <<EOF
apiVersion: kubeadm.k8s.io/v1beta3   
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "${currentvm_ip}"
  bindPort: 0

nodeRegistration:
  name: "${currentvm}"

---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration

etcd:
  local:
    serverCertSANs:
      - "${currentvm_ip}"
      - "127.0.0.1"
    peerCertSANs:
      - "${currentvm_ip}"
    extraArgs:
      initial-cluster: "etcd1=https://${etcd1_ip}:2380,etcd2=https://${etcd2_ip}:2380,etcd3=https://${etcd3_ip}:2380"
      initial-cluster-state: "new"
      initial-cluster-token: "etcd-cluster-1"
EOF

sudo mkdir -p $PKI_DIR/etcd || true
sudo cp $SHARED_DIR/ca.crt $PKI_DIR/etcd/ca.crt
sudo cp $SHARED_DIR/ca.key $PKI_DIR/etcd/ca.key

sudo chmod 600 "$PKI_DIR/etcd/ca.key"
sudo chown root:root "$PKI_DIR/etcd/ca.key" "$PKI_DIR/etcd/ca.crt"

sudo kubeadm init phase certs etcd-server --config $kube_config_file
sudo kubeadm init phase certs etcd-peer --config $kube_config_file
sudo kubeadm init phase certs etcd-healthcheck-client --config $kube_config_file
sudo kubeadm init phase certs apiserver-etcd-client --config $kube_config_file

sudo mkdir -p $SHARED_DIR/$currentvm || true
sudo cp $PKI_DIR/apiserver-etcd-client.crt $SHARED_DIR/$currentvm/apiserver-etcd-client.crt
sudo cp $PKI_DIR/apiserver-etcd-client.key $SHARED_DIR/$currentvm/apiserver-etcd-client.key

# create systemd service file for etcd
sudo tee $ETCD_SERVICE > /dev/null <<EOF
[Unit]
Description=etcd
[Service]
ExecStart=/usr/local/bin/etcd \\
  --name $currentvm \\
  --initial-advertise-peer-urls https://${currentvm_ip}:2380 \\
  --listen-peer-urls https://${currentvm_ip}:2380 \\
  --listen-client-urls https://${currentvm_ip}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${currentvm_ip}:2379 \\
  --initial-cluster-token etcd-cluster-1 \\
  --initial-cluster etcd1=https://${etcd1_ip}:2380,etcd2=https://${etcd2_ip}:2380,etcd3=https://${etcd3_ip}:2380 \\
  --log-outputs=/var/lib/etcd/etcd.log \\
  --initial-cluster-state new \\
  --snapshot-count '10000' \\
  --wal-dir=/var/lib/etcd/wal \\
  --data-dir=/var/lib/etcd/data \\
  --client-cert-auth \\
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --cert-file=/etc/kubernetes/pki/etcd/server.crt \\
  --key-file=/etc/kubernetes/pki/etcd/server.key \\
  --peer-client-cert-auth \\
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt \\
  --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

# download and install etcd binaries
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download && mkdir -p /tmp/etcd-download

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download --strip-components=1 --no-same-owner
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

sudo mv /tmp/etcd-download/etcd* /usr/local/bin/

# enable and start etcd service
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# Verify etcd status
echo "Checking etcd status..."
/usr/local/bin/etcdctl --endpoints=https://$currentvm_ip:2379 --insecure-skip-tls-verify endpoint health

echo "Setup completed for $currentvm ($currentvm_ip)."
