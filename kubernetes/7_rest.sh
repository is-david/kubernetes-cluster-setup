# check etcd cluster health
sudo etcdctl --endpoints=https://10.0.1.21:2379,https://10.0.1.22:2379,https://10.0.1.23:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health --cluster

# Install calico on control 1
kubectl  apply --server-side -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

