# Configuration Layering

This document describes how versions, configuration values, and secrets flow through the infrastructure layers.

## Overview

Configuration follows a three-tier model:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Configuration Layers                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Defaults (Terraform variables, Flux bases)            │
│  ├─ Location: variables.tf, flux/bases/                         │
│  ├─ Contents: Default versions, base helm values                │
│  └─ Override: terraform.tfvars, -var flags                      │
│                                                                  │
│  Layer 2: Cluster Config (Git/Flux + Terraform)                 │
│  ├─ Location: flux/overlays/{cluster}/, terraform apply         │
│  ├─ Contents: IPs, domains, cluster-specific versions           │
│  └─ Override: Edit overlay files, rerun terraform               │
│                                                                  │
│  Layer 3: Runtime Override ({app}-override ConfigMaps)          │
│  ├─ Location: Kubernetes ConfigMaps/Secrets                     │
│  ├─ Contents: Debug flags, temporary tuning                     │
│  └─ Override: kubectl edit, operator RBAC                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Layer 1: Defaults

### Terraform Variables

Application versions defined in `variables.tf`:

```hcl
variable "coder_version" {
  description = "Version of coder from https://github.com/coder/coder/releases/"
  type        = string
  default     = "v2.16.0"
}

variable "authentik_version" {
  description = "Version of authentik from https://github.com/goauthentik/authentik/releases/"
  type        = string
  default     = "2024.4.0"
}
```

Override via:
- `terraform.tfvars` file
- Command line: `tofu apply -var coder_version=v2.17.0`
- Environment: `TF_VAR_coder_version=v2.17.0`

### Flux Bases (Hardcoded Versions)

Controller versions hardcoded in `flux/bases/controllers/`:

| Component | File | Current Version |
|-----------|------|-----------------|
| cert-manager | `cert-manager/cert-manager.yaml` | 1.14.4 |
| ingress-nginx | `ingress-nginx/ingress-nginx.yaml` | 4.10.0 |
| longhorn | `longhorn/longhorn.yaml` | 1.7.1 |
| rook-ceph | `rook-ceph/rook-ceph.yaml` | 1.13.5 |
| redis-operator | `redis-operator/redis-operator.yaml` | 0.18.3 |
| reflector | `reflector/reflector.yaml` | 7.1.262 |

To update: Edit the YAML file and commit to Git.

## Layer 2: Cluster Configuration

### Terraform → ConfigMaps

Terraform creates ConfigMaps that Flux uses for substitution:

```hcl
# terraform/modules/k8s-bootstrap/coder.tf
resource "kubernetes_config_map" "coder_kustomize" {
  metadata {
    name      = "coder-kustomize"
    namespace = "flux-system"
  }
  data = {
    CODER_VERSION     = var.coder_version
    CODER_HOST        = "coder.${var.domain}"
    CODER_ACCESS_URL  = "https://coder.${var.domain}"
  }
}
```

### Flux PostBuild Substitution

Flux Kustomizations reference ConfigMaps for variable substitution:

```yaml
# flux/bases/apps/coder.yaml
spec:
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: coder-kustomize
      - kind: ConfigMap
        name: cluster-config
```

Variables are substituted using `${VARIABLE_NAME}` syntax:

```yaml
# flux/bases/apps/coder/helm-release.yaml
spec:
  chart:
    spec:
      chart: coder
      version: "${CODER_VERSION}"  # Substituted from ConfigMap
```

### Cluster Overlay ConfigMap

Per-cluster values in `flux/overlays/{cluster}/cluster-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-config
  namespace: flux-system
data:
  CLUSTER_NAME: "sharingio"
  DOMAIN: "sharing.io"
  INGRESS_IP: "144.24.33.179"
  CODER_HOST: "coder.sharing.io"
```

## Layer 3: Runtime Overrides

### Override ConfigMaps/Secrets

Terraform creates empty override resources with `lifecycle.ignore_changes`:

```hcl
# terraform/modules/k8s-bootstrap/coder.tf
resource "kubernetes_config_map" "coder_override" {
  metadata {
    name      = "coder-override"
    namespace = "coder"
    annotations = {
      "config.ii.coop/options" = <<-EOT
        Available overrides:
        CODER_LOG_LEVEL: trace|debug|info|warn|error
        CODER_VERBOSE: true|false
        CODER_EXPERIMENTS: comma-separated features
      EOT
    }
  }
  data = {}  # Empty by default

  lifecycle {
    ignore_changes = [data]  # Allow runtime modifications
  }
}
```

### How Apps Consume Overrides

HelmRelease values reference all config layers:

```yaml
# flux/bases/apps/coder/helm-release.yaml
spec:
  values:
    coder:
      envFrom:
        - configMapRef:
            name: coder-config      # Base config (terraform)
        - secretRef:
            name: coder-config      # Base secrets (terraform)
        - configMapRef:
            name: coder-override    # Runtime overrides
            optional: true
        - secretRef:
            name: coder-override    # Runtime secret overrides
            optional: true
```

### RBAC for Override Editing

The `claude-operator` role can edit override resources:

```yaml
# flux/bases/configs/claude-system.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: claude-override-editor
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames:
      - "authentik-override"
      - "coder-override"
      - "tunneld-override"
      - "longhorn-override"
      - "cert-manager-override"
    verbs: ["get", "list", "watch", "update", "patch"]
```

## Value Flow Diagram

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  variables.tf    │     │ terraform.tfvars │     │   -var flags     │
│  (defaults)      │ ←── │ (cluster values) │ ←── │  (CLI override)  │
└────────┬─────────┘     └──────────────────┘     └──────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  terraform/modules/k8s-bootstrap/                                │
│  Creates: ConfigMaps, Secrets, Override resources                │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  Kubernetes ConfigMaps (flux-system namespace)                   │
│  - coder-kustomize: {CODER_VERSION, CODER_HOST, ...}            │
│  - authentik-kustomize: {AUTHENTIK_VERSION, ...}                │
│  - cluster-config: {DOMAIN, INGRESS_IP, ...}                    │
│  - cluster-ips: {DNS_IP, WIREGUARD_IP, ...}                     │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  Flux Kustomization (postBuild.substituteFrom)                   │
│  Substitutes ${VARIABLE} in YAML files                          │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  HelmRelease                                                     │
│  - chart.spec.version: "${CODER_VERSION}" → "v2.16.0"           │
│  - values.coder.envFrom: [coder-config, coder-override]         │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  Running Pod                                                     │
│  Environment variables from all ConfigMaps/Secrets merged       │
│  Later sources override earlier (override wins)                 │
└──────────────────────────────────────────────────────────────────┘
```

## What Goes Where

| Value Type | Layer | Location | Example |
|------------|-------|----------|---------|
| App version (parameterized) | 1 | `variables.tf` | `coder_version = "v2.16.0"` |
| Controller version (hardcoded) | 1 | `flux/bases/controllers/*/` | `version: 1.14.4` |
| Domain, IPs | 2 | `flux/overlays/{cluster}/cluster-config.yaml` | `DOMAIN: sharing.io` |
| App credentials | 2 | Terraform → K8s Secrets | `CODER_PG_CONNECTION_URL` |
| Debug flags | 3 | `{app}-override` ConfigMap | `CODER_VERBOSE: "true"` |
| Temporary secrets | 3 | `{app}-override` Secret | `DEBUG_API_KEY` |

## Updating Versions

### Parameterized Versions (Coder, Authentik)

```bash
# Option 1: Edit terraform.tfvars
echo 'coder_version = "v2.17.0"' >> terraform.tfvars
tofu apply

# Option 2: Command line
tofu apply -var coder_version=v2.17.0
```

### Hardcoded Versions (Controllers)

```bash
# Edit the HelmRelease file
vim flux/bases/controllers/cert-manager/cert-manager.yaml
# Change: version: 1.14.4 → version: 1.15.0
git add -A && git commit -m "Update cert-manager to 1.15.0"
git push
# Flux auto-reconciles
```

### Runtime Override (Debugging)

```bash
# Edit override ConfigMap directly
kubectl edit configmap coder-override -n coder

# Or patch it
kubectl patch configmap coder-override -n coder \
  --type merge -p '{"data":{"CODER_VERBOSE":"true"}}'
```
