================
Salt Vagrant LXC
================

Instantiate a Salt RAAS development environment using Vagrant and LXC

Hardware Recommendations
========================

LXC containers are generally limited by the ulimit/cgroup resources settings of the
host, but are configurable per instance.

The host managing the LXC containers must have sufficient resources (mem, disk)
to allow for a Salt RAAS dev environment. The following is the minimum recommended
host resource allocation:

Recommendation::

    LXC containers: 1
    Memory per container: 2G (configured JVM limit. More would be better)
    Disk per container: 20G (depends on how much data you want to throw at Cassandra)

Conclusion::

    Min memory available on LXC host: 1 * 2G = 2G
    Min disk available on LXC host: 1 * 20G = 20G


Instructions
============

This project clones data from Salt Stack's private repos on github. PKI is
required to fully automate provisioning of a RAAS dev environment. You must
have at least read access to https://github.com/saltstack/raas and you must
have a public key added to your github account.

By default, the Vagrantfile maps /root/.ssh on your system to /root/.ssh
in the LXC container. If you would like to use key-pairs in a different
location, modify the Vagrantfile to map the correct directory on your host.
For example, replacing `<username>` with your POSIX user in the example
below would map the .ssh directory in your home directory to the LXC
container's /root/.ssh directory. The provisioning script runs as root
within the LXC container.

.. code-block:: Vagrantfile

    ...
    master_config.vm.synced_folder "/home/<usename>/.ssh", "/root/.ssh"
    ...

Run the following commands in a terminal after installing Vagrant, the Vagrant
LXC plugin, and your host's LXC packages.

.. code-block:: bash

    git clone https://github.com/ckochenower/salt-vagrant-lxc.git -b raas_dev
    cd salt-vagrant-lxc
    vagrant up --provider=lxc

Hint: If your OS does not provide a package for the Vagrant LXC plugin, you can
install it from within vagrant:

.. code-block:: bash

   vagrant plugin install vagrant-lxc

This will download an Ubuntu LXC compatible image and create 1 container/node.
The node will be a Salt Master named `master` and a Salt Minion named
`master_minion`. This single node will have Salt, Cassandra, and RAAS installed
from source cloned to /usr/src. None of the respective services will be
installed/started for you. You must start them.

Make sure the container is running:

.. code-block:: bash

    vagrant status

You should see something similar to the following::

    master                    running (lxc)

Open 2 terminals and login to `master` in each terminal. The following is run
from the directory containing the Vagrantfile in this project to login to the
`master`.:

.. code-block:: bash

    vagrant ssh master

Once logged in, become root:

.. code-block:: bash

    sudo -i

Do the following in each respective terminal to start all required processes
(note that the salt-minion and salt-master start automatically on
``vagrant up``. If you want, you can stop them and start them in the
foreground):

Terminal 1:

.. code-block:: bash

    raas -ldebug

Terminal 2:

1. Make sure Cassandra is up and running:

.. code-block:: bash

    nodetool status

You should immediately see something similar to the following:

The first two letters encode the status.

Status - U (up) or D (down)
Indicates whether the node is functioning or not.

State - N (normal), L (leaving), J (joining), M (moving)
The state of the node in relation to the cluster.::

    Datacenter: datacenter1
    =======================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address        Load       Tokens  Owns    Host ID                               Rack
    UN  192.168.50.10  62.75 KB   256     ?       d615dce3-edca-4a3b-858d-9ebb49adcc00  rack1

    Note: Non-system keyspaces don't have the same replication settings, effective ownership information is meaningless


2. List all salt keys. The master_minion will be listed under Unaccepted Keys.::

.. code-block:: bash

    salt-key -L

salt-key -L should produce the following result::

    root@saltmaster:/usr/src# salt-key -L
    Accepted Keys:
    Denied Keys:
    Unaccepted Keys:
    master_minion
    Rejected Keys:

3. Accept the master_minion key.:

.. code-block:: bash

    salt-key -a master_minion

salt-key -L should now produce the following result::

    root@saltmaster:/usr/src# salt-key -L
    Accepted Keys:
    master_minion
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:

4. Make sure the master_minion responds to a test.ping

.. code-block:: bash

    salt '*' test.ping

test.ping should produce the following result::

    master_minion:
        True

5. Login to Cassandra and make sure data is persisting to the DB:

.. code-block:: bash

    root@saltmaster:~# cqlsh localhost -u root -p salt
    Connected to Test Cluster at localhost:9042.
    [cqlsh 5.0.1 | Cassandra 2.1.6 | CQL spec 3.2.0 | Native protocol v3]
    Use HELP for help.
    root@cqlsh> desc keyspaces;

    system_traces  system_auth  raas_a9b1f4bf8aea4fd28b0e24ab9a4  system

    root@cqlsh> use raas_a9b1f4bf8aea4fd28b0e24ab9a4;
    root@cqlsh:raas_a9b1f4bf8aea4fd28b0e24ab9a4> desc tables;

    salt_returns     schema_version  files        groups       routines 
    internal_caches  minions_cache   users        minions      directory
    auth_configs     pillars         minion_keys  permissions
    efilters         salt_events     cmds         audit      
    masters_config   tgts            jids         roles

    root@cqlsh:raas_a9b1f4bf8aea4fd28b0e24ab9a4> select * from jids;

     partkey              | jid                  | user | load
    ----------------------+----------------------+------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     20150623215457029819 | 20150623215457029819 | root | 0x81a46c6f616489a3636d64a77075626c697368a36a6964b43230313530363233323135343537303239383139a66b776172677383ac73686f775f74696d656f7574c3a964656c696d69746572a13aa873686f775f6a6964c2a361726790a475736572a4726f6f74a87467745f74797065a4676c6f62a3726574a0a3746774a12aa366756ea9746573742e70696e67

    (1 rows)

6. Make sure you setup your git config so you don't push as root

.. code-block:: bash

    git config --global user.name "<your name>"
    git config --global user.email "<your e-mail>"

