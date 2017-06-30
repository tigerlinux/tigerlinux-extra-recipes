# [CLUSTERING DOCKER WITH SWARM IN COREOS](http://tigerlinux.github.io)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

This article will explore how to build and operate a docker cluster in "swarm" mode using as a base operating system CoreOS Linux. We'll go trough all stages on the cluster construction and configuration, up to the many ways used to deploy replicated services in the cluster, and how to scale these services.


## Base environment:

We'll use CoreOS virtual machines deployed on a OpenStack cloud. CoreOS (stable-channel) 1409.5.0 with docker 1.12.6.

Four virtual instances, IP's: 192.168.150.3, 192.168.150.12, 192.168.150.16 and 192.168.150.22.


## Initial Setup:

First, we need to enable and start docker on all four servers:

```
systemctl enable docker
systemctl start docker
```


## SWARM Initalization:

Now is the time to build our swarm cluster. Initialy, we'll define two servers as managers (192.168.150.3 and 12), and the other two as workers (192.168.150.16 and 22). At a later stages on this article, we'll promote one of our workers to manager in order to have three managers in the cluster.

In the first "manager" machine (IP: 192.168.150.3) run the following command:

```bash
docker swarm init --advertise-addr 192.168.150.3
```

The command will output the following lines:

```
Swarm initialized: current node (cca1qryxm4lhyf7a6qywxsjoi) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-60102dvjqhjdvnkmvn6jzmuzz0s44pilkvmlkmldycdej1psv9-enq4jearscuseob8gor5105cq \
    192.168.150.3:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

**NOTE: The token will be different for each swarm cluster.**

You can always obtain the join token with the following command in any manager node:

```bash
docker swarm join-token worker
```

Also, if you want to include the output in a variable inside a shell script:

```bash
docker swarm join-token worker|grep "\-\-token"|awk '{print $2}'
```

The above commands will give you the token used to join the cluster as a "worker". Changing "worker" for "manager" will give you the token used to join as a "manager":

```bash
docker swarm join-token manager

docker swarm join-token manager|grep "\-\-token"|awk '{print $2}'
``` 


## Adding a second manager:

Obtain the "join token" by running the following command in the first manager (192.168.150.3):

```bash
docker swarm join-token manager
```

For this LAB, the output was:

```bash
docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-60102dvjqhjdvnkmvn6jzmuzz0s44pilkvmlkmldycdej1psv9-dw0lci5ps266iarbl7dib7561 \
    192.168.150.3:2377
```

Now, let's add the second manager by running the following command in the machine 192.168.150.12:

```bash
docker swarm join \
--token SWMTKN-1-60102dvjqhjdvnkmvn6jzmuzz0s44pilkvmlkmldycdej1psv9-dw0lci5ps266iarbl7dib7561 \
192.168.150.3:2377
```

The output of the command will be **This node joined a swarm as a manager.**

**NOTE: In actual production conditions, it's recommended to have at least 3 manager nodes. Docker people recommend to have bewteen 3 to 7 managers in a cluster.**


## Adding the workers:

Now, it's time to add the two worker machines to the swarm cluster. On each of the worker machines (192.168.150.16 and 192.168.150.22) run the following command:

```bash
docker swarm join \
--token SWMTKN-1-60102dvjqhjdvnkmvn6jzmuzz0s44pilkvmlkmldycdej1psv9-enq4jearscuseob8gor5105cq \
192.168.150.3:2377
```

The output of the command should be: **"This node joined a swarm as a worker."**

Now, in any of the two manager nodes (192.168.150.3 or 192.168.150.12) you can see the nodes in your cluster by running the command **docker node ls**:

```bash
docker node ls
ID                           HOSTNAME                                STATUS  AVAILABILITY  MANAGER STATUS
8dvvw01bnqr6dr2idqtinfx31    server-22.virtualstack2.gatuvelus.home  Ready   Active
alubanzad32ra75wa1zwtiadw    server-12.virtualstack2.gatuvelus.home  Ready   Active        Reachable
cca1qryxm4lhyf7a6qywxsjoi *  server-3.virtualstack2.gatuvelus.home   Ready   Active        Leader
euwvqoed07gik6506kaof5y84    server-16.virtualstack2.gatuvelus.home  Ready   Active
```

**An important note here:** The managers will also run your services. They are not limited to manager-only tasks. They also run container services too.


## Deploying replicated services:

For starter, let's deploy a single, non-replicated service into our swarm using the following command in any of the managers (192.168.150.3 or 192.168.150.12):

```bash
docker service create \
--replicas 1 \
--name mariadb-service-01 \
-e MYSQL_ROOT_PASSWORD="P@ssw0rd" \
-p 3306:3306 \
mariadb:10.1
```

The last command will create our service with only one replica in our swarm. Note something here: The exposed port (3306) will be available in all our nodes. No matter where is running our docker container, the service will be available across all nodes (managers or workers) in our cluster.

You can see the service state with the command "docker service ls" (in the managers):

```bash
docker service ls
ID            NAME                REPLICAS  IMAGE         COMMAND
4bm6x2e9h94v  mariadb-service-01  1/1       mariadb:10.1
```

And, if you want to inspect the service (this will reveal where the service is running it's container tasks), use **"docker service ps SERVICE_ID_OR_NAME"**:

```bash
docker service ps mariadb-service-01
ID                         NAME                  IMAGE         NODE                                    DESIRED STATE  CURRENT STATE               ERROR
62julw4m4mlgz1kxbohu0sx88  mariadb-service-01.1  mariadb:10.1  server-12.virtualstack2.gatuvelus.home  Running        Running about a minute ago
```

If for some case the node where the service is running goes down, the "swarm" will re-schedulle the service on another node. In order to see this in action, we stopped the node where the service is running, then issued on one of the managers the "docker service ps mariadb-service-01" again. Look the results:

```bash
docker service ps mariadb-service-01
ID                         NAME                      IMAGE         NODE                                    DESIRED STATE  CURRENT STATE                ERROR
9hei5m7m5ydzxxwa78qhshrgw  mariadb-service-01.1      mariadb:10.1  server-22.virtualstack2.gatuvelus.home  Running        Running about a minute ago
62julw4m4mlgz1kxbohu0sx88   \_ mariadb-service-01.1  mariadb:10.1  server-12.virtualstack2.gatuvelus.home  Shutdown       Complete about a minute ago
```

The swarm re-schedulled our service into another node, and, it's showing the old task as "shutdown" in the former node. Note something here. The former server (server-12, 192.168.150.12 in our LAB) was a manager. The new one (server-22, 192.168.150.22) is a worker. Services are schedulled across your nodes, no matter if they are managers or workers.

**WARNING: If you don't use shared storage, and your service is running a database, this operation will result in the original data being lost. With database services, always use shared storage for the data files inside the container. Later, we'll show how to perform this task.**

Now, let's do something different with a replicated service using 3 replicas (we started again our stopped node before creating the following service):

```bash
docker service create \
--replicas 3 \
--name apache-service-01 \
-p 80:80 \
httpd:2.4-alpine
```

Let's see our service list:

```bash
docker service ls
ID            NAME                REPLICAS  IMAGE             COMMAND
4bm6x2e9h94v  mariadb-service-01  1/1       mariadb:10.1
ce98r4zqkdva  apache-service-01   3/3       httpd:2.4-alpine
```

And, our service "ps":

```bash
docker service ps apache-service-01
ID                         NAME                 IMAGE             NODE                                    DESIRED STATE  CURRENT STATE               ERROR
8dkux93gwtp5yhe2or69v0je7  apache-service-01.1  httpd:2.4-alpine  server-3.virtualstack2.gatuvelus.home   Running        Running about a minute ago
27y7yx2twhrzlj76n5herfu1s  apache-service-01.2  httpd:2.4-alpine  server-16.virtualstack2.gatuvelus.home  Running        Running about a minute ago
8ftzufsmd1koh9svn5rpw790y  apache-service-01.3  httpd:2.4-alpine  server-12.virtualstack2.gatuvelus.home  Running        Running about a minute ago
```

Let's stop the "server-16" node (shutdown linux command) and see what happens:

```bash
docker service ps apache-service-01
ID                         NAME                     IMAGE             NODE                                    DESIRED STATE  CURRENT STATE               ERROR
8dkux93gwtp5yhe2or69v0je7  apache-service-01.1      httpd:2.4-alpine  server-3.virtualstack2.gatuvelus.home   Running        Running 5 minutes ago
6y8frkjhkkylsxbqiqw5towuv  apache-service-01.2      httpd:2.4-alpine  server-12.virtualstack2.gatuvelus.home  Running        Running about a minute ago
27y7yx2twhrzlj76n5herfu1s   \_ apache-service-01.2  httpd:2.4-alpine  server-16.virtualstack2.gatuvelus.home  Shutdown       Running 4 minutes ago
8ftzufsmd1koh9svn5rpw790y  apache-service-01.3      httpd:2.4-alpine  server-12.virtualstack2.gatuvelus.home  Running        Running 5 minutes ago
```

Docker swarm schedulled an additional replica in server-12. Then, server-12 (192.168.150.12, our second manager) it's running two replicas of our apache service.


**OPERATIONAL NOTE HERE:** Think ahead of possible internet access problems. Pre-provision the images you plan to use on all your nodes. For our specific case we executed the following commands in all our four nodes before launching our services:

```bash
docker pull mariadb:10.1
docker pull httpd:2.4-alpine
```

Doing so, if a docker node fails, the re-schedulling of the containers will be faster.

Removing our services is easy to do. Just use "docker service rm SERVICE_NAME_OR_ID":

```bash
docker service rm apache-service-01
docker service rm mariadb-service-01
```


## Adding shared storage to the mix:

For the following example, we'll deploy a nginx service that will use a NFS shared storage for its default webpage. First, let's pull our base image (nginx:1.12) in all our four nodes using the following command:

```bash
docker pull nginx:1.12
```

We have a NFS server exposing the following share: 192.168.1.1:/data/docker-nfs

We'll include our NFS shared storage in our **CoreOS** machines. For this to work properly in CoreOS, we need to create a "mount" system file on "/etc/systemd/system/" directory. Again, do the following steps on all the CoreOS servers. Create the file:

```bash
vi /etc/systemd/system/mnt-dockernfs.mount
```

Containing:

```bash
[Unit]
Description = NFS Mount 01

[Mount]
What=192.168.1.1:/data/docker-nfs
Where=/mnt/dockernfs
Type=nfs
Options=rw,hard,intr,timeo=90,bg,vers=3,proto=tcp,rsize=32768,wsize=32768

[Install]
WantedBy = multi-user.target
``` 

Then, enable and activate the mount with the following command:

```bash
systemctl enable --now /etc/systemd/system/mnt-dockernfs.mount
```

Now, you should have the filesystem mounted on all servers.

Inside the share, we have a directory "nginx-01" with an html file "index.html" containing the string "HELLO NGINX USERS":

```bash
cat /mnt/dockernfs/nginx-01/index.html
HELLO NGINX USERS
```

Let's create then a NGINX service which uses the NFS mounted directory to access it's "index.html" file. Do this task on one of your managers (192.168.150.3 or 12):


```bash
docker service create \
--replicas 2 \
--name nginx-nfs-service-01 \
--mount \
type=bind,\
src=/mnt/dockernfs/nginx-01,\
dst=/usr/share/nginx/html,\
ro \
-p 80:80 \
nginx:1.12
```

And, let's test it with curl against all our nodes:

```bash
server-3 / # curl http://192.168.150.3
HELLO NGINX USERS
server-3 / # curl http://192.168.150.12
HELLO NGINX USERS
server-3 / # curl http://192.168.150.16
HELLO NGINX USERS
server-3 / # curl http://192.168.150.22
HELLO NGINX USERS
server-3 / #
```

Now, let's apply the same principle to make a MariaDB service which data can survive when the node goes down. Remember our previous warning about database containers losing their data after a re-schedulle ?. This basicaly solves that problem:

```bash
mkdir -p /mnt/dockernfs/mariadb-service-01/config
mkdir -p /mnt/dockernfs/mariadb-service-01/data

echo "[mysqld]" > /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "max_connections=100" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "max_allowed_packet=1024M" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "thread_cache_size=128" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "sort_buffer_size=4M" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "bulk_insert_buffer_size=16M" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "max_heap_table_size=32M" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf
echo "tmp_table_size=32M" >> /mnt/dockernfs/mariadb-service-01/config/server.cnf

docker service create \
--replicas 1 \
--name mariadb-nfs-service-01 \
--mount \
type=bind,\
src=/mnt/dockernfs/mariadb-service-01/config,\
dst=/etc/mysql/conf.d \
--mount \
type=bind,\
src=/mnt/dockernfs/mariadb-service-01/data,\
dst=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD="P@ssw0rd" \
-p 3306:3306 \
mariadb:10.1
```

That last mariadb service will have it's data directory (/var/lib/mysql) inside the container, mapped to the directory "/mnt/dockernfs/mariadb-service-01/data", which resides on the NFS shared storage. Also we did the same for the server configuration, that points inside the container to "/etc/mysql/conf.d", and it is mapped to "/mnt/dockernfs/mariadb-service-01/config", which is also residing on the NFS shared storage.

With "docker service ps mariadb-nfs-service-01" we can see where is running the actual task for the service (the docker container):

```bash
docker service ps mariadb-nfs-service-01
ID                         NAME                      IMAGE         NODE                                   DESIRED STATE  CURRENT STATE               ERROR
1va73fbnoe3bftk0nob9z6ykw  mariadb-nfs-service-01.1  mariadb:10.1  server-3.virtualstack2.gatuvelus.home  Running        Running about a minute ago
```

Now, let's connect to the database engine from a remote machine, and then create a database:

```bash
mysql -h 192.168.150.22 -u root -p"P@ssw0rd" -e "CREATE DATABASE DockerDB;"

mysql -h 192.168.150.22 -u root -p"P@ssw0rd" -e "show databases;"
+--------------------+
| Database           |
+--------------------+
| DockerDB           |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
```

The database "DockerDB" was successfully created. Let's stop the server "server-3" (192.168.150.3) where the mariadb container is actually running.

Because the server we stopped was the first manager, let's enter to the other one (192.168.150.12) and see the status of our mariadb service:

```bash
docker service ps mariadb-nfs-service-01
ID                         NAME                          IMAGE         NODE                                    DESIRED STATE  CURRENT STATE                ERROR
1ulfranmj11ygb1exb7rukl0w  mariadb-nfs-service-01.1      mariadb:10.1  server-16.virtualstack2.gatuvelus.home  Running        Running about a minute ago 
1va73fbnoe3bftk0nob9z6ykw   \_ mariadb-nfs-service-01.1  mariadb:10.1  server-3.virtualstack2.gatuvelus.home   Shutdown       Shutdown about a minute ago
```

Our new container is on server-16 (192.168.150.16). Let's see if our database is still there:

```bash
 mysql -h 192.168.150.22 -u root -p"P@ssw0rd" -e "show databases;"
+--------------------+
| Database           |
+--------------------+
| DockerDB           |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
```

Our service is alive with its database originaly created using the former container-task running on server-3 (192.168.150.3), now working on a container-task running on server-16 (192.168.150.16).


## Promoting a worker to manager:

Our current setup is made of two managers and two workers, but we should have a minimun of three managers. This is easy to do by promoting one of the workers to manager. Lets promote the server 102.168.150.16 to manager with the command "docker node promote NODENAME". Run this command on any of the managers:

```bash
docker node ls
ID                           HOSTNAME                                STATUS  AVAILABILITY  MANAGER STATUS
8dvvw01bnqr6dr2idqtinfx31    server-22.virtualstack2.gatuvelus.home  Ready   Active
alubanzad32ra75wa1zwtiadw    server-12.virtualstack2.gatuvelus.home  Ready   Active        Leader
cca1qryxm4lhyf7a6qywxsjoi *  server-3.virtualstack2.gatuvelus.home   Ready   Active        Reachable
euwvqoed07gik6506kaof5y84    server-16.virtualstack2.gatuvelus.home  Ready   Active

docker node promote server-16.virtualstack2.gatuvelus.home
Node server-16.virtualstack2.gatuvelus.home promoted to a manager in the swarm.

docker node ls
ID                           HOSTNAME                                STATUS  AVAILABILITY  MANAGER STATUS
8dvvw01bnqr6dr2idqtinfx31    server-22.virtualstack2.gatuvelus.home  Ready   Active
alubanzad32ra75wa1zwtiadw    server-12.virtualstack2.gatuvelus.home  Ready   Active        Leader
cca1qryxm4lhyf7a6qywxsjoi *  server-3.virtualstack2.gatuvelus.home   Ready   Active        Reachable
euwvqoed07gik6506kaof5y84    server-16.virtualstack2.gatuvelus.home  Ready   Active        Reachable
```

Now, our cluster contains three managers and one worker.

**NOTE: We can also demote a manager to worker with the command "docker node demote NODENAME".**


## Global services:

A service can be configured to be replicated in all the nodes in the cluster, by using "--mode global" in its "service create" command. Let's launch a global service for apache, running on port 8080:

```bash
docker service create \
--mode global \
--name apache-global-service-01 \
-p 8080:80 \
httpd:2.4-alpine
```

Using the "docker service ps" command will show the service running containers-tasks in all our nodes:

```bash
docker service ps apache-global-service-01
ID                         NAME                          IMAGE             NODE                                    DESIRED STATE  CURRENT STATE               ERROR
0s8etz1e9d8u89vgllw42rggk  apache-global-service-01      httpd:2.4-alpine  server-22.virtualstack2.gatuvelus.home  Running        Running about a minute ago
1d6indthgtvqswdrv0azhos5k   \_ apache-global-service-01  httpd:2.4-alpine  server-16.virtualstack2.gatuvelus.home  Running        Running about a minute ago
efia6lygag449ncoe2yoni679   \_ apache-global-service-01  httpd:2.4-alpine  server-3.virtualstack2.gatuvelus.home   Running        Running 4 minutes ago  
3sw31p6ji91rh68bsy3acbotx   \_ apache-global-service-01  httpd:2.4-alpine  server-12.virtualstack2.gatuvelus.home  Running        Running 4 minutes ago
```


## Scaling-UP replicated services:

One of the services we have running is a two-replica service:

```bash
docker service ls
ID            NAME                      REPLICAS  IMAGE             COMMAND
45c3qwbgrn92  apache-global-service-01  global    httpd:2.4-alpine
8oyq0bx2ty61  mariadb-nfs-service-01    1/1       mariadb:10.1
a0mrgp3kiik1  nginx-nfs-service-01      2/2       nginx:1.12
```

We can chance the replica factor by using the "scale" option of the "docker service" command. Let's add two more replicas to the nginx-nfs-service-01 service:

```bash
docker service scale nginx-nfs-service-01=4

nginx-nfs-service-01 scaled to 4
```

Now see:

```bash
docker service ls
ID            NAME                      REPLICAS  IMAGE             COMMAND
45c3qwbgrn92  apache-global-service-01  global    httpd:2.4-alpine
8oyq0bx2ty61  mariadb-nfs-service-01    1/1       mariadb:10.1
a0mrgp3kiik1  nginx-nfs-service-01      4/4       nginx:1.12
```

We can scale-down the service too. Let's remove a replica from the service

```bash
docker service scale nginx-nfs-service-01=3

nginx-nfs-service-01 scaled to 3

docker service ls
ID            NAME                      REPLICAS  IMAGE             COMMAND
45c3qwbgrn92  apache-global-service-01  global    httpd:2.4-alpine
8oyq0bx2ty61  mariadb-nfs-service-01    1/1       mariadb:10.1
a0mrgp3kiik1  nginx-nfs-service-01      3/3       nginx:1.12
```

**NOTE: This can work for services sharing read-only data, but if you try to do this with the mariadb service running in the cluster, you'll probably end with database files corruption in the shared NFS storage.**


## Recommendations for Load Balancing.

For any service running in a swarm cluster and exposing a port, the port is opened on all nodes no matter if the node have a container task or not. All nodes answers to connections made to the exposed service port. That means in a practical point of view that a load balancer can be put in front of our nodes in order to distribute the traffic, and ensure service high-availability using a single VIP on the LB.

Note that, also the managers can be load balanced. You can expose the "docker" service running in the managers in order to enable remote access. When doing this, please try to use ALWAYS TLS if you are inside a production environment. For this lab, and in order to make things simpler, we'll forget about TLS.

What we are going to do, is to enable the docker TCP API port (2375) on CoreOS.

Create the following file in all your managers:

```bash
vi /etc/systemd/system/docker-tcp.socket
```

Containing:

```bash
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=2375
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
```

Save the file and run the following commands

```bash
systemctl enable docker-tcp.socket
systemctl stop docker
systemctl start docker-tcp.socket
systemctl start docker
```

Next step is to create a load balancer which VIP uses port 2375, and connects to all 3 servers.

Because our LAB is running inside an OpenStack cloud, we created a LBaaS with the VIP: 192.168.150.27, port 2375 and the pool using our 3 managers. From a remote machine with docker, then we can connect to the "SWARM VIP":

```bash
docker --host=tcp://192.168.150.27:2375 service ls
ID            NAME                      REPLICAS  IMAGE             COMMAND
45c3qwbgrn92  apache-global-service-01  global    httpd:2.4-alpine
8oyq0bx2ty61  mariadb-nfs-service-01    1/1       mariadb:10.1
a0mrgp3kiik1  nginx-nfs-service-01      3/3       nginx:1.12
```

Please, again, DO NOT do this without using TLS on a production environment. Also, restrict which specific machines can connect remotely to the docker API port. If you over-expose your service, you'll end hacked !.

END.-

