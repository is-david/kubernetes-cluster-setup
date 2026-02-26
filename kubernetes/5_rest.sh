# check etcd cluster health
sudo etcdctl --endpoints=https://10.0.1.21:2379,https://10.0.1.22:2379,https://10.0.1.23:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health --cluster

# Install calico on control 1
kubectl  apply --server-side -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# on control 2 and 3
# You can now join any number of control-plane nodes running the following command on each as root:

sudo kubeadm join 10.0.1.5:6443 --token abcdef.123456789 --discovery-token-ca-cert-hash sha256:abc... --control-plane --certificate-key abc... --ignore-preflight-errors=Mem

# Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
# As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
# "kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

# On worker nodes, you can join the cluster with:
# Then you can join any number of worker nodes by running the following on each as root:

sudo kubeadm join 10.0.1.5:6443 --token abcdef.123456789 --discovery-token-ca-cert-hash sha256:abc... --ignore-preflight-errors=Mem
