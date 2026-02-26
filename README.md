# kubernetes-cluster-setup
Scripts for deploying a high‑availability Kubernetes cluster with an external HA etcd cluster and multiple control‑plane nodes, using Multipass VMs for training and learning purposes. The workflow is designed for a Windows environment using MobaXterm as the terminal and Multipass as the VM manager.
## Requirements
- MobaXterm (Windows terminal + SSH client): https://mobaxterm.mobatek.net/
- Multipass (lightweight VM manager by Canonical): https://multipass.run/
## Repository structure
- vm-init/ — scripts to create and configure all required VMs
- kubernetes/ — scripts to deploy etcd, control-plane nodes, workers, and supporting components
## Usage
- Create all VMs using the scripts in the vm-init/ directory.
- Deploy the Kubernetes cluster using the scripts in the kubernetes/ directory.
