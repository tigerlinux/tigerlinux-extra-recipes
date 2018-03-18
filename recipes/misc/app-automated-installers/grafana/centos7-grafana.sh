#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# GRAFANA Server Installation Script
# Rel 1.1
# For usage on centos7 64 bits machines.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
OSFlavor='unknown'
lgfile="/var/log/grafana-server-automated-installer.log"
credfile="/root/grafana-server-credentials.txt"
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

export mariadbpass=`openssl rand -hex 10`
export grafanadbpass=`openssl rand -hex 10`
export mariadbip='127.0.0.1'
export grafanapass=`openssl rand -hex 10`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "800" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for a PHPIPAM Server. Aborting!" &>>$lgfile
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

cat <<EOF >/etc/yum.repos.d/mariadb101.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum -y update --exclude=kernel* &>>$lgfile
yum -y install MariaDB MariaDB-server MariaDB-client galera crudini &>>$lgfile

cat <<EOF >/etc/my.cnf.d/server-grafana.cnf
[mysqld]
binlog_format = ROW
default-storage-engine = innodb
innodb_autoinc_lock_mode = 2
query_cache_type = 1
query_cache_size = 8388608
query_cache_limit = 1048576
bind-address = $mariadbip
max_allowed_packet = 1024M
max_connections = 1000
innodb_doublewrite = 1
innodb_log_file_size = 100M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table
EOF

mkdir -p /etc/systemd/system/mariadb.service.d/
cat <<EOF >/etc/systemd/system/mariadb.service.d/limits.conf
[Service]
LimitNOFILE=65535
EOF

cat <<EOF >/etc/security/limits.d/10-mariadb.conf
mysql hard nofile 65535
mysql soft nofile 65535
EOF

systemctl --system daemon-reload &>>$lgfile

systemctl enable mariadb.service &>>$lgfile
systemctl start mariadb.service &>>$lgfile

cat<<EOF >/root/os-db.sql
UPDATE mysql.user SET Password=PASSWORD('$mariadbpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$mariadbpass' WITH GRANT OPTION;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS grafanadb default character set utf8;
GRANT ALL ON grafanadb.* TO 'grafanadbuser'@'%' IDENTIFIED BY '$grafanadbpass';
GRANT ALL ON grafanadb.* TO 'grafanadbuser'@'127.0.0.1' IDENTIFIED BY '$grafanadbpass';
GRANT ALL ON grafanadb.* TO 'grafanadbuser'@'localhost' IDENTIFIED BY '$grafanadbpass';
USE grafanadb;
CREATE TABLE \`session\` (
    \`key\`       CHAR(16) NOT NULL,
    \`data\`      BLOB,
    \`expiry\`    INT(11) UNSIGNED NOT NULL,
    PRIMARY KEY (\`key\`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
FLUSH PRIVILEGES;
EOF

mysql < /root/os-db.sql >> $credfile

cat<<EOF >/root/.my.cnf
[client]
user = "root"
password = "$mariadbpass"
host = "localhost"
EOF

chmod 0600 /root/.my.cnf

rm -f /root/os-db.sql

echo "Database credentials:" > $credfile
echo "User: root" >> $credfile
echo "Password: $mariadbpass" >> $credfile
echo "Listen IP: $mariadbip" >> $credfile
echo "Grafana Database: grafanadb" >> $credfile
echo "Grafana DB User: grafanadbuser" >> $credfile
echo "Grafana DB User Password: $grafanadbpass" >> $credfile
echo "Grafana User: admin" >> $credfile
echo "Grafana Initial password: admin" >> $credfile
echo "URL: http://YOUR_SERVER_IP" >> $credfile
echo "URL: https://YOUR_SERVER_IP" >> $credfile
echo "Grafana Admin User: admin" >> $credfile
echo "Grafana Admin User Password: $grafanapass" >> $credfile

yum -y install nginx &>>$lgfile

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
   sendfile            on;
   tcp_nopush          on;
   tcp_nodelay         on;
   keepalive_timeout   65;
   types_hash_max_size 2048;
   include             /etc/nginx/mime.types;
   default_type        application/octet-stream;
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
        proxy_pass http://127.0.0.1:3000;
     }
   }
   server {
      listen       443 ssl http2 default_server;
      listen       [::]:443 ssl http2 default_server;
      ssl_certificate "/etc/pki/nginx/server.crt";
      ssl_certificate_key "/etc/pki/nginx/private/server.key";
      include /etc/nginx/default.d/sslconfig.conf;

      server_name _;

      location / {
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_pass http://127.0.0.1:3000;
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

mkdir -p /etc/pki/nginx
mkdir -p /etc/pki/nginx/private

openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/nginx/private/server.key -out /etc/pki/nginx/server.crt &>>$lgfile

chmod 0600 /etc/pki/nginx/private/server.key
chown nginx.nginx /etc/pki/nginx/private/server.key

systemctl enable nginx &>>$lgfile

yum -y install initscripts fontconfig &>>$lgfile
yum -y install https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.6.2-1.x86_64.rpm &>>$lgfile

systemctl daemon-reload &>>$lgfile
systemctl enable grafana-server &>>$lgfile
systemctl stop grafana-server &>>$lgfile

crudini --set /etc/grafana/grafana.ini server http_addr 127.0.0.1
crudini --set /etc/grafana/grafana.ini server http_port 3000
crudini --set /etc/grafana/grafana.ini database type mysql
crudini --set /etc/grafana/grafana.ini database host "127.0.0.1:3306"
crudini --set /etc/grafana/grafana.ini database name grafanadb
crudini --set /etc/grafana/grafana.ini database user grafanadbuser
crudini --set /etc/grafana/grafana.ini database password $grafanadbpass
crudini --set /etc/grafana/grafana.ini security admin_user admin
crudini --set /etc/grafana/grafana.ini security admin_password $grafanapass

systemctl restart nginx grafana-server &>>$lgfile

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

systemctl crond

finalcheck=`curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1/|grep -c 302`

if [ $finalcheck == "1" ]
then
	echo "Your GRAFANA Server is ready. See your credentials at $credfile" &>>$lgfile
	echo "" &>>$lgfile
	cat $credfile &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
else
	echo "GRAFANA Server install failed" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
fi
