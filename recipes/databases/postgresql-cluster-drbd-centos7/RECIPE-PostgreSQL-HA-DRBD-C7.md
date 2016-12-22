# A POSTGRESQL 9.5 CLUSTER WITH DRBD, PACEMAKER AND COROSYNC ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

- Create a highly available postgresql 9.5 cluster with drbd as a storage backend, and pacemaker/corosync as cluster software.
- Allow multi-database setups with each database running in it's own engine and port.
- Create a scripts structure allowing multiples databases and easy of administration.
- Atomate all start/stop tasks, backup tasks, and all log/archive cleaning tasks.


## Where are we going to install it ?:

Two virtual servers (4 vpcu, 16GB Ram, two virtual HD's, one for the O/S with 15GB, the other for the Database with 60GB's.). OS: Centos 7 with EPEL Repo installed. Fully updated. FirewallD and SELINUX disabled.

**NOTES:**

* The virtual servers are openstack based, but, this can be replicated on any cloud platform or with bare metal servers.
* This is la LAB using only one ethernet interface per server. For production usage, we recommend two interfaces: One for general database traffic, and the other dedicated to DRBD.

Hostnames/IP's of our servers:

**vm-172-16-31-29.mydomain.dom (IP: 172.16.31.29)**
**vm-172-16-31-30.mydomain.dom (IP: 172.16.31.30)**

The VIP for our service: **172.16.31.210**


## How we constructed the whole thing ?:


### BASIC SERVER SETUP:

Let's do some basic server setup first, focused to kernel, limits, ssh trusts, etc. You must do this on both servers.

First step: Configure a bi-directional ssh trust between both servers. As this is very basic, we'll not explain it here. Just remember to create your keys with `"ssh-keygen -t rsa"` and deploy them with `"ssh-copy-id"`. You'll end with an `/root/.ssh/authorized_keys` containing the public key.

Second step: Let's adjust the Kernel, limits and do some memory tunning (adjust those variables for your server).

Add to /etc/sysctl.conf the following lines (again, adjust this based on your server RAM):

```
kernel.shmmax = 17179869184
kernel.shmall = 2147483648
kernel.sem = 500 32000 300 1500
```

Execute the following command:

sysctl -p

Add at the end of `/etc/security/limits.conf` file:

```
   postgres soft nofile 1024
   postgres hard nofile 65536

   postgres soft nproc 4094
   postgres hard nproc 16384

   postgres soft stack 10240
   postgres hard stack 32768
```

Save the file.

Now let's install tuned and disable Transparent Huge Pages... If you don't disable THP, your postgresql server will suffer excesive System CPU Usage.

```
yum install tuned tuned-utils
```

Create a new profile:

```
mkdir /etc/tuned/custom-thp
```

```
vi /etc/tuned/custom-thp/tuned.conf
```

Contents:

```
[main]
include=virtual-guest

[vm]
transparent_hugepages=never

[script]
script=script.sh
```

Save the file.

NOTE: If this is a bare-metal server, use **"include=throughput-performance"** instead of **"include=virtual-guest"**.

Create the following script:

```
vi /etc/tuned/custom-thp/script.sh
```

With contents:

```bash
#!/bin/sh

. /usr/lib/tuned/functions

start() {
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
    return 0
}

stop() {
    return 0
}

process $@
```

Save the file and change it's permissions/mode:

```
chmod 755 /etc/tuned/custom-thp/script.sh
```

Activate the profile, and start tuned. Also let tuned start at boot time:

```
tuned-adm profile custom-thp

systemctl enable tuned
systemctl restart tuned
systemctl status tuned
```

That end's basic server setup.

**NOTE: It's a good idea if you perform a final yum update and reboot the servers in order to start clean:**

```
yum clean all && yum -y update && reboot
```


### REPOSITORIES AND PACKAGES INSTALLATION.

Now, we need to include proper repositories both for PostgreSQL software and DRBD. For DRBD we need to include "ELREPO". Those procedures most be performed on both servers:

* El-Repo:

```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
```

* PostgreSQL 9.5:

```
rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm
```

We proceed to do a "yum clean" and a "yum update":

```
yum clean all; yum -y update
```

With both repos ready, we proceed to excecute the following commands. Please note that the order is very important. Please execute the commands in the same order as this documentation shows:

```
yum -y install kmod-drbd84 drbd84-utils drbd84-utils-sysvinit

groupadd -g 26 -o -r postgres
useradd -M -n -g postgres -o -r -d /var/lib/pgsql -s /bin/bash -c "PostgreSQL Server" -u 26 postgres

yum install postgresql95 postgresql95-contrib postgresql95-devel postgresql95-docs postgresql95-libs postgresql95-plperl postgresql95-plpython postgresql95-pltcl postgresql95-server postgresql95-python

systemctl stop postgresql-9.5
systemctl disable postgresql-9.5
```

**NOTE: Again, PLEASE, ensure the proper order here. It's very important that the postgresql user and group are created before the postgresql packages installation. Later you'll come to see why !.**


### DRBD SETUP.

Now, we proceed to setup our DRBD resources on both servers. For our setup, we have an extra hard disk (virtual) in both servers. The extra hard disk device is "/dev/vdb", but this can change in your setup so adjust the following procedures if you have a different disk consiguration.

First, in both servers, we load the drbd module. This module is part of the ELREPO drbd packages and it's not included by default on EL7.

```
modprobe drbd
```

In both servers, we proceed to create the "postgres" resource:

```
vi /etc/drbd.d/postgres.res
```

Contents:

```
resource postgresql {
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

    on vm-172-16-31-29.mydomain.dom {
        device /dev/drbd0;
        disk /dev/vdb;
        address 172.16.31.29:7789;
        meta-disk internal;
    }
    on vm-172-16-31-30.mydomain.dom {
        device /dev/drbd0;
        disk /dev/vdb;
        address 172.16.31.30:7789;
        meta-disk internal;
    }
}
```

Then we save the file.

**NOTE SOMETHING HERE: Because our LAB servers only have one ethernet giga interface, we are limiting the DRBD traffic to about 40% of total traffic (40M). In production environment, you should have a secondary ethernet per server and dedicate DRBD traffic on this interface. This also means adjust the rate to a higher values, nearing 90% of available ethernet bandwidth for your setup.**

In both servers, we run the following commands:

```
dd if=/dev/zero bs=1M count=10 of=/dev/vdb
sync

drbdadm create-md postgresql
```

Now, we need to execute commands on the first node:

In the vm-172-16-31-29 server:

```
modprobe drbd
drbdadm up postgresql

drbdadm -- --overwrite-data-of-peer primary postgresql
```

Then in both servers we run the commands:

```
systemctl start drbd
systemctl enable drbd
systemctl status drbd
```

Those steps will do the first DRBD synchronization. Here, we'll need to wait until the DRBD volume is fully in sync. We can monitor the proccess by issuing the following command in any of the servers:

Node: "vm-172-16-31-29":

```
while true; do clear; cat /proc/drbd; sleep 10;done
```

This command will put a "loop" showing the status of the DRBD. It will be fully sinchronized when it reaches 100% percent. Once this happens, we can continue our setup.


### POSTGRESQL SPACE PREPARATION

Now that our DRBD is fully in sync, we proceed to create the postgresql filesystems and adjust proper permissions and directories.

In the "vm-172-16-31-29" node, we proceed to create the filesystem over the DRBD resource. We only need to do this once, as the data is now in full replication:

```
mkfs.xfs -L postgres01 /dev/drbd0
```

Now, in both servers we run the following commands:

```
mkdir /postgres

echo "/dev/drbd/by-res/postgresql /postgres xfs rw,noauto 0 0" >> /etc/fstab
chown -R postgres.postgres /postgres
```

**Do you remember when we told you to ensure the proper steps in the package installation section ?. That's the reason: In the command above, we "chown'ed" the /postgres directory to "postgres.postgres". If for any reason the UID number and GID number are different on both servers, the H.A. setup WILL BREAK when the resource passes from one server to the other one. That being said, let's continue:**

Temporarilly, we mount the drbd resource in the node "vm-172-16-31-29" in order to create the following directories:

```
mount /postgres/
mkdir -p /postgres/archive
mkdir -p /postgres/archive/database01
mkdir -p /postgres/archive/database02
mkdir -p /postgres/backup
mkdir -p /postgres/data
mkdir -p /postgres/data/database01
mkdir -p /postgres/data/database02
mkdir -p /postgres/log
mkdir -p /postgres/log/database01
mkdir -p /postgres/log/database02
mkdir -p /postgres/temporal
mkdir -p /postgres/wall
```

**NOTE SOMETHING HERE: One of our goals is to allow a multi-database setup and each database running in it's own postgresql instance. For this reason, we are creating the "databaseXX" directories here.**

Again, we need to apply the proper permissions (still in the "vm-172-16-31-29" node):

```
chown -R postgres.postgres /postgres
```

The following directory is created, but, we let it be "root.root"

```
mkdir -p /postgres/bin

chown root.root /postgres/bin
```

And just for convenience, let's create the following symlink.

```
ln -s /usr/pgsql-9.5 /postgres/bin/9.5.2
```

Then we dismount the resource from "vm-172-16-31-29" server:

```
cd /
umount /postgres
```

In the second node (vm-172-16-31-30) we proceed to make it primary and mount the resource. That's just to ensure everything is OK:

```
drbdadm primary postgresql
mount /postgres
```

Then we dismount the resource and setup again both nodes as primary:

```
cd /
umount /postgres
drbdadm primary all
```

**NOTE: Fail to do this, and you'll end with a SPLIT BRAIN situation.**

Then, in both nodes, we proceed to stop and disable the DRBD service, as it will be controlled by the cluster service.

```
systemctl stop drbd
systemctl disable drbd
systemctl status drbd
```


### EXTRA SETUP FOR OPENSTACK ONLY

If you are not using OpenStack, omit this section. Otherwise we need to ensure to allow the VIP to be present in the VM's ports. This is acomplished using "allowed address pairs" Neutron feature. If you fail to do this in OpenStack, your VIP will be unable to be contacted.

For this LAB, our VIP is 172.16.31.210, our network name in neutron is "netvlan31" and our security group name is postgresql-access.

First, we proceed to create the port with the IP 172.16.31.210 in the network "netvlan31" and with the security group "postgresql-access":

```
neutron port-create --fixed-ip ip_address=172.16.31.210 --security-group postgresql-access netvlan31
```

For our LAB, this created the port with ID: 9271476f-43fd-48cd-87d2-f385c9d72838

We then proceed to obtain the port ID's containing the IP's 172.16.31.29 y 172.16.31.30:

```
neutron port-list|grep 172.16.31.29|awk '{print $2}'
749677da-3c24-4737-b27f-19e5111d1b05

neutron port-list|grep 172.16.31.30|awk '{print $2}'
824f097b-3eeb-44d2-90df-1ac18ed6c039
```

And with this information, we update both ports with allowed address pairs poiting to the VIP:

```
neutron port-update 749677da-3c24-4737-b27f-19e5111d1b05 --allowed_address_pairs list=true type=dict ip_address=172.16.31.210
neutron port-update 824f097b-3eeb-44d2-90df-1ac18ed6c039 --allowed_address_pairs list=true type=dict ip_address=172.16.31.210
```

**NOTE: Most cloud's apply very strong anti-spoofing measures that won't allow a "Floating VIP" to exist unless you take the proper steps. Please document yourself very well if you plan to use this postgresql-drbd-cluster recipe in a cloud like AWS.**


### CLUSTER SOFTWARE INSTALLATION

In both servers, we proceed to install the cluster packages:

```
yum install pacemaker pcs corosync resource-agents pacemaker-cli
```

Also, we set the "hacluster" account password:

```
echo "hacluster:P@ssW0rdCl7sT3r"|chpasswd
```

Then, in both servers, we start the pcsd service:

```
systemctl start pcsd
systemctl status pcsd
```

And in both servers, we authorize both nodes:

```
pcs cluster auth vm-172-16-31-29 vm-172-16-31-30
```

(this last command will ask for the "hacluster" account and it's password).

In the first node (172.16.31.29) we proceed to create and start the cluster. All the following commands will be executed on this node:

```
pcs cluster setup --name cluster_postgres vm-172-16-31-29 vm-172-16-31-30

pcs cluster start --all
```

We check it's status:

```
pcs status cluster
corosync-cmapctl | grep members
pcs status corosync
```

We verify the config state and disable stonith:

```
crm_verify -L -V
pcs property set stonith-enabled=false
```

And disable our quorum policy, as we have only two nodes:

```
pcs property set no-quorum-policy=ignore
pcs property
```

We proceed to create our VIP resource (IP: 172.16.31.210):

```
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=172.16.31.210 cidr_netmask=32 nic=eth0:0 op monitor interval=30s
```

**VERY IMPORTANT NOTE: As our ethernet interfaces are named "eth0", we choose our eth alias as "eth0:0". Adjust this alias based on your ethernet names.**

As soon as we complete this command, we can see this IP ready in the node with "ip a" or "ifconfig".

We verify the state of our resources:

```
pcs status resources

[root@vm-172-16-31-29 /]# pcs status resources
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started
```

En this point, we need to enable all our cluster related services IN BOTH SERVERS:

```
systemctl enable pcsd
systemctl enable corosync
systemctl enable pacemaker
```

**BUGFIX: Due an existing bug with the corosync service, we need to include a 10 seconds delay in the systemd script, and we need to perform this VERY VITAL STEP IN BOTH SERVERS:**

```
vi /usr/lib/systemd/system/corosync.service
```

After "[service]" section, we add the following line:

```
ExecStartPre=/usr/bin/sleep 10
```

So the file new content will be:

```
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

Then we proceed to save the file and reload systemctl daemon, again, in both servers:

```
systemctl daemon-reload
```

Now, we proceed to create the DRBD resource. The following steps will be performed on the first server (172.16.31.29):

```
cd /
pcs cluster cib add_drbd
```

This create the file: /add_drbd

Then:

```
cd /
pcs -f add_drbd resource create postgres_data ocf:linbit:drbd drbd_resource=postgresql op monitor interval=60s
pcs -f add_drbd resource master postgres_data_sync postgres_data master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

Now, we need to fix the following file permission IN BOTH SERVERS or the DRBD resource will not work:

**Remember: Both servers:**

```
chmod 777 /var/lib/pacemaker/cores
```

Back on the primary node (172.16.31.29):

```
cd /
pcs cluster cib-push add_drbd
```

That last command creates the DRBD resource into the cluster services.

Then, in the primary node (172.16.31.29) we proceed to create the following script:

```
vi /etc/init.d/postgressvc
```

With the contents:

```bash
#!/bin/bash
#

case $1 in
start)
	echo "Starting Postgres DB Services"
	echo "0" > /var/log/db-svc-started.log
	rm -f /var/log/db-svc-stopped.log
	exit 0
	;;
stop)
	echo "Stopping Postgres DB Services"
	rm -f /var/log/db-svc-started.log
	echo "0" > /var/log/db-svc-stopped.log
	exit 0
	;;
status|monitor)
	echo "Postgres DB Services Status"
	if [ -f /var/log/db-svc-started.log ]
	then
		exit 0
	else
		exit 3
	fi
	;;
restart)
	echo "Postgres DB Services Restart"
	exit 0
	;;
esac
```

Then we save the file, change it's mode to 755, and copy it to the secondary node:

```
chmod 755 /etc/init.d/postgressvc

scp /etc/init.d/postgressvc vm-172-16-31-30:/etc/init.d/
```

Still in the same node (172.16.31.29) we proceed to create the service in the cluster:

```
pcs resource create svcpostgressvc lsb:postgressvc op monitor interval=30s
```

In order to allow the script to be somewhat independent from the cluster service, we proceed to remove the monitor:

```
pcs resource op remove svcpostgressvc monitor
```

**This step is very important in order to allow the Database Administrator to start/stop the database services without causing the cluster to declare a failover. Normally, this contradicts what the the cluster software does: Monitor the service and start a failover if the service fail's, but as we are using a multi-database/multi-engine approach, we need to let the DBA to have fully authority over it's managed resources. The H.A. will then work as "server level" and not at "service level", so, the full failover will happen if the active node goes dead on unreachable.**

We apply the proper constrains in order to link the VIP with the resource and set the preferent node to "vm-172-16-31-29":

```
pcs constraint colocation add svcpostgressvc virtual_ip INFINITY
pcs constraint order virtual_ip then svcpostgressvc
pcs constraint location svcpostgressvc prefers vm-172-16-31-29=50
```

Now, we add the filesystem resource:

```
cd /
pcs cluster cib add_fs
pcs -f add_fs resource create postgres_fs Filesystem device="/dev/drbd/by-res/postgresql" directory="/postgres" fstype="xfs"

pcs -f add_fs constraint colocation add postgres_fs postgres_data_sync INFINITY with-rsc-role=Master

pcs -f add_fs constraint order promote postgres_data_sync then start postgres_fs

pcs -f add_fs constraint colocation add svcpostgressvc postgres_fs INFINITY

pcs -f add_fs constraint order postgres_fs then svcpostgressvc

pcs cluster cib-push add_fs
```

In this point, all resources must be fully available in the node **"vm-172-16-31-29"**.

You can do a crash test by rebooting the primary node, or, by issuing the following commands:

We proceed to stop the primary node:

```
pcs cluster stop vm-172-16-31-29
```

All resources will go to vm-172-16-31-30.

And if we start the primary node again:

```
pcs cluster start vm-172-16-31-29
```

All resources will go back to 172.16.31.29.

This part conclude the cluster configuration, so we now will proceed to configure postgresql.


### POSTGRESQL SETUP

At this point, we should have all resources (VIP, DRBD and /postgres mount) fully working in the primary node (vm-172-16-31-29 or 172.16.31.29)

We need to complete the "postgres" account profile with the PATH and other settings. This need to be done in BOTH SERVERS:

```
echo "source /etc/bashrc" > /var/lib/pgsql/.pgsql_profile
echo "export PATH=\$PATH:/usr/pgsql-9.5/bin/" >> /var/lib/pgsql/.pgsql_profile
chown postgres.postgres /var/lib/pgsql/.pgsql_profile
```

And we also change the postgres account password **(please use something more strong than 123456)**:

```
echo "postgres:123456"|chpasswd
```

The following commands must be completed in the active node (172.16.31.29):

We enter to the postgres account with "su"

```
su - postgres
```

We proceed to create both databases:

```
initdb -D /postgres/data/database01
initdb -D /postgres/data/database02
```

Then, we run the following commands in order to move the xlog dirs to the /postgres/wall dir:

```
mv /postgres/data/database01/pg_xlog /postgres/wall/database01
mv /postgres/data/database02/pg_xlog /postgres/wall/database02
ln -s /postgres/wall/database01 /postgres/data/database01/pg_xlog
ln -s /postgres/wall/database02 /postgres/data/database02/pg_xlog
```

We proceed to save the original config's (just in case....):

```
mv /postgres/data/database01/postgresql.conf /postgres/data/database01/postgresql.conf.ORIGINAL
mv /postgres/data/database02/postgresql.conf /postgres/data/database02/postgresql.conf.ORIGINAL
mv /postgres/data/database01/pg_hba.conf /postgres/data/database01/pg_hba.conf.ORIGINAL
mv /postgres/data/database02/pg_hba.conf /postgres/data/database02/pg_hba.conf.ORIGINAL
```

Then create new ones:

```
vi /postgres/data/database01/postgresql.conf
```

With the contents:

```
#
# POSTGRES CONFIG DATABASE01 SERVICE
#
listen_addresses = '*'
port = 9911
max_connections = 2000
superuser_reserved_connections = 6
password_encryption = on
shared_buffers = 2048MB
temp_buffers = 128MB
work_mem = 32MB
maintenance_work_mem = 64MB
dynamic_shared_memory_type = posix
shared_preload_libraries = '$libdir/passwordcheck,$libdir/pg_stat_statements'
max_worker_processes = 8
# wal_level = hot_standby
wal_level = minimal
fsync = on
synchronous_commit = on
wal_sync_method = fdatasync
wal_log_hints = off
wal_buffers = -1
wal_writer_delay = 200ms
commit_delay = 0
commit_siblings = 5
max_wal_size = 3GB
min_wal_size = 100MB
checkpoint_timeout = 5min
checkpoint_completion_target = 0.5
checkpoint_warning = 30s
# archive_mode = on
archive_mode = off
# archive_command = 'cp  %p  /postgres/archive/database01/%f </dev/null'
archive_timeout = 60
# max_wal_senders = 6
max_wal_senders = 0
wal_keep_segments = 64
hot_standby = on
max_standby_archive_delay = 30s
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = off
wal_receiver_timeout = 60s
effective_cache_size = 4GB
log_destination = 'stderr'
logging_collector = on
log_directory = '/postgres/log/database01'
log_filename = 'psqldatabase01-%Y%m%d.log'
log_file_mode = 0600
log_truncate_on_rotation = on
log_rotation_age = 1d
log_rotation_size = 100MB
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = on
log_error_verbosity = default
log_hostname = on
log_line_prefix = '%t <%u:%d:%r>'
log_lock_waits = off
log_statement = 'ddl'
log_temp_files = -1
log_timezone = 'America/Caracas'
log_parser_stats = on
log_planner_stats = on
log_executor_stats = on
log_statement_stats = off
temp_tablespaces = 'TEMP'
datestyle = 'iso, dmy'
timezone = 'America/Caracas'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
```

```
vi /postgres/data/database02/postgresql.conf
```

Contents:

```
#
# POSTGRES CONFIG DATABASE02 SERVICE
#
listen_addresses = '*'
port = 9912
max_connections = 2000
superuser_reserved_connections = 6
password_encryption = on
shared_buffers = 2048MB
temp_buffers = 128MB
work_mem = 32MB
maintenance_work_mem = 64MB
dynamic_shared_memory_type = posix
shared_preload_libraries = '$libdir/passwordcheck,$libdir/pg_stat_statements'
max_worker_processes = 8
# wal_level = hot_standby
wal_level = minimal
fsync = on
synchronous_commit = on
wal_sync_method = fdatasync
wal_log_hints = off
wal_buffers = -1
wal_writer_delay = 200ms
commit_delay = 0
commit_siblings = 5
max_wal_size = 3GB
min_wal_size = 100MB
checkpoint_timeout = 5min
checkpoint_completion_target = 0.5
checkpoint_warning = 30s
# archive_mode = on
archive_mode = off
# archive_command = 'cp  %p  /postgres/archive/database02/%f </dev/null'
archive_timeout = 60
# max_wal_senders = 6
max_wal_senders = 0
wal_keep_segments = 64
hot_standby = on
max_standby_archive_delay = 30s
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = off
wal_receiver_timeout = 60s
effective_cache_size = 4GB
log_destination = 'stderr'
logging_collector = on
log_directory = '/postgres/log/database02'
log_filename = 'psqldatabase02-%Y%m%d.log'
log_file_mode = 0600
log_truncate_on_rotation = on
log_rotation_age = 1d
log_rotation_size = 100MB
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = on
log_error_verbosity = default
log_hostname = on
log_line_prefix = '%t <%u:%d:%r>'
log_lock_waits = off
log_statement = 'ddl'
log_temp_files = -1
log_timezone = 'America/Caracas'
log_parser_stats = on
log_planner_stats = on
log_executor_stats = on
log_statement_stats = off
temp_tablespaces = 'TEMP'
datestyle = 'iso, dmy'
timezone = 'America/Caracas'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
```

```
vi /postgres/data/database01/pg_hba.conf
```

With the contents:

```
#
# SECURITY CONFIGURATION
#
#
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
#
# "local" is for Unix domain socket connections only
local   all         all                               trust
# IPv4 local connections:
host    all         all         127.0.0.1/32          trust
host    all         all         172.16.0.0/16         md5
```

And:

```
vi /postgres/data/database02/pg_hba.conf
```

With the contents:

```
#
# SECURITY CONFIGURATION
#
#
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
#
# "local" is for Unix domain socket connections only
local   all         all                               trust
# IPv4 local connections:
host    all         all         127.0.0.1/32          trust
host    all         all         172.16.0.0/16         md5
```

**NOTES:**

* Because our LAB network and other internal networks are all aroung 172.16.0.0/16 space, we are allowing them into postgres instances with md5 passwords. Change this to suit your real environment.
* Our timezone is set to "America/Caracas". Change this in order to reflect you location.
* We are using ports 9911 and 9912 for our database instances. Change them to suit your desired setup, and remember if you are running inside a cloud environment to adjust your security groups.

After all 4 config files are ready, we do a test:

```
pg_ctl start -D /postgres/data/database01/
pg_ctl start -D /postgres/data/database02/
```

We should see our database ports:

```
[postgres@vm-172-16-31-29 ~]$ ss -ltn|grep :99
LISTEN     0      128                       *:9911                     *:*     
LISTEN     0      128                       *:9912                     *:*     
LISTEN     0      128                      :::9911                    :::*     
LISTEN     0      128                      :::9912                    :::*
```

We proceed to connect to both services and change the "postgres" admin user to "P@ssw0rd" (please use something more cryptic):

```
psql -U postgres -h 127.0.0.1 -p 9911
postgres=# ALTER ROLE postgres WITH PASSWORD 'P@ssw0rd';
\q

psql -U postgres -h 127.0.0.1 -p 9912
postgres=# ALTER ROLE postgres WITH PASSWORD 'P@ssw0rd';
\q
```

After we change the password, we shoud change the "trust" for "md5" in the pg_hba.conf for network 127.0.0.1 in order to reinforce our security, but, let "local" with "trust" in order to allow the automated backups to work properlly. Then, we proceed to restart the services and do a connection test:

```
pg_ctl restart -D /postgres/data/database02
pg_ctl restart -D /postgres/data/database01
```

And then we connect using the password "P@ssw0rd":

```
psql -U postgres -h 127.0.0.1 -p 9911 -W
psql -U postgres -h 127.0.0.1 -p 9912 -W
```

Also, we can connect from outside directly to the VIP (any server in our allowed network as declared in pg_hba.conf):

```
psql -h 172.16.31.210 -U postgres -p 9911 -W
psql -h 172.16.31.210 -U postgres -p 9912 -W
```

Then we stop both instances:

```
pg_ctl stop -D /postgres/data/database02
pg_ctl stop -D /postgres/data/database01
```

And leave the "postgres" account with `"exit"`

After all those commands (ran in the primary/active node 172.16.31.29), we proceed to create the main control script IN BOTH SERVERS:

```
vi /usr/local/bin/postgres-db-control.sh
```

Contents:

```bash
#!/bin/bash
#
# Postgres-DB control script
#

postgressvcdir="/postgres"
postgresuser="postgres"
basedir="/postgres/data/"
#mydblist='
#    database01
#    database02
#'

mydblist=`ls $basedir`

myuser=`whoami`

case $myuser in
root)
    mysucommand="su - $postgresuser -c "
    ;;
$postgresuser)
    mysucommand="bash -c "
    ;;
*)
    echo "Current user not root nor $postgresuser ... aborting !!"
    exit 0
    ;;
esac

PATH=$PATH:/usr/pgsql-9.5/bin/

if [ ! -z $2 ]
then
    mydblist=$2
fi

case $1 in
start)
    echo ""
    for i in $mydblist
    do
        echo "Starting Database Service: $i"
        echo ""
        $mysucommand "pg_ctl start -D /postgres/data/$i > /postgres/data/$i/startlog.log"
        echo ""
        echo "Status:"
        $mysucommand "pg_ctl status -D /postgres/data/$i"
    done
    echo ""
    ;;
stop)
    echo ""
    for i in $mydblist
    do
        echo "Stopping Database Service: $i"
        $mysucommand "pg_ctl stop -D /postgres/data/$i"
    done
    echo ""
    ;;

stopfast)
        echo ""
        for i in $mydblist
        do
                echo "Stopping Database Service - FAST MODE - : $i"
                $mysucommand "pg_ctl stop -D /postgres/data/$i -m fast"
        done
        echo ""
        ;;
status|monitor)
    echo ""
    for i in $mydblist
    do
        echo ""
        echo "Status of Database Service: $i"
        $mysucommand "pg_ctl status -D /postgres/data/$i"
        echo ""
    done
    echo ""
    ;;
restart)
    echo ""
    for i in $mydblist
    do
        echo "Restarting Database Service: $i"
        echo ""
        $mysucommand "pg_ctl restart -D /postgres/data/$i > /postgres/data/$i/startlog.log"
        echo ""
        $mysucommand "pg_ctl status -D /postgres/data/$i"
        echo ""
    done
    echo ""
    ;;
*)
    echo ""
    echo "Usage: $0 start|stop|stopfast|status|restart"
    echo ""
    ;;
esac
```

We save and make executable the file:

```
chmod 755 /usr/local/bin/postgres-db-control.sh
```

Also, in both servers, we proceed to modify our cluster script:

```
vi /etc/init.d/postgressvc
```

New Content:

```bash
#!/bin/bash
#

mystatus=`/usr/local/bin/postgres-db-control.sh status 2>/dev/null|grep -ci "server is running"`

case $1 in
start)
        echo "Starting Postgres DB Services"
        echo "0" > /var/log/db-svc-started.log
        rm -f /var/log/db-svc-stopped.log
        /usr/local/bin/postgres-db-control.sh start > /dev/null 2>&1
        exit 0
        ;;
stop)
        echo "Stopping Postgres DB Services"
        rm -f /var/log/db-svc-started.log
        echo "0" > /var/log/db-svc-stopped.log
        /usr/local/bin/postgres-db-control.sh stopfast > /dev/null 2>&1
        exit 0
        ;;
status|monitor)
        echo "Postgres DB Services Status"
        if [ $mystatus == "0" ]
        then
                rm -f /var/log/db-svc-started.log
                echo "0" > /var/log/db-svc-stopped.log
                exit 3
        else
                echo "0" > /var/log/db-svc-started.log
                rm -f /var/log/db-svc-stopped.log
                exit 0
        fi
        ;;
restart)
        echo "Postgres DB Services Restart"
        /usr/local/bin/postgres-db-control.sh stopfast > /dev/null 2>&1
        /usr/local/bin/postgres-db-control.sh start > /dev/null 2>&1
        rm -f /var/log/db-svc-stopped.log
        echo "0" > /var/log/db-svc-started.log
        exit 0
        ;;
esac
```

**NOTE: It is very important to ensure the exit codes are the right ones. We can verify this:**

```
/etc/init.d/postgressvc status;echo "echo result: $?"
/etc/init.d/postgressvc monitor;echo "echo result: $?"
/etc/init.d/postgressvc start;echo "echo result: $?"
/etc/init.d/postgressvc stop;echo "echo result: $?"
/etc/init.d/postgressvc restart;echo "echo result: $?"
```

Now, in the primary/active node (172.16.31.29) we proceed to start our database services:

```
/usr/local/bin/postgres-db-control.sh start
```

In this point, the "database01" and "database02" instances are active. The control script can be used to fully administer the start/stop/status/restart of all instances, or individual instances:

```
postgres-db-control.sh stop: Stop all active services.
postgres-db-control.sh stopfast: Stop (forcefully) all active services.
postgres-db-control.sh start: Start all services.
postgres-db-control.sh restart: Restart all services.
postgres-db-control.sh status: Show the status of all services.
```

The same commands can be used with a specific instance:

```
postgres-db-control.sh stopfast database01: Stop "database01" instance forcefully.
postgres-db-control.sh start database02: Starts database02 service.
postgres-db-control.sh restart database01: Restart database01 service.
postgres-db-control.sh status database02: Shows database02 service.
```

**NOTE: The script can be used either by root or by postgres acccount. The script logic takes into account the calling user and "su" into postgres if it's root the calling user.**

You can add other database services the same way as "database01" and "database02" were added.

At this point, your cluster is fully working, and in the case of an active node failure, it will just start all resources (and database instances) in the surviving server, and fail-back to the primary once it's recovered.


### CLEANING AND BACKUP TASKS.

This would not be a complete solution if we don't include taks for backups and cleaning.

* First thing to do: Archives cleaning:

Just in case you decide to enable archives in the postgresql.conf file, you can include a "cleanup task" if you want to delete archives older than 60 minutes. Just create the following file:

```
vi /etc/cron.d/postgres-archive-cleanup-crontab
```

With the content:

```
*/15 * * * * root [ -d /postgres/archive ] && for i in `ls /postgres/archive/`; do /bin/find /postgres/archive/$i -mmin +60 -name "*" -daystart -type f -print -delete;done > /var/log/last-postgres-archive-cleanup.log 2>&1
```

Save the file and restart the crontab:

```
systemctl restart crond
```

You can adjust the command with any time permance you want (minutes, days, etc). Again, just in the case you decide to enable archives and want to keep them at bay so they don't eat all your hard disk space.

* Second thing to do: Logs cleaning.

Same situation as with archives: You may decide to keep only few days of logs, so they don't eat your very precious hard disk space. For that matter, we can create the following crontab in both servers that will ensure only 2 days of logs:

```
vi /etc/cron.d/postgres-log-cleanup-crontab
```

Contents:

```
15 */2 * * * root [ -d /postgres/log/ ] && /bin/find /postgres/log/ -name "*.log" -mtime +0 -daystart -print -delete > /var/log/last-postgres-log-cleanup.log 2>&1
```

Save the file, restart crontab:

```
systemctl restart crond
```

Again, you can change the time with whatever suits your desire setup. This is just an example.

* And third importan thing to do: Automated Backups:

Of course you'll need to backup your databases at least daily. The following script will ensure all databases in all instances will be properly backed up to a specific directory (for our LAB: /postgres/backup). This directory can be a point mount to anything remote (nfs, gluster, cifs, usb disk, san, etc.). Also the script will retain the last 15 days of backups:

```
vi /usr/local/bin/postgres-databases-backup.sh
```

Contents:

```bash
#!/bin/bash
#
# Postgres-DB backup script
#

postgresuser="postgres"
postgresgroup="postgres"
basedir="/postgres/data"
backuplogs="/postgres/backup"
backupdir="/mnt/db-backups"
mydatespec=`date +%Y%m%d%H%M`
myname=`hostname -s`
daystoretain="15"

logspec="$backuplogs/$myname-dumplog-$mydatespec.log"

if [ -d $basedir ]
then
    myservicelist=`ls $basedir`
else
    echo ""
    echo "Cannot access $basedir. Aborting"
    echo ""
    exit 0
fi

myuser=`whoami`

case $myuser in
root)
    mysucommand="su - $postgresuser -c "
    ;;
$postgresuser)
    mysucommand="bash -c "
    ;;
*)
    echo "Current user not root nor $postgresuser ... aborting !!"
    exit 0
    ;;
esac

#
# Note: If you change the postgresql version, please adjust this path:
#
PATH=$PATH:/usr/pgsql-9.5/bin/

#
# Main loop
#
for i in $myservicelist
do
    if [ -f $basedir/$i/postgresql.conf ]
    then
        #
        # We determine the port first:
        #
        myport=`grep port.\*= $basedir/$i/postgresql.conf|awk '{print $3}'`
        #
        # Then our database list, just in case the instance is running multiple databases
        #
        dblist=`$mysucommand "psql -U $postgresuser -p $myport -l -x"|grep -i name|awk '{print $3}'|grep -v template`
        #
        # Loop: Run all databases, and make the backup of each and every one.
        #
        for db in $dblist
        do
            if [ -d $backupdir ]
            then
                echo ""  >> $logspec
                echo "Backing Up Database $db on service $i, port $myport"  >> $logspec
                echo ""
                echo "Backing Up Database $db on service $i, port $myport"
                echo ""
                echo "Backup File: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                $mysucommand "pg_dump -U $postgresuser -p $myport -Z 9 $db" > \
                    $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz
            else
                echo ""  >> $logspec
                echo "Cannot access $backupdir in order to create the backup file"  >> $logspec
                echo ""  >> $logspec
            fi
            echo ""
            if [ -f $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz ]
            then
                if [ $myuser == "root" ]
                then
                    chown $postgresuser.$postgresgroup $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz
                fi
                echo ""  >> $logspec
                echo "Backup file created OK: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                echo "Backup file created OK: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"
                echo ""  >> $logspec
            else
                echo ""  >> $logspec
                echo "Failed to create backup file: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                echo "Failed to create backup file: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"
                echo ""  >> $logspec
            fi
            echo ""
        done
        #
        # End of loop
        #
    fi
done
#
#
#

if [ $myuser == "root" ]
then
    chown $postgresuser.$postgresgroup $logspec
fi

#
# Now we proceed to delete files older than "daystoretain"
# Backups and Backup Logs.
#

find $backupdir -name "$myname-pgdump-*-database-*.gz" -mtime +$daystoretain -delete
find $backuplogs -name "$myname-dumplog-*.log" -mtime +$daystoretain -delete

#
# END
#
```

Then we proceed to save the file and make it 755:

```
chmod 755 /usr/local/bin/postgres-databases-backup.sh
```

We create the backup dir:

```
mkdir /mnt/db-backups/
```

And make the directory owned by the postgres user and group:

```
chown postgres.postgres /mnt/db-backups/
```

**NOTE: Remember: In a production environment, you should ensure those backups are sent to a NFS, CIFS, GlusterFS, or any other external storage.**

Finally, we create the crontab:

```
vi /etc/cron.d/postgres-backup-crontab
```

Contents:

```
10 01 * * * root /usr/local/bin/postgres-databases-backup.sh > /var/log/last-postgres-backup.log 2>&1
```

Save the file, and restart crontab

```
systemctl restart crond
```

The crontab will run the backup script every day at 01:10am. Adjust the frecuency and times as you desire.

At this point you should have everything you need in order to put his recipe into a production environment. Enjoy !!!!


## EXTRA NOTES:

Use the following commands in order to see the cluster status and it's resources:

```
pcs status
pcs resource show
```

If you want to stop a node:

pcs stop NODE-NAME. Example:

```
pcs stop vm-172-16-31-29
```

If you use this command in the active node, all resources will pass to the standby node, making it the new active node.

You can start the node again with:

pcs start NODE-NAME

Example:

```
pcs start vm-172-16-31-29
```

If this is the preferent node, all resources will go back to this server.

THE END.-
