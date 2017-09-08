#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# PHPMYFAQ with Dockerized MariaDB 10.1 Installation Script
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.1
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/phpmyfaq-install.log"
credentialsfile="/root/phpmyfaq-access-info.txt"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname rsync
	setenforce 0
	sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
fi

if [ -f /etc/debian_version ]
then
	OSFlavor='debian-based'
	apt-get -y clean
	apt-get -y update

	cat<<EOF >/etc/apt/apt.conf.d/99aptget-reallyunattended
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF

	export DEBIAN_FRONTEND=noninteractive
	apt-get \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		-y install \
		coreutils grep debianutils base-files lsb-release curl wget net-tools git \
		iproute openssh-client sed openssl xz-utils bzip2 util-linux procps mount \
		lvm2 hostname sudo rsync
fi

export mariadbport='3306'
export mariadbip='127.0.0.1'
export mariadbpass=`openssl rand -hex 10`
export phpdbuser="phpmyfaquser"
export phpdbname="phpmyfaqdb"
export phpdbuserpass=`openssl rand -hex 10`

echo "MariaDB User: root" >> $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile
echo "MariaDB listen PORT: $mariadbport" >> $credentialsfile
echo "" >> $credentialsfile
echo "ENTER TO YOUR PHPMYFAQ SITE AND FINISH THE INSTALLATION" >> $credentialsfile
echo "WITH THE FOLLOWING DATABASE INFORMATION" >> $credentialsfile
echo "PHPMYFAQ Database type: MySQL/MariaDB Class" >> $credentialsfile
echo "PHPMYFAQ Database Host: 127.0.0.1" >> $credentialsfile
echo "PHPMYFAQ Database User: $phpdbuser" >> $credentialsfile
echo "PHPMYFAQ Database Password: $phpdbuserpass" >> $credentialsfile
echo "PHPMYFAQ Database Name: $phpdbname" >> $credentialsfile
echo "phpmyfaq URL: http://`ip route get 1 | awk '{print $NF;exit}'`" >> $credentialsfile

if [ `uname -p 2>/dev/null|grep x86_64|head -n1|wc -l` != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for phpmyfaq. Aborting!" &>>$lgfile
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

case $OSFlavor in
centos-based)
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
	yum-config-manager \
	--add-repo \
	https://download.docker.com/linux/centos/docker-ce.repo

	yum -y install firewalld
	systemctl enable firewalld
	systemctl restart firewalld
	firewall-cmd --zone=public --add-service=http --permanent
	firewall-cmd --zone=public --add-service=https --permanent
	firewall-cmd --zone=public --add-service=ssh --permanent
	firewall-cmd --reload

	yum -y update --exclude=kernel*
	yum -y install docker-ce

	systemctl start docker
	systemctl enable docker
	
	yum -y install mariadb crudini
	
	yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
	yum -y erase php*
	yum -y update --exclude=kernel*
	yum -y install httpd mod_php71w php71w php71w-opcache \
	php71w-pear php71w-pdo php71w-xml php71w-pdo_dblib \
	php71w-mbstring php71w-mysqlnd php71w-mcrypt php71w-fpm \
	php71w-bcmath php71w-gd php71w-cli dos2unix \
	perl-Time-HiRes libjpeg-turbo perl-Convert-BinHex \
	perl-Date-Manip perl-DBD-MySQL perl-DBI \
	perl-Email-Date-Format perl-IO-stringy perl-IO-Zlib \
	perl-MailTools perl-MIME-Lite perl-MIME-tools perl-MIME-Types \
	perl-Module-Load perl-Package-Constants \
	perl-Time-HiRes perl-TimeDate perl-YAML-Syck \
	mod_evasive mod_ssl
	
	export apacheaccount="apache"
	
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
	
	cat <<EOF >/etc/httpd/conf.d/extra-security.conf
ServerTokens ProductOnly
FileETag None
ExtendedStatus Off
UseCanonicalName Off
TraceEnable off
ServerSignature Off
<FilesMatch "^(xmlrpc\.php|wp-trackback\.php)">
Order Deny,Allow
Deny from all
</FilesMatch>
EOF

	sed -r -i 's/^SSLProtocol.*/SSLProtocol\ all\ -SSLv2\ -SSLv3/g' /etc/httpd/conf.d/ssl.conf
	sed -r -i 's/^SSLCipherSuite.*/SSLCipherSuite\ HIGH:MEDIUM:!aNULL:\!MD5:\!SSLv3:\!SSLv2/g' /etc/httpd/conf.d/ssl.conf
	sed -r -i 's/^\#SSLHonorCipherOrder.*/SSLHonorCipherOrder\ on/g' /etc/httpd/conf.d/ssl.conf
	
	systemctl restart httpd
	systemctl enable httpd

	;;
debian-based)
	amiubuntu1604=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*16.04.\*LTS|head -n1|wc -l`
	if [ $amiubuntu1604 != "1" ]
	then
		echo "This is NOT an Ubuntu 16.04LTS machine. Aborting !" &>>$lgfile
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi
	apt-get -y update
	apt-get -y remove docker docker-engine
	apt-get -y install \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

	DEBIAN_FRONTEND=noninteractive apt-get -y install ufw
	systemctl enable ufw
	systemctl restart ufw
	ufw --force default deny incoming
	ufw --force default allow outgoing
	ufw allow ssh/tcp
	ufw allow http/tcp
	ufw allow https/tcp
	ufw --force enable

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"

	apt-get -y update
	apt-get -y install docker-ce
	systemctl enable docker
	systemctl start docker
	systemctl restart docker
	
	DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-client crudini
	
	DEBIAN_FRONTEND=noninteractive apt-get -y install php-curl php-gd \
	php-mbstring php-mcrypt php-xml php-xmlrpc apache2 php \
	libapache2-mod-php php-mysql dos2unix php-zip php-pclzip \
	libjpeg-turbo8 libapache2-mod-evasive

	cat <<EOF >/etc/apache2/conf-available/security.conf
ServerTokens ProductOnly
FileETag None
ExtendedStatus Off
UseCanonicalName Off
TraceEnable off
ServerSignature Off
<FilesMatch "^(xmlrpc\.php|wp-trackback\.php)">
Order Deny,Allow
Deny from all
</FilesMatch>
EOF

	a2enconf security.conf
	a2ensite default-ssl.conf
	a2enmod ssl
	a2enmod evasive
	
	export apacheaccount="www-data"
	
	ln -s /etc/php/7.0/apache2/php.ini /etc/php.ini
	
	crudini --set /etc/php.ini PHP upload_max_filesize 100M
	crudini --set /etc/php.ini PHP post_max_size 100M
	crudini --set /etc/php.ini PHP memory_limit 256M
	
	mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`
	
	a2enconf phpmyfaq-extra.conf

	if [ -f /usr/share/zoneinfo/$mytimezone ]
	then
		crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
	else
		crudini --set /etc/php.ini PHP date.timezone "UTC"
		export $mytimezone="Etc/UTC"
	fi
	
	systemctl restart apache2
	systemctl enable apache2

	;;
unknown)
	echo "Unkown/Unsupported operating system. Aborting!" &>>$lgfile
	exit 0
	;;
esac

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf

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

mkdir -p /var/phpmyfaq-storage

if [ -z $nxsto ]
then
	echo "No usable extra storage found" &>>$lgfile
else
	echo "Extra storage found: $nxsto" &>>$lgfile
	cat /etc/fstab > /etc/fstab.ORG
	umount /dev/$nxsto >/dev/null 2>&1
	cat /etc/fstab |egrep -v "($nxsto|phpmyfaqsto)" > /etc/fstab.NEW
	cat /etc/fstab.NEW > /etc/fstab
	mkfs.ext4 -F -F -L phpmyfaqsto /dev/$nxsto
	echo 'LABEL=phpmyfaqsto /var/phpmyfaq-storage ext4 defaults 0 0' >> /etc/fstab
	mount /var/phpmyfaq-storage
	mv /var/www/html /var/phpmyfaq-storage/html
	ln -s /var/phpmyfaq-storage/html /var/www/html
fi

rm -f /var/www/html/index.html

mkdir -p /var/phpmyfaq-storage/mariadb01/data
mkdir -p /var/phpmyfaq-storage/mariadb01/conf.d
rm -rf /var/lib/mysql
rm -rf /var/phpmyfaq-storage/mariadb01/data/*
ln -s /var/phpmyfaq-storage/mariadb01/data /var/lib/mysql

cat<<EOF >/var/phpmyfaq-storage/mariadb01/conf.d/server.cnf
[mysqld]
max_connections = 100
max_allowed_packet = 1024M
thread_cache_size = 128
sort_buffer_size = 4M
bulk_insert_buffer_size = 16M
max_heap_table_size = 32M
tmp_table_size = 32M
[mysqldump]
max_allowed_packet = 1024M
EOF

docker pull mariadb:10.1

docker run --name mariadb-engine-docker \
-v /var/phpmyfaq-storage/mariadb01/conf.d:/etc/mysql/conf.d \
-v /var/phpmyfaq-storage/mariadb01/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="$mariadbpass" \
-p $mariadbip:$mariadbport:3306 \
-d mariadb:10.1

sleep 20

docker ps -a
docker stop mariadb-engine-docker

cat<<EOF >/var/phpmyfaq-storage/mariadb01/conf.d/server.cnf
[mysqld]
socket = /var/lib/mysql/mysql.sock
max_connections = 100
max_allowed_packet = 1024M
thread_cache_size = 128
sort_buffer_size = 4M
bulk_insert_buffer_size = 16M
max_heap_table_size = 32M
tmp_table_size = 32M
[mysqldump]
max_allowed_packet = 1024M
EOF

docker start mariadb-engine-docker
docker ps -a

echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"$mariadbpass\""  >> /root/.my.cnf 
echo "host = \"localhost\""  >> /root/.my.cnf
echo "socket = \"/var/lib/mysql/mysql.sock\""  >> /root/.my.cnf
chmod 600 /root/.my.cnf

cat<<EOF >/etc/systemd/system/docker-mariadb-server.service
Description=Docker MariaDB 10.1 Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
ExecStartPre=`which sleep` 10
ExecStartPre=-/usr/bin/docker rm -f mariadb-engine-docker
ExecStart=/bin/bash -c "/usr/bin/docker run --name mariadb-engine-docker -v /var/phpmyfaq-storage/mariadb01/conf.d:/etc/mysql/conf.d -v /var/phpmyfaq-storage/mariadb01/data:/var/lib/mysql -p $mariadbip:$mariadbport:3306 -d mariadb:10.1"
ExecStop=/usr/bin/bash -c "/usr/bin/docker stop mariadb-engine-docker"

[Install]
WantedBy=multi-user.target
EOF
#
systemctl daemon-reload
#
systemctl enable docker-mariadb-server --no-pager
systemctl stop docker-mariadb-server --no-pager
systemctl start docker-mariadb-server --no-pager
systemctl status docker-mariadb-server --no-pager
sync
sleep 10
#

cat<<EOF >/root/os-db.sql
CREATE DATABASE IF NOT EXISTS $phpdbname default character set utf8;
GRANT ALL ON $phpdbname.* TO '$phpdbuser'@'%' IDENTIFIED BY '$phpdbuserpass';
GRANT ALL ON $phpdbname.* TO '$phpdbuser'@'127.0.0.1' IDENTIFIED BY '$phpdbuserpass';
GRANT ALL ON $phpdbname.* TO '$phpdbuser'@'localhost' IDENTIFIED BY '$phpdbuserpass';
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql
mysql -u root -h 127.0.0.1 -P $mariadbport -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
mysql -u root -h localhost -P $mariadbport -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
mysql -u root --protocol=socket --socket=/var/lib/mysql/mysql.sock -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
sync
rm -f /root/os-db.sql

wget http://download.phpmyfaq.de/phpMyFAQ-2.9.8.tar.gz -O /root/phpMyFAQ-2.9.8.tar.gz
tar -xzvf /root/phpMyFAQ-2.9.8.tar.gz -C /usr/local/src/
rsync -avP /usr/local/src/phpmyfaq/ /var/www/html/
chown -R root.root /var/www/html/*
rm -rf /root/phpMyFAQ-2.9.8.tar.gz /usr/local/src/phpmyfaq

mkdir /var/www/html/images
mkdir /var/www/html/attachments
mkdir /var/www/html/data

chown -R $apacheaccount:$apacheaccount \
/var/www/html/images \
/var/www/html/data \
/var/www/html/lang \
/var/www/html/attachments \
/var/www/html/admin/images \
/var/www/html/config

sed -r -i "s@Europe/Berlin@$mytimezone@g" /var/www/html/config/constants.php

systemctl enable rc-local >/dev/null 2>&1
systemctl enable rc.local >/dev/null 2>&1
chmod 755 /etc/rc.d/rc.local >/dev/null 2>&1
chmod 755 /etc/rc.local >/dev/null 2>&1

echo "`which systemctl` restart docker-mariadb-server.service" >> /etc/rc.local
sed -r -i 's/exit\ 0//g' /etc/rc.local
sed -r -i "s/\#\!\/bin\/sh.*/\#\!\/bin\/bash/g" /etc/rc.local
sed -r -i "s/\#\!\/bin\/bash.*/\#\!\/bin\/bash/g" /etc/rc.local


if [ `docker ps|grep -c mariadb-engine-docker` == "1" ] && [ -f /var/www/html/config/constants.php ]
then
	echo "Base Installation Completed. You need to enter to the server with a browser and finish the installation with the credentials stored at $credentialsfile" &>>$lgfile
	cat $credentialsfile &>>$lgfile
	echo "Enter to your server IP with any browser in order to configure your phpmyfaq Site using the database information on the credentials file" &>>$lgfile
else
	echo "Installation failed !" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END