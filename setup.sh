#!/usr/bin/env bash

set -e

# Configuration
REG_NAME='kind-registry'
REG_PORT='5443'
CLUSTER_NAME='kind'
CERTS_DIR="$(pwd)/registry-certs"

# Clean up
docker rm -f ${REG_NAME}
kind delete cluster --name demo
rm -rf ${CERTS_DIR}

# Create kind cluster
kind create cluster --name demo

# Install OLMv1 experimental release
curl -L -s https://github.com/operator-framework/operator-controller/releases/download/v1.6.0/install-experimental.sh | sed 's/install_default_catalogs=true/install_default_catalogs=false/' | sed 's/60/180/' | bash -s

# Configure containerd to use certs.d directory and skip TLS verification for kind-registry
docker exec -i demo-control-plane sh -c 'cat >> /etc/containerd/config.toml <<EOF

[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = "/etc/containerd/certs.d"
EOF'

docker exec -i demo-control-plane mkdir -p /etc/containerd/certs.d/kind-registry:5443
docker exec -i demo-control-plane sh -c 'cat > /etc/containerd/certs.d/kind-registry:5443/hosts.toml <<EOF
server = "https://kind-registry:5443"

[host."https://kind-registry:5443"]
  skip_verify = true
EOF'

docker exec -i demo-control-plane systemctl restart containerd

# Create directory for certificates
mkdir -p ${CERTS_DIR}

# Create namespace and Certificate using cert-manager
kubectl create namespace registry --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: registry-tls
  namespace: registry
spec:
  secretName: registry-tls
  issuerRef:
    name: olmv1-ca
    kind: ClusterIssuer
  dnsNames:
    - localhost
    - kind-registry
  ipAddresses:
    - 127.0.0.1
  privateKey:
    algorithm: RSA
    size: 4096
EOF

# Wait for certificate to be ready
echo "Waiting for certificate to be issued..."
kubectl wait --for=condition=Ready certificate/registry-tls -n registry --timeout=60s

# Extract certificate and key from the secret
kubectl get secret registry-tls -n registry -o jsonpath='{.data.tls\.crt}' | base64 -d > ${CERTS_DIR}/domain.crt
kubectl get secret registry-tls -n registry -o jsonpath='{.data.tls\.key}' | base64 -d > ${CERTS_DIR}/domain.key

# Create registry and attach to the kind network
docker run -d --restart=always \
  -p "127.0.0.1:${REG_PORT}:5443" \
  -v ${CERTS_DIR}:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:5443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  --name "${REG_NAME}" \
  registry:3

sleep 3

docker network connect "kind" "${REG_NAME}"

# Copy runnable images to local registry
REGISTRY="localhost:${REG_PORT}"
skopeo copy docker://gcr.io/kubebuilder/kube-rbac-proxy:v0.5.0 docker://${REGISTRY}/kubebuilder/kube-rbac-proxy:v0.5.0 --dest-tls-verify=false
skopeo copy docker://quay.io/olmtest/webhook-operator:0.0.3 docker://${REGISTRY}/olmtest/webhook-operator:0.0.3 --dest-tls-verify=false --override-os=linux
skopeo copy docker://quay.io/olmtest/webhook-operator:v0.0.5 docker://${REGISTRY}/olmtest/webhook-operator:v0.0.5 --dest-tls-verify=false --override-os=linux

# Build and push images to local registry
docker build -t ${REGISTRY}/olm-kubecon2025-demo:bundle-v0.0.1 -f ./bundles/demo-operator.v0.0.1.Dockerfile ./bundles
docker build -t ${REGISTRY}/olm-kubecon2025-demo:bundle-v0.0.2 -f ./bundles/demo-operator.v0.0.2.Dockerfile ./bundles
docker build -t ${REGISTRY}/olm-kubecon2025-demo:catalog -f ./catalog.Dockerfile .

docker push ${REGISTRY}/olm-kubecon2025-demo:bundle-v0.0.1
docker push ${REGISTRY}/olm-kubecon2025-demo:bundle-v0.0.2
docker push ${REGISTRY}/olm-kubecon2025-demo:catalog

# build demo
#./generate-asciidemo.sh -u -n "kubecon-na-2025" kubecon-demo-script.sh
