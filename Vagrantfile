# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Use trusty64 base box
  config.vm.box = "ubuntu/trusty64"
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 1536]
  end

  # Configure port forwarding
  config.vm.network "forwarded_port", guest: 8080, host: 8082

  # Ensure packages are up to date
  config.vm.provision :shell do |shell|
    # Uncomment the line below if you're in the Jembi Cape Town office
    shell.inline = "echo \"Acquire::http::Proxy \\\"http://192.168.1.53:3142\\\";\nAcquire::http::Proxy { download.oracle.com DIRECT; }\" > /etc/apt/apt.conf.d/01JembiServerproxy;
      sudo add-apt-repository ppa:webupd8team/java -y;
      sudo apt-get update"
    # shell.inline = "sudo add-apt-repository ppa:webupd8team/java -y;
    #   sudo apt-get updatesudo apt-get update";
  end

  # Setup LC_ALL locale flag
  config.vm.provision :shell do |shell|
    shell.inline = "echo 'LC_ALL=\"en_US.UTF-8\"' >> /etc/default/locale"
  end

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "openmrs-shr.pp"
  end
end
