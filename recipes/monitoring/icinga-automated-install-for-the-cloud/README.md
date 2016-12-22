# AN ICINGA AUTOMATED INSTALL WITH DOCKERIZED DATABASE BACKEND AND CLOUD BACKUPS

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

Icinga is another interesting monitoring application, and it's very very easy to deploy. In it's most simple way, we can just check availability of servers and services for most common OpenSource applications in the Internet. Of course, it's also a good choice for a simple monitoring solution in the cloud.

The recipe presented here is not only an automated way to install icinga.. also it contain many other technologies and sysadmin technics, ranging from many "file manipulation" ways, to dockerization of the Icinga database backend, puppet-control for files and crontabs, and system backups sent to a OpenStack-based Cloud Object Storage service.

The recipe has two versions: One version for manual running (with a lot of comments inside the script), and one "comment-stripped" version, designed to be passed as user-data in a cloudformation deployment.

In conclusión, this recipe uses the following sysadmin topics:

* General bash scripting.
* File contents manipulation.
* Database services dockerization.
* Puppet automation.
* Backup's automation (database and logs) and sending of those backups to a cloud storage (OpenStack SWIFT Object Storage).


## What kind of hardware and software you need ?.

This is fully designed for the cloud (specially OpenStack, but also can be adapted to be run in AWS). The script (cloud version) included in this recipe is designed to be passed as "user data" (Metadata services) either on OpenStack or any other cloud using metadata bootstraping services (think AWS and the like).

About the software: You'll need a machine with the following software requeriments. Again, either a virtual cloud instance, or, a bare metal machine if you want to test in a non-cloud environment:

* Centos 7 fully updated.
* EPEL Repository installed. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL.
* SELINUX Disabled.
* FirewallD Disabled.


## What knowledge should you need to have at hand ?:

* General Linux administration.
* Monitoring concepts - specially with Icinga.
* Docker concepts.
* Puppet concepts.

## What files you'll find here ?:

* [RECIPE-icinga-automated-cloud-install.md: Our recipe, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/monitoring/icinga-automated-install-for-the-cloud/RECIPE-icinga-automated-cloud-install.md "Icinga Automated Install for the Cloud")
* [scripts: Scripts referenced/created for this recipe.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/monitoring/icinga-automated-install-for-the-cloud/scripts "Icinga Automated Install Scripts")

