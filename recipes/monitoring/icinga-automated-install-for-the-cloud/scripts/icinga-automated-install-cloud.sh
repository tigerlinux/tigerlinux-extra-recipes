#!/bin/bash
#
# Icinga Installation Script - for Cloudformation and similar environments
#
# Requeriment: Centos 7 with EPEL installed
# FirewallD and SELINUX disabled
#
# By Reinaldo R. Martinez P.
# tigerlinux AT gmail DOT com
#
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
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
rpm --import http://packages.icinga.org/icinga.key
wget http://packages.icinga.org/epel/ICINGA-release.repo -O /etc/yum.repos.d/ICINGA-release.repo
rm -f /etc/yum.repos.d/docker.repo
tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
yum clean all
yum -y update
yum -y install docker-engine
systemctl enable docker
systemctl start docker
systemctl status docker
yum -y install icinga2
systemctl enable icinga2
systemctl start icinga2
systemctl status icinga2
yum -y install mariadb
mkdir -p /opt/icinga-database/conf.d
mkdir -p /var/icinga-database/dbfiles
docker ps -aq --no-trunc|xargs docker rm -f
rm -rf /var/lib/mysql
rm -rf /var/icinga-database/dbfiles/*
ln -s /var/icinga-database/dbfiles /var/lib/mysql
yum -y install crudini
echo "" > /opt/icinga-database/conf.d/server.cnf
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_connections 100
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_allowed_packet 1024M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld thread_cache_size 128
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld sort_buffer_size 4M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld bulk_insert_buffer_size 16M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld max_heap_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqld tmp_table_size 32M
crudini --set /opt/icinga-database/conf.d/server.cnf mysqldump max_allowed_packet 1024M
docker run --name mariadb-engine-icinga \
-v /opt/icinga-database/conf.d:/etc/mysql/conf.d \
-v /var/icinga-database/dbfiles:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="$mysqlrootpass" \
-p 127.0.0.1:3306:3306 \
-d mariadb:5.5
sleep 20
docker stop mariadb-engine-icinga
docker ps -a
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
echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"$mysqlrootpass\""  >> /root/.my.cnf 
echo "host = \"localhost\""  >> /root/.my.cnf
chmod 600 /root/.my.cnf
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
echo "show databases;"|mysql -h localhost -p$mysqlrootpass
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
yum -y install icinga2-ido-mysql
mysql -h localhost -p$mysqlrootpass icinga2 < /usr/share/icinga2-ido-mysql/schema/mysql.sql
cp /etc/icinga2/features-available/ido-mysql.conf /etc/icinga2/features-available/ido-mysql.conf.`date +%Y%m%d%H%M`
echo "library \"db_ido_mysql\"" > /etc/icinga2/features-available/ido-mysql.conf
echo "" >> /etc/icinga2/features-available/ido-mysql.conf
echo "object IdoMysqlConnection \"ido-mysql\" {" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  user = \"icinga2\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  password = \"$icingadbpass\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  host = \"localhost\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "  database = \"icinga2\"" >> /etc/icinga2/features-available/ido-mysql.conf
echo "}" >> /etc/icinga2/features-available/ido-mysql.conf
icinga2 feature enable ido-mysql
yum -y install httpd
systemctl enable httpd
systemctl start httpd
systemctl status httpd
firewall-cmd --add-service=http
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
icinga2 feature enable command
systemctl restart icinga2
yum -y install icingaweb2 icingacli
echo "<HTML>" > /var/www/html/index.html
echo "<HEAD>" >> /var/www/html/index.html
echo "<META HTTP-EQUIV=\"refresh\" CONTENT=\"0;URL=/icingaweb2\">" >> /var/www/html/index.html
echo "</HEAD>" >> /var/www/html/index.html
echo "<BODY>" >> /var/www/html/index.html
echo "</BODY>" >> /var/www/html/index.html
echo "</HTML>" >> /var/www/html/index.html
crudini --set /etc/php.ini Date date.timezone "$phptimezone"
yum -y install php-ldap
systemctl restart httpd
yum -y install nagios-plugins-all
icingacli module enable setup
icingacli setup token create > /root/icinga-token.txt
chmod 600 /root/icinga-token.txt
cat /root/icinga-token.txt
yum -y install puppet
mkdir -p /etc/puppet/modules/servercrontabs
mkdir -p /etc/puppet/modules/servercrontabs/libs
mkdir -p /etc/puppet/modules/servercrontabs/templates
mkdir -p /etc/puppet/modules/servercrontabs/manifests
mkdir -p /etc/puppet/modules/servercrontabs/files
echo "GRANT SELECT ON icinga2.* TO 'backups'@'%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
echo "GRANT SELECT ON icinga2web.* TO 'backups'@'%' IDENTIFIED BY '$icingadbbackup';"|mysql -h localhost -p$mysqlrootpass
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
chmod g+rwx /etc/icingaweb2/enabledModules
systemctl restart icinga2
yum -y install python-pip python python-devel blas-devel lapack-devel gcc-c++
yum -y groupinstall "Development Tools"
pip install python-openstackclient
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
mkdir -p /var/db-backups
mkdir -p /var/db-fullbackups
/usr/bin/puppet apply -l /var/log/puppet-mysqldump-manifest.log /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp
mytest=`grep -c "mysqldump.pp" /etc/rc.local`
if [ $mytest == "0" ]
then
	echo "/usr/bin/puppet apply -l /var/log/puppet-mysqldump-manifest.log /etc/puppet/modules/servercrontabs/manifests/mysqldump.pp" >> /etc/rc.local
fi
echo ""
echo "Installation finished. Remember to use the following token wen asked:"
echo ""
cat /root/icinga-token.txt

