packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.1.7"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-hyperv
    hyperv = {
      version = "1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "version" {
  type = string
}

variable "vagrant_box" {
  type = string
}

variable "disk_size" {
  type    = string
  default = 16 * 1024
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = "sha256:91236b4f3373773681da7d89982053ee76bcaba41467178f26a7678c0abaf7ed"
}

variable "iso_file" {
  type    = string
  default = env("PROXMOX_ISO_FILE")
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

source "qemu" "astra-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 2 * 1024
  qemuargs = [
    ["-cpu", "host"]
  ]
  headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  format         = "qcow2"
  disk_size      = var.disk_size
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  boot_wait      = "5s"
  boot_command = [
    "<tab>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "/install.amd/vmlinuz initrd=/install.amd/initrd.gz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter>",
  ]
  shutdown_command  = "echo vagrant | sudo -S poweroff"
}

source "qemu" "astra-uefi-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  efi_boot     = true
  cpus         = 2
  memory       = 2 * 1024
  qemuargs = [
    ["-cpu", "host"],
  ]
  headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  format         = "qcow2"
  disk_size      = var.disk_size
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  boot_wait      = "10s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter><wait5s>",
    "initrd /install.amd/initrd.gz",
    "<enter><wait5s>",
    "boot",
    "<enter><wait5s>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "proxmox-iso" "astra-amd64" {
  vm_id			   = 1001
  template_name            = "astra-${var.version}-amd64-pve"
  tags                     = "astra-${var.version};template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  bios                     = "seabios"
  cpu_type = "host"
  cores    = 2
  memory   = 2 * 1024
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = false
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
  }
  iso_checksum     = var.iso_checksum
  iso_file	   = var.iso_file
  unmount_iso      = true
  os               = "l26"
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  http_directory   = "."
  boot_wait        = "5s"
  boot_command = [
    "<enter>",
    "<esc>",
    "<enter>",
    "<wait>",
    "/netinst/linux",
    " initrd=/netinst/initrd.gz",
    " modprobe.blacklist=evbug",
    " auto=true",
    " netcfg/get_hostname=astra",
    " netcfg/get_domain=",
    " astra-license/license=true",
    " network-console/enable=false",
    " net.ifnames=0",
    " preseed/url={{.HTTPIP}}:{{.HTTPPort}}/tmp/preseed-proxmox.txt",
    "<enter>",
  ]
}

source "hyperv-iso" "astra-amd64" {
  temp_path         = "tmp"
  headless          = true
  http_directory    = "."
  generation        = 2
  cpus              = 2
  memory            = 2 * 1024
  switch_name       = var.hyperv_switch_name
  vlan_id           = var.hyperv_vlan_id
  disk_size         = var.disk_size
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  ssh_username      = "vagrant"
  ssh_password      = "vagrant"
  ssh_timeout       = "60m"
  first_boot_device = "DVD"
  boot_order        = ["SCSI:0:0"]
  boot_wait         = "5s"
  boot_command = [
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/tmp/preseed-hyperv.txt",
    " hostname=vagrant",
    " domain=home",
    " net.ifnames=0",
    " BOOT_DEBUG=2",
    " DEBCONF_DEBUG=5",
    "<enter><wait5s>",
    "initrd /install.amd/initrd.gz",
    "<enter><wait5s>",
    "boot",
    "<enter><wait5s>",
  ]
  shutdown_command  = "echo vagrant | sudo -S poweroff"
}

build {
  sources = [
    "source.qemu.astra-amd64",
    "source.qemu.astra-uefi-amd64",
    "source.proxmox-iso.astra-amd64",
    "source.hyperv-iso.astra-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-guest-additions.sh",
      "provision.sh"
    ]
  }

  provisioner "shell-local" {
    environment_vars = [
      "PACKER_VERSION={{packer_version}}",
      "PACKER_VM_NAME={{build `ID`}}",
    ]
    scripts = [
      "provision-local-hyperv.cmd"
    ]
    only = [
      "astra-amd64-hyperv",
    ]
  }

  # post-processor "vagrant" {
    # only = [
      # "qemu.astra-amd64",
      # "hyperv-iso.astra-amd64",
    # ]
    # output               = var.vagrant_box
    # vagrantfile_template = "Vagrantfile.template"
  # }
# 
  # post-processor "vagrant" {
    # only = [
      # "qemu.astra-uefi-amd64",
    # ]
    # output               = var.vagrant_box
    # vagrantfile_template = "Vagrantfile-uefi.template"
  # }
}
