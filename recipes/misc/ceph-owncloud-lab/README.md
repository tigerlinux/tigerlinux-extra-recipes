# [LAB: OWNCLOUD SERVER USING CEPH-RBD FOR PRIMARY BACKING STORAGE AND CEPH-S3 FOR ADDITIONAL EXTERNAL STORAGE + NEXTCLOUD WITH FULL CEPH-S3 PRIMARY STORAGE BACKEND](http://tigerlinux.github.io)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to acomplish four major goals here:

* Install/deploy a fully working CEPH Cluster using Centos 7.
* Install Owncloud on Centos 7, and configure it to use a CEPH-Based rbd-pool in the CEPH Cluster as primary storage.
* Add a "external storage" option in owncloud with a bucket created in CEPH-S3.
* Replace Owncloud with Nextcloud, and configure it to use the native CEPH-S3 Object Storage as primary storage backend


## Where are we going to install it ?:

For the storage part (the CEPH cluster) we will use 3 Centos 7 nodes, each one with the following configuration:

* Centos 7 (updated up to May 2017).
* 2 VCPU's, 2 GB's RAM, 4 GB's Swap disk, 60GB HD for the Operating System, two extra 32GB disks for OSD, and, one 32GB solid state disk for OSD Journals.
* 2 ethernet network cards, one for general administration and ceph client-server access, and the other for the CEPH storage/cluster network.

*Note: This LAB is being emulated/virtualized using VirtualBox machines, but, our intention is to make it the most similar to a real-production environment.*

Nodes IP and names:

* Node 1: server-71: 192.168.56.71 / 192.168.200.71
* Node 2: server-72: 192.168.56.72 / 192.168.200.72
* Node 3: server-73: 192.168.56.71 / 192.168.200.73

We'll use the first node (server-71) as "deploy node" too.

For the application part (the Owncloud/Nextcloud Server) we will use another Centos 7 machine, 2 VCPU's, 2 GB's RAM, 4 GB's Swap disk, 60GB HD for the Operating System, with only one NIC in the same CEPH-Cluster primary network. Name: server-70, IP 192.168.56.70.

All nodes are correctly NTP and DNS Configured (all hostname fully resolvable across all 4 servers). SELINUX and FirewallD disabled, and, EPEL repo already installed and enabled on all four servers.

Our networks:

* 192.168.56.0/24: Primary network, and, CEPH client-server network. All interactions between owncloud and the ceph service will be performed trough this net.
* 192.168.200.0/24: CEPH intra-cluster network (AKA: Storage Network). All CEPH-Node storage intra-cluster operations will be performed trough this network.


## LAB SETUP. PART 1 . CEPH Cluster related setups.

In the first part of this recipe, we'll setup and test the CEPH cluster. Each node in the CEPH will have two OSD disks and one OSD Journal disk. 


### Basic operating system preparations.

Before fully using ceph on centos 7, we need to do the following tasks:

* Install Kernel 4 from "elrepo.org".
* Enable centos ceph-jewel repositories.

Firts, let's do the "kernel" part. Install/enable "elrepo.org" on all four servers and install the kernel series 4:

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum -y --enablerepo=elrepo-kernel install kernel-ml kernel-ml-devel
```

And, modify/re-apply grub in order to make kernel 4 our default kernel:

```bash
sed -r -i 's/saved/0/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
```

Now with the kernel installed, add the ceph-jewel repository:

```bash
rpm -ivh http://download.ceph.com/rpm-jewel/el7/noarch/ceph-release-1-0.el7.noarch.rpm
```

*NOTE: Centos Jewel repo is not as updated as the official ceph-jewel repo. Please always use the one directly available from ceph.*

Do a full update and a reboot:

```bash
yum -y update
reboot
```

When your four servers are back online, they'll be fully updated and running kernel series 4 from "elrepo.org".

And, run the following command on all 3 servers to ensure our names are resolvable via /etc/hosts:

```bash
echo "192.168.56.71 server-71" >> /etc/hosts
echo "192.168.56.72 server-72" >> /etc/hosts
echo "192.168.56.73 server-73" >> /etc/hosts

```

### CEPH User and SSH environment preparation.

In our 3 CEPH servers (server-71, server-72 and server-73), proceed to create a user that we'll use for all ceph deploy operations:

```bash
useradd -c "Ceph Deploy User" -m -d /home/ceph-deploy -s /bin/bash ceph-deploy
echo "ceph-deploy:P@ssw0rd"|chpasswd

```

In our first ceph node (server-71), which we'll cosider from now our "deploy" node, let's create a ssh-key inside the "ceph-deploy" user, and, send that key to all 3 nodes, then, exit ceph-deploy account:

```bash
su - ceph-deploy
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
ssh-copy-id server-71
ssh-copy-id server-72
ssh-copy-id server-73
exit
```

In all 3 CEPH nodes, add sudo permissions to the ceph-deploy account:

```bash
echo "ceph-deploy ALL = (ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
sudo chmod 0440 /etc/sudoers.d/ceph-deploy

```

In the ceph-deploy node (node 1, server-71), do a "su - ceph-deploy", and inside the account, create the following file:

```bash
su - ceph-deploy
vi ~/.ssh/config
```

Containing:

```bash
Host server-71
   Hostname server-71
   User ceph-deploy
Host server-72
   Hostname server-72
   User ceph-deploy
Host server-73
   Hostname server-73
   User ceph-deploy
Host server-70
   Hostname server-70
   User ceph-deploy
```

Set the proper bits on the file:

```bash
chmod 644 ~/.ssh/config
```

Save the file and exit the ceph-deploy account.

```bash
exit
```


### OSD Disks/journal preparation.

See the "lsblk" from our CEPH servers (is the same on all 3 CEPH nodes):

```bash
lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdd      8:48   0   32G  0 disk
sdb      8:16   0   32G  0 disk
sr0     11:0    1 1024M  0 rom
sdc      8:32   0   32G  0 disk
sda      8:0    0   60G  0 disk
+-sda2   8:2    0    4G  0 part [SWAP]
+-sda3   8:3    0 55.8G  0 part /
+-sda1   8:1    0  256M  0 part /boot
```

Our OSD disk will be sdb and sdc. We need to format them in xfs. In all 3 ceph nodes, run the following commands:

```bash
parted -s /dev/sdb mklabel gpt mkpart primary xfs 0% 100%
mkfs.xfs -f /dev/sdb
parted -s /dev/sdc mklabel gpt mkpart primary xfs 0% 100%
mkfs.xfs -f /dev/sdc
sync

```

And, our journals too. Because we have a single disk for OSD Journals (sdd), we'll split the disk in two partitions:

```bash
parted -s /dev/sdd mklabel gpt mkpart primary xfs 0% 50%
parted -s /dev/sdd mkpart primary xfs 50% 100%
sync
mkfs.xfs -f /dev/sdd1
mkfs.xfs -f /dev/sdd2
sync

```

Each partition will serve a specific OSD. Then, our disk mapping will be (for each server):

* OSD Disk 1: sdb, journal: sdd1
* OSD Disk 2: sdc, journal: sdd2


### CEPH Cluster deployment:

**Please take note: All the following commands will be executed in the "deploy" node (server-71) and inside the ceph-deploy user:**

Enter with "su" to the deploy user, and install the ceph-deploy tool with sudo:

```bash
su - ceph-deploy
sudo yum -y install ceph-deploy
```

Create the following directory and change into it:

```bash
mkdir ~/ceph-cluster
cd ~/ceph-cluster
```

Execute the command:

```bash
ceph-deploy new server-71
```

Edit the file "ceph.conf" and add the following config lines:

```bash
vi ceph.conf
```

Config lines to add:

```bash
osd pool default size = 2
rbd default features = 1
public network = 192.168.56.0/24
cluster network = 192.168.200.0/24
```

Save the file, and install the packages in all 3 nodes with the following command. The ceph deploy command will install all ceph-needed packages in all 3 nodes.:

```bash
ceph-deploy install --no-adjust-repos server-71 server-72 server-73
```

*NOTE 1: Because all needed repos (ceph-jewel and epel) are already installed in all 3 nodes, we can safelly use "--no-adjust-repos" option here.*
*NOTE 2: If the install command fails in any node due Internet access problems, run it again (and again) until no errores are showed.*

With the following command, proceed to create the initial monitor:

```bash
ceph-deploy --overwrite-conf mon create-initial
```

This last command created the keyrings:

```bash
[ceph-deploy@server-71 ceph-cluster]$ ls -la *.keyring
-rw------- 1 ceph-deploy ceph-deploy 113 May  1 17:07 ceph.bootstrap-mds.keyring
-rw------- 1 ceph-deploy ceph-deploy 113 May  1 17:07 ceph.bootstrap-osd.keyring
-rw------- 1 ceph-deploy ceph-deploy 113 May  1 17:07 ceph.bootstrap-rgw.keyring
-rw------- 1 ceph-deploy ceph-deploy 129 May  1 17:07 ceph.client.admin.keyring
-rw------- 1 ceph-deploy ceph-deploy  73 May  1 16:34 ceph.mon.keyring
[ceph-deploy@server-71 ceph-cluster]$

```

Let's prepare and activate our 6 OSD's (two in each server) by running the following commands:

```bash
ceph-deploy osd prepare server-71:sdb:/dev/sdd1 server-71:sdc:/dev/sdd2
ceph-deploy osd prepare server-72:sdb:/dev/sdd1 server-72:sdc:/dev/sdd2
ceph-deploy osd prepare server-73:sdb:/dev/sdd1 server-73:sdc:/dev/sdd2

ssh server-71 "sudo chown ceph.ceph /dev/sdb* /dev/sdc* /dev/sdd*"
ssh server-72 "sudo chown ceph.ceph /dev/sdb* /dev/sdc* /dev/sdd*"
ssh server-73 "sudo chown ceph.ceph /dev/sdb* /dev/sdc* /dev/sdd*"

ceph-deploy osd activate server-71:sdb1:/dev/sdd1 server-71:sdc1:/dev/sdd2
ceph-deploy osd activate server-72:sdb1:/dev/sdd1 server-72:sdc1:/dev/sdd2
ceph-deploy osd activate server-73:sdb1:/dev/sdd1 server-73:sdc1:/dev/sdd2
```

Change to "all-can-read" the admin keyring:

```bash
ssh server-71 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
```

Now we can check the health of our node by running the command, and we'll see something that is still wrong:

```bash
[ceph-deploy@server-71 ceph-cluster]$ ceph health
HEALTH_WARN too few PGs per OSD (21 < min 30)
[ceph-deploy@server-71 ceph-cluster]$
```

Our PG's per OSD are too low for our 6 OSD's in the cluster. More info on this:

```bash
[ceph-deploy@server-71 ceph-cluster]$ ceph osd lspools
0 rbd,
[ceph-deploy@server-71 ceph-cluster]$ ceph osd pool get rbd pg_num
pg_num: 64
[ceph-deploy@server-71 ceph-cluster]$

```

The minimun "recommended" PG's x OSD is 20, and the máximun is 32 (this is something I recommend the lector to review on ceph online documentation).

For our 6 OSD's, our minimun would be 6 x 20 = 120 PG/PGP, and our maximun 6 x 32 = 192 PG/PGP. If you set the minimun for this (30, according to the healht message), 6 x 30 = 180. We can set to the actual minimun ceph expects (180) with the following commands:

```bash
ceph osd pool set rbd pg_num 180
ceph osd pool set rbd pgp_num 180
```

NOTE: More information here: [http://docs.ceph.com/docs/master/rados/operations/placement-groups/](http://docs.ceph.com/docs/master/rados/operations/placement-groups/)

After a few moments (seconds, o minutes depending of your cluster disk and net speeds) the cluster will rebalance itself and then:

```bash
[ceph-deploy@server-71 ceph-cluster]$ ceph health
HEALTH_OK
[ceph-deploy@server-71 ceph-cluster]$

```


And

```bash
[ceph-deploy@server-71 ceph-cluster]$ ceph -s
    cluster f9a466d8-a0e6-42ba-863d-08e417cd3025
     health HEALTH_OK
     monmap e1: 1 mons at {server-71=192.168.56.71:6789/0}
            election epoch 3, quorum 0 server-71
     osdmap e35: 6 osds: 6 up, 6 in
            flags sortbitwise,require_jewel_osds
      pgmap v78: 180 pgs, 1 pools, 0 bytes data, 0 objects
            207 MB used, 191 GB / 191 GB avail
                 180 active+clean
[ceph-deploy@server-71 ceph-cluster]$
```

The final message (180 active+clean) means all your placement groups are working, and your cluster is fully online.

We can (this is optional, but very usefull) set all our nodes as admins with the following command:

```bash 
ceph-deploy admin server-71 server-72 server-73
ssh server-71 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh server-72 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh server-73 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
```

Next step, add the metadata server (in server-71 for our lab):

```bash
ceph-deploy mds create server-71
```

And, activate the remaining 2 nodes as Monitors too:

```bash
ceph-deploy mon add server-72
ceph-deploy mon add server-73
```

Check the quorum status with the following command:

```bash
ceph quorum_status --format json-pretty
```

The resuld should be:

```bash

{
    "election_epoch": 6,
    "quorum": [
        0,
        1,
        2
    ],
    "quorum_names": [
        "server-71",
        "server-72",
        "server-73"
    ],
    "quorum_leader_name": "server-71",
    "monmap": {
        "epoch": 3,
        "fsid": "f9a466d8-a0e6-42ba-863d-08e417cd3025",
        "modified": "2017-05-01 17:35:28.141805",
        "created": "2017-05-01 17:07:45.207622",
        "mons": [
            {
                "rank": 0,
                "name": "server-71",
                "addr": "192.168.56.71:6789\/0"
            },
            {
                "rank": 1,
                "name": "server-72",
                "addr": "192.168.56.72:6789\/0"
            },
            {
                "rank": 2,
                "name": "server-73",
                "addr": "192.168.56.73:6789\/0"
            }
        ]
    }
}
```

You are set here. Exit the account with:

```bash
exit
```

And, in order to force via "udev" that all ceph-related devices are property of "ceph" account, create the following file in all 3 CEPH nodes:

```bash
vi /etc/udev/rules.d/10-ceph-udev.rules
```

Containing:

```bash
SUBSYSTEM=="block", KERNEL=="sdb*", OWNER="ceph", GROUP="ceph", MODE="0660"
SUBSYSTEM=="block", KERNEL=="sdc*", OWNER="ceph", GROUP="ceph", MODE="0660"
SUBSYSTEM=="block", KERNEL=="sdd*", OWNER="ceph", GROUP="ceph", MODE="0660"
```

Then save the file. Now, each time you reboot your server, your devices will be set as property of ceph.

Finally, just to check that our cluster is able to function after a full reboot, proceed to reboot all 3 CEPH servers:

```bash
reboot
```

After all nodes are started again, chech the cluster status with "ceph health" and "ceph -w".


## LAB SETUP. PART 2 (CEPH-Owncloud related setups - Basic rbd block storage).

In this section we'll create the pool that will be mounted as a block device inside the owncloud server.


### Owncloud POOL creation.

In any of the CEPH nodes, proceed to create the pool for Owncloud and set a replica factor of "2" (mean, the original object and one copy) with the following commands:

```bash
ceph osd pool create owncloud 180 180 replicated
ceph osd pool set owncloud size 2
```

Verify the pool with "rados lspools":

```bash
[root@server-71 ~]# rados lspools
rbd
owncloud
[root@server-71 ~]#
```

### Owncloud Server Setup - CEPH preparations.

Create a ceph-deploy account in the owncloud server (server-70):

```bash
useradd -c "Ceph Deploy User" -m -d /home/ceph-deploy -s /bin/bash ceph-deploy
echo "ceph-deploy:P@ssw0rd"|chpasswd

```

And give the account in server-70 (owncloud) proper sudo permissions:

```bash
echo "ceph-deploy ALL = (ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
sudo chmod 0440 /etc/sudoers.d/ceph-deploy

```

Run the following command on the "server-70" machine in order to ensure our CEPH node names are resolvable via /etc/hosts:

```bash
echo "192.168.56.71 server-71" >> /etc/hosts
echo "192.168.56.72 server-72" >> /etc/hosts
echo "192.168.56.73 server-73" >> /etc/hosts

```


In the ceph-deploy node (server-71), proceed to enter into the ceph-deploy account and the change to the ceph-cluster dir:

```bash
su - ceph-deploy
cd ~/ceph-cluster/
```

From the ceph-deploy account in the ceph-deploy node "server-71", proceed to copy the ssh-key to the owncloud server:

```bash
ssh-copy-id server-70
```

And, install the ceph dependencies from the ceph-deploy machine "server-71" to the owncloud machine "server-70":

```bash
ceph-deploy install server-70
ceph-deploy admin server-70
ssh server-70 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh server-70 "sudo yum -y install ceph-common python-ceph-compat python-cephfs rbd-fuse"
```

Still in the ceph-deploy account in the ceph-deploy server "server-70", proceed to create an account that we'll use to authenticate access to the "owncloud" pool:

```bash
ceph auth get-or-create client.owncloud mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=owncloud'

```

The result from the last command is (for this specific LAB):

```bash
[client.owncloud]
        key = AQCepwhZPWwCFxAAQMTdn17Vbj+DJ7MAQ2YlcA==
```

With this access key created, send the key to the owncloud server (server-70) from the ceph-deploy account in server-71:

```bash
ceph auth get-or-create client.owncloud | ssh server-70 "sudo tee /etc/ceph/ceph.client.owncloud.keyring"
ssh server-70 "sudo chmod +r /etc/ceph/ceph.client.owncloud.keyring"

```

Exit the ceph-deploy account.


### CEPH RBD Mount on the Owncloud server.

Because our owncloud node is also admin, we can create a volume inside, but, first some calculations....

Our CEPH cluster size (total) is 32GB x 6 = 192GB, but, because our replica factor is 2 (the object and a copy), our actual "máximun safe size" is two thirds of that, mean, 32GB x 4 = 128GB. With that on mind, we should not create anything larger than this safe limit. In any case, we'll just create a single 64GB volume inside the pool with the following command:

```bash
rbd --pool owncloud create --size 64G owncloud-rbd-01
```

And, check it with "rbd --pool owncloud du":

```bash
[root@server-70 ~]# rbd --pool owncloud du
warning: fast-diff map is not enabled for owncloud-rbd-01. operation may be slow.
NAME            PROVISIONED USED
owncloud-rbd-01      65536M    0

```

*Did you saw the "fast-diff" warning ?. You can enable it, but, you can also need to enable "object-map" and "exclusive-lock". Sadly, the RBD kernel module is still uncompatible with those features so, we should not enable them by now. That's the reason of the "rbd default features = 1" inside the ceph config.*

You can check your volume (image really) with the "rbd info" command:

```bash
[root@server-70 ~]# rbd info --pool owncloud owncloud-rbd-01
rbd image 'owncloud-rbd-01':
        size 65536 MB in 16384 objects
        order 22 (4096 kB objects)
        block_name_prefix: rbd_data.121da238e1f29
        format: 2
        features: layering
        flags:
[root@server-70 ~]#
```

With our client created (client.owncloud) and with access to the "onwncloud" pool, map a device to it using the following command (in the owncloud server "server-70"):

```bash
rbd map owncloud-rbd-01 --name client.owncloud --pool owncloud
```

Result:

```
/dev/rbd0
```

So, our "owncloud-rbd-01" 64GB image inside the owncloud pool is mapped to the block device "/dev/rbd0" on the "server-70" machine. You can also see that with "blkid":

```bash
[root@server-70 ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
rbd0   252:0    0   64G  0 disk
sr0     11:0    1 1024M  0 rom
sda      8:0    0   60G  0 disk
+-sda2   8:2    0    4G  0 part [SWAP]
+-sda3   8:3    0 55.8G  0 part /
+-sda1   8:1    0  256M  0 part /boot
[root@server-70 ~]#
```

Format the block device:

```bash
parted -s /dev/rbd0 mklabel gpt mkpart primary xfs 0% 100%
mkfs.xfs -f /dev/rbd0
```

Proceed to create a directory for mounting the filesystem (on server-70):

```bash
mkdir /mnt/owncloud-data
```

And, add the following lines to /etc/fstab:

```bash
#
# Owncloud pool
#
/dev/rbd0       /mnt/owncloud-data      xfs     rw,noauto        0 0
```

Mount it:

```bash
mount /mnt/owncloud-data
```

Add the following line to the *"/etc/ceph/rbdmap"* file in the owncloud server:

```bash
owncloud/owncloud-rbd-01 id=owncloud,keyring=/etc/ceph/ceph.client.owncloud.keyring
```

Enable the rbdmap service (again, in server-70):

```bash
systemctl enable rbdmap.service
```

And, add the following command at the end of your /etc/rc.local file:

```bash
/usr/bin/mount /mnt/owncloud-data
```

*NOTE: The reason we create the fstab entry with "rw,noauto" and later mount the filesystem in the rc.local file, is because the rbdmap service runs after the mount service, creating a situation where the block device is not available at the time the system try to mount it, and, negating any posible boot without error.*

In order to test that the rbd device is being mounted at boot, proceed to reboot the server and then check thar everything is mounted and working OK.


## LAB SETUP. PART 3 (Owncloud Installation with the rbd block device).

In this section we are going to install Owncloud, and, set it to use the block device for its primary storage.


### MariaDB installation and setup.

Owncloud needs a database, and for our setup we'll use MariaDB 10.1. First, add the MariaDB repository. Create the file "/etc/yum.repos.d/mariadb101.repo" with the following contents:

```bash
# MariaDB 10.1 CentOS repository list - created 2017-05-02 17:25 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

And, run the following commands:

```bash
yum -y update
yum -y install MariaDB MariaDB-server MariaDB-client galera
yum -y install crudini

echo "" > /etc/my.cnf.d/server-owncloud.cnf

crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld binlog_format ROW
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld default-storage-engine innodb
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld innodb_autoinc_lock_mode 2
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld query_cache_type 0
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld query_cache_size 0
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld bind-address 0.0.0.0
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld max_allowed_packet 1024M
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld max_connections 1000
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld innodb_doublewrite 1
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld innodb_log_file_size 100M
crudini --set /etc/my.cnf.d/server-owncloud.cnf mysqld innodb_flush_log_at_trx_commit 2
echo "innodb_file_per_table" >> /etc/my.cnf.d/server-owncloud.cnf

systemctl enable mariadb.service
systemctl start mariadb.service

/usr/bin/mysqladmin -u root password "P@ssw0rd"

echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"P@ssw0rd\""  >> /root/.my.cnf
echo "host = \"localhost\""  >> /root/.my.cnf

```

With the MariaDB 10.1 engine working, proceed to create the database:

```bash
mysql -e "CREATE DATABASE owncloud;"
```


### Owncloud dependencies and packages installation. Owncloud setup with the CEPH-RBD device.

We'll install and configure Owncloud, and modify it in order to use the already-mounted CEPH RBD device on /mnt/owncloud-data.

Run the following commands in order to install all required packages. Owncloud is part of EPEL repositories (another reason to need EPEL REPOS on the servers).

```bash
yum -y install owncloud-httpd owncloud-mysql owncloud \
httpd php php-mysql sqlite php-dom \
php-mbstring php-gd php-pdo php-json php-xml php-zip \
php-gd curl php-curl php-mcrypt php-pear

```

And, set some extra configs:

```bash
crudini --set /etc/php.ini PHP upload_max_filesize 60M
crudini --set /etc/php.ini PHP post_max_size 60M
```

Proceed to create the following symlink:

```bash
ln -s /etc/httpd/conf.d/owncloud-access.conf.avail /etc/httpd/conf.d/z-owncloud-access.conf
```

Enable/Start apache:

```bash
systemctl enable httpd
systemctl start httpd
```

Run the following command in order to setup owncloud:

```bash
sudo -u apache /usr/bin/php /usr/share/owncloud/occ maintenance:install --database "mysql" --database-name "owncloud"  --database-user "root" --database-pass "P@ssw0rd" --admin-user "admin" --admin-pass "P@ssw0rd" --data-dir="/var/lib/owncloud/data"
```

The last command need the database root user and it's password in order to run. Also, it will set the Owncloud Admin user "admin" with password "P@ssw0rd".

Next, we need to let Owncloud knows the fqdn's and/or IP's used to contact it with any browser. Our server FQDN is "server-70.virtualpc.gatuvelus.home", IP 192.168.56.70, so, let's include those as allowed access domains:

```bash
sudo -u apache /usr/bin/php /usr/share/owncloud/occ config:system:set trusted_domains 1 --value=192.168.56.70
sudo -u apache /usr/bin/php /usr/share/owncloud/occ config:system:set trusted_domains 2 --value=server-70.virtualpc.gatuvelus.home
```

In order to include dependencies for caching, let's install and activate redis:

```bash
yum -y install redis php-pecl-redis
systemctl enable redis
systemctl start redis
```

Then, proceed to add the following config to the owncloud configuration file "/etc/owncloud/config.php":

```bash

  'memcache.local' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' =>
  array(
    'host' => 'localhost',
    'port' => 6379,
  ),
```

And, restart apache:

```bash
systemctl restart httpd
```

Now, in order to let Owncloud use our RBD device, move owncloud data directory to the RBD mount point, and, create a symlink, all by using the following commands:

```bash
mv /var/lib/owncloud/data /mnt/owncloud-data/
ln -s /mnt/owncloud-data/data /var/lib/owncloud/data
systemctl restart httpd
```

If this web server will be dedicated just for owncloud, proceed to create the file *"/var/www/html/index.html"* with the following contents:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/owncloud">
</HEAD>
<BODY>
</BODY>
</HTML>
```

This file will ensure proper redirection from the root website to the actual "/owncloud" webdir.


## LAB SETUP. PART 4. Add external storare folder with a CEPH-S3 object storage.

The primary backing storage is based on CEPH-RBD (block device), but, we can also add "external storage" based on a native object storage like CEPH-S3.


### CEPH-S3 configuration on the CEPH cluster.

In the ceph deploy server "server-71", enter with "su" to the deploy user, and change to the ceph-cluster directory:

```bash
su - ceph-deploy
cd ceph-cluster/
```

Proceed to create two rados gateways, one on server-72 and the other in server-73:

```bash
ceph-deploy rgw create server-72 server-73
```

The API gateways will serve on port 7480.

Why two servers ?. In our solution we are going to use just one, but, in actual production conditions, you'll likely use both servers behind any load-balancing solution.

Next thing to do is create our user for S3-Like access to our services. Run the following commands (inside the ceph-deploy account):

```bash
radosgw-admin user create --uid="ownclouds3" --display-name="Owncloud S3 User"
radosgw-admin quota set --quota-scope=user --uid="ownclouds3" --max-objects=-1 --max-size=64G
```

With "radosgw-admin user info --uid=ownclouds3" we can obtain the user information, specially the access key and secret:


```bash
[root@server-70 data]# radosgw-admin user info --uid=ownclouds3

{
    "user_id": "ownclouds3",
    "display_name": "Owncloud S3 User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "ownclouds3",
            "access_key": "BTEBI1IGKSGP3ZYWR292",
            "secret_key": "j4QtRO10f3rc5WRKjSSUBrYdzT7sqgTiEZXmYnwD"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "max_size_kb": -1,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "max_size_kb": 67108864,
        "max_objects": -1
    },
    "temp_url_keys": []
}

```

Then, for this LAB, the user access key is "BTEBI1IGKSGP3ZYWR292" and the secret "j4QtRO10f3rc5WRKjSSUBrYdzT7sqgTiEZXmYnwD"

The next task is test this information in the Owncloud server.


### CEPH-S3 configuration on the Owncloud server.

Before configure Owncloud to access the CEPH-S3 gateway, we should ensure the owncloud server "server-70" can interact with the gateway service. In the server-70, run the following commands in order to install what we need to interact with S3:

```bash
yum -y install python-boto
```

Create a python script "/root/cephs3test.py" with the following contents:

```bash
import boto
import boto.s3.connection

access_key = 'BTEBI1IGKSGP3ZYWR292'
secret_key = 'j4QtRO10f3rc5WRKjSSUBrYdzT7sqgTiEZXmYnwD'
conn = boto.connect_s3(
   aws_access_key_id = access_key,
   aws_secret_access_key = secret_key,
   host = 'server-72', port = 7480,is_secure=False, calling_format = boto.s3.connection.OrdinaryCallingFormat(),)

bucket = conn.create_bucket('my-new-bucket')
for bucket in conn.get_all_buckets():
   print "{name} {created}".format(name = bucket.name,created = bucket.creation_date,)
```

Run the script with python:

```bash
python /root/cephs3test.py
```

The result should be something like:

```bash
my-new-bucket 2017-05-02T20:04:02.009Z
```

*NOTE:* This sample is taken from the CEPH page: http://docs.ceph.com/docs/jewel/install/install-ceph-gateway/

You can check the bucket existence with the following command:

```bash
[root@server-70 data]# radosgw-admin bucket list
[
    "my-new-bucket"
]
```

Then, erase the test bucket. Use the command:

```bash
radosgw-admin bucket rm my-new-bucket
```

Now that we know our owncloud machine can interact with CEPH-S3, let's modify owncloud to use it. First, go to your owncloud server and log in using the admin credentials (admin/P@ssw0rd).

Go to the "admin" menu, then to the "Apps" section (http://192.168.56.70/owncloud/index.php/settings/apps). In the "disabled" section, enable the "External storage support" APP.

Now, because you activated the external storage support app, in the administration menu you'll have a new option for external storage. Add amazon S3 external storage with the following configuration:

- Folder Name: CEPH-S3-Cluster
- bucket: owncloudbucket
- hostname: 192.168.56.72
- port: 7480
- Access key: BTEBI1IGKSGP3ZYWR292
- Secret key: j4QtRO10f3rc5WRKjSSUBrYdzT7sqgTiEZXmYnwD
- Enable Path Style: Checked

After you have set those settings, you'll see a green circle at the left of your storage option, indicating that you are connected to the CEPH-S3 storage.

Logout, and log-back in to start using your owncloud installation backed by CEPH-S3 object storage.

Note something here. The extra object-backed storaged will be added as an "extra folder" that can share contents among all (or specific) users in Owncloud, but, it won't be the primary backing storage. In order to use CEPH-S3 as "primary backing storage", you need the "enterprise" owncloud version.


### What if I want redundancy or load-balancing in Owncloud ?

If, you want just redundancy (active/stand-by), you can use cluster solutions like pacemaker/corosync in order to have two owncloud servers sharing a VIP (virtual IP) and mounting the RBD device in the active node. That's already covered on some of my recipes. Just ensure the RBD device is mapped to all servers needing it, but, ensure also only one server will use it at the time, our you'll risk data corruption.

Now, if you want multiple servers running at the same time and load-balance them behind any http-capable load balancer, you have the following options:

- Use the owncloud enterprise version with CEPH-S3 as primary backing storage.
- Use the community version, but, instead of formating the RBD device with xfs, use a cluster-aware filesystem like GFS or OCFS. Also, remember to disable RBD caching as this is not compatible with the use of either GFS or OCFS. More information [here](http://docs.ceph.com/docs/master/rbd/rbd-config-ref/).


### Extending the LAB: Using NEXTCLOUD instead of OWNCLOUD.

Lets asume that you want to get rid of owncloud and use nextcloud instead. Note that the following steps will force the removal of Owncloud.

First, let's create a database for our nextcloud installation:

```bash
mysql -e "CREATE DATABASE nextcloud;"
mysql -e "grant all on nextcloud.* to 'nextclouduser'@'localhost' identified by 'P@ssw0rd';"
mysql -e "FLUSH PRIVILEGES;"
```

Download the lattest 11 release and unzip it to apache main web dir:

```bash
mkdir /workdir
cd /workdir
wget https://download.nextcloud.com/server/releases/latest-11.zip
unzip /workdir/latest-11.zip -d /var/www/html/
```

Now, and because nextcloud requires php from 5.6 and centos 7 php version is 5.4, we need to update our php version. Note that, this will KILL our owncloud install:

```bash
yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum update --skip-broken
yum -y erase php-common
yum -y install mod_php71w php71w php71w-opcache \
php71w-pear php71w-pdo php71w-xml php71w-pdo_dblib \
php71w-mbstring php71w-mysql php71w-mcrypt php71w-fpm \
php71w-bcmath php71w-gd php71w-cli php71w-zip php71w-dom \
php71w-pecl-memcached php71w-pecl-redis
```

Your old owncloud config will be located at "/etc/owncloud/config.php.rpmsave".

Set some extra PHP configs:

```bash
crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M
```

Modify the file "/var/www/html/index.html". New contents:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/nextcloud">
</HEAD>
<BODY>
</BODY>
</HTML>
```

Get rid of last owncloud dependencies:

```bash
rm -f /etc/httpd/conf.d/z-owncloud-access.conf
rm -rf /etc/owncloud
rm -rf /mnt/owncloud-data/data
mysql -e "DROP DATABASE owncloud;"
```

Create a directory inside our RBD mount point:

```bash
mkdir /mnt/owncloud-data/data
```

Set the following permissions:

```bash
chown -R apache.apache /var/www/html/nextcloud /mnt/owncloud-data/data
```

Restart apache:

```bash
systemctl restart httpd
```

Next step: Enter with a browser to our nextcloud directory and set database info and data dir:

- http://192.168.56.70/nextcloud

Complete the following information:

- User: admin
- Password: P@ssw0rd
- Data dir: /mnt/owncloud-data/data
- Database type: mysql/mariadb
- DB Name: nextcloud
- DB User: nextclouduser
- DB User password: P@ssw0rd
- DB Host: localhost:3306

Then click on "complete the installation". Your installation will begin to use the RBD mount in "/mnt/owncloud-data".


### Setting NEXTCLOUD primary storage to CEPH-S3 native object storage.

Using RBD is OK but, what if you want to use a CEPH-S3 bucket as primary storage instead of the data dir at /mnt/owncloud-data/data ?. This is one of the main differences between Nextcloud and Owncloud. In owncloud, only te enterprise offering can use CEPH/AWS S3 as primary backend. In next cloud, you can use CEPH/AWS S3 right out of the box !.

Let's proceed to create a CEPH-S3 bucket for our nextcloud installation. First, our user:

```bash
radosgw-admin user create --uid="nextclouds3" --display-name="Nextcloud S3 User"
radosgw-admin quota set --quota-scope=user --uid="nextclouds3" --max-objects=-1 --max-size=64G
```

And get the auth info:

```bash
[root@server-70 data]# radosgw-admin user info --uid=nextclouds3
{
    "user_id": "nextclouds3",
    "display_name": "Nextcloud S3 User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "nextclouds3",
            "access_key": "X2UYM65Q9Y52EJGBYGBN",
            "secret_key": "tdJnpQUMU1xY9V58ZC35YQ4SrXYyrFODwkskmiP6"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "max_size_kb": -1,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "max_size_kb": 67108864,
        "max_objects": -1
    },
    "temp_url_keys": []
}
```

Our access key is "X2UYM65Q9Y52EJGBYGBN" and our secret "tdJnpQUMU1xY9V58ZC35YQ4SrXYyrFODwkskmiP6".

Now, in order to get our installation to use CEPH-S3, we need to modify the file "/var/www/html/nextcloud/config/config.php" and include the following section:

```bash
  'objectstore' => array (
        'class' => 'OC\\Files\\ObjectStore\\S3',
        'arguments' => array (
                'bucket' => 'nextcloud',
                'autocreate' => true,
                'key'    => 'X2UYM65Q9Y52EJGBYGBN',
                'secret' => 'tdJnpQUMU1xY9V58ZC35YQ4SrXYyrFODwkskmiP6',
                'hostname' => '192.168.56.72',
                'port' => 7480,
                'use_ssl' => false,
                'region' => 'optional',
                // required for some non amazon s3 implementations
                'use_path_style'=>true
        ),
  ),
```

Our new config file will be set to:

```bash
<?php
$CONFIG = array (
  'instanceid' => 'oclxrn65asbl',
  'passwordsalt' => 'rMZe6RWrIgHSyfxIy1kcjd0Tg4sZVx',
  'secret' => 'CvK5CCiL+tMU9rX/FeVtL3b4IXdhOCnp/MglZJx+XPbqui9x',
  'trusted_domains' =>
  array (
    0 => '192.168.56.70',
  ),
  'datadirectory' => '/mnt/owncloud-data/data',
  'objectstore' => array (
        'class' => 'OC\\Files\\ObjectStore\\S3',
        'arguments' => array (
                'bucket' => 'nextcloud',
                'autocreate' => true,
                'key'    => 'X2UYM65Q9Y52EJGBYGBN',
                'secret' => 'tdJnpQUMU1xY9V58ZC35YQ4SrXYyrFODwkskmiP6',
                'hostname' => '192.168.56.72',
                'port' => 7480,
                'use_ssl' => false,
                'region' => 'optional',
                // required for some non amazon s3 implementations
                'use_path_style'=>true
        ),
  ),
  'overwrite.cli.url' => 'http://192.168.56.70/nextcloud',
  'dbtype' => 'mysql',
  'version' => '11.0.3.2',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'nextclouduser',
  'dbpassword' => 'P@ssw0rd',
  'logtimezone' => 'UTC',
  'installed' => true,
);
```

Then, restart apache:

```bash
systemctl restart httpd
```

Also, proceed to add the following config to the owncloud configuration file "/var/www/html/nextcloud/config/config.php":

```bash
  'memcache.local' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' =>
  array (
    'host' => 'localhost',
    'port' => 6379,
  ),
```

Then (again) restart apache:

```bash
systemctl restart httpd
```

Our final config:

```bash
<?php
$CONFIG = array (
  'instanceid' => 'oclxrn65asbl',
  'passwordsalt' => 'rMZe6RWrIgHSyfxIy1kcjd0Tg4sZVx',
  'secret' => 'CvK5CCiL+tMU9rX/FeVtL3b4IXdhOCnp/MglZJx+XPbqui9x',
  'trusted_domains' =>
  array (
    0 => '192.168.56.70',
  ),
  'datadirectory' => '/mnt/owncloud-data/data',
  'objectstore' => array (
        'class' => 'OC\\Files\\ObjectStore\\S3',
        'arguments' => array (
                'bucket' => 'nextcloud',
                'autocreate' => true,
                'key'    => 'X2UYM65Q9Y52EJGBYGBN',
                'secret' => 'tdJnpQUMU1xY9V58ZC35YQ4SrXYyrFODwkskmiP6',
                'hostname' => '192.168.56.72',
                'port' => 7480,
                'use_ssl' => false,
                'region' => 'optional',
                // required for some non amazon s3 implementations
                'use_path_style'=>true
        ),
  ),
  'memcache.local' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' =>
  array (
    'host' => 'localhost',
    'port' => 6379,
  ),
  'overwrite.cli.url' => 'http://192.168.56.70/nextcloud',
  'dbtype' => 'mysql',
  'version' => '11.0.3.2',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'nextclouduser',
  'dbpassword' => 'P@ssw0rd',
  'logtimezone' => 'UTC',
  'installed' => true,
);
```

Now, all your user files will be stored using CEPH-S3. That, apart of being more "native" for nextcloud, will ease your multi-server/load-balanced nextcloud deployments!.

We can check the bucket statistics using radosgw-admin command tool:

```bash
[root@server-70 /]# radosgw-admin bucket stats --bucket=nextcloud
{
    "bucket": "nextcloud",
    "pool": "default.rgw.buckets.data",
    "index_pool": "default.rgw.buckets.index",
    "id": "3720f2c0-132c-4c49-8dbb-17ad3cc6c9ad.94107.1",
    "marker": "3720f2c0-132c-4c49-8dbb-17ad3cc6c9ad.94107.1",
    "owner": "nextclouds3",
    "ver": "0#181",
    "master_ver": "0#0",
    "mtime": "2017-05-29 21:11:14.415720",
    "max_marker": "0#",
    "usage": {
        "rgw.main": {
            "size_kb": 116890,
            "size_kb_actual": 117004,
            "num_objects": 46
        }
    },
    "bucket_quota": {
        "enabled": false,
        "max_size_kb": -1,
        "max_objects": -1
    }
}
```

And if you want to list all objects in the bucket, use the command:

```bash
radosgw-admin bucket list --bucket=nextcloud
```

END.-


