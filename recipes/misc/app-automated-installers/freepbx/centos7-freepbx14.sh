#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# FreePBX-14 Server Automated Installation Script
# Rel 1.0
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/freepbx-automated-installer.log"
credentialsfile="/root/freepbx-access-info.txt"
echo "Start Date/Time: `date`" &>>$lgfile

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

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "2" ] || [ $instram -lt "900" ] || [ $avusr -lt "15000000" ] || [ $avvar -lt "15000000" ]
then
	echo "Not enough hardware for FreePBX. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
# yum -y erase firewalld
yum -y install firewalld
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --reload

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

yum -y update
yum -y install mariadb-server mariadb crudini

echo "" > /etc/my.cnf.d/mariadb-server-custom.cnf

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
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql

rm -f /root/os-db.sql

yum -y groupinstall core base "Development Tools"

yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update --exclude=kernel*
yum -y erase php*
yum -y install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear \
php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap \
tftp-server httpd make ncurses-devel libtermcap-devel curl \
sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
audiofile-devel gtk2-devel subversion git crontabs cronie cronie-anacron doxygen \
kernel-headers-`uname -r` kernel-devel-`uname -r` kernel-headers kernel-devel \
glibc-headers sqlite sqlite-devel ntp ntpdate cpp make automake autoconf unzip \
python python-devel texinfo uuid uuid-devel libuuid libuuid-devel jansson jansson-devel \
gmime-devel gmime ncurses-devel wget net-tools gnutls-devel unixODBC mysql-connector-odbc \
gcc gcc-c++ lynx bison

cd /root
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs
cd /

pear install Console_Getopt

systemctl enable httpd.service
systemctl start httpd.service

systemctl stop chrony
systemctl disable chrony
systemctl enable ntpdate
systemctl enable ntpd
systemctl stop ntpd
systemctl start ntpdate
systemctl start ntpd

mkdir /workdir
cd /workdir
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-14-current.tar.gz
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/openr2/openr2-1.3.3.tar.gz
wget https://github.com/meduketto/iksemel/archive/master.zip -O iksemel-master.zip
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz


tar -xzvf jansson.tar.gz -C /usr/local/src/
unzip iksemel-master.zip -d /usr/local/src
tar -xzvf dahdi-linux-complete-current.tar.gz -C /usr/local/src/
tar -xzvf libpri-current.tar.gz -C /usr/local/src/
tar -xzvf asterisk-14-current.tar.gz -C /usr/local/src/
tar -xzvf openr2-1.3.3.tar.gz -C /usr/local/src/

# mv /workdir/asterisk-13-current.tar.gz /root/

cd /
rm -rf /workdir/*

cd /usr/local/src/iksemel-*
./autogen.sh
./configure
make
make install
cd /
rm -rf /usr/local/src/iksemel-*

cd /usr/local/src/dahdi-linux-complete-*
make all
make install
make config
cp /usr/local/src/dahdi-linux-complete-*/tools/dahdi.init /etc/init.d/dahdi
cd /
rm -rf /usr/local/src/dahdi-linux-complete-*

cd /usr/local/src/openr2-*
./configure --prefix=/usr
make
make install
cd /
rm -rf /usr/local/src/openr2-*

cd /usr/local/src/jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install
cd /
rm -rf /usr/local/src/jansson-*

ldconfig -v

cd /usr/local/src/libpri-*
make
make install
cd /
rm -rf /usr/local/src/libpri-*

cd /usr/local/src/asterisk-*
./contrib/scripts/install_prereq install
yum -y clean all
./configure --libdir=/usr/lib64 --with-pjproject-bundled
ldconfig -v
./contrib/scripts/get_mp3_source.sh
make menuselect.makeopts
menuselect/menuselect --enable-category MENUSELECT_ADDONS \
--enable format_mp3 \
--enable res_config_mysql \
--enable app_mysql \
--enable cdr_mysql \
--enable app_meetme \
--enable app_confbridge
make
make addons
make install
make addons-install
make config
cd /
rm -rf /usr/local/src/asterisk-*
ldconfig -v

adduser -M -c "Asterisk User" -d /var/lib/asterisk/ asterisk

ln -s /usr/lib64/asterisk /usr/lib/asterisk

chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www

ldconfig -v

sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

systemctl disable asterisk
systemctl disable dahdi

/etc/init.d/dahdi start
dahdi_genconf
/etc/init.d/dahdi restart

chown -R asterisk.asterisk /dev/dahdi
/etc/init.d/dahdi restart
systemctl enable dahdi

echo "/var/log/asterisk/full" > /etc/logrotate.d/asterisk
echo "/var/log/asterisk/queue_log" >> /etc/logrotate.d/asterisk
echo "/var/log/asterisk/cdr-csv/Master.csv" >> /etc/logrotate.d/asterisk
echo "/var/log/asterisk/*.log" >> /etc/logrotate.d/asterisk
echo "{" >> /etc/logrotate.d/asterisk
echo -e "\tmissingok" >> /etc/logrotate.d/asterisk
echo -e "\trotate 5" >> /etc/logrotate.d/asterisk
echo -e "\tdaily" >> /etc/logrotate.d/asterisk
echo -e "\tcreate 0640 asterisk asterisk" >> /etc/logrotate.d/asterisk
echo -e "\tcompress" >> /etc/logrotate.d/asterisk
echo -e "\tpostrotate" >> /etc/logrotate.d/asterisk
echo -e "\t\t/usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null" >> /etc/logrotate.d/asterisk
echo -e "\tendscript" >> /etc/logrotate.d/asterisk
echo "}" >> /etc/logrotate.d/asterisk

cp /etc/sysconfig/asterisk /etc/sysconfig/asterisk-ORIGINAL-DONTERASE
echo "AST_USER=\"asterisk\"" > /etc/sysconfig/asterisk
echo "AST_GROUP=\"asterisk\"" >> /etc/sysconfig/asterisk

crudini --set /etc/php.ini PHP upload_max_filesize 120M
crudini --set /etc/php.ini PHP memory_limit 256M

mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

if [ -f /usr/share/zoneinfo/$mytimezone ]
then
	crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
else
	crudini --set /etc/php.ini PHP date.timezone "UTC"
fi

systemctl restart httpd

cd  /workdir
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar -xzvf freepbx-14.0-latest.tgz -C /usr/src/
cd /
rm -f /workdir/*
cd /usr/src/freepbx/
./start_asterisk start
./install -n &>>$lgfile

cd /

yum -y clean all

cat <<EOF >/etc/systemd/system/freepbx.service
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
 
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable freepbx.service
systemctl start freepbx.service
sleep 10
sync
systemctl status freepbx.service &>>$lgfile
sleep 5

ln -s /var/www/html/admin/modules/conferences/etc/confbridge.conf /etc/asterisk/confbridge.conf

echo "/usr/sbin/asterisk -rx \"module load app_confbridge.so\" 2>/dev/null 2>&1" >> /etc/rc.local
# echo "/usr/sbin/fwconsole pm2 --restart=ucp" >> /etc/rc.local
# echo "/usr/sbin/fwconsole restart" >> /etc/rc.local

#cd /
#npm install -g ini
#npm install -g mariasql
#npm install -g asterisk-manager
#npm install -g socket.io
#npm install -g async
#npm install -g express
#npm install -g ltx
#npm install -g node-uuid
#npm install -g uuid
#npm install -g node-xmpp-client
#npm install -g q
#cd /

fwconsole chown
fwconsole ma upgrade framework
fwconsole ma upgradeall

# Fix for UCP failing to properly run
yum -y remove nodejs
yum -y remove npm
yum -y install nodejs
fwconsole ma uninstall ucp
fwconsole ma remove ucp
fwconsole ma download ucp
fwconsole ma install ucp

/usr/sbin/asterisk -rx \"module load app_confbridge.so\" 2>/dev/null 2>&1
/usr/sbin/fwconsole ma refreshsignatures
/usr/sbin/fwconsole restart


systemctl enable rc-local
chmod 755 /etc/rc.local

if [ -f /usr/sbin/fwconsole ]
then
	echo "FreePBX 14 Installed" &>>$lgfile
	echo "End date:" &>>$lgfile
	date &>>$lgfile
else
	echo "FreePBX 14 failed to install" &>>$lgfile
	echo "End date:" &>>$lgfile
	date &>>$lgfile
fi

# END