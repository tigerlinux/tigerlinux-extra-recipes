#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Zabbix Server Automated Installation Script
# Rel 1.2
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/zabbixserver-automated-installer.log"
credentialsfile="/root/zabbix-access-info.txt"
echo "Start Date/Time: `date`" &>>$lgfile
debug="no"

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname
else
	echo "Nota a centos machine. Aborting!." &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

amicen=`lsb_release -i|grep -ic centos`
crel7=`lsb_release -r|awk '{print $2}'|grep ^7.|wc -l`
if [ $amicen != "1" ] || [ $crel7 != "1" ]
then
	echo "This is NOT a Centos 7 machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export mariadbip='127.0.0.1'
export mariadbpass=`openssl rand -hex 10`
export zabbixdbpass=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for MariaDB. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
yum -y install firewalld
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp --permanent
firewall-cmd --reload

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf

if [ `grep -c swapfile /etc/fstab` == "0" ]
then
	myswap=`free -m -t|grep -i swap:|awk '{print $2}'`
	if [ $myswap -lt 2000 ]
	then
		fallocate -l 2G /swapfile
		chmod 600 /swapfile
		mkswap /swapfile
		swapon /swapfile
		echo '/swapfile none swap sw 0 0' >> /etc/fstab
	fi
fi

yum -y install epel-release
# Kill packet.net repositories if detected here.
yum -y install yum-utils
repotokill=`yum repolist|grep -i ^packet|cut -d/ -f1`
for myrepo in $repotokill
do
	echo "Disabling repo: $myrepo" &>>$lgfile
	yum-config-manager --disable $myrepo &>>$lgfile
done

cat <<EOF >/etc/yum.repos.d/mariadb101.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

if [ $debug == "yes" ]
then
	wget http://mirror.gatuvelus.home/cfgs/repos/centos7/mariadb101-amd64.repo -O /etc/yum.repos.d/mariadb101.repo
fi

yum -y update --exclude=kernel*
yum -y install MariaDB MariaDB-server MariaDB-client galera crudini

echo "" > /etc/my.cnf.d/mariadb-server-custom.cnf

crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld binlog_format ROW
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld default-storage-engine innodb
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld innodb_autoinc_lock_mode 2
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld query_cache_type 0
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld query_cache_size 0
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld bind-address $mariadbip
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld max_allowed_packet 1024M
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld max_connections 1000
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld innodb_doublewrite 1
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld innodb_log_file_size 100M
crudini --set /etc/my.cnf.d/mariadb-server-custom.cnf mysqld innodb_flush_log_at_trx_commit 2
echo "innodb_file_per_table" >> /etc/my.cnf.d/mariadb-server-custom.cnf

mkdir -p /etc/systemd/system/mariadb.service.d/
mkdir -p /etc/systemd/system/mariadb.service.d/
cat <<EOF >/etc/systemd/system/mariadb.service.d/limits.conf
[Service]
LimitNOFILE=65535
EOF

cat <<EOF >/etc/security/limits.d/10-mariadb.conf
mysql hard nofile 65535
mysql soft nofile 65535
EOF

systemctl --system daemon-reload

systemctl enable mariadb.service
systemctl start mariadb.service

cloudconfigdrive=`grep cloudconfig /etc/fstab |grep -v swap|awk '{print $1}'`
if [ $cloudconfigdrive ]
then
	umount $cloudconfigdrive
	cat /etc/fstab > /etc/fstab.backup-original
	cat /etc/fstab|egrep -v $cloudconfigdrive > /etc/fstab.pre-cloudconfigdrive
	cat /etc/fstab.pre-cloudconfigdrive > /etc/fstab
fi

devicelist=`lsblk -do NAME,TYPE -nl -e1,2,11|grep disk|grep -v drbd|awk '{print $1}'`

nxsto=''
for blkst in $devicelist
do
	if [ `lsblk -do NAME,TYPE|grep -v NAME|grep disk|awk '{print $1}'|grep -v da|grep -c ^$blkst` == "1" ] \
	&& [ `blkid |grep $blkst|grep -ci swap` == 0 ] \
	&& [ `grep -v cloudconfig /etc/fstab |grep -ci ^/dev/$blkst` == 0 ] \
	&& [ `pvdisplay|grep -ci /dev/$blkst` == 0 ] \
	&& [ `df -h|grep -ci ^/dev/$blkst` == 0 ]
	then
		echo "Device $blkst usable" &>>$lgfile
		nxsto=$blkst
	fi
done

mkdir -p /var/mariadb-storage

if [ -z $nxsto ]
then
	echo "No usable extra storage found" &>>$lgfile
else
	echo "Extra storage found: $nxsto" &>>$lgfile
	cat /etc/fstab > /etc/fstab.ORG
	umount /dev/$nxsto >/dev/null 2>&1
	cat /etc/fstab |egrep -v "($nxsto|mariadbsto)" > /etc/fstab.NEW
	cat /etc/fstab.NEW > /etc/fstab
	mkfs.ext4 -F -F -L mariadbsto /dev/$nxsto
	echo 'LABEL=mariadbsto /var/mariadb-storage ext4 defaults 0 0' >> /etc/fstab
	mount /var/mariadb-storage
	systemctl stop mariadb.service
	sync
	sleep 5
	mv /var/lib/mysql /var/mariadb-storage/
	ln -s /var/mariadb-storage/mysql /var/lib/mysql
	systemctl start mariadb.service
fi

cat<<EOF >/root/os-db.sql
UPDATE mysql.user SET Password=PASSWORD('$mariadbpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$mariadbpass' WITH GRANT OPTION;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE zabbixdb default character set utf8;
GRANT ALL ON zabbixdb.* TO 'zabbixdbuser'@'%' IDENTIFIED BY '$zabbixdbpass';
GRANT ALL ON zabbixdb.* TO 'zabbixdbuser'@'127.0.0.1' IDENTIFIED BY '$zabbixdbpass';
GRANT ALL ON zabbixdb.* TO 'zabbixdbuser'@'localhost' IDENTIFIED BY '$zabbixdbpass';
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql

cat<<EOF >/root/.my.cnf
[client]
user = "root"
password = "$mariadbpass"
host = "localhost"
EOF

chmod 0600 /root/.my.cnf

rm -f /root/os-db.sql

yum -y install zlib-devel glibc-devel curl-devel gcc automake \
libidn-devel openssl-devel net-snmp-devel rpm-devel \
OpenIPMI-devel net-snmp net-snmp-utils php-mysqlnd \
php-gd php-bcmath php-mbstring php-xml nmap php \
MariaDB-devel MariaDB-client httpd mod_php php-ldap \
mod_evasive mod_ssl

ldconfig -v >/dev/null 2>&1

crudini --set /etc/php.ini PHP max_execution_time 300
crudini --set /etc/php.ini PHP max_input_time 300
crudini --set /etc/php.ini PHP memory_limit 256M
crudini --set /etc/php.ini PHP mbstring.func_overload 0

mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

if [ -f /usr/share/zoneinfo/$mytimezone ]
then
	crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
else
	crudini --set /etc/php.ini PHP date.timezone "UTC"
fi

cat <<EOF >/etc/httpd/conf.d/extra-security.conf
ServerTokens ProductOnly
FileETag None
ExtendedStatus Off
UseCanonicalName Off
TraceEnable off
ServerSignature Off
EOF

sed -r -i 's/^SSLProtocol.*/SSLProtocol\ all\ -SSLv2\ -SSLv3/g' /etc/httpd/conf.d/ssl.conf
sed -r -i 's/^SSLCipherSuite.*/SSLCipherSuite\ HIGH:MEDIUM:!aNULL:\!MD5:\!SSLv3:\!SSLv2/g' /etc/httpd/conf.d/ssl.conf
sed -r -i 's/^\#SSLHonorCipherOrder.*/SSLHonorCipherOrder\ on/g' /etc/httpd/conf.d/ssl.conf

rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

yum -y update --exclude=kernel*

yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent

cp /usr/share/doc/zabbix-server-mysql-3.*/create.sql.gz /root/
gunzip /root/create.sql.gz

mysql -u zabbixdbuser -h localhost -p$zabbixdbpass zabbixdb < /root/create.sql
sync
sleep 5
rm -f /root/create.sql

cat <<EOF>/etc/sudoers.d/zabbix
Defaults:zabbix !requiretty
Defaults:zabbixsrv !requiretty
zabbix ALL=(ALL) NOPASSWD:ALL
zabbixsrv ALL=(ALL) NOPASSWD:ALL
EOF

chmod 0440 /etc/sudoers.d/zabbix

cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.ORIGINAL

cat <<EOF>/etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
DBName=zabbixdb
DBUser=zabbixdbuser
DBPassword=$zabbixdbpass
DBPort=3306
DBHost=localhost
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
EOF

systemctl start zabbix-server.service
systemctl enable zabbix-server.service
systemctl restart httpd
systemctl enable httpd

cat <<EOF>/etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']       = 'MYSQL';
\$DB['SERVER']     = 'localhost';
\$DB['PORT']       = '3306';
\$DB['DATABASE']   = 'zabbixdb';
\$DB['USER']       = 'zabbixdbuser';
\$DB['PASSWORD']   = '$zabbixdbpass';
// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA']     = '';

\$ZBX_SERVER       = 'localhost';
\$ZBX_SERVER_PORT  = '10051';
\$ZBX_SERVER_NAME  = 'Zabbix Server';

\$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
EOF

chown apache.apache /etc/zabbix/web/*.php

systemctl start zabbix-agent.service
systemctl enable zabbix-agent.service

echo "MariaDB User: root" > $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile
echo "ZabbixDB: zabbixdb" >> $credentialsfile
echo "ZabbixDB User: zabbixdbuser" >> $credentialsfile
echo "ZabbixDB User Password: $zabbixdbpass" >> $credentialsfile
echo "Zabbix admin user: admin" >> $credentialsfile
echo "Zabbix admin user password: zabbix" >> $credentialsfile
echo "Zabbix URL: http://`ip route get 1 | awk '{print $NF;exit}'`" >> $credentialsfile
echo "Zabbix URL - Encrypted: https://`ip route get 1 | awk '{print $NF;exit}'`" >> $credentialsfile

cat <<EOF>/var/www/html/index.html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/zabbix">
</HEAD>
<BODY>
</BODY>
</HTML>
EOF

if [ `ss -ltn|grep -c :10051` -gt "0" ]
then
	echo "Zabbix Server Installation ready. Credentials file: $credentialsfile" &>>$lgfile
	echo "Your credentials:" &>>$lgfile
	cat $credentialsfile  &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "Zabbix installation failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi

# END