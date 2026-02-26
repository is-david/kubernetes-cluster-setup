# kubernetes setup
* execute 1_create_etcd_ca_cert.sh on control plane 1 VM
* verify etcd version in 2_etcd_setup.sh script and execute it on all etcd VMs
* execute script 3_haproxy_setup.sh on kube-api-lb VM
* execute script 4_control_plane_1_setup.sh on control plane 1 VM, and note the join instructions for other control plane nodes and worker nodes.
* validate all pods on system namespace are up (except for coredns). install calico as per instructions in 5_rest.sh script
* validate all pods are up
* update scripts 5_rest_of_control_plane_setup.sh and 6_worker_node_setup.sh with token and hash which recieved as join string on control1
* connect the rest of the control planes by executing 5_rest_of_control_plane_setup.sh script on each remaining control plane nodes
* connect worker nodes by executing 6_worker_node_setup.sh script on each remaining worker nodes

