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
have at least read access to https://github.com/SS-priv/raas and you must
have a public key added to your github account.

By default, the Vagrantfile maps /root/.ssh on your system to /root/.ssh on
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

Open 4 terminals and login to `master` in each terminal. The following is run
from the directory containing the Vagrantfile in this project to login to the
`master`.:

.. code-block:: bash

    vagrant ssh master

Once logged in, become root:

.. code-block:: bash

    sudo -i

Do the following in each respective terminal to start all required processes:

Terminal 1:

.. code-block:: bash

    raas

Terminal 2:

.. code-block:: bash

    salt-master -l debug

Terminal 3:

.. code-block:: bash

    salt-minion -l debug 

Terminal 4:

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

2. Make sure the master_minion responds to a test.ping

.. code-block:: bash

    salt '*' test.ping

test.ping should produce the following result::

    master_minion:
        True

3. List all salt keys. The master_minion will be listed under Unaccepted Keys.::

.. code-block:: bash

    salt-key -L

salt-key -L should produce the following result::

    root@saltmaster:/usr/src# salt-key -L
    Accepted Keys:
    Denied Keys:
    Unaccepted Keys:
    master_minion
    Rejected Keys:

4. Accept the master_minion key.:

.. code-block:: bash

    salt-key -a master_minion

salt-key -L should now produce the following result::

    root@saltmaster:/usr/src# salt-key -L
    Accepted Keys:
    master_minion
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:

5. Login to Cassandra and make sure data is persisting to the DB:

.. code-block:: bash

    root@saltmaster:/usr/src# cqlsh 192.168.50.10 -u salt -p salt -k salt
    salt@cqlsh:salt> desc tables;
        
    salt_returns  cmd            minions_cache  salt_events  minions
    tgt           master_config  jids           minion_key 
    salt@cqlsh:salt> select * from jids;
    
     customer_id                          | jid                  | load
    --------------------------------------+----------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     a9b1f4bf-8aea-4fd2-8b0e-24ab9a416859 | 20150427192150556978 | {"fun": "test.ping", "ret": "", "tgt": "*", "arg": [], "jid": "20150427192150556978", "cmd": "publish", "kwargs": {"show_jid": false, "delimiter": ":", "show_timeout": true}, "tgt_type": "glob", "user": "sudo_vagrant"}
    
    (1 rows)
