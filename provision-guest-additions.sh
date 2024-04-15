#!/bin/bash
set -eux

# astra linux debian repository unlock.
astra-mic-control disable
echo 'deb https://deb.debian.org/debian/ buster main contrib non-free' > /etc/apt/sources.list.d/debian.list
echo 'deb https://security.debian.org/debian-security/ buster/updates main contrib non-free' >> /etc/apt/sources.list.d/debian.list
wget -O- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6d33866edd8ffa41c0143aeddcc9efbf77e11517' | apt-key add -
wget -O- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xac530d520f2f3269f5e98313a48449044aad5c5d' | apt-key add -
apt-get update

# install the Guest Additions.
if [ -n "$(lspci | grep 'Red Hat' | head -1)" ]; then
# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent
elif [ -n "$(lspci | grep VMware | head -1)" ]; then
# install the VMware Guest Additions.
apt-get install -y open-vm-tools
elif [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" == 'Microsoft Corporation' ]; then
# no need to install the Hyper-V Guest Additions (aka Linux Integration Services)
# as they were already installed from tmp/preseed-hyperv.txt.
exit 0
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
