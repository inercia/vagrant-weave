# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# used for exporting the Weave sources
GOPATH=ENV['GOPATH']

# name, external IP and internal bridge addresses
CFG = [ ["weave1", "192.168.40.11", "172.17.51.1"],
        ["weave2", "192.168.40.12", "172.17.52.1"] ]

###########################################################################

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # config.vm.box = "robwc/minitrusty64"    # a minimal Ubuntu
  config.vm.box = "baremettle/ubuntu-14.04"

  config.vm.box_check_update = false

  ["virtualbox", "vmware_fusion", "vmware_workstation", "libvirt"].each do |p|
    config.vm.provider "p" do |v|
      v.vmx["memsize"]              = "1024"
      v.vmx["numvcpus"]             = "1"
      v.vmx["cpuid.coresPerSocket"] = "1"
    end
  end

  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.storage_pool_name = "default"
  end

  #########################
  # shared folders
  #########################

  # see this page for running NFS without asking password
  # http://joemaller.com/3411/vagrant-nfs-shares-without-a-password/
  config.vm.synced_folder ".", "/vagrant", create: true, type: "nfs"

  # export the weave:export directory
  config.vm.synced_folder "/var/tmp", "/weave/images", create: true, type: "nfs"

  # export the weave sources
  config.vm.synced_folder GOPATH, "/weave/src", create: true, type: "nfs"

  #########################
  # provisioning
  #########################

  CFG.each do |name, ext_ip, bridge_ip|
	  config.vm.define name do |weave|
	    weave.vm.hostname = name
	    weave.vm.network "private_network", ip:ext_ip
	    weave.vm.provision "shell",
	    	path: "provision.d/all.sh",
	    	args: "#{ext_ip} #{bridge_ip}"
	  end
  end
end

