# A ZABBIX 3 H.A. CLUSTER IN CENTOS 7

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

Zabbix (http://www.zabbix.com) is one of the best OpenSource monitoring solutions for corporative environments, and is also very easy to implement in a private cloud. In my last 7 years I have been implementing this software after being working with other similar solutions (cacti, plain-old mrtg, etc.) for the pervious 10 years and more recently a workmate and me migrated from a single-central (virtual) zabbix 2.2 server to a more robust, higly available, zabbix 3 solution. This solution is what I'm going to document in this recipe.

This solution is based on one of my former recipes in this site (MariaDB 10.1 cluster, with 3 nodes, are deployed on our OpenStack-based private cloud), and with an active/pasive Zabbix 3 cluster using pacemaker/corosync on Centos 7 (very similar to my former PostgreSQL H.A. DRBD recipe, also on this site).


## What kind of hardware and software you need ?.

First the database cluster: Our solution uses MariaDB 10.1 backend, load-balanced with OpenStack LBaaS (single VIP). This MariaDB Cluster is based on 3 nodes (magic number), multi-master, asynchronous model. The recipe used is in this site, and referenced by the following link:

* https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/databases/mariadb-cluster-centos7/RECIPE-Cluster-MariaDB-10.1-C7.md

The Zabbix Service is based on two Centos 7 O/S servers (EPEL Installed, SELINUX/FirewallD disabled), in an active/pasive model using Pacemaker/Corosync. The VIP is floating (declared as address-pair in OpenStack) an configured as a corosync/pacemaker resource. The Zabbix and httpd services are also managed by pacemaker/corosync.

About the software: You'll need a machine with the following software requeriments:

* Centos 7 fully updated.
* EPEL Repository installed. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL.
* SELINUX Disabled.
* FirewallD Disabled.


## What knowledge should you need to have at hand ?:

* General Linux administration.
* Monitoring concepts - specially with Zabbix.
* Cluster concepts (pacemaker/corosync).
* Optional but recommended: Layer 4 Load Balancing concepts.


## What files you'll find here ?:

* [RECIPE-zabbix-ha-cluster-C7.md: Our recipe, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/monitoring/zabbix-3-ha-cluster/RECIPE-zabbix-ha-cluster-C7.md "Zabbix 3 H.A. Recipe")
* [scripts: Scripts referenced/created for this recipe.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/monitoring/zabbix-3-ha-cluster/scripts "Our Zabbix 3 Recipe Support Scripts")

