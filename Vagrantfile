Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.network :forwarded_port, :guest => 5000, :host => 7237
  config.vm.provision :shell, :inline => 'apt-get update'
  config.vm.provision :puppet do |puppet|
    puppet.module_path    = "puppet/modules"
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "site.pp"
  end
end
