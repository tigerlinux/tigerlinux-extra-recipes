#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Wordpress with Dockerized MariaDB 10.1 Installation Script
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.0
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/wordpress-install.log"
credentialsfile="/root/wordpress-access-info.txt"
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
	yum -y erase firewalld
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
export wpdbuser="wordpressuser"
export wpdbname="wordpressdb"
export wdbuserpass=`openssl rand -hex 10`

echo "MariaDB User: root" >> $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile
echo "MariaDB listen PORT: $mariadbport" >> $credentialsfile
echo "Wordpress DB access info: DBName: $wpdbname, DBUser: $wpdbuser, DBUserPass: $wdbuserpass" >> $credentialsfile
echo "Wordpress URL: http://`ip route get 1 | awk '{print $NF;exit}'`" >> $credentialsfile

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
	echo "Not enough hardware for Wordpress. Aborting!" &>>$lgfile
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

	yum -y update
	yum -y install docker-ce

	systemctl start docker
	systemctl enable docker
	
	yum -y install mariadb crudini
	
	yum -y install httpd php-common mod_php php-pear php-opcache \
	php-pdo php-mbstring php-mysqlnd php-xml php-bcmath \
	php-json php-cli php-gd php-cli dos2unix
	
	export apacheaccount="apache"
	
	cat <<EOF>/etc/httpd/conf.d//wordpress-extra.conf
<Directory /var/www/html/>
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>
EOF
	
	crudini --set /etc/php.ini PHP upload_max_filesize 100M
	crudini --set /etc/php.ini PHP post_max_size 100M
	crudini --set /etc/php.ini PHP memory_limit 256M
	
	mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

	if [ -f /usr/share/zoneinfo/$mytimezone ]
	then
		crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
	else
		crudini --set /etc/php.ini PHP date.timezone "UTC"
	fi
	
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
	libapache2-mod-php php-mysql dos2unix
	
	export apacheaccount="www-data"
	
	ln -s /etc/php/7.0/apache2/php.ini /etc/php.ini
	
	crudini --set /etc/php.ini PHP upload_max_filesize 100M
	crudini --set /etc/php.ini PHP post_max_size 100M
	crudini --set /etc/php.ini PHP memory_limit 256M
	
	mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`
	
	cat <<EOF>/etc/apache2/conf-available/wordpress-extra.conf
<Directory /var/www/html/>
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>
EOF

	a2enconf wordpress-extra.conf

	if [ -f /usr/share/zoneinfo/$mytimezone ]
	then
		crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
	else
		crudini --set /etc/php.ini PHP date.timezone "UTC"
	fi
	
	systemctl restart apache2
	systemctl enable apache2

	;;
unknown)
	echo "Unkown/Unsupported operating system. Aborting!" &>>$lgfile
	exit 0
	;;
esac

devicelist=`lsblk -do NAME|grep -v NAME`

nxsto=''
for blkst in $devicelist
do
	if [ `lsblk -do NAME,TYPE|grep -v NAME|grep disk|awk '{print $1}'|grep -v da|grep -c ^$blkst` == "1" ] \
	&& [ `blkid |grep $blkst|grep -ci swap` == 0 ] \
	&& [ `grep -v cloudconfig /etc/fstab |grep -ci ^/dev/$blkst` == 0 ]
	then
		echo "Device $blkst usable" &>>$lgfile
		nxsto=$blkst
	fi
done

mkdir -p /var/wordpress-storage

if [ -z $nxsto ]
then
	echo "No usable extra storage found" &>>$lgfile
else
	echo "Extra storage found: $nxsto" &>>$lgfile
	cat /etc/fstab > /etc/fstab.ORG
	umount /dev/$nxsto >/dev/null 2>&1
	cat /etc/fstab |egrep -v "($nxsto|wpcontsto)" > /etc/fstab.NEW
	cat /etc/fstab.NEW > /etc/fstab
	mkfs.ext4 -F -F -L wpcontsto /dev/$nxsto
	echo 'LABEL=wpcontsto /var/wordpress-storage ext4 defaults 0 0' >> /etc/fstab
	mount /var/wordpress-storage
	mv /var/www/html /var/wordpress-storage/html
	ln -s /var/wordpress-storage/html /var/www/html
fi

rm -f /var/www/html/index.html

mkdir -p /var/wordpress-storage/mariadb01/data
mkdir -p /var/wordpress-storage/mariadb01/conf.d
rm -rf /var/lib/mysql
rm -rf /var/wordpress-storage/mariadb01/data/*
ln -s /var/wordpress-storage/mariadb01/data /var/lib/mysql

cat<<EOF >/var/wordpress-storage/mariadb01/conf.d/server.cnf
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
-v /var/wordpress-storage/mariadb01/conf.d:/etc/mysql/conf.d \
-v /var/wordpress-storage/mariadb01/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="$mariadbpass" \
-p $mariadbip:$mariadbport:3306 \
-d mariadb:10.1

sleep 20

docker ps -a
docker stop mariadb-engine-docker

cat<<EOF >/var/wordpress-storage/mariadb01/conf.d/server.cnf
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
ExecStart=/bin/bash -c "/usr/bin/docker run --name mariadb-engine-docker -v /var/wordpress-storage/mariadb01/conf.d:/etc/mysql/conf.d -v /var/wordpress-storage/mariadb01/data:/var/lib/mysql -p $mariadbip:$mariadbport:3306 -d mariadb:10.1"
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
CREATE DATABASE IF NOT EXISTS $wpdbname default character set utf8;
GRANT ALL ON $wpdbname.* TO '$wpdbuser'@'%' IDENTIFIED BY '$wdbuserpass';
GRANT ALL ON $wpdbname.* TO '$wpdbuser'@'127.0.0.1' IDENTIFIED BY '$wdbuserpass';
GRANT ALL ON $wpdbname.* TO '$wpdbuser'@'localhost' IDENTIFIED BY '$wdbuserpass';
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql
mysql -u root -h 127.0.0.1 -P $mariadbport -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
mysql -u root -h localhost -P $mariadbport -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
mysql -u root --protocol=socket --socket=/var/lib/mysql/mysql.sock -p`grep password /root/.my.cnf |cut -d\" -f2` < /root/os-db.sql
sync
rm -f /root/os-db.sql

wget http://wordpress.org/latest.tar.gz -O /root/latest.tar.gz
tar -xzvf /root/latest.tar.gz -C /usr/local/src/
rsync -avP /usr/local/src/wordpress/ /var/www/html/
rm -rf /root/latest.tar.gz /usr/local/src/wordpress
mkdir -p /var/www/html/wp-content/uploads
chown -R $apacheaccount:$apacheaccount /var/www/html/*
mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
cp /var/www/html/wp-config.php /root/
dos2unix /var/www/html/wp-config.php
sed -r -i "s/database_name_here/$wpdbname/g" /var/www/html/wp-config.php
sed -r -i "s/username_here/$wpdbuser/g" /var/www/html/wp-config.php
sed -r -i "s/password_here/$wdbuserpass/g" /var/www/html/wp-config.php
sed -i -i "s/localhost/127.0.0.1/g" /var/www/html/wp-config.php

sed -r -i "s/'AUTH_KEY'.*/'AUTH_KEY',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'SECURE_AUTH_KEY'.*/'SECURE_AUTH_KEY',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'LOGGED_IN_KEY'.*/'LOGGED_IN_KEY',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'NONCE_KEY'.*/'NONCE_KEY',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'AUTH_SALT'.*/'AUTH_SALT',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'SECURE_AUTH_SALT'.*/'SECURE_AUTH_SALT',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'LOGGED_IN_SALT'.*/'LOGGED_IN_SALT',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php
sed -r -i "s/'NONCE_SALT'.*/'NONCE_SALT',\ '`openssl rand -hex 30`'\);/g" /var/www/html/wp-config.php

systemctl enable rc-local >/dev/null 2>&1
systemctl enable rc.local >/dev/null 2>&1
chmod 755 /etc/rc.d/rc.local >/dev/null 2>&1
chmod 755 /etc/rc.local >/dev/null 2>&1

echo "`which systemctl` restart docker-mariadb-server.service" >> /etc/rc.local
sed -r -i 's/exit\ 0//g' /etc/rc.local
sed -r -i "s/\#\!\/bin\/sh.*/\#\!\/bin\/bash/g" /etc/rc.local
sed -r -i "s/\#\!\/bin\/bash.*/\#\!\/bin\/bash/g" /etc/rc.local


if [ `docker ps|grep -c mariadb-engine-docker` == "1" ] && [ -f /var/www/html/wp-config.php ]
then
	echo "Installation Completed. Your credentials are stored at $credentialsfile" &>>$lgfile
	cat $credentialsfile &>>$lgfile
	echo "Enter to your server IP with any browser in order to configure your Wordpress Site" &>>$lgfile
else
	echo "Installation failed !" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END