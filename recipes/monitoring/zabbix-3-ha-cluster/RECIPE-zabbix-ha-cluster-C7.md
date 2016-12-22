# A ZABBIX 3 H.A. CLUSTER IN CENTOS 7

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

Create a highly available Zabbix 3 cluster with highly available, horizontally scalable database backend.


## Where are we going to install it ?:

* For the database, we'll use this site recipe for MariaDB 10.1 cluster on centos 7, balanced with OpenStack LBaaS (all access trough a single VIP). The cluster is using 3 nodes (magic number). Recipe: **https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/databases/mariadb-cluster-centos7/RECIPE-Cluster-MariaDB-10.1-C7.md**
* For the Zabbix Cluster, we'll use two Centos 7 Servers, with EPEL repository installed, SELINUX disabled, FirewallD disabled (we are using the Cloud security groups).

Our pre-created database cluster VIP is: 172.16.10.221, port 3306 (OpenStack LBaaS Load Balancer, with source-ip based session persistence, and least_connections balancing metod).

Our two Zabbix 3 Servers:

* Node 1: 172.16.10.57 (vm-172-16-10-57.mydomain.dom)
* Node 2: 172.16.10.58 (vm-172-16-10-58.mydomain.dom)

Our Zabbix 3 Cluster VIP (with address-pairs defined on openstack): 172.16.10.222


## How we constructed the whole thing ?:


### Basic server setup:

Please execute the following steps in both servers:

Install EPEL (if you did'nt already):

```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm
```

Ensure SELINUX and FIREWALLD are disabled:

```
setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld
```

Perform a full update:

```
yum clean all
yum -y update
```

Then, reboot your server:

```
reboot
```

Configure a bi-directional ssh trust between both servers. As this is very basic, we'll not explain it here. Just remember to create your keys with `"ssh-keygen -t rsa"` and deploy them with `"ssh-copy-id"`. You'll end with an `/root/.ssh/authorized_keys` containing the public key.

Also create the following file:

```
vi /root/.ssh/config
```

With the contents:

```
Host *
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
```

Change it's permission:

```
chmod 600 /root/.ssh/config
```

And delete if found the following file:

```
rm -f /root/.ssh/known_hosts
```

Include in your `/etc/hosts` file the names (short and full dns names) with IP's of your Zabbix Hosts:

```
#
#
#
172.16.10.57 vm-172-16-10-57 vm-172-16-10-57.mydomain.dom
172.16.10.58 vm-172-16-10-58 vm-172-16-10-58.mydomain.dom
#
#
#
```


### Dependencies and php setup:

Now, we need to include on both Zabbix Nodes the proper dependencies/packages:

```
yum install zlib-devel mysql-devel glibc-devel curl-devel gcc automake mysql \
libidn-devel openssl-devel net-snmp-devel rpm-devel OpenIPMI-devel net-snmp \
net-snmp-utils php-mysql php-gd php-bcmath php-mbstring php-xml nmap php
```

Proceed to modify the `/etc/php.ini` file on both nodes in order to change some important settings required by zabbix:

```
vi /etc/php.ini
```

```
max_execution_time = 300
max_input_time = 300
memory_limit = 256M
post_max_size = 32M
date.timezone = America/Caracas
mbstring.func_overload = 2
```

Save the file.

**NOTE: Adjust the timezone for your real scenario. Mine is America/Caracas. Don't use it unless you are really in America/Caracas.**


### Database client support:

Again, those steps must be completed on both Zabbix nodes.

Install the MariaDB 10.1 repository and update the mysql libraries to MariaDB:

Create the following file (repo file):

```
vi /etc/yum.repos.d/MariaDB101.repo
```

With the following contents:

```
# MariaDB 10.1 CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

Perform an Update:

```
yum -y update
```

Just in case, ensure the following packages are installed:

```
yum install MariaDB-devel MariaDB-shared MariaDB-client MariaDB-common
```

And finish with a "ldconfig":

```
ldconfig -v
```


### Zabbix Database Creation:

In any of the MariaDB Cluster nodes, proceed to create the database and it's user:

```
MariaDB [(none)]> create database zabbixdb default character set utf8;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON zabbixdb.* TO 'zabbixuser'@'%' IDENTIFIED BY 'P@ssw0rd' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> exit;
```

This will create our database "zabbixdb", with it's user "zabbixuser" and password "P@ssw0rd". Please use a more cryptic password on real-life production environments.


### Zabbix software installation

In both Zabbix nodes, install the zabbix 3 repo:

```
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
```

Then proceed to install zabbix components:

```
yum install zabbix-server-mysql zabbix-web-mysql
yum install zabbix-agent
```

We detected a rare condition where the postgresql packages got installed to, interfering with the mysql/mariadb access. Just in case, run the following command in order to get rid of those packages:

```
yum erase zabbix-server-pgsql zabbix-web-pgsql
```

In our primary node (vm-172-16-10-57), proceed to populate the Zabbix database:

```
mkdir /workdir
cp /usr/share/doc/zabbix-server-mysql-3.0.1/create.sql.gz /workdir
cd /workdir
gunzip create.sql.gz
mysql -u zabbixuser -h 172.16.10.221 -pP@ssw0rd zabbixdb < /workdir/create.sql
```
>

**NOTE: At the moment we installed this solution, zabbix was in version 3.0.1. Adjust the directory above with the updated version you are installing**

In both zabbix nodes, create the following sudo file:

```
vi /etc/sudoers.d/zabbix
```

Containing:

```
Defaults:zabbix !requiretty
Defaults:zabbixsrv !requiretty
zabbix ALL=(ALL) NOPASSWD:ALL
zabbixsrv ALL=(ALL) NOPASSWD:ALL
```

Save the file and set permissions:

```
chmod 0440 /etc/sudoers.d/zabbix
```

In both zabbix nodes, disable the services:

```
systemctl stop zabbix-server.service
systemctl stop httpd.service
systemctl disable zabbix-server.service
systemctl disable httpd.service
```

And also, in both server nodes, configure the zabbix services to use the database by editing the file `/etc/zabbix/zabbix_server.conf`:

Edit the file:

```bash
vi /etc/zabbix/zabbix_server.conf
```

And change/edit/add-where-needed the following parameters inside the file on both zabbix servers:

```bash
DBHost=172.16.10.221
DBName=zabbixdb
DBUser=zabbixuser
DBPassword=P@ssw0rd
DBPort=3306
```

Save the file.

**NOTE: Remember to include your "real" database access information here. For this recipe, we have an external DB cluster with the aforementioned data. Also remember that, this recipe is using a cluster with DB-VIP: 172.16.10.221.**


### Optional: OpenStack Only: VIP Creation (allowed address pairs):

If you are not using OpenStack, omit this section. Otherwise we need to ensure to allow the VIP to be present in the VM's ports. This is acomplished using "allowed address pairs" Neutron feature. If you fail to do this in OpenStack, your VIP will be unable to be contacted.

For this LAB, our VIP is 172.16.10.222, our network name in neutron is "net-vlan-10" and our security group name is zabbix3-access.

With this information, we proceed to create the VIP port:

```
neutron port-create --fixed-ip ip_address=172.16.10.222 --security-group zabbix3-access net-vlan-10
```

We then proceed to obtain the port ID's containing the IP's 172.16.10.57 and 58 (our Zabbix 3 nodes):

```
neutron port-list|grep 172.16.10.57|awk '{print $2}'
d3b0e8e7-aed6-44e7-93c2-cf3bc41bc992
neutron port-list|grep 172.16.10.58|awk '{print $2}'
172ffe1d-e409-4599-9333-6b719db788a9
```

And with this information, we update both ports with allowed address pairs poiting to the VIP:

```
neutron port-update d3b0e8e7-aed6-44e7-93c2-cf3bc41bc992 --allowed_address_pairs list=true type=dict ip_address=172.16.10.222
neutron port-update 172ffe1d-e409-4599-9333-6b719db788a9 --allowed_address_pairs list=true type=dict ip_address=172.16.10.222
```

**NOTE: Most cloud's apply very strong anti-spoofing measures that won't allow a "Floating VIP" to exist unless you take the proper steps. Please document yourself very well if you plan to use this zabbix3-h.a. recipe in a cloud like AWS.**


### Zabbix 3 Cluster Creation

First, on both zabbix nodes, proceed to install all cluster-related software:

```
yum install pacemaker pcs corosync resource-agents pacemaker-cli
```

Also, in both nodes, set the **"hacluster"** account password:

```
echo "hacluster:P@ssW0rdCl7sT3r"|chpasswd
```

Start the cluster service in both nodes:

```
systemctl start pcsd
systemctl status pcsd
```

And also in both nodes, authorize the servers into the cluster:

```
pcs cluster auth vm-172-16-10-57 vm-172-16-10-58
```

(this last command will ask for the "hacluster" account and it's password).

On the primary node (172.16.10.57) proceed to create and start the cluster:

```
pcs cluster setup --name cluster_zabbix vm-172-16-10-57 vm-172-16-10-58
pcs cluster start --all
```

Then check the cluster status:

```
pcs status cluster
corosync-cmapctl | grep members
pcs status corosync
```

Proceed to verify the config state and disable stonith:

```
crm_verify -L -V
pcs property set stonith-enabled=false
```

And disable our quorum policy, as we have only two nodes:

```
pcs property set no-quorum-policy=ignore
pcs property
```

We proceed to create our VIP resource  (IP 172.16.10.222):

```
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=172.16.10.222 cidr_netmask=32 nic=eth0:0 op monitor interval=30s
```

**VERY IMPORTANT NOTE: As our ethernet interfaces are named "eth0", we choose our eth alias as "eth0:0". Adjust this alias based on your ethernet names.**

As soon as this command is completed, we can see this IP ready in the primary node with "ip a" or "ifconfig".

Proceed to verify the state of our resources:

```bash
pcs status resources

[root@vm-172-16-10-57 ~]# pcs status resources
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vm-172-16-10-57
```

En this point, we need to enable all our cluster related services IN BOTH ZABBIX SERVERS:

```bash
systemctl enable pcsd
systemctl enable corosync
systemctl enable pacemaker
```

**BUGFIX: Due an existing bug with the corosync service, we need to include a 10 seconds delay in the systemd script, and we need to perform this VERY VITAL STEP IN BOTH SERVERS:**

```bash
vi /usr/lib/systemd/system/corosync.service
```

After "[service]" section, we add the following line:

```bash
ExecStartPre=/usr/bin/sleep 10
```

So the file new content will be:

```bash
[Unit]
Description=Corosync Cluster Engine
ConditionKernelCommandLine=!nocluster
Requires=network-online.target
After=network-online.target

[Service]
ExecStartPre=/usr/bin/sleep 10
ExecStart=/usr/share/corosync/corosync start
ExecStop=/usr/share/corosync/corosync stop
Type=forking

# The following config is for corosync with enabled watchdog service.
#
#  When corosync watchdog service is being enabled and using with
#  pacemaker.service, and if you want to exert the watchdog when a
#  corosync process is terminated abnormally,
#  uncomment the line of the following Restart= and RestartSec=.
#Restart=on-failure
#  Specify a period longer than soft_margin as RestartSec.
#RestartSec=70
#  rewrite according to environment.
#ExecStartPre=/sbin/modprobe softdog soft_margin=60

[Install]
WantedBy=multi-user.target
```

Then we proceed to save the file and reload systemctl daemon, again, in both servers:

```bash
systemctl daemon-reload
```

Proceed to create the following script on the primary node (172.16.10.57):

```bash
vi /etc/init.d/zabbixsvc
```

Containing:

```bash
#!/bin/bash
#

case $1 in
start)
    echo "Starting Zabbix HA Services"
    echo "0" > /var/log/zabbix-ha-started.log
    rm -f /var/log/zabbix-ha-stopped.log
    exit 0
    ;;
stop)
    echo "Stopping Zabbix HA Services"
    rm -f /var/log/zabbix-ha-started.log
    echo "0" > /var/log/zabbix-ha-stopped.log
    exit 0
    ;;
status|monitor)
    echo "Zabbix HA Services Status"
    if [ -f /var/log/zabbix-ha-started.log ]
    then
        exit 0
    else
        exit 3
    fi
    ;;
restart)
    echo "Zabbix HA Services Restart"
    exit 0
    ;;
esac
```

Save the script, make it exec and scp it to the secondary node:

```
chmod 755 /etc/init.d/zabbixsvc

scp /etc/init.d/zabbixsvc vm-172-16-10-58:/etc/init.d/
```

Now, in the primary node (172.16.10.57), proceed to create the LSB Zabbix Service resource:

```bash
pcs resource create svczabbixsvc lsb:zabbixsvc op monitor interval=30s
```

In order to allow the script to be somewhat independent from the cluster service, we proceed to remove the monitor:

```bash
pcs resource op remove svczabbixsvc monitor
```

This step will allow you to actually stop the zabbix service, without causing a "failover" to the stand-by node.

We apply the proper constrains in order to link the VIP with the resource and set the preferent node to vm-172-16-10-57:

```bash
pcs constraint colocation add svczabbixsvc virtual_ip INFINITY
pcs constraint order virtual_ip then svczabbixsvc
pcs constraint location svczabbixsvc prefers vm-172-16-10-57=50
```

In both zabbix nodes, proceed to create the main control script:

```bash
vi /usr/local/bin/zabbix-ha-control.sh
```

Containing:

```bash
#!/bin/bash
#
# Zabbix HA Control Services

case $1 in
start)
        echo "Starting Zabbix Services"
        systemctl start zabbix-server.service
        systemctl start httpd.service
        ;;
stop)
        echo "Stopping Zabbix Services"
        systemctl stop zabbix-server.service
        systemctl stop httpd.service
        ;;
status|monitor)
        echo "Zabbix Services Status"
        systemctl status zabbix-server.service
        echo ""
        echo ""
        systemctl status httpd.service
        ;;
esac
```

Save the file and make it mode 755. Remember: In both zabbix nodes:

```bash
chmod 755 /usr/local/bin/zabbix-ha-control.sh
```

And in both nodes, proceed to modify the zabbix script LSB file:

```bash
vi /etc/init.d/zabbixsvc
```

New contents:

```bash
#!/bin/bash
#

mystatus=`/usr/local/bin/zabbix-ha-control.sh status 2>/dev/null|grep -ci "server is running"`

case $1 in
start)
        echo "Starting Zabbix HA Services"
        echo "0" > /var/log/zabbix-ha-started.log
        rm -f /var/log/zabbix-ha-stopped.log
        /usr/local/bin/zabbix-ha-control.sh start > /dev/null 2>&1
        exit 0
        ;;
stop)
        echo "Stopping Zabbix HA Services"
        rm -f /var/log/zabbix-ha-started.log
        echo "0" > /var/log/zabbix-ha-stopped.log
        /usr/local/bin/zabbix-ha-control.sh stop > /dev/null 2>&1
        exit 0
        ;;
status|monitor)
        echo "Zabbix HA Services Status"
        if [ $mystatus == "0" ]
        then
                rm -f /var/log/zabbix-ha-started.log
                echo "0" > /var/log/zabbix-ha-stopped.log
                exit 3
        else
                echo "0" > /var/log/zabbix-ha-started.log
                rm -f /var/log/zabbix-ha-stopped.log
                exit 0
        fi
        ;;
restart)
        echo "Zabbix HA Services Restart"
        /usr/local/bin/zabbix-ha-control.sh stop > /dev/null 2>&1
        /usr/local/bin/zabbix-ha-control.sh start > /dev/null 2>&1
        rm -f /var/log/zabbix-ha-started.log
        echo "0" > /var/log/zabbix-ha-stopped.log
        exit 0
        ;;
esac
```

**NOTE: It is very important to ensure the exit codes are the right ones. We can verify this:**

```
/etc/init.d/zabbixsvc status;echo "echo result: $?"
/etc/init.d/zabbixsvc monitor;echo "echo result: $?"
/etc/init.d/zabbixsvc start;echo "echo result: $?"
/etc/init.d/zabbixsvc stop;echo "echo result: $?"
/etc/init.d/zabbixsvc restart;echo "echo result: $?"
```

In the primary/active node (172.16.10.57) start-up the services:

```
/usr/local/bin/zabbix-ha-control.sh start
```

In both Zabbix nodes, create the following file (it's a simple html redirect):

```
vi /var/www/html/index.html
```

Containing:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/zabbix">
</HEAD>
<BODY>
</BODY>
</HTML>
```

With a browser of your preference (firefox, chrome, ms-ie, etc.) enter to the HTTP VIP (for our setup: 172.16.10.222) in order to continue with the installation:

**http://172.16.10.222**

After a brief wizard, near the third slide, you will be prompted to configure the database access. Use the following data:

> Database Type: mysql
> 
> Database Host: 172.16.10.221
> 
> Database Port: 3306
> 
> Database Name: zabbixdb
> 
> User: zabbixuser
> 
> Password: P@ssw0rd
> 

In the following slide, put this:

> Host: localhost
> 
> Port: 10051
> 
> Name:
> 

**NOTE: Leave the name in blank as it is**

After following the wizard, in the primary node you'll have the following file configured:

**/etc/zabbix/web/zabbix.conf.php**

Proceed to scp this file to the secondary node (172.16.10.58):

```
scp /etc/zabbix/web/zabbix.conf.php vm-172-16-10-58:/etc/zabbix/web/
```

If everything goes OK, you'll be able to enter to your zabbix installation with the following default user/pass:

> User: Admin
> 
> Pass: zabbix
> 


### Agent Configuration (Cluster Nodes):

In both zabbix nodes, proceed to edit the file `/etc/zabbix/zabbix_agentd.conf`:

Change the following values:

```
Server=172.16.10.57,172.16.10.58
ServerActive=172.16.10.57,172.16.10.58
```

Comment out the Hostname:

```
#Hostname=Zabbix server
```

Save the file and enable/start the agent:

```
systemctl enable zabbix-agent
systemctl stop zabbix-agent
systemctl start zabbix-agent
systemctl status zabbix-agent
```

**VERY IMPORTANT NOTE: For every agent you configure, no matter if it's linux, unix or windows, in the config items "Server" and "ServerActive", you must put BOTH Real IP (RIP's) of both zabbix nodes. NEVER EVER put the VIP !. Both IP's always comma-separated as in the agent config previouslly performed on both zabbix nodes**


### Extra recommendations for survival on big environments:

If your environment is big, with multiple sites (datacenters), distribute your monitoring load using Zabbix Proxies. Install a Zabbix Proxy (with it's own database) in the site, register/define it in the Main Zabbix Server (you must do this in the Zabbix Admin Page), and configure all the agents in your site with the IP of the proxy (Server and ServerActive items).

Doing this, you'll save a lot of extra load in your main zabbix server, you'll save some bandwidth, and make your whole monitoring solution more resilient to wan-link failures.

Also remember zabbix is a "database-hungry" solution. You need more power ??... add more nodes to the MariaDB Cluster (grow horizontally).

END.-
