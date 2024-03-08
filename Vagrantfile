Vagrant.configure("2") do |config|
 
    config.vm.provider :virtualbox do |virtualbox, override|
        override.vm.box     = 'ubuntu/jammy64'
        virtualbox.memory   = 4096
        virtualbox.customize ["modifyvm", :id, "--cpus", "4"]
    end

    # Vagrant.has_plugin?("vagrant-libvirt") || (
    #     config.vm.provider :libvirt do |libvirt, override|
    #         puts "This won't work yet - no clue what box to use as an equivalent to ubuntu/jammy64 (ubuntu server 22)"
    #         override.vm.box = "???"
    #         libvirt.memory = 4096
    #         libvirt.cpus = 4
    #     end
    # )


    NUM_NODES = 3

    config.vm.synced_folder ".", "/vagrant", disabled: true

    config.vm.define "puppet-master" do |node|
        node.vm.network "private_network", ip: "192.168.56.2"
        node.vm.synced_folder "puppet/code/", "/etc/puppetlabs/code"

        node.vm.provision :shell, name: "apply hostname", inline: "echo \'puppet-master.local\' > /etc/hostname"

        node.vm.provision :shell, name: "apply host puppet-master", inline: "echo \'192.168.56.2 puppet-master.local\' >> /etc/hosts"
        (1..NUM_NODES).each do |j|
            node.vm.provision :shell, name: "apply host node-#{j}", inline: "echo \'192.168.57.#{j + 1} node-#{j}.local\' >> /etc/hosts"
        end
        node.vm.provision :shell, name: "reboot for netconf", inline: "echo \"Rebooting to apply network config\"", reboot: true

        # enable puppet repo
        node.vm.provision :shell, name: "setup puppet package repo",
            inline: "wget http://apt.puppet.com/puppet8-release-jammy.deb -O puppet.deb --quiet && dpkg -i puppet.deb && rm puppet.deb && apt-get update -q", env: {"DEBIAN_FRONTEND" => "noninteractive"}
        
        # install puppet server
        node.vm.provision :shell, name: "install puppet server", inline: "apt-get install puppetserver -o Dpkg::Options::=\"--force-confold\" -q -y", env: {"DEBIAN_FRONTEND" => "noninteractive"}  
        # enable naive autosigning - NEVER DO THIS IN PROD SEE https://www.puppet.com/docs/puppet/8/ssl_autosign.html
        node.vm.provision :shell, name: "enable naive autosign", inline: "puppet config set autosign true --section server"
        node.vm.provision :shell, name: "configure alt-ssl puppet CA",
            inline: "puppet config set dns_alt_names puppet-master,puppet-master.local,puppetdb,puppetdb.local,puppetboard,puppetboard.local,IP:127.0.0.1"
        node.vm.provision :shell, name: "enable puppet server", inline: "systemctl enable --now puppetserver"

        # To install any packages, just install into shared folder like:
        # puppet module install --target-dir ./puppet/code/environments/production/modules/ <module>

        # install puppet agent
        node.vm.provision :shell, name: "install puppet agent", inline: "apt-get install puppet-agent facter -o Dpkg::Options::=\"--force-confold\" -q -y", env: {"DEBIAN_FRONTEND" => "noninteractive"}
        node.vm.provision :shell, name: "enable puppet agent", inline: "puppet resource service puppet ensure=running enable=true"   
        node.vm.provision :shell, name: "set puppet master connection", inline: "puppet config set server puppet-master.local --section main"
        node.vm.provision :shell, name: "bootstrap puppet ssl", inline: "puppet ssl bootstrap" # nothing further is needed, as autosigning is enabled!

        # install puppetdb
        node.vm.provision :shell, name: "enable puppetdb", inline: "puppet resource package puppetdb ensure=latest"
        node.vm.provision :shell, name: "configure puppetdb", inline: "echo \'[main]\nserver_urls = https://puppet-master.local:8081\' > /etc/puppetlabs/puppet/puppetdb.conf"
        node.vm.provision :shell, name: "configure puppet for puppetdb",
            inline: "puppet config set storeconfigs true --section server \
                && puppet config set storeconfigs_backend puppetdb --section server \
                && puppet config set reports store,puppetdb --section server"
        node.vm.provision :shell, name: "create routes.yaml", inline: "echo \'---\server:\n  facts:\n     terminus: puppetdb\n    cache: yaml\' > $(puppet config print route_file)"
        node.vm.provision :shell, name: "restart puppet server", inline: "systemctl restart puppetserver"
    end


    (1..NUM_NODES).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.network "private_network", ip: "192.168.57.#{i + 1}"
            node.vm.provision :shell, name: "apply hostname", inline: "echo \'node-#{i}.local\' > /etc/hostname"

            node.vm.provision :shell, name: "apply host puppet-master", inline: "echo \'192.168.56.2 puppet-master.local\' >> /etc/hosts"
            (1..NUM_NODES).each do |j|
                node.vm.provision :shell, name: "apply host node-#{j}", inline: "echo \'192.168.57.#{j + 1} node-#{j}.local\' >> /etc/hosts"
            end
            node.vm.provision :shell, name: "reboot for netconf", inline: "echo \"Rebooting to apply network config\"", reboot: true

            # enable puppet repo
            node.vm.provision :shell, name: "setup puppet package repo",
                inline: "wget http://apt.puppet.com/puppet8-release-jammy.deb -O puppet.deb --quiet && dpkg -i puppet.deb && rm puppet.deb && apt-get update -q", env: {"DEBIAN_FRONTEND" => "noninteractive"}
                
            # install puppet agent
            node.vm.provision :shell, name: "install puppet agent", inline: "apt-get install puppet-agent facter -o Dpkg::Options::=\"--force-confold\" -q -y", env: {"DEBIAN_FRONTEND" => "noninteractive"}
            node.vm.provision :shell, name: "enable puppet agent", inline: "puppet resource service puppet ensure=running enable=true"   
            node.vm.provision :shell, name: "set puppet master connection", inline: "puppet config set server puppet-master.local --section main"
            node.vm.provision :shell, name: "bootstrap puppet ssl", inline: "puppet ssl bootstrap" # nothing further is needed, as autosigning is enabled!
        end
    end
end
