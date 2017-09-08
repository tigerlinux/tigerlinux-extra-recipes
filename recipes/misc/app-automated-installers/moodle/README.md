# SEMI-AUTOMATED MOODLE INSTALLER WITH  MARIADB 10.1 FOR CENTOS7

This script will install a LAMP server (MariaDB 10.1 from official mariadb repos, php 7.1 from webtatic and other componentes from EPEL and Centos 7 repos) then download the latest "stable" moodle version, pre-configure it (database, url, etc.) and let it ready for the web-based final setup.

All database credentiales and moodle base URL information will be stored on the file "/root/moodle-server-mariadb-credentials.txt". Also, the tasks and error will be logged to the file "/var/log/moodle-server-automated-installer.log". Once this script finish, the success of failure state will be stored on the "/var/log/moodle-server-automated-installer.log" file. Then you can complete the web-based install with the information indicated by the log on the "/root/moodle-server-mariadb-credentials.txt" file (basically, your https URL).

# FIREWALLD

This script will install and configure firewalld with the following ports opened:

- 22 tcp (ssh).
- 80 tcp (http).
- 443 tcp (https).

Please note that this script will disable selinux.


# AWS AND OPENSTACK ENVIRONMENT WITH PUBLIC-IP'S/EIP'S/FIP'S

If you are running this script inside a virtual cloud instance using "aws-style" public-ip's, floating-ip's or elastic-ip's (OpenStack too), the script will try to detect the public IP from the metadata services in the cloud, and configure moodle to answer HTTPS using the public/eip/fip. This apply to both AWS and OpenStack (if using this networking model) but can also apply to any similar system using the AWS networking model.

Note tha you can always change Moodle URL by editing the file "/var/www/html/config.php" and changing the following variable:

```bash
$CFG->wwwroot   = 'https://SERVER_IP';
```

You can set a FQDN too. Example follows:

```bash
$CFG->wwwroot   = 'https://www.mymoodle.com';
```

Please always use a HTTPS-based URL.


# LETSENCRYPT

This script will install "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on apache is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.
