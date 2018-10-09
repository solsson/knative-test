

KO_DOCKER_REPO=ko.local ko apply -f config/
KO_DOCKER_REPO=ko.local ko apply -f config/buses/stub/
KO_DOCKER_REPO=ko.local ko apply -f pkg/sources/k8sevents/

EVENTING_DOCS_REF=26d3de54de5faef7209de007a649304ae284dacc
curl -SLs https://github.com/knative/docs/raw/$EVENTING_DOCS_REF/eventing/samples/k8s-events/serviceaccount.yaml | kubectl apply -f -

mkdir sample-k8sevents
curl -o sample-k8sevents/Dockerfile -SLs https://github.com/knative/docs/raw/$EVENTING_DOCS_REF/eventing/samples/k8s-events/Dockerfile

Had to mod the build a bit
```
cat <<EOF > sample-k8sevents/Dockerfile
FROM golang:1.11.1@sha256:4400859267b8837d7d94d4cf0c85562984ab5159d75413c23eb2f60caac0d4e4 AS builder

WORKDIR /go/src/github.com/knative/docs/

RUN go get -v "k8s.io/api/core/v1"
RUN go get -v "github.com/knative/eventing/pkg/event"

ADD https://github.com/knative/docs/raw/$EVENTING_DOCS_REF/eventing/samples/k8s-events/function.go /go/src/github.com/knative/docs/eventing/samples/k8s-events/function.go

RUN CGO_ENABLED=0 go build ./eventing/samples/k8s-events

FROM gcr.io/distroless/base

COPY --from=builder /go/src/github.com/knative/docs/k8s-events /sample

ENTRYPOINT ["/sample"]
EXPOSE 8080
EOF
```

docker build -t knative-local-registry:5000/eventing-samples/k8sevents sample-k8sevents/
# Must be pushed (on minikube as well) because serving looks up revisions
docker push knative-local-registry:5000/eventing-samples/k8sevents

curl -o sample-k8sevents/function.yaml -SLs https://github.com/knative/docs/raw/$EVENTING_DOCS_REF/eventing/samples/k8s-events/function.yaml
curl -o sample-k8sevents/flow.yaml -SLs https://github.com/knative/docs/raw/$EVENTING_DOCS_REF/eventing/samples/k8s-events/flow.yaml

### getting image pull error for `sub-[uuid]` replicasets' pods

Possibly because if `imagePullPolicy: Always`?

Take the image digest and retag:
```
docker tag ko.local/receive_adapter-[id] knative-local-registry:5000/knative-eventing/receive_adapter:dev
docker push knative-local-registry:5000/knative-eventing/receive_adapter:dev

kubectl -n default patch eventsources.feeds.knative.dev/k8sevents --type=json -p $"
  [{
    \"op\": \"replace\",
    \"path\": \"/spec/parameters/image\",
    \"value\": \"knative-local-registry:5000/knative-eventing/receive_adapter:dev\"
  }]"
```

Status: the sub pod gets events, but the e2e flow doesn't work

## Github events

```
eval $(minikube docker-env)

FEEDLET_IMG=knative-local-registry:5000/knative-eventing/source-github-feedlet:dev
RECEIVE_ADAPTER_IMG=knative-local-registry:5000/knative-eventing/source-github-receive:dev

KO_DOCKER_REPO=ko.local ko apply -f pkg/sources/github/

KO_TMP=$(kubectl get eventsource.feeds.knative.dev/github -o=jsonpath='{.spec.image}')
docker tag $KO_TMP $FEEDLET_IMG
docker push $FEEDLET_IMG
kubectl -n default patch eventsource.feeds.knative.dev/github --type=json -p $"
  [{
    \"op\": \"replace\",
    \"path\": \"/spec/image\",
    \"value\": \"$FEEDLET_IMG\"
  }]"

KO_TMP=$(kubectl get eventsource.feeds.knative.dev/github -o=jsonpath='{.spec.image}')
docker tag $KO_TMP $RECEIVE_ADAPTER_IMG
docker push $RECEIVE_ADAPTER_IMG
kubectl -n default patch eventsource.feeds.knative.dev/github --type=json -p $"
  [{
    \"op\": \"replace\",
    \"path\": \"/spec/parameters/image\",
    \"value\": \"$RECEIVE_ADAPTER_IMG\"
  }]"

### TODO same receive adapter. We can do the same push and patch as for k8sevents.
```
