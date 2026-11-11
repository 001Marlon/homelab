# Bootstrap-Schicht: GitHub-Actions-Runner als LXC auf Proxmox.
#
# Bewusst getrennt von infrastructure/proxmox/terraform: Die Pipeline verwaltet
# alles AUSSER dem Runner, auf dem sie selbst läuft. Dieser Teil wird nur von
# Hand angewendet (siehe Doku: Disaster Recovery -> Runner neu aufsetzen).
#
# Zugangsdaten kommen direkt aus homelab-secrets.yml (Repo-Root, gitignored),
# der State liegt im privaten Secrets-Repo unter terraform/bootstrap.tfstate.

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116"
    }
  }
}

variable "secrets_file" {
  type    = string
  default = "../../../homelab-secrets.yml"
}

locals {
  tf = yamldecode(file(var.secrets_file)).terraform

  runner = {
    id       = 103
    hostname = "homelab-runner01"
    ip       = "192.168.178.203/24"
  }
}

provider "proxmox" {
  endpoint = local.tf.proxmox_endpoint
  # root@pam ist nötig: das LXC-Feature "nesting" darf nur root setzen
  username = local.tf.proxmox_username
  password = local.tf.proxmox_password
  insecure = true
}

resource "proxmox_virtual_environment_download_file" "debian_lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = local.tf.proxmox_node_name
  url          = "http://download.proxmox.com/images/system/debian-13-standard_13.6-1_amd64.tar.zst"
  overwrite    = false
}

resource "proxmox_virtual_environment_container" "github_runner" {
  node_name    = local.tf.proxmox_node_name
  vm_id        = local.runner.id
  description  = "GitHub Actions Runner (Bootstrap) - nicht von der Pipeline verwaltet"
  tags         = ["bootstrap", "ci"]
  unprivileged = true

  start_on_boot = true
  started       = true

  # Nach TrueNAS (1) und Debian (2)
  startup {
    order = 3
  }

  # systemd im unprivilegierten Debian-Container braucht nesting
  features {
    nesting = true
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_lxc_template.id
    type             = "debian"
  }

  initialization {
    hostname = local.runner.hostname

    ip_config {
      ipv4 {
        address = local.runner.ip
        gateway = local.tf.default_gateway
      }
    }

    dns {
      servers = [local.tf.default_dns_server]
    }

    user_account {
      keys = local.tf.ssh_public_keys
    }
  }
}
