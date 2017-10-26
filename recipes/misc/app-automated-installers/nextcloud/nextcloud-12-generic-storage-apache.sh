#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# NextCloud 12 Automated Installation Script - Apache version
# Rel 1.1
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export OSFlavor='unknown'
export lgfile="/var/log/nextcloud-automated-installer.log"
echo "Start Date/Time: `date`" &>>$lgfile

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools \
	git findutils iproute grep openssh sed gawk openssl which xz bzip2 \
	util-linux procps-ng which lvm2 sudo hostname &>>$lgfile
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

if [ `uname -p 2>/dev/null|grep x86_64|head -n1|wc -l` != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export mariadbpass=`openssl rand -hex 10`
export nextcloudadminpass=`openssl rand -hex 10`

if [ `lscpu -a --extended|grep -ic yes` -lt "1" ] || [ `free -m -t|grep -i mem:|awk '{print $2}'` -lt "900" ] || [ `df -k --output=avail /usr|tail -n 1` -lt "5000000" ] || [ `df -k --output=avail /var|tail -n 1` -lt "5000000" ]
then
	echo "Not enough hardware for NextCloud. Aborting!" &>>$lgfile
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

# Kill packet.net repositories if detected here.
yum -y install yum-utils &>>$lgfile
repotokill=`yum repolist|grep -i ^packet|cut -d/ -f1`
for myrepo in $repotokill
do
	echo "Disabling repo: $myrepo" &>>$lgfile
	yum-config-manager --disable $myrepo &>>$lgfile
done

mkdir -p /var/nextcloud-sto-data

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

if [ -z $nxsto ]
then
	echo "No usable extra storage found" &>>$lgfile
else
	echo "Extra storage found: $nxsto" &>>$lgfile
	cat /etc/fstab > /etc/fstab.ORG
	umount /dev/$nxsto >/dev/null 2>&1
	cat /etc/fstab |egrep -v "($nxsto|nextcloudsto)" > /etc/fstab.NEW
	cat /etc/fstab.NEW > /etc/fstab
	mkfs.ext4 -F -F -L nextcloudsto /dev/$nxsto
	echo 'LABEL=nextcloudsto /var/nextcloud-sto-data ext4 defaults 0 0' >> /etc/fstab
	mount /var/nextcloud-sto-data
fi

yum -y install epel-release &>>$lgfile
yum -y install device-mapper-persistent-data &>>$lgfile

cat <<EOF >/etc/yum.repos.d/mariadb101.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum -y update --exclude=kernel* &>>$lgfile
yum -y install MariaDB MariaDB-server MariaDB-client galera crudini &>>$lgfile

cat <<EOF >/etc/my.cnf.d/server-nextcloud.cnf
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
CREATE DATABASE nextcloud;
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

yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update --exclude=kernel* &>>$lgfile
yum -y erase php-common
yum -y install httpd mod_php71w php71w php71w-opcache \
php71w-pear php71w-pdo php71w-xml php71w-pdo_dblib \
php71w-mbstring php71w-mysqlnd php71w-mcrypt php71w-fpm \
php71w-bcmath php71w-gd php71w-cli php71w-ldap \
redis php71w-pecl-memcached php71w-pecl-redis \
mod_evasive mod_ssl unzip &>>$lgfile

ln -s /usr/bin/php /usr/local/bin/php

crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M

cat <<EOF>/etc/php.d/opcache.ini
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.memory_consumption=128
opcache.save_comments=1
opcache.revalidate_freq=1
opcache.blacklist_filename=/etc/php.d/opcache*.blacklist
opcache.fast_shutdown=1
EOF

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
Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
EOF

sed -r -i 's/^SSLProtocol.*/SSLProtocol\ all\ -SSLv2\ -SSLv3/g' /etc/httpd/conf.d/ssl.conf
sed -r -i 's/^SSLCipherSuite.*/SSLCipherSuite\ HIGH:MEDIUM:!aNULL:\!MD5:\!SSLv3:\!SSLv2/g' /etc/httpd/conf.d/ssl.conf
sed -r -i 's/^\#SSLHonorCipherOrder.*/SSLHonorCipherOrder\ on/g' /etc/httpd/conf.d/ssl.conf

systemctl enable redis
systemctl start redis

wget https://download.nextcloud.com/server/releases/latest-12.zip -O /root/latest-12.zip &>>$lgfile
unzip /root/latest-12.zip -d /var/www/html/ &>>$lgfile
rm -f /root/latest-12.zip

cat <<EOF >/var/www/html/index.html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/nextcloud">
</HEAD>
<BODY>
</BODY>
</HTML>
EOF

if [ ! -f /var/www/html/nextcloud/occ ]
then
	echo "Nextcloud Installation FAILED. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

chown -R apache.apache /var/www/html/nextcloud
chown -R apache.apache /var/nextcloud-sto-data

sudo -u apache /usr/local/bin/php \
/var/www/html/nextcloud/occ maintenance:install \
--database "mysql" \
--database-host 127.0.0.1:3306 \
--database-name "nextcloud"  \
--database-user "root" \
--database-pass "$mariadbpass" \
--admin-user "admin" \
--admin-pass "$nextcloudadminpass" \
--data-dir="/var/nextcloud-sto-data" &>>$lgfile

cat<<EOF >/root/nextcloud-credentials.txt
Nextcloud admin user: admin
Nextcloud admin pass: $nextcloudadminpass
Access nextcloud web interface trough any of the following URL's:
EOF

allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
mycount=1

for myip in $allipaddr
do
	sudo -u apache /usr/local/bin/php \
	/var/www/html/nextcloud/occ \
	config:system:set \
	trusted_domains $mycount \
	--value=$myip
	mycount=$[mycount+1]
	echo "- http://$myip" >> /root/nextcloud-credentials.txt
done
echo "Final counter: $mycount" &>>$lgfile

sudo -u apache /usr/local/bin/php \
/var/www/html/nextcloud/occ \
config:system:set \
trusted_domains $mycount \
--value=`hostname`
echo "- http://`hostname`" >> /root/nextcloud-credentials.txt
mycount=$[mycount+1]

publicip=`curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`
publichostname=`curl http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null`

if [ -z $publicip ]
then
	echo "No metadata-based public IP detected" &>>$lgfile
else
	echo $publicip
	sudo -u apache /usr/local/bin/php \
	/var/www/html/nextcloud/occ \
	config:system:set \
	trusted_domains $mycount \
	--value=$publicip
	echo "- http://$publicip" >> /root/nextcloud-credentials.txt
	mycount=$[mycount+1]
fi

if [ -z $publichostname ]
then
	echo "No metadata-based public hostname detected" &>>$lgfile
else
	sudo -u apache /usr/local/bin/php \
	/var/www/html/nextcloud/occ \
	config:system:set \
	trusted_domains $mycount \
	--value=$publichostname
	echo "- http://$publichostname" >> /root/nextcloud-credentials.txt
	mycount=$[mycount+1]
fi

cat /var/www/html/nextcloud/config/config.php > /root/config.php-original

sed -i '$ d' /var/www/html/nextcloud/config/config.php

cat <<EOF >>/var/www/html/nextcloud/config/config.php
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'memcache.local' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => '127.0.0.1',
    'port' => 6379,
    'timeout' => 0.0,
    'password' => '', // Optional, if not defined no password will be used.
  ),
);
EOF

systemctl enable httpd
systemctl restart httpd

sudo -u apache /usr/local/bin/php \
/var/www/html/nextcloud/occ \
user:delete admin

export OC_PASS="$nextcloudadminpass"
su -s /bin/bash apache -c '/usr/local/bin/php \
/var/www/html/nextcloud/occ \
user:add --password-from-env \
--group="admin" \
--display-name="NextCloud SuperAdmin" \
admin
'

yum -y install python-certbot-apache &>>$lgfile

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

cat<<EOF>/etc/cron.d/nextcloud-job-crontab
#
#
# Nextcloud cron job
#
# Every 15 minutes
#
*/15 * * * * apache /usr/bin/php -f /var/www/html/nextcloud/cron.php
#
EOF

sudo -u apache /usr/local/bin/php /var/www/html/nextcloud/cron.php

systemctl reload crond

finalcheck=`sudo -u apache /usr/local/bin/php /var/www/html/nextcloud/occ config:system:get version 2>&1|grep -c ^12.`

if [ $finalcheck == "1" ]
then
	export nextcloudversion=`sudo -u apache /usr/local/bin/php /var/www/html/nextcloud/occ config:system:get version 2>&1`
	echo "NEXTCLOUD VERSION: $nextcloudversion" >> /root/nextcloud-credentials.txt
	echo "Ready. Your nextcloud access credentials are stored in the file /root/nextcloud-credentials.txt:" &>>$lgfile
	echo "" &>>$lgfile
	cat /root/nextcloud-credentials.txt &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "Nextcloud installation failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
