# TEAMPASS CENTOS-7 SERVER AUTOMATED INSTALLER.

This script will do a basic LEMP installation (php 7.1 from webtatic repos, nginx from EPEL repos, mariadb 10.1 from MariaDB repos), then install and configure TEAMPASS 2.1. The script was designed to run on Centos 7.x, specially the one found on cloud images for aws, openstack and other cloud providers.

The results from all actions performed by this script will be stored at the log file "/var/log/teampass-server-automated-installer.log". The credentials for databases (mysql root, teampass) will be stored at the file "/root/teampass-server-credentials.txt".

**NOTE: You'll need the "teampass" database credentials con the file "/root/teampass-server-credentials.txt" in order to finish the instalation!**

The script will do the basic installation and database creation but the final steps need to be performed by you using your browser. Once the scripted installation is done (monitor the installation with `tail -f /var/log/teampass-server-automated-installer.log`) use your browser to finish the web-install part entering to the server IP or FQDN.

Once the web install part is done, you must remove the "/usr/share/nginx/html/install" directory with the following command:

```bash
rm -rf  /usr/share/nginx/html/install
```

Then, you'll be able to logon to your teampass installation.


# LETSENCRYPT

The script will install "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on nginx is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.


# OPENED PORTS

FirewallD allow traffic for the following ports only (input traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).

**NOTE:** Both php-fpm and mariadb services are configured to listen on localhost only (127.0.0.0:9000 and 127.0.0.0:3306).


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb.
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.
