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
        node.vm.network "forwarded_port", guest: 8000, host: 8124
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
        node.vm.provision :shell, name: "install postgres repo", inline: "echo \"deb http://apt.postgresql.org/pub/repos/apt jammy-pgdg main\" > /etc/apt/sources.list.d/pgdg.list"
        node.vm.provision :shell, name: "install postgres signing key", inline: "curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg"
        node.vm.provision :shell, name: "refresh package list", inline: "apt-get update"

        # install salt packages
        node.vm.provision :shell, name: "install salt packages", inline: "apt-get install salt-minion salt-master salt-ssh salt-syndic salt-cloud salt-api python3-pip libgit2-dev patchelf pkg-config python3-psycopg2 -o Dpkg::Options::=\"--force-confold\" -q -y"
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
        node.vm.provision :shell, name: "get alcali module", inline: "mkdir -p /srv/salt/auth/ && curl -o /srv/salt/auth/alcali.py https://raw.githubusercontent.com/latenighttales/alcali/v3006.3.0/docker/saltconfig/salt/auth/alcali.py"


        # install and setup postgres16, used as a returner for salt minions
        node.vm.provision :shell, name: "install postgres16", inline: "apt-get install postgresql-16 postgresql-contrib-16 -o Dpkg::Options::=\"--force-confold\" -q -y"
        node.vm.provision :shell, name: "install psycopg2", inline: "/opt/saltstack/salt/salt-pip install psycopg2-binary"
        node.vm.provision :shell, name: "global access psql", inline: "echo \"listen_addresses = '127.0.0.1,192.168.57.2'\" >> /etc/postgresql/16/main/postgresql.conf"
        node.vm.provision :shell, name: "setup acls", inline: "echo \"local all postgres ident\nhost salt alcali 127.0.0.1/32 md5\nhost salt salt 127.0.0.1/32 md5\nhost salt salt 192.168.57.0/24 md5\n\" > /etc/postgresql/16/main/pg_hba.conf"
        node.vm.provision :shell, name: "start postgresql", inline: "systemctl enable --now postgresql"
        node.vm.provision :shell, name: "create roles and database", inline: <<-'SCRIPT'
sudo -u postgres psql << EOF
CREATE ROLE salt WITH PASSWORD 'e8b61efb5667ef953b704fce877bbe3f' LOGIN;
CREATE DATABASE salt WITH OWNER salt;

-- TODO Better privileges
EOF
SCRIPT
        node.vm.provision :shell, name: "create roles and database", inline: <<-'SCRIPT'
env PGPASSWORD="e8b61efb5667ef953b704fce877bbe3f" psql -h 127.0.0.1 -U salt -d salt << EOF
--
-- Table structure for table 'jids'
--

DROP TABLE IF EXISTS jids;
CREATE TABLE jids (
  jid   varchar(20) PRIMARY KEY,
  load  text NOT NULL
);

--
-- Table structure for table 'salt_returns'
--

DROP TABLE IF EXISTS salt_returns;
CREATE TABLE salt_returns (
  fun       varchar(50) NOT NULL,
  jid       varchar(255) NOT NULL,
  return    text NOT NULL,
  full_ret  text,
  id        varchar(255) NOT NULL,
  success   varchar(10) NOT NULL,
  alter_time   TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_salt_returns_id ON salt_returns (id);
CREATE INDEX idx_salt_returns_jid ON salt_returns (jid);
CREATE INDEX idx_salt_returns_fun ON salt_returns (fun);
CREATE INDEX idx_salt_returns_updated ON salt_returns (alter_time);

--
-- Table structure for table salt_events
--

DROP TABLE IF EXISTS salt_events;
DROP SEQUENCE IF EXISTS seq_salt_events_id;
CREATE SEQUENCE seq_salt_events_id;
CREATE TABLE salt_events (
    id BIGINT NOT NULL UNIQUE DEFAULT nextval('seq_salt_events_id'),
    tag varchar(255) NOT NULL,
    data text NOT NULL,
    alter_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    master_id varchar(255) NOT NULL
);

CREATE INDEX idx_salt_events_tag on salt_events (tag);

-- TODO: Fix privileges of alcali
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO alcali;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO salt;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO alcali;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO salt;

EOF
SCRIPT
 
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
            node.vm.provision :shell, name: "install salt packages", inline: "apt-get install salt-minion salt-master salt-ssh salt-syndic salt-cloud salt-api python3-pip libgit2-dev patchelf pkg-config python3-psycopg2 -o Dpkg::Options::=\"--force-confold\" -q -y"
            node.vm.provision :shell, name: "install psycopg2", inline: "/opt/saltstack/salt/salt-pip install psycopg2-binary"

            # start salt
            node.vm.provision :shell, name: "start salt components", inline: "systemctl enable salt-minion", reboot: true
        end
    end
end
