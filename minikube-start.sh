minikube start --memory=10240 --cpus=4 \
  --kubernetes-version=v1.10.8 \
  --vm-driver=hyperkit \
  --bootstrapper=kubeadm \
  --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
  --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key"
