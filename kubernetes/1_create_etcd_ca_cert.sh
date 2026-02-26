#!/usr/bin/env bash

# clenup
sudo rm -fr /etc/kubernetes/pki/etcd* || true

sudo kubeadm init phase certs etcd-ca

mkdir -p /Shared/kubernetes/etcd-certs || true
sudo cp /etc/kubernetes/pki/etcd/ca.crt /Shared/kubernetes/etcd-certs/ca.crt
sudo cp /etc/kubernetes/pki/etcd/ca.key /Shared/kubernetes/etcd-certs/ca.key