terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
  }
}

# API-Token terraform@pve!github-actions-homelab-runner01 (Rolle TerraformRole),
# kein root-Passwort. Nur der Bootstrap (Runner-LXC) braucht root@pam.
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}
