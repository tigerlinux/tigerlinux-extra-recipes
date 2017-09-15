#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
#
# Cloudify Community automatic installer script.
# Baremetal version (Generic), Cloudify Community.
# Release 1.3
#
# This script (that can run on any kind of machine) fully
# automates the installation of Cloudify series 17.3 (Community)
# on any kind of machine. This need to be run on either Centos 7
# or RHEL 7.
#
# Minimun requiremens:
# 5GB free space, 2 vcpu, 4GB RAM
# Centos 7, basic installation with SSH (Selection: "Infrastructure 
# Server" recommended. If "minimal install" is used, ensure you have 
# ssh server/client packages configured and sshd service running).
#
# This script need to be run inside the console (ssh or local) and
# directly by the root account (not sudo). Also, it is not compatible
# with "nohup" (cloudify bootstrap will fail).
# It can be run on baremetal or cloud machines (or any generic server)
# running Centos 7 (x86_64) with Internet access.
#
# Once this script ends, your access credentials will be
# located at the following file: /root/cfy-credentials.txt
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
lgfile="/var/log/cloudify-automated-installer.log"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'
export admuser="admin"
export admpass=`openssl rand -hex 10`

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git \
	findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux \
	procps-ng which lvm2 &>>$lgfile
fi

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "2" ] || [ $instram -lt "3500" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for Cloudify. Aborting!"  &>>$lgfile
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
	# NOTE: Installing EPEL will make things easier, but, it could break
	# RHEL compatibility. Just in case, we'll use EPEL only if we can
	# detect we are running inside a CentOS machine. Otherwise, we'll not
	# install EPEL, needed for "jq" command used in this script.
	yum -y install curl wget redhat-lsb-core net-tools &>>$lgfile
	yum -y install findutils iproute grep openssh sed coreutils gawk openssl which &>>$lgfile
	# If we are a "CentOS" machine, then we'll use epel-release and jq from epel.
	# If we are not a Centos machine, we'll just download "jq" from github.
	amicentos=`lsb_release -i|grep -ic centos`
	if [ $amicentos == "1" ]
	then
		yum -y install epel-release &>>$lgfile
		yum -y install jq &>>$lgfile
	else
		wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/local/bin/jq &>>$lgfile
		chmod 755 /usr/local/bin/jq
	fi
	
	testrel7=`lsb_release -r|awk '{print $2}'|grep ^7.|wc -l`
	if [ $testrel7 == "1" ]
	then
		echo "Running on Centos/RHEL 7"  &>>$lgfile
	else
		echo "This is not a centos/rhel 7 machine"  &>>$lgfile
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi
	
	setenforce 0
	sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
	yum -y erase firewalld &>>$lgfile
	yum -y install tuned tuned-utils &>>$lgfile
	echo "virtual-guest" > /etc/tuned/active_profile
	systemctl enable tuned
	systemctl start tuned
	yum -y install http://repository.cloudifysource.org/cloudify/17.3.31/release/cloudify-17.3.31~community.el6.x86_64.rpm &>>$lgfile
	;;
unknown)
	echo "Unkown or unsupported distribution detected. Aborting !." &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
	;;
esac

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf

if [ ! -f /opt/cfy/bin/cfy ]
then
	echo "ALERT !. Cloudify Client installation not found. Aborting" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_rsa.pub ]
then
	echo "Public/Private key already here!!" &>>$lgfile
else
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

# For future use....
if [ $OSFlavor == "debian-based" ]
then
	echo "Host *" > ~/.ssh/config
	echo "  KexAlgorithms +diffie-hellman-group1-sha1" >> ~/.ssh/config
	chmod 600 ~/.ssh/config
	echo "KexAlgorithms +diffie-hellman-group1-sha1" >> /etc/ssh/sshd_config
	echo "Ciphers +aes128-cbc" >> /etc/ssh/sshd_config
	/etc/init.d/ssh reload
fi

privateip=`ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"|head -n 1|xargs ifconfig|grep inet' '|awk '{print $2}'`
publicip=$privateip

echo "admin user: $admuser" > /root/cfy-credentials.txt
echo "admin user password: $admpass" >> /root/cfy-credentials.txt
chmod 700 /root/cfy-credentials.txt

echo "Credentials:" &>>$lgfile
cat /root/cfy-credentials.txt &>>$lgfile

cfy bootstrap \
/opt/cfy/cloudify-manager-blueprints/simple-manager-blueprint.yaml \
-i public_ip=$privateip \
-i private_ip=$publicip \
-i ssh_user=root \
-i ssh_port=22 \
-i ssh_key_filename="/root/.ssh/id_rsa" \
-i agents_user=cloudify \
-i admin_username=$admuser \
-i admin_password=$admpass \
-i minimum_required_total_physical_memory_in_mb=3000 &>>$lgfile

cfy status > /root/cfy-status.txt
cfy status  &>>$lgfile

#
# Perform API TEST
apitest=`curl -X GET --header "Tenant: default_tenant" -u $admuser:$admpass "http://localhost/api/v3/status?_include=status" 2>/dev/null|jq '.status' 2>/dev/null|grep running|wc -l`

yum -y install firewalld &>>$lgfile
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --zone=public --add-port=5672/tcp --permanent
firewall-cmd --zone=public --add-port=8086/tcp --permanent
firewall-cmd --zone=public --add-port=9100/tcp --permanent
firewall-cmd --zone=public --add-port=9200/tcp --permanent
firewall-cmd --zone=public --add-port=9999/tcp --permanent
firewall-cmd --zone=public --add-port=53333/tcp --permanent
firewall-cmd --zone=public --add-port=8300/tcp --permanent
firewall-cmd --zone=public --add-port=8301/tcp --permanent
firewall-cmd --zone=public --add-port=8500/tcp --permanent
firewall-cmd --zone=public --add-port=15432/tcp --permanent
firewall-cmd --zone=public --add-port=22000/tcp --permanent
firewall-cmd --zone=public --add-port=53229/tcp --permanent
firewall-cmd --reload

if [ $apitest == "1" ]
then
	echo "" &>>$lgfile
	echo "Installation finished, API TEST OK" &>>$lgfile
	echo "See your credentials at /root/cfy-credentials.txt" &>>$lgfile
	echo "Also, see cloudify status at /root/cfy-status.txt" &>>$lgfile
	echo "IMPORTANT NOTE: The community version does not include" &>>$lgfile
	echo "the WEB user interface." &>>$lgfile
	echo "" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "" &>>$lgfile
	echo "Installation finished, but API TEST FAILED !!" &>>$lgfile
	echo "See your credentials at /root/cfy-credentials.txt" &>>$lgfile
	echo "Also, see cloudify status at /root/cfy-status.txt" &>>$lgfile
	echo "IMPORTANT NOTE: The community version does not include" &>>$lgfile
	echo "the WEB user interface." &>>$lgfile
	echo "" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
