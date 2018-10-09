
minikube version | grep v0.29 && echo "Note: We've had issues with controller-manager crashlooping on Minikube 0.29"
minikube version | grep v0.30 && echo "Note: We've had issues with controller-manager crashlooping on Minikube 0.30"

minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.11.3 \
  --vm-driver=hyperkit \
  --bootstrapper=kubeadm \
  --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
  --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key"
