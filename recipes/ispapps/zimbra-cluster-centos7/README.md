# ZIMBRA HA-INSTALL WITH PACEMAKER, COROSYNC AND DRBD ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

This recipe will allow you to install a cluster-aware Zimbra-based e-mail solution on Centos 7, using the following components:

- DRBD: The complete /opt/zimbra directory will be pointed on both servers to a drbd-based resource.
- Pacemaker/Corosync: This is the cluster control. We'll use 4 cluster-declared resources in our solution: The DRBD data sincronization, the filesystem mounted using the drbd backend, a Virtual IP (which is married to the Zimbra services FQDN), and a zimbra service declared as a OCF resource.

Because zimbra uses all it's storage and configuration in /opt/zimbra, this is the place you want to share between nodes using drbd. All other things works like most cluster solutions in the wild.

This recipe will guide you trough all the steps you need to perform "in right order" for a complete, production-class, zimbra active/pasive e-mail solution. 


## Environment:

Two Centos 7 servers, each with two HD's (virtualized on OpenStack). First disk for O/S, second disk for DRBD shared space. Both servers with EPEL-7 enabled, firewalld and selinux disabled, fully updated (centos 7.3.1611 updated up to dic 20 2016).

IP's:

node-01: 172.16.70.58 - hostname: instance-172-16-70-58.virt.tac.dom
node-02: 172.16.70.51 - hostname: instance-172-16-70-51.virt.tac.dom


## Domain part:

DNS Domain: zimbratest.dom
DNS MX: mail.zimbratest.dom (IP: 172.16.70.210)

The IP 172.16.70.210 will be configured as a cluster resource in corosync/pacemaker, and the FQDN "mail.zimbratest.dom" will be used as hostname in the zimbra configuration.


## Procedures:

Note that those procedures need to be performed in the order declared in this document. Fail to do all steps in proper order, and your solution will not work at all.


### STEP ONE: Basic servers setup:

Let's do some basic server setup first. First thing to do, is to re-enable "ssh" for root, and create a by-directional ssh trust between both servers.

**NOTE:** Because our servers are cloud (OpenStack based) we should reconfigure our "cloud-init" is reconfigured to allow ssh for root too. For this to work, edit the file `/etc/cloud/cloud.cfg` on both servers and change:

```bash
disable_root: 0
ssh_pwauth:   1
```

Then save the file.

Also, re-enable ssh for root and set a password for it (later we can lock the password):

In both servers, edit:

```bash
vi /etc/ssh/sshd_config
```

Set the following parameters to "yes":

```bash
PasswordAuthentication yes
PermitRootLogin yes
```

Then run the following commands:

```bash
rm -f /root/.ssh/authorized_keys
echo "root:P@ssw0rd"|chpasswd
systemctl restart sshd
```

Remember this has to be done on both servers.

Once the ssh part is ready, we need to generate the ssh-keys.

In the first node (172.16.70.58) execute the following commands (inside the root account):

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo 'Host *' > ~/.ssh/config
echo 'StrictHostKeyChecking no' >> ~/.ssh/config
echo 'UserKnownHostsFile=/dev/null' >> ~/.ssh/config
chmod 600 ~/.ssh/config
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Then, copy the ssh directory from node 01 (172.16.70.58) to node 02 (172.16.70.51) - remember it will ask the password previouslly set before (`echo "root:P@ssw0rd"|chpasswd`):

```bash
scp -r ~/.ssh 172.16.70.51:/root/
```

Now, in both nodes and in order to ensure proper name resolution (even in the event of a DNS failure) run the following commands:

```bash
echo "172.16.70.58 node-01.zimbratest.dom node-01" >> /etc/hosts
echo "172.16.70.51 node-02.zimbratest.dom node-02" >> /etc/hosts
echo "172.16.70.210 mail.zimbratest.dom mail" >> /etc/hosts
```

Lock the root password on both servers:

```bash
passwd -l root
```

Ensure that nor sendmail neither postfix are running (port 25 must be available for zimbra). Do this on both servers:

```bash
systemctl disable sendmail
systemctl disable postfix
systemctl stop sendmail
systemctl stop postfix
```

And, create the following directory on both servers:

```bash
mkdir -p /mnt/zimbra-storage
```

This concludes the basic server setup


### STEP 2: DRBD basic setup.

First, add the repositories for DRBD in centos 7 (elrepo.org) on both servers:

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum clean all && yum -y update
```

Then, in both servers, install drbd and load drbd module:

```bash
yum -y install kmod-drbd84 drbd84-utils drbd84-utils-sysvinit
modprobe drbd
```

In both servers, proceed to create the "zimbradrbd" resource:

```
vi /etc/drbd.d/zimbradrbd.res
```

Contents:

```bash
resource zimbradrbd {
    protocol C;
    disk {
        # on I/O errors, detach device
        on-io-error detach;
    }

    meta-disk internal;
    device /dev/drbd1;

    syncer {
        verify-alg sha1;
        rate 40M;
    }

    net {
        allow-two-primaries;
    }

    on instance-172-16-70-58.virt.tac.dom {
        device /dev/drbd0;
        disk /dev/vdb;
        address 172.16.70.58:7789;
        meta-disk internal;
    }
    on instance-172-16-70-51.virt.tac.dom {
        device /dev/drbd0;
        disk /dev/vdb;
        address 172.16.70.51:7789;
        meta-disk internal;
    }
}
```

Then save the file.

**NOTE SOMETHING HERE: Because our LAB servers only have one ethernet giga interface, we are limiting the DRBD traffic to about 40% of total traffic (40M). In production environment, you should have a secondary ethernet per server and dedicate DRBD traffic on this interface. This also means adjust the rate to a higher values, nearing 90% of available ethernet bandwidth for your setup.**

In both servers, run the following commands:

```bash
dd if=/dev/zero bs=1M count=10 of=/dev/vdb
sync

drbdadm create-md zimbradrbd
```

Now, execute the following commands on the first node (172.16.70.58):

```bash
modprobe drbd
drbdadm up zimbradrbd

drbdadm -- --overwrite-data-of-peer primary zimbradrbd
```

Then in both servers run the commands:

```bash
systemctl start drbd
systemctl enable drbd
systemctl status drbd
```

Those steps will do the first DRBD synchronization. Here, you'll need to wait until the DRBD volume is fully in sync. You can monitor the proccess by issuing the following command in any of the servers:


```bash
while true; do clear; cat /proc/drbd; sleep 10;done
```

This command will put a "loop" showing the status of the DRBD. It will be fully sinchronized when it reaches 100% percent. Once this happens, you can continue to next steps.


### EXTRA SETUP FOR OPENSTACK ONLY (needed for VIP sharing between servers)

If you are not using OpenStack, omit this section. Otherwise you need to allow the VIP to be present in the VM's ports. This is acomplished using "allowed address pairs" Neutron feature. If you fail to do this in OpenStack, your VIP will be unable to be contacted.

For this LAB, our VIP is 172.16.70.210 (fqdn: mail.zimbratest.dom), our network name in neutron is "shared-01" and our security group name is FULLACCESS (id: ca88d014-42e3-43e7-874e-3d5aa4d8eefd).

First, proceed to create the port with the IP 172.16.70.210 in the network "shared-01" and with the security group "ca88d014-42e3-43e7-874e-3d5aa4d8eefd":

```
neutron port-create --fixed-ip ip_address=172.16.70.210 --security-group ca88d014-42e3-43e7-874e-3d5aa4d8eefd shared-01
```

For our LAB, this created the port with ID: b4a9d2b4-5cc6-4ad5-8362-472c77d6c8dc

Then, proceed to obtain the port ID's containing the IP's 172.16.70.58 and 172.16.70.51 (our zimbra nodes IP's):

```
neutron port-list|grep 172.16.70.58|awk '{print $2}'
7589eff5-44d1-4185-bde5-783004010ca0

neutron port-list|grep 172.16.70.51|awk '{print $2}'
1177f4a0-99e5-4bd1-ba31-94b2e9e33b8b
```

And with this information, update both ports with allowed address pairs poiting to the VIP:

```
neutron port-update 7589eff5-44d1-4185-bde5-783004010ca0 --allowed_address_pairs list=true type=dict ip_address=172.16.70.210
neutron port-update 1177f4a0-99e5-4bd1-ba31-94b2e9e33b8b --allowed_address_pairs list=true type=dict ip_address=172.16.70.210
```

Now, the VIP will be allowed to exist on any of the zimbra nodes. This step is **MANDATORY** for any OpenStack solution using cluster-based floating VIP's. OpenStack anti-spoofing rules are very strong, and without this step, the VIP wont be able to be contacted.

**NOTE: Most cloud's apply very strong anti-spoofing measures that won't allow a "Floating VIP" to exist unless you take the proper steps. Please document yourself very well if you plan to use this recipe in a cloud like AWS.**



### STEP 3: Cluster software setup - part 1 (IP Resource)

In order to make a proper cluser-based zimbra installation, we need to do some steps in specific order. First thing to do is install all cluster software in the servers, and enable our first shared resource: The IP (for our LAB: 172.16.70.210. This is the IP linked to the name: mail.zimbratest.dom, mean, our MX).

First, on both servers install the software:

```bash
yum -y install pacemaker pcs corosync resource-agents pacemaker-cli
```

Set the "hacluster" account password in both servers:

```bash
echo "hacluster:P@ssW0rdCl7sT3r"|chpasswd
```

In both servers proceed to start the pcsd service:

```bash
systemctl start pcsd
systemctl status pcsd
```

And in both servers, authorize both nodes:

```bash
pcs cluster auth instance-172-16-70-58 instance-172-16-70-51
```

(this last command will ask for the "hacluster" account and it's password).

The last command should return that both servers are authorized (or already authorized).

Now, you can work the following commands in the first node (172.16.70.58):

Create the cluster:

```bash
pcs cluster setup --name cluster_zimbra instance-172-16-70-58 instance-172-16-70-51

pcs cluster start --all
```

Check cluster status:

```bash
pcs status cluster
corosync-cmapctl | grep members
pcs status corosync
```

Verify the config state and disable stonith:

```bash
crm_verify -L -V
pcs property set stonith-enabled=false
```

And disable the quorum policy, as there are only two nodes:

```bash
pcs property set no-quorum-policy=ignore
pcs property
```

Proceed to create our VIP resource (IP: 172.16.70.210):

```bash
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=172.16.70.210 cidr_netmask=32 nic=eth0:0 op monitor interval=30s
```

**VERY IMPORTANT NOTE: As our ethernet interfaces are named "eth0", we choose our eth alias as "eth0:0". Adjust this alias based on your ethernet names. Fail to do this properlly, and prepare to live in a world full of pain !.**

As soon as we complete this command, we can see this IP ready in the node with "ip a" or "ifconfig". Note that the IP can be started on any of both nodes so check on both servers.

Verify the state of our resources:

```bash
pcs status resources


virtual_ip     (ocf::heartbeat:IPaddr2):       Started instance-172-16-70-51
```

At this point, we need to enable all our cluster related services IN BOTH SERVERS:

```bash
systemctl enable pcsd
systemctl enable corosync
systemctl enable pacemaker
```

**BUGFIX: Due an existing bug with the corosync service, you'll need to include a 10 seconds delay in the systemd script. Please perform this VERY VITAL STEP IN BOTH SERVERS:**

```bash
vi /usr/lib/systemd/system/corosync.service
```

After "[service]" section, add the following line:

```bash
ExecStartPre=/usr/bin/sleep 10
```

So the file new content will be:

```bash
[Unit]
Description=Corosync Cluster Engine
ConditionKernelCommandLine=!nocluster
Requires=network-online.target
After=network-online.target

[Service]
ExecStartPre=/usr/bin/sleep 10
ExecStart=/usr/share/corosync/corosync start
ExecStop=/usr/share/corosync/corosync stop
Type=forking

# The following config is for corosync with enabled watchdog service.
#
#  When corosync watchdog service is being enabled and using with
#  pacemaker.service, and if you want to exert the watchdog when a
#  corosync process is terminated abnormally,
#  uncomment the line of the following Restart= and RestartSec=.
#Restart=on-failure
#  Specify a period longer than soft_margin as RestartSec.
#RestartSec=70
#  rewrite according to environment.
#ExecStartPre=/sbin/modprobe softdog soft_margin=60

[Install]
WantedBy=multi-user.target
```

Proceed to save the file and reload systemctl daemon, again, in both servers:

```bash
systemctl daemon-reload
```

**NOTE: Again, fail to do this very important step, and "again", prepare to live in a world full of pain !.**


### STEP 4: Cluster software setup - part 2 (DRBD Resource)

Note that our DRBD resource will be used in order to share zimbra storage between both servers. Basically, we'll ensure that our /opt/zimbra is symlinked to /mnt/zimbra-storage, but first, we need to create the drbd part.

First stage: Ensure your first node (172.16.70.58) is the DRBD primary by running the following command:

```bash
drbdadm primary zimbradrbd
```

And ensure your other node (172.16.70.51) is the secondary:

```bash
drbdadm secondary zimbradrbd
```

In your first server (172.16.70.51, which is your drbd primary rigth now) proceed to create the xfs filesystem for zimbra:

```bash
mkfs.xfs -L zimbra01 /dev/drbd0
```

Then, ensure both your servers are primary (run this only in your first server):

```bash
drbdadm primary all
```

**NOTE: Fail to do this, and you'll end with a SPLIT BRAIN situation.**

Then, in both nodes, proceed to stop and disable the DRBD service, as it will be controlled by the cluster service.

```bash
systemctl stop drbd
systemctl disable drbd
systemctl status drbd
```

Proceed to create the DRBD resource. The following steps will be performed on the first server (172.16.70.58):

```bash
cd /
pcs cluster cib add_drbd
```

This create the file: /add_drbd

Then:

```bash
cd /
pcs -f add_drbd resource create zimbra_data ocf:linbit:drbd drbd_resource=zimbradrbd op monitor interval=60s
pcs -f add_drbd resource master zimbra_data_sync zimbra_data master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

Now, proceed to fix the following file permission IN BOTH SERVERS or the DRBD resource will not work:

**Remember: Both servers:**

```bash
chmod 777 /var/lib/pacemaker/cores
```

Back on the primary node (172.16.70.58), run the following commands:

```bash
cd /
pcs cluster cib-push add_drbd
```

That last command creates the DRBD resource into the cluster services.

Then, in both servers proceed to create the following script:

```
vi /usr/lib/ocf/resource.d/heartbeat/zimbractl
```

With the contents:

```bash
#!/bin/sh
#
# Resource script for Zimbra
#
# Description:  Manages Zimbra as an OCF resource in
#               an high-availability setup.
#
# Author:       RRMP <tigerlinux@gmail.com>
# License:      GNU General Public License (GPL)
#
#
#       usage: $0 {start|stop|reload|monitor|validate-all|meta-data}
#
#       The "start" arg starts a Zimbra instance
#
#       The "stop" arg stops it.
#
# OCF parameters:
#  OCF_RESKEY_binary
#  OCF_RESKEY_config_dir
#  OCF_RESKEY_parameters
#
##########################################################################

# Initialization:

: ${OCF_FUNCTIONS_DIR=${OCF_ROOT}/lib/heartbeat}
. ${OCF_FUNCTIONS_DIR}/ocf-shellfuncs

: ${OCF_RESKEY_binary="zmcontrol"}
: ${OCF_RESKEY_zimbra_dir="/opt/zimbra"}
: ${OCF_RESKEY_zimbra_user="zimbra"}
: ${OCF_RESKEY_zimbra_group="zimbra"}
USAGE="Usage: $0 {start|stop|reload|status|monitor|validate-all|meta-data}";

##########################################################################

usage() {
	echo $USAGE >&2
}

meta_data() {
	cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="postfix">
<version>0.1</version>
<longdesc lang="en">
This script manages Zimbra as an OCF resource in a high-availability setup.
</longdesc>
<shortdesc lang="en">Manages a highly available Zimbra mail server instance</shortdesc>

<parameters>

<parameter name="binary" unique="0" required="0">
<longdesc lang="en">
Short name to the Zimbra control script.
For example, "zmcontrol" of "/etc/init.d/zimbra".
</longdesc>
<shortdesc lang="en">
Short name to the Zimbra control script</shortdesc>
<content type="string" default="zmcontrol" />
</parameter>

<parameter name="zimbra_dir" unique="1" required="0">
<longdesc lang="en">
Full path to Zimbra directory.
For example, "/opt/zimbra".
</longdesc>
<shortdesc lang="en">
Full path to Zimbra directory</shortdesc>
<content type="string" default="/opt/zimbra" />
</parameter>

<parameter name="zimbra_user" unique="1" required="0">
<longdesc lang="en">
Zimbra username.
For example, "zimbra".
</longdesc>
<shortdesc lang="en">Zimbra username</shortdesc>
<content type="string" default="zimbra" />
</parameter>

<parameter name="zimbra_group"
 unique="1" required="0">
<longdesc lang="en">
Zimbra group.
For example, "zimbra".
</longdesc>
<shortdesc lang="en">Zimbra group</shortdesc>
<content type="string" default="zimbra" />
</parameter>

</parameters>

<actions>
<action name="start"   timeout="360s" />
<action name="stop"    timeout="360s" />
<action name="reload"  timeout="360s" />
<action name="monitor" depth="0"  timeout="40s"
 interval="60s" />
<action name="validate-all"  timeout="360s" />
<action name="meta-data"  timeout="5s" />
</actions>
</resource-agent>
END
}

case $1 in
meta-data)
	meta_data
	exit $OCF_SUCCESS
	;;

usage|help)
	usage
	exit $OCF_SUCCESS
	;;
start)
	echo "Starting Zimbra Services"
	echo "0" > /var/log/db-svc-started.log
	rm -f /var/log/zimbra-svc-stopped.log
	if [ -f /etc/init.d/zimbra ]
	then
		/etc/init.d/zimbra start
	fi
	ocf_log info "Zimbra started."
	exit $OCF_SUCCESS
	;;
stop)
	echo "Stopping Zimbra Services"
	rm -f /var/log/db-svc-started.log
	echo "0" > /var/log/zimbra-svc-stopped.log
	if [ -f /etc/init.d/zimbra ]
	then
		/etc/init.d/zimbra stop
		/bin/killall -9 -u zimbra
	fi
	ocf_log info "Zimbra stopped."
	exit $OCF_SUCCESS
	;;
status|monitor)
	echo "Zimbra Services Status"
	if [ -f /var/log/zimbra-svc-started.log ]
	then
		exit $OCF_SUCCESS
	else
		exit $OCF_NOT_RUNNING
	fi
	;;
restart|reload)
	echo "Zimbra Services Restart"
	ocf_log info "Reloading Zimbra."
	if [ -f /etc/init.d/zimbra ]
	then
		/etc/init.d/zimbra stop
		/bin/killall -9 -u zimbra
		/etc/init.d/zimbra start
	fi
	exit $OCF_SUCCESS
	;;
validate-all)
	echo "Validating Zimbra"
	exit $OCF_SUCCESS
	;;
*)
	usage
	exit $OCF_ERR_UNIMPLEMENTED
	;;
esac
```

Save the file, and change it's mode to 755:

```bash
chmod 755 /usr/lib/ocf/resource.d/heartbeat/zimbractl
```

In the primary node (172.16.70.58) proceed to create the service in the cluster:

```bash
pcs resource create svczimbra ocf:heartbeat:zimbractl op monitor interval=30s
```

In order to allow the script to be somewhat independent from the cluster service, proceed to remove the monitor:

```bash
pcs resource op remove svczimbra monitor
```

Apply the proper constrains in order to link the VIP with the resource and set the preferent node to "instance-172-16-70-58":

```bash
pcs constraint colocation add svczimbra virtual_ip INFINITY
pcs constraint order virtual_ip then svczimbra
pcs constraint location svczimbra prefers instance-172-16-70-58
```

With `pcs status`, check the cluster and services status:

```bash
pcs status
Cluster name: cluster_zimbra
Stack: corosync
Current DC: instance-172-16-70-51 (version 1.1.15-11.el7_3.2-e174ec8) - partition with quorum
Last updated: Wed Dec 21 10:22:12 2016          Last change: Wed Dec 21 10:14:43 2016 by root via cibadmin on instance-172-16-70-58

2 nodes and 4 resources configured

Online: [ instance-172-16-70-51 instance-172-16-70-58 ]

Full list of resources:

 virtual_ip     (ocf::heartbeat:IPaddr2):       Started instance-172-16-70-58
 Master/Slave Set: zimbra_data_sync [zimbra_data]
     Masters: [ instance-172-16-70-58 ]
     Slaves: [ instance-172-16-70-51 ]
 svczimbra      (ocf::heartbeat:zimbractl):     Started instance-172-16-70-58

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Now, proceed to add the filesystem resource. Perform the following steps in your primary node (172.16.70.58):

```
cd /
pcs cluster cib add_fs
pcs -f add_fs resource create zimbra_fs Filesystem device="/dev/drbd/by-res/zimbradrbd" directory="/mnt/zimbra-storage" fstype="xfs"
pcs -f add_fs constraint colocation add zimbra_fs zimbra_data_sync INFINITY with-rsc-role=Master
pcs -f add_fs constraint order promote zimbra_data_sync then start zimbra_fs
pcs -f add_fs constraint colocation add svczimbra zimbra_fs INFINITY
pcs -f add_fs constraint order zimbra_fs then svczimbra
pcs cluster cib-push add_fs
```

At this point, all resources must be fully available in the node **"172.16.70.58"**.

You can do a crash test by rebooting the primary node, or, by issuing the following commands:

Proceed to stop the primary node:

```
pcs cluster stop instance-172-16-70-58
```

All resources will go to instance-172-16-70-51.

And if you start the primary node again:

```
pcs cluster start instance-172-16-70-58
```

All resources will go back to instance-172-16-70-58

This part conclude the cluster configuration, so it's time to install and configure Zimbra.


### STEP 5: Zimbra setup - first node (172.16.70.58)

First, ensure your primary node (172.16.70.58) has all resources (`pcs status`). This is vital, as our first zimbra install need the IP and DRBD resources online and present in the server.

Then, download and uncompress the zimbra software using the following commands:

```bash
yum -y install wget
mkdir /var/workdir
ln -s /var/workdir /workdir
cd /workdir
wget https://files.zimbra.com/downloads/8.7.1_GA/zcs-8.7.1_GA_1670.RHEL7_64.20161025045328.tgz
tar -xzvf zcs-8.7.1_GA_1670.RHEL7_64.20161025045328.tgz -C /usr/local/src/
```

Also, copy the software (using scp) from the first node to the second one:

```bash
scp -r /usr/local/src/zcs-8.7.1_GA_1670.RHEL7_64.20161025045328 172.16.70.51:/usr/local/src/
```

Now, let's do some automation. In our primary node (172.16.70.58) proceed to create the file:

```bash
vi /root/zimbraconfig.cfg
```

Containing:

```bash
AVDOMAIN="zimbratest.dom"
AVUSER="admin@zimbratest.dom"
CREATEADMIN="admin@zimbratest.dom"
CREATEADMINPASS="P@ssw0rd"
CREATEDOMAIN="zimbratest.dom"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="mail.zimbratest.dom"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="P@ssw0rd"
LDAPPOSTPASS="P@ssw0rd"
LDAPROOTPASS="P@ssw0rd"
LDAPADMINPASS="P@ssw0rd"
LDAPREPPASS="P@ssw0rd"
LDAPBESSEARCHSET="set"
LDAPHOST="mail.zimbratest.dom"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="972"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@zimbratest.dom"
SMTPHOST="mail.zimbratest.dom"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@zimbratest.dom"
SNMPNOTIFY="yes"
SNMPTRAPHOST="mail.zimbratest.dom"
SPELLURL="http://mail.zimbratest.dom:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.7"
TRAINSAHAM="ham.__pmk747iv@zimbratest.dom"
TRAINSASPAM="spam.wmyxq9qbc@zimbratest.dom"
UIWEBAPPS="yes"
UPGRADE="yes"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.89ctpzdl@zimbratest.dom"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="P@ssw0rd"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="P@ssw0rd"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="P@ssw0rd"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/lib/jvm/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP="172.16.20.11 172.16.20.10"
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="TRUE"
zimbraMtaMyNetworks="127.0.0.0/8 [::1]/128 172.16.70.0/24"
zimbraPrefTimeZoneId="America/Caracas"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckNotificationEmail="admin@zimbratest.dom"
zimbraVersionCheckNotificationEmailFrom="admin@zimbratest.dom"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="TRUE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-dnscache zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy "
```

Adapt the file to your needs but the most important parts are:

- All the passwords (set here to P@ssw0rd).
- The zimbraMtaNetworks (172.16.70.0/24 included here).
- The timezone (America/Caracas here).
- The domain (zimbratest.dom here)
- The server short hostname ("mail" here, completing the FQDN as mail.zimbratest.dom, which is also set to our VIP shared IP resource).
- The "zimbraDNSMasterIP" variable pointing to your DNS servers.
- The "SYSTEMMEMORY" variable should be adjusted accordingly to your machines available ram.

Also, create the following file:

```bash
vi /root/zimbra-keystrokes.cfg
```

Containing:

```bash
y
y
y
y
y
y
y
y
y
y
n
y
y
```

After the file is set and configured, run the installer calling the file in our primary node:

```bash
cd /usr/local/src/zcs-*
./install.sh -s < /root/zimbra-keystrokes.cfg
```

>

**Note something here:** The file "/root/zimbra-keystrokes.cfg" basically answers "y" or "no" to all common questions in zimbra installation script and chooses all zimbra components. If you want to install only some components, either modify your `/root/zimbra-keystrokes.cfg` file, or, run completely interactive:

```bash
cd /usr/local/src/zcs-*
./install.sh -s
```

Please also note that running the install with "-s" option, will just install all software, but it wont do any post-configuration.


**VERY IMPORTANT NOTE: Ensure that your /etc/hosts entries are in the form "IP FQND SHORTNAME". Example:**

```bash
cat /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.70.58 node-01.zimbratest.dom node-01
172.16.70.51 node-02.zimbratest.dom node-02
172.16.70.210 mail.zimbratest.dom mail
172.16.70.51 instance-172-16-70-51.virt.tac.dom instance-172-16-70-51
```
>

After the primary software installation is done, let's configure zimbra in our primary node using the commands:

```bash
mkdir -p /opt/zimbra/java/jre/lib/security/
ln -s /opt/zimbra/common/etc/java/cacerts /opt/zimbra/java/jre/lib/security/cacerts
chown -R  zimbra.zimbra /opt/zimbra/java
/opt/zimbra/libexec/zmsetup.pl -c /root/zimbraconfig.cfg
```

**NOTE AGAIN:** We are doing the configuration part in an automated way by pre-creating a configuration file (`/root/zimbraconfig.cfg`) and passing it to zmsetup.pl (zimbra configurator script), but if you want to go "interactive", just do:

```bash
mkdir -p /opt/zimbra/java/jre/lib/security/
ln -s /opt/zimbra/common/etc/java/cacerts /opt/zimbra/java/jre/lib/security/cacerts
chown -R  zimbra.zimbra /opt/zimbra/java
/opt/zimbra/libexec/zmsetup.pl
```

As you probably noted, in interactive you only need to get rid of the "-c /root/zimbraconfig.cfg"

When the zimbra config finishes (either if you did it automated or interactive), stop and disable the software in the primary node:

```bash
/etc/init.d/zimbra stop
systemctl disable zimbra
killall -9 -u zimbra
```

With zimbra stopped, run the following commands in order to transfer all contents from the /opt/zimbra directory to /mnt/zimbra-storage (our drbd resource):

```bash
unalias mv
mv -v /opt/zimbra/* /mnt/zimbra-storage/
mv -v /opt/zimbra/.* /mnt/zimbra-storage/
mv -v /opt/zimbra/log/* /mnt/zimbra-storage/log/
mv -v /opt/zimbra/log/.* /mnt/zimbra-storage/log/
```

**Please ensure that everything inside /opt/zimbra is moved to /mnt/zimbra-storage (the drbd space). Ensure that all files are moved. Left no one in the /opt/zimbra dir.**

Then, move the original directory and symlink the /opt/zimbra to /mnt/zimbra-storage directory:

```bash
mv /opt/zimbra /opt/zimbra-old
ln -s /mnt/zimbra-storage /opt/zimbra
```

And run a "fixpermision" command just in order to fix any bad permission on files or directories:

```bash
/opt/zimbra/libexec/zmfixperms -extended
```

Now, and because we are goind to need it for the second node installation, obtain the zimbra user UID number and zimbra group GID number:

```bash
su - zimbra -c "id -a"
uid=990(zimbra) gid=988(zimbra) groups=988(zimbra),5(tty),89(postfix)
```

For our specific installation or the first node:

- Zimbra user UID Number: 990
- Zimbra group GID Number: 988
- Postfix group GID Number: 89

Next, copy the following files from the first (primary - 172.16.70.58) node to the secondary (172.16.70.51):

```bash
scp /root/zimbra* 172.16.70.51:/root/
```

**NOTE: Those are your automation files. If you want to do all interactive way, you won't need those files in the second server/node.**

Finally, stop the cluster services on our primary node (172.16.70.58) so all the resources will pass to the other node (172.16.70.51):

```bash
pcs cluster stop instance-172-16-70-58
```

### STEP 6: Zimbra setup - second node (172.16.70.51)

With our second node (172.16.70.51) as primary/active and with all resources (drbd/fs/ip) active, proceed to install zimbra. Remember we already copied our "automation" files from the first node to the second one.

Then, in our second node (172.16.70.51) run the following commands:

```bash
cd /usr/local/src/zcs-*
./install.sh -s < /root/zimbra-keystrokes.cfg

**AGAIN !!. If you don't want to perform the installation in an automated/non-interactive way, don't use the zimbra-keystrokes.cfg file, but, ENSURE your package selections are the same in the second node as you selected them in the first node.**

cd /

mkdir -p /opt/zimbra/java/jre/lib/security/
ln -s /opt/zimbra/common/etc/java/cacerts /opt/zimbra/java/jre/lib/security/cacerts
chown -R  zimbra.zimbra /opt/zimbra/java
/opt/zimbra/libexec/zmsetup.pl -c /root/zimbraconfig.cfg

```

**IMPORTANT NOTE: If you opted to do the installation interactivelly, ENSURE to use the same options in the second node as you did in your first node.**

>

After the setup finishes it's run, stop and disable zimbra:

```bash
cd /
/etc/init.d/zimbra stop
systemctl disable zimbra
killall -9 -u zimbra
```

Before continuing, check that the second nodes have the same UID/GID numbers as the first node:

```bash
su - zimbra -c "id -a"
uid=990(zimbra) gid=988(zimbra) groups=988(zimbra),5(tty),89(postfix)
```

If the numbers are the same, we are OK. If the numbers are diffetent, use the commands "usermod -u NEW_UID zimbra" and "groupmod -g NEW_GID zimbra" to change them. Normally, and if you performed all steps in the same order as this guid, both servers should have the same uid/gid for all zimbra related users and groups.

With zimbra stopped, run the following commands in order to point our drbd resource to /opt/zimbra:

```bash
mv /opt/zimbra /opt/zimbra-old
ln -s /mnt/zimbra-storage /opt/zimbra
```

Now, proceed to reactivate the master node:

```bash
pcs cluster start instance-172-16-70-58
```

Because zimbra is now installed, the service script will detect the presence of "/etc/init.d/zimbra" and start all related services.

Also, we should enable policyd. First, su to zimbra account (in our primary node, 172.16.70.58):

```bash
su - zimbra
```

And inside the zimbra account run the following commands:

```bash
zmprov ms `zmhostname` +zimbraServiceInstalled cbpolicyd && zmprov ms `zmhostname` +zimbraServiceEnabled cbpolicyd
```

And verify with (still inside zimbra account):

```bash
zmprov gs `zmhostname` | grep zimbraServiceInstalled
zmcbpolicydctl status
```

If for some reason you sense the urge to disable the proxy, follow the next steps:

First, in the primary node (the one that should be active right now) enter to zimbra account:

```bash
su - zimbra
```

Then issue the following commands:

```bash
zmprov ms `zmhostname` zimbraImapProxyBindPort 0
zmprov ms `zmhostname` zimbraImapSSLProxyBindPort 0
zmprov ms `zmhostname` zimbraPop3ProxyBindPort 0
zmprov ms `zmhostname` zimbraPop3SSLProxyBindPort 0

zmprov ms `zmhostname` zimbraImapBindPort 143
zmprov ms `zmhostname` zimbraImapSSLBindPort 993
zmprov ms `zmhostname` zimbraPop3BindPort 110
zmprov ms `zmhostname` zimbraPop3SSLBindPort 995

zmprov ms `zmhostname` -zimbraServiceEnabled memcached
zmprov ms `zmhostname` -zimbraServiceEnabled imapproxy
zmprov ms `zmhostname` -zimbraServiceInstalled memcached
zmprov ms `zmhostname` -zimbraServiceInstalled imapproxy

zmproxyctl stop
zmmemcachedctl stop
zmcontrol stop
zmcontrol start
exit
```

Finally, and in order to ensure all permisions fixed and everything working OK, from the "root" account run the following commands (in the active node):

```bash
/etc/init.d/zimbra stop
yum -y erase zimbra-proxy zimbra-proxy-base zimbra-proxy-components
killall postdrop
killall -9 zimbra
/opt/zimbra/libexec/zmfixperms -extended -verbose
/etc/init.d/zimbra start
```

**NOTE: Ensure to run those last commands on the active server.**

Note: On the non-active node, also run the following command in order to get rid of the proxy service:

```bash
yum -y erase zimbra-proxy zimbra-proxy-base zimbra-proxy-components
```

You are set !.

Now, you can enter to your administrative interface with the url:

- https://172.16.70.210:7071
- User: admin
- Password: P@ssw0rd

And, in your normal-user web interface (create a normal user first in the admin interface):

- https://172.16.70.210:8443


### STEP FINAL: Failover test.

Either reboot your primary node, or, stop it's cluster services by running the command:

```bash
pcs cluster stop instance-172-16-70-58
```

All your services will be started on the other node (172.16.70.51) including the VIP (172.16.70.210). Because all related data (databases, ldap, mailboxes) are located inside /opt/zimbra (pointed to the drbd resource), all your original data will be there !.

# END.-

