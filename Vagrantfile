# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ffuenf/ubuntu-15.04-server-amd64"
  yamlconfig = YAML.load_file "config.yml"
  yamlpriv = YAML.load_file "private.yml"

  config.vm.provider "virtualbox" do |v, override|
      override.vm.network "forwarded_port", guest: 8787, host: 8788
      v.memory = yamlconfig['vm_memory']
      #v.cpus = 2
  end

  # Enable provisioning with CFEngine. CFEngine Community packages are
  # automatically installed. For example, configure the host as a
  # policy server and optionally a policy file to run:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.am_policy_hub = true
  #   # cf.run_file = "motd.cf"
  # end
  #
  # You can also configure and bootstrap a client to an existing
  # policy server:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.policy_server_address = "10.0.2.15"
  # end

  config.vm.provision "chef_solo" do |chef|
    # chef.log_level = :info
    chef.log_level = :debug
    chef.add_recipe "setup_rchk"
  end

end
