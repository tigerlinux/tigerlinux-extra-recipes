# LAB: AN OPENSTACK MITAKA CLOUD WITH CEPH RADOS STORAGE BACKEND USING UBUNTU 14.04LTS - PART 2: OPENSTACK MITAKA CONFIGURATION FOR CEPH USAGE.

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

We are dividing this recipe in two parts. The first part will create the CEPH cluster, and the second part (this document) will modify the OpenStack server in order to use CEPH.


### Basic server setup:

**NOTE:** Prior to OpenStack installation, we upgraded our OpenStack MITAKA server kernel to 4.2:

```bash
apt-get install --install-recommends linux-generic-lts-wily
reboot
```

With OpenStack installed, we proceed to create the ceph-deploy account on it:

```bash
useradd -c "Ceph Deploy User" -m -d /home/ceph-deploy -s /bin/bash ceph-deploy
echo "ceph-deploy:P@ssw0rd"|chpasswd
```

And give the account proper sudo permissions:

```bash
echo "ceph-deploy ALL = (ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-deploy
sudo chmod 0440 /etc/sudoers.d/ceph-deploy
```

In the ceph-deploy node (172.16.11.62), we proceed to enter to the ceph-deploy account and the ceph-cluster dir:

```bash
su - ceph-deploy
cd ~/ceph-cluster/
```

Then, copy the ssh-key to the openstack server:

```bash
ssh-copy-id 172.16.11.179
```

And, install the ceph dependencies from the ceph-deploy machine to the openstack one:

```bash
ceph-deploy install 172.16.11.179
ceph-deploy admin 172.16.11.179
ssh 172.16.11.179 "sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
ssh 172.16.11.179 "sudo apt-get -y install ceph-common python-ceph"
```

Still in the ceph-deploy account, we proceed to create the accounts for the OpenStack modules:

Cinder and Nova:

```bash
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
```

Result:

```bash
[client.cinder]
        key = AQCwwllXmGcXOxAAP+XVZk+tzmZz7WXIOMKCZw==

```

Glance:

```bash
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
```

Result:

```bash
[client.glance]
        key = AQDhq1lX1FjTBxAA/2eCFPg0TnkiL5ZFoTDYug==
```

Cinder-Backups:

```bash
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'
```

Result:

```bash
[client.cinder-backup]
        key = AQAdrFlXaXdnNxAA5N/ZBUnE+/3sZIhThKrPIA==
```

After the keys are created for cinder, cinder-backup and glance, we proceed to deploy them from the "ceph-deploy" node to the "openstack" server:

```bash
ceph auth get-or-create client.glance | ssh 172.16.11.179 "sudo tee /etc/ceph/ceph.client.glance.keyring"
ssh 172.16.11.179 "sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring"

ceph auth get-or-create client.cinder | ssh 172.16.11.179 "sudo tee /etc/ceph/ceph.client.cinder.keyring"
ssh 172.16.11.179 "sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring"

ceph auth get-or-create client.cinder-backup | ssh 172.16.11.179 "sudo tee /etc/ceph/ceph.client.cinder-backup.keyring"
ssh 172.16.11.179 "sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring"
```

```bash
ceph auth get-key client.cinder | ssh 172.16.11.179 "sudo tee /tmp/client.cinder.key"
```

In the openstack server (172.16.11.179) we proceed to run the following commands:

```bash
cd /tmp
uuidgen
```

The "uuidgen" command exit give us the following UUID (of course, this will be different for you):

```bash
21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a
```

With this uuid, we proceed to run the following commands (in the openstack server):

```bash
cd /tmp
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF

virsh secret-define --file secret.xml
```

The last command (virsh secret define) output (for this lab) was:

```bash
Secret 21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a created
```

The secret ID is the same as our UUID. Then, we proceed to activate this secret in libvirt and erase the temporal files:

```bash
cd /tmp
virsh secret-set-value --secret 21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a --base64 $(cat client.cinder.key)
rm -f secret.xml client.cinder.key
```

**NOTE:** If your production setup contains multiple compute nodes, try to use the same UUID for all of them.

Now, we can proceed to configure each OpenStack component, one by one.


### Glance Configuration:

In the openstack server, using crudini based tools, we proceed to reconfigure glance:

```bash
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.PRE-RBD
crudini --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
crudini --set /etc/glance/glance-api.conf glance_store default_store rbd
crudini --set /etc/glance/glance-api.conf glance_store stores "rbd,http"
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
```

**NOTE:** CEPH Documentation recommends that the following properties must be set on any glance image to be used with CEPH:

* hw_scsi_model=virtio-scsi
* hw_disk_bus=scsi
* hw_qemu_guest_agent=yes
* os_require_quiesce=yes

But, we found that the property "hw_disk_bus=scsi" is best to be set as "hw_disk_bus=virtio". We'll explain this later.

Finally, we restart glance:

```bash
openstack-control.sh restart glance
```

NOTE: The "openstack-control.sh" script is part of the ["TigerLinux OpenStack MITAKA Unattended-Automated tool for Ubuntu 14.04lts"](https://github.com/tigerlinux/openstack-mitaka-installer-ubuntu1404lts) we used in order to get our OpenStack Mitaka up and running !.


### Cinder Configuration:

Our OpenStack installation already have a LVM backend (enabled_backends=lvm). We are going to add an additional backend, named "rbd".

By using crudini, we proceed to re-configure cinder:

```bash
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.PRE-RBD
crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends "lvm,rbd"
crudini --set /etc/cinder/cinder.conf rbd volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set /etc/cinder/cinder.conf rbd rbd_pool volumes
crudini --set /etc/cinder/cinder.conf rbd rbd_ceph_conf "/etc/ceph/ceph.conf"
crudini --set /etc/cinder/cinder.conf rbd rbd_flatten_volume_from_snapshot false
crudini --set /etc/cinder/cinder.conf rbd rbd_max_clone_depth 5
crudini --set /etc/cinder/cinder.conf rbd rbd_store_chunk_size 4
crudini --set /etc/cinder/cinder.conf rbd rados_connect_timeout -1
crudini --set /etc/cinder/cinder.conf rbd glance_api_version 2
crudini --set /etc/cinder/cinder.conf rbd rbd_user cinder
crudini --set /etc/cinder/cinder.conf rbd rbd_secret_uuid 21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a
crudini --set /etc/cinder/cinder.conf rbd volume_backend_name CEPH_RBD
```

Restart cinder:

```bash
openstack-control.sh restart cinder
```

And create the volume type:

```bash
source /root/keystonerc_fulladmin
openstack volume type create --property volume_backend_name=CEPH_RBD --description "CEPH RBD Backend" rbd
```

Result:

```
+---------------------------------+--------------------------------------+
| Field                           | Value                                |
+---------------------------------+--------------------------------------+
| description                     | CEPH RBD Backend                     |
| id                              | 8878c924-61c8-419d-8e0b-941f66635cbc |
| is_public                       | True                                 |
| name                            | rbd                                  |
| os-volume-type-access:is_public | True                                 |
| properties                      | volume_backend_name='CEPH_RBD'       |
+---------------------------------+--------------------------------------+
```

That way, you'll have both the LVM and the RBD backends. This is very common. Normally, our automated openstack installer at github allows you to select and automate the configuration of 3 different backends: nfs, gluster and lvm. In production environments is very common to have many different cinder-volume backends for many different storage solutions. That's very "101" in OpenStack deployments.


### Cinder Backups.

First, we need to enable cinder backups in horizon:

Edit the file:

```
vi /etc/openstack-dashboard/local_settings.py
```

Search for the section "OPENSTACK_CINDER_FEATURES" and set "true" to "enable_backup" key:

```python
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': True,
}
```

Save the file, and restart apache:

```
/etc/init.d/apache2 restart
```

Next, by using crudini, modify cinder to enable backups using ceph backed storage:

```bash
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.PRE-RBD-BACKUPS
crudini --set /etc/cinder/cinder.conf DEFAULT backup_driver cinder.backup.drivers.ceph
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_conf "/etc/ceph/ceph.conf"
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_user cinder-backup
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_chunk_size 134217728
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_pool backups
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_unit 0
crudini --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_count 0
crudini --set /etc/cinder/cinder.conf DEFAULT restore_discard_excess_bytes true
```

Install the package:

aptitude install cinder-backup

We need to include cinder-backups in our installer control script (openstack-control.sh):

```
vi /usr/local/bin/openstack-control.sh
```

```bash
# Cinder. Index=3
svccinder=(
"
cinder-api
cinder-scheduler
cinder-volume
cinder-backup
"
)
```

After saving the file with the modifications, we proceed to restart cinder:

```
openstack-control.sh restart cinder
```

### Nova and Libvirt

In the openstack server, edit the `/etc/ceph/ceph.conf` file:

```bash
vi /etc/ceph/ceph.conf
```

And add the following lines:

```bash
[client]
    rbd cache = true
    rbd cache writethrough until flush = true
    admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok
    log file = /var/log/qemu/qemu-guest-$pid.log
    rbd concurrent management ops = 20
[mon]
        mon host = vm-172-16-11-62,vm-172-16-11-63,vm-172-16-11-64
        mon addr = 172.16.11.62:6789,172.16.11.63:6789,172.16.11.64:6789
```

Create the following directories and set their permissions:

```bash
mkdir -p /var/run/ceph/guests/ /var/log/qemu/
chown libvirt-qemu:kvm /var/run/ceph/guests /var/log/qemu/
```

**NOTE:** Those permissions vary from distro to distro. We are using current libvirt packages at ubuntu-cloud-archive.

By using "crudini", we proceed to reconfigure nova:

```bash
cp /etc/nova/nova.conf /etc/nova/nova.conf.PRE-RBD
crudini --set /etc/nova/nova.conf libvirt images_type rbd
crudini --set /etc/nova/nova.conf libvirt images_rbd_pool vms
crudini --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf "/etc/ceph/ceph.conf"
crudini --set /etc/nova/nova.conf libvirt rbd_user cinder
crudini --set /etc/nova/nova.conf libvirt rbd_secret_uuid "21c6ed7f-dbc8-43cb-bc30-c28c4a6c481a"
crudini --set /etc/nova/nova.conf libvirt disk_cachemodes "network=writeback"
crudini --set /etc/nova/nova.conf libvirt inject_password false
crudini --set /etc/nova/nova.conf libvirt inject_key false
crudini --set /etc/nova/nova.conf libvirt inject_partition "-2"
crudini --set /etc/nova/nova.conf libvirt hw_disk_discard unmap
```

And, restart nova services:

```bash
openstack-control.sh restart nova
```

### Testing - Cinder:

First test, let's create a volume, type "rbd":

```bash
source /root/keystonerc_fulladmin

openstack volume create --type rbd --size 1 mycephvol

+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2016-06-09T19:50:51.101670           |
| description         | None                                 |
| encrypted           | False                                |
| id                  | 40e85181-d4d9-4b58-adfe-d6f785c2825f |
| migration_status    | None                                 |
| multiattach         | False                                |
| name                | mycephvol                            |
| properties          |                                      |
| replication_status  | disabled                             |
| size                | 1                                    |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | rbd                                  |
| updated_at          | None                                 |
| user_id             | 30299fb37bef4bfe87b65a22ba61bfd2     |
+---------------------+--------------------------------------+
```

We can check directly in RBD:

```bash
root@vm-172-16-11-179:/# rbd --pool volumes ls
volume-40e85181-d4d9-4b58-adfe-d6f785c2825f
root@vm-172-16-11-179:/# rbd --pool volumes du
warning: fast-diff map is not enabled for volume-40e85181-d4d9-4b58-adfe-d6f785c2825f. operation may be slow.
NAME                                        PROVISIONED USED 
volume-40e85181-d4d9-4b58-adfe-d6f785c2825f       1024M    0 
root@vm-172-16-11-179:/# 
```

Then delete the volume and check in rbd:

```bash
[root@vm-172-16-11-179 ~(keystone_fulladmin)]$ openstack volume delete mycephvol
[root@vm-172-16-11-179 ~(keystone_fulladmin)]$ rbd --pool volumes ls
[root@vm-172-16-11-179 ~(keystone_fulladmin)]$ rbd --pool volumes du
NAME PROVISIONED USED 
[root@vm-172-16-11-179 ~(keystone_fulladmin)]$ 
```

### Testing - Glance.

With glance, we are going to create an image using opentack client:

First, we "cd" to the openstack installer directory, where we'll find "cirros" images:

```bash
cd /usr/local/openstack/openstack-mitaka-installer-ubuntu1404lts/
```

**NOTE:** The installer already add the cirros images, in qcow format, but, rbd requires the images in raw format, so we'll transform them first:

```bash
qemu-img convert -f qcow2 -O raw \
/usr/local/openstack/openstack-mitaka-installer-ubuntu1404lts/libs/cirros/cirros-0.3.4-i386-disk.img \
/tmp/cirros-0.3.4-i386-disk.raw
```

Then, add to openstack:


```bash
source /root/keystonerc_fulladmin

openstack image create "Cirros 0.3.4 32 bits RBD Based" \
--disk-format raw \
--public \
--container-format bare \
--project admin \
--protected \
--file /tmp/cirros-0.3.4-i386-disk.raw \
--property hw_scsi_model=virtio-scsi \
--property hw_disk_bus=scsi \
--property hw_qemu_guest_agent=yes \
--property os_require_quiesce=yes
```

Did you noticed the properties ?. Those are "highly recommended" for images that will produce rbd-backend instances !. Don't forget to add them. You can do it at creation time, or later in the horizon dashboard, in the "image metadata" section for each image. Also, remember to use raw images instead qcow !.

**VERY IMPORTANT NOTE - READ THIS OR YOU WILL BE UNABLE TO BOOT-FROM-CINDER:** Those properties will make imposible to boot from a cinder backed volume, but, it does not affect at all attaching a rbd backend volume to an existing instance as an extra disk. Change "--property hw_disk_bus=scsi" to "--property hw_disk_bus=virtio" in order to let the image to work properly in all conditions. If you want to play safe, forget the [CEPH recomendation ](http://docs.ceph.com/docs/master/rbd/rbd-openstack/) about "--property hw_disk_bus=scsi" and ALWAYS set **"--property hw_disk_bus=virtio"**. 

Another thing you need to consider, is booting from the right cinder backend when you have multiple cinder backends (this LAB in fact have rbd and lvm configured). You can force (again, using properties) a image to boot on a specific cinder backend when using the default launch panel in horizon.

Just go to your image in Horizon, select your image, edit the "metadata" and search for "volume type", then set it to the desired backend name (rbd for this LAB). If set trough "property", use:

```bash
--cinder_img_volume_type=rbd
```

That last sample will force your image to use the "rbd" backend when you use the standar launch instance panel in horizon.

We can check our images in glance:

```bash
source /root/keystonerc_fulladmin

openstack image list
+--------------------------------------+--------------------------------+--------+
| ID                                   | Name                           | Status |
+--------------------------------------+--------------------------------+--------+
| 9265188c-9e7c-4c23-981d-0ff4c63e6d7a | Cirros 0.3.4 32 bits RBD Based | active |
| aa8d23a3-eaff-4d25-8791-ba972ffb7e01 | Cirros 0.3.4 64 bits           | active |
| 9122b7fb-68f6-42b3-83e6-114b6c5b41c9 | Cirros 0.3.4 32 bits           | active |
+--------------------------------------+--------------------------------+--------+
```

And also in RBD:

```bash
[root@vm-172-16-11-179 openstack-mitaka-installer-ubuntu1404lts(keystone_fulladmin)]$ rbd --pool images ls
9265188c-9e7c-4c23-981d-0ff4c63e6d7a
[root@vm-172-16-11-179 openstack-mitaka-installer-ubuntu1404lts(keystone_fulladmin)]$ rbd --pool images du
warning: fast-diff map is not enabled for 9265188c-9e7c-4c23-981d-0ff4c63e6d7a. operation may be slow.
NAME                                      PROVISIONED   USED 
9265188c-9e7c-4c23-981d-0ff4c63e6d7a@snap      40162k 40162k 
9265188c-9e7c-4c23-981d-0ff4c63e6d7a           40162k      0 
<TOTAL>                                        40162k 40162k 
[root@vm-172-16-11-179 openstack-mitaka-installer-ubuntu1404lts(keystone_fulladmin)]$ 
```

### Testing - Nova

Now, our more important test: Let's boot an instance:

```bash
source /root/keystonerc_fulladmin

openstack server create \
--image 9265188c-9e7c-4c23-981d-0ff4c63e6d7a \
--flavor m1.small \
--key-name openstack-server-01 \
--security-group 22d1492a-88d1-4ce6-822d-c1ad24c21faa \
--nic net-id=1369069c-862b-48f8-8f31-e8e5a14b95a0 \
cirros-rbd-test

+--------------------------------------+-----------------------------------------------------------------------+
| Field                                | Value                                                                 |
+--------------------------------------+-----------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                |
| OS-EXT-AZ:availability_zone          |                                                                       |
| OS-EXT-SRV-ATTR:host                 | None                                                                  |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | None                                                                  |
| OS-EXT-SRV-ATTR:instance_name        | instance-00000002                                                     |
| OS-EXT-STS:power_state               | 0                                                                     |
| OS-EXT-STS:task_state                | scheduling                                                            |
| OS-EXT-STS:vm_state                  | building                                                              |
| OS-SRV-USG:launched_at               | None                                                                  |
| OS-SRV-USG:terminated_at             | None                                                                  |
| accessIPv4                           |                                                                       |
| accessIPv6                           |                                                                       |
| addresses                            |                                                                       |
| adminPass                            | 4AGYopj3ZNun                                                          |
| config_drive                         |                                                                       |
| created                              | 2016-06-09T20:41:22Z                                                  |
| flavor                               | m1.small (1227addb-e0f1-4282-ab9a-b23dc993d438)                       |
| hostId                               |                                                                       |
| id                                   | aa1a1b6f-7498-4861-a44b-85c88c0975a7                                  |
| image                                | Cirros 0.3.4 32 bits RBD Based (9265188c-9e7c-4c23-981d-0ff4c63e6d7a) |
| key_name                             | openstack-server-01                                                   |
| name                                 | cirros-rbd-test                                                       |
| os-extended-volumes:volumes_attached | []                                                                    |
| progress                             | 0                                                                     |
| project_id                           | 04f8c86eb3a84d398a0d225d0a93564e                                      |
| properties                           |                                                                       |
| security_groups                      | [{u'name': u'22d1492a-88d1-4ce6-822d-c1ad24c21faa'}]                  |
| status                               | BUILD                                                                 |
| updated                              | 2016-06-09T20:41:22Z                                                  |
| user_id                              | 30299fb37bef4bfe87b65a22ba61bfd2                                      |
+--------------------------------------+-----------------------------------------------------------------------+
```

Eventually, we can see the instance fully active:

```bash
openstack server list

+--------------------------------------+-----------------+--------+-----------------------+
| ID                                   | Name            | Status | Networks              |
+--------------------------------------+-----------------+--------+-----------------------+
| aa1a1b6f-7498-4861-a44b-85c88c0975a7 | cirros-rbd-test | ACTIVE | internal=192.168.34.5 |
+--------------------------------------+-----------------+--------+-----------------------+
```

Again, we proceed to check the rbd pool:

```bash
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ rbd --pool vms ls
aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk
aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk.swap
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ rbd --pool vms du
warning: fast-diff map is not enabled for aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk. operation may be slow.
warning: fast-diff map is not enabled for aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk.swap. operation may be slow.
NAME                                           PROVISIONED  USED 
aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk           40162k     0 
aa1a1b6f-7498-4861-a44b-85c88c0975a7_disk.swap       2048M 4096k 
<TOTAL>                                              2087M 4096k 
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ 
```

All ephemeral space will be located in the CEPH cluster. Even the swap is there !.

We proceed to delete our instance:

```bash
openstack server delete aa1a1b6f-7498-4861-a44b-85c88c0975a7
```

And check again the rbd pool:

```bash
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ rbd --pool vms ls
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ rbd --pool vms du
NAME PROVISIONED USED 
[root@vm-172-16-11-179 nova(keystone_fulladmin)]$ 
```

This finish our LAB. All storage components used by OpenStack are "RBD" backed !.


### CEPH and OPENSTACK recommendations

* If possible, separate your public network from your cluster network. Use the public network for your client-server connections, and your cluster network for inter-node operations (like OSD replication and heartbeat). More information here: [CEPH Network Configuration Reference.](http://docs.ceph.com/docs/jewel/rados/configuration/network-config-ref/)
* For maximun troughput, in your OSD's, DO NOT set your journal in the same disk or partition of your data disk. This decreases performance. Use a separate disk for the Journal, and if possible, a ssd disk. More information at: [OSD Deploy documentation.](http://docs.ceph.com/docs/jewel/rados/deployment/ceph-deploy-osd/)
* Like any other network-based file-service solution, CEPH can be affected by lack of bandwidth. Depending of your load, you'll need ethernet interfaces from 1G to 10G. Take this into account and monitor your CEPH nodes network utilization closely in order to identify network bottlenecks.
*  In OpenStack, don't mix all your traffic in a single nic. That will completelly destroy your performance. In the same way you should have a separated traffic network for "ceph-public" and "ceph-cluster", set your openstack production deployment with "at least" 3 networks if you want to use ceph: An admin and inter-openstack communication network, a "external-instance-communication" network (for your intances external and-or-vlan's based networks), and a "network storage" network which you will use to communicate your openstack nodes with ceph cluster "public network".
* If you follow the former networking advice, try to set your "openstack storage network" in the same IP space as "ceph public network" in order to avoid passing trough a router. Again, think on terms of performance and avoid common networking bottlenecks.
* Consider network bonding for your primary traffic !. Also, and depending of your switches, you can aggregate traffic in multiple nic's.
* Think on giga and ten-giga (10G) interfaces for your storage network. Everything related to CEPH must avoid network bottlenecks, both in OpenStack and in the CEPH Cluster.
* Monitor everything: With OpenSource solutions like mrtg, rddtool, icinga, cacti, zabbix, etc., there is NO POSSIBLE EXCUSE for you or your team about the proper monitoring of your production environment. The first way to correct a bottleneck is to identify it's presence, and this is where proper monitoring of your production infrastructure becomes vital and mandatory !.

END.-
