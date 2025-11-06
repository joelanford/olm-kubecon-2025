# This is a purpose-build repository to capture the stages and prerequites for the team's presentation to kubecon NA 2025. 

# Structure:

## bundles

This directory includes bundle manifests for a couple of versions of a demo operator, to showcase registry+v1 support in OLMv1 for webhooks and SingleNamespace/OwnNamespace InstallModes. 

containing:
- demo-operator.v0.0.1 which only supports SingleNamespace/OwnNamespace InstallMode 
- demo-operator.v0.0.2 which only supports AllNamespaces InstallMode
- dockerfiles for building the bundle images

## catalog

This directory contains the File-Based Catalog upgrade graph for the demo-operator package
(plus the associated catalog.Dockerfile to build the catalog image)

## generate-asciidemo.sh

A script to process the kubecon-demo-script.sh into an asciicast

## kubecon-demo-script.sh

A script to demonstrate some feature functionality since our 1.0 release of OLMv1, including
- SingleNamespace/OwnNamespace InstallMode support for registry+v1 bundles
- Webhook support for registry+v1 bundles
- phased installation / upgrade approaches using ClusterExtensionRevision API

## manifests

Containing manifests for navigating the demo execution
- 00_clustercatalog.yaml: stamping out the ClusterCatalog manifest containing the demo-operator package
- 01_clusterextension-setup.yaml: stamping out the Namespaces, ServiceAccounts, and support resources
- 02_clusterextension-v0.0.1.yaml: installing the initial version (v0.0.1) of the demo-operator
- 03_clusterextension-v0.0.2-broken.yaml: installing the upgraded version (v0.0.2) of the demo-operator, but with the Single/OwnNamespace configuration still in-place
- 04_clusterextension-v0.0.2-fixed.yaml: installing the upgraded version (v0.0.2) of the demo-operator, with corrected AllNamespaceMode configuration

## samples

Containing samples of resources demonstrating webhook functionality:
- invalid.yaml: demonstrating that admission is prevented successfully for noncompliant CRs
- valid.yaml: demonstrating webhook success with compliant CRs


## DEMO
[https://asciinema.org/a/754187](https://asciinema.org/a/754187)
