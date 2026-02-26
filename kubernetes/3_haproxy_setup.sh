#!/usr/bin/env bash

# ==========================================================
# HAProxy config generator for Kubernetes HA control-plane
# + optional NodePort load balancing
# LB uses its own IP (no VIP required)
# ==========================================================

# Detect LB VM IP (primary outbound interface)
LB_IP="10.0.1.5"
API_PORT=6443

# --- Control-plane nodes ---
CONTROL_PLANES=(
  "control1 10.0.1.11"
  "control2 10.0.1.12"
  "control3 10.0.1.13"
)

# --- NodePort services to expose ---
# Format: "serviceName nodePort"
# Add as many as you want
NODEPORTS=(
  "nginx 30080"
  "app1 30081"
)

# Update and install HAProxy
sudo apt update
sudo apt install haproxy -y

# Generate HAProxy config
OUTPUT_FILE="${OUTPUT_FILE:-/etc/haproxy/haproxy.cfg}"

echo "Detected LB IP: $LB_IP"
echo "Generating HAProxy config at: $OUTPUT_FILE"
echo

sudo bash -c "cat > $OUTPUT_FILE" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 2000
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 10s
    timeout client  1m
    timeout server  1m

# ===========================
# Kubernetes API LoadBalancer
# ===========================
frontend kubernetes-frontend
    bind ${LB_IP}:${API_PORT}
    default_backend kubernetes-backend

backend kubernetes-backend
    option tcp-check
    balance roundrobin
EOF

# Add control-plane servers
for entry in "${CONTROL_PLANES[@]}"; do
    NAME=$(echo "$entry" | awk '{print $1}')
    IP=$(echo "$entry" | awk '{print $2}')
    echo "    server ${NAME} ${IP}:${API_PORT} check fall 3 rise 2" | sudo tee -a "$OUTPUT_FILE" >/dev/null
done

sudo systemctl restart haproxy
sudo systemctl enable haproxy

# ===========================
# NodePort LoadBalancers
# ===========================
# echo "" | sudo tee -a "$OUTPUT_FILE" >/dev/null
# echo "# ===========================" | sudo tee -a "$OUTPUT_FILE" >/dev/null
# echo "# NodePort Services" | sudo tee -a "$OUTPUT_FILE" >/dev/null
# echo "# ===========================" | sudo tee -a "$OUTPUT_FILE" >/dev/null

# for svc in "${NODEPORTS[@]}"; do
#     NAME=$(echo "$svc" | awk '{print $1}')
#     PORT=$(echo "$svc" | awk '{print $2}')

#     echo "" | sudo tee -a "$OUTPUT_FILE" >/dev/null
#     echo "frontend ${NAME}-frontend" | sudo tee -a "$OUTPUT_FILE" >/dev/null
#     echo "    bind ${LB_IP}:${PORT}" | sudo tee -a "$OUTPUT_FILE" >/dev/null
#     echo "    default_backend ${NAME}-backend" | sudo tee -a "$OUTPUT_FILE" >/dev/null

#     echo "backend ${NAME}-backend" | sudo tee -a "$OUTPUT_FILE" >/dev/null
#     echo "    balance roundrobin" | sudo tee -a "$OUTPUT_FILE" >/dev/null

#     for entry in "${CONTROL_PLANES[@]}"; do
#         NODE_IP=$(echo "$entry" | awk '{print $2}')
#         echo "    server ${NAME}-${NODE_IP} ${NODE_IP}:${PORT} check" | sudo tee -a "$OUTPUT_FILE" >/dev/null
#     done
# done
