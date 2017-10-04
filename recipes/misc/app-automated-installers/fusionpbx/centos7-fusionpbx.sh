#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# FusionPBX Installation Script
# Rel 1.0
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
export lgfile="/var/log/fusionpbx-automated-installer.log"
export fslgfile="/root/fusionpbx-install-information.log"
export credfile="/root/fusionpbx-credentials.txt"
echo "Start Date/Time: `date`" &>>$lgfile


if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools \
	git findutils iproute grep openssh sed gawk openssl which xz bzip2 \
	util-linux procps-ng which lvm2 sudo hostname rsync &>>$lgfile
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

if [ $cpus -lt "2" ] || [ $instram -lt "1700" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for FusionPBX. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
yum -y install git firewalld &>>$lgfile
systemctl enable firewalld
systemctl restart firewalld
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

yum -y update --exclude=kernel* &>>$lgfile

cat<<EOF >/etc/systemd/system/rngd.service
[Unit]
Description=Hardware RNG Entropy Gatherer Daemon

[Service]
ExecStart=/sbin/rngd -f -r /dev/urandom

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart rngd
systemctl enable rngd

wget https://raw.githubusercontent.com/fusionpbx/fusionpbx-install.sh/master/centos/pre-install.sh -O /root/pre-install.sh &>>$lgfile
chmod 755 /root/pre-install.sh &>>$lgfile
/root/pre-install.sh &>>$lgfile
cd /usr/src/fusionpbx-install.sh/centos
# ./install.sh &>>$fslgfile
./install.sh | tee -a $fslgfile &>>$lgfile

systemctl start memcached
systemctl enable memcached

cp /etc/systemd/system/multi-user.target.wants/freeswitch.service /root/freeswitch.service.original
cp /etc/sysconfig/freeswitch /root/freeswitch-sysconfig-original

cat <<EOF>/etc/systemd/system/multi-user.target.wants/freeswitch.service
[Unit]
Description=freeswitch
After=syslog.target network.target local-fs.target postgresql.service

[Service]
Type=forking
User=freeswitch
PIDFile=/run/freeswitch/freeswitch.pid
EnvironmentFile=-/etc/sysconfig/freeswitch
ExecStartPre=/bin/mkdir -p /var/run/freeswitch/
ExecStartPre=/bin/chown -R freeswitch:daemon /var/run/freeswitch/
ExecStartPre=/usr/bin/sleep 10
ExecStart=/usr/bin/freeswitch -nonat -ncwait -u freeswitch -g daemon -run /var/run/freeswitch \$FREESWITCH_PARAMS
ExecReload=/usr/bin/kill -HUP \$MAINPID
TimeoutSec=60s
Restart=always
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
LimitRTPRIO=infinity
LimitRTTIME=7000000
IOSchedulingClass=realtime
IOSchedulingPriority=2
CPUSchedulingPolicy=rr
CPUSchedulingPriority=89
UMask=0007

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF>/etc/sysconfig/freeswitch
FS_USER="freeswitch"
FS_GROUP="daemon"
FREESWITCH_PARAMS=""
EOF

systemctl daemon-reload &>>$lgfile
systemctl stop freeswitch &>>$lgfile
systemctl start freeswitch &>>$lgfile

mytimezone=`timedatectl status|grep -i "time zone:"|cut -d: -f2|awk '{print $1}'`

if [ -f /usr/share/zoneinfo/$mytimezone ]
then
	crudini --set /etc/php.ini PHP date.timezone "$mytimezone"
	crudini --set /etc/php.ini Date date.timezone "$mytimezone"
else
	crudini --set /etc/php.ini PHP date.timezone "UTC"
	crudini --set /etc/php.ini Date date.timezone "UTC"
fi

systemctl restart php-fpm &>>$lgfile
systemctl restart nginx &>>$lgfile
systemctl status freeswitch &>>$lgfile
systemctl status nginx &>>$lgfile
systemctl status php-fpm &>>$lgfile

yum -y install python2-certbot-nginx &>>$lgfile

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

export fspass=`grep password: /var/log/fusionpbx-automated-installer.log|awk '{print $2}'`
export fsuser=`grep username: /var/log/fusionpbx-automated-installer.log|awk '{print $2}'|grep -v "@"`
export fsuserdomain=`grep username: /var/log/fusionpbx-automated-installer.log|awk '{print $2}'|grep "@"`
export urldomain=`grep "domain name:" /var/log/fusionpbx-automated-installer.log |awk '{print $3}'`

echo "" >> $credfile
echo "Your FusionPBX install information is stored on the file $fslgfile" >> $credfile
echo "Admin User: $fsuser" >> $credfile
echo "Admin User Password: $fspass" >> $credfile
echo "Admin URL: $urldomain" >> $credfile
echo "Admin User with Domain: $fsuserdomain" >> $credfile

# Spanish audio - /usr/share/freeswitch/sounds/es
wget http://files.freeswitch.org/freeswitch-sounds-es-mx-maria-44100.tar.gz -O /root/freeswitch-sounds-es-mx-maria-44100.tar.gz &>>$lgfile
yum -y install ffmpeg-libs &>>$lgfile
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro &>>$lgfile
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm &>>$lgfile
yum clean all &>>$lgfile
yum -y update &>>$lgfile
yum -y install ffmpeg ffmpeg-devel &>>$lgfile
tar -xzvf /root/freeswitch-sounds-es-mx-maria-44100.tar.gz -C /usr/share/freeswitch/sounds/ &>>$lgfile
rm -f /root/freeswitch-sounds-es-mx-maria-44100.tar.gz &>>$lgfile
cd /usr/share/freeswitch/sounds/es/mx/maria
for dir in `ls`
do 
	mkdir $dir/8000
	mkdir $dir/16000
	mkdir $dir/32000
done
cd /usr/share/freeswitch/sounds/es/mx/maria
for dir in `ls`
do
	cd $dir/44100/
		for mywav in `ls *.wav`
		do
			echo $mywav
			ffmpeg -i "$mywav" -ar 8000 -ac 1 -ab 128 "../8000/"$mywav &>>$lgfile
			ffmpeg -i "$mywav" -ar 16000 "../16000/"$mywav &>>$lgfile
			ffmpeg -i "$mywav" -ar 32000 "../32000/"$mywav &>>$lgfile
		done
	cd ../..
done
cd /
chown -R freeswitch.daemon /usr/share/freeswitch/sounds/es

# Add/change the default audio language in your /etc/freeswitch/vars.xml file:
#
# <!-- Sets the sound directory. -->
# #<X-PRE-PROCESS cmd="set" data="sound_prefix=$${sounds_dir}/en/us/callie" />
# <X-PRE-PROCESS cmd="set" data="sound_prefix=$${sounds_dir}/es/mx/maria"/>
# <X-PRE-PROCESS cmd="set" data="default_language=es"/>

sync
sleep 10

if [ `ss -ltn|grep -c :443` -gt 0 ] && [ `ss -ltn|grep -c :8021` -gt 0 ] && [ `ss -ltn|grep -c :5432` -gt 0 ]
then
	echo "Your FusionPBX Server is ready. See your credentials at $credfile and $fslgfile" &>>$lgfile
	echo "" &>>$lgfile
	cat $credfile &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "FusionPBX Server install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
