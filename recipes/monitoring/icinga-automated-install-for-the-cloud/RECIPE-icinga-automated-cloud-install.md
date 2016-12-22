# AN ICINGA AUTOMATED INSTALL WITH DOCKERIZED DATABASE BACKEND AND CLOUD BACKUPS

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

Build a fully automated script which will install icinga with it's dependencies and will configure the following items:

* Dockerized, fully systemd-automated database service.
* All icinga configuration files worked on "automated way" without carbon-unit (aka:human) intervention. Show several ways to "skin the cat" (manipulate the file contents).
* Icinga databases created, and populated.
* Puppet-based crontab (and support scripts) creation.
* Optional backups to an OpenStack-SWIFT Cloud Storage (Object Storage).


## Where are we going to install it ?:

This recipe was designed to be run in a cloud environment (OpenStack or AWS instance), but, you can use any server you want, provided the followings conditions are met:

* Centos 7 fully updated.
* EPEL Repository installed. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL.
* SELINUX Disabled.
* FirewallD Disabled.


If you are using AWS of OpenStack based instances, try to use an Image (AMI or Glance-Image) that follows above requirements, or, construct your own image and register it with the cloud environment (AWS-AMI or OpenStack Glance Image).


## How we constructed the whole thing ?:

This solution contains two scripts:

* [Cloud-ready Icinga Installation Script.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/monitoring/icinga-automated-install-for-the-cloud/scripts/icinga-automated-install-cloud.sh "Icinga Automated Install Script - Cloud Version")
* [Very Commented Icinga Installation Script.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/monitoring/icinga-automated-install-for-the-cloud/scripts/icinga-automated-install-with-comments.sh "Icinga Automated Install Script - Commented Version")

The one you want to se in order to check what it does and how it does, is the **"Commented"** version. This version has several comments on each part, so it can be used for learning. You can also run it manually inside your server, and it will do everything to get the icinga ready for the wizard-install part.

The one you want to use inside a cloud environment is the **"Cloud-Ready"** version. Why this version is the one to use in a cloud ?.. because the size. For use this script inside a Cloud Environment (specially OpenStack), the script should be no more than 16Kb in size. So, all comments are basically stripped out of the script in order to be passed as "user data" in any metadata-based cloud platform (like AWS and OpenStack).

The tasks performed by the script are very documented inside the "Very Commented" version, so instead of explaining here what the scripts does, I'll let you see the script and understand how things are done.


## How the script must be used ?:

First, ensure the machine requeriments are met as documented here:

* Centos 7 fully updated.
* EPEL Repository installed. For EPEL install instruction see: [https://fedoraproject.org/wiki/EPEL.](https://fedoraproject.org/wiki/EPEL)
* SELINUX Disabled.
* FirewallD Disabled.

Second, modify the variables at the start of the script:

```bash
icingadbpass="P@ssw0rd"
icingadbbackup="P@ssw0rd"
mysqlrootpass="P@ssw0rd"
phptimezone="America/Caracas"
osprjname="ec2testing"
osusrname="ec2testing"
ospassword="ec2testing"
osdomain="default"
osendpoint="http://192.168.1.4:35357/v3"
cloudcontainer="special-app"
backuptstoswift="no"
```

What does those variables mean ??. Explanations follow:

* icingadbpass: This is the Icinga DB Password. Set to something very cryptic in production environments. The databases will run inside a docker container exposing the MariaDB port 3306 only to localhost (127.0.0.1) but, a good password is always a good idea.
* icingadbbackup: For our backup system, we are creating a "SELECT ONLY" account. This is it's password.
* mysqlrootpass: This is the mysql root account password. Again, a good/strong password is a good idea here.
* phptimezone: This is the "php.ini" timezone. Because I'm in Caracas, Venezuela, I set my default to "America/Caracas". Adjust this variable accordingly.
* osprjname: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack project/tenant name.
* osusrname: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack user name.
* ospassword: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack user password.
* osdomain: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack domain.
* osendpoint: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack HTTP/HTTPS Keystone Endpoint.
* cloudcontainer: If you plan to use the Object Storage Based Backups, then set this variable to your OpenStack SWIFT Container. The container MUST BE already created.
* backuptstoswift: Set this to YES if you want to include Backups to the Cloud.

**NOTES:**

* This script was designed to use an OpenStack Cloud with V3 authentication, mean, Liberty or newer. If you use my OpenStack Automated Installers ([published on Github](https://github.com/tigerlinux)), my "liberty" (and newer) versions already use/setup Keystone AUTH V3. If you use an OpenStack cloud without V3, you must modify the script accordingly.
* It's very very easy to adapt this to AWS. Just need to change the secuence which copies the backup files to the cloud storage, and "pip install" aws client instead of openstack client. Also, you don't need to include cloud authentication data inside the virtual machine if you use AWS. AWS can assign "roles" (RBAC) at instance level for Read-Write operations to AWS Object Storage Buckets.

After modifying those variables, you are set !. Just run the script (if you are running it manually inside the server) or pass it as "user-data" (bootstrap) to you cloud instance and go for a coffe !.

After the script is donde, you will have an almost-ready icinga installation. You only need to complete the wizard by entering with any browser to the icinga machine. You'll need some extra data to complete the wizard:

* Icinga WEB Database: **icinga2web**, user: **icinga2web**, password: The one to set on **"icingadbpass"** variable.
* Icinga IDO Database: **icinga2**, user: **icinga2**, password: The one to set on **"icingadbpass"** variable.
* Icinga Install Token: Generated by the script and save it inside the server in the following file: **/root/icinga-token.txt**.

Note that this script is the base of a "Cloudformation" approach. You can adapt it to an OpenStack-Heat or AWS-Cloudformation environment, as it will run completelly unattended.

Enjoy !!!

END.-

