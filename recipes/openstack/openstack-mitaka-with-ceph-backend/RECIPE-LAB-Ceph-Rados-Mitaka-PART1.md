# LAB: AN OPENSTACK MITAKA CLOUD WITH CEPH RADOS STORAGE BACKEND USING UBUNTU 14.04LTS - PART 1: CEPH CLUSTER

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to acomplish two major goals here:

* Install/deploy a fully working CEPH Cluster using Ubuntu 14.04lts packages (with external CEPH repos).
* Reconfigure an OpenStack existing installation (Mitaka on Ubuntu 14.04lts) in order to use the CEPH Cluster in Nova and Cinder as storage backends. This will cover both ephemeral and permanent disk space.


## Where are we going to install it ?:

For the first part (the CEPH cluster) we will use 3 Ubuntu 14.04lts nodes, each one with the following configuration:

* Ubuntu 14.04 lts x86_64 installed and fully updated.
* 4 VCPU's, 4 GB's RAM, 8 GB's Swap disk, and one extra ephemeral 60Gb disk for CEPH storage.

Nodes IP and names:

* Node 1: vm-172-16-11-62: 172.16.11.62
* Node 2: vm-172-16-11-63: 172.16.11.63
* Node 3: vm-172-16-11-64: 172.16.11.64

We'll use the first node as "deploy node" too.

All nodes are correctly NTP-Configured and fully updated.

For the second part (the OpenStack integration with the CEPH cluster) we will use an existing OpenStack monolithic system using Mitaka on Ubuntu 14.04lts. The system was installed using the following automated tool:

* [TigerLinux OpenStack MITAKA Unattended-Automated tool for Ubuntu 14.04lts](https://github.com/tigerlinux/openstack-mitaka-installer-ubuntu1404lts)

OpenStack Server IP: 172.16.11.179. Correctly NTP-Configured and fully updated.


## How are we going to do it ?:

We are dividing this recipe in two parts. The first part (this document) will create the CEPH cluster, and the second part will modify the OpenStack server in order to use CEPH.


### Basic server setup:

First, we need to ensure our servers are fully updated:

```bash
aptitude update
aptitude -y upgrade
```

Also, we are going to use a 4.x based kernel, from Ubuntu repos:

```bash
apt-get install --install-recommends linux-generic-lts-wily
reboot
```

Once the servers are back online, we need to include the CEPH repo:

```bash
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
apt-add-repository 'deb http://download.ceph.com/debian-jewel/ trusty main'
aptitude update
```

We are going to use the node-1 (172.16.11.62) as our ceph-deploy node. For this task we'll create a "ceph-deploy" user on all 3 nodes with the following commands.

```bash
useradd -c "Ceph Deploy User" -m -d /home/ceph-deploy -s /bin/bash ceph-deploy
echo "ceph-deploy:P@ssw0rd"|chpasswd
```

In the first node (172.16.11.62), we change with "su" to the user and generate a ssh-key:

```bash
su - ceph-deploy
ssh-keygen -t rsa
```

And, still into the ceph-deploy account, we proceed to copy the ssh-key to all servers, and exit from the account:

```bash
ssh-copy-id vm-172-16-11-62
ssh-copy-id vm-172-16-11-63
ssh-copy-id vm-172-16-11-64
exit
```

In all 3 nodes, we add sudo permisions to the account:

```bash
echo "ceph-deploy ALL = (ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
sudo chmod 0440 /etc/sudoers.d/ceph-deploy
```

In the ceph-deploy node (node 1, 172.16.11.62), do a "su - ceph-deploy", create the following file:

```bash
su - ceph-deploy
vi ~/.ssh/config
```

Containing:

```bash
Host vm-172-16-11-62
   Hostname vm-172-16-11-62
   User ceph-deploy
Host vm-172-16-11-63
   Hostname vm-172-16-11-63
   User ceph-deploy
Host vm-172-16-11-64
   Hostname vm-172-16-11-64
   User ceph-deploy
Host 172.16.11.179
   Hostname 172.16.11.179
   User ceph-deploy
```

Save the file and exit the ceph-deploy account.

```
exit
```

With the user and ssh part ready, we proceed to format the filesystem ceph will use for storage:

In each server we proceed to execute:

```bash
aptitude -y install xfsprogs
mkfs.xfs -L ceph-storage /dev/vdb -f
mkdir -p /srv/ceph-storage
echo "LABEL=ceph-storage /srv/ceph-storage xfs rw,noexec,nodev,noatime,nodiratime,barrier=0 0 0" >> /etc/fstab
mount /srv/ceph-storage
```

**NOTE:** At the end of this recipe you'll find some notes about real-life production environments. What we are doing here is good for a LAB, but not very good for a real-file production environment.

Finally, in the ceph-deploy node (172.16.11.62) install the ceph-deploy tool:

```bash
aptitude install ceph-deploy
```

This conclude the basic server setup.


### CEPH Cluster deployment:

**Please take note: All the following commands will be executed in the "deploy" node (172.16.11.62) and inside the ceph-deploy user:**

Enter with "su" to the deploy user:

```bash
su - ceph-deploy
```

Create the following directory and change into it:

```bash
mkdir ~/ceph-cluster
cd ~/ceph-cluster
```

Execute the command:

```bash
ceph-deploy new vm-172-16-11-62
```

Edit the following file:

```bash
vi ceph.conf
```

Add the lines:

```bash
osd pool default size = 2
rbd default features = 1
```

NOTE: If you have multiple network interfaces, also add:

```
public network = {cidr}/{netmask}
cluster network = {cidr}/{netmask}
```

Example:

```
public network = 172.16.11.0/24
cluster network = 172.16.10.0/24
```

**VERY IMPORTANT NOTE:** In production conditions, you should have two networks: A public network for most client-server operations, and a cluster network for inter-ceph-nodes operations. See [CEPH Network Documentation for more information about this topic.](http://docs.ceph.com/docs/jewel/rados/configuration/network-config-ref/)

Now, we proceed to install the packages:

```bash
ceph-deploy install vm-172-16-11-62 vm-172-16-11-63 vm-172-16-11-64
```

**NOTE:** From the last command, you'll see an "apt" error. This does not affect really the installation, as the error happens for a "apt duplicated" entry. The install command create a repo file in /etc/apt/sources.list.d for the CEPH repository, so, in order to get rid of this line, after the "ceph deploy install XXXX" command is completed, edit your /etc/apt/sources.list file and comment the following line near the end of the file:

```bash
# deb http://download.ceph.com/debian-jewel/ trusty main
```

The ceph deploy command will install all ceph-needed packages in all 3 nodes.

Now, let's create the initial monitor:

```bash
ceph-deploy mon create-initial
```

This last command created the keyrings:

```bash
ceph-deploy@vm-172-16-11-62:~/ceph-cluster$ ls -la *.keyring
-rw------- 1 ceph-deploy ceph-deploy 71 Jun  7 13:51 ceph.bootstrap-mds.keyring
-rw------- 1 ceph-deploy ceph-deploy 71 Jun  7 13:51 ceph.bootstrap-osd.keyring
-rw------- 1 ceph-deploy ceph-deploy 71 Jun  7 13:51 ceph.bootstrap-rgw.keyring
-rw------- 1 ceph-deploy ceph-deploy 63 Jun  7 13:51 ceph.client.admin.keyring
-rw------- 1 ceph-deploy ceph-deploy 73 Jun  7 13:43 ceph.mon.keyring
ceph-deploy@vm-172-16-11-62:~/ceph-cluster$ 
```

Let's prepare and activate our 3 OSD's by running the following commands:

```bash
ceph-deploy osd prepare vm-172-16-11-62:/srv/ceph-storage
ceph-deploy osd prepare vm-172-16-11-63:/srv/ceph-storage
ceph-deploy osd prepare vm-172-16-11-64:/srv/ceph-storage

ssh vm-172-16-11-62 "sudo chown ceph.ceph /srv/ceph-storage"
ssh vm-172-16-11-63 "sudo chown ceph.ceph /srv/ceph-storage"
ssh vm-172-16-11-64 "sudo chown ceph.ceph /srv/ceph-storage"

ceph-deploy osd activate vm-172-16-11-62:/srv/ceph-storage
ceph-deploy osd activate vm-172-16-11-63:/srv/ceph-storage
ceph-deploy osd activate vm-172-16-11-64:/srv/ceph-storage
```

**VERY IMPORTANT NOTE AIMED TO PRODUCTION SYSTEMS:** Please stop here and understand something: This is a LAB and does not reflect a very important point for production systems: The journal SHOULD BE in a separated disk or partition (better a disk), and for optimal performace, a SSD drive is recommended. More information here: [OSD Deploy documentation.](http://docs.ceph.com/docs/jewel/rados/deployment/ceph-deploy-osd/) For an optimal performance solution, use normal disks for the OSD main storage, and ssd for the Journal.

Continuing our quest, change to "all-can-read" the admin keyring:

```bash
ssh vm-172-16-11-62 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
```

Now we can check the health of our node by running the command:

```bash
ceph-deploy@vm-172-16-11-62:~/ceph-cluster$ ceph health
HEALTH_OK
ceph-deploy@vm-172-16-11-62:~/ceph-cluster$ 
```

And

```bash
ceph-deploy@vm-172-16-11-62:~/ceph-cluster$ ceph -w
    cluster da8f49ea-5d8c-41e3-ae93-7d7812da30fc
     health HEALTH_OK
     monmap e1: 1 mons at {vm-172-16-11-62=172.16.11.62:6789/0}
            election epoch 3, quorum 0 vm-172-16-11-62
     osdmap e16: 3 osds: 3 up, 3 in
            flags sortbitwise
      pgmap v34: 64 pgs, 1 pools, 0 bytes data, 0 objects
            15459 MB used, 164 GB / 179 GB avail
                  64 active+clean

2016-06-07 14:32:42.483683 mon.0 [INF] pgmap v34: 64 pgs: 64 active+clean; 0 bytes data, 15459 MB used, 164 GB / 179 GB avail
```

If you see the message "active+clean" then the cluster is clean and rebalanced. Exit the command with **ctrl+c**.

We can (this is optional, but very usefull) set all our nodes as admins with the following command:

```bash 
ceph-deploy admin vm-172-16-11-62 vm-172-16-11-63 vm-172-16-11-64
ssh vm-172-16-11-62 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh vm-172-16-11-63 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh vm-172-16-11-64 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
```

Now, we'll add the metadata server:

```bash
ceph-deploy mds create vm-172-16-11-62
```

And, activate the remaining 2 nodes as Monitors too:

```bash
ceph-deploy mon add vm-172-16-11-63
ceph-deploy mon add vm-172-16-11-64
```

We can check the quorum status:

```bash
ceph quorum_status --format json-pretty
```

result:

```
{
    "election_epoch": 6,
    "quorum": [
        0,
        1,
        2
    ],
    "quorum_names": [
        "vm-172-16-11-62",
        "vm-172-16-11-63",
        "vm-172-16-11-64"
    ],
    "quorum_leader_name": "vm-172-16-11-62",
    "monmap": {
        "epoch": 3,
        "fsid": "da8f49ea-5d8c-41e3-ae93-7d7812da30fc",
        "modified": "2016-06-07 14:43:44.923451",
        "created": "2016-06-07 13:51:33.106780",
        "mons": [
            {
                "rank": 0,
                "name": "vm-172-16-11-62",
                "addr": "172.16.11.62:6789\/0"
            },
            {
                "rank": 1,
                "name": "vm-172-16-11-63",
                "addr": "172.16.11.63:6789\/0"
            },
            {
                "rank": 2,
                "name": "vm-172-16-11-64",
                "addr": "172.16.11.64:6789\/0"
            }
        ]
    }
}

```

We are set here. Exit the account with:

```bash
exit
```

And, just to check that our cluster is able to function after a full reboot, proceed to reboot all 3 servers:

```bash
reboot
```

After all nodes are started again, chech the cluster status with "ceph health" and "ceph -w".

NOTE: You can use also the command: "ceph report"... but, prepare for a long reading !. Maybe you'll want to do a "ceph report | less" command !.


### OpenStack POOL's and initial tests:

With our ceph cluster running, we can proceed to create the pools for our openstack installation, and do some basic tests in order to check the cluster:

It's a good idea that you document yourself about ceph operations, and specially, pools and placement groups. Please whenever you can, read the following links:

* [CEPH Pools.](http://ceph.com/docs/master/rados/operations/pools/)
* [CEPH Placement Groups.](http://ceph.com/docs/master/rados/operations/placement-groups/)

Let's create our first pool, that will be used for some testing:

NOTE: As all 3 nodes are admin's, you can run the following commands on any of the nodes, from the root account:

```bash
ceph osd pool create nova 64 64 replicated
```

Result:

```bash
pool 'nova' created
```

We can verify the pool with:

```bash
rados lspools
```

Result:

```
rbd
nova
```

Let's do a little test. Let's create a 200 MB volume inside the pool:

```
rbd --pool nova create --size 200M nova-test
```

We can run some commands to check the volume:

```bash
root@vm-172-16-11-62:~# rbd --pool nova ls
nova-test
root@vm-172-16-11-62:~# rbd --pool nova du
NAME      PROVISIONED USED 
nova-test        200M    0 
<TOTAL>          200M    0 
root@vm-172-16-11-62:~# 
```

Now, in any of our nodes (let's try in the first one, 172.16.11.62), we'll create a "rbd" device and attach the nova-test volume to it:

```bash
rbd map nova-test --name client.admin --pool nova
```

Result:

```
/dev/rbd0
```

The last operation created in our server the device /dev/rbd0, mapped to our volume "nova-test" in the pool "nova".

Then, we proceed to create a fs in the device:

```bash
mkfs.xfs -L nova-test /dev/rbd0 -f

log stripe unit (4194304 bytes) is too large (maximum is 256KiB)
log stripe unit adjusted to 32KiB
meta-data=/dev/rbd0              isize=256    agcount=8, agsize=6144 blks
         =                       sectsz=512   attr=2, projid32bit=0
data     =                       bsize=4096   blocks=49152, imaxpct=25
         =                       sunit=1024   swidth=1024 blks
naming   =version 2              bsize=4096   ascii-ci=0
log      =internal log           bsize=4096   blocks=1200, version=2
         =                       sectsz=512   sunit=8 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

```

Let's mount it:

```bash
mkdir /mnt/nova-test
mount -t xfs /dev/rbd0 /mnt/nova-test/

root@vm-172-16-11-62:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            2.0G   12K  2.0G   1% /dev
tmpfs           396M  428K  395M   1% /run
/dev/vda5        29G  2.9G   24G  11% /
none            4.0K     0  4.0K   0% /sys/fs/cgroup
none            5.0M     0  5.0M   0% /run/lock
none            2.0G     0  2.0G   0% /run/shm
none            100M     0  100M   0% /run/user
/dev/vda1       1.4G  100M  1.2G   8% /boot
/dev/vdb         60G  5.1G   55G   9% /srv/ceph-storage
/dev/rbd0       188M  9.9M  178M   6% /mnt/nova-test
root@vm-172-16-11-62:~# 
```

We can do a performance test too:

```bash
cd /mnt/nova-test
time dd if=/dev/zero of=myfile.dat bs=1M count=100

100+0 records in
100+0 records out
104857600 bytes (105 MB) copied, 0.0998055 s, 1.1 GB/s

real    0m0.102s
user    0m0.000s
sys     0m0.100s
```

With our tests done, let's dismount the volume, and delete it:


And then delete the volume:

```bash
cd  /
umount /mnt/nova-test
rbd unmap nova-test --pool nova
rbd --pool nova remove nova-test

Removing image: 100% complete...done.
```

Then, we proceed to create the remaining pools. Those will be used in our OpenStack deployment:

ceph osd pool create volumes 64 64 replicated
ceph osd pool create images 64 64 replicated
ceph osd pool create backups 64 64 replicated
ceph osd pool create vms 64 64 replicated

This conclude are first part !. The CEPH Cluster Creation.

We will use those pools the following way:

* "images" pool: For Glance Images Storage Backend.
* "volumes" pool: For a Cinder Storage Backend.
* "backups" pool: For Cinder Backups Storage Backend.
* "vms" pool: For Nova/Libvirt instance ephemeral storage backend.


### Extra notes for production CEPH Clusters.

* If possible, separate your public network from your cluster network. Use the public network for your client-server connections, and your cluster network for inter-node operations (like OSD replication and heartbeat). More information here: [CEPH Network Configuration Reference.](http://docs.ceph.com/docs/jewel/rados/configuration/network-config-ref/)
* For maximun troughput, in your OSD's, DO NOT set your journal in the same disk or partition of your data disk. This decreases performance. Use a separate disk for the Journal, and if possible, a ssd disk. More information at: [OSD Deploy documentation.](http://docs.ceph.com/docs/jewel/rados/deployment/ceph-deploy-osd/)
* Like any other network-based file-service solution, CEPH can be affected by lack of bandwidth. Depending of your load, you'll need ethernet interfaces from 1G to 10G. Take this into account and monitor your CEPH nodes network utilization closely in order to identify network bottlenecks.

END.-
