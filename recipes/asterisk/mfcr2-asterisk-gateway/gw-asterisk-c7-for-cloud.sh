#!/bin/bash
#
# MFCR2-Asterisk 13 based VoIP Gateway
#
# Requeriments: Centos 7 with EPEL installed
# FirewallD and SELINUX disabled
#
# By Reinaldo R. Martinez P.
# tigerlinux AT gmail DOT com
#
# Script for cloud-init based systems.
#

# MariaDB Password:

mariadbpass="P@ssw0rd"

# Full Update:

yum clean all
yum -y update

# Uncomment the following lines if you don't meet the original requirements for EPEL, SELINUX and FirewallD:

# EPEL

# rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum clean all
# yum -y update

# SELINUX and FirewallD:

# setenforce 0
# sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
# systemctl stop firewalld
# systemctl disable firewalld

# Dependencies:

yum -y groupinstall core
yum -y groupinstall base "Development Tools"

yum -y install gcc gcc-c++ lynx bison mariadb-devel mariadb-server mariadb-libs mariadb \
php php-mysql php-pear php-mbstring tftp-server httpd make ncurses-devel libtermcap-devel \
sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
audiofile-devel gtk2-devel subversion kernel-devel git subversion kernel-devel php-process \
crontabs cronie cronie-anacron doxygen kernel-headers-`uname -r` kernel-devel-`uname -r` \
glibc-headers sqlite sqlite-devel ntp ntpdate cpp make automake autoconf php-pear-MDB2 \
php-pear-MDB2-Driver-mysql php-pear-MDB2-Driver-mysqli php-pear-DB perl-DBD-MySQL \
python python-devel texinfo uuid uuid-devel libuuid libuuid-devel jansson jansson-devel \
gmime-devel gmime

cd /usr/local/src/
git clone https://github.com/meduketto/iksemel

cd /usr/local/src/iksemel/

./autogen.sh
./configure
make
make install

cd /

# NTP Setup:

systemctl stop chrony
systemctl disable chrony
systemctl enable ntpdate
systemctl enable ntpd
systemctl stop ntpd
systemctl start ntpdate
systemctl start ntpd

# MariaDB Setup:

systemctl enable mariadb
systemctl start mariadb

/usr/bin/mysqladmin -u root password "$mariadbpass"

echo "[client]" > /root/.my.cnf
echo "user=root" >> /root/.my.cnf
echo "password=$mariadbpass" >> /root/.my.cnf

chmod 0400 /root/.my.cnf

# Asterisk Installation from Sources:

mkdir /workdir
cd /workdir
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/openr2/openr2-1.3.3.tar.gz

tar -xzvf dahdi-linux-complete-current.tar.gz -C /usr/local/src/
tar -xzvf libpri-current.tar.gz -C /usr/local/src/
tar -xzvf asterisk-13-current.tar.gz -C /usr/local/src/
tar -xzvf openr2-1.3.3.tar.gz -C /usr/local/src/

cd /usr/local/src/dahdi-linux-complete-*
make all
make install
make config
cp /usr/local/src/dahdi-linux-complete-*/tools/dahdi.init /etc/init.d/dahdi
cd /

cd /usr/local/src/openr2-*
./configure --prefix=/usr
make
make install
cd /

cd /usr/local/src/libpri-*
make
make install
cd /

cd /usr/local/src/asterisk-*
./contrib/scripts/install_prereq install
./configure --with-pjproject-bundled
ldconfig -v
./contrib/scripts/get_mp3_source.sh
make menuselect.makeopts
menuselect/menuselect --enable-category MENUSELECT_ADDONS \
--enable format_mp3 \
--enable res_config_mysql \
--enable app_mysql \
--enable cdr_mysql \
--enable app_meetme \
--enable MOH-OPSOUND-GSM \
--enable CORE-SOUNDS-EN-GSM \
--enable CORE-SOUNDS-ES-GSM \
--enable EXTRA-SOUNDS-EN-GSM
make
make addons
make install
make addons-install
make config
make progdocs
cd /
ldconfig -v

# Asterisk Config Files:

cp /usr/local/src/asterisk-13*/configs/samples/* /etc/asterisk/
cd /etc/asterisk/
for i in `ls`;do echo $i;mv $i `echo $i|sed 's/.sample//'`;done
cd /

# Asterisk User:

adduser -M -c "Asterisk User" -d /var/lib/asterisk/ asterisk

chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib/asterisk

# Let's run asterisk with the "asterisk/asterisk" user/group:

cp /etc/sysconfig/asterisk /etc/sysconfig/asterisk-ORIGINAL-DONTERASE
echo "AST_USER=\"asterisk\"" > /etc/sysconfig/asterisk
echo "AST_GROUP=\"asterisk\"" >> /etc/sysconfig/asterisk

ldconfig -v

# Enabling services:

systemctl enable dahdi
systemctl enable asterisk

# Preparing more config files:

echo "" > /etc/asterisk/sip_custom.conf
echo "" > /etc/asterisk/extensions_custom.conf

echo "#include sip_custom.conf" >> /etc/asterisk/sip.conf
echo "#include extensions_custom.conf" >> /etc/asterisk/extensions.conf

chown -R asterisk.asterisk /etc/asterisk

# Set and run dahdi

/etc/init.d/dahdi start
dahdi_genconf
/etc/init.d/dahdi restart

chown -R asterisk.asterisk /dev/dahdi

# Restart dahdi and start asterisk:

/etc/init.d/dahdi restart
/etc/init.d/asterisk start

# Set the Logrotate

echo "/var/log/asterisk/messages" > /etc/logrotate.d/asterisk
echo "/var/log/asterisk/queue_log" >> /etc/logrotate.d/asterisk
echo "/var/log/asterisk/cdr-csv/Master.csv" >> /etc/logrotate.d/asterisk
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

# Ready !. We are done !!!

echo ""
echo "INSTALLATION COMPLETE. Proceeding to reboot in 10 seconds"
echo ""

sleep 10

reboot
