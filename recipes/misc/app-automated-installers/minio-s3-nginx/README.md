# MINIO S3 AUTOMATED INSTALLATION SCRIPT

Supported Operating Systems: Centos 7, Ubuntu 16.04 lts (64 bits only)


## Scripts included on this directory:

- minio-s3-docker.sh: Minio S3 automated installer with docker and nginx. Minio will be dockerized and reacheable trough nginx.


## Usage:

Base requeriments:

- Distribution: Centos 7 64 bits or Ubuntu 16.04lts 64 bits.
- Minimun hardware: 1 cores/threads, 512MB RAM, 10GB Free for the "/usr" partition, and 10GB Free for the "/var" partition, or if a single partition for all (/) 10GB free total.
- The server must have internet access and at least one usable (static) IP Address.
- Optional: An extra volume for persistent storage.

Copy the script to any place inside the operating system, and run it as "root" (please don't use "sudo". Become root with "sudo su -" or enter ssh as root and run the script).
The script can also be used in any cloud supporting "user_data" or "bootstrap" scripts (AWS, OpenStack, Digital Ocean, etc.).


## FIREWALLD/UFW

Depenging on the distro (centos7 or ubuntu1604lts) firewalld/ufw will be installed and configured. The only ports to open will be:

- 22 tcp (ssh).
- 8080 and 8443 tcp (minio-http/minio-https).


## What the script does ?:

The script perform the following actions in the operating system:

- Verifies the base Operating System environment. If the O/S is unsupported by the script, it exits and show an error to the console indicating the unsupported platform.
- Download and install (yum/apt) some packages needed to properly run.
- Verifies the minimum hardware requirements, and if the machine does not meet the minimums, it exits indicating the hardware does not meet the minimum requirements for this nextcloud installation design.
- If the script find a free disk (an extra persistent, ephemeral or physical hard disk device), it assumes the user want it as storage for NextCloud. The script take all proper steps in order to fully format the drive and configure a mount point for it, on "/var/nextcloud-sto-data" (non minio-s3 version).
- Install and configures minio-s3 (docker based), and if a free disk (an extra persistent, ephemeral or physical hard disk device) is found, it configure the storage to be used by minio-s3 as persistent storage (mounted on "/var/minio-storage").
- It also installs and configures nginx as a front-end to minio on port 8080 (tcp) and 8443 (tcp-ssl/tls).
- Finally, all access data (and admin credentials) are stored on the file: /root/minios3-credentials.txt.

## Running time:

Depending on Internet access conditions, the script can take from 10 minutes to 20 minutes to complete.

Please note that this script will disable both firewalld and selinux on Centos 7 machines. If you want you can install them back after this script finish its run.


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7 or Ubuntu 16.04lts.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.


END.-
