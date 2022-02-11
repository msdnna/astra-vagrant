SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=1.6

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-virtualbox, make build-hyperv or make build-vsphere

build-libvirt: astra-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: astra-${VERSION}-uefi-amd64-libvirt.box
build-virtualbox: astra-${VERSION}-amd64-virtualbox.box
build-hyperv: astra-${VERSION}-amd64-hyperv.box
build-vsphere: astra-${VERSION}-amd64-vsphere.box

astra-${VERSION}-amd64-libvirt.box: preseed.txt provision.sh astra.pkr.hcl Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f astra-${VERSION}-amd64 $@

astra-${VERSION}-uefi-amd64-libvirt.box: preseed.txt provision.sh astra.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.astra-uefi-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f astra-${VERSION}-uefi-amd64 $@

astra-${VERSION}-amd64-virtualbox.box: preseed.txt provision.sh astra.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=virtualbox-iso.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f astra-${VERSION}-amd64 $@

astra-${VERSION}-amd64-hyperv.box: tmp/preseed-hyperv.txt provision.sh astra.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.astra-amd64 -on-error=abort -timestamp-ui astra.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f astra-${VERSION}-amd64 $@

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-astra-virtual-machines-on-hyper-v
tmp/preseed-hyperv.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 linux-image-virtual linux-tools-virtual linux-cloud-tools-virtual,g' preseed.txt >$@

astra-${VERSION}-amd64-vsphere.box: tmp/preseed-vsphere.txt provision.sh astra-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_version=${VERSION} \
		packer build -only=vsphere-iso.astra-amd64 -timestamp-ui astra-vsphere.pkr.hcl
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f astra-${VERSION}-amd64 $@

tmp/preseed-vsphere.txt: preseed.txt
	mkdir -p tmp
	sed -E 's,(d-i pkgsel/include string .+),\1 open-vm-tools,g' preseed.txt >$@

.PHONY: help buid-libvirt buid-uefi-libvirt build-virtualbox build-vsphere
