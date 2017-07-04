# [CLUSTERING DOCKER CONTAINERS WITH MESOS/MARATHON ON UBUNTU 1604LTS](http://tigerlinux.github.io)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

This article will explore how to build and operate a Mesos/Marathon cluster on Ubuntu 16.04lts. We'll go trough all stages for the cluster construction and configuration, up to how to launch, manage and load-balance dockerized services inside the cluster.

We'll use Mesos 1.3.0 and marathon 1.4.5 (from mesos oficial APT repositories for Ubuntu 16.04lts).



## Base environment:

Four cloud instances (OpenStack based), two for masters, two for slaves. Base O/S: Ubuntu Server 16.04LTS 64 bits (amd64), fully updated:

server-12.virtualstack2.gatuvelus.home (192.168.150.12) - master01
server-17.virtualstack2.gatuvelus.home (192.168.150.17) - master02
server-24.virtualstack2.gatuvelus.home (192.168.150.24) - slave01
server-26.virtualstack2.gatuvelus.home (192.168.150.26) - slave02



## Mesos/Marathon/Docker packages installation:

The following steps need to be performed on all four machines. We are going to install repositories and base mesosphere sofware. Note that, all commands will be done inside the root account on the linux machines:

```bash
apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF

cat <<EOF >/etc/apt/sources.list.d/mesosphere.list
deb http://repos.mesosphere.com/ubuntu xenial main
EOF

apt-get -y update
```

In our masters (192.168.150.12 and .17) we'll proceed to install the mesos/marathon/zookeeper packages and some extra dependencies. Run the following commands in the masters:

```bash
apt-get -y install mesos marathon zookeeper

systemctl disable mesos-slave
systemctl stop mesos-master
systemctl stop mesos-slave
systemctl stop marathon
systemctl enable marathon
systemctl enable mesos-master
systemctl stop zookeeper
systemctl enable zookeeper

apt-get -y install python-pip jq curl
pip install mesos.cli

``` 

In our slaves (192.168.150.24 and .26) we'll proceed to install the following packages (docker included):

```bash
apt-get -y update
apt-get -y remove docker docker-engine
apt-get -y install \
apt-transport-https \
ca-certificates \
curl \
software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

apt-get -y update
apt-get -y install docker-ce
systemctl enable docker
systemctl start docker
systemctl restart docker

apt-get -y install mesos zookeeper

systemctl enable mesos-slave
systemctl stop mesos-master
systemctl stop mesos-slave
systemctl stop marathon
systemctl disable marathon
systemctl disable mesos-master
systemctl stop zookeeper
systemctl disable zookeeper

```


## Zookeeper configuration in the Masters:

We need to configure our zookeeper cluster. Run the following commands on both masters (192.168.150.12 and .17):

```bash
echo "server.1=192.168.150.12:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
echo "server.2=192.168.150.17:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
```

In our first master (192.168.150.12) run the following commands:

```bash
echo "1" > /etc/zookeeper/conf/myid
systemctl start zookeeper
systemctl status zookeeper
```

In our second master (192.168.150.17) run the following commands:

```bash
echo "2" > /etc/zookeeper/conf/myid
systemctl start zookeeper
systemctl status zookeeper
```

**Note: Each zookeeper node should have an unique number from 1 to 255. For our cluster, the first master will be "1" and the second master will be "2".**



## Masters final configuration:

With our zookeeper cluster running, now is the time to configure our mesos/marathon services in the masters. Run the following command on both masters (192.168.150.12 and .17):

```bash
echo "1" > /etc/mesos-master/quorum
echo "zk://192.168.150.12:2181,192.168.150.17:2181/mesos" > /etc/mesos/zk
cat /etc/mesos/zk

ip a|grep 192.168.150|awk '{print $2}'|cut -d/ -f1 > /etc/mesos-master/ip
cat /etc/mesos-master/ip > /etc/mesos-master/hostname
cat /etc/mesos-master/hostname

echo "mesoscluster01" > /etc/mesos-master/cluster
cat /etc/mesos-master/cluster

mkdir -p /etc/marathon/conf
cat /etc/mesos-master/hostname > /etc/marathon/conf/hostname
cat /etc/marathon/conf/hostname

echo "zk://192.168.150.12:2181,192.168.150.17:2181/mesos" > /etc/marathon/conf/master
echo "zk://192.168.150.12:2181,192.168.150.17:2181/marathon" > /etc/marathon/conf/zk
cat /etc/marathon/conf/master
cat /etc/marathon/conf/zk

systemctl enable mesos-master
systemctl enable marathon
systemctl start mesos-master
systemctl start marathon

cat <<EOF >/usr/local/etc/.mesos.json
{
    "profile": "default",
    "default": {
        "master": "zk://localhost:2181/mesos",
        "log_level": "warning",
        "log_file": "/var/log/mesos-cli.log"
    }
}
EOF

```

It will take few seconds (maybe a minute) to have all services fully working. Mesos will be available in port tcp:5050 and marathon in port tcp:8080. You can use a browser to see both services at their respective ports:

- Mesos: http://MASTER_IP:5050
- Marathon: http://MASTER_IP:8080



## Slaves final configuration:

With our master configured and running, we need to add the slaves to the cluster. Run the following command on both slaves (192.168.150.24 and .26):

```bash
echo "zk://192.168.150.12:2181,192.168.150.17:2181/mesos" > /etc/mesos/zk
cat /etc/mesos/zk

ip a|grep 192.168.150|awk '{print $2}'|cut -d/ -f1 > /etc/mesos-slave/ip
cat /etc/mesos-slave/ip > /etc/mesos-slave/hostname
cat /etc/mesos-slave/hostname

echo "docker,mesos" > /etc/mesos-slave/containerizers
echo "docker" > /etc/mesos-slave/image_providers
echo "filesystem/linux,docker/runtime" > /etc/mesos-slave/isolation
echo "10mins" > /etc/mesos-slave/executor_registration_timeout

cat <<EOF >/etc/mesos-slave/executor_environment_variables
{
  "JAVA_HOME": "/usr/lib/jvm/java-8-openjdk-amd64"
}
EOF

systemctl enable mesos-slave
systemctl start mesos-slave

```


## Using the Marathon API from console.

Both mesos and marathon expose web interfaces, avaiable on ports 5050 (mesos) and 8080 (marathon) on any of the masters. Also, mesos exposes an API that you can (and will) interact with using curl. The current API


```bash
curl -X GET -H "Content-Type: application/json" http://192.168.150.12:8080/v2/info 2>/dev/null| jq '.'

{
  "name": "marathon",
  "version": "1.4.5",
  "buildref": "unknown",
  "elected": true,
  "leader": "192.168.150.17:8080",
  "frameworkId": "bbf812e3-3faf-4ff7-8c14-3ca2152811cf-0000",
  "marathon_config": {
    "master": "zk://192.168.150.12:2181,192.168.150.17:2181/mesos",
    "failover_timeout": 604800,
    "framework_name": "marathon",
    "ha": true,
    "checkpoint": true,
    "local_port_min": 10000,
    "local_port_max": 20000,
    "executor": "//cmd",
    "hostname": "192.168.150.17",
    "webui_url": null,
    "mesos_role": null,
    "task_launch_timeout": 300000,
    "task_reservation_timeout": 20000,
    "reconciliation_initial_delay": 15000,
    "reconciliation_interval": 600000,
    "mesos_user": "root",
    "leader_proxy_connection_timeout_ms": 5000,
    "leader_proxy_read_timeout_ms": 10000,
    "features": [],
    "mesos_leader_ui_url": "http://192.168.150.17:5050/"
  },
  "zookeeper_config": {
    "zk": "zk://192.168.150.12:2181,192.168.150.17:2181/marathon",
    "zk_timeout": 10000,
    "zk_session_timeout": 10000,
    "zk_max_versions": 50
  },
  "event_subscriber": null,
  "http_config": {
    "http_port": 8080,
    "https_port": 8443
  }
}

```

All outputs and inputs are in JSON format. For the outputs, you can parse them with "jq" or "python -m json.tool" (the example above used jq, and more examples in the following chapters uses python for json parsing).

The complete API reference for Marathon is in the following link:

- [https://mesosphere.github.io/marathon/api-console/index.html](https://mesosphere.github.io/marathon/api-console/index.html)



## Defining custom application ports on the slaves.

Mesos/marathon assign in a dynamic way the port mappings for your containers. If you want to force the external port to, by example, http (80), https (443), mysql (3306) or in general any port you want to specify, you need to make those ports available in your slaves as "resources". The ports should be specified on ranges. Use the following commands in your slaves in order to acomplish this task:

```bash
cat <<EOF > /etc/mesos-slave/resources
ports:[80-82,3306-3306]
EOF

systemctl stop mesos-slave
rm -rf /var/lib/mesos/*
systemctl start mesos-slave

```

**NOTE: If you don't include the port resources with the ports you want to expose in your nodes, mesos will be unable to deploy containers in "BRIDGE" mode with specific hostPort's different than "0".**



## Deploying applications on Mesos/Marathon PART 1: A single web server.

Let's begin with a simple docker-based apache server, exposing port tcp 80. Run the following command on any of your masters:

```bash

cat <<EOF >/root/simple-apache.json
{
  "id": "apache-simple-01",
  "mem": 0,
  "cpus": 0,
  "disk": 0,
  "instances": 1,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "httpd:2.4-alpine",
      "forcePullImage": true,
      "network": "BRIDGE",
      "portMappings": [
        { 
          "containerPort": 80, 
          "hostPort": 80,	  
          "protocol": "tcp"
        }
      ]
    }
  },
  "healthChecks": [
    {
      "protocol": "HTTP",
      "path": "/",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ]
}
EOF

curl -X POST -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps -d@/root/simple-apache.json

```

This instruction will schedule the creation of a docker container, exposing port 80 (hostPort) to internal port 80 (containerPort). Note: For exposing ports different than the default ones, you need to include those ports as described earlier on this article. Also, if you change your port offering, you need to stop mesos-slave, erase all files under "/var/lib/mesos/" and start mesos-slave again. Example below:

```bash
cat <<EOF > /etc/mesos-slave/resources
ports:[80-82,443-443,2048-65535]
EOF

systemctl stop mesos-slave
rm -rf /var/lib/mesos/*
systemctl start mesos-slave

```

The "healthChecks" is one of the most important configurations in any mesos/marathon application. Here is where Mesos/Marathon control the health of your tasks, and when the application is unhealthy, it takes actions (like starting a new instance in order to replace the failed task).

You can check the status of your application using the browser (http://MASTER_IP:8080) or in the console with the mesos cli:

```bash
 mesos ps
   TIME   STATE    RSS    CPU  %MEM     COMMAND     USER                            ID
 0:00:00    R    1.92 MB  1.1  1.50  NO EXECUTABLE  root  apache-simple-01.a8181c8d-604d-11e7-807b-fa163e314f39
```

The application can be deleted using the browser (http://MASTER_IP:8080) or in the console with a call to the REST API:

```bash
curl -X DELETE -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps/apache-simple-01 2>/dev/null| python -m json.tool
``` 

The last command will return:

```bash
{
    "deploymentId": "578d3e8a-3af6-4e21-8063-dd83337e1b97",
    "version": "2017-07-04T01:10:08.717Z"
}
```



## Deploying applications on Mesos/Marathon PART 2: Two apache servers with NFS shared storage.

In the following example, we'll add a NFS storage to our cluster (specifically to our slaves), and let a pair of containers ("instances": 2) to use the shared storage defined as "volumes" inside the application definition. Our NFS shared storage address is: 192.168.1.1:/data/mesos-nfs

First, let's enable nfs and mount our storage with the following commands on both slaves (192.168.150.24 and .26):

```bash
apt-get -y install nfs-common
mkdir -p /mnt/nfs-storage
echo "192.168.1.1:/data/mesos-nfs /mnt/nfs-storage nfs auto,rw,hard,intr,timeo=90,bg,vers=3,proto=tcp,rsize=32768,wsize=32768 0 0" >> /etc/fstab
mount /mnt/nfs-storage

```

In any of the slaves, run the following commands in order to create a directory containing a simple index.html file:

```bash
mkdir /mnt/nfs-storage/webdir-01
echo "HELLO MESOS WORLD" > /mnt/nfs-storage/webdir-01/index.html
```

Next, in any of our masters, let's deploy our application, with two replicas, and using the shared storage:

```bash
cat <<EOF >/root/apache-nfs-replicated.json
{
  "id": "apache-nfs-01",
  "mem": 0,
  "cpus": 0,
  "disk": 0,
  "instances": 2,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "httpd:2.4-alpine",
      "forcePullImage": true,
      "network": "BRIDGE",
      "portMappings": [
        { 
          "containerPort": 80, 
          "hostPort": 80,	  
          "protocol": "tcp"
        }
      ]
    },
    "volumes": [
     {
        "containerPath": "/usr/local/apache2/htdocs",
        "hostPath": "/mnt/nfs-storage/webdir-01",
        "mode": "RW"
     }
    ]
  },
  "healthChecks": [
    {
      "protocol": "HTTP",
      "path": "/",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ]
}
EOF

curl -X POST -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps -d@/root/apache-nfs-replicated.json

```

We can list our applications using either "mesos ps" in any of the masters or the following REST call:

```bash
curl -X GET -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps 2>/dev/null| python -m json.tool
```

And our specific tasks:

```bash
curl -X GET -H "Content-Type: application/json" http://192.168.150.12:8080/v2/tasks 2>/dev/null| python -m json.tool
```

Using "jq" parser, we can obtain the hosts running our tasks for our specific application (which we named "apache-nfs-01") :

```bash
curl -X GET -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps/apache-nfs-01/tasks 2>/dev/null| jq '.tasks[].host'

"192.168.150.26"
"192.168.150.24"
```

With our IP's, and knowing our app port (80 as defined on "hostPort" inside the json file), let's tests our docker-based web servers:

```bash
curl http://192.168.150.24
HELLO MESOS WORLD

curl http://192.168.150.26
HELLO MESOS WORLD
```


## Deploying applications on Mesos/Marathon PART 3: Testing failover, shared storage and passing environment variables to our docker containers.

Let's play a little more. This time with a mariadb database service running in a container, and we'll see what happens when the container get killed somehow.

In order to prepare our environment, let's run the following commands on any of our slaves:

```bash
mkdir -p /mnt/nfs-storage/mariadb-service-01/config
mkdir -p /mnt/nfs-storage/mariadb-service-01/data

echo "[mysqld]" > /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "max_connections=100" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "max_allowed_packet=1024M" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "thread_cache_size=128" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "sort_buffer_size=4M" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "bulk_insert_buffer_size=16M" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "max_heap_table_size=32M" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf
echo "tmp_table_size=32M" >> /mnt/nfs-storage/mariadb-service-01/config/server.cnf

```


In any of the masters, run the following commands:

```bash
cat <<EOF >/root/mariadb-nfs.json
{
  "id": "mariadb-nfs-01",
  "mem": 0,
  "cpus": 0,
  "disk": 0,
  "instances": 1,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "mariadb:10.1",
      "forcePullImage": true,
      "network": "BRIDGE",
      "portMappings": [
        { 
          "containerPort": 3306, 
          "hostPort": 3306,
          "protocol": "tcp"
        }
      ]
    },
    "volumes": [
     {
        "containerPath": "/etc/mysql/conf.d",
        "hostPath": "/mnt/nfs-storage/mariadb-service-01/config",
        "mode": "RW"
     },
     {
        "containerPath": "/var/lib/mysql",
        "hostPath": "/mnt/nfs-storage/mariadb-service-01/data",
        "mode": "RW"
     }
    ]
  },
  "env": {
    "MYSQL_ROOT_PASSWORD": "P@ssw0rd"
  },
  "healthChecks": [
    {
      "protocol": "TCP",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ],
  "unreachableStrategy": {
    "inactiveAfterSeconds": 60,
    "expungeAfterSeconds": 120
  }
}
EOF

curl -X POST -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps -d@/root/mariadb-nfs.json

```

Note something here: The container image we are using (mariadb:10.1) requires an environment variable "MYSQL_ROOT_PASSWORD" to be passed to the container at creation/run time. This is acomplished in Mesos/Marathon by including a "env:" section in our JSON:

```bash
  "env": {
    "MYSQL_ROOT_PASSWORD": "P@ssw0rd"
  },
```

After deploying our applicaiton, we can check the host in which it is running:

```bash
curl -X GET -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps/mariadb-nfs-01/tasks 2>/dev/null| jq '.tasks[].host'

"192.168.150.24"
```

Let's force a failure to see how mesos/marathon recovers: In the slave "192.168.150.24" force a "reboot". If you observe the application in the marathon dashboard (http://MASTER_IP:8080). The app will be marked as "unhealthy". After the time indicated on "inactiveAfterSeconds" has passed (60 for our deployed application plus our grace period, again, 60 more seconds), a new instance will be launched with the original data left on the shared storage. You can control the way an application gets re-scheduled after a failure with the sections:

```bash
  "healthChecks": [
    {
      "protocol": "TCP",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ],
  "unreachableStrategy": {
    "inactiveAfterSeconds": 60,
    "expungeAfterSeconds": 120
  }
```

More information about controling the tasks behaviour in the following links:

- [Marathon: Health Checks and Task Termination.] (https://mesosphere.github.io/marathon/docs/health-checks.html)
- [Marathon: Task Handling Configuration](https://mesosphere.github.io/marathon/docs/configure-task-handling.html)

NOTE: Before continuing, we need to delete our applications, as they will interfere with the usage of "marathon-lb" in the following section of this article:

```bash
curl -X DELETE -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps/apache-nfs-01 2>/dev/null| python -m json.tool
curl -X DELETE -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps/mariadb-nfs-01 2>/dev/null| python -m json.tool
```



## Marathon load balancer.

Consider the following escenario: You want to expose specific services trough a load balancer in a configurable and automatic way, fully integrated with mesos/marathon. Marathon includes a "service" which runs inside a container for that specific task: marathon-lb.

In our setup, we'll install marathon-lb in both slaves. Normally, the recommendation is to have about three marathon-lb services each running in its own server, but for our setup we'll just use two, one on each slave. Another recommendation is to have mesos endpoint served trough a load balancer and let marathon-lb connect to mesos using the load-balanced endpoint. For now and in order to make things simpler, we are not going to load-balance our mesos endpoints (we could do it, due the fact that we are running inside OpenStack and we have LBaaSV2 available, but let's keep this simple).

Then, in our slaves, run the following commands:

```bash
docker pull mesosphere/marathon-lb

docker create \
--name marathon-lb-01 \
-e PORTS=9090 \
--net=host \
--privileged \
mesosphere/marathon-lb \
sse \
--marathon http://192.168.150.12:8080 \
--group webapps01

cat <<EOF >/etc/systemd/system/marathon-lb-01.service
[Unit]
Description=Marathon Load Balancer Service
Requires=docker.service
After=docker.service

[Service]
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/docker start -a %p
ExecStop=-/usr/bin/docker stop -t 2 %p

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable marathon-lb-01
systemctl start marathon-lb-01

```

**NOTE: In the servers where marathon-lb starts, the service will take control of ports 80, 443, 9090 and 9091. Do not attempt to deploy services with a hostport using those ports.**

We have two load balancers, one on each slave.

Now, let's deploy a service with two instances. Note some differences here from what we have being doing:

- We are including a "labels" section. One of the labels uses the key "HAPROXY_GROUP" with the value "webapps01". Our marathon-lb service was created with "--group webapps01". This means that, any application launched in marathon with this key/value combination in it's label will be "load-balanced" by our marathon-lb services.
- Also included in the labels is the key "HAPROXY_0_VHOST" with value "server-26.virtualstack2.gatuvelus.home". This will instruct marathon-lb to serve on it's http port (being exposed on the slave where is being run) any http requesto to this hostname (mean: host-header name recognition at load-balancer level).
- We are using "hostPort": 0 in our json file, and instead using "servicePort": 10240. This will instruct marathon-lb to server the application on the port indicated by "servicePort".

Then, run the following commands on any master:

```bash
cat <<EOF >/root/apache-nfs-replicated-lb.json
{
  "id": "apache-nfs-lb-01",
  "labels": {
      "HAPROXY_GROUP": "webapps01",
      "HAPROXY_0_VHOST": "server-26.virtualstack2.gatuvelus.home"
  },
  "mem": 0,
  "cpus": 0,
  "disk": 0,
  "instances": 2,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "httpd:2.4-alpine",
      "forcePullImage": true,
      "network": "BRIDGE",
      "portMappings": [
        { 
          "containerPort": 80, 
          "hostPort": 0,
          "servicePort": 10240,	  
          "protocol": "tcp"
        }
      ]
    },
    "volumes": [
     {
        "containerPath": "/usr/local/apache2/htdocs",
        "hostPath": "/mnt/nfs-storage/webdir-01",
        "mode": "RW"
     }
    ]
  },
  "healthChecks": [
    {
      "protocol": "HTTP",
      "path": "/",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ]
}
EOF

curl -X POST -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps -d@/root/apache-nfs-replicated-lb.json

```

Let's do some testing:

```bash
curl http://server-26.virtualstack2.gatuvelus.home/
HELLO MESOS WORLD

curl http://192.168.150.24:10240
HELLO MESOS WORLD

curl http://192.168.150.26:10240
HELLO MESOS WORLD

curl http://server-24.virtualstack2.gatuvelus.home/
<html><body><h1>503 Service Unavailable</h1>
No server is available to handle this request.
</body></html>
```

Time to analize our results:

- The port "10240" is being served by both marathon-lb services running on both slaves, so the "curl" requests to this port on both slaves are successfull.
- The port 80 on server 192.168.150.26 (hostname: server-26.virtualstack2.gatuvelus.home) is being served with host-header-name recognition for the hostname "server-26.virtualstack2.gatuvelus.home". That's the reason the curl on server-26, port 80 works OK, and not in the case of server-24. There is no-one serving the host-header name "server-24.virtualstack2.gatuvelus.home".

Now, let's deploy a second application which will use "server-24.virtualstack2.gatuvelus.home" in the label. First, on any of our slaves, let's create a second web directory with a different index.html file:

```bash
mkdir /mnt/nfs-storage/webdir-02
echo "HELLO WORLD OF MARATHON-LB" > /mnt/nfs-storage/webdir-02/index.html
```

Then, run the following commands on any of our masters:

```bash
cat <<EOF >/root/apache-nfs-replicated-lb-02.json
{
  "id": "apache-nfs-lb-02",
  "labels": {
      "HAPROXY_GROUP": "webapps01",
      "HAPROXY_0_VHOST": "server-24.virtualstack2.gatuvelus.home"
  },
  "mem": 0,
  "cpus": 0,
  "disk": 0,
  "instances": 2,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "httpd:2.4-alpine",
      "forcePullImage": true,
      "network": "BRIDGE",
      "portMappings": [
        { 
          "containerPort": 80, 
          "hostPort": 0,
          "servicePort": 10241,	  
          "protocol": "tcp"
        }
      ]
    },
    "volumes": [
     {
        "containerPath": "/usr/local/apache2/htdocs",
        "hostPath": "/mnt/nfs-storage/webdir-02",
        "mode": "RW"
     }
    ]
  },
  "healthChecks": [
    {
      "protocol": "HTTP",
      "path": "/",
      "portIndex": 0,
      "gracePeriodSeconds": 60,
      "intervalSeconds": 10,
      "timeoutSeconds": 10,
      "maxConsecutiveFailures": 3
    }
  ]
}
EOF

curl -X POST -H "Content-Type: application/json" http://192.168.150.12:8080/v2/apps -d@/root/apache-nfs-replicated-lb-02.json

```

The last application will deploy our services on the "marathon-lb" port 10241. Let's do some testing:

```bash
curl http://server-26.virtualstack2.gatuvelus.home
HELLO MESOS WORLD

curl http://server-24.virtualstack2.gatuvelus.home
HELLO WORLD OF MARATHON-LB

curl http://192.168.150.24:10241
HELLO WORLD OF MARATHON-LB

curl http://192.168.150.26:10241
HELLO WORLD OF MARATHON-LB

curl http://192.168.150.24:10240
HELLO MESOS WORLD

curl http://192.168.150.26:10240
HELLO MESOS WORLD
```

Now, let's force curl to send a specific host-header name to each of our LB's IP's:

```bash
curl --header 'Host: server-24.virtualstack2.gatuvelus.home' http://192.168.150.24
HELLO WORLD OF MARATHON-LB

curl --header 'Host: server-26.virtualstack2.gatuvelus.home' http://192.168.150.24
HELLO MESOS WORLD

curl --header 'Host: server-24.virtualstack2.gatuvelus.home' http://192.168.150.26
HELLO WORLD OF MARATHON-LB

curl --header 'Host: server-26.virtualstack2.gatuvelus.home' http://192.168.150.26
HELLO MESOS WORLD
```

You can see your marathon-lb layer working as it shoud. In real-world operational conditions, you should put a load-balancer in front of all marathon-lb services in order to have high-availability and real load balancing.

Note something very important here: "marathon-lb" is not only a load balancer. It is a "service discovery" component. It discovers the applications trough the use of the labels, then expose them to the specific ports and host-header names requested inside the application configuration json file.

Mode documentation about "marathon-lb" in the following links:

- [Marathon-lb github repo](https://github.com/mesosphere/marathon-lb)
- [Marathon-lb WIKI](https://github.com/mesosphere/marathon-lb/wiki)
- [Marathon-lb help](https://github.com/mesosphere/marathon-lb/blob/master/Longhelp.md)

NOTE: Marathon-lb exposes some interesting things too. The following URL (by example) expose all stats in the load balancer: http://192.168.150.26:9090/haproxy?stats. In the documentation you'll find more about what kind of information (and how to use it) is being provided by marathon-lb.



## Operational Recommendations:

- Load balance your masters. This include ports 5050 (mesos) and 8080 (marathon).
- Restrict the endpoints to specific networks and consider using authentication. Marathon support ldap-authentication trough it's plugin architecture.
- Start your master cluster layer with at least 3 servers. Set your quorum to at least the size of your cluster plus one. If your cluster has three servers, set your quorum to 2.
- Don't spawn too many marathon-lb services or you will impose too much load over your mesos/marathon masters. Also, consider a load balancer in front of your marathon-lb servers.
- Check carefully all mesos/marathon documentation. Mesos/marathon can do a lot more of what we did on this article. Mesos can deploy services taking into consideration constrains that include hosts and racks.

END.-
