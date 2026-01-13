# Adding a New Cluster

This guide walks through adding a new cluster to the multi-cluster infrastructure.

## Prerequisites

- Access to the cloud provider (OCI, Equinix, etc.)
- Terraform/OpenTofu installed
- `kubectl` and `flux` CLI installed
- Git write access to this repository

## Overview

Adding a new cluster involves:

1. Create terraform cluster directory
2. Create flux overlay with cluster config
3. Create flux cluster directory
4. Deploy with terraform
5. Update DNS/registrar (if needed)

## Step 1: Create Terraform Cluster Directory

```bash
# Create directory
mkdir -p terraform/clusters/new-cluster

# Copy from existing cluster as template
cp terraform/clusters/sharingio-oci/*.tf terraform/clusters/new-cluster/

# Create cluster-specific .envrc
cp terraform/clusters/sharingio-oci/.envrc terraform/clusters/new-cluster/

# Symlink shared tfvars (or create cluster-specific one)
cd terraform/clusters/new-cluster
ln -sf ../../../terraform.tfvars terraform.tfvars
```

### Required Files

**`terraform/clusters/new-cluster/versions.tf`**:

```hcl
terraform {
  required_version = ">= 1.8"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.29"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9.0"
    }
    # ... other providers as needed
  }

  # Remote backend - each cluster needs its own state file
  backend "http" {
    update_method = "PUT"
  }
}
```

**`terraform/clusters/new-cluster/.envrc`**:

```bash
# OCI Object Storage PAR for this cluster's state
export TF_HTTP_ADDRESS="https://....objectstorage.../new-cluster.tfstate"
```

**`terraform/clusters/new-cluster/providers.tf`**:

```hcl
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

provider "kubernetes" {
  alias                  = "cluster"
  host                   = module.cluster.kubeconfig_host
  client_certificate     = base64decode(module.cluster.kubeconfig_client_certificate)
  client_key             = base64decode(module.cluster.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.cluster.kubeconfig_ca_certificate)
}

# ... other providers
```

**`terraform/clusters/new-cluster/main.tf`**:

```hcl
module "cluster" {
  source = "../../modules/talos-cluster/oci"  # or /equinix, etc.

  cluster_name       = "new-cluster"
  domain             = "example.com"
  controlplane_count = 3
  worker_count       = 3

  # Cloud-specific variables
  compartment_ocid = var.compartment_ocid
  region           = var.region
}

module "k8s_bootstrap" {
  source = "../../modules/k8s-bootstrap"

  cluster_name = "new-cluster"
  domain       = "example.com"

  ingress_ip   = module.cluster.cluster_ingress_ip
  dns_ip       = module.cluster.cluster_dns_ip
  wg_ip        = module.cluster.cluster_wireguard_ip
  apiserver_ip = module.cluster.cluster_apiserver_ip

  admin_email = var.admin_email

  # App versions (or use defaults from module)
  coder_version     = var.coder_version
  authentik_version = var.authentik_version

  providers = {
    kubernetes = kubernetes.cluster
  }
}

# Flux GitOps bootstrap
resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux - new-cluster"
  repository = var.github_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.this, module.k8s_bootstrap]

  embedded_manifests = true
  path               = "flux/clusters/new-cluster"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}
```

**`terraform/clusters/new-cluster/variables.tf`**:

```hcl
# OCI Authentication
variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "tenancy_ocid" {
  type      = string
  sensitive = true
}

# ... other auth variables

# Cluster identity
variable "domain" {
  type    = string
  default = "example.com"
}

variable "admin_email" {
  description = "Admin email for ACME and bootstrap accounts"
  type        = string
  default     = "admin@example.com"
}

# Application versions
variable "coder_version" {
  type    = string
  default = "v2.16.0"
}

variable "authentik_version" {
  type    = string
  default = "2024.4.0"
}
```

**`terraform/clusters/new-cluster/outputs.tf`**:

```hcl
output "kubeconfig" {
  value     = module.cluster.kubeconfig
  sensitive = true
}

output "cluster_ips" {
  description = "Reserved IPs for DNS configuration"
  value = {
    dns       = module.cluster.cluster_dns_ip
    ingress   = module.cluster.cluster_ingress_ip
    wireguard = module.cluster.cluster_wireguard_ip
    apiserver = module.cluster.cluster_apiserver_ip
  }
}
```

## Step 2: Create Flux Overlay

```bash
mkdir -p flux/overlays/new-cluster
```

**`flux/overlays/new-cluster/cluster-config.yaml`**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-config
  namespace: flux-system
data:
  # Cluster identity
  CLUSTER_NAME: "new-cluster"
  DOMAIN: "example.com"

  # App hostnames
  CODER_HOST: "coder.example.com"
  CODER_WILDCARD_DOMAIN: "coder.example.com"
  AUTHENTIK_HOST: "sso.example.com"

  # Versions
  CODER_VERSION: "v2.16.0"
  AUTHENTIK_VERSION: "2024.4.0"

  # Reserved IPs - fill after terraform apply
  INGRESS_IP: ""
  DNS_IP: ""
  WIREGUARD_IP: ""
  APISERVER_IP: ""
```

**`flux/overlays/new-cluster/kustomization.yaml`**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - cluster-config.yaml
  - ../../bases/controllers
  - ../../bases/apps
  - ../../bases/configs
```

## Step 3: Create Flux Cluster Directory

```bash
mkdir -p flux/clusters/new-cluster
```

**`flux/clusters/new-cluster/cluster-config.yaml`**:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cluster-config
  namespace: flux-system
spec:
  interval: 1m0s
  path: ./flux/overlays/new-cluster
  prune: false
  sourceRef:
    kind: GitRepository
    name: flux-system
```

**`flux/clusters/new-cluster/infrastructure.yaml`**:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infrastructure
  namespace: flux-system
spec:
  interval: 1m0s
  dependsOn:
    - name: cluster-config
  path: ./flux/bases/controllers
  prune: true
  wait: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-config
```

**`flux/clusters/new-cluster/configs.yaml`**:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: configs
  namespace: flux-system
spec:
  interval: 1m0s
  dependsOn:
    - name: cluster-config
  path: ./flux/bases/configs
  prune: true
  wait: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-config
      - kind: ConfigMap
        name: cluster-ips
```

**`flux/clusters/new-cluster/apps.yaml`**:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 1m0s
  dependsOn:
    - name: cluster-config
    - name: infrastructure
  path: ./flux/bases/apps
  prune: true
  wait: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-config
```

## Step 4: Deploy with Terraform

### Create State Backend

For OCI HTTP backend, create a new PAR for this cluster's state:

```bash
oci os preauth-request create \
  --bucket-name sharingio-tfstate \
  --namespace axe608t7iscj \
  --name new-cluster-state-rw \
  --access-type ObjectReadWrite \
  --time-expires $(date -d "+365 days" +%Y-%m-%dT%H:%M:%SZ) \
  --object-name new-cluster.tfstate
```

Update `terraform/clusters/new-cluster/.envrc` with the PAR URL from the output.

### Initialize and Apply

```bash
cd terraform/clusters/new-cluster

# Source environment (sets TF_HTTP_ADDRESS)
source .envrc
# Or if using direnv: direnv allow

# The terraform.tfvars symlink should already point to shared secrets
# Or create cluster-specific tfvars if needed

# Initialize terraform
tofu init

# Review plan
tofu plan

# Apply
tofu apply
```

### Update Cluster Config with IPs

After apply, get the reserved IPs:

```bash
tofu output cluster_ips
```

Update `flux/overlays/new-cluster/cluster-config.yaml` with the actual IPs.

## Step 5: Commit and Push

```bash
cd /path/to/infra

git add flux/overlays/new-cluster/
git add flux/clusters/new-cluster/
git add terraform/clusters/new-cluster/

git commit -m "Add new-cluster infrastructure"
git push origin main
```

Flux will automatically bootstrap and reconcile.

## Step 6: DNS Configuration (Optional)

If this cluster needs its own domain/subdomain:

### Update Registrar

Add NS records pointing to the cluster's DNS IP.

### Configure DNS Server

Add zones in Technitium or your DNS server:
- `example.com` → ingress IP
- `*.example.com` → ingress IP
- `ns.example.com` → dns IP
- `k8s.example.com` → apiserver IP

## Verification

```bash
# Check Flux status
flux get kustomizations

# Check all resources
kubectl get all -A

# Check HelmReleases
kubectl get helmreleases -A
```

## Cluster-Specific Customizations

### Adding Patches

Create patches in the overlay:

```bash
mkdir flux/overlays/new-cluster/patches
```

**`flux/overlays/new-cluster/patches/coder-replicas.yaml`**:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: coder
  namespace: flux-system
spec:
  values:
    coder:
      replicaCount: 5
```

Update kustomization.yaml:

```yaml
patches:
  - path: patches/coder-replicas.yaml
    target:
      kind: HelmRelease
      name: coder
```

### Disabling Components

To skip certain apps for this cluster, use patches to suspend them:

```yaml
# flux/overlays/new-cluster/patches/disable-rook.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: rook-ceph
  namespace: flux-system
spec:
  suspend: true
```

## Troubleshooting

### Flux Not Reconciling

```bash
# Check source
flux get sources git

# Force reconcile
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

### ConfigMap Not Found

The cluster-config Kustomization must complete before other Kustomizations. Check dependencies:

```bash
kubectl get kustomizations -n flux-system
```

### HelmRelease Failures

```bash
# Get details
kubectl describe helmrelease <name> -n flux-system

# Check helm history
helm history <release-name> -n <namespace>
```

## Directory Structure Summary

After adding a new cluster:

```
infra/
├── terraform.tfvars             # Shared secrets (gitignored)
│
├── terraform/
│   ├── modules/                 # Shared modules
│   │   ├── talos-cluster/oci/
│   │   └── k8s-bootstrap/
│   │
│   └── clusters/
│       ├── sharingio-oci/       # Existing cluster
│       │   ├── .envrc
│       │   ├── versions.tf
│       │   ├── providers.tf
│       │   ├── main.tf
│       │   └── ...
│       │
│       └── new-cluster/         # New cluster
│           ├── .envrc           # TF_HTTP_ADDRESS for this cluster
│           ├── versions.tf      # Provider requirements + backend
│           ├── providers.tf     # Provider configurations
│           ├── main.tf          # Module calls
│           ├── variables.tf
│           ├── locals.tf
│           ├── outputs.tf
│           ├── dns.tf           # DNS records
│           └── terraform.tfvars -> ../../../terraform.tfvars
│
└── flux/
    ├── bases/                   # Shared (unchanged)
    │   ├── apps/
    │   ├── configs/
    │   └── controllers/
    │
    ├── overlays/
    │   ├── sharingio-oci/       # Existing cluster
    │   └── new-cluster/         # New cluster
    │       ├── cluster-config.yaml
    │       ├── kustomization.yaml
    │       └── patches/         # Optional
    │
    └── clusters/
        ├── cluster-sharingio-oci/   # Existing
        └── cluster-new-cluster/     # New cluster
            ├── cluster-config.yaml  # Flux Kustomization for overlay
            ├── infrastructure.yaml
            ├── configs.yaml
            ├── apps.yaml
            └── flux-system/         # Created by flux bootstrap
```
