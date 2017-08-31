#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Dockerized MariaDB Installation Script
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.1
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/mariadb-dockerizerd-install.log"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux procps-ng which lvm2 sudo hostname
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
		lvm2 hostname sudo
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

export mariadbport='3306'
export mariadbip='0.0.0.0'
export mariadbpass=`openssl rand -hex 10`
credentialsfile="/root/mariabd-access-info.txt"

echo "MariaDB Credentials: Password: $mariadbpass, Listen IP: $mariadbip, Listen PORT: $mariadbport" &>>$lgfile
echo "MariaDB User: root" > $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile
echo "MariaDB listen PORT: $mariadbport" >> $credentialsfile

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "10000000" ] || [ $avvar -lt "10000000" ]
then
	echo "Not enough hardware for Dockerized-MariaDB. Aborting!" &>>$lgfile
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
fi

mkdir -p /var/mariadb-storage/mariadb01/data
mkdir -p /var/mariadb-storage/mariadb01/conf.d
rm -rf /var/lib/mysql
rm -rf /var/mariadb-storage/mariadb01/data/*
ln -s /var/mariadb-storage/mariadb01/data /var/lib/mysql

# First config, without the mariadb/mysql socket file.
echo "" > /var/mariadb-storage/mariadb01/conf.d/server.cnf
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_connections 100
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_allowed_packet 1024M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld thread_cache_size 128
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld sort_buffer_size 4M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld bulk_insert_buffer_size 16M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_heap_table_size 32M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld tmp_table_size 32M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqldump max_allowed_packet 1024M
#
# Let's pull the mariadb 10.1 image:
docker pull mariadb:10.1
#
# Run at first time, with root password and the config without
# the mysql/mariadb socket file:
docker run --name mariadb-engine-docker \
-v /var/mariadb-storage/mariadb01/conf.d:/etc/mysql/conf.d \
-v /var/mariadb-storage/mariadb01/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="$mariadbpass" \
-p $mariadbip:$mariadbport:3306 \
-d mariadb:10.1
#
# a safe 20 seconds stabilization wait.
sleep 20
#
# Let's stop the mariadb docker:
docker ps -a
docker stop mariadb-engine-docker
#
# Now, we'll reconfigure mariadb, this time, using the socket file
#
echo "" > /var/mariadb-storage/mariadb01/conf.d/server.cnf
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld socket /var/lib/mysql/mysql.sock
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_connections 100
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_allowed_packet 1024M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld thread_cache_size 128
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld sort_buffer_size 4M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld bulk_insert_buffer_size 16M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld max_heap_table_size 32M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqld tmp_table_size 32M
crudini --set /var/mariadb-storage/mariadb01/conf.d/server.cnf mysqldump max_allowed_packet 1024M
#
# Then, start mariadb again:
docker start mariadb-engine-docker
docker ps -a
#
# Let's prepare our mysql client file so we can use the
# "mysql" command passwordless:
echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"$mariadbpass\""  >> /root/.my.cnf 
echo "host = \"localhost\""  >> /root/.my.cnf
echo "socket = \"/var/lib/mysql/mysql.sock\""  >> /root/.my.cnf
chmod 600 /root/.my.cnf
#
# Now, and because we want our dockerized mariadb to start as a service,
# let's create a systemd control file for it
#
echo "[Unit]" > /etc/systemd/system/docker-mariadb-server.service
echo "Description=Docker MariaDB 10.1 Service" >> /etc/systemd/system/docker-mariadb-server.service
echo "After=docker.service" >> /etc/systemd/system/docker-mariadb-server.service
echo "Requires=docker.service" >> /etc/systemd/system/docker-mariadb-server.service
echo "" >> /etc/systemd/system/docker-mariadb-server.service
echo "[Service]" >> /etc/systemd/system/docker-mariadb-server.service
echo "Type=oneshot" >> /etc/systemd/system/docker-mariadb-server.service
echo "RemainAfterExit=true" >> /etc/systemd/system/docker-mariadb-server.service
echo "ExecStartPre=-/usr/bin/docker rm -f mariadb-engine-docker" >> /etc/systemd/system/docker-mariadb-server.service
echo "ExecStart=/bin/bash -c \"/usr/bin/docker run --name mariadb-engine-docker -v /var/mariadb-storage/mariadb01/conf.d:/etc/mysql/conf.d -v /var/mariadb-storage/mariadb01/data:/var/lib/mysql -p $mariadbip:$mariadbport:3306 -d mariadb:10.1\"" >> /etc/systemd/system/docker-mariadb-server.service
echo "ExecStop=/usr/bin/bash -c \"/usr/bin/docker stop mariadb-engine-docker\"" >> /etc/systemd/system/docker-mariadb-server.service
echo "" >> /etc/systemd/system/docker-mariadb-server.service
echo "[Install]" >> /etc/systemd/system/docker-mariadb-server.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/docker-mariadb-server.service
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

if [ `docker ps|grep -c mariadb-engine-docker` == "1" ]
then
	echo "Completed. Your credentials are stored at $credentialsfile" &>>$lgfile
	cat $credentialsfile &>>$lgfile
else
	echo "Installation failed !" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END