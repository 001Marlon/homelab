resource "proxmox_virtual_environment_vm" "debian" {
  name      = "homelab-debian01"
  node_name = "homelab-pve01"

  vm_id = 102

  started         = true
  stop_on_destroy = true

  cpu {
    cores = 4
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
        address = "192.168.178.202/24"
        gateway = "192.168.178.1"
      }
    }

    dns {
      servers = ["192.168.178.1"]
    }

    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }

  keyboard_layout = "de"
}