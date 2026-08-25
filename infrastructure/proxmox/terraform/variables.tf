# ---General---

variable "ssh_public_key" {
  type        = string
  sensitive   = true
}

variable "proxmox_node_name" {
  type = string
}

variable "default_gateway" {
  type = string
}

variable "default_dns_server" {
  type = string
}

# --- Proxmox ---

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

# --- TrueNAS Scale VM ---

variable "truenas_vm_id" {
  type = number
}

variable "truenas_vm_name" {
  type = string
}

variable "truenas_vm_ip" {
  type = string
}

variable "truenas_iso_url" {
  type = string
}

variable "truenas_hdd_ids" {
  type = list(string)
}

# --- Debian VM ---

variable "debian_vm_id" {
  type = number
}

variable "debian_vm_name" {
  type = string
}

variable "debian_vm_ip" {
  type = string
}

variable "debian_cloud_image_url" {
  type = string
}