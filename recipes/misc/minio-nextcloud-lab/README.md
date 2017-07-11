# [NEXTCLOUD WITH MINIO (S3 MODE) PRIMARY STORAGE BACKEND - CENTOS7.](http://tigerlinux.github.io)


- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**



## What is our goal here ?:

Minio is another relatively new technology for object storage with an AWS-S3 compatible api aimed to be easy and fast to implement. We have three goals here:

- First goal: Install a minio server the fastest way possible by using a docker container.
- Second goal: Install a nextcloud server and change it's primary storage in order to use the minio serveron AWS-S3 compatible mode.
- Third goal: Secure our minio service behind an NGINX server trough the use of proxypass.


## Base environment:

Two servers (cloud instances, OpenStack based): Base O/S: Centos 7, selinux and firewalld disabled, EPEL repo installed and available. Fully updated:

Minio server: server-16.virtualstack2.gatuvelus.home (192.168.150.16)
Nextcloud server: server-22.virtualstack2.gatuvelus.home (192.168.150.22)

The minio server has a second volume attached as /dev/vdb for additional storage. This storage will be used as persistent storage for the minio service.


## Minio installation:

Our minio server (192.168.150.16) contains an additional volume attached to it as /dev/vdb. With the following instructions, we'll format and mount this volume:

```bash
mkfs.xfs -L miniostorage /dev/vdb -f

mkdir /mnt/storage

cp /etc/fstab /etc/fstab.ORIGINAL

cat <<EOF >>/etc/fstab
LABEL=miniostorage  /mnt/storage  xfs  defaults 0 0
EOF

```

We are going to use Docker for our Minio installation. With the following commands, we proceed to install docker:

```bash
yum -y install yum-utils device-mapper-persistent-data lvm2

yum-config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

yum -y update
yum -y install docker-ce

systemctl start docker
systemctl enable docker

```


Finally, we can deploy our container-based service using the following commands:

```bash
docker pull minio/minio

mkdir -p /mnt/storage/minioserver01/data
mkdir -p /mnt/storage/minioserver01/config

docker run \
--detach -it \
--name minioserver01 \
--restart unless-stopped \
-p 9000:9000 \
-v /mnt/storage/minioserver01/data:/export \
-v /mnt/storage/minioserver01/config:/root/.minio \
minio/minio server /export

```

**NOTE: Our minio server will use the mounted storage for persistence. Both the data and minio configuration will be stored on the persistent volume.**

With the dockerized minio service running, we can download and install the "minio cli" and some other utilities we are going to use later:

```bash
yum -y install wget jq
wget https://dl.minio.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/miniocli
chmod 755 /usr/local/bin/miniocli
```

**NOTE: The reason we are renaming mc to miniocli is because there is a very popular programm called "midnight commander" which main executable is also "mc".**

Our minio server config file will be located at /mnt/storage/minioserver01/config/config.json (In the persistent volume). This file contains the access key and the secret. By using the "jq" utility we installed previously, we can obtain both the access and the secret:

```bash
cat /mnt/storage/minioserver01/config/config.json |jq '.credential.accessKey'
"OLBSDFQ13IPAYT5OCL0A"

cat /mnt/storage/minioserver01/config/config.json |jq '.credential.secretKey'
"qmX6zOqOTXsHith0dWLnNi5SkzILRaCTLoZRe33T"
```

We'll need the access and secret in order to configure the minion client. Our server name config inside the client will be "minioserver01":

```bash
miniocli config host add minioserver01 \
http://127.0.0.1:9000 \
`cat /mnt/storage/minioserver01/config/config.json |jq '.credential.accessKey'|cut -d\" -f2` \
`cat /mnt/storage/minioserver01/config/config.json |jq '.credential.secretKey'|cut -d\" -f2` \
S3v4
```

The last command will return:

```bash
Added `minioserver01` successfully.
```

Now, let's do some testing. First, let's create a bucket:

```bash
miniocli mb minioserver01/bucket01

Bucket created successfully `minioserver01/bucket01`.
```

**NOTE: All commands issued to "miniocli/mc" must include the "server" name configured previously when called the "miniocli config host add XXXX" command.**

Now, let's copy a file onto the bucket, and list all buckets and files on "minioserver01":

```bash
 miniocli cp /etc/bashrc minioserver01/bucket01
/etc/bashrc:                2.79 KB / 2.79 KB ?¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦? 100.00% 39.33 KB/s 0s

miniocli ls minioserver01

[2017-07-10 17:37:13 -04]     0B bucket01/

miniocli ls minioserver01/bucket01
[2017-07-10 17:37:13 -04] 2.8KiB bashrc

```

Let's erase our files and bucket:

```bash
 miniocli rm minioserver01/bucket01/bashrc
Removing `minioserver01/bucket01/bashrc`.

miniocli rm minioserver01/bucket01
Removing `minioserver01/bucket01`.
```

That concludes basic minio installation and testing.



## Nextcloud installation and configuration.

With our S3 compatible minio server up and running, we can proceed to install nextcloud. Now, we'll work on the nextcloud server (192.168.150.22).

First, we need a good database. We'll install and configure MariaDB 10.1 in our nextcloud server:

```bash
cat <<EOF >/etc/yum.repos.d/mariadb101.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum -y update
yum -y install MariaDB MariaDB-server MariaDB-client galera
yum -y install crudini

echo "" > /etc/my.cnf.d/server-nextcloud.cnf

crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld binlog_format ROW
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld default-storage-engine innodb
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld innodb_autoinc_lock_mode 2
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld query_cache_type 0
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld query_cache_size 0
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld bind-address 127.0.0.1
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld max_allowed_packet 1024M
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld max_connections 1000
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld innodb_doublewrite 1
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld innodb_log_file_size 100M
crudini --set /etc/my.cnf.d/server-nextcloud.cnf mysqld innodb_flush_log_at_trx_commit 2
echo "innodb_file_per_table" >> /etc/my.cnf.d/server-nextcloud.cnf

mkdir -p /etc/systemd/system/mariadb.service.d/
echo "[Service]" > /etc/systemd/system/mariadb.service.d/limits.conf
echo "LimitNOFILE=65535" >> /etc/systemd/system/mariadb.service.d/limits.conf
echo "mysql hard nofile 65535" > /etc/security/limits.d/10-mariadb.conf
echo "mysql soft nofile 65535" >> /etc/security/limits.d/10-mariadb.conf

systemctl --system daemon-reload

systemctl enable mariadb.service
systemctl start mariadb.service

/usr/bin/mysqladmin -u root password "P@ssw0rd"

echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"P@ssw0rd\""  >> /root/.my.cnf
echo "host = \"localhost\""  >> /root/.my.cnf
chmod 0600 /root/.my.cnf

mysql -e "CREATE DATABASE nextcloud;"

``` 

After our database setup is done, let's install some dependencies and perform some basic php config. Note that we are installing php7 from external repositories. Nextcloud requires php > 5.6, and centos 7 comes with php 5.4:

```bash
yum -y install https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update
yum -y erase php-common
yum -y install httpd mod_php71w php71w php71w-opcache \
php71w-pear php71w-pdo php71w-xml php71w-pdo_dblib \
php71w-mbstring php71w-mysql php71w-mcrypt php71w-fpm \
php71w-bcmath php71w-gd php71w-cli php71w-zip php71w-dom \
php71w-pecl-memcached php71w-pecl-redis redis

crudini --set /etc/php.ini PHP upload_max_filesize 100M
crudini --set /etc/php.ini PHP post_max_size 100M

systemctl enable redis
systemctl start redis

```

Now, we can proceed to download and decompress nextcloud:

```bash
wget https://download.nextcloud.com/server/releases/latest-11.zip -O /root/latest-11.zip
unzip /root/latest-11.zip -d /var/www/html/
```

And create the following file (just a little touch to redirect our default website to /nextcloud):

```bash
cat <<EOF >/var/www/html/index.html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/nextcloud">
</HEAD>
<BODY>
</BODY>
</HTML>
EOF
```

We proceed to create the data directory and set the following permissions:

```bash
mkdir -p /var/lib/nextcloud/data
chown -R apache.apache /var/lib/nextcloud
chown -R apache.apache /var/www/html/nextcloud
```

**NOTE: Alsways create the data directory outside the webserver document directory.**

Running the following command will finish nextcloud base installation:

```bash
sudo -u apache /usr/bin/php \
/var/www/html/nextcloud/occ maintenance:install \
--database "mysql" \
--database-host 127.0.0.1:3306 \
--database-name "nextcloud"  \
--database-user "root" \
--database-pass "P@ssw0rd" \
--admin-user "admin" \
--admin-pass "P@ssw0rd" \
--data-dir="/var/lib/nextcloud/data"
```

The last command will output:

```bash
Nextcloud is not installed - only a limited number of commands are available
Nextcloud was successfully installed
```

Also, we need to run the following commands in order to include the hostname and server IP in our "allowed hostname" list:

```bash
sudo -u apache /usr/bin/php \
/var/www/html/nextcloud/occ \
config:system:set \
trusted_domains 1 \
--value=`ifconfig eth0|grep inet|grep -v inet6|awk '{print $2}'`

sudo -u apache /usr/bin/php \
/var/www/html/nextcloud/occ \
config:system:set \
trusted_domains 2 \
--value=`hostname`

```

We can start/enable apache now:

```bash
systemctl start httpd
systemctl enable httpd
```

Our configuration file (/var/www/html/nextcloud/config/config.php) will end like the following one:

```bash
<?php
$CONFIG = array (
  'passwordsalt' => 'arJ8LnHvCPiQ/rHGaK6fG0UGM1WHfQ',
  'secret' => '59wGub4yD28cv8kACSKQXD7olbvpUdYytOw6IYPD4btX5JSm',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => '192.168.150.22',
    2 => 'server-22.virtualstack2.gatuvelus.home',
  ),
  'datadirectory' => '/var/lib/nextcloud/data',
  'overwrite.cli.url' => 'http://localhost',
  'dbtype' => 'mysql',
  'version' => '11.0.3.2',
  'dbname' => 'nextcloud',
  'dbhost' => '127.0.0.1:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'oc_admin1',
  'dbpassword' => '0MWw7WnsxQVTxFskGhs9gpCzZOnlJH',
  'logtimezone' => 'UTC',
  'installed' => true,
  'instanceid' => 'ocprl7a72f3r',
);

```

We need to include the following sections for our S3-Like minio storage, and for the redis cache:

```bash
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => 'localhost',
    'port' => 6379,
    'timeout' => 0.0,
    'password' => '', // Optional, if not defined no password will be used.
  ),
  'objectstore' => [
    'class' => 'OC\\Files\\ObjectStore\\S3',
    'arguments' => [
      'bucket' => 'nextcloud',
      'autocreate' => true,
      'key'    => 'OLBSDFQ13IPAYT5OCL0A',
      'secret' => 'qmX6zOqOTXsHith0dWLnNi5SkzILRaCTLoZRe33T',
      'hostname' => '192.168.150.16',
      'port' => 9000,
      'use_ssl' => false,
      'region' => 'optional',
      'use_path_style' => true
    ],
  ],

```

We can automate this task with some smart use of linux tools:

```bash
sed -i '$ d' /var/www/html/nextcloud/config/config.php

cat <<EOF >>/var/www/html/nextcloud/config/config.php
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => 'localhost',
    'port' => 6379,
    'timeout' => 0.0,
    'password' => '', // Optional, if not defined no password will be used.
  ),
  'objectstore' => [
    'class' => 'OC\\Files\\ObjectStore\\S3',
    'arguments' => [
      'bucket' => 'nextcloud',
      'autocreate' => true,
      'key'    => 'OLBSDFQ13IPAYT5OCL0A',
      'secret' => 'qmX6zOqOTXsHith0dWLnNi5SkzILRaCTLoZRe33T',
      'hostname' => '192.168.150.16',
      'port' => 9000,
      'use_ssl' => false,
      'region' => 'optional',
      'use_path_style' => true
    ],
  ],
);
EOF

```

Our final config will be:

```bash
<?php
$CONFIG = array (
  'passwordsalt' => 'arJ8LnHvCPiQ/rHGaK6fG0UGM1WHfQ',
  'secret' => '59wGub4yD28cv8kACSKQXD7olbvpUdYytOw6IYPD4btX5JSm',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => '192.168.150.22',
    2 => 'server-22.virtualstack2.gatuvelus.home',
  ),
  'datadirectory' => '/var/lib/nextcloud/data',
  'overwrite.cli.url' => 'http://localhost',
  'dbtype' => 'mysql',
  'version' => '11.0.3.2',
  'dbname' => 'nextcloud',
  'dbhost' => '127.0.0.1:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'oc_admin1',
  'dbpassword' => '0MWw7WnsxQVTxFskGhs9gpCzZOnlJH',
  'logtimezone' => 'UTC',
  'installed' => true,
  'instanceid' => 'ocprl7a72f3r',
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => 'localhost',
    'port' => 6379,
    'timeout' => 0.0,
    'password' => '', // Optional, if not defined no password will be used.
  ),
  'objectstore' => [
    'class' => 'OC\Files\ObjectStore\S3',
    'arguments' => [
      'bucket' => 'nextcloud',
      'autocreate' => true,
      'key'    => 'OLBSDFQ13IPAYT5OCL0A',
      'secret' => 'qmX6zOqOTXsHith0dWLnNi5SkzILRaCTLoZRe33T',
      'hostname' => '192.168.150.16',
      'port' => 9000,
      'use_ssl' => false,
      'region' => 'optional',
      'use_path_style' => true
    ],
  ],
);

```

We proceed to apache:

```bash
systemctl restart httpd
```

After restarting apache, nextcloud is ready to work using minio as S3-Like backend.



## Using nginx with proxypass for Minio.

Well do a change in our setup. We'll put an nginx server in front of Minio, and reconfigure nextcloud to use the nginx service running on port 80. Also we'll reconfigure our docker service in order to expose its port only trough localhost.

Our first task is to reconfigure or containerized minio service to run on localhost:9000. In our minio server (192.168.150.16) we proceedo to run the following commands:

```bash
docker rm -f minioserver01

docker run \
--detach -it \
--name minioserver01 \
--restart unless-stopped \
-p 127.0.0.1:9000:9000 \
-v /mnt/storage/minioserver01/data:/export \
-v /mnt/storage/minioserver01/config:/root/.minio \
minio/minio server /export

```

Second task: On our minio server (192.168.150.16) we proceed to install nginx, create an nginx config with proxypass and start/enable nginx:

```bash
yum -y install nginx

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original

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
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;

        server_name server-16.virtualstack2.gatuvelus.home;
        location / {
           proxy_buffering off;
           proxy_set_header Host \$http_host;
           proxy_pass http://127.0.0.1:9000;
        }
    }
}
EOF

systemctl start nginx
systemctl enable nginx

```

By the way: Minio will be fully reachable trough the server default website: http://server-16.virtualstack2.gatuvelus.home. Using the access/secret you can enter to minio interface and do some basic tasks.

Finally on our nextcloud server (192.168.150.22) we need to change the IP and PORT of our S3-Minio service. This time, we'll use the server hostname (server-16.virtualstack2.gatuvelus.home) and the port 80 tcp instead of the port 9000 tcp:

Runing the following commands on the nextcloud server (192.168.150.22) will change our backend address and port:

```bash
sed -r -i 's/192.168.150.16/server-16.virtualstack2.gatuvelus.home/g' /var/www/html/nextcloud/config/config.php
sed -r -i 's/9000/80/g' /var/www/html/nextcloud/config/config.php

systemctl restart redis
systemctl restart httpd

```

Ready !. Our nextcloud setup will use the minio server exposing its services trough nginx proxypass.

END.-

