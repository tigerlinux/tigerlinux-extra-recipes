# CINDER BACKUPS WITH SWIFT

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

As other cloud implementations on the OpenSource and non-OpenSource world, OpenStack provides both ["Block Storage"](https://en.wikipedia.org/wiki/Block-level_storage) and ["Object Storage"](https://en.wikipedia.org/wiki/Object_storage) solutions. For "Block Storage", Cinder is the OpenStack module providing all related operations, and Swift is the one that does the "Object Storage" part. Both are the fundamentals of the ["Cloud Storage"](https://en.wikipedia.org/wiki/Cloud_storage) OpenStack solution.

In any cloud implementation, while the block storage just provides "virtual hard disks" to the virtual machines ("instances" in Cloud Slang), the Object Storage can be used for aplications that range from simgle Static-Web-Elements storage and serving, to full backups for many elements in the Cloud. One of those elements which benefit from Swift, is the "Cloud Storage" virtual disks backup, AKA "Cinder-Backups".

Cinder as it comes, can perform "full backups" of any of it's managed volumes, and send that backup "as an Object" to other backends, including NFS, CEPH... and of course: Swift Object Storage.

This recipe just will show you what do you need to reconfigure in OpenStack in order to allow "Cinder Backups" to work !.


## What recipes you'll find here ?:

Just one and very simple recipe that will allow you to modify cinder and horizon in order to enable Cinder Backups with Swift Storage Backend.

* [RECIPE: Cinder Backups with SWIFT, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/cinder-backups-with-swift/RECIPE-cinder-backups-with-swift.md "OpenStack Cinder Backups with Swift")
