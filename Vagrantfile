# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT

# Add the DataStax Repo
cat >/etc/apt/sources.list.d/cassandra.sources.list <<EOL
deb http://debian.datastax.com/community stable main
EOL
wget http://debian.datastax.com/debian/repo_key -O /tmp/cassandra.sources.gpg
apt-key add /tmp/cassandra.sources.gpg

# Update
apt-get update

# Install required packages
apt-get install -y git wget psmisc
apt-get install -y python python-dev python-pip python-zmq python-yaml python-msgpack python-m2crypto python-jinja2
apt-get install -y python3 python3-dev python3-pip python3-zmq python3-yaml python3-msgpack python3-tornado
pip install tornado pycrypto cassandra-driver
pip3 install pycrypto aiohttp cassandra-driver jsonschema pytest pytest-tornado ldap3
pip3 install tornado --upgrade
pip3 install msgpack-python --upgrade

# Install Oracle Java
cd /tmp
mkdir -p /usr/lib/jvm
if test -e /srv/downloads/server-jre-8u40-linux-x64.tar.gz
then
    cp /srv/downloads/server-jre-8u40-linux-x64.tar.gz ./
else
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u40-b26/server-jre-8u40-linux-x64.tar.gz
fi
tar xzf server-jre-8u40-linux-x64.tar.gz -C /usr/lib/jvm
update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0_40/bin/java" 1
update-alternatives --set java /usr/lib/jvm/jdk1.8.0_40/bin/java

# Install Cassandra
mkdir -p /etc/cassandra
apt-get install -y dsc21
cp /srv/salt/cassandra/conf/cassandra.yaml /etc/cassandra/
service cassandra restart

# Clone Salt source
cd /usr/src/
git clone https://github.com/saltstack/salt.git -b develop
cd salt

# Install Salt
python3 setup.py install --force
python setup.py install --force
mkdir -p /etc/salt

# Add the following to /etc/salt/master
cat >/etc/salt/master <<EOL
engines:
  raas: {}
master_job_cache: raas
event_return: raas
raas_server: http://192.168.50.10
raas_username: root
raas_password: salt
ext_pillar:
  - raas
EOL

# Add the following to /etc/salt/minion
cat >/etc/salt/minion <<EOL
master: localhost
id: master_minion
EOL

# Get the RAAS source
cd /usr/src
git clone git@github.com:saltstack/raas.git
git clone git@github.com:saltstack/raas_master.git
cd raas

# Install the DB schema
cat >>/tmp/cassandra_create_user.cql <<end-of-script
CREATE USER IF NOT EXISTS root WITH PASSWORD 'salt' NOSUPERUSER;
GRANT ALL PERMISSIONS on ALL KEYSPACES to root;
end-of-script
cqlsh localhost -u cassandra -p cassandra -f /tmp/cassandra_create_user.cql

# Install RAAS
python3 setup.py install --force
cd ../raas_master
cp salt/engines/raas* /usr/local/lib/python2.7/dist-packages/salt/engines/
cp salt/returners/raas* /usr/local/lib/python2.7/dist-packages/salt/returners/
cp salt/fileserver/raas* /usr/local/lib/python2.7/dist-packages/salt/fileserver/
cp salt/pillar/raas* /usr/local/lib/python2.7/dist-packages/salt/pillar/
cd ../raas

#Add the following to /etc/raas/raas
mkdir -p /etc/raas
cd /etc/raas
cat >/etc/raas/raas <<EOL
bigret: cassandra
cassandra:
  cluster:
    - localhost
  port: 9042
  username: root
  password: salt
EOL

salt-master -d -ldebug
salt-minion -d -ldebug

SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define :master do |master_config|
    #master_config.vm.box = "fgrehm/precise64-lxc"
    #master_config.vm.box = "fgrehm/centos-6-64-lxc"
    master_config.vm.box = "fgrehm/trusty64-lxc"
    master_config.vm.host_name = 'saltmaster.local'
    master_config.vm.network "private_network", ip: "192.168.50.10", lxc__bridge_name: 'virbr0'
    master_config.vm.synced_folder "/root/.ssh", "/root/.ssh"
    master_config.vm.synced_folder "saltstack/salt/", "/srv/salt"
    master_config.vm.synced_folder "saltstack/pillar/", "/srv/pillar"
    master_config.vm.synced_folder "saltstack/reactor/", "/srv/reactor"
    master_config.vm.synced_folder "saltstack/downloads/", "/srv/downloads"

    master_config.vm.provision "shell", inline: $script
  end

end
