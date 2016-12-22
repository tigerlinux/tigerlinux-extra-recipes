# AWS (EC2-API) EXTENDED SUPPORT INSTALL ON OPENSTACK (LIBERTY OVER UBUNTU 14.04LTS).

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to include the EC2-API extended support into an existing OpenStack cloud based on Ubuntu 14.04lts. Due the fact that currently there is no EC2 packages in the ["Ubuntu Cloud Archive"](http://ubuntu-cloud.archive.canonical.com/ubuntu/) repo for Kilo, Liberty or Mitaka, we'll proceed to include the EC2 support directly from their main [Github Site.](https://github.com/openstack/ec2-api)


## Where are we going to install it ?:

Monolithic OpenStack LAB Cloud (Just one all-in-one server, IP 192.168.56.101) with external database backend (172.16.32.117) and **OpenStack LIBERTY installed over Ubuntu 14.04lts**. The platform was installed by using the openstack automated installer available at the following link:

* [TigerLinux OpenStack LIBERTY Automated Installer for Ubuntu 14.04lts](https://github.com/tigerlinux/openstack-liberty-installer-ubuntu1404lts)


## How we constructed the whole thing ?:


### EC2 Support installation from source:

First, we need to install some packages:

```
apt-get update
apt-get install libxslt-dev libz-dev libxml2-dev python-pip python-dev git
```

We proceed to download the packages from github, checkout to the version needed for our OpenStack release, and install the software:

```
cd /usr/local/src
git clone https://github.com/openstack/ec2-api/
cd /usr/local/src/ec2-api/
git checkout tags/1.0.2
pip install -e ./
```

We'll finish with the following files:

```
/usr/local/bin/ec2-api
/usr/local/bin/ec2-api-manage
/usr/local/bin/ec2-api-metadata
/usr/local/bin/ec2-api-s3
```

We add our EC2-API User and a lot of needed directories. Also set the proper permissions:

```
useradd  -c "EC2-Api User" -d /var/lib/ec2api -m -s /bin/bash ec2api

mkdir -p /var/lib/ec2api
mkdir -p /etc/ec2api
mkdir -p /var/log/ec2api

cp /usr/local/src/ec2-api/etc/ec2api/api-paste.ini /etc/ec2api/
touch /etc/ec2api/ec2api.conf

chown -R ec2api.ec2api /var/lib/ec2api /etc/ec2api /var/log/ec2api
mv /usr/local/bin/ec2-api* /usr/bin/
ln -s /usr/bin/ec2-api-manage /usr/bin/ec2api-manage
```

Note that in the steps above we moved our EC2 python files from `/usr/local/bin` to `/usr/bin`.

Now, using "crudini", we proceed to configure EC2:

```
crudini --set /etc/ec2api/ec2api.conf DEFAULT admin_user nova
crudini --set /etc/ec2api/ec2api.conf DEFAULT admin_password "P@ssw0rd"
crudini --set /etc/ec2api/ec2api.conf DEFAULT admin_tenant_name services

crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2api_listen 0.0.0.0
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2api_listen_port 8788
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2api_use_ssl false

crudini --set /etc/ec2api/ec2api.conf DEFAULT metadata_listen 0.0.0.0
crudini --set /etc/ec2api/ec2api.conf DEFAULT metadata_listen_port 8789
crudini --set /etc/ec2api/ec2api.conf DEFAULT metadata_use_ssl false

crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_url "http://192.168.56.101:5000/v3"
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_ec2_tokens_url "http://192.168.56.101:5000/v3/ec2tokens"

crudini --set /etc/ec2api/ec2api.conf DEFAULT my_ip 192.168.56.101
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_host 192.168.56.101
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_port 8788
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_scheme http
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_path "/services/Cloud"
crudini --set /etc/ec2api/ec2api.conf DEFAULT region_list nova

crudini --set /etc/ec2api/ec2api.conf DEFAULT full_vpc_support true
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_host 192.168.56.101
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_port 3334
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_use_ssl false
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_private_dns_show_ip true
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_listen 0.0.0.0
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_listen_port 3334

crudini --set /etc/ec2api/ec2api.conf database connection "mysql://ec2apidbuser:P@ssw0rd@172.16.32.117:3306/ec2apidb"

crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_uri "http://192.168.56.101:5000/"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken identity_uri "http://192.168.56.101:35357/"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_version v3
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_user nova
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_password "P@ssw0rd"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_tenant_name services
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_url http://192.168.56.101:35357
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_plugin password
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken project_domain_id default
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken user_domain_id default
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken project_name services
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken username nova
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken password P@ssw0rd

crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_ip 192.168.56.101
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_port 8775
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_protocol http
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_insecure true
crudini --set /etc/ec2api/ec2api.conf metadata metadata_proxy_shared_secret "P@ssw0rd"

crudini --set /etc/ec2api/ec2api.conf DEFAULT tempdir "/tmp"
crudini --set /etc/ec2api/ec2api.conf DEFAULT api_paste_config "/etc/ec2api/api-paste.ini"
crudini --set /etc/ec2api/ec2api.conf DEFAULT state_path "/var/lib/ec2api"
crudini --set /etc/ec2api/ec2api.conf DEFAULT internal_service_availability_zone nova

crudini --set /etc/ec2api/ec2api.conf DEFAULT log_file "/var/log/ec2api/ec2api.log"
```

**NOTE:** We detected some issues on Liberty when V3 authentication is used. In order to avoid such issues, we set Auth V2 (this can change in Mitaka):

```
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_version v2.0
crudini --del /etc/ec2api/ec2api.conf keystone_authtoken project_domain_id
crudini --del /etc/ec2api/ec2api.conf keystone_authtoken user_domain_id
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_url "http://192.168.56.101:5000/v2.0"
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_ec2_tokens_url "http://192.168.56.101:5000/v2.0/ec2tokens"
```

In the Database Server, we proceed to create the EC2 database and user:

```
mysql> CREATE DATABASE ec2apidb default character set utf8;
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'%' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'192.168.56.101' IDENTIFIED BY 'P@ssw0rd';
mysql> FLUSH PRIVILEGES;
```

We proceed to provision/populate the database:

```
su ec2api -s /bin/sh -c "ec2-api-manage --config-file /etc/ec2api/ec2api.conf db_sync"
```

**VERY IMPORTANT NOTE:** On early versions of EC2 support for OpenStack, you need to enable Cinder V1 Api. In later versions this has been corrected:

Cinder V1 api reactivation:

```
crudini --set /etc/cinder/cinder.conf DEFAULT enable_v1_api true
openstack-control.sh restart cinder
```

We proceed to create the "upstart" control files for our services:

```
/usr/bin/ec2-api
/usr/bin/ec2-api-metadata
/usr/bin/ec2-api-s3
```

Create the file:

```
vi /etc/init/ec2-api.conf
```

Containing:

```
description "OpenStack AWS-EC2 API"
author "Reynaldo Martinez <tigerlinux@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

chdir /var/run

respawn
respawn limit 20 5
limit nofile 65535 65535

pre-start script
        for i in lock run log lib ; do
                mkdir -p /var/$i/ec2api
                chown ec2api /var/$i/ec2api
        done
end script

script
        [ -x "/usr/bin/ec2-api" ] || exit 0
        DAEMON_ARGS=""
        [ -r /etc/default/openstack ] && . /etc/default/openstack
        [ -r /etc/default/$UPSTART_JOB ] && . /etc/default/$UPSTART_JOB
        [ "x$USE_SYSLOG" = "xyes" ] && DAEMON_ARGS="$DAEMON_ARGS --use-syslog"
        [ "x$USE_LOGFILE" != "xno" ] && DAEMON_ARGS="$DAEMON_ARGS --log-file=/var/log/ec2api/ec2api.log"

        exec start-stop-daemon --start --chdir /var/lib/ec2api \
                --chuid ec2api:ec2api --make-pidfile --pidfile /var/run/ec2api/ec2-api.pid \
                --exec /usr/bin/ec2-api -- --config-file=/etc/ec2api/ec2api.conf ${DAEMON_ARGS}
end script
```

Create the file:

```
vi /etc/init/ec2-api-metadata.conf
```

Containing:

```
description "OpenStack AWS-EC2 API Metadata Service"
author "Reynaldo Martinez <tigerlinux@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

chdir /var/run

respawn
respawn limit 20 5
limit nofile 65535 65535

pre-start script
        for i in lock run log lib ; do
                mkdir -p /var/$i/ec2api
                chown ec2api /var/$i/ec2api
        done
end script

script
        [ -x "/usr/bin/ec2-api-metadata" ] || exit 0
        DAEMON_ARGS=""
        [ -r /etc/default/openstack ] && . /etc/default/openstack
        [ -r /etc/default/$UPSTART_JOB ] && . /etc/default/$UPSTART_JOB
        [ "x$USE_SYSLOG" = "xyes" ] && DAEMON_ARGS="$DAEMON_ARGS --use-syslog"
        [ "x$USE_LOGFILE" != "xno" ] && DAEMON_ARGS="$DAEMON_ARGS --log-file=/var/log/ec2api/ec2api.log"

        exec start-stop-daemon --start --chdir /var/lib/ec2api \
                --chuid ec2api:ec2api --make-pidfile --pidfile /var/run/ec2api/ec2-api-metadata.pid \
                --exec /usr/bin/ec2-api-metadata -- --config-file=/etc/ec2api/ec2api.conf ${DAEMON_ARGS}
end script
```

Create the file:

```
vi /etc/init/ec2-api-s3.conf
```

Containing:

```
description "OpenStack AWS-EC2 API S3"
author "Reynaldo Martinez <tigerlinux@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

chdir /var/run

respawn
respawn limit 20 5
limit nofile 65535 65535

pre-start script
        for i in lock run log lib ; do
                mkdir -p /var/$i/ec2api
                chown ec2api /var/$i/ec2api
        done
end script

script
        [ -x "/usr/bin/ec2-api-s3" ] || exit 0
        DAEMON_ARGS=""
        [ -r /etc/default/openstack ] && . /etc/default/openstack
        [ -r /etc/default/$UPSTART_JOB ] && . /etc/default/$UPSTART_JOB
        [ "x$USE_SYSLOG" = "xyes" ] && DAEMON_ARGS="$DAEMON_ARGS --use-syslog"
        [ "x$USE_LOGFILE" != "xno" ] && DAEMON_ARGS="$DAEMON_ARGS --log-file=/var/log/ec2api/ec2api.log"

        exec start-stop-daemon --start --chdir /var/lib/ec2api \
                --chuid ec2api:ec2api --make-pidfile --pidfile /var/run/ec2api/ec2-api-s3.pid \
                --exec /usr/bin/ec2-api-s3 -- --config-file=/etc/ec2api/ec2api.conf ${DAEMON_ARGS}
end script
```

Time to start the services:

```
start ec2-api
start ec2-api-metadata
start ec2-api-s3

status ec2-api
status ec2-api-metadata
status ec2-api-s3
```

We need to modify our "openstack-control.sh" script (included in our OpenStack Automated Installer) in order to include ec2 services:

```
vi /usr/local/bin/openstack-control.sh
```

```bash
if [ -f /etc/openstack-control-script-config/nova-full-installed ]
then
        if [ -f /etc/openstack-control-script-config/nova-without-compute ]
        then
                svcnova=(
                        "
                        nova-api
                        nova-cert
                        nova-scheduler
                        nova-conductor
                        nova-console
                        nova-consoleauth
                        $consolesvc
                        ec2-api
                        ec2-api-metadata
                        ec2-api-s3
                        "
                )
        else
                svcnova=(
                        "
                        nova-api
                        nova-cert
                        nova-scheduler
                        nova-conductor
                        nova-console
                        nova-consoleauth
                        $consolesvc
                        nova-compute
                        ec2-api
                        ec2-api-metadata
                        ec2-api-s3
                        "
                )
        fi
else
```

With all EC2 support properlly installed and configured, we need to create the EC2 services and endpoints:

```
source /root/keystonerc_fulladmin

openstack service create \
--name ec2 \
--description "OpenStack EC2 Compute" \
ec2

openstack endpoint create --region RegionOne \
ec2 public http://192.168.56.101:8788/services/Cloud

openstack endpoint create --region RegionOne \
ec2 internal http://192.168.56.101:8788/services/Cloud

openstack endpoint create --region RegionOne \
ec2 admin http://192.168.56.101:8788/services/Cloud
```

Basic installation ready !


### EC2 Client configuration and testing:

Now, let's proceed to install and configure the aws python client and do some basic testing:

Using pip, we proceed to install the awscli:

```
pip install awscli
```

**NOTE:** Please use the "pip installed" version instead of the packaged version. The "pip" installed version is more up-to-date than the packaged version !.

Before we try to configure the aws client, we need to generate the credentials from openstack:

```
source /root/keystonerc_fulladmin

openstack ec2 credentials create

+------------+-----------------------------------------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                                                   |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------+
| access     | 95efb8c9655145038eb2d85e92a919f6                                                                                                        |
| links      | {u'self': u'http://192.168.56.101:35357/v3/users/8fe771f194ab4f77ba835bbf733e85b9/credentials/OS-EC2/95efb8c9655145038eb2d85e92a919f6'} |
| project_id | f0ba388be6014442968523ca43385b44                                                                                                        |
| secret     | c02595c5725e4e3da008c0515daa9ff1                                                                                                        |
| trust_id   | None                                                                                                                                    |
| user_id    | 8fe771f194ab4f77ba835bbf733e85b9                                                                                                        |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------+
```

With the "access key" and "secret", we can configure aws cli:

```
aws configure

AWS Access Key ID [None]: 95efb8c9655145038eb2d85e92a919f6
AWS Secret Access Key [None]: c02595c5725e4e3da008c0515daa9ff1
Default region name [None]: nova
Default output format [None]: table
```

Ok we are set !. Time to do some testing:

```
aws --endpoint-url http://192.168.56.101:8788/services/Cloud ec2 describe-images

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                                 DescribeImages                                                                                                  |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
||                                                                                                    Images                                                                                                     ||
|+--------------+-----------------------------+---------------+------------------------------+------------+-----------------------+-----------------------------------+---------+------------------+-------------+|
|| Architecture |        CreationDate         |    ImageId    |        ImageLocation         | ImageType  |         Name          |              OwnerId              | Public  | RootDeviceType   |    State    ||
|+--------------+-----------------------------+---------------+------------------------------+------------+-----------------------+-----------------------------------+---------+------------------+-------------+|
||              |  2016-03-08T12:54:24.000000 |  ami-fe2a24a7 |  None (Cirros 0.3.4 64 bits) |  machine   |  Cirros 0.3.4 64 bits |  f0ba388be6014442968523ca43385b44 |  True   |  instance-store  |  available  ||
||              |  2016-03-08T12:54:10.000000 |  ami-c4eff9dd |  None (Cirros 0.3.4 32 bits) |  machine   |  Cirros 0.3.4 32 bits |  f0ba388be6014442968523ca43385b44 |  True   |  instance-store  |  available  ||
|+--------------+-----------------------------+---------------+------------------------------+------------+-----------------------+-----------------------------------+---------+------------------+-------------+|

aws --endpoint-url http://192.168.56.101:8788/services/Cloud ec2 describe-volumes
-----------------
|DescribeVolumes|
+---------------+

aws --endpoint-url http://192.168.56.101:8788/services/Cloud ec2 describe-instances
-------------------
|DescribeInstances|
+-----------------+

aws --endpoint-url http://192.168.56.101:8788/services/Cloud ec2 describe-vpcs
--------------
|DescribeVpcs|
+------------+

aws --endpoint-url http://192.168.56.101:8788/services/Cloud ec2 describe-subnets
-----------------
|DescribeSubnets|
+---------------+
```

This finish what we wanted to cover in this recipe. For a more complete LAB, with real EC2-Classic and EC2-VPC tests, please see our Centos-7 based recipe in the following link:

* [RECIPE: OpenStack AWS-EC2 Compatibility and LAB - Centos 7, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/openstack-aws-ec2-compatibility/RECIPE-aws-ec2-openstack-compat-lab.md "OpenStack AWS-EC2 Compat - Centos 7")

END.-

