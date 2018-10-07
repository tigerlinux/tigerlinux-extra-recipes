#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# OpenVPN Server installation script
# Rel 1.1
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/openvpn-server-automated-installer.log"

# Begining of Customization
#
# Ensure to set the following variables to the proper values, specially the
# VPN_PUBLIC_IP. If you don't modify "VPN_PUBLIC_IP", the script will default
# to the server main IP. If you use the name "CURL" the script will try to
# determine the VPN IP from the "outside publicly detectable" IP.
#
EASYRSA_REQ_COUNTRY="US"
EASYRSA_REQ_PROVINCE="Michigan"
EASYRSA_REQ_CITY="Chicago"
EASYRSA_REQ_ORG="TigerLinux Company INC"
EASYRSA_REQ_EMAIL="nobody@none.com"
EASYRSA_REQ_OU="Operations"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
#
VPN_PUBLIC_IP="127.0.0.1"
# VPN_PUBLIC_IP="CURL"
#
# Set also OpenVPN protocol. tcp or udp. Our default is udp
# VPN_PROTOCOL="tcp"
VPN_PROTOCOL="udp"
#
# And the OpenVPN port:
VPN_PORT="1194"
#
# End of Customization

echo "Start Date/Time: `date`" &>>$lgfile

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools \
	git findutils iproute grep openssh sed gawk openssl which xz bzip2 \
	util-linux procps-ng which lvm2 sudo hostname &>>$lgfile
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

if [ $cpus -lt "1" ] || [ $instram -lt "480" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for an OpenVPN Server. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
yum -y install ntp ntpdate firewalld &>>$lgfile
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --reload

systemctl disable postfix
systemctl stop postfix

systemctl stop chronyd
systemctl disable chronyd
systemctl stop ntpd
systemctl start ntpdate
systemctl start ntpd
systemctl enable ntpdate ntpd
sleep 5
ntpq -np &>>$lgfile

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/20-ipforward-openvpn.conf
sysctl -p /etc/sysctl.d/20-ipforward-openvpn.conf

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

yum -y install epel-release &>>$lgfile
yum -y install device-mapper-persistent-data &>>$lgfile

yum -y install openvpn easy-rsa &>>$lgfile

primaryip=`ip route get 1 | awk '{print $NF;exit}'`
curlpublicip=`curl ipinfo.io/ip`

if [ $VPN_PUBLIC_IP == "127.0.0.1" ]
then
	VPN_PUBLIC_IP=$primaryip
fi

if [ $VPN_PUBLIC_IP == "CURL" ]
then
	VPN_PUBLIC_IP=$curlpublicip
fi

cp -v /usr/share/doc/openvpn-*/sample/sample-config-files/server.conf /etc/openvpn/server.conf.example &>>$lgfile

if [ $VPN_PROTOCOL == "tcp" ]
then
	cat <<EOF>/etc/openvpn/server.conf
port $VPN_PORT
mssfix 1200
tun-mtu 1500
auth-nocache
proto tcp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem
server 172.16.27.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
tls-crypt /etc/openvpn/openvpn.tlsauth
auth SHA256
cipher AES-256-CBC
persist-key
persist-tun
script-security 2
tls-cipher DEFAULT:!EXP:!LOW:!PSK:!SRP:!kRSA
comp-lzo
verb 3
user nobody
group nobody
topology subnet
remote-cert-eku "TLS Web Client Authentication"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS $DNS1"
push "dhcp-option DNS $DNS2"
EOF
else
	cat <<EOF>/etc/openvpn/server.conf
port $VPN_PORT
mssfix 1200
tun-mtu 1500
auth-nocache
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem
server 172.16.27.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
tls-crypt /etc/openvpn/openvpn.tlsauth
auth SHA256
cipher AES-256-CBC
persist-key
persist-tun
script-security 2
tls-cipher DEFAULT:!EXP:!LOW:!PSK:!SRP:!kRSA
comp-lzo
verb 3
explicit-exit-notify 1
user nobody
group nobody
topology subnet
remote-cert-eku "TLS Web Client Authentication"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS $DNS1"
push "dhcp-option DNS $DNS2"
EOF
fi

openvpn --genkey --secret /etc/openvpn/openvpn.tlsauth &>>$lgfile

mkdir -p /etc/openvpn/easy-rsa/keys

cp -vrf /usr/share/easy-rsa/3.0/* /etc/openvpn/easy-rsa/ &>>$lgfile

cd /etc/openvpn/easy-rsa

# Initial variables:
cat <<EOF>>vars
set_var EASYRSA_REQ_COUNTRY    "$EASYRSA_REQ_COUNTRY"
set_var EASYRSA_REQ_PROVINCE   "$EASYRSA_REQ_PROVINCE"
set_var EASYRSA_REQ_CITY       "$EASYRSA_REQ_CITY"
set_var EASYRSA_REQ_ORG        "$EASYRSA_REQ_ORG"
set_var EASYRSA_REQ_EMAIL      "$EASYRSA_REQ_EMAIL"
set_var EASYRSA_REQ_OU         "$EASYRSA_REQ_OU"
set_var EASYRSA_KEY_SIZE       4096
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650
EOF

# Basic PKI and CA:
./easyrsa init-pki &>>$lgfile
./easyrsa --batch build-ca nopass &>>$lgfile

# DH file:
./easyrsa gen-dh &>>$lgfile

# Server certs:
./easyrsa build-server-full server nopass &>>$lgfile

# First client:
export EASYRSA_REQ_CN="Client One"
./easyrsa --batch gen-req client01 nopass &>>$lgfile
./easyrsa --batch sign-req client client01 &>>$lgfile

cp -v /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/ &>>$lgfile
cp -v /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/ &>>$lgfile
cp -v /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/ &>>$lgfile
cp -v /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/dh2048.pem &>>$lgfile

mkdir /etc/openvpn/easy-rsa/keys/client01
cp -v /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/easy-rsa/keys/client01/client01-ca.crt &>>$lgfile
cp -v /etc/openvpn/easy-rsa/pki/issued/client01.crt /etc/openvpn/easy-rsa/keys/client01/ &>>$lgfile
cp -v /etc/openvpn/easy-rsa/pki/private/client01.key /etc/openvpn/easy-rsa/keys/client01/ &>>$lgfile
cp -v /etc/openvpn/openvpn.tlsauth /etc/openvpn/easy-rsa/keys/client01/client01-openvpn.tlsauth &>>$lgfile

cat <<EOF>/etc/openvpn/easy-rsa/keys/client01/client01.ovpn
client
tls-client
dev tun
proto $VPN_PROTOCOL
remote $VPN_PUBLIC_IP $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
client01-ca ca.crt
cert client01.crt
key client01.key
tls-crypt client01-openvpn.tlsauth
topology subnet
pull
verb 4
comp-lzo
remote-cert-eku "TLS Web Client Authentication"
keysize 256
remote-cert-tls server
auth SHA256
cipher AES-256-CBC
mssfix 1200
tun-mtu 1500
auth-nocache
EOF

cat <<EOF>/etc/openvpn/easy-rsa/client-template.ovpn
client
tls-client
dev tun
proto $VPN_PROTOCOL
remote $VPN_PUBLIC_IP $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
ca CLIENTNAME-ca.crt
cert CLIENTNAME.crt
key CLIENTNAME.key
tls-crypt CLIENTNAME-openvpn.tlsauth
topology subnet
pull
verb 4
comp-lzo
remote-cert-eku "TLS Web Client Authentication"
keysize 256
remote-cert-tls server
auth SHA256
cipher AES-256-CBC
mssfix 1200
tun-mtu 1500
auth-nocache
EOF

cd /

systemctl enable openvpn@server.service
systemctl start openvpn@server.service
systemctl status openvpn@server.service &>>$lgfile

firewall-cmd --permanent --zone=public --add-port $VPN_PORT/udp
firewall-cmd --permanent --zone=public --add-port $VPN_PORT/tcp
firewall-cmd --permanent --zone=trusted --add-port $VPN_PORT/udp
firewall-cmd --permanent --zone=trusted --add-port $VPN_PORT/tcp
firewall-cmd --permanent --zone=trusted --add-interface=tun0
firewall-cmd --permanent --zone=trusted --add-masquerade
export primarynic=`ip route get 1|grep dev|awk '{print $5}'`
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s  172.16.27.0/24 -o $primarynic -j MASQUERADE
firewall-cmd --reload

echo "/usr/bin/firewall-cmd --permanent --zone=trusted --add-interface=tun0" >> /etc/rc.local
systemctl enable rc-local
chmod 755 /etc/rc.d/rc.local

iptables -v -L -n &>>$lgfile
iptables -v -L -n -t nat &>>$lgfile

cat <<EOF>/usr/local/bin/generate-new-openvpn-client.sh
#!/bin/bash
#
PATH=\$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
#
if [ -z \$1 ]
then
 echo "Missing client name. Example: client02. Example: jane.doe"
 exit 0
fi
cd /etc/openvpn/easy-rsa
export EASYRSA_REQ_CN="OpenVPN Client \$1"
./easyrsa --batch gen-req \$1 nopass
./easyrsa --batch sign-req client \$1
mkdir /etc/openvpn/easy-rsa/keys/\$1
cp -v /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/easy-rsa/keys/\$1/\$1-ca.crt
cp -v /etc/openvpn/easy-rsa/pki/issued/\$1.crt /etc/openvpn/easy-rsa/keys/\$1/
cp -v /etc/openvpn/easy-rsa/pki/private/\$1.key /etc/openvpn/easy-rsa/keys/\$1/
cp -v /etc/openvpn/openvpn.tlsauth /etc/openvpn/easy-rsa/keys/\$1/\$1-openvpn.tlsauth
cd /
cp /etc/openvpn/easy-rsa/client-template.ovpn /etc/openvpn/easy-rsa/keys/\$1/\$1.ovpn
sed -r -i "s/CLIENTNAME/\$1/g" /etc/openvpn/easy-rsa/keys/\$1/\$1.ovpn
echo ""
echo "All your files are on /etc/openvpn/easy-rsa/keys/\$1/"
ls -la /etc/openvpn/easy-rsa/keys/\$1/
echo ""
EOF

chmod 755 /usr/local/bin/generate-new-openvpn-client.sh

if [ $VPN_PROTOCOL == "tcp" ]
then
	checkovn=`ss -ltn|grep -c $VPN_PORT`
else
	checkovn=`ss -lun|grep -c $VPN_PORT`
fi

echo "" &>>$lgfile

if [ $checkovn == "0" ]
then
	echo "OpenVPN Failed to install" &>>$lgfile
else
	echo "OpenVPN Installed"  &>>$lgfile
fi

echo "" &>>$lgfile
echo "End Date/Time: `date`" &>>$lgfile

#
# END
#