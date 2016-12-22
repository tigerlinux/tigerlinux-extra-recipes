# A MARIADB 10.1 ACTIVE/ACTIVE SYNCHRONOUS CLUSTER FOR THE CLOUD.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

- Create a highly available multi master synchronous replication cluster with MariaDB


## Where are we going to install it ?:

Two virtual servers (4 vpcu, 16GB Ram, two virtual HD's, one for the O/S with 15GB, the other for the Database with 60GB's.). OS: Centos 7 with EPEL Repo installed. Fully updated. FirewallD and SELINUX disabled.

**NOTE:The virtual servers are openstack based, but, this can be replicated on any cloud platform or with bare metal servers.**

Hostnames/IP's of our servers:

**vm-172-16-11-114.mydomain.dom (IP: 172.16.11.114)**
**vm-172-16-11-115.mydomain.dom (IP: 172.16.11.115)**


## How we constructed the whole thing ?:


### Basic server setup:

In our setup, the second disk (**/dev/vdb**) will be used for the MariaDB data.

On both servers proceed to execute the following commands

```
mkfs.xfs -f -L mariadbdata /dev/vdb

mkdir /mariadbdata

cp /etc/fstab /etc/fstab.BAK.NO-ERASE
echo "LABEL=mariadbdata /mariadbdata xfs rw,noauto 0 0" >> /etc/fstab

mount /mariadbdata
```

Our data will be located on /mariadbdata directory.


### MariaDB Repositories and Packages:

Now, we need to install the mariaDB 10.1 repository. The following commands must be executed on all servers:

Create the following file:

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

Save the file, and run the following commands:

```
yum clean all
yum -y update

yum -y install MariaDB MariaDB-server MariaDB-client galera

mv /var/lib/mysql /mariadbdata/

ln -s /mariadbdata/mysql /var/lib/mysql

/etc/init.d/mysql start
chkconfig mysql on
```

Then, execute the following command:

```
mysql_secure_installation
```

When asked, set root password to "P@ssw0rd" (use something more cryptic for real-world environments) and allow root remote connections.

Then, execute the following commands:

```
echo "[client]" > /root/.my.cnf
echo "user = "root"" >> /root/.my.cnf
echo "password = \"P@ssw0rd\""  >> /root/.my.cnf 
echo "host = \"localhost\""  >> /root/.my.cnf

chmod 600 /root/.my.cnf
```

**NOTE: In the /root/.my.cnf file, ensure the password is the same you used when ran mysql_secure_installation command.**

Run the `mysql` command, and once inside, execute the following sql commands. Again, use the same password !:

```
mysql

MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'P@ssw0rd' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> exit
```

Then stop the database services:

```
/etc/init.d/mysql stop
```


### MariaDB/Galera CLUSTER Setup:

In the first node (172.16.11.114) we proceed to create the cluster config file:

```
vi /etc/my.cnf.d/cluster.cnf
```

Contents:

```
[mysqld]
wsrep_on=ON
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
query_cache_size=0
bind-address=0.0.0.0
max_allowed_packet=1024M
max_connections=1000
innodb_doublewrite=1

datadir=/mariadbdata/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2

# Galera Provider Configuration
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#wsrep_provider_options="gcache.size=32G"

# Galera Cluster Configuration
wsrep_cluster_name="MariaDB-Cluster01"
wsrep_cluster_address="gcomm://172.16.11.114,172.16.11.115"

# Galera Synchronization Congifuration
wsrep_sst_method=rsync
#wsrep_sst_auth=user:pass

# Galera Node Configuration
wsrep_node_address="172.16.11.114"
wsrep_node_name="vm-172-16-11-114"
```

Save the file and continue with the second node:

In the second node (172.16.11.115) we proceed to create the cluster config file:

```
vi /etc/my.cnf.d/cluster.cnf
```

```
[mysqld]
wsrep_on=ON
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
query_cache_size=0
bind-address=0.0.0.0
max_allowed_packet=1024M
max_connections=1000
innodb_doublewrite=1

datadir=/mariadbdata/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2

# Galera Provider Configuration
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#wsrep_provider_options="gcache.size=32G"

# Galera Cluster Configuration
wsrep_cluster_name="MariaDB-Cluster01"
wsrep_cluster_address="gcomm://172.16.11.114,172.16.11.115"

# Galera Synchronization Congifuration
wsrep_sst_method=rsync
#wsrep_sst_auth=user:pass

# Galera Node Configuration
wsrep_node_address="172.16.11.115"
wsrep_node_name="vm-172-16-11-115"
```

And again, we save the file.

In the first node (172.16.11.114) we proceed to execute the following command:

```
galera_new_cluster
```

This command start the new cluster !. Basically, you are performing a **"cluster bootstrap"**.

In the second node (172.16.11.115) we just start the service:

```
/etc/init.d/mysql start
```

**NOTES:**
* The services MUST BE disabled. Do not use `chkconfig mysql on` or `systemctl enable mysql` !.
* The first node to start with the command **"galera_new_cluster"** will start the cluster service, and the remaining nodes will join the cluster. All cluster will then fully synchronice up to a "multi-master/multi-active" configuration.
* In the cluster goes completelly down (energy disruption, or administrativelly down by human intervention), you should start the same way: One onde with `galera_new_cluster` command, and the other nodes with `/etc/init.d/mysql start`. You may need to check wich node have the most up-to-date data. See mariadb documentation in order to know how to perform this check.

After all nodes are working, you can check the cluster status entering to the the service (with `mysql` command) and running the SQL:

```
MariaDB [(none)]> SHOW STATUS LIKE 'wsrep%';
```


### Post configuration:

After we have our cluster running, we should install tuned-utils and set to either virtual-guest or throughput-performance:

```
yum install tuned tuned-utils
```

Then we activate and enable the profile:

```
tuned-adm profile virtual-guest
systemctl enable tuned
systemctl restart tuned
systemctl status tuned
```

**NOTE: If you are using bare-metal servers, use "throughput-performance" instead of "virtual-guest".**


### LBaaS Recommendations:

This solution is designed to be used behind a Layer 4 TCP load balancer. The autor of this recipe actually uses this solution behind LBaaS OpenStack Services for heavy-load traffic, including, Zabbix monitoring Service database backend (this will be included in another recipe in monitoring section).

Just create your pool with the MariaDB port (3306). Depending of your front-end solution, you may need to include "session persistence" based on source IP. Try to use "least connections" balancing method with TCP basic healtcheck.


### And of course: The Backup Script and crontab:


In all servers, create the following script:

```
vi /usr/local/bin/server-backup.sh
```

Contents:

```bash
#!/bin/bash
#
# Server Backup Script
#
# By Reinaldo Martínez P.
# Caracas, Venezuela.
# TigerLinux AT gmail DOT com
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

directory="/mnt/backups"
myhostname=`hostname -s`
timestamp=`date +%Y%m%d`
daystokeep=5
databasebackupuser="root"
databasebackuppass="P@ssw0rd"

#databases='
#        mysql
#        test
#'
databases=`echo "show databases"|mysql -s -u $databasebackupuser -p$databasebackuppass`

for i in $databases
do
        nice -n 10 ionice -c2 -n7 \
	mysqldump -u $databasebackupuser \
	-p$databasebackuppass \
	--single-transaction \
	--quick \
	--lock-tables=false \
	$i|gzip > $directory/backup-server-db-$i-$myhostname-$timestamp.gz
done

find $directory/ -name "backup-server-*$myhostname*gz" -mtime +$daystokeep -delete
find $directory/ -name "backup-server-db-*$myhostname*gz" -mtime +$daystokeep -delete

echo ""
echo "Server Backup Ready (Configurations and databases)"
echo "Log at: /var/log/server-backup-last-results.log"
echo "Backup file at: $directory/backup-server-$myhostname-$timestamp.tgz"
echo "Databases Backups at $directory/backup-server-db-DBNAME-$myhostname-$timestamp.gz"
echo ""
```

Save the file and make it exec:

```
chmod 755 /usr/local/bin/server-backup.sh
```

Create the directory:

```
mkdir -p /mnt/backups
```

And the crontab:

```
vi /etc/cron.d/server-db-backup-crontab
```

Contents:

```
#
#
# Server backup crontab
#
30 01 * * * root /usr/local/bin/server-backup.sh > /var/log/last-server-backup-crontab.log 2>&1
```

Save the file and restart crontab:

```
systemctl restart crond
```

The backup will run every day at 01:30am. Also, the script will erase backups older than 5 days.

**NOTES:**
* In production environments, you shoud create a mysql account with "select only" permissions and use this account for all backup related tasks. See the variables in the script: **databasebackupuser** and **databasebackuppass**.
* Also, the backup directoy **/mnt/backups** should be a mount point for a remote filesystem (NFS, CIFS, GLusterFS, etc.).
* Modify the variable **daystokeep** in order to have more (or less) historical backups.
* See the commented lines on the script. You can choose to backup only certain databases instead of all databases in the service.

END.-
