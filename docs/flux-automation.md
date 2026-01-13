# Flux Automation Capabilities

This document describes Flux's capabilities for monitoring upstream releases and automating updates.

## Overview

Flux can monitor and automate updates from:

| Source Type | Controller | Resource |
|-------------|------------|----------|
| Container Images | Image Reflector + Automation | ImageRepository, ImagePolicy |
| Helm Charts (HTTPS) | Source Controller | HelmRepository |
| Helm Charts (OCI) | Source Controller | HelmRepository (type: oci) |
| Git Repositories | Source Controller | GitRepository |
| S3/GCS Buckets | Source Controller | Bucket |

## Current Setup

The image automation controllers are already installed:

```hcl
# main.tf
resource "flux_bootstrap_git" "this" {
  components_extra = ["image-reflector-controller", "image-automation-controller"]
}
```

## Container Image Monitoring

### ImageRepository

Monitors a container registry for new tags:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: coder
  namespace: flux-system
spec:
  image: ghcr.io/coder/coder
  interval: 1h
  # For private registries:
  # secretRef:
  #   name: ghcr-credentials
```

Supported registries:
- Docker Hub
- GitHub Container Registry (ghcr.io)
- GitLab Container Registry
- AWS ECR
- Google GCR/Artifact Registry
- Azure ACR
- Any OCI-compliant registry

### ImagePolicy

Selects which tags to track based on policies:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: coder
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: coder
  policy:
    semver:
      range: ">=2.0.0 <3.0.0"  # Only 2.x versions
```

Policy options:

```yaml
# Semantic versioning
policy:
  semver:
    range: ">=1.0.0"

# Alphabetical (for date-based tags like 2024.01.15)
policy:
  alphabetical:
    order: asc  # or desc

# Numerical (for build numbers)
policy:
  numerical:
    order: asc  # or desc

# Filter with regex first
filterTags:
  pattern: "^v[0-9]+\\.[0-9]+\\.[0-9]+$"  # Only vX.Y.Z tags
  extract: "$1"
```

### ImageUpdateAutomation

Commits version updates back to Git:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: flux-system
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        name: fluxcdbot
        email: flux@sharing.io
      messageTemplate: |
        Automated image update

        {{range .Changed.Changes}}
        - {{.OldValue}} -> {{.NewValue}}
        {{end}}
    push:
      branch: main  # Direct push
      # Or create PR branch:
      # branch: flux-image-updates
  update:
    path: ./flux
    strategy: Setters
```

### Marking Fields for Update

Use setter comments to mark fields that should be auto-updated:

```yaml
# For container images
spec:
  containers:
    - name: app
      image: ghcr.io/coder/coder:v2.16.0  # {"$imagepolicy": "flux-system:coder"}

# For just the tag
spec:
  values:
    image:
      tag: "v2.16.0"  # {"$imagepolicy": "flux-system:coder:tag"}

# For just the image name (without tag)
spec:
  values:
    image:
      repository: ghcr.io/coder/coder  # {"$imagepolicy": "flux-system:coder:name"}
```

## Helm Chart Monitoring

### HelmRepository (HTTPS)

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: coder
  namespace: flux-system
spec:
  interval: 1h
  url: https://helm.coder.com/v2
```

### HelmRepository (OCI)

For Helm charts stored as OCI artifacts:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: oci-charts
  namespace: flux-system
spec:
  type: oci
  interval: 5m
  url: oci://ghcr.io/myorg/charts
  # For private registries:
  # secretRef:
  #   name: ghcr-credentials
```

### Auto-updating Chart Versions

Use the same setter pattern for chart versions:

```yaml
spec:
  chart:
    spec:
      chart: coder
      version: "2.16.0"  # {"$imagepolicy": "flux-system:coder-chart:tag"}
      sourceRef:
        kind: HelmRepository
        name: coder
```

## Git Repository Monitoring

Already configured - monitors for new commits:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m
  url: ssh://git@github.com/sharingio/infra.git
  ref:
    branch: main
  secretRef:
    name: flux-system
```

For monitoring tags instead of branches:

```yaml
spec:
  ref:
    semver: ">=1.0.0"  # Latest semver tag
```

## Notifications

### Provider

Configure where to send notifications:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: slack
  namespace: flux-system
spec:
  type: slack
  channel: deployments
  secretRef:
    name: slack-webhook
---
apiVersion: v1
kind: Secret
metadata:
  name: slack-webhook
  namespace: flux-system
stringData:
  address: https://hooks.slack.com/services/xxx/yyy/zzz
```

Supported provider types:
- `slack`
- `discord`
- `msteams`
- `github` (commit status, PR comments)
- `gitlab`
- `gitea`
- `bitbucket`
- `azuredevops`
- `googlechat`
- `webex`
- `sentry`
- `azureeventhub`
- `telegram`
- `lark`
- `matrix`
- `opsgenie`
- `alertmanager`
- `grafana`
- `webex`
- `rocket`
- `generic` (webhook)
- `generic-hmac` (signed webhook)

### Alert

Configure what events to notify about:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: on-call
  namespace: flux-system
spec:
  providerRef:
    name: slack
  eventSeverity: info  # info, error
  eventSources:
    - kind: GitRepository
      name: '*'
    - kind: Kustomization
      name: '*'
    - kind: HelmRelease
      name: '*'
    - kind: ImagePolicy
      name: '*'
  # Optional: only specific events
  # inclusionList:
  #   - ".*succeeded.*"
  # exclusionList:
  #   - ".*no changes.*"
```

### Event Types

Events you can monitor:

| Source | Events |
|--------|--------|
| GitRepository | New commits, fetch failures |
| HelmRepository | New chart versions, fetch failures |
| HelmRelease | Install, upgrade, rollback, failure |
| Kustomization | Apply success/failure |
| ImageRepository | New tags discovered |
| ImagePolicy | Policy match changes |

## Example: Full Image Automation Setup

Monitor Coder releases and auto-update:

```yaml
# flux/bases/configs/image-automation/coder.yaml
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: coder
  namespace: flux-system
spec:
  image: ghcr.io/coder/coder
  interval: 1h
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: coder
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: coder
  filterTags:
    pattern: '^v(?P<version>[0-9]+\.[0-9]+\.[0-9]+)$'
    extract: '$version'
  policy:
    semver:
      range: ">=2.0.0"
---
# flux/clusters/cluster-sharingio-oci/image-automation.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: flux-system
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        name: Flux Bot
        email: flux@sharing.io
      messageTemplate: |
        chore: update images

        {{range .Changed.Changes}}
        - {{.OldValue}} -> {{.NewValue}}
        {{end}}
    push:
      branch: main
  update:
    path: ./flux
    strategy: Setters
```

Then mark the HelmRelease:

```yaml
# flux/bases/apps/coder/helm-release.yaml
spec:
  chart:
    spec:
      chart: coder
      version: "${CODER_VERSION}"  # {"$imagepolicy": "flux-system:coder:tag"}
```

## Recommended File Organization

```
flux/
├── bases/
│   └── configs/
│       └── image-automation/      # Shared ImageRepository/ImagePolicy
│           ├── kustomization.yaml
│           ├── coder.yaml
│           └── authentik.yaml
│
├── overlays/
│   └── sharingio-oci/
│       └── image-policies/        # Cluster-specific version constraints
│           └── kustomization.yaml
│
└── clusters/
    └── cluster-sharingio-oci/
        └── image-automation.yaml  # Per-cluster ImageUpdateAutomation
```

## Security Considerations

### Private Registries

Create credentials secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-credentials
  namespace: flux-system
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "ghcr.io": {
          "username": "flux",
          "password": "${GITHUB_TOKEN}"
        }
      }
    }
```

Reference in ImageRepository:

```yaml
spec:
  secretRef:
    name: ghcr-credentials
```

### Git Push Credentials

For ImageUpdateAutomation to push commits, the GitRepository secret needs write access:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: flux-system
  namespace: flux-system
type: Opaque
stringData:
  identity: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...deploy key with write access...
    -----END OPENSSH PRIVATE KEY-----
  known_hosts: |
    github.com ssh-rsa AAAA...
```

## Monitoring Without Auto-Update

If you want to be notified of new versions without auto-updating:

1. Set up ImageRepository and ImagePolicy (monitors versions)
2. Set up Alert to notify on ImagePolicy changes
3. Skip ImageUpdateAutomation (no auto-commits)

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: new-versions
  namespace: flux-system
spec:
  providerRef:
    name: slack
  eventSeverity: info
  eventSources:
    - kind: ImagePolicy
      name: '*'
      namespace: flux-system
```

This gives you visibility into available updates without automatic changes.
