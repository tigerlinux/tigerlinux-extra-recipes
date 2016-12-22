#!/bin/bash
#
# Icinga Installation Script - Very commented version
#
# Requeriment: Centos 7 with EPEL installed
# FirewallD and SELINUX disabled
#
# By Reinaldo R. Martinez P.
# tigerlinux AT gmail DOT com
#

#
# First, some usefull variables:
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
# Icinga Databases Password:
# Main WEB Database: icinga2web, user: icinga2web
# IDO Database: icinga2, user: icinga2
icingadbpass="P@ssw0rd"
# Icinga DB Account password
icingadbbackup="P@ssw0rd"
# MySQL/MariaDB Root account password
mysqlrootpass="P@ssw0rd"
# PHP.INI Timezone
phptimezone="America/Caracas"
# OpenStack V3 Auth Project Name
osprjname="ec2testing"
# OpenStack V3 Auth User Name
osusrname="ec2testing"
# OpenStack V3 Auth User Password
ospassword="ec2testing"
# OpenStack V3 Domain
osdomain="default"
# OpenStack V3 Keystone Endpoint
osendpoint="http://192.168.1.4:35357/v3"
# SWIFT Container - please ensure this is already created
cloudcontainer="special-app"
# Set this to YES if you want to use OpenStack-based Cloud Storage Backups.
backuptstoswift="no"

#
# First, repo installation and full update:
# We need to include the Icinga REPO Key and Icinga Repo definition file in order
# to access the Icinga packages
#

rpm --import http://packages.icinga.org/icinga.key
wget http://packages.icinga.org/epel/ICINGA-release.repo -O /etc/yum.repos.d/ICINGA-release.repo

#
#
# Docker Installation - from docker repo
#
# We are going to use DOCKER for the MariaDB Icinga Database Backend.
# While EPEL repo contains docker, the docker main repos always contains
# a more recent/updated version
# The following lines show a way to automate a file creation and also send
# it to the console by using tee with <<-'EOF'
#

rm -f /etc/yum.repos.d/docker.repo

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

#
# Full update now - first we clean all cache, then, yum update everything
#

yum clean all
yum -y update

#
# Let's install and activate Docker.
#

yum -y install docker-engine
systemctl enable docker
systemctl start docker
systemctl status docker

#
#
# Icinga packages basic installation and basic server activation
#

yum -y install icinga2

systemctl enable icinga2
systemctl start icinga2
systemctl status icinga2

#
#
# mariaDB 5.5 install and configuration - with Docker and crudini
#

#
#
# First install mariadb client
#

yum -y install mariadb

#
#
# We are going to configure Docker MariaDB container to use two external directories,
# one for the configuration, the other one for the database files.
#

mkdir -p /opt/icinga-database/conf.d
mkdir -p /var/icinga-database/dbfiles

#
#
# If we are running again this script, we do some clean up first
#

docker ps -aq --no-trunc|xargs docker rm -f

rm -rf /var/lib/mysql
rm -rf /var/icinga-database/dbfiles/*

#
# Let's map /var/lib/mysql to /var/icinga-database/dbfiles so
# we see not only our database files in the centos standard
# localtion but also the mysql/mariadb socket in order to
# let the mysql client to find it and use it.
#

ln -s /var/icinga-database/dbfiles /var/lib/mysql

#
# Crudini install - this is the best way to automate ini files
# manipulation
#

yum -y install crudini

#
# Using crudini, let's create our "MariaDB" main config:
#
# TRICK: This initial config WILL NOT include the mysql socket
# definition. For some reason, the first time it run with the socket
# defined on the config, it fails the first provisioning.
#

echo "" > /opt/icinga-database/conf.d/server.cnf

crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_connections 100
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_allowed_packet 1024M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld thread_cache_size 128
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld sort_buffer_size 4M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld bulk_insert_buffer_size 16M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_heap_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld tmp_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqldump max_allowed_packet 1024M

#
#
# Run the container: The first time we run the container, we include the variable
# wich configures the root account, and map the internal config and database directories
# to our previouslly created outside directories.
#

docker run --name mariadb-engine-icinga \
-v /opt/icinga-database/conf.d:/etc/mysql/conf.d \
-v /var/icinga-database/dbfiles:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="$mysqlrootpass" \
-p 127.0.0.1:3306:3306 \
-d mariadb:5.5

#
#
# This step is a trick... nasty but necessary...
# The first creation of the container need to be done
# without the socket line (mysql.sock) in the config or it
# fails. The, we wait a safe 20 seconds in order to let
# the docker container to fully stabilize, the, stop it,
# change the config again in order to include the socket
# line, and let the systemctl unit to do start the db
# container again.
#

sleep 20

docker ps -a
docker stop mariadb-engine-icinga

echo "" > /opt/icinga-database/conf.d/server.cnf

crudini --set /opt/icinga-database/conf.d/server.cnf mysqld socket /var/lib/mysql/mysql.sock
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_connections 100
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_allowed_packet 1024M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld thread_cache_size 128
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld sort_buffer_size 4M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld bulk_insert_buffer_size 16M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_heap_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld tmp_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqldump max_allowed_packet 1024M

docker start mariadb-engine-icinga
docker ps -a

#
#
# Let's create a .my.cnf file in order to ease our database creation later.
#

echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"$mysqlrootpass\""  >> /root/.my.cnf 
echo "host = \"localhost\""  >> /root/.my.cnf

chmod 600 /root/.my.cnf


#
#
# Now, we ensure the database will run as part of systemd
#
# This systemd unit sanitize the container each time a "start" is
# called. That way, we ensure our container run's OK
#

echo "[Unit]" > /etc/systemd/system/icinga-mariadb-server.service
echo "Description=Icinga MariaDB 5.5 Service" >> /etc/systemd/system/icinga-mariadb-server.service
echo "After=docker.service" >> /etc/systemd/system/icinga-mariadb-server.service
echo "Requires=docker.service" >> /etc/systemd/system/icinga-mariadb-server.service
echo "" >> /etc/systemd/system/icinga-mariadb-server.service
echo "[Service]" >> /etc/systemd/system/icinga-mariadb-server.service
echo "Type=oneshot" >> /etc/systemd/system/icinga-mariadb-server.service
echo "RemainAfterExit=true" >> /etc/systemd/system/icinga-mariadb-server.service
echo "ExecStartPre=-/usr/bin/docker rm -f mariadb-engine-icinga" >> /etc/systemd/system/icinga-mariadb-server.service
echo "ExecStart=/usr/bin/bash -c \"/usr/bin/docker run --name mariadb-engine-icinga -v /opt/icinga-database/conf.d:/etc/mysql/conf.d -v /var/icinga-database/dbfiles:/var/lib/mysql -p 127.0.0.1:3306:3306 -d mariadb:5.5\"" >> /etc/systemd/system/icinga-mariadb-server.service
echo "ExecStop=/usr/bin/bash -c \"/usr/bin/docker stop mariadb-engine-icinga\"" >> /etc/systemd/system/icinga-mariadb-server.service
echo "" >> /etc/systemd/system/icinga-mariadb-server.service
echo "[Install]" >> /etc/systemd/system/icinga-mariadb-server.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/icinga-mariadb-server.service

systemctl daemon-reload

systemctl enable icinga-mariadb-server

sleep 10

#
#
# This is just a test !!
#

echo "show databases;"|mysql -h localhost -p$mysqlrootpass

#
#
# Then, create and provision our databases
#

sleep 20

echo "CREATE DATABASE icinga2;"|mysql -h localhost -p$mysqlrootpass
sleep 3
echo "GRANT ALL ON icinga2.* TO 'icinga2'@'%' IDENTIFIED BY '$icingadbpass';"|mysql -h localhost -p$mysqlrootpass

echo "CREATE DATABASE icinga2web;"|mysql -h localhost -p$mysqlrootpass
sleep 3
echo "GRANT ALL ON icinga2web.* TO 'icinga2web'@'%' IDENTIFIED BY '$icingadbpass';"|mysql -h localhost -p$mysqlrootpass

echo "Listing our databases:"

sleep 1
echo "show databases;"|mysql -h localhost -p$mysqlrootpass
sleep 5

#
#
# We continue the ICINGA installation:
#

yum -y install icinga2-ido-mysql

mysql -h localhost -p$mysqlrootpass icinga2 < /usr/share/icinga2-ido-mysql/schema/mysql.sql

#
#
# More config:
# This is another way used to configure a file with "echo's" instead of the "tee" used before.
#

cp /etc/icinga2/features-available/ido-mysql.conf /etc/icinga2/features-available/ido-mysql.conf.`date +%Y%m%d%H%M`

echo "library \"db_ido_mysql\"" > /etc/icinga2/features-available/ido-mysql.conf
echo "" >> /etc/icinga2/features-available/ido-mysql.conf
echo "object IdoMysqlConnection \"ido-mysql\" {" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  user = \"icinga2\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  password = \"$icingadbpass\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  host = \"localhost\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  database = \"icinga2\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "}" >> /etc/icinga2/features-available/ido-mysql.conf

#
#
# Enable icinga mysql ido
#

icinga2 feature enable ido-mysql

#
#
# Install and activate apache
#

yum -y install httpd
systemctl enable httpd
systemctl start httpd
systemctl status httpd

#
#
# Firewall rules - Just in case you forgot to disable firewalld
#

firewall-cmd --add-service=http
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

#
#
# More ICINGA feature activation
#

icinga2 feature enable command
systemctl restart icinga2

#
#
# Icinga web support:
#

yum -y install icingaweb2 icingacli

#
# Normally, icinga2 on centos install's itself in a webfoder, so, for convenience, we
# create a html index with redirect to this folder. If you go to the web server root,
# you'll be redirected to the icinga2 web folder
#

echo "<HTML>" > /var/www/html/index.html
echo "<HEAD>" >> /var/www/html/index.html
echo "<META HTTP-EQUIV=\"refresh\" CONTENT=\"0;URL=/icingaweb2\">" >> /var/www/html/index.html
echo "</HEAD>" >> /var/www/html/index.html
echo "<BODY>" >> /var/www/html/index.html
echo "</BODY>" >> /var/www/html/index.html
echo "</HTML>" >> /var/www/html/index.html

#
#
# PHP Timezone and other php things:
#

crudini --set /etc/php.ini Date date.timezone "$phptimezone"

#
#
# Just in case you want to enable ICINGA LDAP Auth later...

yum -y install php-ldap

systemctl restart httpd

#
#
# nagios plugins for monitoring
#

yum -y install nagios-plugins-all

#
#
# Then we generate the token for the wizard-based install and save it
# to a file inside the server
#

icingacli module enable setup
icingacli setup token create > /root/icinga-token.txt
chmod 600 /root/icinga-token.txt
cat /root/icinga-token.txt

#
#
# Time for puppet:
#
# Firts install puppet and make a module structure for the server crontabs
#

yum -y install puppet

mkdir -p /etc/puppet/modules/servercrontabs
mkdir -p /etc/puppet/modules/servercrontabs/libs
mkdir -p /etc/puppet/modules/servercrontabs/templates
mkdir -p /etc/puppet/modules/servercrontabs/manifests
mkdir -p /etc/puppet/modules/servercrontabs/files

#
#
# The backup user for ... database backups of course
#
# PLEASE note something: Why is that 172.x.x.x ACL ???.. Simple: The database is running inside a container. The container
# real IP's uses 172.x.x.x docker network. If you try to enter from outside the machine localhost IP, what the MariaDB
# engine inside the container will see is a connection from a 172.x.x.x IP.
#

echo "GRANT SELECT ON icinga2.* TO 'backups'@'localhost' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2.* TO 'backups'@'127.%.%.%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2.* TO 'backups'@'172.%.%.%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2web.* TO 'backups'@'localhost' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2web.* TO 'backups'@'127.%.%.%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2web.* TO 'backups'@'172.%.%.%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass

#
#
# The puppet manifest... created with CAT <<EOF >>... anothe way to skin a cat
#
# Note something here: The manifest will do two things:
# Thing 1: Create the crontab line
# Thing 2: Create the backup script wich will do our Backup job, and optionally,
#          send those backups to the cloud object storage container.
# If you plan to use AWS S3 instead of OPENSTACK SWIFT, this is where you need to
# do your first modifications in order to use aws client instead of openstack
# client to send files to Cloud Object Storage.
#

rm -f /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp

if [ $backuptstoswift == "yes" ]
then

cat <<EOF >> /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp
cron { 'update_cron_dbdump_01':
	ensure  => 'present',
	command => '/usr/local/bin/database-backups.sh >> /var/log/server-db-backups.log 2>&1',
	user => 'root', 
	hour => '19', 
	minute => '05', 
}
file { '/usr/local/bin/database-backups.sh':
	ensure => file,
	mode => "755",
	owner => 'root',
	group => 'root',
	content => "#!/bin/bash
# Backup Script
PATH=\$PATH:/bin:/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin
#
rm -f /var/db-backups/*
nice -n 10 ionice -c2 -n7 mysqldump \
-u backups \
-p$icingadbbackup \
--single-transaction --quick --lock-tables=false \
icinga2|gzip > /var/db-backups/backup-server-db-icinga2-\`hostname -s\`-\`date +%Y%m%d%H%M\`.gz
#
nice -n 10 ionice -c2 -n7 mysqldump \
-u backups \
-p$icingadbbackup \
--single-transaction --quick --lock-tables=false \
icinga2web|gzip > /var/db-backups/backup-server-db-icinga2web-\`hostname -s\`-\`date +%Y%m%d%H%M\`.gz
#
rm -f /var/db-fullbackups/*
tar -czvf /var/db-fullbackups/bak-and-logs-latest-`hostname -s`.tgz \
/var/db-backups/backup-server-db* \
/var/log/icinga2/* \
/var/log/httpd/*
cp /var/db-fullbackups/bak-and-logs-latest-\`hostname -s\`.tgz \
/var/db-fullbackups/bak-and-logs-\`hostname -s\`-\`date +%Y%m%d%H%M\`.tgz
cd /var/db-fullbackups
source /root/keystone_authconfig
for myfile in \`ls\`;do openstack object create $cloudcontainer \$myfile;done
#
#
",
}
EOF

else

cat <<EOF >> /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp
cron { 'update_cron_dbdump_01':
	ensure  => 'present',
	command => '/usr/local/bin/database-backups.sh >> /var/log/server-db-backups.log 2>&1',
	user => 'root', 
	hour => [ 05, 11, 19 ], 
	minute => '45', 
}
file { '/usr/local/bin/database-backups.sh':
	ensure => file,
	mode => "755",
	owner => 'root',
	group => 'root',
	content => "#!/bin/bash
# Backup Script
PATH=\$PATH:/bin:/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin
#
nice -n 10 ionice -c2 -n7 mysqldump \
-u backups \
-p$icingadbbackup \
--single-transaction --quick --lock-tables=false \
icinga2|gzip > /var/db-backups/backup-server-db-icinga2-\`hostname -s\`-\`date +%Y%m%d%H%M\`.gz
#
nice -n 10 ionice -c2 -n7 mysqldump \
-u backups \
-p$icingadbbackup \
--single-transaction --quick --lock-tables=false \
icinga2web|gzip > /var/db-backups/backup-server-db-icinga2web-\`hostname -s\`-\`date +%Y%m%d%H%M\`.gz
",
}
EOF

fi

#
#
# To finish or Job with Icinga, let's create the groups and hosts for db monitoring
#
# The tests made here with grep, is a failsafe made in order to not repeat the same
# config if you are re-running the script
#

mygrpdbtest=`grep -c MySQL-servers /etc/icinga2/conf.d/groups.conf `

if [ $mygrpdbtest == "0" ]
then
	echo "" >> /etc/icinga2/conf.d/groups.conf
	echo "object HostGroup \"MySQL-servers\" {" >> /etc/icinga2/conf.d/groups.conf
	echo "  display_name = \"MySQL Servers\"" >> /etc/icinga2/conf.d/groups.conf
	echo "  assign where host.vars.os == \"mysqlserver\"" >> /etc/icinga2/conf.d/groups.conf
	echo "}" >> /etc/icinga2/conf.d/groups.conf >> /etc/icinga2/conf.d/groups.conf
	echo "" >> /etc/icinga2/conf.d/groups.conf >> /etc/icinga2/conf.d/groups.conf
fi

mygrpwebtest=`grep -c WEB-servers /etc/icinga2/conf.d/groups.conf `

if [ $mygrpwebtest == "0" ]
then
	echo "" >> /etc/icinga2/conf.d/groups.conf
	echo "object HostGroup \"WEB-servers\" {" >> /etc/icinga2/conf.d/groups.conf
	echo "  display_name = \"WEB Servers\"" >> /etc/icinga2/conf.d/groups.conf
	echo "  assign where host.vars.os == \"webserver\"" >> /etc/icinga2/conf.d/groups.conf
	echo "}" >> /etc/icinga2/conf.d/groups.conf >> /etc/icinga2/conf.d/groups.conf
	echo "" >> /etc/icinga2/conf.d/groups.conf >> /etc/icinga2/conf.d/groups.conf
fi

myicingadbidotest=`grep -c icinga-db-ido /etc/icinga2/conf.d/hosts.conf`
myicingawebtest=`grep -c icinga-db-web /etc/icinga2/conf.d/hosts.conf`

if [ $myicingadbidotest == "0" ]
then
	echo "" >> /etc/icinga2/conf.d/hosts.conf
	echo "object Host \"icinga-db-ido\" {" >> /etc/icinga2/conf.d/hosts.conf
	echo "   import \"generic-host\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   address = \"localhost\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.os = \"mysqlserver\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   check_command = \"mysql\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_database = \"icinga2\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_username = \"icinga2\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_password = \"P@ssw0rd\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_hostname = \"localhost\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_port = \"3306\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "}" >> /etc/icinga2/conf.d/hosts.conf
	echo "" >> /etc/icinga2/conf.d/hosts.conf
fi

if [ $myicingawebtest == "0" ]
then
	echo ""  >> /etc/icinga2/conf.d/hosts.conf
	echo "object Host \"icinga-db-web\" {" >> /etc/icinga2/conf.d/hosts.conf
	echo "   import \"generic-host\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   address = \"localhost\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.os = \"mysqlserver\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   check_command = \"mysql\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_database = \"icinga2web\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_username = \"icinga2web\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_password = \"P@ssw0rd\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_hostname = \"localhost\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "   vars.mysql_port = \"3306\"" >> /etc/icinga2/conf.d/hosts.conf
	echo "}" >> /etc/icinga2/conf.d/hosts.conf
	echo "" >> /etc/icinga2/conf.d/hosts.conf
fi

#
# Patch - sometimes this fail:
# For some reason, in some run's the web wizard fails if the following
# file is not set to the rigth permissions
#

chmod g+rwx /etc/icingaweb2/enabledModules

#
# Then, restart icinga service:
#

systemctl restart icinga2

#
#
# In order to allow the machine to contact the object storage in the openstack
# cloud, we need to install the openstack client and enable the credentials
#

#
# If you plan to use AWS S3 instead of OPENSTACK SWIFT, modify the following
# secuences in order to "pip install" aws python client instead of openstack
# python client
#

yum -y install python-pip python python-devel blas-devel lapack-devel gcc-c++
yum -y groupinstall "Development Tools"
pip install python-openstackclient

#
# If we are going to use OpenStack SWIFT based backups, we need
# to create the keystone authorization file
# If you are using Keystone V2 instead of V3, you'll need to
# modify the following lines
#

if [ $backuptstoswift == "yes" ]
then
rm -f /root/keystone_authconfig
cat <<EOF >> /root/keystone_authconfig
export OS_USERNAME=$osusrname
export OS_PASSWORD=$ospassword
export OS_TENANT_NAME=$osprjname
export OS_PROJECT_NAME=$osprjname
export OS_AUTH_URL=$osendpoint
export OS_VOLUME_API_VERSION=2
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_DOMAIN_NAME=$osdomain
export OS_USER_DOMAIN_NAME=$osdomain
export OS_AUTH_VERSION=3
EOF
chmod 0600 /root/keystone_authconfig
fi


#
#
# The Puppet manifest file is created, but not applied yet. Let's apply it now
#

mkdir -p /var/db-backups
mkdir -p /var/db-fullbackups

/usr/bin/puppet apply -l /var/log/puppet-mysqldump-manifest.log /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp

#
#
# And enable it at the end of rc.local, only if it's not already there
#
#

mytest=`grep -c "mysqldump.pp" /etc/rc.local`

if [ $mytest == "0" ]
then
	echo "/usr/bin/puppet apply -l /var/log/puppet-mysqldump-manifest.log /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp" >> /etc/rc.local
fi

#
#
# Then we are done, and let's give the "carbon-unit" AKA Human Sysadmin a kind reminder
# about the ICINGA Install Token:
#

echo ""
echo "Installation finished. Remember to use the following token when asked:"
echo ""
cat /root/icinga-token.txt

#
# END. That's all. You are redy to enter to your icinga web server and complete the wizard-install
#
