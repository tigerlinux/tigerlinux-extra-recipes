# AWS (EC2-API) EXTENDED SUPPORT INSTALL ON OPENSTACK (LIBERTY OVER CENTOS 7) AND EC2-CLASSIC/EC2-VPC LAB.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to include the EC2-API extended support into an existing OpenStack cloud, and do some LAB's with ec2-classic and ec2-vpc emulation on OpenStack.


## Where are we going to install it ?:

Monolithic OpenStack LAB Cloud (Just one all-in-one server, IP 192.168.1.4), with **OpenStack LIBERTY installed over Centos 7**. The platform was installed by using the openstack automated installer available at the following link:

* [TigerLinux OpenStack LIBERTY Automated Installer for Centos 7](https://github.com/tigerlinux/openstack-liberty-installer-centos7)


## How we constructed the whole thing ?:


### Fist Steps: OpenStack Environment Setup.

Our target OpenStack installation is using a all-in-one approach (development platform). We currently have the following pre-configured in the cloud platform:

* A external network (non-shared) called "public-internet-access", with it's subnet (subnet-internet-access) cidr: 192.168.1.0/24, dhcp range: 192.168.1.210-250.
* Only one tenand: admin.
* LVM's for Cinder block storage.

We begin by creating a specific tenant "ec2-testing", with it's user "ec2-testing", password "ec2-testing", roles: user and member (non-admin user).

The ID for this tenant is: 2da33b2651d7400c8005b84475ac14f0

We proceed to add floating IP's for this tenant. The FIP's belong to the external network CIDR but are outside the dhcp range:

```
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.35 public-internet-access
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.36 public-internet-access
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.37 public-internet-access
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.38 public-internet-access
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.39 public-internet-access
neutron floatingip-create --tenant-id 2da33b2651d7400c8005b84475ac14f0 --floating-ip-address 192.168.1.40 public-internet-access
```

This creates 6 FIP's (floating IP's) to our "ec2-testing" tenant.

Now, we need to create the internal "ec2-classic" network and it's router, GRE type. The requeriments for EC2-Compat is that both the network and subnet "MUST BE" named subnet-awsXXXX, for this lab, subnet-aws0001. Also, the router name must be router-aws001.

We used the Horizon Dashboard for those tasks. The net (GRE type) was named "subnet-aws0001". The subnet was created with the same name, "subnet-aws0001", CIDR:172.16.1.0/24, gateway 172.16.1.1, dhcp range 172.16.1.2-254. The router "router-aws0001" has it's gateway set to the external network, and an interface to the "subnet-aws0001" subnet, with the IP: 172.16.1.1 (the default gateway). This is all "openstack basic" so we'll not extend any explanaition here about openstack network creation.

At this point, the "ec2-testing" tenant is able to create instances on the subnet "subnet-aws0001" and assign them FIP's.

Now, we proceed to create an "keystone credentials" for the ec2-testing user:

```
vi /root/keystonerc_ec2
```

Containing:

```
export OS_USERNAME=ec2-testing
export OS_PASSWORD=ec2-testing
export OS_TENANT_NAME=ec2-testing
export OS_PROJECT_NAME=ec2-testing
export OS_AUTH_URL=http://192.168.1.4:5000/v3
export OS_VOLUME_API_VERSION=2
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_AUTH_VERSION=3
PS1='[\u@\h \W(keystone_ec2)]$ '
```

We proceed to save the file, and source the credentials:

```
source /root/keystonerc_ec2
```

Now with the shell session pointing to the ec2-testing account, we proceed to create the EC2 credentials:

Command:

```
openstack ec2 credentials create
```

Result:

```
+------------+--------------------------------------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                                                |
+------------+--------------------------------------------------------------------------------------------------------------------------------------+
| access     | b8f23017d84e4bbf8665f65e4182f8e4                                                                                                     |
| links      | {u'self': u'http://192.168.1.4:35357/v3/users/7f36ec1afbc44a3aa37c9dc803e6b1cc/credentials/OS-EC2/b8f23017d84e4bbf8665f65e4182f8e4'} |
| project_id | 2da33b2651d7400c8005b84475ac14f0                                                                                                     |
| secret     | 04afb05f0b2d499e852cafca19a35b66                                                                                                     |
| trust_id   | None                                                                                                                                 |
| user_id    | 7f36ec1afbc44a3aa37c9dc803e6b1cc                                                                                                     |
+------------+--------------------------------------------------------------------------------------------------------------------------------------+
```

We proceed to install the aws python client:

```
yum install python-pip
pip install awscli
```

With the "access" and "secret" previouslly obtained with the "openstack ec2 credentials create" command, we proceed to configure the aws client:

```
aws configure
AWS Access Key ID [None]: b8f23017d84e4bbf8665f65e4182f8e4
AWS Secret Access Key [None]: 04afb05f0b2d499e852cafca19a35b66
Default region name [None]: nova
Default output format [None]: table
```

This finish our pre-flight check !!.


### EC2 Support Installation:

First, we need to create the proper endpoints for EC2:

Source the "admin" tenant/user keystone credentials:

```
source /root/keystonerc_fulladmin
```

Create the service, and endpoints:

```
openstack service create \
--name ec2 \
--description "OpenStack EC2 Compute" \
ec2

openstack endpoint create --region Casita-Cloud-01 \
ec2 public http://192.168.1.4:8788/services/Cloud

openstack endpoint create --region Casita-Cloud-01 \
ec2 internal http://192.168.1.4:8788/services/Cloud

openstack endpoint create --region Casita-Cloud-01 \
ec2 admin http://192.168.1.4:8788/services/Cloud
```

Install the components using yum:

```
yum install openstack-ec2-api python-ec2-api-doc python2-ec2-api
```

Using "croudini", configure the EC2 Support. Note that we are using the same "nova" user (as used in nova modules) for give EC2 modules access to Keystone and the core of openstack:

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

crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_url "http://192.168.1.4:5000/v3"
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_ec2_tokens_url "http://192.168.1.4:5000/v3/ec2tokens"

crudini --set /etc/ec2api/ec2api.conf DEFAULT my_ip 192.168.1.4
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_host 192.168.1.4
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_port 8788
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_scheme http
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_path "/services/Cloud"
crudini --set /etc/ec2api/ec2api.conf DEFAULT region_list nova

crudini --set /etc/ec2api/ec2api.conf DEFAULT full_vpc_support true
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_host 192.168.1.4
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_port 3334
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_use_ssl false
crudini --set /etc/ec2api/ec2api.conf DEFAULT ec2_private_dns_show_ip true
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_listen 0.0.0.0
crudini --set /etc/ec2api/ec2api.conf DEFAULT s3_listen_port 3334

crudini --set /etc/ec2api/ec2api.conf database connection "mysql://ec2apidbuser:P@ssw0rd@192.168.1.4:3306/ec2apidb"

crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_uri "http://192.168.1.4:5000/"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken identity_uri "http://192.168.1.4:35357/"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_version v3
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_user nova
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_password "P@ssw0rd"
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken admin_tenant_name services
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_url http://192.168.1.4:35357
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_plugin password
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken project_domain_id default
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken user_domain_id default
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken project_name services
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken username nova
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken password "P@ssw0rd"

crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_ip 192.168.1.4
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_port 8775
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_protocol http
crudini --set /etc/ec2api/ec2api.conf metadata nova_metadata_insecure true
crudini --set /etc/ec2api/ec2api.conf metadata metadata_proxy_shared_secret "P@ssw0rd"

crudini --set /etc/ec2api/ec2api.conf DEFAULT tempdir "/tmp"
crudini --set /etc/ec2api/ec2api.conf DEFAULT api_paste_config "/etc/ec2api/api-paste.ini"
crudini --set /etc/ec2api/ec2api.conf DEFAULT state_path "/var/lib/ec2api"
crudini --set /etc/ec2api/ec2api.conf DEFAULT internal_service_availability_zone nova
```

**NOTE: In liberty, we found some problems using the V3 authentication, so, use V2 "for now". Please take note this can change on Mitaka:**

```
crudini --set /etc/ec2api/ec2api.conf keystone_authtoken auth_version v2.0
crudini --del /etc/ec2api/ec2api.conf keystone_authtoken project_domain_id
crudini --del /etc/ec2api/ec2api.conf keystone_authtoken user_domain_id
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_url "http://192.168.1.4:5000/v2.0"
crudini --set /etc/ec2api/ec2api.conf DEFAULT keystone_ec2_tokens_url "http://192.168.1.4:5000/v2.0/ec2tokens"
```

Create the following directories and symlinks:

```
mkdir -p /var/lib/ec2api
chown -R ec2api.ec2api /var/lib/ec2api
ln -s /usr/bin/ec2-api-manage /usr/bin/ec2api-manage
```

Create the ec2api database:

```
mysql> CREATE DATABASE ec2apidb default character set utf8;
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'%' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL ON ec2apidb.* TO 'ec2apidbuser'@'192.168.1.4' IDENTIFIED BY 'P@ssw0rd';
mysql> FLUSH PRIVILEGES;
```

Provision/Populate the EC2 database:

```
su ec2api -s /bin/sh -c "ec2-api-manage db_sync"
```

VERY IMPORTANT NOTE: On early versions of EC2 support for OpenStack, you need to enable Cinder V1 Api. In later versions this has been corrected:

Cinder V1 api reactivation:

```
crudini --set /etc/cinder/cinder.conf DEFAULT enable_v1_api true
openstack-control.sh restart cinder
```

We proceed to start and enable EC2 related services:

```
systemctl start openstack-ec2-api openstack-ec2-api-metadata openstack-ec2-api-s3
systemctl enable openstack-ec2-api openstack-ec2-api-metadata openstack-ec2-api-s3
systemctl status openstack-ec2-api openstack-ec2-api-metadata openstack-ec2-api-s3
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
                        openstack-nova-api
                        openstack-nova-cert
                        openstack-nova-scheduler
                        openstack-nova-conductor
                        openstack-nova-consoleauth
                        openstack-ec2-api
                        openstack-ec2-api-metadata
                        openstack-ec2-api-s3
                        $consolesvc
                        "
                )
        else
                svcnova=(
                        "
                        openstack-nova-api
                        openstack-nova-cert
                        openstack-nova-scheduler
                        openstack-nova-conductor
                        openstack-nova-consoleauth
                        $consolesvc
                        openstack-nova-compute
                        openstack-ec2-api
                        openstack-ec2-api-metadata
                        openstack-ec2-api-s3
                        "
                )
        fi
else
```

You can do a simple test:

```
openstack-control.sh status nova
```

At this stage, you can call specific aws commands from the aws python client:

**Describe-Images Command**

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-images

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                                      DescribeImages                                                                                                       |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
||                                                                                                         Images                                                                                                          ||
|+--------------+-----------------------------+---------------+-----------------------------------+------------+----------------------------+-----------------------------------+---------+------------------+-------------+|
|| Architecture |        CreationDate         |    ImageId    |           ImageLocation           | ImageType  |           Name             |              OwnerId              | Public  | RootDeviceType   |    State    ||
|+--------------+-----------------------------+---------------+-----------------------------------+------------+----------------------------+-----------------------------------+---------+------------------+-------------+|
||              |  2016-02-08T00:52:28.000000 |  ami-3acb2899 |  None (Ubuntu-1604lts-64-Cloud)   |  machine   |  Ubuntu-1604lts-64-Cloud   |  4ad2b7c527894e40a9316b8ca3c101df |  True   |  instance-store  |  available  ||
||              |  2016-02-08T00:51:43.000000 |  ami-aba41c0e |  None (Ubuntu-1604lts-32-Cloud)   |  machine   |  Ubuntu-1604lts-32-Cloud   |  4ad2b7c527894e40a9316b8ca3c101df |  True   |  instance-store  |  available  ||
||              |  2016-02-06T22:07:16.000000 |  ami-74c45943 |  None (Windows-7-SP1-32)          |  machine   |  Windows-7-SP1-32          |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T22:00:47.000000 |  ami-6de8d2ae |  None (Windows-Server-2012-R2-64) |  machine   |  Windows-Server-2012-R2-64 |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T22:00:25.000000 |  ami-00ed4961 |  None (Windows-Server-2008-R2-64) |  machine   |  Windows-Server-2008-R2-64 |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:58:31.000000 |  ami-d1e1dc6b |  None (FreeBSD-10.0-64-Cloud)     |  machine   |  FreeBSD-10.0-64-Cloud     |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:57:41.000000 |  ami-35a799f3 |  None (Ubuntu-1404lts-64-Cloud)   |  machine   |  Ubuntu-1404lts-64-Cloud   |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:57:10.000000 |  ami-321465d0 |  None (Ubuntu-1404lts-32-Cloud)   |  machine   |  Ubuntu-1404lts-32-Cloud   |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:56:27.000000 |  ami-aabaa7ae |  None (Debian-8-64-Cloud)         |  machine   |  Debian-8-64-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:56:00.000000 |  ami-5d12200b |  None (Debian-8-32-Cloud)         |  machine   |  Debian-8-32-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:55:23.000000 |  ami-5aa53d11 |  None (Debian-7-64-Cloud)         |  machine   |  Debian-7-64-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:54:55.000000 |  ami-a0e2b00b |  None (Debian-7-32-Cloud)         |  machine   |  Debian-7-32-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:54:01.000000 |  ami-dbf0c2b9 |  None (Centos-7-64-Cloud)         |  machine   |  Centos-7-64-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:53:15.000000 |  ami-e73db79b |  None (Centos-6-64-Cloud)         |  machine   |  Centos-6-64-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:52:44.000000 |  ami-721d48b7 |  None (Centos-6-32-Cloud)         |  machine   |  Centos-6-32-Cloud         |                                   |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:00:34.000000 |  ami-1d4dcaf0 |  None (Cirros 0.3.4 64 bits)      |  machine   |  Cirros 0.3.4 64 bits      |  4ad2b7c527894e40a9316b8ca3c101df |  True   |  instance-store  |  available  ||
||              |  2016-02-06T21:00:22.000000 |  ami-e1b8d42c |  None (Cirros 0.3.4 32 bits)      |  machine   |  Cirros 0.3.4 32 bits      |  4ad2b7c527894e40a9316b8ca3c101df |  True   |  instance-store  |  available  ||
|+--------------+-----------------------------+---------------+-----------------------------------+------------+----------------------------+-----------------------------------+---------+------------------+-------------+|
```

**Describe-Key-Pairs**

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-key-pairs

--------------------------------------------------------------------
|                         DescribeKeyPairs                         |
+------------------------------------------------------------------+
||                            KeyPairs                            ||
|+---------------------------------------------------+------------+|
||                  KeyFingerprint                   |  KeyName   ||
|+---------------------------------------------------+------------+|
||  70:b6:92:ca:d5:c2:47:37:d0:8a:4e:e8:b7:03:bd:6c  |  topcat-01 ||
|+---------------------------------------------------+------------+|
```

**Describe-Volumes**

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-volumes

-----------------
|DescribeVolumes|
+---------------+
```

**Describe-Instances**

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-instances

-------------------
|DescribeInstances|
+-----------------+
```

Before we start "instance creation" a-la AWS way and with the AWS CLI, we need to include our external network as default network in the ec2 module:

```
crudini --set /etc/ec2api/ec2api.conf DEFAULT external_network public-internet-access

systemctl restart openstack-ec2-api openstack-ec2-api-metadata openstack-ec2-api-s3
systemctl status openstack-ec2-api openstack-ec2-api-metadata openstack-ec2-api-s3
```

### EC2-Classic Instances

With our OpenStack cloud EC2 support fully installed and configured, we are ready to go: Let's create an EC2-Classic Instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 run-instances \
--image-id ami-321465d0 \
--instance-type m1.normal.2cores \
--placement AvailabilityZone=nova \
--count 1 \
--security-groups default
```

Result:

```
-------------------------------------------------------
|                    RunInstances                     |
+----------------+------------------------------------+
|  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  |
|  ReservationId |  r-i9z44sn3                        |
+----------------+------------------------------------+
||                     Instances                     ||
|+----------------------+----------------------------+|
||  AmiLaunchIndex      |  0                         ||
||  ImageId             |  ami-321465d0             ||
||  InstanceId          |  i-296c306d                ||
||  InstanceType        |  m1.normal.2cores          ||
||  KeyName             |                            ||
||  LaunchTime          |  2016-03-08T00:22:48Z      ||
||  PrivateDnsName      |                            ||
||  PrivateIpAddress    |                            ||
||  PublicDnsName       |                            ||
|+----------------------+----------------------------+|
|||                    Placement                    |||
||+----------------------------------+--------------+||
|||  AvailabilityZone                |  nova        |||
||+----------------------------------+--------------+||
|||                      State                      |||
||+-------------------+-----------------------------+||
|||  Code             |  0                          |||
|||  Name             |  pending                    |||
||+-------------------+-----------------------------+||
```

Using "describe-instances" we can se our instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-instances

---------------------------------------------------------
|                   DescribeInstances                   |
+-------------------------------------------------------+
||                    Reservations                     ||
|+----------------+------------------------------------+|
||  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  ||
||  ReservationId |  r-i9z44sn3                        ||
|+----------------+------------------------------------+|
|||                      Groups                       |||
||+-----------------------+---------------------------+||
|||  GroupId              |  sg-d900da4d              |||
|||  GroupName            |  default                  |||
||+-----------------------+---------------------------+||
|||                     Instances                     |||
||+----------------------+----------------------------+||
|||  AmiLaunchIndex      |  0                         |||
|||  ImageId             |  ami-321465d0              |||
|||  InstanceId          |  i-296c306d                |||
|||  InstanceType        |  m1.normal.2cores          |||
|||  KeyName             |                            |||
|||  LaunchTime          |  2016-03-08T00:22:48Z      |||
|||  PrivateDnsName      |  172.16.1.5                |||
|||  PrivateIpAddress    |  172.16.1.5                |||
|||  PublicDnsName       |                            |||
||+----------------------+----------------------------+||
||||                    Placement                    ||||
|||+----------------------------------+--------------+|||
||||  AvailabilityZone                |  nova        ||||
|||+----------------------------------+--------------+|||
||||                 SecurityGroups                  ||||
|||+----------------------+--------------------------+|||
||||  GroupId             |  sg-d900da4d             ||||
||||  GroupName           |  default                 ||||
|||+----------------------+--------------------------+|||
||||                      State                      ||||
|||+-------------------+-----------------------------+|||
||||  Code             |  16                         ||||
||||  Name             |  running                    ||||
|||+-------------------+-----------------------------+|||
```

From the openstack dashboard we can assign a FIP to the instance, then see the change in aws command:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-instances

---------------------------------------------------------
|                   DescribeInstances                   |
+-------------------------------------------------------+
||                    Reservations                     ||
|+----------------+------------------------------------+|
||  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  ||
||  ReservationId |  r-i9z44sn3                        ||
|+----------------+------------------------------------+|
|||                      Groups                       |||
||+-----------------------+---------------------------+||
|||  GroupId              |  sg-d900da4d              |||
|||  GroupName            |  default                  |||
||+-----------------------+---------------------------+||
|||                     Instances                     |||
||+----------------------+----------------------------+||
|||  AmiLaunchIndex      |  0                         |||
|||  ImageId             |  ami-321465d0              |||
|||  InstanceId          |  i-296c306d                |||
|||  InstanceType        |  m1.normal.2cores          |||
|||  KeyName             |                            |||
|||  LaunchTime          |  2016-03-08T00:22:48Z      |||
|||  PrivateDnsName      |  172.16.1.5                |||
|||  PrivateIpAddress    |  172.16.1.5                |||
|||  PublicDnsName       |  192.168.1.36              |||
|||  PublicIpAddress     |  192.168.1.36              |||
||+----------------------+----------------------------+||
||||                    Placement                    ||||
|||+----------------------------------+--------------+|||
||||  AvailabilityZone                |  nova        ||||
|||+----------------------------------+--------------+|||
||||                 SecurityGroups                  ||||
|||+----------------------+--------------------------+|||
||||  GroupId             |  sg-d900da4d             ||||
||||  GroupName           |  default                 ||||
|||+----------------------+--------------------------+|||
||||                      State                      ||||
|||+-------------------+-----------------------------+|||
||||  Code             |  16                         ||||
||||  Name             |  running                    ||||
|||+-------------------+-----------------------------+|||
```

We proceed to kill the instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 terminate-instances --instance-ids i-296c306d

-------------------------
|  TerminateInstances   |
+-----------------------+
||TerminatingInstances ||
|+---------------------+|
||     InstanceId      ||
|+---------------------+|
||  i-296c306d         ||
|+---------------------+|
|||   CurrentState    |||
||+-------+-----------+||
||| Code  |   Name    |||
||+-------+-----------+||
|||  16   |  running  |||
||+-------+-----------+||
|||   PreviousState   |||
||+-------+-----------+||
||| Code  |   Name    |||
||+-------+-----------+||
|||  16   |  running  |||
||+-------+-----------+||
```

Let's create another instance, this time with a security group associated to it:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 run-instances \
--image-id ami-b5f702c7 \
--instance-type m1.normal.2cores \
--placement AvailabilityZone=nova \
--count 1 \
--security-groups default \
--key-name topcat-01
```

Result:

```
-------------------------------------------------------
|                    RunInstances                     |
+----------------+------------------------------------+
|  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  |
|  ReservationId |  r-vyfa28d2                        |
+----------------+------------------------------------+
||                      Groups                       ||
|+-----------------------+---------------------------+|
||  GroupId              |  sg-d900da4d              ||
||  GroupName            |  default                  ||
|+-----------------------+---------------------------+|
||                     Instances                     ||
|+----------------------+----------------------------+|
||  AmiLaunchIndex      |  0                         ||
||  ImageId             |  ami-321465d0              ||
||  InstanceId          |  i-eea072ab                ||
||  InstanceType        |  m1.normal.2cores          ||
||  KeyName             |  topcat-01                 ||
||  LaunchTime          |  2016-03-08T00:34:25Z      ||
||  PrivateDnsName      |                            ||
||  PrivateIpAddress    |                            ||
||  PublicDnsName       |                            ||
|+----------------------+----------------------------+|
|||                    Placement                    |||
||+----------------------------------+--------------+||
|||  AvailabilityZone                |  nova        |||
||+----------------------------------+--------------+||
|||                 SecurityGroups                  |||
||+----------------------+--------------------------+||
|||  GroupId             |  sg-d900da4d             |||
|||  GroupName           |  default                 |||
||+----------------------+--------------------------+||
|||                      State                      |||
||+-------------------+-----------------------------+||
|||  Code             |  0                          |||
|||  Name             |  pending                    |||
||+-------------------+-----------------------------+||
```

And, using AWS this time, we proceed to associate the FIP:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 associate-address \
--public-ip 192.168.1.37 \
--instance-id i-eea072ab
```

We can see the instance now with the FIP:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-instances

---------------------------------------------------------
|                   DescribeInstances                   |
+-------------------------------------------------------+
||                    Reservations                     ||
|+----------------+------------------------------------+|
||  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  ||
||  ReservationId |  r-vyfa28d2                        ||
|+----------------+------------------------------------+|
|||                      Groups                       |||
||+-----------------------+---------------------------+||
|||  GroupId              |  sg-d900da4d              |||
|||  GroupName            |  default                  |||
||+-----------------------+---------------------------+||
|||                     Instances                     |||
||+----------------------+----------------------------+||
|||  AmiLaunchIndex      |  0                         |||
|||  ImageId             |  ami-321465d0             |||
|||  InstanceId          |  i-eea072ab                |||
|||  InstanceType        |  m1.normal.2cores          |||
|||  KeyName             |  topcat-01                 |||
|||  LaunchTime          |  2016-03-08T00:34:25Z      |||
|||  PrivateDnsName      |  172.16.1.6                |||
|||  PrivateIpAddress    |  172.16.1.6                |||
|||  PublicDnsName       |  192.168.1.37              |||
|||  PublicIpAddress     |  192.168.1.37              |||
||+----------------------+----------------------------+||
||||                    Placement                    ||||
|||+----------------------------------+--------------+|||
||||  AvailabilityZone                |  nova        ||||
|||+----------------------------------+--------------+|||
||||                 SecurityGroups                  ||||
|||+----------------------+--------------------------+|||
||||  GroupId             |  sg-d900da4d             ||||
||||  GroupName           |  default                 ||||
|||+----------------------+--------------------------+|||
||||                      State                      ||||
|||+-------------------+-----------------------------+|||
||||  Code             |  16                         ||||
||||  Name             |  running                    ||||
|||+-------------------+-----------------------------+|||
```

And again, let's kill the instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 terminate-instances --instance-ids i-eea072ab
```


### EC2-VPC Instances.

First thing to do before creating VPC Instances, is to create the VPC:

First, we need to create our DHCP Config options (note: Our DNS's for this lab are 192.168.1.6 and .7):

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-dhcp-options \
--dhcp-configuration "Key=domain-name-servers,Values=192.168.1.6,192.168.1.7"

--------------------------------------
|          CreateDhcpOptions         |
+------------------------------------+
||            DhcpOptions           ||
|+----------------+-----------------+|
||  DhcpOptionsId |  dopt-eaf1128b  ||
|+----------------+-----------------+|
|||       DhcpConfigurations       |||
||+--------------------------------+||
|||               Key              |||
||+--------------------------------+||
|||  domain-name-servers           |||
||+--------------------------------+||
||||            Values            ||||
|||+------------------------------+|||
||||             Value            ||||
|||+------------------------------+|||
||||  192.168.1.6                 ||||
||||  192.168.1.7                 ||||
|||+------------------------------+|||
```

Now, we proceed to create the VPC:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-vpc --cidr-block 172.16.1.0/24

--------------------------------------------------------------------------------
|                                   CreateVpc                                  |
+------------------------------------------------------------------------------+
||                                     Vpc                                    ||
|+---------------+----------------+------------+-------------+----------------+|
||   CidrBlock   | DhcpOptionsId  | IsDefault  |    State    |     VpcId      ||
|+---------------+----------------+------------+-------------+----------------+|
||  172.16.1.0/24|  default       |  False     |  available  |  vpc-10b51779  ||
|+---------------+----------------+------------+-------------+----------------+|
```

Proceed to associate the DHCP options with the vpc:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 associate-dhcp-options \
--vpc-id vpc-10b51779 \
--dhcp-options-id dopt-eaf1128b
```

Check the VPC Now:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-vpcs

--------------------------------------------------------------------------------
|                                 DescribeVpcs                                 |
+------------------------------------------------------------------------------+
||                                    Vpcs                                    ||
|+---------------+----------------+------------+-------------+----------------+|
||   CidrBlock   | DhcpOptionsId  | IsDefault  |    State    |     VpcId      ||
|+---------------+----------------+------------+-------------+----------------+|
||  172.16.1.0/24|  dopt-eaf1128b |  False     |  available  |  vpc-10b51779  ||
|+---------------+----------------+------------+-------------+----------------+|
```

And for the VPC, let's create a subnetwork:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-subnet \
--vpc-id vpc-10b51779 \
--cidr-block 172.16.1.0/24

---------------------------------------------------------------------------------------------------------------------------------------
|                                                            CreateSubnet                                                             |
+-------------------------------------------------------------------------------------------------------------------------------------+
||                                                              Subnet                                                               ||
|+-------------------------+----------------+---------------+----------------------+------------+-------------------+----------------+|
|| AvailableIpAddressCount |   CidrBlock    | DefaultForAz  | MapPublicIpOnLaunch  |   State    |     SubnetId      |     VpcId      ||
|+-------------------------+----------------+---------------+----------------------+------------+-------------------+----------------+|
||  252                    |  172.16.1.0/24 |  False        |  False               |  available |  subnet-93de6820  |  vpc-10b51779  ||
|+-------------------------+----------------+---------------+----------------------+------------+-------------------+----------------+|
```

The VPC need's a router too, attached with a internet gateway.

Let's create the internet gateway first:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-internet-gateway

-----------------------------------------
|         CreateInternetGateway         |
+---------------------------------------+
||           InternetGateway           ||
|+--------------------+----------------+|
||  InternetGatewayId |  igw-f74e631c  ||
|+--------------------+----------------+|
```

Attach it to the VPC:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 attach-internet-gateway \
--internet-gateway-id igw-f74e631c \
--vpc-id vpc-10b51779
```

In neutron, we can see the ports being created by the EC2-OpenStack layer:

```
source /root/keystonerc_fulladmin
neutron router-port-list vpc-10b51779
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------------------+
| id                                   | name | mac_address       | fixed_ips                                                                            |
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------------------+
| 96387f33-973b-4cb7-a23d-4a47f080bacf |      | fa:16:3e:c8:d0:ff | {"subnet_id": "530ed4a7-92cc-4203-80f4-5a53e679bd63", "ip_address": "172.16.1.5"}    |
| d0b1744f-a08c-44d2-90d8-dc9dd7c0b850 |      | fa:16:3e:4f:fb:bf | {"subnet_id": "ea4b3598-c91a-4392-bc1a-dc93bc141eaf", "ip_address": "192.168.1.228"} |
| f0f1d895-e04a-4678-9833-9d0f8b9e3611 |      | fa:16:3e:7b:9d:a0 | {"subnet_id": "530ed4a7-92cc-4203-80f4-5a53e679bd63", "ip_address": "172.16.1.1"}    |
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------------------+
```

We must create a route-table for the VPC:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-route-table --vpc-id vpc-10b51779

-------------------------------------------------------------------------
|                           CreateRouteTable                            |
+-----------------------------------------------------------------------+
||                             RouteTable                              ||
|+---------------------------------+-----------------------------------+|
||          RouteTableId           |               VpcId               ||
|+---------------------------------+-----------------------------------+|
||  rtb-16647ad2                   |  vpc-10b51779                     ||
|+---------------------------------+-----------------------------------+|
|||                              Routes                               |||
||+-----------------------+------------+--------------------+---------+||
||| DestinationCidrBlock  | GatewayId  |      Origin        |  State  |||
||+-----------------------+------------+--------------------+---------+||
|||  172.16.1.0/24        |  local     |  CreateRouteTable  |  active |||
||+-----------------------+------------+--------------------+---------+||
```

The default route (0.0.0.0/0):

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 create-route \
--route-table-id rtb-16647ad2 \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id igw-f74e631c

--------------------
|    CreateRoute   |
+---------+--------+
|  Return |  True  |
+---------+--------+
```

Finally, we associate the route table with the subnet:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 associate-route-table \
--route-table-id rtb-16647ad2 \
--subnet-id subnet-93de6820

----------------------------------------
|          AssociateRouteTable         |
+----------------+---------------------+
|  AssociationId |  rtbassoc-93de6820  |
+----------------+---------------------+
```

**NOTE**: We need to include manually (with Neutron) the dns servers:

```
source /root/keystonerc_fulladmin
neutron subnet-update --dns-nameserver 192.168.1.6 --dns-nameserver 192.168.1.7 subnet-93de6820
```

Please note that the VPC will have it's own security group. You can see this on Horizon. In this point you should add rules for icmp and ssh access to this security group.

With the VPC ready, routes and network done too, we proceed to create a VPC-Based EC2 instance, and add to it an EIP (Elastic IP):

First the instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 run-instances \
--image-id ami-321465d0 \
--instance-type m1.normal.2cores \
--placement AvailabilityZone=nova \
--count 1 \
--subnet-id subnet-93de6820 \
--key-name topcat-01

----------------------------------------------------------------
|                         RunInstances                         |
+-------------------+------------------------------------------+
|  OwnerId          |  2da33b2651d7400c8005b84475ac14f0        |
|  ReservationId    |  r-bxqifglc                              |
+-------------------+------------------------------------------+
||                          Instances                         ||
|+--------------------------+---------------------------------+|
||  AmiLaunchIndex          |  0                              ||
||  ImageId                 |  ami-321465d0                   ||
||  InstanceId              |  i-5fcafaa7                     ||
||  InstanceType            |  m1.normal.2cores               ||
||  KeyName                 |  topcat-01                      ||
||  LaunchTime              |  2016-03-08T02:14:37Z           ||
||  PrivateDnsName          |  172.16.1.7                     ||
||  PrivateIpAddress        |  172.16.1.7                     ||
||  PublicDnsName           |                                 ||
||  SourceDestCheck         |  True                           ||
||  SubnetId                |  subnet-93de6820                ||
||  VpcId                   |  vpc-10b51779                   ||
|+--------------------------+---------------------------------+|
|||                     NetworkInterfaces                    |||
||+---------------------+------------------------------------+||
|||  Description        |                                    |||
|||  MacAddress         |  fa:16:3e:48:b7:9d                 |||
|||  NetworkInterfaceId |  eni-791396aa                      |||
|||  OwnerId            |  2da33b2651d7400c8005b84475ac14f0  |||
|||  PrivateIpAddress   |  172.16.1.7                        |||
|||  SourceDestCheck    |  True                              |||
|||  Status             |  in-use                            |||
|||  SubnetId           |  subnet-93de6820                   |||
|||  VpcId              |  vpc-10b51779                      |||
||+---------------------+------------------------------------+||
||||                       Attachment                       ||||
|||+-----------------------+--------------------------------+|||
||||  AttachTime           |  2016-03-08T02:14:38.006290Z   ||||
||||  AttachmentId         |  eni-attach-791396aa           ||||
||||  DeleteOnTermination  |  True                          ||||
||||  DeviceIndex          |  0                             ||||
||||  Status               |  attached                      ||||
|||+-----------------------+--------------------------------+|||
||||                         Groups                         ||||
|||+-------------------------+------------------------------+|||
||||  GroupId                |  sg-0e51462b                 ||||
||||  GroupName              |  default                     ||||
|||+-------------------------+------------------------------+|||
||||                   PrivateIpAddresses                   ||||
|||+--------------------------------+-----------------------+|||
||||  Primary                       |  True                 ||||
||||  PrivateIpAddress              |  172.16.1.7           ||||
|||+--------------------------------+-----------------------+|||
|||                         Placement                        |||
||+-----------------------------------------+----------------+||
|||  AvailabilityZone                       |  nova          |||
||+-----------------------------------------+----------------+||
|||                      SecurityGroups                      |||
||+--------------------------+-------------------------------+||
|||  GroupId                 |  sg-0e51462b                  |||
|||  GroupName               |  default                      |||
||+--------------------------+-------------------------------+||
|||                           State                          |||
||+-----------------------+----------------------------------+||
|||  Code                 |  0                               |||
|||  Name                 |  pending                         |||
||+-----------------------+----------------------------------+||
```


Then, we allocate the "EIP" (Elastic IP):

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 allocate-address --domain vpc

--------------------------------------------------
|                 AllocateAddress                |
+--------------------+---------+-----------------+
|    AllocationId    | Domain  |    PublicIp     |
+--------------------+---------+-----------------+
|  eipalloc-d4cd413e |  vpc    |  192.168.1.231  |
+--------------------+---------+-----------------+
```

**Note something here:** The elastic IP is taken from the DHCP pool defined on the external network.


Then we assign the EIP to the instance:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 associate-address \
--allocation-id eipalloc-d4cd413e \
--instance-id i-5fcafaa7 \
--network-interface-id eni-791396aa

----------------------------------------
|           AssociateAddress           |
+----------------+---------------------+
|  AssociationId |  eipassoc-d4cd413e  |
+----------------+---------------------+
```

Our VPC-Instance is ready, and with an EIP assigned to it (for this example: 192.168.1.231)

Now let's create another instance, this time an EC2-Classic one:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 run-instances \
--image-id ami-321465d0 \
--instance-type m1.normal.2cores \
--placement AvailabilityZone=nova \
--count 1 \
--security-groups default \
--key-name topcat-01

-------------------------------------------------------
|                    RunInstances                     |
+----------------+------------------------------------+
|  OwnerId       |  2da33b2651d7400c8005b84475ac14f0  |
|  ReservationId |  r-gx0qkiji                        |
+----------------+------------------------------------+
||                     Instances                     ||
|+----------------------+----------------------------+|
||  AmiLaunchIndex      |  0                         ||
||  ImageId             |  ami-321465d0              ||
||  InstanceId          |  i-985fa356                ||
||  InstanceType        |  m1.normal.2cores          ||
||  KeyName             |  topcat-01                 ||
||  LaunchTime          |  2016-03-08T02:46:01Z      ||
||  PrivateDnsName      |                            ||
||  PrivateIpAddress    |                            ||
||  PublicDnsName       |                            ||
|+----------------------+----------------------------+|
|||                    Placement                    |||
||+----------------------------------+--------------+||
|||  AvailabilityZone                |  nova        |||
||+----------------------------------+--------------+||
|||                      State                      |||
||+-------------------+-----------------------------+||
|||  Code             |  0                          |||
|||  Name             |  pending                    |||
||+-------------------+-----------------------------+||
```

And give it a FIP:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 associate-address \
--public-ip 192.168.1.37 \
--instance-id i-985fa356
```

We have both instances running on OpenStack: One EC2-Classic, the other one, VPC.

Then, we proceed to delete both instances:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 terminate-instances --instance-id i-5fcafaa7
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 terminate-instances --instance-id i-985fa356

aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-instances
-------------------
|DescribeInstances|
+-----------------+
```

And set free the previouslly reserved EIP 192.168.1.231:

```
aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-addresses
------------------------------------------------------
|                  DescribeAddresses                 |
+----------------------------------------------------+
||                     Addresses                    ||
|+--------------------+-----------+-----------------+|
||    AllocationId    |  Domain   |    PublicIp     ||
|+--------------------+-----------+-----------------+|
||  eipalloc-d4cd413e |  vpc      |  192.168.1.231  ||
||                    |  standard |  192.168.1.36   ||
||                    |  standard |  192.168.1.37   ||
||                    |  standard |  192.168.1.39   ||
||                    |  standard |  192.168.1.40   ||
||                    |  standard |  192.168.1.38   ||
||                    |  standard |  192.168.1.35   ||
|+--------------------+-----------+-----------------+|

aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 release-address --allocation-id eipalloc-d4cd413e

aws --endpoint-url http://192.168.1.4:8788/services/Cloud ec2 describe-addresses
--------------------------------
|       DescribeAddresses      |
+------------------------------+
||          Addresses         ||
|+-----------+----------------+|
||  Domain   |   PublicIp     ||
|+-----------+----------------+|
||  standard |  192.168.1.36  ||
||  standard |  192.168.1.37  ||
||  standard |  192.168.1.39  ||
||  standard |  192.168.1.40  ||
||  standard |  192.168.1.38  ||
||  standard |  192.168.1.35  ||
|+-----------+----------------+|
```

### Extra Notes:

* The compatibility is still partial. You can see current limitations on the [project site at github.](https://github.com/openstack/ec2-api "EC2 for OpenStack Project Site")
* This is more suited for LAB purposes (example: if you are training yourself on OpenStack and want to try without the aws free tier limitations).
* For Cloudformation tasks, you need to directly interact with HEAT Cloudformation. HEAT (the OpenStack cloudformation/orchestrating component) support many AWS items. For a list of current compatibility between OpenStack HEAT and AWS Cloudformation, see [Heat Template Guide.](http://docs.openstack.org/developer/heat/template_guide/index.html)

END.-
