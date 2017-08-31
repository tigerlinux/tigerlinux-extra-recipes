# DOCKER-CE INSTALLATION SCRIPT

Supported Operating Systems: Centos 7, Ubuntu 16.04 lts (64 bits only)

This script will install and start docker-ce from Docker-CE oficial repositories on Centos7 and Ubuntu 16.04 lts (64 bits only).

Please note that this script will disable both firewalld and selinux if the machine is a Centos7. If you want you can install them back after this script finish its run.

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7 or Ubuntu 16.04lts
- Architecture: x86_64/amd64.
- INSTALLED RAM: 512Mb.
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.
