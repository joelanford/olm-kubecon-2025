# OLMv1 KubeCon NA 2025 Demo

This repository contains the materials and demonstrations for the OLMv1 presentation at KubeCon NA 2025.

## Demo

![Demo](demo.gif)

[View on asciinema](https://asciinema.org/a/VFakQTsZN75d6b5oY2ZMvmc0o)

## Overview

This demo showcases feature functionality added since the 1.0 release of OLMv1, including:

- **SingleNamespace/OwnNamespace InstallMode** support for registry+v1 bundles
- **Webhook support** for registry+v1 bundles
- **Phased installation/upgrade** approaches using ClusterExtensionRevision API

## Repository Structure

### `bundles/`

Bundle manifests for multiple versions of a demo operator, showcasing registry+v1 support in OLMv1 for webhooks and SingleNamespace/OwnNamespace InstallModes.

Contains:
- `demo-operator.v0.0.1` - Supports only SingleNamespace/OwnNamespace InstallMode
- `demo-operator.v0.0.2` - Supports only AllNamespaces InstallMode
- Dockerfiles for building the bundle images

### `catalog/`

File-Based Catalog upgrade graph for the demo-operator package, including:
- Catalog metadata and structure
- `catalog.Dockerfile` for building the catalog image

### `manifests/`

Kubernetes manifests for executing the demo:

| File | Description |
|------|-------------|
| `00_clustercatalog.yaml` | ClusterCatalog manifest containing the demo-operator package |
| `01_clusterextension-setup.yaml` | Namespaces, ServiceAccounts, and support resources |
| `02_clusterextension-v0.0.1.yaml` | Initial installation (v0.0.1) of the demo-operator |
| `03_clusterextension-v0.0.2-broken.yaml` | Upgrade to v0.0.2 with incorrect Single/OwnNamespace configuration |
| `04_clusterextension-v0.0.2-fixed.yaml` | Upgrade to v0.0.2 with corrected AllNamespaceMode configuration |

### `samples/`

Sample resources demonstrating webhook functionality:

- `invalid.yaml` - Demonstrates admission prevention for noncompliant CRs
- `valid.yaml` - Demonstrates webhook success with compliant CRs

### Scripts

- **`setup.sh`** - Sets up the local environment (kind cluster, registry, and OLMv1)
- **`kubecon-demo-script.sh`** - Main demo script showcasing OLMv1 features
- **`generate-asciidemo.sh`** - Processes the demo script into an asciicast format

## Prerequisites

Before running the demo, ensure you have the following tools installed:

- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [skopeo](https://github.com/containers/skopeo/blob/main/install.md)
- [krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) with the following plugins:
  - `tree` - Install with: `kubectl krew install tree`
  - `get-all` - Install with: `kubectl krew install get-all`

## Getting Started

### 1. Environment Setup

Run the setup script to create a local kind cluster with OLMv1 and a local image registry:

```bash
./setup.sh
```

This script will:
- Create a kind cluster named `demo`
- Install OLMv1 experimental release (v1.6.0)
- Set up a local Docker registry (`kind-registry:5443`) with TLS certificates
- Configure containerd to use the local registry
- Build and push demo operator bundles and catalog images to the local registry
- Copy required base images to the local registry

### 2. Run the Demo

Once setup is complete, run the demo script:

```bash
./kubecon-demo-script.sh
```

You can also follow the manifests manually in order (`00_*.yaml` through `04_*.yaml`) to see the progression of the demo.

## License

See the LICENSE file for details.
