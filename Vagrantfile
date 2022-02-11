
# The contents below were provided by the Packer Vagrant post-processor

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
  end
end


# The contents below (if any) are custom contents provided by the
# Packer template during image build.
Vagrant.configure(2) do |config|
  config.vm.provider 'libvirt' do |lv|
    lv.graphics_type = 'spice'
    lv.video_type = 'qxl'
    lv.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
    lv.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
  end
end

