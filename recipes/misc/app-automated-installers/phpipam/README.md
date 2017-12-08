# PHPIPAM CENTOS-7 SERVER AUTOMATED INSTALLER.

This script will do a basic LEMP installation (php 7.1 from webtatic repos, nginx from EPEL repos, mariadb 10.1 from MariaDB repos), then install and configure PHPIPAM 1.3. The script was designed to run on Centos 7.x, specially the one found on cloud images for aws, openstack and other cloud providers.

The results from all actions performed by this script will be stored at the log file "/var/log/phpipam-server-automated-installer.log". The credentials for databases (mysql root, phpipam) and the credentials for PHPIPAM will be stored at the file "/root/phpipam-server-credentials.txt".


# LETSENCRYPT

The script will install "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on nginx is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.


# OPENED PORTS

FirewallD allow traffic for the following ports only (input traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).

**NOTE:** Both php-fpm and mariadb services are configured to listen on localhost only (127.0.0.0:9000 and 127.0.0.0:3306).


# DEFAULT CREDENTIALS

The default admin user is "Admin" (yes, a "capital" "A") with password "ipamadmin". The first time you log with those credentials, PHPIPAM will force you to change the password.


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 512Mb.
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.
