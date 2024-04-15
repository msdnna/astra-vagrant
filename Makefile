SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=1.7

export PROXMOX_URL?=https://192.168.1.21:8006/api2/json
export PROXMOX_USERNAME?=root@pam
export PROXMOX_PASSWORD?=vagrant
export PROXMOX_NODE?=pve

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-proxmox, make build-hyperv, make build-vsphere or make build-esxi

build-libvirt: astra-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: astra-${VERSION}-uefi-amd64-libvirt.box
build-proxmox: astra-${VERSION}-amd64-proxmox.box
build-hyperv: astra-${VERSION}-amd64-hyperv.box
build-vsphere: astra-${VERSION}-amd64-vsphere.box
build-esxi: astra-${VERSION}-amd64-esxi.box

astra-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh astra.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@./box-metadata.sh libvirt astra-${VERSION}-amd64 $@

astra-${VERSION}-uefi-amd64-libvirt.box: preseed.txt provision.sh astra.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.astra-uefi-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@./box-metadata.sh libvirt astra-${VERSION}-uefi-amd64 $@

astra-${VERSION}-amd64-proxmox.box: tmp/preseed-proxmox.txt provision.sh astra.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl

tmp/preseed-proxmox.txt: preseed.txt
	mkdir -p tmp
	sed -E -e 's,(d-i pkgsel/include string .+),\1 qemu-guest-agent,g' -e 's,(in-target systemctl enable .+)(\; \\),\1 qemu-guest-agent.service \2,g' preseed.txt >$@

astra-${VERSION}-amd64-hyperv.box: tmp/preseed-hyperv.txt provision.sh astra.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@./box-metadata.sh hyperv astra-${VERSION}-amd64 $@

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-astra-virtual-machines-on-hyper-v
tmp/preseed-hyperv.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 hyperv-daemons,g' preseed.txt >$@

astra-${VERSION}-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh astra-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra-vsphere.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.astra-amd64 -timestamp-ui astra-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere astra-${VERSION}-amd64 $@

astra-${VERSION}-amd64-esxi.box: preseed.txt provision.sh astra-esxi.pkr.hcl
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init astra-esxi.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	PACKER_ESXI_VNC_PROBE_TIMEOUT=15s \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=vmware-iso.astra-amd64 -timestamp-ui astra-esxi.pkr.hcl
	echo '{"provider":"vmware_esxi"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vmware_esxi astra-${VERSION}-amd64 $@

tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

.PHONY: help buid-libvirt buid-uefi-libvirt build-proxmox build-vsphere build-esxi
