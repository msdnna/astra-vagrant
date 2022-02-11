variable "disk_size" {
  type    = string
  default = "16384"
}

variable "iso_url" {
  type    = string
  default = "smolensk-1.6.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:70841ce6473f171638e66635a75a3c8a0d1287158d1c042c85e22d983b150de1"
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

variable "vagrant_box" {
  type = string
}

source "hyperv-iso" "astra-amd64" {
  boot_command = [
    "<enter>",
    "<esc>",
    "<enter>",
    "<wait>",
    "/netinst/linux",
    " initrd=/netinst/initrd.gz",
    " modprobe.blacklist=evbug",
    " auto=true",
    " hostname=astra",
    " domain=",
    " astra-license/license=true",
    " net.ifnames=0",
    " preseed/url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    "<enter>",
  ]
  boot_wait         = "2s"
  boot_order        = ["SCSI:0:0"]
  first_boot_device = "DVD"
  cpus              = 2
  memory            = 2048
  disk_size         = var.disk_size
  generation        = 2
  headless          = true
  http_directory    = "."
  iso_checksum      = var.iso_checksum
  iso_url           = var.iso_url
  switch_name       = var.hyperv_switch_name
  temp_path         = "tmp"
  vlan_id           = var.hyperv_vlan_id
  ssh_username      = "vagrant"
  ssh_password      = "vagrant"
  ssh_timeout       = "60m"
  shutdown_command  = "echo vagrant | sudo -S poweroff"
}

source "qemu" "astra-amd64" {
  accelerator = "kvm"
  boot_command = [
    "<enter>",
    "<esc>",
    "<enter>",
    "<wait>",
    "/netinst/linux",
    " initrd=/netinst/initrd.gz",
    " modprobe.blacklist=evbug",
    " auto=true",
    " hostname=astra",
    " domain=",
    " astra-license/license=true",
    " net.ifnames=0",
    " preseed/url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    "<enter>",
  ]
  boot_wait      = "2s"
  disk_discard   = "unmap"
  disk_interface = "virtio-scsi"
  disk_size      = var.disk_size
  format         = "qcow2"
  headless       = true
  http_directory = "."
  iso_checksum   = var.iso_checksum
  iso_url        = var.iso_url
  qemuargs = [
    ["-m", "2048"],
    ["-smp", "2"],
  ]
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "qemu" "astra-uefi-amd64" {
  accelerator = "kvm"
  boot_command = [
    "e",
    "<leftCtrlOn>kkkkkkkkkkkkkkkkkkkk<leftCtrlOff>",
    "<enter>", "linux /linux",
    " auto=true",
    " url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    " hostname=astra",
    " net.ifnames=0",
    " DEBCONF_DEBUG=5",
    "<enter>",
    "initrd /initrd.gz",
    "<enter>",
    "<f10>",
  ]
  boot_wait      = "2s"
  disk_discard   = "unmap"
  disk_interface = "virtio-scsi"
  disk_size      = var.disk_size
  format         = "qcow2"
  headless       = true
  http_directory = "."
  iso_checksum   = var.iso_checksum
  iso_url        = var.iso_url
  qemuargs = [
    ["-bios", "/usr/share/ovmf/OVMF.fd"],
    ["-device", "virtio-vga"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-m", "2048"],
    ["-smp", "2"],
  ]
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "virtualbox-iso" "astra-amd64" {
  boot_command = [
    "<enter>",
    "<esc>",
    "<enter>",
    "<wait>",
    "/netinst/linux",
    " initrd=/netinst/initrd.gz",
    " modprobe.blacklist=evbug",
    " auto=true",
    " hostname=astra",
    " domain=",
    " astra-license/license=true",
    " net.ifnames=0",
    " preseed/url={{.HTTPIP}}:{{.HTTPPort}}/preseed.txt",
    "<enter>",
  ]
  boot_wait            = "2s"
  disk_size            = var.disk_size
  guest_additions_mode = "attach"
  guest_os_type        = "Debian_64"
  hard_drive_discard   = true
  hard_drive_interface = "sata"
  headless             = true
  http_directory       = "."
  iso_checksum         = var.iso_checksum
  iso_url              = var.iso_url
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "2048"],
    ["modifyvm", "{{.Name}}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--vram", "16"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],
    ["modifyvm", "{{.Name}}", "--nictype1", "82540EM"],
    ["modifyvm", "{{.Name}}", "--nictype2", "82540EM"],
    ["modifyvm", "{{.Name}}", "--nictype3", "82540EM"],
    ["modifyvm", "{{.Name}}", "--nictype4", "82540EM"],
  ]
  vboxmanage_post = [
    ["storagectl", "{{.Name}}", "--name", "IDE Controller", "--remove"],
  ]
  ssh_username        = "vagrant"
  ssh_password        = "vagrant"
  ssh_timeout         = "60m"
  shutdown_command    = "echo vagrant | sudo -S poweroff"
  post_shutdown_delay = "2m"
}

build {
  sources = [
    "source.hyperv-iso.astra-amd64",
    "source.qemu.astra-amd64",
    "source.qemu.astra-uefi-amd64",
    "source.virtualbox-iso.astra-amd64",
  ]

  provisioner "shell" {
    execute_command   = "sudo -S {{ .Vars }} bash {{ .Path }}"
    expect_disconnect = true
    scripts = [
      "provision-guest-additions.sh",
      "provision.sh",
    ]
  }

  provisioner "shell-local" {
    environment_vars = [
      "PACKER_VERSION=${packer.version}",
      "PACKER_VM_NAME=${build.ID}",
    ]
    only = [
      "hyperv-iso.astra-amd64",
    ]
    scripts = ["provision-local-hyperv.cmd"]
  }

  post-processor "vagrant" {
    only = [
      "qemu.astra-amd64",
      "virtualbox-iso.astra-amd64",
      "hyperv-iso.astra-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }

  post-processor "vagrant" {
    only = [
      "qemu.astra-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile-uefi.template"
  }
}
