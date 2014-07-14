# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
    config.vm.box = "precise32"
    config.vm.box_url = "http://files.vagrantup.com/precise32.box"
    
    config.vm.network :bridged
    config.vm.forward_port 8080, 8082

    config.vm.provision :shell do |shell|
        shell.inline = "mkdir -p /etc/puppet/modules;
            puppet module install puppetlabs/vcsrepo"
    end

    config.vm.provision :puppet do |puppet|
        puppet.manifests_path = "manifests"
        puppet.manifest_file  = "openmrs-shr.pp"
    end
end
