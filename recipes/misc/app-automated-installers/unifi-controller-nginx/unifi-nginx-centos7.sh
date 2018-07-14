#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# UniFi controller with nginx front-end
# For Centos 7 64 bits.
# Release 1.1
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/unifi-nginx-server-automated-installer.log"
credfile="/root/unifi-nginx-server-credentials.txt"
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

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for an UniFi controller. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
yum -y install firewalld &>>$lgfile
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --zone=public --add-service=ssh --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8880/tcp --permanent
firewall-cmd --zone=public --add-port=8443/tcp --permanent
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

yum -y install epel-release
yum -y install device-mapper-persistent-data

yum -y install nginx unzip

openssl dhparam -out /etc/nginx/dhparams.pem 2048 &>>$lgfile

cat <<EOF >/etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
 worker_connections 1024;
}

http {
 log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
 '\$status \$body_bytes_sent "\$http_referer" '
 '"\$http_user_agent" "\$http_x_forwarded_for"';

 access_log  /var/log/nginx/access.log  main;
 client_max_body_size 100M;

 sendfile            on;
 tcp_nopush          on;
 tcp_nodelay         on;
 keepalive_timeout   300;
 types_hash_max_size 2048;

 include             /etc/nginx/mime.types;
 default_type        application/octet-stream;

 include /etc/nginx/conf.d/*.conf;

 server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name  _;
  root /usr/share/nginx/html;
  server_tokens off;
  proxy_ssl_verify off;
  proxy_ssl_session_reuse on;
  proxy_cache off;
  proxy_store off;
  proxy_connect_timeout 300;
  proxy_send_timeout 300;
  proxy_read_timeout 86400;
  send_timeout 300;

  include /etc/nginx/default.d/*.conf;

  location /wss {
   proxy_pass https://127.0.0.1:8443;
   proxy_http_version 1.1;
   proxy_buffering off;
   proxy_set_header Upgrade \$http_upgrade;
   proxy_set_header Connection "Upgrade";
   proxy_read_timeout 86400;
  }

  location / {
   proxy_pass https://127.0.0.1:8443;
   proxy_set_header Host \$host;
   proxy_set_header X-Real-IP \$remote_addr;
   proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;
  }

 error_page 404 /404.html;
 location = /40x.html {
 }

 error_page 500 502 503 504 /50x.html;
  location = /50x.html {
  }
 }
 server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  server_name  _;
  root /usr/share/nginx/html;
  server_tokens off;
  proxy_ssl_verify off;
  proxy_ssl_session_reuse on;
  proxy_cache off;
  proxy_store off;
  proxy_connect_timeout 300;
  proxy_send_timeout 300;
  proxy_read_timeout 86400;
  send_timeout 300;

  ssl_certificate "/etc/pki/nginx/server.crt";
  ssl_certificate_key "/etc/pki/nginx/private/server.key";

  include /etc/nginx/default.d/*.conf;

  location /wss {
   proxy_pass https://127.0.0.1:8443;
   proxy_http_version 1.1;
   proxy_buffering off;
   proxy_set_header Upgrade \$http_upgrade;
   proxy_set_header Connection "Upgrade";
   proxy_read_timeout 86400;
  }

  location / {
   proxy_pass https://127.0.0.1:8443;
   proxy_set_header Host \$host;
   proxy_set_header X-Real-IP \$remote_addr;
   proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;
  }

  error_page 404 /404.html;
  location = /40x.html {
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
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

yum -y install java-1.8.0-openjdk &>>$lgfile

# UniFi fails with MongoDB 3.6.. at least for 5.6.x series.
cat <<EOF>/etc/yum.repos.d/mongodb-org-3.4.repo
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF

yum -y update --exclude=kernel* &>>$lgfile
yum install -y mongodb-org &>>$lgfile
systemctl stop mongod.service
systemctl disable mongod.service

wget https://www.ubnt.com/downloads/unifi/5.8.24/UniFi.unix.zip -O /root/unifi.zip &>>$lgfile
unzip /root/unifi.zip -d /opt/ &>>$lgfile
useradd -c "UniFi System User" -d /opt/UniFi -s /bin/bash unifi &>>$lgfile
chown -R unifi.unifi /opt/UniFi

cat <<EOF>/etc/systemd/system/unifi.service
[Unit]
Description=UniFi
After=syslog.target
After=network.target

[Service]
Type=simple
User=unifi
Group=unifi
ExecStart=/usr/bin/java -jar /opt/UniFi/lib/ace.jar start
ExecStop=/usr/bin/java -jar /opt/UniFi/lib/ace.jar stop
# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300
WorkingDirectory=/opt/UniFi

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /var/opt/UniFi/data
ln -s /var/opt/UniFi/data /opt/UniFi/data
chown -R unifi.unifi /var/opt/UniFi /opt/UniFi

systemctl daemon-reload
systemctl start unifi &>>$lgfile
systemctl enable unifi

systemctl enable nginx
systemctl restart nginx &>>$lgfile

sleep 60

systemctl status nginx unifi &>>$lgfile

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

finalcheck=`curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1/|grep -c 302`

if [ $finalcheck == "1" ]
then
	echo "Ready. Your UniFi Controller is ready." &>>$lgfile
	echo "" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "UniFi controller install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
#
# END
#