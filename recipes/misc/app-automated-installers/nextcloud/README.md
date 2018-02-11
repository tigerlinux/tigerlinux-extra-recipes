# NEXTCLOUD INSTALLATION SCRIPTS (FOR BARE METAL OR AWS/OPENSTACK/CLOUD-INIT BASED CLOUDS)

Supported Operating Systems: Centos 7. Nextcloud release 11.


## Scripts included on this directory:

- nextcloud-XX-generic-storage-apache.sh: Nextcloud fully automated installer with standard storage (where XX is the nextcloud release) - apache version.
- nextcloud-XX-generic-storage-nginx.sh: Nextcloud fully automated installer with standard storage (where XX is the nextcloud release) - nginx version.
- nextcloud-XX-minios3-storage-apache.sh: Nextcloud fully automated installer with minio-s3 based storage (where XX is the nextcloud release).


## Usage:

Base requeriments:

- Distribution: Centos 7 64 bits.
- Minimun hardware: 1 cores/threads, 1024MB RAM, 10GB Free for the "/usr" partition, and 10GB Free for the "/var" partition, or if a single partition for all (/) 10GB free total.
- The server must have internet access and at least one usable (static) IP Address.
- Optional: An extra volume for persistent storage.

Copy the script to any place inside the operating system, and run it as "root" (please don't use "sudo". Become root with "sudo su -" or enter ssh as root and run the script).
The script can also be used in any cloud supporting "user_data" or "bootstrap" scripts (AWS, OpenStack, Digital Ocean, etc.).


## TCP ports exposed (FIREWALLD):

- SSH (22 tcp).
- Nextcloud will expose ports 80 tcp (http) and 443 tcp (https).
- Minio will expose port 8080 tcp trough nginx.


## What the script does ?:

The script perform the following actions in the operating system:

- Verifies the base Operating System environment. If the O/S is unsupported by the script, it exits and show an error to the console indicating the unsupported platform.
- Download and install (yum) some packages needed to properly run.
- Verifies the minimum hardware requirements, and if the machine does not meet the minimums, it exits indicating the hardware does not meet the minimum requirements for this nextcloud installation design.
- If the script find a free disk (an extra persistent, ephemeral or physical hard disk device), it assumes the user want it as storage for NextCloud. The script take all proper steps in order to fully format the drive and configure a mount point for it, on "/var/nextcloud-sto-data" (non minio-s3 version).
- For the "minio-s3" version, it install and configures minio-s3 (docker based), and if a free disk (an extra persistent, ephemeral or physical hard disk device) is found, it configure the storage to be used by minio-s3 as persistent storage (mounted on "/var/minio-storage").
- For the minio-s3 based version, it also installs and configures nginx as a front-end to minio on port 8080 (tcp).
- Configure MariaDB 10.1 repository for Centos7, and then installs and configure MariaDB 10.1 with a secure password also stored on the file "/root/.my.cnf" with unix mode "0600".
- Perform a full-update of the operating system with the new repos activated.
- Creates a database for nextcloud.
- Install and configures php 7.1 from webtactic repos.
- Also installs apache and redis (redis will be used for cache and file locking on nextcloud).
- Fully automates the nextcloud configuration, including admin user and its passwords.
- Fully include the "hostnames/IP's" in the nextcloud configuration. If the machine is a cloud machine (amazon, openstack or any other using standard metadata services), it try to configure the external IP and external hostname into the nextcloud configuration.
- For the minio-s3 based version, it reconfigures nextcloud to use the minio-s3 based storage.
- Finally, all access data (and admin credentials) are stored on the file: /root/nextcloud-credentials.txt.

## Running time:

Depending on Internet access conditions, the script can take from 10 minutes to 20 minutes to complete.

Please note that this script will disable selinux. 


## FirewallD service:

Firewall-d will be configured with the following ports opened:

- 22 tcp (ssh).
- 80 tcp (http).
- 443 tcp (https).
- 8080 tcp (minio http, only for the scripts using minio-s3).


## Apache vs Nginx:

We don't have a preference here, but in general terms Nginx is faster than apache. Having said that, you'll probably find the ones using nginx faster. Note that the minio-s3 based ones are "exotic" as they combine nginx as a front-end for minio-s3 (serving all storage contents that way) and apache is just used as the "nextcloud" engine frontend.


## Letsencrypt:

Our default installation creates a self-signed certificate for the https service. "Certbot" utility is included if you want to add a let's encrypt free certificate. The crontab for auto-renewal is also included as part of our solution.


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.


END.-
