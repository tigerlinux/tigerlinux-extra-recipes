#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# ODOO ERP RELEASE 10 Setup for Centos 7 64 bits
# Release 1.2
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/odoo-erp-install.log"
echo "Start Date/Time: `date`" &>>$lgfile
credentialsfile="/root/odoo-credentials.txt"
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
else
	echo "Not a centos server. Aborting!" &>>$lgfile
	exit 0
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export odooadminpassword=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "2" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for ODOO. Aborting!" &>>$lgfile
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

yum -y update --exclude=kernel*

yum -y install postgresql-server

postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql

yum-config-manager --add-repo=https://nightly.odoo.com/10.0/nightly/rpm/odoo.repo
yum -y update --exclude=kernel*
yum -y install odoo fontconfig libpng libX11 libXext libXrender \
xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi wkhtmltopdf

systemctl enable odoo
systemctl start odoo

cat <<EOF >/etc/odoo/odoo.conf
[options]
; This is the password that allows database operations:
admin_passwd = $odooadminpassword
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /usr/lib/python2.7/site-packages/odoo/addons
xmlrpc_interface = 127.0.0.1
EOF

systemctl restart odoo

yum -y install nginx

cat /etc/nginx/nginx.conf >> /etc/nginx/nginx.conf.original

cat <<EOF >/etc/nginx/nginx.conf
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    client_max_body_size 1000m;
    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   120;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;

        server_name `hostname`;
        location / {
           proxy_buffering off;
           proxy_set_header Host \$http_host;
           proxy_pass http://127.0.0.1:8069;
        }
    }
}
EOF

systemctl start nginx
systemctl enable nginx

finalcheck=`ss -ltn|grep -c :8069`

echo "ODOO Credentials" > $credentialsfile
echo "Password: $odooadminpassword" >> $credentialsfile
allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
for myip in $allipaddr
do
	echo "URL: http://$myip" >> $credentialsfile
done

if [ $finalcheck -gt "0" ]
then
	echo "Your ODOO server is ready. See your credentials at $credentialsfile" &>>$lgfile
	cat $credentialsfile &>>$lgfile
else
	echo "Odoo Server install failed" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END