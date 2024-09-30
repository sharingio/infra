terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.7.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~>0.6.0-beta.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 0.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~>1.3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~>6.3.0"
    }
    powerdns = {
      source  = "pan-net/powerdns"
      version = "1.5.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
  required_version = ">= 1.2"
  backend "kubernetes" {
    secret_suffix = "cluster-state"
    namespace     = "tfstate"
    config_path   = "~/.kube/config-fop"
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}
provider "github" {
  token = var.github_token
  owner = var.github_org
}
provider "flux" {
  kubernetes = {
    config_path = local_file.kubeconfig.filename
  }
  git = {
    url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}
provider "dns" {
  update {
    server        = var.rfc2136_nameserver
    key_name      = var.rfc2136_tsig_keyname
    key_secret    = var.rfc2136_tsig_key
    key_algorithm = "hmac-sha256"
  }
}
provider "powerdns" {
  api_key    = var.pdns_api_key
  server_url = var.pdns_host
}
provider "kubernetes" {
  alias = "cluster-sharingio-oci"
  # config_path = "./kubeconfig"
  # We use an IP here to speed things up, the first nome name might work as well
  host                   = "https://${module.cluster.cluster_node0_ip}:6443"
  client_certificate     = base64decode(module.cluster-sharingio-oci.kubeconfig_client_certificate)
  client_key             = base64decode(module.clustercluster-sharingio-oci.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.clustercluster-sharingio-oci.kubeconfig_cluster_ca_certificate)
}
