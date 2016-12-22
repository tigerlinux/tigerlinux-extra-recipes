# JUJU TUTORIAL - CANONICAL'S APT ON THE CLOUD ! - PART 2

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction. From tutorial part 1 to tutorial part 2:

The first part of our juju tutorials (available [here](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/misc/juju-tut-part1)) explored the very basics of Juju using manual clouds and lxd. This time, we'll extend our environment to OpenStack. 

In this part-two juju tutorial, we'll implement juju in order to control deployments in a Mitaka-based OpenStack private cloud.


## Our Environment:

For our tutorial, we created one juju workstation in VirtualBox, installed using my unattended seeds in the following url:

- [Unattended installations templates for Centos, Debian and Ubuntu.](http://tigerlinux.github.io/recipes/linux/unattended/index.html)

This machine is a Ubuntu-1404lts 64 bits based workstation, and we'll use it as our "juju workstation" for the juju deployments environment. IP: 192.168.56.68.

About our cloud: Mitaka based, installed on Ubuntu 1404lts 64 bits too, fully provisioned (tenants, images, networks, etc.). Keystone endpoint: http://192.168.1.4:5000/v3. The cloud was installed using my unattended/semi-automated installers for mitaka-ubuntu, available in the following url:

- [Unattended/semi-automated installer for OpenStack MITAKA on Ubuntu 14.04lts.](https://github.com/tigerlinux/openstack-mitaka-installer-ubuntu1404lts)

For our OpenStack cloud access, we'll use the following information:

- OpenStack Keystone Endpoint: http://192.168.1.4:5000/v3
- OpenStack Project/Tenant: admin
- OpenStack user: admin
- OpenStack region: casitalab01
- OpenStack user password: P@ssw0rd
- OpenStack default domain: default
- OpenStack flavor to use: m2.normal (customized, with ram=1024M, cpu=2 cores, root-disk=60GB)
- OpenStack network: external-01 (external flat, with dhcp. No fips needed)
- Extra flavors:  m1.large (ram=2048M, cpu=1 cores, root-disk=32GB) and m1.small (ram=512M, cpu=1 cores, root-disk=32GB)


## Basic secure ssh environment for JUJU (A little SysAdmin task..):

First task on a SysAdmin list of tasks is ensure the environment is updated and secured. We'll apply basic survival rules here. For all our juju interactions, we'll create an account with sudo access in the juju workstation 192.168.56.68 using the following command (as root):

```bash
useradd -c "Juju Account" -d /home/juju -m -s /bin/bash juju
echo 'Defaults:juju !requiretty' > /etc/sudoers.d/juju
echo 'juju ALL=(ALL)       NOPASSWD:ALL' >> /etc/sudoers.d/juju
chmod 0440 /etc/sudoers.d/juju
echo "juju:P@ssw0rd"|chpasswd
```

Then, just ssh or "su" to the "juju" account. From this point all our admin tasks will be done from the juju account in the juju workstation.


## JUJU installation on the JUJU control workstation:

In our juju control workstation 192.168.56.68 (juju account), install juju using the following commands:

```bash
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y ppa:juju/proposed
sudo apt-get -y update
sudo apt-get -y install juju-2.0
```

**NOTE: At the moment of writing this tutorial (early November 2016), juju-2 packages for Ubuntu 14.04 are missing from the "stable" branch, but are available on "proposed" and "devel" branches of the PPA. If you go for the "stable" branch, only juju 1.x is available for Ubuntu 14.04. For Ubuntu 16.04lts, juju-2 is fully available on the stable branch of the PPA.**


## OpenStack client environment and image setup:

Ok, first, we need to create some files and install some packages in our JUJU control workstation because we are going to need openstack access from the workstation too. First the packages, specifically the openstack and swift clients:

```bash
sudo apt-get update
sudo apt-get -y install python-software-properties
sudo apt-get -y install ubuntu-cloud-keyring
sudo add-apt-repository -y cloud-archive:mitaka
sudo apt-get -y update && apt-get -y dist-upgrade
sudo apt-get -y install python-openstackclient python-swiftclient
```

Now, let's create our OpenStack credentials file:

```bash
vi ~/keystonerc_admin
```

Containing our credentials and environment:

```bash
export OS_USERNAME=admin
export OS_PASSWORD=P@ssw0rd
export OS_TENANT_NAME=admin
export OS_PROJECT_NAME=admin
export OS_AUTH_URL=http://192.168.1.4:5000/v3
export OS_VOLUME_API_VERSION=2
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_AUTH_VERSION=3
PS1='[\u@\h \W(keystone_admin)]$ '
```

**NOTE: My openstack automated installer already create this file in the /root account on the openstack nodes. Just copy it to the juju server if you don't want to create a new file. Please note: You are NOT FORCED to use the admin account. Use any account that can create instances and with enough quota for the instances you'll need.**

Now, let's source our credentials file and do a simple test:

```bash
source ~/keystonerc_admin
openstack compute service list -c Id -c Binary

+----+------------------+
| Id | Binary           |
+----+------------------+
|  1 | nova-consoleauth |
|  2 | nova-cert        |
|  3 | nova-scheduler   |
|  4 | nova-conductor   |
|  5 | nova-console     |
| 10 | nova-compute     |
+----+------------------+
```

If the `openstack compute service list -c Id -c Binary` command returns our complete list of "nova" services, then your credentials are OK. Otherwise, you'll have to double check your credentials (our your openstack server).

Now, and assuming you don't have an already loaded glance image for Ubuntu 14.04lts, let's download the image, and add it to glance. Note that we need the "cloudimage" here (not any other kind of image):

```bash
wget https://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img

openstack image create "Ubuntu-1404lts-64-CloudImage-for-JUJU" \
--disk-format qcow2 \
--public \
--container-format bare \
--project $OS_PROJECT_NAME \
--file ~/ubuntu-14.04-server-cloudimg-amd64-disk1.img
```

After our image is loaded, obtain it's ID (we'll use it later):

```bash
openstack image show Ubuntu-1404lts-64-CloudImage-for-JUJU -c id -f value

dd2c10b7-92a8-4b86-ad0d-ee4bb95a5094
```

Our image id is: "dd2c10b7-92a8-4b86-ad0d-ee4bb95a5094", but, we always can obtain the id by running the command `openstack image show Ubuntu-1404lts-64-CloudImage-for-JUJU -c id -f value`.

Now, let's create some files we are going to need with juju. First, our cloud environment file:

```bash
vi ~/my-private-oscloud01.yaml
```

Containing:

```bash
clouds:
   oscloud01:
      type: openstack
      auth-types: [userpass]
      regions:
         casitalab01:
            endpoint: http://192.168.1.4:5000/v3
```

Second, the credentials file:

```bash
vi ~/my-private-oscloud01-creds.yaml
```

Containing:

```bash
credentials:
  oscloud01:
    default-region: casitalab01
    admin:
       domain-name: default
       auth-type: userpass
       password: P@ssw0rd
       tenant-name: admin
       username: admin
```

With our two files ready, let's add them to Juju:

```bash
juju add-cloud oscloud01 ~/my-private-oscloud01.yaml
juju add-credential oscloud01 -f ~/my-private-oscloud01-creds.yaml
```

List your cloud and credentials:

```bash
[juju@server-68 ~(keystone_admin)]$ juju show-cloud oscloud01

defined: local
type: openstack
description: Openstack Cloud
auth-types: [userpass]
regions:
  casitalab01:
    endpoint: http://192.168.1.4:5000/v3
	
[juju@server-68 ~(keystone_admin)]$ juju list-credentials

Cloud      Credentials
oscloud01  admin

[juju@server-68 ~(keystone_admin)]$
```

If you want to see the "password", use the command: `juju list-credentials --format yaml --show-secrets`.

Finally, let's set our default credential for the openstack cloud:

```bash
juju set-default-credential oscloud01 admin

Default credential for oscloud01 set to "admin".
```

**NOTE: You can have multiple credentials for your clouds in Juju.**


## Juju OpenStack Private Cloud bootstrap:

With base environment ready, let's proceed to bootstrap our cloud. Remember all actions will be performed on our juju control workstation using the juju account. First, let's create the following directory:

```bash
mkdir -p ~/simplestreams/images
```

Source our openstack environment file:

```bash
source ~/keystonerc_admin
```

Remember our OpenStack access info (from the beginning of this tutorial):

- OpenStack Keystone Endpoint: http://192.168.1.4:5000/v3 (but v2.0 is also available)
- OpenStack Project/Tenant: admin
- OpenStack user: admin
- OpenStack region: casitalab01
- OpenStack user password: P@ssw0rd
- OpenStack default domain: default
- OpenStack flavor to use: m2.normal (customized, with ram=1024M, cpu=2 cores, root-disk=60GB)
- OpenStack network: external-01 (external flat, with dhcp. No fips needed)
- Extra flavor:  m1.large (ram=2048M, cpu=1 cores, root-disk=32GB) and m1.small (ram=512M, cpu=1 cores, root-disk=32GB)

Now, let's create our simplestreams definition for the previously created glance image (ubuntu trusty) and set our metadata. Note that in the "-i" parameter, we are obtaining the UUID of the ubuntu glance image that we loaded before:

```bash
juju metadata generate-image \
-d ~/simplestreams \
-i `openstack image show Ubuntu-1404lts-64-CloudImage-for-JUJU -c id -f value` \
-s trusty \
-r casitalab01 \
-a amd64 \
-u http://192.168.1.4:5000/v3

juju metadata generate-tools -d ~/simplestreams
```

Finally, let's bootstrap our cloud:

```bash
juju bootstrap oscloud01/casitalab01 oscontroller01 \
--bootstrap-series "trusty" \
--constraints "instance-type=m2.normal" \
--metadata-source ~/simplestreams \
--config network=external-01 \
--config use-floating-ip=false \
--config use-default-secgroup=false \
-v
```

**NOTES:**
- The "constraints" with "instance-type=m2.normal" ensures our bootstrap machine will use a specific openstack flavor (m2.normal for our installation).
- The extra config options forces to use a specific network (external-01 for our installation), disable the use of floating IP's, and enable juju to create it's own security groups.
- The metadata-source indicates the information about our glance image (the one we downloaded and added to glance) in the "~/simplestreams" directory. All deployed machines in our cloud will use this image as source.
- Our cloud is based on trusty series (--bootstrap-series "trusty").

The command will take some time to complete all actions. When ready, you can check your controller:

```bash
juju list-controllers --refresh

Controller       Model    User   Access     Cloud/Region           Models  Machines    HA  Version
oscontroller01*  default  admin  superuser  oscloud01/casitalab01       2         1  none  2.0.1.1
```

Also, you can see your machine created in openstack. This is your controller instance, based on the flavor choosen in the "constraints" option:

```bash
openstack server list

+--------------------------------------+--------------------------+--------+---------------------------+
| ID                                   | Name                     | Status | Networks                  |
+--------------------------------------+--------------------------+--------+---------------------------+
| a117dc7b-dd0c-4170-814d-5c00fe98742a | juju-aa6fde-controller-0 | ACTIVE | external-01=192.168.1.229 |
+--------------------------------------+--------------------------+--------+---------------------------+
```

You can ssh to your controller from the juju environment by using the command `juju ssh -m controller 0`:

```bash
[juju@server-68 ~(keystone_admin)]$ juju ssh -m controller 0

Welcome to Ubuntu 14.04.5 LTS (GNU/Linux 3.13.0-100-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

  System information as of Tue Nov  8 11:43:39 UTC 2016

  System load:  1.08              Processes:           84
  Usage of /:   1.2% of 62.96GB   Users logged in:     0
  Memory usage: 5%                IP address for eth0: 192.168.1.229
  Swap usage:   0%

  Graph this data and manage this system at:
    https://landscape.canonical.com/

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.

New release '16.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

```

This concludes our controller bootstrap section. In the next section, we'll proceed to add deployment machines to our cloud.


## Adding deployment machines:

With our controller ready, our remaining taks is to add machines. We can do this with the "juju add-machine" command. We can also add constraints like "instance-type=m2.normal". Let's add two machines, one with m2.normal OpenStack flavor, and another more with m1.large OpenStack flavor:

First, the two "m2.normal" machines:

```bash
juju add-machine \
--constraints "instance-type=m2.normal" \
--series "trusty"

juju add-machine \
--constraints "instance-type=m1.large" \
--series "trusty"
```

**NOTES AND IMPORTANT TIPS TO CONSIDER:** 

- If for some reason any of your machines fail to start (timeouts, or any other failure including openstack failures) remove it with "juju remove-machine MACHINE-ID".
- If "juju remove-machine" is unable to destroy the machine on OpenStack, use the command "openstack server list" to see your instance (and the one(s) that failed), then "openstack server delete UUID" (with the UUID of the failed machine), finally, call the command "juju remove-machine MACHINE-ID --force".
- After you clear the "mess" and solve whatever went wrong, try again to add your machine(s).


After a little while, you can check the status of your machines both on OpenStack (using `openstack server list`) and in JUJU (using `juju status`):

```bash
[juju@server-68 ~(keystone_admin)]$ openstack server list

+--------------------------------------+--------------------------+--------+---------------------------+
| ID                                   | Name                     | Status | Networks                  |
+--------------------------------------+--------------------------+--------+---------------------------+
| a4a55cb0-638f-4fc6-b30b-15757722ec55 | juju-38732f-default-1    | ACTIVE | external-01=192.168.1.231 |
| b49b19ca-3adc-41f4-837d-4786af3c3465 | juju-38732f-default-0    | ACTIVE | external-01=192.168.1.230 |
| a117dc7b-dd0c-4170-814d-5c00fe98742a | juju-aa6fde-controller-0 | ACTIVE | external-01=192.168.1.229 |
+--------------------------------------+--------------------------+--------+---------------------------+



[juju@server-68 ~(keystone_admin)]$ juju status

Model    Controller      Cloud/Region           Version
default  oscontroller01  oscloud01/casitalab01  2.0.1.1

App  Version  Status  Scale  Charm  Store  Rev  OS  Notes

Unit  Workload  Agent  Machine  Public address  Ports  Message

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.230  b49b19ca-3adc-41f4-837d-4786af3c3465  trusty  nova
1        started  192.168.1.231  a4a55cb0-638f-4fc6-b30b-15757722ec55  trusty  nova

```

You can see your deployment machines (in this tutorial, ID's 0 and 1), and, ssh to them with the following commands:

```bash
juju ssh -m default 0
juju ssh -m default 1
```


## Let's deploy some applications on the cloud.


Now, we'll deploy our first applications. In "openstack" clouds, we need to add the placement, that is, in which machine the application will be located. Let's deploy a wordpress solution (which includes mysql) in machine "0" - the first one - (remember: All commands must be launched in the juju control workstation 192.168.56.68, inside the juju account):

```bash
juju deploy mysql --to 0
juju deploy wordpress --to 0
juju add-relation wordpress mysql 
juju expose wordpress
```

The "juju deploy" command create on machine "0" our mysql and wordpress apps. The "add-relation" command create a working relationship between wordpress and juju, efectively creating the wordpress database on the mysql app, and enabling wordpress to use this database.

With the command `juju status` we can see how the statuses of our components (mysql and wordpress) change until eventually they say "idle":

```bash
juju status

Model    Controller      Cloud/Region           Version
default  oscontroller01  oscloud01/casitalab01  2.0.1.1

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql               unknown      1  mysql      jujucharms   55  ubuntu
wordpress           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit          Workload  Agent  Machine  Public address  Ports     Message
mysql/0*      unknown   idle   0        192.168.1.230   3306/tcp
wordpress/0*  unknown   idle   0        192.168.1.230   80/tcp

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.230  b49b19ca-3adc-41f4-837d-4786af3c3465  trusty  nova
1        started  192.168.1.231  a4a55cb0-638f-4fc6-b30b-15757722ec55  trusty  nova

Relation      Provides   Consumes   Type
cluster       mysql      mysql      peer
db            mysql      wordpress  regular
loadbalancer  wordpress  wordpress  peer

```

Now, let's extend this a little more. We already have a wordpress server in our machine with ID=0 (IP: 192.168.1.230). Let's add another wordpress "unit", but to machine with ID=1 (IP: 192.168.1.231):

```bash
juju add-unit wordpress --to 1
```

After a little while (it depends of how fast is your cloud), you'll see both units working:

```bash
juju status

Model    Controller      Cloud/Region           Version
default  oscontroller01  oscloud01/casitalab01  2.0.1.1

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql               unknown      1  mysql      jujucharms   55  ubuntu
wordpress           unknown      2  wordpress  jujucharms    4  ubuntu  exposed

Unit          Workload  Agent  Machine  Public address  Ports     Message
mysql/0*      unknown   idle   0        192.168.1.230   3306/tcp
wordpress/0*  unknown   idle   0        192.168.1.230   80/tcp
wordpress/1   unknown   idle   1        192.168.1.231   80/tcp

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.230  b49b19ca-3adc-41f4-837d-4786af3c3465  trusty  nova
1        started  192.168.1.231  a4a55cb0-638f-4fc6-b30b-15757722ec55  trusty  nova

Relation      Provides   Consumes   Type
cluster       mysql      mysql      peer
db            mysql      wordpress  regular
loadbalancer  wordpress  wordpress  peer
```

Because "wordpress" application is already "related" to mysql, and it's already "exposed" too, all units scaling out from the same application will inherit both the relation with mysql and will be exposed as well.

With both machines exposing wordpress, you can include any LBaaS from OpenStack in order to loadbalance you application !


## Adding High Availability to the mix.

If you lose your controller machine, you'll be unable to do anything with the cloud using JUJU, so, let's add some redundancy here. This is acomplished with the "enable-ha" sub-command. Let's do-it for our cloud:

```bash
juju enable-ha -n 3 --constraints "instance-type=m2.normal"
```

Explanation:

- **enable-ha**: It enable the redundancy at controller level.
- **-n 3**: -n followed with a number indicates the redundancy level. For our tutorial, "-n 3" means we'll have two aditional nodes. Please note: This number MUST BE an odd number from 3 to 7.
- **--constraints "instance-type=m1.normal"**: As with our other deployments, we'll indicate here the instance type (OpenStack flavor) that will be used for the HA nodes. As a general recomendation, try that your controllers are the same size.

You can check the status of the controller specific machines in the "controller" model using the command `juju status -m controller`:

```bash
juju status -m controller

Model       Controller      Cloud/Region           Version
controller  oscontroller01  oscloud01/casitalab01  2.0.1.1

App  Version  Status  Scale  Charm  Store  Rev  OS  Notes

Unit  Workload  Agent  Machine  Public address  Ports  Message

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.229  a117dc7b-dd0c-4170-814d-5c00fe98742a  trusty  nova
1        started  192.168.1.232  688410e4-cfb2-40fc-ae24-f9d68fc7f83a  trusty  nova
2        started  192.168.1.233  7d9ea203-62b3-418e-b31d-dc01efdc3ec7  trusty  nova
```

Initially, your new machines will be on "pending" until the provisioning process finish and the "Started" state is reached.

With "openstack server list" you can see your instances:

```bash
openstack server list

+--------------------------------------+--------------------------+--------+---------------------------+
| ID                                   | Name                     | Status | Networks                  |
+--------------------------------------+--------------------------+--------+---------------------------+
| 7d9ea203-62b3-418e-b31d-dc01efdc3ec7 | juju-aa6fde-controller-2 | ACTIVE | external-01=192.168.1.233 |
| 688410e4-cfb2-40fc-ae24-f9d68fc7f83a | juju-aa6fde-controller-1 | ACTIVE | external-01=192.168.1.232 |
| a4a55cb0-638f-4fc6-b30b-15757722ec55 | juju-38732f-default-1    | ACTIVE | external-01=192.168.1.231 |
| b49b19ca-3adc-41f4-837d-4786af3c3465 | juju-38732f-default-0    | ACTIVE | external-01=192.168.1.230 |
| a117dc7b-dd0c-4170-814d-5c00fe98742a | juju-aa6fde-controller-0 | ACTIVE | external-01=192.168.1.229 |
+--------------------------------------+--------------------------+--------+---------------------------+
```

In conclusion, your JUJU OpenStack based cloud will have 5 machines: 2 Machines in the "default" model (`juju list-machines -m default`) for application deployment, and 3 machines in the "controller" model for controller high-availability (juju list-machines -m controller):

```bash
[juju@server-68 ~(keystone_admin)]$ juju list-machines -m default

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.230  b49b19ca-3adc-41f4-837d-4786af3c3465  trusty  nova
1        started  192.168.1.231  a4a55cb0-638f-4fc6-b30b-15757722ec55  trusty  nova


[juju@server-68 ~(keystone_admin)]$ juju list-machines -m controller

Machine  State    DNS            Inst id                               Series  AZ
0        started  192.168.1.229  a117dc7b-dd0c-4170-814d-5c00fe98742a  trusty  nova
1        started  192.168.1.232  688410e4-cfb2-40fc-ae24-f9d68fc7f83a  trusty  nova
2        started  192.168.1.233  7d9ea203-62b3-418e-b31d-dc01efdc3ec7  trusty  nova
``` 


## Adding LXD to our OpenStack based cloud:

We can extend our cloud by enabling lxd-based containers on the instances. In order to acomplish this, we must install lxd on our deployment machines. First, from the "juju" user in the "juju" 192.168.56.68 workstation, ssh to both machines using the command `juju ssh -m default MACHINE-ID` ("juju ssh -m default 0" and "juju ssh -m default 1"), then run the following commands on each machine:

```bash
sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install lxd lxd-client lxd-tools
sudo usermod -a -G lxd ubuntu
newgrp lxd
sudo lxd init
sudo lxc network set lxdbr0 ipv6.address none
exit
exit
```

The "sudo lxd init" command will ask some questions. Set all with the defaults (take into account this is a LAB not a production environment). The command `sudo lxc network set lxdbr0 ipv6.address none` is just to forcibly disable IPv6 support in lxd, as juju does not support it yet.

That's it. Our two deployment machines are lxd-enabled !!. Now, let's do a deployment, but, calling lxd on machine ID=1:

```bash
juju deploy mysql mysql01-in-lxd --to lxd:1
juju deploy wordpress wordpress01-in-lxd --to lxd:1
juju add-relation wordpress01-in-lxd mysql01-in-lxd
juju expose wordpress01-in-lxd
```

What are the diferences now ?:

- Using "lxd:1" means "lxd on machine 1". This will be deployed on machine 1 (IP:192.168.1.231), but into a "lxd" container.
- Because is using a container, the machine will be located on the lxd bridged network, not in the main server interface.
- With "expose", the actual port of the container running the app will get opened, but, because it's a container app into a bridged network with no routes from the external network arquitecture, it only will be reachable from the machine where the container is located (this case, from 192.168.1.231).

**NOTE: Because juju with lxd needs to download the image, in our case the trusty image, the machines will take some time to get ready, all of course depending on your Internet bandwidth**

When the provisioning is done, we can see our new applications deployed in the lxd-based containers, specifically for this lab: 1/lxd/0 and 1/lxd/1:

```bash
juju@server-64:~$ juju status

Model    Controller      Cloud/Region           Version
default  oscontroller01  oscloud01/casitalab01  2.0.1.1

App                 Version  Status   Scale  Charm      Store       Rev  OS      Notes
mysql                        unknown      1  mysql      jujucharms   55  ubuntu
mysql01-in-lxd               unknown      1  mysql      jujucharms   55  ubuntu
wordpress                    unknown      2  wordpress  jujucharms    4  ubuntu  exposed
wordpress01-in-lxd           unknown      1  wordpress  jujucharms    4  ubuntu  exposed

Unit                   Workload  Agent  Machine  Public address  Ports     Message
mysql01-in-lxd/0*      unknown   idle   1/lxd/0  10.103.129.196  3306/tcp
mysql/0*               unknown   idle   0        192.168.1.230   3306/tcp
wordpress01-in-lxd/0*  unknown   idle   1/lxd/1  10.103.129.76   80/tcp
wordpress/0*           unknown   idle   0        192.168.1.230   80/tcp
wordpress/1            unknown   idle   1        192.168.1.231   80/tcp

Machine  State    DNS             Inst id                               Series  AZ
0        started  192.168.1.230   b49b19ca-3adc-41f4-837d-4786af3c3465  trusty  nova
1        started  192.168.1.231   a4a55cb0-638f-4fc6-b30b-15757722ec55  trusty  nova
1/lxd/0  started  10.103.129.196  juju-38732f-1-lxd-0                   trusty
1/lxd/1  started  10.103.129.76   juju-38732f-1-lxd-1                   trusty

Relation      Provides            Consumes            Type
cluster       mysql               mysql               peer
db            mysql               wordpress           regular
cluster       mysql01-in-lxd      mysql01-in-lxd      peer
db            mysql01-in-lxd      wordpress01-in-lxd  regular
loadbalancer  wordpress           wordpress           peer
loadbalancer  wordpress01-in-lxd  wordpress01-in-lxd  peer
```

Note something here: The container-based applications are restricted to the node where the container machine is running. In practical terms that means: the applications on the containers will only be reachable from inside the machine running the container. If you want to allow the container-based applications to be reacheable from the outside, add IPTABLES rules. Because this was already explained on our first JUJU tutorial, please refer to the following link for more information about how to allow the containers to be reacheable by using IPTABLES:

- [Juju tutorial part 1 - LXD Containers section.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/misc/juju-tut-part1#extending-our-cloud-more-adding-lxd-to-the-scene)


## Some extra notes.

You can deploy applications without specifying an already-created machine. See the following command:

```bash
juju deploy mysql mysql02 --constraints "instance-type=m1.small"
```

The last command will instruct OpenStack to create a new instance with the specified flavor (m1.small). Later, if you want, you can deploy other applications on the same machine (this will be machine ID=3):

```bash
juju deploy wordpress wordpress02 --to 3
juju add-relation wordpress02 mysql02
juju expose wordpress02
```

Here it ends our second JUJU tutorial. There's many other things to cover, but, that will be material for part 3.

END.-
