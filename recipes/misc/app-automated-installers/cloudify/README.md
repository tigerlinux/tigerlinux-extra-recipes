# CLOUDIFY MANAGER INSTALLATION SCRIPTS (OPENSTACK AND BAREMETAL).

Enterprise version: 4.1 GA
Community version: 17.3.31



## Scripts included on this directory:

- cfy-install-community-baremetal.sh: Manager installation script for generic/bare-metal servers. Community release.
- cfy-install-community-openstack.sh: Manager installation script for cloud instances running on OpenStack. Community release.
- cfy-install-enterprise-baremetal.sh: Manager installation script for generic/bare-metal servers. Enterprise release.
- cfy-install-enterprise-openstack.sh: Manager installation script for cloud instances running on OpenStack. Enterprise release.



## Usage: Bare-metal/Generic:

Base requeriments:

- Distribution: Linux RHEL 7 or CentOS 7 (64 bits).
- Minimun hardware: 2 cores/threads, 4GB RAM, 5GB disk space.
- The server must have internet access.

Copy the script for your desired release (community or enterprise) to your server, and run it as "root" (don't use sudo). The script will run completely automated. Also you can use the script with any "cloud-init" based setup (as a bootstrap/user-data script).

The credentials for your manager will be copied to the file: /root/cfy-credentials.txt. The password will be auto-generated, the user will be "admin".



## Usage: Cloud-instances on OpenStack:

- Distribution: Linux RHEL 7, CentOS 7 or Scientific Linux 7 (64 bits), generic cloud images for OpenStack.
- Minimun hardware: 2 vcpu's, 4GB RAM, 5GB disk space.
- The cloud instance must have internet access.
- FIP (floating-ip) attached to the cloud instance (optional but recommended).

Boot your cloud instances using the script as "user-data" (Customization Script).

Example:

```bash

openstack server create my-manager \
--image Centos-7-base-cloud-image \
--flavor openstack-flavor-with-2vcpu-4gbram-5gbharddisk \
--user-data ~/my-userdata-script-for-cfy-manager-install.sh \
--security-group my-security-group-for-cfy-manager \
--nic net-id=my-network \
--key-name my-key

```

After the installation is completed, the credentials will be stored on the file: /root/cfy-credentials.txt.


You'll need to create a security group with the following ports opened: 22, 80, 5672, 8086, 9100, 9200, 9999, 53333. Also, if you plan to include clustering: 8300, 8301, 8500, 15432, 22000 and 53229.

Please note that this script will disable both firewalld and selinux. If you want you can install them back after this script finish its run.


# GENERAL REQUIREMENTS:

Those scripts will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 4GB.
- CPU: 2 Core/Thread.
- FREE DISK SPACE: 5GB.


END.-
