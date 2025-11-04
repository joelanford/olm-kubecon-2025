#!/usr/bin/env bash

#
# Welcome to the kubecon-NA 2025 demo
#
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# assumes it's running from a local clone of operator-framework/operator-controller
make -C ../../operator-framework/operator-controller/ run-experimental
sleep 10

# inspect crds (clustercatalog)
kubectl get crds -A
kubectl get clustercatalog -A

echo "checking catalogd controller is available"
kubectl wait --for=condition=Available -n olmv1-system deploy/catalogd-controller-manager --timeout=1m

echo "installing demo ClusterCatalog"
kubectl apply -f manifests/00_clustercatalog.yaml
echo "... checking clustercatalog is serving"
kubectl wait --for=condition=Serving clustercatalog/olm-kubecon2025-demo --timeout=60s
echo "... checking clustercatalog is finished unpacking"
kubectl wait --for=condition=Progressing=True clustercatalog/olm-kubecon2025-demo --timeout=60s

echo "installing demo namespaces (install|watch), service accounts"
kubectl apply -f manifests/01_clusterextension-setup.yaml

echo "installing demo ClusterExtension, pinned to v0.0.1, watching namespace 'demo'"
kubectl apply -f manifests/02_clusterextension-v0.0.1.yaml

echo "upgrading demo ClusterExtension to v0.0.2"
kubectl apply -f manifests/03_clusterextension_v0.0.2-broken.yaml

echo " ... oops!  We forgot to remove the watch namespace"
kubectl apply -f manifests/04_clusterextension_v0.0.2-fixed.yaml

