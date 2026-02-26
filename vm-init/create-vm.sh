#!/usr/bin/env bash

server_name=$1
export NODE_IP=$2

envsubst '$NODE_IP' < multipass-init.yaml | multipass launch 24.04 \
  --name $server_name \
  --cpus 2 \
  --memory 2G \
  --disk 10G \
  --network name=multipass,mode=manual \
  --cloud-init -

multipass exec $server_name -- sudo mkdir -p /Shared
multipass mount "c:\Users\admin\multipass" "$server_name:/Shared"
