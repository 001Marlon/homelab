# ---------- TrueNAS - Used for ZFS and NFS Shares and Raid Pool for HDDs ----------

resource "proxmox_virtual_environment_vm" "truenas" {
  name      = var.truenas_vm_name
  node_name = var.proxmox_node_name
  vm_id     = var.truenas_vm_id
  description = "TrueNAS SCALE - Managed by Terraform"

  cdrom {
    file_id = proxmox_download_file.truenas_iso.id
  }

  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 4048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
    iothread     = true
  }

  disk {
    datastore_id    = ""
    path_in_datastore = var.truenas_hdd_ids[0]
    file_format     = "raw"
    interface       = "scsi1"
  }

  disk {
    datastore_id    = ""
    path_in_datastore = var.truenas_hdd_ids[1]
    file_format     = "raw"
    interface       = "scsi2"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  on_boot       = true
  started       = true
  stop_on_destroy = true
  keyboard_layout = "de"
}

# ---------- Debian - Mainly used for docker to run applications ----------

resource "proxmox_virtual_environment_vm" "debian" {
  name      = var.debian_vm_name
  node_name = var.proxmox_node_name
  vm_id = var.debian_vm_id
  description = "Debian - Managed by Terraform"

  started         = true
  stop_on_destroy = true
  keyboard_layout = "de"

  cpu {
    cores = 8
    sockets = 1
    type = "host"
  }

  memory {
    dedicated = 12288
  }

  disk {
    datastore_id = "local-lvm"

    import_from = proxmox_download_file.debian_cloud_image.id

    interface = "virtio0"
    iothread  = true
    discard   = "on"

    size = 512
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.debian_vm_ip
        gateway = var.default_gateway
      }
    }

    dns {
      servers = [var.default_dns_server]
    }

    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }
}