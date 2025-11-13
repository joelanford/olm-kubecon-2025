#!/usr/bin/env bash

#
# Welcome to the kubecon-NA 2025 demo
#
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# installing demo ClusterCatalog
kubectl apply -f manifests/00_clustercatalog.yaml

#  checking clustercatalog is serving
kubectl wait --for=condition=Serving clustercatalog/olm-kubecon2025-demo --timeout=60s

# inspecting the demo catalog
kubectl describe clustercatalog olm-kubecon2025-demo

# installing demo namespaces (install|watch), service accounts
kubectl apply -f manifests/01_clusterextension-setup.yaml

# installing demo ClusterExtension, pinned to v0.0.1, watching namespace 'demo'
kubectl apply -f manifests/02_clusterextension-v0.0.1.yaml

# waiting for demo-operator.v0.0.1 to report Installed=True
kubectl wait --for=condition=Installed clusterextension/demo-operator --timeout=180s

# checking status on demo-operator.v0.0.1
kubectl get clusterextensions.olm.operatorframework.io demo-operator -o yaml | yq '.spec'
kubectl get clusterextensions.olm.operatorframework.io demo-operator -o yaml | yq '.status.conditions[]| select(.type == "Installed")'

# checking ClusterExtensionRevision (CER) after install
kubectl get clusterextensionrevision -A

# checking the olm.targetNamespaces annotation of the deployment
kubectl get deployments.apps -n demo-operator webhook-operator-controller-manager -o jsonpath={.spec.template.metadata.annotations} | jq | grep "olm.targetNamespaces"

# upgrading demo ClusterExtension to v0.0.2, with a broken manifest
kubectl apply -f manifests/03_clusterextension-v0.0.2-broken.yaml
sleep 5
kubectl get clusterextension demo-operator -o yaml | yq '.status.conditions[] | select(.type=="Progressing")'

#  ... oops!  We forgot to remove the watch namespace!  Fix that
kubectl apply -f manifests/04_clusterextension-v0.0.2-fixed.yaml

#  status after demo-operator.v0.0.2 fixed installation
kubectl wait --for=jsonpath='{.status.install.bundle.name}="demo-operator.v0.0.2"' clusterextension demo-operator --timeout=30s
kubectl wait --for=condition=Installed clusterextension/demo-operator --timeout=180s

#  ... fixed!
kubectl get clusterextension demo-operator -o yaml | yq '.status.conditions[] | select(.type=="Installed")'

# final status
kubectl get clusterextension demo-operator
kubectl get clusterextensionrevisions

# demonstrating webhook behavior: invalid CRs are rejected with an error (expected)
kubectl apply -f samples/invalid.yaml || true

# installing a valid CR which should get accepted and succeed
kubectl apply -f samples/valid.yaml

# inspecting the diff between two ClusterExtensionRevisions (CERs) and comparing the RBAC
diff -u --color=always <(kubectl get clusterextensionrevision demo-operator-1 -o yaml | yq e '.spec.phases[] | select(.name=="rbac") | .objects[].object | "\(.kind)/\(.metadata.name) \(.rules | tojson)"' -) <(kubectl get clusterextensionrevision demo-operator-2 -o yaml | yq e '.spec.phases[] | select(.name=="rbac") | .objects[].object | "\(.kind)/\(.metadata.name) \(.rules | tojson)"' -)

# checking the installed validating webhook configuration
kubectl describe validatingwebhookconfigurations.admissionregistration.k8s.io -l olm.operatorframework.io/owner=demo-operator | sed -n '/Ca Bundle:/,/Port:/p'

# checking the installed mutating webhook configuration
kubectl describe mutatingwebhookconfigurations.admissionregistration.k8s.io -l olm.operatorframework.io/owner=demo-operator | sed -n '/Ca Bundle:/,/Port:/p'

# checking the conversion webhook configuration in the CRD
kubectl describe crd webhooktests.webhook.operators.coreos.io | sed -n '/Ca Bundle:/,/Port:/p'

# showing the mutation webhook has inserted mutate: true
kubectl get webhooktests.v1.webhook.operators.coreos.io valid -o yaml

# showing the conversion webhook has moved .spec fields to .spec.conversion
kubectl get webhooktests.v2.webhook.operators.coreos.io valid -o yaml

# showing the entire ownership tree (requires krew plugin 'tree')
kubectl tree clusterextensions demo-operator -A

# showing what's installed (requires krew plugin 'get-all')
kubectl get-all -l olm.operatorframework.io/owner=demo-operator

# uninstall: deleting the ClusterExtension
kubectl delete clusterextension demo-operator --wait=true --timeout=60s

# showing that nothing is installed anymore (requires krew plugin 'get-all')
kubectl get-all -l olm.operatorframework.io/owner=demo-operator

# leave data on screen for a moment before looping anew
sleep 5
