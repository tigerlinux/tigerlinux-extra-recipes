#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Apache TOMCAT with nginx frontend automated installation script
# Rel 1.0
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export OSFlavor='unknown'
export lgfile="/var/log/tomcat-nginx-automated-installer.log"
export credfile="/root/tomcat-nginx-access-credentials.txt"
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

if [ `uname -p 2>/dev/null|grep x86_64|head -n1|wc -l` != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

export tomcatadminpass=`openssl rand -hex 10`

echo "Tomcat CREDENTIALS FILE:" > $credfile
echo "" >> $credfile
echo "tomcat admin: manager, password: $tomcatadminpass" >> $credfile
echo "" >> $credfile

if [ `lscpu -a --extended|grep -ic yes` -lt "1" ] || [ `free -m -t|grep -i mem:|awk '{print $2}'` -lt "900" ] || [ `df -k --output=avail /usr|tail -n 1` -lt "5000000" ] || [ `df -k --output=avail /var|tail -n 1` -lt "5000000" ]
then
	echo "Not enough hardware for syncope. Aborting!" &>>$lgfile
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
firewall-cmd --reload

echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/10-disable-timestamps.conf
sysctl -p /etc/sysctl.d/10-disable-timestamps.conf &>>$lgfile

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

curl \
	-Lo /root/jdk-8u172-linux-x64.rpm \
	--header "Cookie: oraclelicense=accept-securebackup-cookie" \
	"https://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jdk-8u172-linux-x64.rpm" &>>$lgfile
yum -y localinstall /root/jdk-8u172-linux-x64.rpm &>>$lgfile
sync
rm -f /root/jdk-8u172-linux-x64.rpm
if [ `which java 2>/dev/null|wc -l` == "0" ]
then
	yum -y install java-1.8.0-openjdk &>>$lgfile
fi

yum -y install unzip

wget \
--no-cookies \
--no-check-certificate \
--header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
-O /root/jce_policy-8.zip

if [ ! -d /usr/java/latest/jre/lib ]
then
	echo "Oracle OpenJDK failed to install. Aborting" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

mkdir /usr/local/src/java-extra

unzip -d /usr/local/src/java-extra/ /root/jce_policy-8.zip  &>>$lgfile
cp -v /usr/local/src/java-extra/UnlimitedJCEPolicyJDK8/*.jar /usr/java/latest/jre/lib/security/

groupadd tomcat &>>$lgfile
useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat &>>$lgfile

echo "export JAVA_HOME=\"/usr/java/latest/jre\"" >> /etc/profile.d/java-environment.sh
echo "JAVA_HOME=\"/usr/java/latest/jre\"" >> /etc/environment
source /etc/profile.d/java-environment.sh
echo $JAVA_HOME &>>$lgfile
ln -s /usr/java/latest /usr/lib/jvm
export JAVA_HOME="/usr/java/latest/jre"

wget http://www-us.apache.org/dist/tomcat/tomcat-8/v8.5.32/bin/apache-tomcat-8.5.32.tar.gz -O /root/apache-tomcat.tar.gz &>>$lgfile

tar -xzvf /root/apache-tomcat.tar.gz -C /opt/ &>>$lgfile
mv /opt/apache-tomcat-* /opt/tomcat
chown -R tomcat.tomcat /opt/tomcat
ln -s /opt/tomcat /opt/apache-tomcat

if [ ! -f /opt/tomcat/bin/startup.sh ]
then
	echo "Tomcat failed to install. Aborting" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0	
fi

cat<<EOF>/etc/systemd/system/tomcat.service
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/java/latest/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/bin/kill -15 \$MAINPID

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF>/opt/tomcat/conf/tomcat-users.xml
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="manager-jmx"/>
  <role rolename="manager-status"/>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>
  <user username="manager" password="$tomcatadminpass" roles="manager-script,manager-gui,manager-status,manager-jmx,admin-gui,admin-script"/>
</tomcat-users>
EOF

systemctl daemon-reload
systemctl restart tomcat
systemctl enable tomcat &>>$lgfile
systemctl status tomcat &>>$lgfile

wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz -O /root/maven.tar.gz &>>$lgfile
tar -xzvf /root/maven.tar.gz -C /opt/ &>>$lgfile
rm -f /root/maven.tar.gz
mv /opt/apache-maven-* /opt/apache-maven
echo "export PATH=\$PATH:/opt/apache-maven/bin" > /etc/profile.d/maven-environment.sh
ln -s /opt/apache-maven/bin/mvn /usr/local/bin/mvn
source /etc/profile.d/maven-environment.sh
mvn -v &>>$lgfile

yum -y install nginx httpd-tools &>>$lgfile

cat /etc/nginx/nginx.conf >> /etc/nginx/nginx.conf.original

openssl dhparam -out /etc/nginx/dhparams.pem 2048 &>>$lgfile

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
 sendfile on;
 tcp_nopush on;
 tcp_nodelay on;
 keepalive_timeout 65;
 types_hash_max_size 2048;
 include /etc/nginx/mime.types;
 default_type application/octet-stream;
 include /etc/nginx/conf.d/*.conf;
 server {
  listen       80 default_server;
  listen       [::]:80 default_server;
  server_name _;
  location / {
   proxy_http_version 1.1;
   proxy_set_header Upgrade \$http_upgrade;
   proxy_set_header Connection 'upgrade';
   proxy_set_header Host \$host;
   proxy_pass http://127.0.0.1:8080;
  }
 }
 server {
  listen 443 ssl http2 default_server;
  listen [::]:443 ssl http2 default_server;
  ssl_certificate "/etc/pki/nginx/server.crt";
  ssl_certificate_key "/etc/pki/nginx/private/server.key";
  include /etc/nginx/default.d/sslconfig.conf;
  server_name _;
  location / {
   proxy_http_version 1.1;
   proxy_set_header Upgrade \$http_upgrade;
   proxy_set_header Connection 'upgrade';
   proxy_set_header Host \$host;
   proxy_pass http://127.0.0.1:8080;
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

systemctl restart nginx &>>$lgfile
systemctl enable nginx &>>$lgfile
systemctl status nginx &>>$lgfile

wget \
https://downloads.mariadb.com/Connectors/java/connector-java-2.2.2/mariadb-java-client-2.2.2.jar -O \
/opt/tomcat/lib/mariadb-java-client-2.2.2.jar &>>$lgfile

wget \
https://jdbc.postgresql.org/download/postgresql-42.2.1.jar -O \
/opt/tomcat/lib/postgresql-42.2.1.jar &>>$lgfile

chown tomcat.tomcat /opt/tomcat/lib/mariadb-java-client-2.2.2.jar
chown tomcat.tomcat /opt/tomcat/lib/postgresql-42.2.1.jar

systemctl restart tomcat &>>$lgfile

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

echo "Waiting 30 seconds" &>>$lgfile
sleep 30
systemctl status tomcat &>>$lgfile
systemctl status nginx &>>$lgfile

finalcheck=`curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1/|grep -c 200`

if [ $finalcheck == "1" ]
then
	echo "Ready. Your Tomcat server is ready. See your tomcat admin credentials at $credfile" &>>$lgfile
	echo "" &>>$lgfile
	cat $credfile &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "Tomcat Server install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
#
# END
#