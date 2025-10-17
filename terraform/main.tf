variable LXC {
    type = list(object({
    name        = string
    vmid        = number
    cores       = number
    memory      = number # in GB
    storage_size = number
    ip_address  = string
    unprivileged  = optional(bool, true)

  }))
    default = [
        { name = "n8n-LXC", vmid = 115, cores = 2, memory = 8, storage_size = 20, ip_address = "192.168.10.226/24"}
    ]
}


# loop over the LXC variable to create multiple containers
resource "proxmox_lxc" "lxc" {
  for_each = { for lxc in var.LXC : lxc.name => lxc }
  target_node = "mainproxmox"
  hostname     = each.value.name
  vmid         = each.value.vmid

  cores        = each.value.cores
  memory       = each.value.memory * 1024
  swap         = 512
  ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  
  ssh_public_keys = file("~/.ssh/lxc-keys.pub")
  password = var.proxmox_lxc_password
  unprivileged = each.value.unprivileged

  onboot = true
  start = true

  rootfs {
    size = "${each.value.storage_size}G"
    storage = "local-lvm"
  }

  network {
    name = "eth0"
    bridge = "vmbr0"
    gw = "192.168.10.1"
    ip = each.value.ip_address
  }
}


variable "proxmox_lxc_password" {
  type = string
  sensitive = true
}