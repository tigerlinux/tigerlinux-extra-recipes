# OPENSTACK ALL-IN-ONE (AIO) FULLY AUTOMATED BOOTSTRAP SCRIPT

Supported Operating Systems: Centos 7 and Ubuntu 16.04lts (both 64 bits). OpenStack RELEASE: OCATA.


## Scripts included on this directory:

- openstack-bootstrap-centos7.sh: OpenStack bootstrap installer for Centos 7.
- openstack-bootstrap-ubuntu1604lts.sh: OpenStack bootstrap installer for Ubuntu 16.04lts.
- openstack-bootstrap-centos7-single-nic.sh: OpenStack bootstrap installer For single-nic environments (centos only, tested on baremetal and packet.net bonding mode networking).


## Usage:

Base requeriments:

- Distribution: Centos 7 or Ubuntu 16.04lts, x86_64 (64 bits).
- Minimun hardware: 2 cores/threads, 8GB RAM, 10GB Free for the "/usr" partition, and 50GB Free for the "/var" partition, or if a single partition for all (/) 50GB free total.
- The server must have internet access and at least one usable (static) IP Address.

Copy the script to any place inside the operating system, and run it as "root" (please don't use "sudo". Become root with "sudo su -" or enter ssh as root and run the script).


## What the script does ?:

The script perform the following actions in the operating system:

- Verifies the base Operating System environment. If the O/S is unsupported by the script, it exits and show an error to the console indicating the unsupported platform.
- Download and install (yum/apt-get) some packages needed to properly run.
- Verifies the minimum hardware requirements, and if the machine does not meet the minimums, it exits indicating the hardware does not meet the minimum requirements for OpenStack.
- Install and configures openvswitch, and creates internal testing interfaces and switches based on the "dummy" ethernet interface. The internal switch is named "br-dummy0", attached  to the dummy0 interface.
- Install and configures two loop devices, one for swift (5 gb), and one for cinder persistent storage (10 gb).
- Downloads (using git) the "tigerlinux" semi-automatted OpenStack installers from github.
- Configures the "tigerlinux" semi-automatted installers, then perform a basic cleanup and run the installer in fully automated mode.
- Check that the OpenStack installer has run properly and openstack is installed. If the check fails, it exits indicating the error.
- Download's two cloud images, one for Centos 7, one for Ubuntu 16.04lts, and include them to Glance.
- Creates an external network over the br-dummy0 bridge.
- Creates an internal network (gre mode).
- Cretes two subnets, one for each network (one for the external net, one for the internal net).
- Creates the router enabling communication between both nets.
- Creates some flavors.
- Creates an admin user "osadmin" with a random-generated password.
- Creates (if does not already exist) an RSA ssh-key (/root/.ssh/id_rsa, /root/.ssh/id_rsa.pub) and includes the key on OpenStack for the osadmin user.
- Creates a rc file for the osdmin user (/root/keystonerc_fullosadmin).
- Finally, it writes a file with all user credentiales at "/root/openstack-credentials.txt"

The last file (/root/openstack-credentials.txt) contains everything the user needs in order to access the OpenStack installation.


## SINGLE-NIC special version:

The script **openstack-bootstrap-centos7-single-nic.sh** can install openstack and set-up ovs networking on a single-nic server. This script will not create the "dummy0" based testing-network. Instead, it will convert the primary interface on a "ovs" switched interface and pass the IP to the switch. It can do it on bonded and non-bonded interfaces. The external network and bridge-mappings will be configured on this interface so the only remaining task the user need to do is to create the subnet (or subnets) on the public/external network.


## OpenStack modules installed:

This solution install and configures the following OpenStack (OCATA) modules:

- Base requirements (libraries, libvirtd, etc.).
- Database (MariaDB 10).
- Message Broker (RabbitMQ).
- Keystone (identity).
- Swift (object storage).
- Glance (images).
- Cinder (persistent block storage).
- Neutron (networking, with ML2/OVS plugin, fwaas and lbaasv2).
- Nova (compute). If the machine does not support hardware virtualization, it reconfigures nova-compute with qemu instead of kvm.
- Ceilometer/AODH/Gnocchi (Metrics/Alarming). Note: Gnocchi is configured with file backend as primary storage.
- Heat (orchestration/cloudformation).
- Horizon (web-dashboard)



## Instances running in the server:

Because the external network is based on a "dummy" net, the instances can only be reached from inside the OpenStack server, but, the instances can reach the interned due special IPTABLES rules created by the installer.

The user can launch instances using the resources created by this installer, and/or include its own resources (networks, images, etc.) in order to further customize the OpenStack installation.



## Running time:

Because the complexity of OpenStack installation, and due the fact that all resources are downloaded from the Internet, the installation is bound to take several minutes (20-40 minutes, maybe more if Internet conditions are far from ideal). The installation on Ubuntu can be about 50% longer that the one for Centos.


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7 or Ubuntu 16.04lts.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 8GB.
- CPU: 2 Core/Thread.
- FREE DISK SPACE: 10GB.


END.-
