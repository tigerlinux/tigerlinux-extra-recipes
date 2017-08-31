#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# OpenVAS-8 install.
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.0
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

export lgfile="/var/log/openvas-automated-install.log"
export credfile="/root/openvas-credentials.txt"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 sudo hostname
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

if [ $cpus -lt "2" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for OpenVAS. Aborting!" &>>$lgfile
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

export openvasadmuser="admin"
export openvasadmpass=`openssl rand -hex 10`
export HOME=/root

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

	yum -y install wget bzip2 texlive net-tools alien gnutls-utils texlive-collection-latexrecommended \
	texlive-changepage texlive-titlesec rsync rng-tools haveged yum-utils device-mapper-persistent-data \
	mingw32-nsis
	mkdir -p /usr/share/texlive/texmf-local/tex/latex/comment
	wget http://mirrors.ctan.org/macros/latex/contrib/comment/comment.sty -O /usr/share/texlive/texmf-local/tex/latex/comment/comment.sty
	cd /usr/share/texlive/texmf-local/tex/latex/comment
	chmod 644 comment.sty
	texhash
	cd /

	yum -y update --exclude=kernel*
	yum -y install redis openvas-cli openvas-gsa openvas-libraries openvas-manager openvas-scanner
	grep -v unixsocket /etc/redis.conf > /etc/redis.conf.TEMP
	cat /etc/redis.conf.TEMP > /etc/redis.conf
	rm -f /etc/redis.conf.TEMP
	echo "unixsocket /tmp/redis.sock" >> /etc/redis.conf
	echo "unixsocketperm 700" >> /etc/redis.conf
	systemctl enable redis
	systemctl restart redis
	openvas-nvt-sync --wget &>>$lgfile
	openvas-scapdata-sync &>>$lgfile
	openvas-certdata-sync &>>$lgfile
	sync
	sleep 10
	openvas-mkcert -q -y &>>$lgfile
	openvas-mkcert-client -n -i &>>$lgfile
	sleep 10

	systemctl restart openvas-scanner
	systemctl restart openvas-manager
	systemctl enable openvas-scanner openvas-manager
	
	echo "Waiting 60 seconds in order to let openvassd to stabilice"
	sleep 60
	sync
	
	while [ `ps -ef|grep -i openvassd:.\*Reloaded|grep -v grep|wc -l` == 1 ]
	do
		echo "Waiting until NVT's are loaded"
		sleep 10
	done
	
	openvasmd --rebuild --progress --verbose &>>$lgfile

	openvasmd --create-user=$openvasadmuser --role=Admin
	openvasmd --user=$openvasadmuser --new-password=$openvasadmpass
	
	systemctl start openvas-gsa
	systemctl enable openvas-gsa
	
	sed -r -i 's/auto_plugin_update=no/auto_plugin_update=yes/g' /etc/sysconfig/openvas-scanner
	systemctl restart crond

	;;
debian-based)
	amiubuntu1604=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*16.04.\*LTS|head -n1|wc -l`
	if [ $amiubuntu1604 != "1" ]
	then
		echo "This is NOT an Ubuntu 16.04LTS machine. Aborting !" &>>$lgfile
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi
	
	export DEBIAN_FRONTEND=noninteractive
	
	apt-get -y update
	apt-get -y install \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

	#apt-get \
	#-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	#-y upgrade
	
	# https://launchpad.net/~mrazavi/+archive/ubuntu/openvas
	apt-get -y install texlive-latex-extra --no-install-recommends
	add-apt-repository -y ppa:mrazavi/openvas
	apt-get -y update
	apt-get -y install alien nsis rpm nmap sqlite3
	apt-get -y install redis-server
	apt-get -y install openvas

	openvas-nvt-sync --wget &>>$lgfile
	openvas-scapdata-sync &>>$lgfile
	openvas-certdata-sync &>>$lgfile
	
	sync
	sleep 10

	systemctl restart openvas-scanner
	systemctl restart openvas-manager
	systemctl enable openvas-scanner openvas-manager
	
	echo "Waiting 60 seconds in order to let openvassd to stabilice"
	sleep 60
	sync
	
	while [ `ps -ef|grep -i openvassd:.\*Reloaded|grep -v grep|wc -l` == 1 ]
	do
		echo "Waiting until NVT's are loaded"
		sleep 10
	done
	
	openvasmd --rebuild --progress --verbose &>>$lgfile

	openvasmd --create-user=$openvasadmuser --role=Admin
	openvasmd --user=$openvasadmuser --new-password=$openvasadmpass
	
	echo "PORT_NUMBER=9443" > /etc/default/openvas-gsa
	
	systemctl restart openvas-gsa
	systemctl enable openvas-gsa
	

	;;
unknown)
	echo "Unkown/Unsupported operating system. Aborting!" &>>$lgfile
	exit 0
	;;
esac

openvas-check-setup --v8 &>>$lgfile

echo "Access OpenVas using the following information:" > $credfile
echo "- URL: https://`ip route get 1 | awk '{print $NF;exit}'`:9443" >> $credfile
echo "- Admin User: $openvasadmuser" >> $credfile
echo "- Admin User Password: $openvasadmpass" >> $credfile

echo "Installation completed. Your credentials are on $credfile" &>>$lgfile
cat $credfile &>>$lgfile

echo "End Date/Time: `date`" &>>$lgfile

#END
