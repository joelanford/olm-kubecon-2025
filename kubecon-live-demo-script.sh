#!/usr/bin/env bash

# installing demo ClusterCatalog
vim manifests/00_clustercatalog.yaml
kubectl apply -f manifests/00_clustercatalog.yaml

# installing demo namespaces (install|watch), service accounts
vim manifests/01_clusterextension-setup.yaml
kubectl apply -f manifests/01_clusterextension-setup.yaml

# installing demo ClusterExtension, pinned to v0.0.1, watching namespace 'demo'
vim manifests/02_clusterextension-v0.0.1.yaml
kubectl apply -f manifests/02_clusterextension-v0.0.1.yaml

# inspecting the demo catalog, extension, and revisions
kubectl describe clustercatalog olm-kubecon2025-demo
kubectl describe clusterextension demo-operator
kubectl get clusterextensionrevisions

# checking the olm.targetNamespaces annotation of the deployment
kubectl get deployments.apps -n demo-operator webhook-operator-controller-manager -o jsonpath={.spec.template.metadata.annotations} | jq | grep "olm.targetNamespaces"

# upgrading demo ClusterExtension to v0.0.2, with invalid configuration
vim manifests/03_clusterextension-v0.0.2-broken.yaml
kubectl apply -f manifests/03_clusterextension-v0.0.2-broken.yaml
kubectl get clusterextension demo-operator -o yaml | yq '.status.conditions[] | select(.type=="Progressing")'

#  ... oops!  We forgot to remove the watch namespace!  Fix that
vim manifests/04_clusterextension-v0.0.2-fixed.yaml
kubectl apply -f manifests/04_clusterextension-v0.0.2-fixed.yaml

# final status
kubectl get clusterextension demo-operator
kubectl get clusterextensionrevisions

# checking the installed webhook configurations
kubectl describe validatingwebhookconfigurations.admissionregistration.k8s.io -l olm.operatorframework.io/owner=demo-operator | sed -n '/Ca Bundle:/,/Port:/p'
kubectl describe mutatingwebhookconfigurations.admissionregistration.k8s.io -l olm.operatorframework.io/owner=demo-operator | sed -n '/Ca Bundle:/,/Port:/p'
kubectl describe crd webhooktests.webhook.operators.coreos.io | sed -n '/Ca Bundle:/,/Port:/p'

# demonstrating webhook behavior: invalid CRs are rejected with an error (expected)
vim samples/invalid.yaml
kubectl apply -f samples/invalid.yaml

# installing a valid CR which should get accepted and succeed
vim samples/valid.yaml
kubectl apply -f samples/valid.yaml

# showing the conversion webhook from v1 to v2 works as expected
kubectl get webhooktests.v1.webhook.operators.coreos.io valid -o yaml
kubectl get webhooktests.v2.webhook.operators.coreos.io valid -o yaml

# inspecting the diff between two ClusterExtensionRevisions (CERs) and comparing the RBAC
diff -u --color=always <(kubectl get clusterextensionrevision demo-operator-1 -o yaml | yq e '.spec.phases[] | select(.name=="rbac") | .objects[].object | "\(.kind)/\(.metadata.name) \(.rules | tojson)"' -) <(kubectl get clusterextensionrevision demo-operator-2 -o yaml | yq e '.spec.phases[] | select(.name=="rbac") | .objects[].object | "\(.kind)/\(.metadata.name) \(.rules | tojson)"' -)

# Entire ownership tree (requires krew plugin 'tree')
kubectl tree clusterextensions demo-operator -A

# Show what's installed (requires krew plugin 'get-all')
kubectl get-all -l olm.operatorframework.io/owner=demo-operator

# uninstall: deleting the ClusterExtension
kubectl delete clusterextension demo-operator --wait=true --timeout=60s

# Show that nothing is installed anymore (requires krew plugin 'get-all')
kubectl get-all -l olm.operatorframework.io/owner=demo-operator
