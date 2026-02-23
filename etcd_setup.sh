#!/usr/bin/env bash

export etcd1_ip=172.20.223.219
export etcd2_ip=172.20.212.174
export etcd3_ip=172.20.219.32

export etcd1_name=etcd1.mshome.net
export etcd2_name=etcd2.mshome.net
export etcd3_name=etcd3.mshome.net

export currentvm=etcd3

# clenup any existing etcd setup
sudo systemctl stop etcd || true
sudo systemctl disable etcd || true
sudo rm -f /etc/systemd/system/etcd.service || true
sudo rm -rf /var/lib/etcd || true

# export currentvm_ip and currentvm_name based on the currentvm variable
eval export currentvm_ip=\${${currentvm}_ip}
eval export currentvm_name=\${${currentvm}_name}

ETCD_DIR="/var/lib/etcd"
ETCD_SERVICE="/etc/systemd/system/etcd.service"
ETCD_VER=v3.6.8

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download

# setup etcd user and directories
sudo mkdir -p $ETCD_DIR
sudo groupadd -f -g 1501 etcd
sudo useradd -c "etcd user" -d $ETCD_DIR -s /bin/false -g etcd -u 1501 etcd
sudo chown -R etcd:etcd $ETCD_DIR

# create systemd service file for etcd
sudo tee $ETCD_SERVICE > /dev/null <<EOF
[Unit]
Description=etcd
[Service]
ExecStart=/usr/local/bin/etcd \\
  --name $currentvm \\
  --initial-advertise-peer-urls https://${currentvm_name}:2380 \\
  --listen-peer-urls https://${currentvm_ip}:2380 \\
  --listen-client-urls https://${currentvm_ip}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${currentvm_name}:2379 \\
  --initial-cluster-token etcd-cluster-1 \\
  --initial-cluster etcd1=https://${etcd1_name}:2380,etcd2=https://${etcd2_name}:2380,etcd3=https://${etcd3_name}:2380 \\
  --log-outputs=/var/lib/etcd/etcd.log \\
  --initial-cluster-state new \\
  --peer-auto-tls \\
  --snapshot-count '10000' \\
  --wal-dir=/var/lib/etcd/wal \\
  --data-dir=/var/lib/etcd/data \\
  --auto-tls
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
/usr/local/bin/etcdctl --endpoints=https://$currentvm_name:2379 --insecure-skip-tls-verify endpoint health

echo "Setup completed for $currentvm_name ($currentvm_ip)."