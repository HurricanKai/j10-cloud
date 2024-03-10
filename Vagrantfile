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

    config.vm.define "salt-master" do |node|
        node.vm.network "private_network", ip: "192.168.57.2"
        node.vm.network "forwarded_port", guest: 8000, host: 8123
        node.vm.synced_folder "salt/master-confs/", "/etc/salt/master.d/"
        node.vm.synced_folder "salt/minion-confs/", "/etc/salt/minion.d/"
        node.vm.synced_folder "salt/pillar/", "/srv/pillar/"
        node.vm.synced_folder "salt/salt/", "/srv/salt/"

        # ensure folders are synced before services start
        node.vm.provision :shell, name: "add vbox workaround", inline: "mkdir -p /etc/systemd/system/salt-minion.service.d/ \
            && echo \'[Unit]\nConditionDirectoryNotEmpty=/etc/salt/minion.d/\n\' > /etc/systemd/system/salt-minion.service.d/99-ensure-configs.conf"
        node.vm.provision :shell, name: "add vbox workaround master", inline: "mkdir -p /etc/systemd/system/salt-master.service.d/ \
            && echo \'[Unit]\nConditionDirectoryNotEmpty=/etc/salt/master.d/\n\' > /etc/systemd/system/salt-master.service.d/99-ensure-configs.conf"

        node.vm.provision :shell, name: "apply hostname", inline: "echo \'salt-master.local\' > /etc/hostname"

        node.vm.provision :shell, name: "apply host salt-master", inline: "echo \'192.168.57.2 salt-master.local\' >> /etc/hosts"
        (1..NUM_NODES).each do |j|
            node.vm.provision :shell, name: "apply host node-#{j}", inline: "echo \'192.168.57.#{j + 100} node-#{j}.local\' >> /etc/hosts"
        end
        node.vm.provision :shell, name: "reboot for netconf", inline: "echo \"Rebooting to apply network config\"", reboot: true

        # enable salt repo
        node.vm.provision :shell, name: "setup salt key",
            inline: "curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg \
            && echo \"deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/latest jammy main\" | sudo tee /etc/apt/sources.list.d/salt.list"
        node.vm.provision :shell, name: "refresh package list", inline: "apt-get update"

        # install salt packages
        node.vm.provision :shell, name: "install salt packages", inline: "apt-get install salt-minion salt-master salt-ssh salt-syndic salt-cloud salt-api python3-pip libgit2-dev patchelf pkg-config -o Dpkg::Options::=\"--force-confold\" -q -y"
        node.vm.provision :shell, name: "install pygit2 for gitfs", inline: "/opt/saltstack/salt/salt-pip install pygit2 --no-deps --only-binary=:all:"


        node.vm.provision :shell, name: "append to default config", inline: "echo \'\nlog_level: debug\n\' >> /etc/salt/master"

        node.vm.provision :shell, name: "set local salt config", inline: "echo \'id: salt-master\ngrains:\n  nodeid: salt-master\n\' > /etc/salt/local-minion.conf"
        node.vm.provision :shell, name: "append to default config", inline: "echo \'\nlog_level: debug\ninclude: minion.d/*.conf\n\' >> /etc/salt/minion"

        # add auto grains
        node.vm.provision :shell, name: "create autosign grain dir", inline: "mkdir /etc/salt/autosign_grains"
        node.vm.provision :shell, name: "enable autosign salt-master", inline: "echo \'salt-master\' >> /etc/salt/autosign_grains/nodeid"
        (1..NUM_NODES).each do |j|
            node.vm.provision :shell, name: "enable autosign node-#{j}", inline: "echo \'node-#{j}\' >> /etc/salt/autosign_grains/nodeid"
        end

        # extra things required for Alcali, much is managed via salt, but there's also some things just needed as-is
        node.vm.provision :shell, name: "install rest_cherrypy deps", inline: "apt-get install python3-openssl -o Dpkg::Options::=\"--force-confold\" -q -y"
        node.vm.provision :shell, name: "install cherrypy", inline: "pip install cherrypy"
        node.vm.provision :shell, name: "generate self-signed certs", inline: "salt-call --local tls.create_self_signed_cert cacert_path='/etc/pki'"
        node.vm.provision :shell, name: "set cert permissions", inline: "chown -R salt:salt /etc/pki/tls"
        
        # start salt
        node.vm.provision :shell, name: "start salt components", inline: "systemctl enable salt-master && systemctl enable salt-syndic && systemctl enable salt-api && systemctl enable salt-minion", reboot: true

        node.vm.provision :shell, name: "run initial salt apply", inline: "salt '*' state.apply"

        node.vm.provision :shell, name: "create alcali user", inline: "cd /opt/alcali && env DJANGO_SUPERUSER_USERNAME=admin DJANGO_SUPERUSER_EMAIL=admin@kaij.party DJANGO_SUPERUSER_PASSWORD=c0cf93cee41178209205d3c503875a /opt/alcali/.venv/bin/python3 /opt/alcali/code/manage.py createsuperuser --noinput"
    end

    (1..NUM_NODES).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.synced_folder "salt/minion-confs/", "/etc/salt/minion.d/"
            # ensure folders are synced before services start
            node.vm.provision :shell, name: "add vbox workaround", inline: "mkdir -p /etc/systemd/system/salt-minion.service.d/ \
                && echo \'[Unit]\nConditionDirectoryNotEmpty=/etc/salt/minion.d/\n\' > /etc/systemd/system/salt-minion.service.d/99-ensure-configs.conf"

            node.vm.network "private_network", ip: "192.168.57.#{i + 100}"
            node.vm.provision :shell, name: "apply hostname", inline: "echo \'node-#{i}.local\' > /etc/hostname"

            node.vm.provision :shell, name: "apply host salt-master", inline: "echo \'192.168.57.2 salt-master.local\' >> /etc/hosts"
            (1..NUM_NODES).each do |j|
                node.vm.provision :shell, name: "apply host node-#{j}", inline: "echo \'192.168.57.#{j + 100} node-#{j}.local\' >> /etc/hosts"
            end
            node.vm.provision :shell, name: "reboot for netconf", inline: "echo \"Rebooting to apply network config\"", reboot: true

            # enable salt repo
            node.vm.provision :shell, name: "setup salt key",
                inline: "curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg \
                && echo \"deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/latest jammy main\" | sudo tee /etc/apt/sources.list.d/salt.list"
            node.vm.provision :shell, name: "refresh package list", inline: "apt-get update"
            
            # set local params
            node.vm.provision :shell, name: "set local salt config", inline: "echo \'id: node-#{i}\ngrains:\n  nodeid: node-#{i}\' > /etc/salt/local-minion.conf"
            node.vm.provision :shell, name: "append to default config", inline: "echo \'\nlog_level: debug\ninclude: minion.d/*.conf\n\' >> /etc/salt/minion"
            # install salt packages
            node.vm.provision :shell, name: "install salt packages", inline: "apt-get install salt-minion -o Dpkg::Options::=\"--force-confold\" -q -y"

            # start salt
            node.vm.provision :shell, name: "start salt components", inline: "systemctl enable salt-minion", reboot: true
        end
    end
end
