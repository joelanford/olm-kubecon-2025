#!/usr/bin/env bash

docker build -t quay.io/olm-kubecon-demo/olm-kubecon2025-demo:bundle-v0.0.1 -f ./bundles/demo-operator.v0.0.1.Dockerfile ./bundles
docker build -t quay.io/olm-kubecon-demo/olm-kubecon2025-demo:bundle-v0.0.2 -f ./bundles/demo-operator.v0.0.2.Dockerfile ./bundles
docker build -t quay.io/olm-kubecon-demo/olm-kubecon2025-demo:catalog -f ./catalog.Dockerfile .

docker push quay.io/olm-kubecon-demo/olm-kubecon2025-demo:bundle-v0.0.1
docker push quay.io/olm-kubecon-demo/olm-kubecon2025-demo:bundle-v0.0.2
docker push quay.io/olm-kubecon-demo/olm-kubecon2025-demo:catalog
