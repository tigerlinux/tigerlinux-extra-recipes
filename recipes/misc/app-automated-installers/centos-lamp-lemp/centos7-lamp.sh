#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# LAMP Server Installation Script
# Rel 1.5
# For usage on centos7 64 bits machines.
# (includes phpmyadmin installation as an option)

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/lamp-server-automated-installer.log"
credfile="/root/lamp-server-mariadb-credentials.txt"
echo "Start Date/Time: `date`" &>>$lgfile
export debug="no"
# Select your php version: Supported options:
# 56 for "php 5.6"
# 71 for "php" 7.1
# anything else for "distro" included php version
export phpversion="71"
# If you want phpmyadmin, let next variable to "yes"
phpmyadmin="yes"

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

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export mariadbpass=`openssl rand -hex 10`
export mariadbip='0.0.0.0'

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


yum -y install epel-release &>>$lgfile
yum -y install device-mapper-persistent-data &>>$lgfile

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

cat <<EOF >/etc/my.cnf.d/server-lamp.cnf
[mysqld]
binlog_format = ROW
default-storage-engine = innodb
innodb_autoinc_lock_mode = 2
query_cache_type = 0
query_cache_size = 0
bind-address = $mariadbip
max_allowed_packet = 1024M
max_connections = 1000
innodb_doublewrite = 1
innodb_log_file_size = 100M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table
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
echo "Listen IP: $mariadbip" >> $credfile

case $phpversion in
56)
	yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
	yum -y update --exclude=kernel* &>>$lgfile
	yum -y erase php-common
	yum -y install httpd mod_php56w php56w php56w-opcache \
	php56w-pear php56w-pdo php56w-xml php56w-pdo_dblib \
	php56w-mbstring php56w-mysqlnd php56w-mcrypt php56w-fpm \
	php56w-bcmath php56w-gd php56w-cli &>>$lgfile
	;;
71)
	yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
	yum -y update --exclude=kernel* &>>$lgfile
	yum -y erase php-common
	yum -y install httpd mod_php71w php71w php71w-opcache \
	php71w-pear php71w-pdo php71w-xml php71w-pdo_dblib \
	php71w-mbstring php71w-mysqlnd php71w-mcrypt php71w-fpm \
	php71w-bcmath php71w-gd php71w-cli &>>$lgfile
	;;
*)
	yum -y update --exclude=kernel* &>>$lgfile
	yum -y install httpd php-common mod_php php-pear php-opcache \
	php-pdo php-mbstring php-mysqlnd php-xml php-bcmath \
	php-json php-cli php-gd &>>$lgfile
	;;
esac

crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M
mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

if [ -f /usr/share/zoneinfo/$mytimezone ]
then
	crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
else
	crudini --set /etc/php.ini PHP date.timezone "UTC"
fi

yum -y install python-certbot-apache mod_evasive mod_ssl &>>$lgfile


cat <<EOF >/var/www/html/index.html
<!DOCTYPE html>
<html>
<body>
<h1>LAMP SERVER READY!!!</h1>
<p>This is a TEST page</p>
</body>
</html>
EOF

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

if [ $phpmyadmin == "yes" ]
then
	export phpmyadminpass=`openssl rand -hex 10`
	wget https://files.phpmyadmin.net/phpMyAdmin/4.7.4/phpMyAdmin-4.7.4-all-languages.tar.gz -O /root/phpMyAdmin-4.7.4-all-languages.tar.gz
	tar -xzvf /root/phpMyAdmin-4.7.4-all-languages.tar.gz -C /var/www/
	rm -f /root/phpMyAdmin-4.7.4-all-languages.tar.gz
	mv /var/www/phpMyAdmin* /var/www/phpmyadmin
	cat<<EOF>/var/www/phpmyadmin/config.inc.php
<?php
\$cfg['blowfish_secret'] = '`openssl rand -hex 16`';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = '127.0.0.1';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '/var/www/phpmyadmin/uploads';
\$cfg['SaveDir'] = '/var/www/phpmyadmin/saves';
\$cfg['Servers'][\$i]['controlhost'] = '127.0.0.1';
\$cfg['Servers'][\$i]['controlport'] = '3306';
\$cfg['Servers'][\$i]['controluser'] = 'phpmyadminuser';
\$cfg['Servers'][\$i]['controlpass'] = '$phpmyadminpass';
\$cfg['Servers'][\$i]['pmadb'] = 'phpmyadmin';
\$cfg['Servers'][\$i]['bookmarktable'] = 'pma__bookmark';
\$cfg['Servers'][\$i]['relation'] = 'pma__relation';
\$cfg['Servers'][\$i]['table_info'] = 'pma__table_info';
\$cfg['Servers'][\$i]['table_coords'] = 'pma__table_coords';
\$cfg['Servers'][\$i]['pdf_pages'] = 'pma__pdf_pages';
\$cfg['Servers'][\$i]['column_info'] = 'pma__column_info';
\$cfg['Servers'][\$i]['history'] = 'pma__history';
\$cfg['Servers'][\$i]['table_uiprefs'] = 'pma__table_uiprefs';
\$cfg['Servers'][\$i]['tracking'] = 'pma__tracking';
\$cfg['Servers'][\$i]['userconfig'] = 'pma__userconfig';
\$cfg['Servers'][\$i]['recent'] = 'pma__recent';
\$cfg['Servers'][\$i]['favorite'] = 'pma__favorite';
\$cfg['Servers'][\$i]['users'] = 'pma__users';
\$cfg['Servers'][\$i]['usergroups'] = 'pma__usergroups';
\$cfg['Servers'][\$i]['navigationhiding'] = 'pma__navigationhiding';
\$cfg['Servers'][\$i]['savedsearches'] = 'pma__savedsearches';
\$cfg['Servers'][\$i]['central_columns'] = 'pma__central_columns';
\$cfg['Servers'][\$i]['designer_settings'] = 'pma__designer_settings';
\$cfg['Servers'][\$i]['export_templates'] = 'pma__export_templates';
EOF
	mkdir -p /var/www/phpmyadmin/uploads
	mkdir -p /var/www/phpmyadmin/saves
	chown -R root.root /var/www/phpmyadmin
	chown -R apache.apache /var/www/phpmyadmin/uploads /var/www/phpmyadmin/saves
	cat <<EOF>/etc/httpd/conf.d/phpmyadmin.conf
Alias /phpmyadmin /var/www/phpmyadmin
<Directory /var/www/phpmyadmin/>
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>
EOF
	
	cat<<EOF >/root/os-db.sql
CREATE DATABASE IF NOT EXISTS phpmyadmin default character set utf8;
GRANT ALL ON phpmyadmin.* TO 'phpmyadminuser'@'%' IDENTIFIED BY '$phpmyadminpass';
GRANT ALL ON phpmyadmin.* TO 'phpmyadminuser'@'127.0.0.1' IDENTIFIED BY '$phpmyadminpass';
GRANT ALL ON phpmyadmin.* TO 'phpmyadminuser'@'localhost' IDENTIFIED BY '$phpmyadminpass';
FLUSH PRIVILEGES;
EOF
	mysql < /root/os-db.sql
	mysql -u root -h 127.0.0.1 -P 3306 -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
	mysql -u root --protocol=socket --socket=/var/lib/mysql/mysql.sock -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql

	mysql -u root -h 127.0.0.1 -P 3306 -p`grep password /root/.my.cnf |cut -d\" -f2` < /var/www/phpmyadmin/sql/create_tables.sql
	mysql < /var/www/phpmyadmin/sql/create_tables.sql
	mysql -u root --protocol=socket --socket=/var/lib/mysql/mysql.sock -p`grep password /root/.my.cnf |cut -d\" -f2` < /var/www/phpmyadmin/sql/create_tables.sql
	
	echo "PHPMYADMIN URL: http://`ip route get 1 | awk '{print $NF;exit}'`/phpmyadmin" >> $credfile
	rm -f /root/os-db.sql
fi

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

systemctl restart httpd crond

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod 755 /usr/local/bin/wp

finalcheck=`curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1/|grep -c 200`

if [ $finalcheck == "1" ]
then
	echo "Ready. Your LAMP Server is ready. See your database credentiales at $credfile" &>>$lgfile
	echo "" &>>$lgfile
	cat $credfile &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "LAMP Server install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
