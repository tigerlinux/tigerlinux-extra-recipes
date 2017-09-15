#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Vesta Control Panel installation script
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.2
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/vestacp-install.log"
vestacreds="/root/vesta-credentials.txt"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname &>>$lgfile
	setenforce 0
	sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
	yum -y erase firewalld
fi

if [ -f /etc/debian_version ]
then
	OSFlavor='debian-based'
	apt-get -y clean
	apt-get -y update &>>$lgfile
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
		lvm2 hostname sudo &>>$lgfile
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export vestapassword=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for VestaCP. Aborting!" &>>$lgfile
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

	;;
debian-based)
	amiubuntu1604=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*16.04.\*LTS|head -n1|wc -l`
	if [ $amiubuntu1604 != "1" ]
	then
		echo "This is NOT an Ubuntu 16.04LTS machine. Aborting !" &>>$lgfile
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi
	apt-get -y update &>>$lgfile
	apt-get -y install \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common &>>$lgfile

	apt-get \
	-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	-y upgrade  &>>$lgfile
	
	# Fix for Ubuntu detection:
	echo "Ubuntu 16.04.3 LTS \n \l" > /etc/issue

	;;
unknown)
	echo "Unkown/Unsupported operating system. Aborting!" &>>$lgfile
	exit 0
	;;
esac

wget -c  http://vestacp.com/pub/vst-install.sh -O /root/vst-install.sh &>>$lgfile
chmod 755 /root/vst-install.sh

# export vestapassword=`openssl rand -hex 10`

/root/vst-install.sh \
--nginx yes \
--apache no \
--phpfpm yes \
--named yes \
--remi no \
--vsftpd yes \
--proftpd no \
--iptables yes \
--fail2ban yes \
--quota no \
--exim yes \
--dovecot yes \
--spamassassin yes \
--clamav yes \
--mysql yes \
--postgresql yes \
--hostname `hostname` \
--force \
--interactive no \
--password $vestapassword &>>$lgfile

echo "Vesta Credentials" > $vestacreds
echo "User: admin" >> $vestacreds
echo "Password: $vestapassword" >> $vestacreds
allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
for myip in $allipaddr
do
	echo "URL: https://$myip:8083" >> $vestacreds
done

finalcheck=`ss -ltn|grep -c :8083`

if [ $finalcheck -gt "0" ]
then
	echo "Your VestaCP server is ready. See your credentials at $vestacreds" &>>$lgfile
	cat $vestacreds &>>$lgfile
else
	echo "VestaCP Server install failed" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END
