# CEILOMETER WITH GNOCCHI STORAGE BACKEND

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

Install and adapt Gnocchi to a previouslly installed OpenStack MITAKA Cloud (Centos 7) as a "Database Storage Backend" for Ceilometer.


## Where are we going to do it ?:

OpenStack Cloud (Mitaka over Centos 7) with Ceilometer/aodh configured and fully active.

The platform was installed by using the openstack automated installer available at the following link:

* [TigerLinux OpenStack MITAKA Automated Installer for Centos 7.](https://github.com/tigerlinux/openstack-mitaka-installer-centos7)

Server IP: 172.16.11.179.

We are using centos here for only one reason: The gnocchi packages are already available on Centos 7 Mitaka Cloud repositories at the time we performed those tests.


## How we constructed the whole thing ?:

### Basic OpenStack initial setup:

With our cloud already running, we need to create the services, endpoints and databases for Gnocchi:

Firts, let's create the service and endpoints:

```
source /root/keystonerc_fulladmin

openstack user create --domain default --password "P@ssw0rd" --email "gnocchi@localhost" gnocchi

openstack role add --project services --user gnocchi admin

openstack service create \
--name gnocchisvc \
--description "OpenStack Metric" \
metric

openstack endpoint create --region RegionOne \
metric public http://172.16.11.179:8041

openstack endpoint create --region RegionOne \
metric internal http://172.16.11.179:8041

openstack endpoint create --region RegionOne \
metric admin http://172.16.11.179:8041
```

Then the gnocchi database (our cloud database backend is MariaDB 10.1):

```
mysql

MariaDB [(none)]> CREATE DATABASE gnocchidb default character set utf8;
MariaDB [(none)]> GRANT ALL ON gnocchidb.* TO 'gnocchidbuser'@'%' IDENTIFIED BY 'P@ssw0rd';
MariaDB [(none)]> GRANT ALL ON gnocchidb.* TO 'gnocchidbuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';
MariaDB [(none)]> GRANT ALL ON gnocchidb.* TO 'gnocchidbuser'@'172.16.11.179' IDENTIFIED BY 'P@ssw0rd';
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> exit;
```


### Gnocchi installation and configuration:

We proceed to "yum install" all related gnocchi packages:

```
yum install openstack-gnocchi-api openstack-gnocchi-carbonara openstack-gnocchi-common \
openstack-gnocchi-indexer-sqlalchemy openstack-gnocchi-metricd openstack-gnocchi-statsd
```

Using crudini, let's proceed to configure gnocchi, section by section:

Logs:

```
crudini --set /etc/gnocchi/gnocchi.conf DEFAULT debug false
crudini --set /etc/gnocchi/gnocchi.conf DEFAULT verbose false
crudini --set /etc/gnocchi/gnocchi.conf DEFAULT log_file /var/log/gnocchi/gnocchi.log
```

Api:

```
crudini --set /etc/gnocchi/gnocchi.conf api host 0.0.0.0
crudini --set /etc/gnocchi/gnocchi.conf api port 8041
```

Database:

```
crudini --set /etc/gnocchi/gnocchi.conf database connection "mysql+pymysql://gnocchidbuser:P@ssw0rd@172.16.11.179:3306/gnocchidb"
```

Keystone Auth:

```
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken auth_uri http://172.16.11.179:5000
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken auth_url http://172.16.11.179:35357
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken auth_type password
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken auth_plugin password
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken memcached_servers 172.16.11.179:11211
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken project_domain_name default
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken user_domain_name default
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken project_name services
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken username gnocchi
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken password "P@ssw0rd"
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken admin_tenant_name services
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken admin_user gnocchi
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken admin_password "P@ssw0rd"
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken identity_uri http://172.16.11.179:35357
crudini --set /etc/gnocchi/gnocchi.conf keystone_authtoken auth_version v3
```

Storage:

```
crudini --set /etc/gnocchi/gnocchi.conf storage driver file
crudini --set /etc/gnocchi/gnocchi.conf storage file_basepath "/var/lib/gnocchi"
crudini --set /etc/gnocchi/gnocchi.conf storage coordination_url "file:///var/lib/gnocchi/locks"
```

**NOTE HERE that we are using file storage. Gnocchi can use a variety of storage for the time-series data.**

Indexer:

```
crudini --set /etc/gnocchi/gnocchi.conf indexer url "mysql+pymysql://gnocchidbuser:P@ssw0rd@172.16.11.179:3306/gnocchidb?charset=utf8"
crudini --set /etc/gnocchi/gnocchi.conf indexer driver sqlalchemy
```

Interesting combination: While time series are stored on a separated backend (file, swift, ceph, etc.), the indexes are stored in a SQL database.

Archive Policy:

```
crudini --set /etc/gnocchi/gnocchi.conf archive_policy default_aggregation_methods "mean,min,max,sum,std,median,count,last,95pct"
```

Pipeline:

```
crudini --set /etc/gnocchi/api-paste.ini "pipeline:main" pipeline "gnocchi+auth"
```

We proceed to populate/provision the gnocchi index database:

```
su gnocchi -s /bin/sh -c "gnocchi-upgrade --config-file /etc/gnocchi/gnocchi.conf --create-legacy-resource-types"
```

Start all gnocchi services:

```
systemctl start openstack-gnocchi-api openstack-gnocchi-metricd
```

And proceed to create the "default policy: low"

```
source /root/keystonerc_fulladmin

gnocchi archive-policy create -d granularity:5m,points:12 -d granularity:1h,points:24 -d granularity:1d,points:30 low
gnocchi archive-policy create -d granularity:60s,points:60 -d granularity:1h,points:168 -d granularity:1d,points:365 medium
gnocchi archive-policy create -d granularity:1s,points:86400 -d granularity:1m,points:43200 -d granularity:1h,points:8760 high
gnocchi archive-policy-rule create -a low -m "*" default
```

We are using our "automated openstack mitaka installer for centos 7" which comes with a service-control script. We need to include gnocchi services into the script:

```
vi /usr/local/bin/openstack-control.sh
```

```bash
if [ -f /etc/openstack-control-script-config/ceilometer-full-installed ]
then
        if [ -f /etc/openstack-control-script-config/ceilometer-without-compute ]
        then
                svcceilometer=(
                        "
			openstack-gnocchi-api
			openstack-gnocchi-metricd
                        openstack-ceilometer-central
                        openstack-ceilometer-api
                        openstack-ceilometer-collector
                        openstack-ceilometer-notification
                        openstack-ceilometer-polling
                        $alarm1
                        $alarm2
                        $alarm3
                        $alarm4
                        "
                )
        else
                svcceilometer=(
                        "
			openstack-gnocchi-api
			openstack-gnocchi-metricd
                        openstack-ceilometer-compute
                        openstack-ceilometer-central
                        openstack-ceilometer-api
                        openstack-ceilometer-collector
                        openstack-ceilometer-notification
                        openstack-ceilometer-polling
                        $alarm1
                        $alarm2
                        $alarm3
                        $alarm4
                        "
                )
        fi
else
```

This finish basic gnocchi setup and configuration.


### Ceilometer modifications:

With gnocchi ready, it's time to modify ceilometer in order to use it.

Just in order to have less time between metric recollections, we proceed to change the time from 10 minutes (600 seconds) to 1 minute (60 seconds). PLEASE do not repeat this on a production environment using MongoDB or you risk to kill your ceilometer and mongodb installation:

```bash
sed -r -i 's/600/60/g' /etc/ceilometer/pipeline.yaml
```

Then, let's modify ceilometer config in order to allow it to use gnocchi instead of MongoDB:

```bash
cat /etc/ceilometer/ceilometer.conf |grep -v _dispatchers > /etc/ceilometer/ceilometer.conf.TEMP
cat /etc/ceilometer/ceilometer.conf.TEMP > /etc/ceilometer/ceilometer.conf

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT meter_dispatchers gnocchi
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT event_dispatchers ""
crudini --set /etc/ceilometer/ceilometer.conf dispatcher_gnocchi url http://172.16.11.179:8041
crudini --set /etc/ceilometer/ceilometer.conf dispatcher_gnocchi filter_service_activity False
crudini --set /etc/ceilometer/ceilometer.conf dispatcher_gnocchi archive_policy low
crudini --set /etc/ceilometer/ceilometer.conf dispatcher_gnocchi resources_definition_file gnocchi_resources.yaml
crudini --set /etc/ceilometer/ceilometer.conf notification store_events false
```

NOTE: Currently, some ceilometer functions will break if you only use Gnocchi as database backend. If you want to keep both mongo and gnocchi, run the following command (see limitations section at the end of this recipe):

```bash
sed -r -i 's/meter_dispatchers\ =\ gnocchi/meter_dispatchers\ =\ gnocchi\nmeter_dispatchers\ =\ database/g' /etc/ceilometer/ceilometer.conf
```

Stop ceilometer, clean up logs, and start ceilometer again:

```bash
openstack-control.sh stop ceilometer

cd /var/log/ceilometer
for i in `ls *.log`; do echo "" > $i; done

openstack-control.sh start ceilometer
```

After few minutes, we'll begin to see the metrics:

```
source /root/keystonerc_fulladmin

gnocchi resource list
gnocchi metric list
gnocchi status
```

From this point, if you decided to have both gnocchi and mongodb, ceilometer will collect all metrics and send them to both mongo and gnocchi. If you opted to leave only gnocchi, then all metrics will be stored only in gnocchi, but, the commands "ceilometer meter-list" and "ceilometer resource-list" will break !. This is a current limitation waiting to be fixed.


### Limitations:

* There are packages for Centos 7 (Mitaka Centos Cloud Repo) and Ubuntu 16.04lts (Ubuntu Main Repo) but not for Ubuntu 14.04lts in ubuntu-cloud-archive. That means, for Ubuntu 14.04lts you'll need to use the packages from source at [gnocchi github repo.](https://github.com/openstack/gnocchi)
* With the ceilometer commands "meter-list" and "resource-list" broken at the moment if you use only gnocchi as db backend, we'll have to wait until this is properlly addressed if we want to use this solution in fully production environments.
* Horizon (the OpenStack web dashboard) is also affected, as it cannot obtain the metrics and resources from ceilometer while using only gnocchi as backend.
* You can use other graphing solutions wich can interface directly with gnocchi, but this means you'll have to do some extra work in order to configure properlly those graphing solutions.

END.-
