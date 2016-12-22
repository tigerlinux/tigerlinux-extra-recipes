# A POSTGRESQL 9.5 CLUSTER WITH DRBD, PACEMAKER AND COROSYNC ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

This recipe, which I currently use in production environments with a lot of success, will allow you to create a **"highly available"** postgres-9.5 service with multi-database/multi-engine-instance capability over Centos 7 with the use of DRBD, Pacemaker and Corosync.

This recipe included script tools aimed to allow the best efficient administration way for specific database services, also allowing the DBA to perform it's task without needed root access to the server.

Automated tasks for backups, log cleaning and archive cleaning are also included here. Please take the time to read and understand the recipe before you launch yourself into running it.

## What kind of hardware and software you need ?.

If you plan to use this recipe for a LAB (testing), you just need two machines, normally virtual instances inside a cloud (aws, openstack, etc.) or two bare-metal servers. Event two virtualbox servers will work. Minimun ram: 4 GB's, 2 VPCU's, one disk for the operating system, and another for the Database Storage.

If you plan to go "production", think of more vcpu's and more ram (8 gb's a good start), two ethernets (one for database traffic, one for DRBD Storage inter-node traffic), and the same disk configuration (one disk or volume for the Operating System, and one separate disk or volume for the Database Storage).

About the OS: You need for this recipe CENTOS 7 Fully updated with EPEL repository installed, SELINUX disabled and FirewallD disabled.

## Why those OS requeriments ?:

* Centos 7: Is the base of our production recipe. Of course you can adapt this to other O/S as long as the components are available.
* EPEL: Some libs and packages are in this repo. Also, really... What is a Centos machine without EPEL ???. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL
* SELINUX: Disabled just to ensure it will not interfere with postgres and/or drbd. You can try to enable and adjust it after you have everything running.
* FIREWALLD: Because our LAB was conducted in a private cloud (OpenStack) environment, we prefer to use the "cloud" security groups instead the local firewall inside the servers. Of course, you can reenable firewall-d later and adjust it acordingly.

## What knowledge should you need to have at hand ?:

* General Linux administration.
* PostgreSQL administration.
* DRBD Concepts and administration.
* Optional: Cloud Computing (OpenStack, AWS) just if you are going to deploy this recipe in a cloud.

## What files you'll find here ?:

* [RECIPE-PostgreSQL-HA-DRBD-C7.md: Our recipe, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/databases/postgresql-cluster-drbd-centos7/RECIPE-PostgreSQL-HA-DRBD-C7.md "Our PostgreSQL HA-DRBD Recipe")
* [scripts: Directory with scripts referenced by our recipe.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/databases/postgresql-cluster-drbd-centos7/scripts "Our Recipe Support Scripts")

