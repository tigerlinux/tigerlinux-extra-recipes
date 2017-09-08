# ZONEMINDER 1.30 AUTOMATED INSTALLER FOR CENTOS7

This script will do a basic distribution setup with some usefull packages, then install and configure ZoneMinder 1.30 with all required dependencies (database included). The database credentiales and access URL's will be stored on the file "/root/zm-credentials.txt". Zoneminder will be ready to use in the server HTTPS url !. All tasks results (and/or error) will be logged to the file "/var/log/zm-automated-install.log".

Please note that this script will disable selinux.

This script will use ZoneMinder oficial repos at [http://zmrepo.zoneminder.com/](http://zmrepo.zoneminder.com/). The database is MariaDB from Centos 7 official repositories.

# FIREWALLD

FirewallD will be installed and configured with. The following ports will be opened:

- 22 tcp (ssh).
- 80 tcp (http).
- 443 tcp (https).

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.

