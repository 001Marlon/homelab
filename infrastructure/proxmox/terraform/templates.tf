resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  url = var.debian_cloud_image_url
}

resource "proxmox_download_file" "truenas_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  url = var.truenas_iso_url
}