#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# MariaDB Server Automated Installation Script
# Rel 1.1
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/mariadbserver-automated-installer.log"
credentialsfile="/root/mariabd-access-info.txt"
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

export mariadbip='0.0.0.0'
export mariadbpass=`openssl rand -hex 10`

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
yum -y erase firewalld

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

echo "MariaDB User: root" > $credentialsfile
echo "MariaDB root password: $mariadbpass" >> $credentialsfile
echo "MariaDB listen IP: $mariadbip" >> $credentialsfile

if [ `mysqladmin -h localhost -u root -p$mariadbpass ping|grep -ci alive` == "1" ]
then
	echo "MariaDB Installation ready. Credentials file: $credentialsfile" &>>$lgfile
	echo "Your credentials:" &>>$lgfile
	cat $credentialsfile  &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "MariaDB installation failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi

# END