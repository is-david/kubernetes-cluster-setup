#!/usr/bin/env bash

# Define the list of servers
SERVERS=(control1 control2 control3 etcd1 etcd2 etcd3 kube-api-lb worker1 worker2 operator)

# Starting points for each group
cp_idx=11
etcd_idx=21
worker_idx=31
operator_idx=41

for name in "${SERVERS[@]}"; do
    case $name in
        kube-api-lb) IP="5" ;;
        control*)    IP=$cp_idx; ((cp_idx++)) ;;
        etcd*)       IP=$etcd_idx; ((etcd_idx++)) ;;
        worker*)     IP=$worker_idx; ((worker_idx++)) ;;
        operator*)   IP=$operator_idx; ((operator_idx++)) ;;
    esac

    # 1. Create the VM with the assigned IP
    ./create-vm.sh "$name" "10.0.1.$IP"

    # 2. Setup Netplan
    # Note: Using 'sudo' inside the exec as cloud-init might still be finishing
    echo "Setting up netplan for $name with IP 10.0.1.$IP"
    timeout 30s multipass exec "$name" -- sudo /usr/local/bin/setup-netplan.sh
    
    # 3. Update and upgrade packages to ensure latest security patches
    # echo "Updating and upgrading packages on $name"
    # multipass exec "$name" -- bash -c "sudo apt update && sudo apt upgrade -y"

    # 4. Bounce the VM to ensure network stack is fresh
    echo "Restarting $name to apply network changes"
    multipass stop "$name"
    multipass start "$name"
done