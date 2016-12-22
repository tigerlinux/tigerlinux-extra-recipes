# ENABLING "CINDER BACKUPS" IN OPENSTACK WITH SWIFT STORAGE BACKEND.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

Modify an already-installed OpenStack installation (Cinder and Swift fully working) in order to enable "Cinder Backups" with Swift Storage Backend. 


## Where are we going to do it ?:

OpenStack Cloud (Liberty over Centos 7). Cinder configured with multiple backends (LVM, NFS and GlusterFS), Swift installed and configured (Note that the same configuration applies for Kilo and Mitaka).

The platform was installed by using the openstack automated installer available at the following link:

* [TigerLinux OpenStack LIBERTY Automated Installer for Centos 7.](https://github.com/tigerlinux/openstack-liberty-installer-centos7)


## How we constructed the whole thing ?:

### Cinder Modifications:

Using "crudini", we proceed to modify "Cinder" in order to allow it to activate the backups option, and, use swift for the backups:

```
crudini --set /etc/cinder/cinder.conf DEFAULT backup_driver cinder.backup.drivers.swift
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_url http://192.168.1.4:8080/v1/AUTH_
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_auth per_user
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_auth_version 1
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_container volumebackups
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_object_size 52428800
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_retry_attempts 3
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_retry_backoff 2
crudini --set /etc/cinder/cinder.conf DEFAULT backup_compression_algorithm zlib
crudini --set /etc/cinder/cinder.conf DEFAULT backup_swift_enable_progress_timer true
```


### OpenStack-Control Script modifications:

In order to allow the "[TigerLinux OpenStack LIBERTY Automated Installer for Centos 7]"(https://github.com/tigerlinux/openstack-liberty-installer-centos7) control script to manage "cinder-backup" service, we need to modify the control script and include the service:

```
vi /usr/local/bin/openstack-control.sh
```

```bash
# Cinder. Index=3
svccinder=(
"
openstack-cinder-api
openstack-cinder-scheduler
openstack-cinder-volume
openstack-cinder-backup
"
)
```

After saving the file with the modifications, we proceed to restart cinder:

```
openstack-control.sh restart cinder
```


### Horizon Modifications:

By default, Horizon (the OpenStack Web Dashboard) disable the "Cinder Backups" functions. We need to re-enable cinder-backups from horizon: 

```
vi /etc/openstack-dashboard/local_settings
```

Search for the section "OPENSTACK_CINDER_FEATURES" and set "true" to "enable_backup" key:

```python
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': True,
}
```

Save the file, and restart apache:

```
systemctl restart httpd
```

We are set !. We enabled cinder backups !. You can do any backup for any cinder-backed volume, as long as you have free space in your Object Storage.

**NOTE:** You can use other Storage Solutions for Cinder-backups. See the following link for more information:

* [Cinder Backup Storage Drivers.](http://docs.openstack.org/mitaka/config-reference/block-storage/backup-drivers.html)

FIN.-

