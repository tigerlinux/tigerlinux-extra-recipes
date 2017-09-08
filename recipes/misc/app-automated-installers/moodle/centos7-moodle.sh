#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Moodle Server Installation Script
# Rel 1.0
# For usage on centos7 64 bits machines.
# (includes phpmyadmin installation as an option)

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
export lgfile="/var/log/moodle-server-automated-installer.log"
export credfile="/root/moodle-server-mariadb-credentials.txt"
echo "Start Date/Time: `date`" &>>$lgfile
export debug="no"


if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools \
	git findutils iproute grep openssh sed gawk openssl which xz bzip2 \
	util-linux procps-ng which lvm2 sudo hostname rsync
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

export mariadbpass=`openssl rand -hex 10`
export moodledbpass=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "480" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for a LAMP Server. Aborting!" &>>$lgfile
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

# Kill packet.net repositories if detected here.
yum -y install yum-utils
repotokill=`yum repolist|grep -i ^packet|cut -d/ -f1`
for myrepo in $repotokill
do
	echo "Disabling repo: $myrepo" &>>$lgfile
	yum-config-manager --disable $myrepo &>>$lgfile
done


yum -y install epel-release
yum -y install yum-utils device-mapper-persistent-data

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

cat <<EOF >/etc/my.cnf.d/server-lamp.cnf
[mysqld]
binlog_format = ROW
default-storage-engine = innodb
innodb_autoinc_lock_mode = 2
query_cache_type = 0
query_cache_size = 0
bind-address = 127.0.0.1
max_allowed_packet = 1024M
max_connections = 1000
innodb_doublewrite = 1
innodb_log_file_size = 100M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
innodb_file_format = barracuda
innodb_large_prefix = on
EOF

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

cat<<EOF >/root/os-db.sql
UPDATE mysql.user SET Password=PASSWORD('$mariadbpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$mariadbpass' WITH GRANT OPTION;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET UTF8 COLLATE utf8_unicode_ci;
GRANT ALL ON moodle.* TO 'moodledbuser'@'%' IDENTIFIED BY '$moodledbpass';
GRANT ALL ON moodle.* TO 'moodledbuser'@'127.0.0.1' IDENTIFIED BY '$moodledbpass';
GRANT ALL ON moodle.* TO 'moodledbuser'@'localhost' IDENTIFIED BY '$moodledbpass';
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

echo "Database credentials:" > $credfile
echo "User: root" >> $credfile
echo "Password: $mariadbpass" >> $credfile
echo "Listen IP: 127.0.0.1" >> $credfile
echo "Moodle DB Name: moodle" >> $credfile
echo "Moodle DB User: moodledbuser" >> $credfile
echo "Moodle DB User Password: $moodledbpass" >> $credfile

yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update --exclude=kernel*
yum -y erase php-common
yum -y install httpd mod_php71w php71w-common php71w-mbstring \
php71w-xmlrpc php71w-soap php71w-gd php71w-xml php71w-intl \
php71w-mysqlnd php71w-cli php71w-mcrypt php71w-ldap php71w-opcache \
python-certbot-apache mod_evasive mod_ssl

crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M
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

systemctl enable httpd
systemctl restart httpd

cat<<EOF>/etc/cron.d/letsencrypt-renew-crontab
#
#
# Letsencrypt automated renewal
#
# Every day at 01:30am
#
30 01 * * * root /usr/bin/certbot renew > /var/log/le-renew.log 2>&1
#
EOF

systemctl reload crond

sed -i 's/^/#&/g' /etc/httpd/conf.d/welcome.conf
sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/httpd/conf/httpd.conf

wget https://download.moodle.org/stable33/moodle-latest-33.tgz -O /root/moodle-latest-33.tgz
tar -xzvf /root/moodle-latest-33.tgz -C /usr/local/src/
rsync -avP /usr/local/src/moodle/ /var/www/html/
chown -R root.root /var/www/html
rm -rf /root/moodle-latest-33.tgz /usr/local/src/moodle

export publicip=`curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`

if [ $publicip ]
then
	export moodleip=$publicip
else
	
	export moodleip=`ip route get 1 | awk '{print $NF;exit}'`
fi

echo "Moodle IP: $moodleip"

echo "Moodle URL: https://$moodleip" >> $credfile

cat<<EOF>/var/www/html/config.php
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();
\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '127.0.0.1';
\$CFG->dbname    = 'moodle';
\$CFG->dbuser    = 'moodledbuser';
\$CFG->dbpass    = '$moodledbpass';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '3306',
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci',
);
\$CFG->wwwroot   = 'https://$moodleip';
\$CFG->dataroot  = '/var/www/moodledata';
\$CFG->directorypermissions = 02777;
\$CFG->admin = 'admin';
require_once(__DIR__ . '/lib/setup.php');
EOF

mkdir /var/www/moodledata
chown -R apache.apache /var/www/moodledata
chmod -R 755 /var/www/moodledata

chmod 644 /var/www/html/config.php

systemctl enable httpd.service
systemctl restart httpd.service

cat<<EOF>/etc/cron.d/moodle-crontab
* * * * *  apache  /usr/bin/php /var/www/html/admin/cli/cron.php >/dev/null
EOF

systemctl reload crond

sync
sleep 10

finalcheck=`ss -ltn|grep -c :443`

if [ $finalcheck == "1" ]
then
	echo "Your MOODLE Server is ready. See your database credentiales at $credfile" &>>$lgfile
	echo "" &>>$lgfile
	cat $credfile &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "MOODLE Server install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
