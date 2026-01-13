# Terraform Provider Upgrade Notes

## Overview

This document describes the schema differences and breaking changes when upgrading the OCI Talos cluster module providers.

| Provider | Old Version | New Version | Breaking Changes |
|----------|-------------|-------------|------------------|
| oracle/oci | 6.7.0 | ~> 7.29 | Minor |
| siderolabs/talos | ~> 0.6.0-beta | ~> 0.9.0 | Yes |
| hashicorp/helm | ~> 2.15.0 | ~> 2.17.0 | None |
| hashicorp/null | (not used) | > 0.0.0 | N/A (new) |

---

## 1. Oracle OCI Provider (6.7.0 → 7.29.0)

### 1.1 `oci_core_instance` Resource

#### launch_options Block Schema

```hcl
launch_options {
  boot_volume_type                      = string  # ISCSI, SCSI, IDE, VFIO, PARAVIRTUALIZED
  firmware                              = string  # BIOS, UEFI_64
  is_consistent_volume_naming_enabled   = bool
  is_pv_encryption_in_transit_enabled   = bool    # Deprecated at create, use parent-level
  network_type                          = string  # E1000, VFIO, PARAVIRTUALIZED
  remote_data_volume_type               = string  # ISCSI, SCSI, IDE, VFIO, PARAVIRTUALIZED
}
```

#### Known Issue: Firmware Override Not Supported

**Error:** `400-InvalidParameter, Overriding Firmware in LaunchOptions is not supported`

**Root Cause:** This is a known bug ([GitHub Issue #2052](https://github.com/oracle/terraform-provider-oci/issues/2052)) affecting custom images imported from Object Storage.

**The Catch-22:**
1. Cannot set `launch_options.firmware` on `oci_core_image` resource (computed attribute)
2. Cannot override firmware at `oci_core_instance` level when using custom images
3. Setting `launch_mode = "CUSTOM"` requires `launch_options`, but they can't be set

**Workaround:** Remove `firmware` from `launch_options` in instance configuration. The firmware type is inherited from the imported image. Talos images from Image Factory are already UEFI-based.

```hcl
# OLD (broken)
launch_options {
  network_type            = "PARAVIRTUALIZED"
  remote_data_volume_type = "PARAVIRTUALIZED"
  boot_volume_type        = "PARAVIRTUALIZED"
  firmware                = "UEFI_64"  # Causes error with custom images
}

# NEW (working)
launch_options {
  network_type            = "PARAVIRTUALIZED"
  remote_data_volume_type = "PARAVIRTUALIZED"
  boot_volume_type        = "PARAVIRTUALIZED"
  # firmware inherited from image - cannot be overridden
}
```

### 1.2 `oci_core_public_ip` Resource

No breaking changes. New `lifetime = "RESERVED"` behavior unchanged.

### 1.3 `oci_core_image` Resource

No breaking changes in schema. The `launch_mode` and `launch_options` interaction issue predates this upgrade.

### 1.4 General Changes (6.7.0 → 7.29.0)

- Version 6.31.0: Made `launch_options` and `fault_domain` updatable in `oci_core_instance`
- Version 6.34.0: Removed deprecated swift password resources
- Version 6.48.0: Fixed agent configuration metadata handling
- No major breaking changes affecting our use case

---

## 2. Siderolabs Talos Provider (0.6.0-beta → 0.9.0)

### 2.1 Breaking Change: `talos_machine_disks` Data Source

**Version 0.9.0** migrated to CEL (Common Expression Language) for disk filtering.

```hcl
# OLD syntax (0.6.x)
data "talos_machine_disks" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = "10.5.0.2"
  filters = {
    size = "> 6GB"
    type = "nvme"
  }
}

# NEW syntax (0.9.0) - CEL expressions
data "talos_machine_disks" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = "10.5.0.2"
  selector             = "disk.size > 6u * GB && disk.transport == 'nvme'"
}
```

#### CEL Expression Examples

| Filter | CEL Expression |
|--------|----------------|
| Size > 6GB | `disk.size > 6u * GB` |
| NVMe disks | `disk.transport == 'nvme'` |
| Non-rotational | `!disk.rotational` |
| Combined | `disk.size > 100u * GB && !disk.rotational` |

#### Full `talos_machine_disks` Schema (v0.9.0)

**Required:**
- `client_configuration` - Talos client config (from `talos_machine_secrets`)
- `node` - Node IP/hostname to query

**Optional:**
- `endpoint` - Custom endpoint (defaults to node)
- `selector` - CEL expression to filter disks (defaults to all)
- `timeouts` - Read timeout configuration

**Output Attributes (disks[]):**
- `dev_path`, `bus_path`, `modalias`, `symlinks` - Device identifiers
- `size`, `pretty_size`, `sector_size`, `io_size` - Specifications
- `model`, `serial`, `uuid`, `wwid`, `transport`, `sub_system` - Hardware details
- `rotational`, `readonly`, `cdrom`, `secondary_disks` - Characteristics

### 2.2 Other Changes

| Version | Change |
|---------|--------|
| 0.7.0 | SDK upgrade to v1.9.0 |
| 0.8.0 | Removed Talos-to-Kubernetes compatibility checks |
| 0.8.0 | Added secure boot support for non-metal image factory URLs |
| 0.8.1 | Fixed `talos_version` to work without "v" prefix |
| 0.9.0 | SDK upgrade to v1.11.0, CEL disk expressions |

### 2.3 Resources Unchanged

These resources have no breaking changes:
- `talos_machine_secrets`
- `talos_machine_configuration` (data source)
- `talos_machine_configuration_apply`
- `talos_cluster_kubeconfig`
- `talos_image_factory_schematic`
- `talos_image_factory_urls` (data source)
- `talos_image_factory_extensions_versions` (data source)
- `talos_client_configuration` (data source)

---

## 3. Hashicorp Helm Provider (2.15.0 → 2.17.0)

### No Breaking Changes

| Version | Changes |
|---------|---------|
| 2.15.0 | Added `upgrade_install` boolean for idempotent installation |
| 2.16.0 | Bug fixes only |
| 2.17.0 | Dry-run now validates against server during plan |

The `helm_template` data source used for Cilium manifest generation is unchanged.

---

## 4. Component Version Updates

| Component | Old | New | Notes |
|-----------|-----|-----|-------|
| Talos Linux | v1.8.1 | v1.12.1 | Major upgrade |
| Kubernetes | v1.31.1 | v1.35.0 | Major upgrade |
| Cilium | 1.16.3 | 1.18.5 | Gateway API improvements |
| Talos CCM | v1.8.0 | v1.11.0 | Matches Talos version |
| OCI CCM | v1.29.0 | v1.29.0 | Unchanged |

---

## 5. New Features Added

### 5.1 Reserved Public IPs (NEW)

```hcl
resource "oci_core_public_ip" "ingress" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.cluster_name}-ingress"
  lifecycle { prevent_destroy = true }
}
```

Three reserved IPs that survive cluster rebuilds:
- `ingress` - HTTP/HTTPS traffic
- `dns` - Technitium DNS server
- `wireguard` - VPN tunnel

### 5.2 Talos Image Auto-Upload (NEW)

```hcl
resource "null_resource" "upload_talos_image" {
  count = var.talos_image_oci_bucket_url == null ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/upload-talos-image.sh ..."
  }
}
```

Automatically downloads from Talos Image Factory, converts to QCOW2, uploads to OCI bucket.

**Dependencies:** `oci` CLI, `xz`, `qemu-img`

### 5.3 Cilium Gateway API (NEW)

```hcl
# New Cilium settings
gatewayAPI.enabled           = "true"
gatewayAPI.hostNetwork.enabled = "true"
l2announcements.enabled      = "true"
externalIPs.enabled          = "true"
kubeProxyReplacement         = "true"
```

Replaces nginx-ingress with Cilium Gateway API for ingress traffic.

### 5.4 Gateway API CRDs (NEW)

Added to Talos external manifests:
- `gateway.networking.k8s.io_gatewayclasses.yaml`
- `gateway.networking.k8s.io_gateways.yaml`
- `gateway.networking.k8s.io_httproutes.yaml`
- `gateway.networking.k8s.io_referencegrants.yaml`
- `gateway.networking.k8s.io_grpcroutes.yaml`
- `gateway.networking.k8s.io_tlsroutes.yaml`

---

## 6. Migration Checklist

- [ ] Update provider version constraints in `versions.tf`
- [ ] Remove `firmware = "UEFI_64"` from `launch_options` blocks
- [ ] Update any `talos_machine_disks` data sources to use CEL syntax
- [ ] Install `oci` CLI locally for Talos image upload
- [ ] Run `tofu init -upgrade` to fetch new providers
- [ ] Run `tofu plan` to verify no unexpected changes
- [ ] Backup `terraform.tfstate` before applying

---

## References

- [OCI Provider Changelog](https://github.com/oracle/terraform-provider-oci/blob/master/CHANGELOG.md)
- [OCI Firmware Override Bug #2052](https://github.com/oracle/terraform-provider-oci/issues/2052)
- [Talos Provider Releases](https://github.com/siderolabs/terraform-provider-talos/releases)
- [Talos Provider Docs](https://registry.terraform.io/providers/siderolabs/talos/latest/docs)
- [Helm Provider Changelog](https://github.com/hashicorp/terraform-provider-helm/blob/main/CHANGELOG.md)
