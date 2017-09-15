#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# LimeSurvey with MariaDB 10.1 DB Backend installation script
# Rel 1.2
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/limesurvey-automated-installer.log"
credentialsfile="/root/limesurvey-and-mariadb-access-info.txt"
echo "Start Date/Time: `date`" &>>$lgfile
debug="no"
limesurveyurl="https://www.limesurvey.org/stable-release?download=2104:limesurvey2673%20170728targz"

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname &>>$lgfile
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
export lmdbpass=`openssl rand -hex 10`
export limeadmpass=`openssl rand -hex 10`


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
yum -y install firewalld &>>$lgfile
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

yum -y install epel-release &>>$lgfile
# Kill packet.net repositories if detected here.
yum -y install yum-utils &>>$lgfile
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

yum -y update --exclude=kernel* &>>$lgfile
yum -y install MariaDB MariaDB-server MariaDB-client galera crudini &>>$lgfile

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
CREATE DATABASE limesurveydb default character set utf8;
GRANT ALL ON limesurveydb.* TO 'limesurveydbuser'@'%' IDENTIFIED BY '$lmdbpass';
GRANT ALL ON limesurveydb.* TO 'limesurveydbuser'@'127.0.0.1' IDENTIFIED BY '$lmdbpass';
GRANT ALL ON limesurveydb.* TO 'limesurveydbuser'@'localhost' IDENTIFIED BY '$lmdbpass';
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

echo "LimeSurvey Admin user: admin" > $credentialsfile
echo "LimeSurvey Admin user password: $limeadmpass" >> $credentialsfile
echo "LimeSurvey URL Admin: http://`ip route get 1 | awk '{print $NF;exit}'`/limesurvey/admin" >> $credentialsfile
echo "Main LimeSurvey URL: http://`ip route get 1 | awk '{print $NF;exit}'`" >> $credentialsfile
echo "MariaDB Main Admin User: root" >> $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile
echo "LimeSurvey DB name: limesurveydb, DB User: limesurveydbuser, password: $lmdbpass" >> $credentialsfile

yum -y install php-cli php php-gd httpd gd \
perl-Archive-Tar perl-MIME-Lite perl-MIME-tools \
perl-Date-Manip perl-PHP-Serialization \
perl-Archive-Zip perl-Module-Load \
php php-mysqlnd php-pear php-pear-DB php-mbstring \
php-process perl-Time-HiRes perl-Net-SFTP-Foreign \
perl-Expect libjpeg-turbo perl-Convert-BinHex \
perl-Date-Manip perl-DBD-MySQL perl-DBI \
perl-Email-Date-Format perl-IO-stringy perl-IO-Zlib \
perl-MailTools perl-MIME-Lite perl-MIME-tools perl-MIME-Types \
perl-Module-Load perl-Package-Constants \
perl-Time-HiRes perl-TimeDate perl-YAML-Syck php \
python-certbot-apache mod_evasive mod_ssl &>>$lgfile

crudini --set /etc/php.ini PHP upload_max_filesize 60M
crudini --set /etc/php.ini PHP post_max_size 60M

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

wget $limesurveyurl -O /root/limesurvey.tgz &>>$lgfile

tar -xzvf /root/limesurvey.tgz -C /var/www/html/ &>>$lgfile
chown -R root.root /var/www/html/limesurvey
chown -R apache.apache /var/www/html/limesurvey/application/config/
chown -R apache.apache /var/www/html/limesurvey/upload/
chown -R apache.apache /var/www/html/limesurvey/tmp/
rm -f /root/limesurvey.tar.gz

cp /var/www/html/limesurvey/application/config/config-sample-mysql.php /var/www/html/limesurvey/application/config/config.php
chown apache.apache /var/www/html/limesurvey/application/config/config.php

sed -r -i 's/dbname=limesurvey/dbname=limesurveydb/g' /var/www/html/limesurvey/application/config/config.php
sed -r -i "s/'username'\ =>\ 'root'/'username'\ =>\ 'limesurveydbuser'/g" /var/www/html/limesurvey/application/config/config.php
sed -r -i "s/'password'\ =>\ ''/'password'\ =>\ '$lmdbpass'/g" /var/www/html/limesurvey/application/config/config.php



cd /var/www/html/limesurvey/application/commands/
php console.php install admin $limeadmpass Admin nobody@none.dom
cd /

if [ ! -f /var/www/html/limesurvey/installer/sql/create-mysql.sql ]
then
	echo "LimeSurvey installation failed. Aborting !." &>>$lgfile
	exit 0
fi

echo "Alias /limesurvey /var/www/html/limesurvey" > /etc/httpd/conf.d/limesurvey.conf
echo "<location /limesurvey>" >> /etc/httpd/conf.d/limesurvey.conf
echo "  Options +FollowSymlinks -MultiViews -Indexes" >> /etc/httpd/conf.d/limesurvey.conf
echo "</location>" >> /etc/httpd/conf.d/limesurvey.conf

cat <<EOF>/var/www/html/index.html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/limesurvey">
</HEAD>
<BODY>
</BODY>
</HTML>
EOF

systemctl restart httpd
systemctl enable httpd

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

if [ `mysqladmin -h localhost -u root -p$mariadbpass ping|grep -ci alive` == "1" ]
then
	echo "LimeSurvey. Credentials file: $credentialsfile" &>>$lgfile
	echo "Your credentials:" &>>$lgfile
	cat $credentialsfile  &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "LimeSurvey installation failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi

# END