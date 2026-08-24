resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "import"

  datastore_id = "local"
  node_name    = "homelab-pve01"

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}