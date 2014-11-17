# -*- mode: ruby -*-
# vi: set ft=ruby :

# some recommended plugins:
# vagrant plugin install vagrant-hostsupdater

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "robwc/minitrusty64"    # a minimal Ubuntu

  config.vm.box_check_update = false
  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true

  # see this page for running NFS without asking password
  # http://joemaller.com/3411/vagrant-nfs-shares-without-a-password/
  config.vm.synced_folder ".", "/vagrant", create: true, type: "nfs"

  ["virtualbox", "vmware_fusion", "vmware_workstation"].each do |p|
    config.vm.provider "p" do |v|
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      v.vmx["cpuid.coresPerSocket"] = "1"
    end
  end

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.provision "shell", path: "provision.d/all.sh"

  config.vm.define "vm1" do |vm1|
    vm1.vm.hostname = "vm1"
    vm1.vm.network "private_network", ip: "192.168.40.11"
    vm1.vm.provision "shell", path: "provision.d/vm1.sh"
  end

  config.vm.define "vm2" do |vm2|
    vm2.vm.hostname = "vm2"
    vm2.vm.network "private_network", ip: "192.168.40.12"
    vm2.vm.provision "shell", path: "provision.d/vm2.sh"
  end
end
