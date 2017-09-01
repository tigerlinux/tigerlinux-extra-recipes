#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# ZoneMinder Setup for Centos 7 64 bits
# Release 1.0
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/zm-automated-install.log"
echo "Start Date/Time: `date`" &>>$lgfile
credentialsfile="/root/zm-credentials.txt"
export OSFlavor='unknown'

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname
	setenforce 0
	sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
	yum -y erase firewalld
else
	echo "Not a centos server. Aborting!" &>>$lgfile
	exit 0
fi

if [ `uname -p 2>/dev/null|grep x86_64|head -n1|wc -l` != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export mariadbpass=`openssl rand -hex 10`
export zmdbpass=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for ZoneMinder. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

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

amicen=`lsb_release -i|grep -ic centos`
crel7=`lsb_release -r|awk '{print $2}'|grep ^7.|wc -l`
if [ $amicen != "1" ] || [ $crel7 != "1" ]
then
	echo "This is NOT a Centos 7 machine. Aborting !"
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
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

yum -y update --exclude=kernel*

yum -y install mariadb-server mariadb crudini

echo "" > /etc/my.cnf.d/server-zoneminder.cnf

crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld binlog_format ROW
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld default-storage-engine innodb
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld innodb_autoinc_lock_mode 2
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld query_cache_type 0
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld query_cache_size 0
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld bind-address 127.0.0.1
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld max_allowed_packet 1024M
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld max_connections 1000
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld innodb_doublewrite 1
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld innodb_log_file_size 100M
crudini --set /etc/my.cnf.d/server-zoneminder.cnf mysqld innodb_flush_log_at_trx_commit 2
echo "innodb_file_per_table" >> /etc/my.cnf.d/server-zoneminder.cnf

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
CREATE DATABASE zm default character set utf8;
GRANT ALL PRIVILEGES ON zm.* TO 'zoneminder'@'localhost' IDENTIFIED BY  '$zmdbpass';
GRANT ALL PRIVILEGES ON zm.* TO 'zoneminder'@'127.0.0.1' IDENTIFIED BY  '$zmdbpass';
GRANT ALL PRIVILEGES ON zm.* TO 'zoneminder'@'%' IDENTIFIED BY  '$zmdbpass';
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql

sleep 5
sync

cat<<EOF >/root/.my.cnf
[client]
user = "root"
password = "$mariadbpass"
host = "localhost"
EOF

chmod 0600 /root/.my.cnf

rm -f /root/os-db.sql

yum -y install --nogpgcheck http://zmrepo.zoneminder.com/el/7/x86_64/zmrepo-7-9.el7.centos.noarch.rpm

yum -y update --exclude=kernel*
yum -y install httpd mod_ssl php-common mod_php php-pear \
php-opcache php-pdo php-mbstring php-mysqlnd php-xml \
php-bcmath php-json php-cli php-gd \
perl-Time-HiRes libjpeg-turbo perl-Convert-BinHex \
perl-Date-Manip perl-DBD-MySQL perl-DBI \
perl-Email-Date-Format perl-IO-stringy perl-IO-Zlib \
perl-MailTools perl-MIME-Lite perl-MIME-tools perl-MIME-Types \
perl-Module-Load perl-Package-Constants \
perl-Time-HiRes perl-TimeDate perl-YAML-Syck
	
crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M
crudini --set /etc/php.ini PHP memory_limit 256M
	
export mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

if [ -f /usr/share/zoneinfo/$mytimezone ]
then
	crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
else
	crudini --set /etc/php.ini PHP date.timezone "UTC"
	export $mytimezone="Etc/UTC"
fi

systemctl restart httpd
systemctl enable httpd

yum -y install zoneminder

mysql -u root --protocol=socket --socket=/var/lib/mysql/mysql.sock -p`grep password /root/.my.cnf |cut -d\" -f2` < /usr/share/zoneminder/db/zm_create.sql

sed -r -i "s/ZM_DB_HOST=localhost/ZM_DB_HOST=127.0.0.1/g" /etc/zm/zm.conf
sed -r -i "s/ZM_DB_USER=zmuser/ZM_DB_USER=zoneminder/g" /etc/zm/zm.conf
sed -r -i "s/ZM_DB_PASS=zmpass/ZM_DB_PASS=$zmdbpass/g" /etc/zm/zm.conf

systemctl restart httpd
sleep 5
sync
systemctl restart zoneminder
systemctl enable zoneminder

cat<<EOF >/var/www/html/index.html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/zm">
</HEAD>
<BODY>
</BODY>
</HTML>
EOF

echo "ZM Credentials" > $credentialsfile
echo "ZM DB Name: zm, ZM DN User: zoneminder, ZM DB User Password: $zmdbpass" >> $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
for myip in $allipaddr
do
	echo "URL: https://$myip" >> $credentialsfile
done

if [ `ss -ltn|grep -c :443` -gt "0" ] && [ `ps -ef|grep zmdc.pl|grep -v grep|wc -l` -gt 0 ]
then
	echo "Your ZoneMinder server is ready. See your credentials at $credentialsfile" &>>$lgfile
	cat $credentialsfile &>>$lgfile
else
	echo "ZM Server install failed" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END