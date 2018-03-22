#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# ODOO ERP RELEASE 10 Setup for Centos 7 64 bits
# Release 1.6
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

export lgfile="/var/log/odoo-erp-install.log"
echo "Start Date/Time: `date`" &>>$lgfile
export credentialsfile="/root/odoo-credentials.txt"
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

yum -y install firewalld &>>$lgfile
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --reload

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf

yum -y install postgresql-server &>>$lgfile

postgresql-setup initdb &>>$lgfile
systemctl start postgresql
systemctl enable postgresql

yum-config-manager --add-repo=https://nightly.odoo.com/10.0/nightly/rpm/odoo.repo &>>$lgfile
yum -y update --exclude=kernel* &>>$lgfile
curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs &>>$lgfile
yum -y install odoo fontconfig libpng libX11 libXext libXrender \
xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi wkhtmltopdf &>>$lgfile

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

yum -y install nginx &>>$lgfile

cat /etc/nginx/nginx.conf >> /etc/nginx/nginx.conf.original

openssl dhparam -out /etc/nginx/dhparams.pem 2048 &>>$lgfile

cat <<EOF >/etc/nginx/nginx.conf
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
 client_max_body_size 1000m;
 log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
 '\$status \$body_bytes_sent "\$http_referer" '
 '"\$http_user_agent" "\$http_x_forwarded_for"';

 access_log  /var/log/nginx/access.log  main;
 sendfile on;
 tcp_nopush on;
 tcp_nodelay on;
 keepalive_timeout 300;
 types_hash_max_size 2048;
 include /etc/nginx/mime.types;
 default_type application/octet-stream;
 include /etc/nginx/conf.d/*.conf;
 server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  server_tokens off;
  proxy_ssl_verify off;
  proxy_ssl_session_reuse on;
  proxy_cache off;
  proxy_store off;
  proxy_connect_timeout 300;
  proxy_send_timeout 300;
  proxy_read_timeout 300;
  send_timeout 300;
  location / {
   proxy_buffering off;
   proxy_set_header Host \$http_host;
   proxy_pass http://127.0.0.1:8069;
  }
 }
 server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  ssl_certificate "/etc/pki/nginx/server.crt";
  ssl_certificate_key "/etc/pki/nginx/private/server.key";
  include /etc/nginx/default.d/sslconfig.conf;

  server_name _;
  server_tokens off;
  proxy_ssl_verify off;
  proxy_ssl_session_reuse on;
  proxy_cache off;
  proxy_store off;
  proxy_connect_timeout 300;
  proxy_send_timeout 300;
  proxy_read_timeout 300;
  send_timeout 300;
  location / {
   proxy_buffering off;
   proxy_set_header Host \$http_host;
   proxy_pass http://127.0.0.1:8069;
  }
 }
}
EOF

cat <<EOF>/etc/nginx/default.d/sslconfig.conf
ssl_session_cache shared:SSL:1m;
ssl_session_timeout  10m;
ssl_prefer_server_ciphers on;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:!DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
ssl_dhparam /etc/nginx/dhparams.pem;
EOF

cat <<EOF>/etc/nginx/default.d/gzip.conf
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 5;
gzip_http_version 1.1;
gzip_min_length 256;
gzip_types
 application/atom+xml
 application/javascript
 application/json
 application/ld+json
 application/manifest+json
 application/rss+xml
 application/vnd.geo+json
 application/vnd.ms-fontobject
 application/x-font-ttf
 application/x-web-app-manifest+json
 application/xhtml+xml
 application/xml
 font/opentype
 image/bmp
 image/svg+xml
 image/x-icon
 text/cache-manifest
 text/css
 text/plain
 text/vcard
 text/vnd.rim.location.xloc
 text/vtt
 text/x-component
 text/x-cross-domain-policy;
EOF

mkdir -p /etc/pki/nginx
mkdir -p /etc/pki/nginx/private

openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/nginx/private/server.key -out /etc/pki/nginx/server.crt &>>$lgfile

chmod 0600 /etc/pki/nginx/private/server.key
chown nginx.nginx /etc/pki/nginx/private/server.key

systemctl restart nginx
systemctl enable nginx

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

finalcheck=`ss -ltn|grep -c :8069`

echo "ODOO Credentials" > $credentialsfile
echo "Password: $odooadminpassword" >> $credentialsfile
allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
for myip in $allipaddr
do
	echo "URL: http://$myip" >> $credentialsfile
	echo "URL-Encrypted: https://$myip" >> $credentialsfile
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
