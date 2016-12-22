# JUJU TUTORIAL - CANONICAL'S APT ON THE CLOUD ! - PART 1

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction. A tale of the IT genesis, or, going from the bare metal to the modern clouds:

A tale of the genesis... I.T. versioned !.

- "In the first day of the technological creation, IT goods created the baremetal server. They gave the server an Operating System with seas of ram, lands of hard disk space, winds of devices, and a sun of cpu cycles giving life to everything... then the gods observed their creation and all was good... for a time."
- "In the second day of the technological creation, IT goods created the monolithic applications. Those applications spawned trough all the garden of O/S edens using resources in disordered ways... and for a little time, it was good as there was plenty of resources to use and abuse.."
- "In the third day of the technological creation, IT goods created the SYSADMIN, with the sole role of take care of the applications and the garden of O/S edens, and keep them from wasting their environments... but the SYSADMIN detected a flaw on the original IT goods monolithic design, and decided to work with their gods to find a solution... The virtualization was born, and again, for a time it was OK for all ... Just for a little while.."
- "In the fourth day of the technological creation, IT goods and SYSADMINs decided that the virtualization needed more control... they needed orquestration and elasticity.. then... with a light that blinded all non-prepared SysAdmins and changed all prehistorical IT concepts... the modern cloud was born."
- "In the fifth day of the technological creation, concepts like DevOps, SysOps, Cloudformation, Infrastructure as Code, and other cloud-infrastructure automation paradigms begun to rise from the very heart of IT heavens (and IT Hells too) crowding the minds and souls of all beings in the creation.. but there was more to come and there's no rest for the wicked ..."

More to come ?. We are just beginning here !. Technology keep going on and advancing... and getting more complex each day. Automation tools like "puppet", "ansible", "chef" have exceed themselves from their original desing, providing the capability to administer and orquestrate clouds like AWS, Azure, GCE and OpenStack based clouds with the same ease as they administer applications. Basically, those tools provide ways to automate the orquestration !.

Following this new paradigm where the orquestration need to be automated, Canonical introduced a tool, which they call ["JUJU"](https://www.ubuntu.com/cloud/juju), and serves as a way to deploy from simple to very complex application scenarios in a cloud oriented way.

But... what's the main working unit or "recipe" in JUJU ?... Let's do a basic comparision here:

- Puppet: They call their recipes "Manifests".
- Ansible: They call their recipes "Playbooks".
- Chef: They call their recipes... guess ??.. "Recipes".
- JUJU: Well... we are in the black-magic IT world now... As you probably inferred: "CHARMS".

So, the basic recipe which describes an application in "JUJU" is called a "Charm". The charm, in it's pure technological form, is an structure with scripts and a some yaml files. This structure not only defines actions used to install, uninstall, start, stop, and in general manage the distinct aspects of an application, but also sets possible actions used to relate the application to others applications installed also trough JUJU. 

By example: We can deploy a single individual mysql service trough a juju charm called "mysql". Then, we can add another charm for wordpress and another one for mediawiki... now... we can "relate" both the mediawiki and the wordpress to the mysql, and, "like an act of black magic" the databases needed for both app charms will be created by the mysql's charm. Moreover, we can scale out the wordpress app including more "units" which spawns to other machines in the cloud.

Well.. is not black magic or any kind of magic at all. Is just years and years of "SysAdmin concepts" and "smart scripting" applied in the form of "hooks" that intercepts specific actions defined in the "JUJU" repertory of possible actions, and finally produce a result: A deployed application that can be related to others, and scaled in a "cloud" way.

"JUJU" can manage many cloud types... Azure, GCE, RackSpace, OpenStack private Clouds, "MAAS" (another concept from the IT lands: Metal as a Service), and ultimately: MANUAL clouds.

This tutorial will, for the sake of simplicity, use a MANUAL cloud... but... what in heavens is a manual cloud ?. A manual cloud is a bunch of individual servers, with no cloud related software managing their resources, that can be also be disparate from each other in terms of hardware (and software too). So, the manual cloud is used to create a cloud where is none existent, and deploy applications through all the servers in the cloud.

We'll cover from installation trough basic application deploying here. For the moment, we'll not enter into charm construction or other clouds like AWS or OpenStack. Those will be topics for part's 2 and/or 3 of our juju tutorial series.


## Our Environment:

For our tutorial, we created four servers in VirtualBox. Those were installed using my unattended seeds in the following url:

- [Unattended installations templates for Centos, Debian and Ubuntu](http://tigerlinux.github.io/recipes/linux/unattended/index.html)

But, you can use whatever servers you have at hand, even mixing baremetals and virtualized. That's the beauty on "Manual" clouds JUJU's concept. Our only recomendation is: Use (for this tutorial) Ubuntu 14.04 LTS 64 bits. This whole tutorial is based on Ubuntu 14.04lts.

Servers for "manual cloud": Four Ubuntu 14.04lts 64 bits (virtualized on VirtualBox, but can be any kind of disparate hardware, baremetal or virtualized). IP's 192.168.56.64, 65, 66 and 67 - fully updated. Our controller will be the 192.168.56.64 machine, and the deploying machines will be 192.168.56.65, 66 and 67.


## First baby steps: Basic secure ssh environment for JUJU (A little SysAdmin task..)

First task on a SysAdmin list of tasks is ensure the environment is updated and secured. We'll apply basic survival rules here. For all our juju interactions, we'll create an account with sudo access and ssh keys alowing non-interactive ssh between nodes.

We'll create an account "juju" with sudo permissions using the following command (from the root account). All our deployments will be performed from the juju account. Run the following command as root in all four servers:

```bash
useradd -c "Juju Account" -d /home/juju -m -s /bin/bash juju
echo 'Defaults:juju !requiretty' > /etc/sudoers.d/juju
echo 'juju ALL=(ALL)       NOPASSWD:ALL' >> /etc/sudoers.d/juju
chmod 0440 /etc/sudoers.d/juju
echo "juju:juju"|chpasswd

```

**NOTE: Don't freak out !!!. The "juju" password is temporary. We'll discard it as soon as we copy our secure key.**

In the first server (192.168.56.64) let's enter to "juju" account with "su - juju", then create a key and ssh config that we'll copy to the other accounts in the other three servers:

```bash
su - juju
mkdir ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo 'Host *' > ~/.ssh/config
echo 'StrictHostKeyChecking no' >> ~/.ssh/config
echo 'UserKnownHostsFile=/dev/null' >> ~/.ssh/config
chmod 600 ~/.ssh/config

```

From there (still in juju account in the first server), we'll copy the ssh-id to the other servers, and to itself with the following commands:

```bash
ssh-copy-id juju@192.168.56.64
ssh-copy-id juju@192.168.56.65
ssh-copy-id juju@192.168.56.66
ssh-copy-id juju@192.168.56.67
```

Then, (again, still from juju account) copy the reminder files from the first server to the other two:

```bash
scp ~/.ssh/id_rsa* ~/.ssh/config juju@192.168.56.65:~/.ssh/
scp ~/.ssh/id_rsa* ~/.ssh/config juju@192.168.56.66:~/.ssh/
scp ~/.ssh/id_rsa* ~/.ssh/config juju@192.168.56.67:~/.ssh/
```

Finally, from the first server, let's get rid of the juju password:

```bash
ssh 192.168.56.64 "sudo passwd -l juju"
ssh 192.168.56.65 "sudo passwd -l juju"
ssh 192.168.56.66 "sudo passwd -l juju"
ssh 192.168.56.67 "sudo passwd -l juju"
```

So, what we did here ?. We basically created a secure environment for juju, with ssh trust relantionships between all four servers. This is very similar to what is needed in OpenStack for the NOVA account in order to allow migrations and resizes in multi-node environments.


## Child steps: JUJU installation on the servers and "manual" cloud bootstraping.

Ok... Our SSH environment is ready, so, let's begin installing JUJU. From now on, we'll do all tasks using the "juju" account we created in all four servers.

First task is to install juju with the following commands inside the juju account. This needs to be don in all four servers:

```bash
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y ppa:juju/proposed
sudo apt-get -y update
sudo apt-get -y install juju-2.0

```

**NOTE: At the moment of writing this tutorial (late october 2016), juju-2 packages for Ubuntu 14.04 are missing from the "stable" branch, but are available on "proposed" and "devel" branches of the PPA. If you go for the "stable" branch, only juju 1.x is available for Ubuntu 14.04. For Ubuntu 16.04lts, juju-2 is fully available on the stable branch of the PPA.**

After the installation is done, we can start/bootstrap our "manual" cloud. In the first server (192.168.56.64) run the following command:

```bash
juju bootstrap manual/192.168.56.64 cloud-manual-01
```

The last command will create our cloud, named "cloud-manual-01", and assign the server 192.168.56.64 as our first machine.

The output from the last command:

```bash
Since Juju 2 is being run for the first time, downloading latest cloud information.
Fetching latest public cloud list...
Updated your list of public clouds with 1 cloud region added:

    added cloud region:
        - aws/us-east-2
Creating Juju controller "cloud-manual-01" on manual
Looking for packaged Juju agent version 2.0.0 for amd64
Fetching Juju GUI 2.2.1
Warning: Permanently added '192.168.56.64' (ECDSA) to the list of known hosts.
Logging to /var/log/cloud-init-output.log on the bootstrap machine
Running apt-get update
Running apt-get upgrade
Installing curl, cpu-checker, bridge-utils, cloud-utils, tmux
Fetching Juju agent version 2.0.0 for amd64
Installing Juju machine agent
Starting Juju machine agent (service jujud-machine-0)
Bootstrap agent now started
Contacting Juju controller at 192.168.56.64 to verify accessibility...
Bootstrap complete, "cloud-manual-01" controller now available.
Controller machines are in the "controller" model.
Initial model "default" added.
```

You can see the status of your cloud and controllers with the commands:

```bash
juju list-controllers --refresh
juju status
```

Now, let's add the other two machines to our cloud. This is also done from the first machine, who is our controller too (192.168.56.64):

```bash
juju add-machine ssh:juju@192.168.56.65
juju add-machine ssh:juju@192.168.56.66
juju add-machine ssh:juju@192.168.56.67
```

Now, run the command `juju list-controllers --refresh` in the controller:

```bash
juju list-controllers --refresh

Controller        Model    User   Access     Cloud/Region  Models  Machines    HA  Version
cloud-manual-01*  default  admin  superuser  manual             2         3  none  2.0.0
```

We have four machines: the one running the controller (that is dedicated for controller and its dependencies) and three more for application deployments !. We can see our deployment machines with the command "juju machines":

```bash
juju machines

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

```


## Teenager steps now: Our very first applications deployed with JUJU.


Now, we'll deploy our first applications. In "manual" clouds, we need to add the placement, that is, in which machine the application will be located. Let's deploy a wordpress solution (which includes mysel) in machine "1" - the second one - (those commands need to be performed in the controller 192.168.56.64):

```bash
juju deploy mysql --to 1
juju deploy wordpress --to 1
juju add-relation wordpress mysql 
juju expose wordpress
```

The "juju deploy" command create on machine "1" our mysql and wordpress apps. The "add-relation" command create a working relationship between wodpress and juju, efectively creating the wordpress database on the mysql app, and enabling wordpress to use this database.

With the command `juju status` we can see how the statuses of our components (mysql and wordpress) change until eventually they say "idle":

```bash
juju status
Model    Controller       Cloud/Region  Version
default  cloud-manual-01  manual        2.0.0

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql               unknown      1  mysql      jujucharms   55  ubuntu
wordpress           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit          Workload  Agent      Machine  Public address  Ports     Message
mysql/0*      unknown   idle       1        192.168.56.66   3306/tcp
wordpress/0*  unknown   idle       1        192.168.56.66   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides   Consumes   Type
cluster       mysql      mysql      peer
db            mysql      wordpress  regular
loadbalancer  wordpress  wordpress  peer

```

This is the moment where our first application is ready to go !. Also, we can see the public IP of our deployment. We can go to our wordpress site using the URL: http://192.168.56.66/

Let's deploy another application. This time, a wikipedia on the machine "0" - the first machine - (192.168.56.65). Again, this need to be performed in the controller (192.168.56.64). Note that, because we already have a mysql server deployed on machine "1", we can use it for the mediawiki app too, so, our mysql will have two databases, one for the wordpress app, and another for the mediawiki. We'll just reuse our current mysql server. Note also we are installing memcached too and relating to the mediawiki app:

```bash
juju deploy cs:trusty/memcached --to 0
juju deploy cs:trusty/mediawiki --to 0
juju add-relation mysql mediawiki:db
juju add-relation memcached mediawiki
juju expose mediawiki
```

What we did here ?:

- The "cs:trusty/" prefix ensures we install the charm versioned for trusty. This is necesary in charms which supports multiple versions.
- Because we already have a mysql working, we need to just add the relation between our new mediawiki deployment and the already existing unit for mysql.
- We really don't need to use "expose" here, due the fact that this is not running inside a LXD containers, but a bare-metal machine and operating system. When using LXD, we need to use "expose" for applications that we want to "expose" to the network. Otherwise, they'll be not reachable.

See our status now:

```bash
juju status
Model    Controller       Cloud/Region  Version
default  cloud-manual-01  manual        2.0.0

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
mediawiki           unknown      1  mediawiki  jujucharms    5  ubuntu  exposed
memcached           unknown      1  memcached  jujucharms   15  ubuntu
mysql               unknown      1  mysql      jujucharms   55  ubuntu
wordpress           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit          Workload  Agent  Machine  Public address  Ports      Message
mediawiki/0*  unknown   idle   0        192.168.56.65   80/tcp
memcached/0*  unknown   idle   0        192.168.56.65   11211/tcp
mysql/0*      unknown   idle   1        192.168.56.66   3306/tcp
wordpress/0*  unknown   idle   1        192.168.56.66   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides   Consumes   Type
cache         mediawiki  memcached  regular
db            mediawiki  mysql      regular
cluster       memcached  memcached  peer
cluster       mysql      mysql      peer
db            mysql      wordpress  regular
loadbalancer  wordpress  wordpress  peer


```

We have a common mysql unit in the 192.168.56.66 server, with databases for the mediawiki in .65 server and the wordpress in the .66 server. Black magic anyone ???...


## Clustered services - A mariadb master/slave deployment.

Now, lets extend this. We are going to add another deployment a mariadb server, and we'll add a name to the deployment. Because we already have a server with port 3306 on machine 1, we'll use machine "0". Also, we'll introduce the concept of charm config.

First, create the file.

```bash
vi ~/mariadb-master.yaml
```

Containing:

```bash
mariadb-master:
  series: "5.5"
```

And deploy with:

```bash
juju deploy cs:trusty/mariadb --config ~/mariadb-master.yaml mariadb-master --to 0
juju expose mariadb-master
```

This basically instructs the charm to use a configuration which, for this case, says "use mariadb series 5.5".

Note some things here:

- The actual name into the yaml file must be the same we use for the application. Our application name is "mariadb-master", so the settings in the yaml file must be started with the same name.

And see our machine list and juju status. Remember all commands are being issued from the controller:

```bash
juju@server-64:~$ juju machines
Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

juju@server-64:~$ juju status
Model    Controller       Cloud/Region  Version
default  cloud-manual-01  manual        2.0.0

App             Version  Status   Scale  Charm      Store       Rev  OS      Notes
mariadb-master  5.5.53   active       1  mariadb    jujucharms    6  ubuntu  exposed
mediawiki                unknown      1  mediawiki  jujucharms    5  ubuntu  exposed
memcached                unknown      1  memcached  jujucharms   15  ubuntu
mysql                    unknown      1  mysql      jujucharms   55  ubuntu
wordpress                unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit               Workload  Agent  Machine  Public address  Ports      Message
mariadb-master/0*  active    idle   0        192.168.56.65              ready
mediawiki/0*       unknown   idle   0        192.168.56.65   80/tcp
memcached/0*       unknown   idle   0        192.168.56.65   11211/tcp
mysql/0*           unknown   idle   1        192.168.56.66   3306/tcp
wordpress/0*       unknown   idle   1        192.168.56.66   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides        Consumes        Type
cluster       mariadb-master  mariadb-master  peer
cache         mediawiki       memcached       regular
db            mediawiki       mysql           regular
cluster       memcached       memcached       peer
cluster       mysql           mysql           peer
db            mysql           wordpress       regular
loadbalancer  wordpress       wordpress       peer

juju@server-64:~$

```

OK... now.. remember our mariadb server which we called "mariadb-master" ?.. Let's add a slave to it:

First, let's create it's config file:

```bash
vi ~/mariadb-slave.yaml
```

Containing:

```bash
mariadb-slave:
  series: "5.5"
```

Deploy to the new machine with:

```bash
juju deploy cs:trusty/mariadb --config ~/mariadb-slave.yaml mariadb-slave --to 2
juju expose mariadb-slave
```

**NOTE: If for some reason the slave fails to install correctly (set itself on error), proceed to manually install on the 192.168.56.67 node the following python dependencies:**

```bash
sudo apt-get install python-yaml python-setuptools python-requests-whl \
python-apt python-debian python-apt-common python-chardet \
python-chardet-whl python-cheetah python-pip python-cheetah
```

**NOTE: Probably you are asking to yourself... how did I knew that some python dependencies where missing in the .67 node ?.. is TigerLinux using some kind of Black Magic too ??. Totally not. Just I observed the mariadb app log in /var/log/juju. The error was very specific about a missing module name in a charm file. Then just compared the installed python packages between node 64, where the mariadb-master is, and node 67, where mariadb-slave is. That's all. Nothing is perfect on the IT world.** 

After you see that the status of both the master and slave are OK, set the master/slave relation:

```bash
juju add-relation mariadb-master:master mariadb-slave:slave
```

Your status will end as:

```bash
Model    Controller       Cloud/Region  Version
default  cloud-manual-01  manual        2.0.0

App             Version  Status   Scale  Charm      Store       Rev  OS      Notes
mariadb-master  5.5.53   active       1  mariadb    jujucharms    6  ubuntu  exposed
mariadb-slave   5.5.53   active       1  mariadb    jujucharms    6  ubuntu  exposed
mediawiki                unknown      1  mediawiki  jujucharms    5  ubuntu  exposed
memcached                unknown      1  memcached  jujucharms   15  ubuntu
mysql                    unknown      1  mysql      jujucharms   55  ubuntu
wordpress                unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit               Workload  Agent  Machine  Public address  Ports      Message
mariadb-master/0*  active    idle   0        192.168.56.65              ready
mariadb-slave/0*   active    idle   2        192.168.56.67              ready
mediawiki/0*       unknown   idle   0        192.168.56.65   80/tcp
memcached/0*       unknown   idle   0        192.168.56.65   11211/tcp
mysql/0*           unknown   idle   1        192.168.56.66   3306/tcp
wordpress/0*       unknown   idle   1        192.168.56.66   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides        Consumes        Type
cluster       mariadb-master  mariadb-master  peer
slave         mariadb-master  mariadb-slave   regular
cluster       mariadb-slave   mariadb-slave   peer
cache         mediawiki       memcached       regular
db            mediawiki       mysql           regular
cluster       memcached       memcached       peer
cluster       mysql           mysql           peer
db            mysql           wordpress       regular
loadbalancer  wordpress       wordpress       peer
```

SSH to our mariadb main server from your controller using juju:

```bash
juju ssh mariadb-master/0
```

From there, you can enter to mariadb and create a database:

```bash
mysql -u root -p$(sudo cat /var/lib/mysql/mysql.passwd)

MariaDB [(none)]> create database JUJUTEST;
Query OK, 1 row affected (0.02 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| JUJUTEST           |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.00 sec)

MariaDB [(none)]> exit
Bye
ubuntu@server-65:~$

```

Exit the ssh with `exit`.

Now, ssh with juju to the slave:

```bash
juju ssh mariadb-slave/0
```

Enter to mariadb and list the databases:

```bash
mysql -u root -p$(sudo cat /var/lib/mysql/mysql.passwd)


MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| JUJUTEST           |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.00 sec)

MariaDB [(none)]> exit

```

Our database is in the slave, so our cluster is up and running !.

**AN IMPORTANT NOTE OF WARNING: Don't mix in the same machine conflicting applications. By example: If you use the same machine for both apache and nginx, you'll end with one of them failing due the fact that both will try to use port TCP 80. In the last exercise, I installed mariadb on the machine "3". If I try to add a wordpress unit in the same machine, one of the charm requirements will try to install some mysql libraries which enter in a direct conflict with the mariadb installed libs. This will render your deployment unusable and you'll have a lot of problems and a sad day trying to recover. Consider yourself advised !.**


## Extending our cloud more. Adding LXD to the scene.

Let's reset our machines and restart the LAB completely from scratch. We'll set all things related to the ssh/juju accounts again and reinstall juju-repos and juju, but, before creating again our manual cloud, we'll include LXD by running the following commands in all the four servers:

```bash
sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install lxd lxd-client lxd-tools
sudo usermod -a -G lxd juju
newgrp lxd
sudo lxd init
sudo lxc network set lxdbr0 ipv6.address none
```

The "sudo lxd init" command will ask some questions. Set all with the defaults (take into account this is a LAB not a production environment). The command `sudo lxc network set lxdbr0 ipv6.address none` is just to forcibly disable IPv6 support in lxd, as juju does not support it yet.

Now, we can create again our cloud:

```bash
juju bootstrap manual/192.168.56.64 cloud-manual-with-lxd-01
```

And add the machines again:

```bash
juju add-machine ssh:juju@192.168.56.65
juju add-machine ssh:juju@192.168.56.66
juju add-machine ssh:juju@192.168.56.67
```

Now, let's do a deployment, but, calling lxd:

```bash
juju deploy mysql --to lxd:1
juju deploy wordpress --to lxd:1
juju add-relation wordpress mysql 
juju expose wordpress
```

What are the diferences now ?:

- Using "lxd:1" means "lxd on machine 1". This will be deployed on machine 192.168.56.66, but into a "lxd" container.
- Because is using a container, the machine will be located on the lxd bridged network, not in the main server interface.
- Now "expose" really works. With "expose", the actual port of the container running the app will get opened, but, because it's a container app into a bridged network with no routes from the external network arquitecture, it only will be reachable from the machine where the container is located (this case, from 192.168.56.66).

**NOTE: Because juju with lxd needs to download the image, in our case the trusty image, the machines will take some time to get ready, depending on your Internet bandwidth**

When everything finish to get provisioned, we can see our deployments and machines:

```bash
juju@server-64:~$ juju status
Model    Controller                Cloud/Region  Version
default  cloud-manual-with-lxd-01  manual        2.0.0

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql               unknown      1  mysql      jujucharms   55  ubuntu
wordpress           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit          Workload  Agent  Machine  Public address  Ports     Message
mysql/0*      unknown   idle   1/lxd/0  10.59.246.193   3306/tcp
wordpress/0*  unknown   idle   1/lxd/1  10.59.246.198   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
1/lxd/0  started  10.59.246.193  juju-a1589f-1-lxd-0   trusty
1/lxd/1  started  10.59.246.198  juju-a1589f-1-lxd-1   trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides   Consumes   Type
cluster       mysql      mysql      peer
db            mysql      wordpress  regular
loadbalancer  wordpress  wordpress  peer

juju@server-64:~$ juju machines
Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
1/lxd/0  started  10.59.246.193  juju-a1589f-1-lxd-0   trusty
1/lxd/1  started  10.59.246.198  juju-a1589f-1-lxd-1   trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

juju@server-64:~$

```

From the machine "192.168.56.66" we can ping and use "lynx" in order to check the worpress app: 

```bash
ping 10.59.246.198
lynx http://10.59.246.198
```

If you want to allow access to the container from your public network, just run the following commands:

```bash
sudo iptables -t nat -I PREROUTING -p tcp -d 192.168.56.66/32 --dport 80 -j DNAT --to 10.59.246.198:80
sudo iptables -A FORWARD -p tcp -i eth0 -d 10.59.246.198 --dport 80 -j ACCEPT
sudo sed -r -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
```

Now, you can enter your containerized application trough: http://192.168.56.66

This will do a port forward from the machine external IP (192.168.56.66), port 80, to the internal container IP and port via "destination nat". The "net.ipv4.ip_forward=1" line need to be enabled on sysctl.conf in order to let the communication to flow between eth0 and the lxd bridge.

If you want to get rid of this config just run:

```bash
sudo iptables -t nat -D PREROUTING -p tcp -d 192.168.56.66/32 --dport 80 -j DNAT --to 10.59.246.198:80
sudo iptables -D FORWARD -p tcp -i eth0 -d 10.59.246.198 --dport 80 -j ACCEPT
sudo sed -r -i 's/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
```

Note that we can have a second wordpress install in the same server. Look how to do it, and expose it using another port:

```bash
juju deploy mysql --to lxd:1 mysql2
juju deploy wordpress --to lxd:1 wordpress2
juju add-relation wordpress2 mysql2
juju expose wordpress2
```

Our status again:

```bash
juju status

Model    Controller                Cloud/Region  Version
default  cloud-manual-with-lxd-01  manual        2.0.0

App         Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql                unknown      1  mysql      jujucharms   55  ubuntu
mysql2               unknown      1  mysql      jujucharms   55  ubuntu
wordpress            unknown      1  wordpress  jujucharms    4  ubuntu  exposed
wordpress2           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit           Workload  Agent  Machine  Public address  Ports     Message
mysql2/0*      unknown   idle   1/lxd/2  10.59.246.219   3306/tcp
mysql/0*       unknown   idle   1/lxd/0  10.59.246.193   3306/tcp
wordpress2/0*  unknown   idle   1/lxd/3  10.59.246.226   80/tcp
wordpress/0*   unknown   idle   1/lxd/1  10.59.246.198   80/tcp

Machine  State    DNS            Inst id               Series  AZ
0        started  192.168.56.65  manual:192.168.56.65  trusty
1        started  192.168.56.66  manual:192.168.56.66  trusty
1/lxd/0  started  10.59.246.193  juju-a1589f-1-lxd-0   trusty
1/lxd/1  started  10.59.246.198  juju-a1589f-1-lxd-1   trusty
1/lxd/2  started  10.59.246.219  juju-a1589f-1-lxd-2   trusty
1/lxd/3  started  10.59.246.226  juju-a1589f-1-lxd-3   trusty
2        started  192.168.56.67  manual:192.168.56.67  trusty

Relation      Provides    Consumes    Type
cluster       mysql       mysql       peer
db            mysql       wordpress   regular
cluster       mysql2      mysql2      peer
db            mysql2      wordpress2  regular
loadbalancer  wordpress   wordpress   peer
loadbalancer  wordpress2  wordpress2  peer

```

OK.. we have two different wordpress apps in the same server, but running in different containers... can we access from outside the second wordpress ?. Of course we can. Just we need to add another IPTABLES rules here, using a different external port.. let's say: 8080. Our second wordpress is on container IP: 10.59.246.226

```
sudo iptables -t nat -I PREROUTING -p tcp -d 192.168.56.66/32 --dport 8080 -j DNAT --to 10.59.246.226:80
sudo iptables -A FORWARD -p tcp -i eth0 -d 10.59.246.226 --dport 80 -j ACCEPT
```

Now, you can enter to your secondary wordpress using: http://192.168.56.66:8080/


## Final part: Adding a GUI to the mix.

JUJU comes with a GUI that you can access by first running some commands from the controller. First, use the following command in your controller:

```bash
juju gui --show-credentials
```

The answer will be something like:

```bash
Opening the Juju GUI in your browser.
If it does not open, open this URL:
https://192.168.56.64:17070/gui/0ba02881-ae3b-4953-81f7-5fa77da1589f/
Username: admin
Password: b1926ff7c0857dd47198b2d0bb4d3df6

```

With a browser, use the provided URL, username and password.

There, you can model your existing applications, export, import, and create new apps.

Note that you can use the following command to "infere" what's the URL of your default model in the controller:

```bash
juju show-controller --show-password
```

The relevant data is at the end:

```bash
    default:
      uuid: 0ba02881-ae3b-4953-81f7-5fa77da1589f
      machine-count: 7
      core-count: 3
  current-model: admin/default
  account:
    user: admin
    access: superuser
    password: b1926ff7c0857dd47198b2d0bb4d3df6
```

With the IP of the controller, port 17070, and the default model uuid you can construct the URL: http://192.168.56.64:17070/gui/0ba02881-ae3b-4953-81f7-5fa77da1589f. The user and password are there too.

Here it ends our first JUJU tutorial. There's many other things to cover, but, that will be material for part 2, and posible part 3 of the JUJU tutorial.

END.-
