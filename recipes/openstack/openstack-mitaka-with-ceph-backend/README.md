# OPENSTACK MITAKA WITH CEPH-RBD STORAGE BACKEND

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

With no possible doubt at all, ["CEPH"](http://ceph.com/) is by far the best storage option for OpenStack based deployments, providing high availability, true live migration, and the best performance in comparison with other network based solutions.

With CEPH, you can give storage services to many openstack components, including:

* Glance: base images can be stored in a ceph rbd pool.
* Cinder Volumes: Cinder can use ceph rbd as a storage backend.
* Cinder Backups: All volume backups can be stored in a ceph rbd pool.
* Nova/libvirt: The instances ephemeral spaces (root, extra disk and swap) can be stored in a ceph rbd pool. This also allow true live migration among compute nodes.
* Swift: There is a project in the openstack community to allow swift to use ceph as storage backend instead of local disks (this is still work-in-progress).

Our recipe will touch the glance, cinder and nova/libvirt implementations.


## About our LAB environment:

Ubuntu 16.04 is out with the lattest ceph stable version (jewel), but, we still recommend to stick with Ubuntu 14.04 as 16.04 is still very new and there are some remaining issues with the ceph packages (something with their systemd implementation is not working properly yet).

The ceph packages will be obtained from the ceph repos for ubuntu trusty, lattest stable ceph version (Jewel). The OpenStack installation will use MITAKA from our own automated installers at github for ubuntu 14.04lts.

Why ubuntu and not centos ?. Of course you can use centos. We just sticking with the most widely used distro for OpenStack installations in the world !.

In our LAB environent we are using four machines (all virtual):

* CEPH Cluster: 3 vm's, each with 4 vcpus, 4GB ram, one HD for the operating system, and one HD dedicated to ceph storage, one nic.
* OpenStack Server: 1 vm with 8 vcpus, 16GB ram, one HD, one nic.

Note that the disk and network configuration is not ideal and definitively not suited for production enviroments. This is a "proof-of-concept" LAB. In the recipes, you'll find specific notes about what extra items you need to include for a real-world production environment. In any case, the configuration principle, is basically the same !.


## What recipes you'll find here ?:

In order to make the lecture more easy to understand, we devided the whole thing in two recipes: The first will guide you trough the ceph cluster configuration stages, and the second trough the openstack configuration with ceph.

* [RECIPE: CEPH Cluster Creation on Ubuntu 14.04lts, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/openstack-mitaka-with-ceph-backend/RECIPE-LAB-Ceph-Rados-Mitaka-PART1.md "CEPH Cluster in Ubuntu 14.04lts")
* [RECIPE: OpenStack MITAKA Re-configuration with CEPH, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/openstack-mitaka-with-ceph-backend/RECIPE-LAB-Ceph-Rados-Mitaka-PART2.md "OpenStack MITAKA With CEPH")

