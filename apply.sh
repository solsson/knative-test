
kubectl apply -f 01-istio/

kubectl wait -n istio-system deploy/istio-pilot --for condition=available

kubectl apply -f 02-serving/

kubectl wait -n knative-serving deploy/knative-ingressgateway --for condition=available
kubectl wait -n knative-serving deploy/activator --for condition=available

kubectl apply -f 03-build/
