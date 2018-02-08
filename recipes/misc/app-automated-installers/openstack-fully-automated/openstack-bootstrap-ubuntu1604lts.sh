#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# OpenStack bootstrap script - systemd-installer mode
# Rel 1.2
# For usage on ubuntu1604lts 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/aio-openstack-installer.log"
echo "Start Date/Time: `date`" &>>$lgfile

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
else
	echo "Nota an Ubuntu Machine. Aborting!." &>>$lgfile
	exit 0
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

export osadminpass=`openssl rand -hex 10`
echo "The Admin password for \"osadmin\" user is: $osadminpass" &>>$lgfile
echo $osadminpass > /root/osadminpass.txt

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	exit 0
fi

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -g -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "2" ] || [ $instram -lt "7" ] || [ $avusr -lt "10000000" ] || [ $avvar -lt "50000000" ]
then
	echo "Not enough hardware for OpenStack. Aborting!" &>>$lgfile
	exit 0
fi

if [ `grep -c swapfile /etc/fstab` == "0" ]
then
	myswap=`free -m -t|grep -i swap:|awk '{print $2}'`
	if [ $myswap -lt 4000 ]
	then
		fallocate -l 4G /swapfile
		chmod 600 /swapfile
		mkswap /swapfile
		swapon /swapfile
		echo '/swapfile none swap sw 0 0' >> /etc/fstab
	fi
fi

if [ `grep -ci source.\*/etc/network/interfaces.d /etc/network/interfaces` == "0" ]
then
	echo "" >> /etc/network/interfaces
	echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
fi

dummynetwork=''
nettotest='192.168.125 192.168.231 172.18.34 172.16.33 10.20.30'
for mynet in $nettotest
do
	if [ `route -n|awk '{print $1}'|grep -ci ^$mynet` == "0" ]
	then
		export dummynetwork=$mynet
	fi
done
export dummyip=$dummynetwork.1
echo "export dummynetwork=$dummynetwork" > /etc/profile.d/os-bootstrap-variables.sh
echo "export dummyip=$dummyip" >> /etc/profile.d/os-bootstrap-variables.sh
modprobe loop
modprobe dummy

amiubuntu1604=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*16.04.\*LTS|head -n1|wc -l`
if [ $amiubuntu1604 != "1" ]
then
	echo "This is NOT an Ubuntu 16.04LTS machine. Aborting !"
	exit 0
fi

apt-get -y install software-properties-common &>>$lgfile
apt-get -y install ubuntu-cloud-keyring &>>$lgfile
add-apt-repository -y cloud-archive:pike &>>$lgfile

apt-get -y update &>>$lgfile

cat <<EOF >/etc/sysctl.d/10-openstack-sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF
sysctl -p /etc/sysctl.d/10-openstack-sysctl.conf

apt-get -y install openvswitch-switch python-openvswitch &>>$lgfile
/etc/init.d/openvswitch-switch restart
systemctl enable openvswitch-switch
systemctl restart openvswitch-switch
ovs-vsctl add-br br-int 2>/dev/null
	
cat <<EOF >/etc/network/interfaces.d/br-int
auto br-int
allow-ovs br-int
iface br-int inet static
ovs_type OVSBridge
address 0.0.0.0
EOF
	
ifup br-int

if [ `grep -ci dummy /etc/modules` == "0" ]
then
	echo "dummy" >> /etc/modules
fi

ovs-vsctl add-br br-dummy0 2>/dev/null
ovs-vsctl add-port br-dummy0 dummy0 2>/dev/null
	
cat <<EOF >/etc/network/interfaces.d/dummy0
allow-br-dummy0 dummy0
iface dummy0 inet manual
ovs_bridge br-dummy0
ovs_type OVSPort
EOF

cat <<EOF >/etc/network/interfaces.d/br-dummy0
auto br-dummy0
allow-ovs br-dummy0
iface br-dummy0 inet static
address $dummyip
netmask 255.255.255.0
ovs_type OVSBridge
ovs_ports dummy0
EOF

ifup br-dummy0
ifup dummy0

if [ `grep -ci loop /etc/modules` == "0" ]
then
	echo "loop" >> /etc/modules
fi
	
osinstaller="https://github.com/tigerlinux/openstack-pike-installer-ubuntu1604lts.git"

git clone $osinstaller /usr/local/osinstaller

if [ ! -f /usr/local/osinstaller/main-installer.sh ]
then
	echo "OS Installer failed to download. Aborting!" &>>$lgfile
	exit 0
fi

mkdir /var/os-loops
truncate -s 5G /var/os-loops/swift-loop.img
truncate -s 20G /var/os-loops/cinder-loop.img
losetup /dev/loop0 /var/os-loops/swift-loop.img
losetup /dev/loop1 /var/os-loops/cinder-loop.img
mkfs.ext4 -F -F -L swift /dev/loop0

mkdir -p /srv/node/d1
pvcreate /dev/loop1
vgcreate cinder-volumes /dev/loop1
systemctl enable rc-local >/dev/null 2>&1
systemctl enable rc.local >/dev/null 2>&1
chmod 755 /etc/rc.d/rc.local >/dev/null 2>&1
chmod 755 /etc/rc.local >/dev/null 2>&1

if [ `grep -ci "cinder-loop.img" /etc/rc.local` == "0" ]
then
	echo "`which losetup` /dev/loop1 /var/os-loops/cinder-loop.img > /dev/null 2>&1" >> /etc/rc.local
	echo "`which lvm` vgscan > /dev/null 2>&1" >> /etc/rc.local
fi
if [ `grep -ci "swift-loop.img" /etc/fstab` == "0" ]
then
	echo '/var/os-loops/swift-loop.img /srv/node/d1 ext4 loop,acl,user_xattr,rw,auto 0 0' >> /etc/fstab
	mount /srv/node/d1/
fi

export oldpassword="0p3nSt4ck"
export newpassword=`openssl rand -hex 10`
export oldipaddress1="192.168.56.60"
export oldipaddress2="192.168.56.62"
export localipaddress=`ip route get 1 | awk '{print $NF;exit}'`
export MYCONF='./configs/main-config.rc'

cd /usr/local/osinstaller
cat ./sample-config/main-config.rc > $MYCONF

sed -r -i "s/$oldpassword/$newpassword/g" $MYCONF
sed -r -i "s/$oldipaddress1/$localipaddress/g" $MYCONF
sed -r -i "s/$oldipaddress2/$localipaddress/g" $MYCONF
sed -r -i "s/^swiftinstall=\"no\"/swiftinstall=\"yes\"/g" $MYCONF
sed -r -i "s/^heatinstall=\"no\"/heatinstall=\"yes\"/g" $MYCONF
sed -r -i "s/^ceilometerinstall=\"no\"/ceilometerinstall=\"yes\"/g" $MYCONF
sed -r -i "s/^swiftmetrics=\"no\"/swiftmetrics=\"yes\"/g" $MYCONF
sed -r -i "s/^dashboard_timezone=.*/dashboard_timezone=\"UTC\"/g" $MYCONF
sed -r -i "s/^extratenants=.*/extratenants=\"\"/g" $MYCONF
sed -r -i "s/^bridge_mappings=.*/bridge_mappings=\"physical01:br-dummy0\"/g" $MYCONF
sed -r -i "s/^forcegremtu=\"no\"/forcegremtu=\"yes\"/g" $MYCONF

####################################
sed -r -i 's/exit\ 0//g' /etc/rc.local
sed -r -i "s/\#\!\/bin\/sh.*/\#\!\/bin\/bash/g" /etc/rc.local
sed -r -i "s/\#\!\/bin\/bash.*/\#\!\/bin\/bash/g" /etc/rc.local

cat <<EOF >/root/final-script.sh
#!/bin/bash
#
export dummynetwork=`route -n|grep br-dummy0|awk '{print $1}'|cut -d. -f1,2,3|grep -v ^169.254`
export osadminpass=`cat /root/osadminpass.txt`
export lgfile="/var/log/aio-openstack-installer.log"
echo "OpenStack osadmin user password: \$osadminpass"
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
cd /usr/local/osinstaller
echo "Installing OpenStack"
./main-installer.sh install auto &>>\$lgfile

if [ ! -f /etc/openstack-control-script-config/install-end-date-and-time ]
then
	echo "OpenStack installation failed. Aborting!"
	echo "End Date/Time: `date`" &>>\$lgfile
	exit 0
fi

source /root/keystonerc_fulladmin
openstack-control.sh disable

echo "[Unit]" > /etc/systemd/system/openstack-automated.service
echo "Description=OpenStack AutoStart" >> /etc/systemd/system/openstack-automated.service
echo "After=network.target rc-local.service rc.local.service" >> /etc/systemd/system/openstack-automated.service
echo "" >> /etc/systemd/system/openstack-automated.service
echo "[Service]" >> /etc/systemd/system/openstack-automated.service
echo "Type=oneshot" >> /etc/systemd/system/openstack-automated.service
echo "RemainAfterExit=true" >> /etc/systemd/system/openstack-automated.service
echo "ExecStartPost=-`which iptables` -t nat -I POSTROUTING 1 -s \$dummynetwork.0/24 ! -d \$dummynetwork.0/24 -o `ip route get 1|grep dev|awk '{print $5}'` -j MASQUERADE -v" >> /etc/systemd/system/openstack-automated.service
echo "ExecStart=`which bash` -c \"/usr/local/bin/openstack-control.sh start\"" >> /etc/systemd/system/openstack-automated.service
echo "ExecStop=`which bash` -c \"/usr/local/bin/openstack-control.sh stop\"" >> /etc/systemd/system/openstack-automated.service
echo "" >> /etc/systemd/system/openstack-automated.service
echo "[Install]" >> /etc/systemd/system/openstack-automated.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/openstack-automated.service
systemctl daemon-reload
systemctl enable openstack-automated.service

climacent="http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
climaubnt="http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"

mkdir /var/os-images
wget $climacent -O /var/os-images/CentOS-7-x86_64-GenericCloud.qcow2
wget $climaubnt -O /var/os-images/xenial-server-cloudimg-amd64-disk1.img

if [ -f /var/os-images/CentOS-7-x86_64-GenericCloud.qcow2 ]
then
	openstack image create "CentOS-7-x86_64-Cloud" \
	--disk-format qcow2 \
	--public \
	--min-disk 10 \
	--container-format bare \
	--project admin \
	--protected \
	--file /var/os-images/CentOS-7-x86_64-GenericCloud.qcow2
fi

if [ -f /var/os-images/xenial-server-cloudimg-amd64-disk1.img ]
then
	openstack image create "Ubuntu-16.04lts-x86_64-Cloud" \
	--disk-format qcow2 \
	--public \
	--min-disk 10 \
	--container-format bare \
	--project admin \
	--protected \
	--file /var/os-images/xenial-server-cloudimg-amd64-disk1.img
fi

sync
rm -rf /var/os-images

l='m1.tiny m1.small m1.medium m1.large m1.xlarge'
for f in $l
do
	openstack flavor delete f >/dev/null 2>&1
done

openstack flavor create --public \
--ram 512 \
--disk 10 \
--ephemeral 0 \
--swap 1024 \
--vcpus 2 \
m1.tiny

openstack flavor create --public \
--ram 1024 \
--disk 10 \
--ephemeral 0 \
--swap 2048 \
--vcpus 2 \
m1.small

openstack flavor create --public \
--ram 2048 \
--disk 10 \
--ephemeral 0 \
--swap 4096 \
--vcpus 2 \
m1.normal

openstack flavor create --public \
--ram 4096 \
--disk 10 \
--ephemeral 0 \
--swap 8192 \
--vcpus 2 \
m1.big

openstack network create \
--project admin \
--external \
--provider-network-type flat \
--provider-physical-network physical01 \
--description "Admin Project Public NET 01" \
public-01

openstack network create \
--project admin \
--internal \
--provider-network-type gre \
--provider-segment 11 \
--description "Admin Project Internal NET 01" \
internal-admin-01

openstack subnet create \
--project admin \
--network public-01 \
--dhcp  \
--ip-version 4 \
--allocation-pool start=\$dummynetwork.2,end=\$dummynetwork.200 \
--subnet-range \$dummynetwork.0/24 \
--gateway \$dummynetwork.1 \
--dns-nameserver 8.8.8.8 \
--dns-nameserver 8.8.4.4 \
--description "Admin Project External SubNet 01" \
subnet-external-admin-01

openstack subnet create \
--project admin \
--network internal-admin-01 \
--dhcp  \
--ip-version 4 \
--allocation-pool start=172.18.123.2,end=172.18.123.200 \
--subnet-range 172.18.123.0/24 \
--gateway 172.18.123.1 \
--dns-nameserver 8.8.8.8 \
--dns-nameserver 8.8.4.4 \
--description "Admin Project Internal SubNet 01" \
subnet-internal-admin-01

openstack router create \
--project admin \
router-admin-01

openstack router add subnet router-admin-01 subnet-internal-admin-01
openstack router set router-admin-01 --external-gateway public-01

if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_rsa.pub ]
then
	echo "Public/Private key already here!!"
else
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
fi

openstack user create \
--domain default \
--password "\$osadminpass" \
--email "osadmin@localhost" \
--project admin \
osadmin

openstack role add --project admin --user osadmin "_member_"
openstack role add --project admin --user osadmin "admin"
openstack role add --project admin --user osadmin "heat_stack_owner"

cat /root/keystonerc_fulladmin > /root/keystonerc_fullosadmin

sed -r -i "s/OS_USERNAME=admin/OS_USERNAME=osadmin/g" /root/keystonerc_fullosadmin
sed -r -i "s/OS_PASSWORD=.*/OS_PASSWORD=\$osadminpass/g" /root/keystonerc_fullosadmin
sed -r -i "s/keystone_fulladmin/keystone_fullosadmin/g" /root/keystonerc_fullosadmin

source /root/keystonerc_fullosadmin

openstack keypair create \
--public-key /root/.ssh/id_rsa.pub \
key-osadmin-01

echo "User: osadmin" > /root/openstack-credentials.txt
echo "Pass: \$osadminpass" >> /root/openstack-credentials.txt
echo "Domain: default" >> /root/openstack-credentials.txt
echo "Horizon URL: http://`ip route get 1 | awk '{print $NF;exit}'`" >> /root/openstack-credentials.txt
echo "Keystone RC Credentials: /root/keystonerc_fullosadmin" >> /root/openstack-credentials.txt
echo "Private key: /root/.ssh/id_rsa" >> /root/openstack-credentials.txt

iptables -t nat -I POSTROUTING 1 -s \$dummynetwork.0/24 ! -d \$dummynetwork.0/24 -o `ip route get 1|grep dev|awk '{print $5}'` -j MASQUERADE -v

echo "Finished:" &>>\$lgfile
cat /root/openstack-credentials.txt &>>\$lgfile
systemctl disable openstack-installer-automated.service
echo "End Date/Time: `date`" &>>\$lgfile
EOF

chmod 755 /root/final-script.sh
cat <<EOF >/etc/systemd/system/openstack-installer-automated.service
[Unit]
Description=OpenStack AutoInstaller
After=network.target rc-local.service rc.local.service
[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=`which bash` -c "/root/final-script.sh &>>/var/log/aio-openstack-installer.log"
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openstack-installer-automated.service

reboot

# END.-