# CHEF TUTORIAL - An infrastructure automation tool.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

If you like to automate things and use from simple shell scripts to more advanced solutions like Puppet, Ansible and Juju, you'll find usefull this short tutorial about [CHEF](https://www.chef.io/).

In this tutorial we'll cover from the very basic "chef" minimal infrastructure installation (server and workstation), to nodes integration with chef, cookbook and recipes administration and application, and some extra things usefull for your first steps into the chef world !.

Some basic concepts here first:

- CHEF Server: Main chef entity, where your infrastructure configuration will exist as a code.
- CHEF Workstation: Your main "command-line-based" (cli) start point. All "chef" administrative tasks will be performed from the chef workstation by using the "knife" and "chef" commands.
- Recipes: The main working unit on chef. A recipe is a set of actions that converges on a specific result (files creation, packages installation, services configuration and start-up, etc.).
- Cookbook: A set of recipes with specific attributes, files, templates, etc. You normally create cookbooks which also contains your recipes.
- Nodes: Your machines !. All recipes/cookbooks are applied to the machines in your infrastructure.


## Our LAB/Tutorial Environment:

- Server and Workstation: Centos 7 64 bits, fully updated. SELINUX and FirewallD disabled, [EPEL](https://fedoraproject.org/wiki/EPEL) repo installed on both machines. IPS: 192.168.56.71 for the server, and 192.168.56.72 for the workstation.
- Nodes: One Centos 7 (192.168.56.73 - SELINUX and Firewall Disabled - EPEL Repo Enabled) and One Ubuntu 14.04lts (192.168.56.74): Each machine has 2 cores and 4 GB's RAM, HD 60GB's, virtualized on VirtualBox.

**NOTE: We installed our machines using automated kickstart/preseed templates available here:**

- [Unattended installation templates for Centos, Debian and Ubuntu.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/linux/unattended)


## CHEF Server basic installation:

First task of the day: We are going to install our CHEF server. Run all commands on the server (for our LAB: 192.168.56.71) inside the root account. We need to get the package first (for our Centos 7 CHEF server):

```bash
mkdir /workdir
cd /workdir
wget https://packages.chef.io/stable/el/7/chef-server-core-12.9.1-1.el7.x86_64.rpm
```

**NOTE: Ensure you are working with the last stable version by checking the url: [https://downloads.chef.io/chef-server/redhat/](https://downloads.chef.io/chef-server/redhat/)**

After the package is downloaded, run the following commands in order to install chef server/services (note: Accept with "yes" when prompted for the "opscode-manage-ctl reconfigure", and "opscode-reporting-ctl reconfigure" commands):

```bash
cd /
rpm -ivh /workdir/chef-server-core-*.el7.x86_64.rpm
chef-server-ctl reconfigure
chef-server-ctl install chef-manage
opscode-manage-ctl reconfigure
chef-server-ctl reconfigure

chef-server-ctl install opscode-reporting
chef-server-ctl reconfigure
opscode-reporting-ctl reconfigure

chef-server-ctl install opscode-push-jobs-server
chef-server-ctl reconfigure
opscode-push-jobs-server-ctl reconfigure
```

Check your chef services status with the command `chef-server-ctl status`:

```bash
chef-server-ctl status

run: bookshelf: (pid 581) 0s; run: log: (pid 578) 0s
run: nginx: (pid 6761) 29s; run: log: (pid 598) 0s
run: oc_bifrost: (pid 587) 0s; run: log: (pid 586) 0s
run: oc_id: (pid 606) 0s; run: log: (pid 605) 0s
run: opscode-erchef: (pid 583) 0s; run: log: (pid 580) 0s
run: opscode-expander: (pid 596) 0s; run: log: (pid 595) 0s
run: opscode-pushy-server: (pid 6717) 30s; run: log: (pid 6760) 30s
run: opscode-reporting: (pid 610) 0s; run: log: (pid 609) 0s
run: opscode-solr4: (pid 589) 0s; run: log: (pid 588) 0s
run: postgresql: (pid 582) 0s; run: log: (pid 579) 0s
run: rabbitmq: (pid 591) 0s; run: log: (pid 590) 0s
run: redis_lb: (pid 6291) 49s; run: log: (pid 607) 0s

```

Create your admin user and first organization with the commands:

- chef-server-ctl user-create USER_NAME FIRST_NAME LAST_NAME EMAIL 'PASSWORD' --filename FILE_NAME
- chef-server-ctl org-create short_name 'full_organization_name' --association_user user_name --filename ORGANIZATION-validator.pem

For our LAB: 

```bash
mkdir /root/.chef
chmod 0700 /root/.chef
chef-server-ctl user-create admin TigerLinux SuperAdmin 'noname@nodomain.bogus' 'P@ssw0rd' --filename /root/.chef/admin.pem
chef-server-ctl org-create tigerlinuxorg 'TigerLinux Organization' --association_user admin --filename /root/.chef/tigerlinuxorg-validator.pem
``` 

Now, you can enter to your chef server gui with: https://192.168.56.71 using the already-created user/pass (admin/P@ssw0rd).


## CHEF Workstation basic installation:

Now, it's time to setup our chef workstation (192.168.1.72). All administration tasks will be performed from our Workstation. First, let's download and install the chef development kit by running (as root) the following commands:

```bash
mkdir /root/.chef
mkdir /root/chef-repo
chmod 0700 /root/.chef
cd /root/.chef
wget https://packages.chef.io/stable/el/7/chefdk-0.19.6-1.el7.x86_64.rpm
rpm -ivh chefdk-0.19.6-1.el7.x86_64.rpm
```

From the CHEF server (192.168.56.71), scp the keys (user and organization) to the workstation:

```bash
scp /root/.chef/*.pem 192.168.56.72:/root/.chef/
```

Now, again in the workstation (192.168.56.72), let's configure "knife" with the following commands:

```bash
knife configure \
--admin-client-name admin \
--admin-client-key /root/.chef/admin.pem \
--validation-client-name tigerlinuxorg-validator \
--validation-key /root/.chef/tigerlinuxorg-validator.pem \
--repository /root/chef-repo \
--server-url "https://server-71:443/organizations/tigerlinuxorg" \
--user admin

knife ssl fetch
knife ssl check
```

Please note that the URL must be the server hostname (in https) and with the /organizations/ORGANIZATION-NAME route. "ORGANIZATION-NAME" is the same name from the "chef-server-ctl org-create2 command.

Test the communication with the server using the following command:

```bash
knife client list

tigerlinuxorg-validator
```

Finally, let's create our complete repo structure:

```bash
cd /root/chef-repo/
mkdir roles cookbooks data_bags environments
```

That finish our "CHEF Workstation setup". From this point, we'll use the "knife" and "chef" commands in our chef workstation to do all our infrastructure administration tasks with chef.


## Bootstraping our nodes:

In "chef" terms, bootstraping a node means: "Include the node in chef server so chef can apply cookbooks/recipes to it". This action install and configure the chef-client, and, add the required permissions so the node can communicate with chef server.

Let's "bootstrap" our first node (the centos 7 one with IP 192.168.56.73). Use the following command (you need ssh access) from your chef workstation (192.168.56.72):

```bash
knife bootstrap 192.168.56.73 --ssh-user root --ssh-password "password" --node-name server-73
```

**NOTE: Our node "192.168.56.73" root user has password set to ... "password" (Don't use something so simple in actual production systems please !!).**

For the Ubuntu machine (192.168.56.74), we'll do something different. In the machine, we have already created an account with sudo using the following commands:

```bash
useradd -c "Chef Account" -s /bin/bash -m chef
echo "chef:P@ssw0rd"|chpasswd
echo 'Defaults:chef !requiretty' > /etc/sudoers.d/chef
echo 'chef ALL=(ALL)       NOPASSWD:ALL' >> /etc/sudoers.d/chef
chmod 0440 /etc/sudoers.d/chef
```

Then, from our chef workstation machine:

```bash
knife bootstrap 192.168.56.74 --ssh-user chef --ssh-password "P@ssw0rd" --sudo --node-name server-74
```

This basically shows that you are not forced to use "root" with ssh. Normally, in cloud-based environments, "root" is completelly disabled from SSH, and you normally have an account with sudo access to do your admin stuff.

**WARNING: If for some reason the command fails with the error " Failed to open TCP connection to server-71:443 (getaddrinfo: Name or service not known)", add the server to your /etc/hosts file with the following command in the bootstrapped nodes:**

```bash
echo "192.168.56.71 server-71" >> /etc/hosts
```

Then run again your bootstrap command.

**NOTE: If your search domain, and in general, if your DNS infrastructure is correctly configured (see your /etc/resolv.conf in your nodes too), you'll probably won't need to include your chef server in the /etc/hosts file. Then again, is a "fail-safe" measure if you don't trust your own DNS infra so it's OK if you want to include the /etc/hosts line. That's up to you !.**

After you successfully bootstraped your nodes, you can check again with the knife command and you should see your nodes there:

```bash
knife client list
 
server-73
server-74
tigerlinuxorg-validator

```

**OPTIONAL: Making the chef-client run periodically:**

If you want your chef-client to run periodically, use a crontab !. The following command creates the crontab. Use it directly in your nodes:

```bash
echo "*/15 * * * * root `which chef-client` -l warn | grep -v 'retrying [1234]/5 in'" > /etc/cron.d/chefclient
```

The last command will create the crontab that will run the chef client every 15 minutes on your nodes.


## Downloading cookbooks from "cookbook market" and using them in our nodes:

Thanks to the OpenSource and CHEF community, chef has a very complete and diverse cookbook library that you can use and adapt to your needs. Firts, see the complete list of available cookbooks in the following url:

- [Chef SuperMarket](https://supermarket.chef.io/)

Let's start with something simple. Let's download (in our chef workstation) a cookbook for basic apache2:

```bash
cd /root/chef-repo/cookbooks/
knife cookbook site download apache2
tar -xzvf apache2-*.tar.gz
rm -f apache2-*.tar.gz
```

Also, read the cookbook information on the web [https://supermarket.chef.io/cookbooks/apache2](https://supermarket.chef.io/cookbooks/apache2). As a general survival measure, please ALWAYS read the requirements and limitations for every external cookbook you pretend to use !.

Then, with the following command upload the cookbook to the chef server:

```bash
knife cookbook upload apache2
```

Now, list your available cookbooks in chef server:

```bash
knife cookbook list

apache2   3.2.2
```

You also can see your available recipes with the command `knife recipe list`. This will show you a lot of recipes just from the "apache2" cookbook. For our just uploaded "apache2" module, the base default recipe is "apache2", which in "chef" terms is "apache2::default" which will just install apache2 on the node. Let's add the reciple to one of our nodes:

First, let's list our nodes:

```bash
 knife node list
 
server-73
server-74
```

Then, apply the "apache2::default" recipe to one of the servers using the `knife node run_list NODE ITEM` command, where "node" is, obviouslly, your node, and ITEM is the recipe/recipes (or roles.. we'll see that later) you want to apply to the node:

```bash
knife node run_list add server-74 'apache2::default'

server-74:
  run_list: recipe[apache2::default]

```

In "server-74", you can just wait until the chef-client runs (remember our 15 minutes crontab ??), or, manually run chef-client there (as root or with sudo). For our LAB, we'll just wait and observe the log on server-74 to see what happens (tail -f /var/log/syslog on server-74 console.)

You can query all the node information using the command (with a "pipe" and less at the end)

```bash
knife node show -l server-74|less
```

The list will include everything, including the actual recipes in the server. If you just want to see the actual recipes in the server don't use "-l":

```bash
knife node show server-74

Node Name:   server-74
Environment: _default
FQDN:        server-74
IP:          10.0.2.15
Run List:    recipe[apache2::default]
Roles:
Recipes:     apache2::default, apache2::mpm_event, apache2::mod_status, apache2::mod_alias, apache2::mod_auth_basic, apache2::mod_authn_core, apache2::mod_authn_file, apache2::mod_authz_core, apache2::mod_authz_groupfile, apache2::mod_authz_host, apache2::mod_authz_user, apache2::mod_autoindex, apache2::mod_deflate, apache2::mod_dir, apache2::mod_env, apache2::mod_mime, apache2::mod_negotiation, apache2::mod_setenvif
Platform:    ubuntu 14.04
Tags:
``` 

**USE THE FORCE LUKE... Mean... the CHEF GUI: In the reports area of your chef Web GUI, you can see all your chef-client runs and their results, including failures, logs, everything. Don't forget that !.**


## Using ROLES in CHEF:

Using individual recipes is just OK but... what if we want to create a "category" or "role" that include several and very specific roles and attributes ?. That is acomplished in CHEF using "ROLES".

Let's create a "LAMP" Server role. First, we need to download our required cookbooks and upload them to our chef server. We already have apache so we just need php and mysql (mariadb really). Note that "php" requires mysql, and: build-essential, xml, yum-epel (which also requires yum) and iis. Also build-essential dependes on seven_zip, mingw and compat_resource. Seven_zip requires windows too, and finally, mariadb requires both yum and apt. Always check in the market the cookbook requirements:

```bash
cd /root/chef-repo/cookbooks/
knife cookbook site download php
knife cookbook site download mysql
knife cookbook site download build-essential
knife cookbook site download xml
knife cookbook site download yum-epel
knife cookbook site download iis
knife cookbook site download seven_zip
knife cookbook site download mingw
knife cookbook site download compat_resource
knife cookbook site download windows
knife cookbook site download yum
knife cookbook site download mariadb
knife cookbook site download apt

for i in `ls *.tar.gz`; do tar -xzvf $i; done
rm -f *.tar.gz

knife cookbook upload compat_resource
knife cookbook upload windows
knife cookbook upload seven_zip
knife cookbook upload mingw
knife cookbook upload build-essential
knife cookbook upload xml
knife cookbook upload iis
knife cookbook upload yum
knife cookbook upload yum-epel
knife cookbook upload mysql
knife cookbook upload php
knife cookbook upload apt
knife cookbook upload mariadb

```

**Note something here: The order is very important, but also chef help's you. Everytime you want to upload a cookbook and the cookbooks dependencies are not in the server, knife warns you with the dependency list (the missing dependencies to be precise), and their minimal required versions.**

Then, we are ready. We have all the required recipes, being the ones we need for our LAMP server:

- apache2::default
- apache2::mod_php5
- php::default
- php::module_mysql
- mariadb::default

Also, depending on our node operating system (we'll create a role for centos and another for ubuntu) we need to include:

- apt::default
- yum::default

Now.... we can assign our recipes as run_list, or, we can create a ROLE with all what we need. First, let's create a directory for our roles in our chef workstation:

```bash
mkdir /root/chef-repo/roles
```

And, we just need to create our roles. For that purpose, we'll create "json" files with all the required information for our two roles:

**For Centos:**

```bash
vi /root/chef-repo/roles/lamp-centos.json
```

Containing:

```bash
{
	"name": "lamp-centos",
	"default_attributes": {
	},
	"json_class": "Chef::Role",
	"run_list": [
		"recipe[yum::default]",
		"recipe[apache2::default]",
		"recipe[php::default]",
		"recipe[php::module_mysql]",
		"recipe[mariadb::default]"
	],
	"description": "A Centos-based LAMP Server",
	"chef_type": "role",
	"override_attributes": {
		"mariadb": {
			"use_default_repository": "True"
		}
	}
}
```

**For Ubuntu:**

```bash
vi /root/chef-repo/roles/lamp-ubuntu.json
```

Containing:

```bash
{
	"name": "lamp-ubuntu",
	"default_attributes": {
	},
	"json_class": "Chef::Role",
	"run_list": [
		"recipe[apt::default]",
		"recipe[apache2::default]",
		"recipe[php::default]",
		"recipe[php::module_mysql]",
		"recipe[mariadb::default]"
	],
	"description": "An Ubuntu-based LAMP Server",
	"chef_type": "role",
	"override_attributes": {
		"mariadb": {
			"use_default_repository": "True"
		}
	}
}
```

**PLEASE NOTE SOMETHING VITAL HERE: Did you saw the "override_attributes" section ?. As stated in the cookbook URL [https://supermarket.chef.io/cookbooks/mariadb](https://supermarket.chef.io/cookbooks/mariadb), if you don't have already installed the oficial mariadb repos, you need to set the attribute "use_default_repository" to "True", or else, the installation will fail !!. Setting the attribute to True ensures the recipe to add it to the operating system is run first.**


With our "json" files ready, let's include our roles into the chef server using the `knife role from file FILENAME` command:

```bash
knife role from file /root/chef-repo/roles/lamp-centos.json
knife role from file /root/chef-repo/roles/lamp-ubuntu.json
```

With `knife role list` you can see your role list, and, with `knife role show ROLENAME` you can see the recipes and their attributes on the role:

```bash
knife role show lamp-centos

chef_type:           role
default_attributes:
description:         A Centos-based LAMP Server
env_run_lists:
json_class:          Chef::Role
name:                lamp-centos
override_attributes:
  mariadb:
    use_default_repository: True
run_list:
  recipe[yum::default]
  recipe[apache2::default]
  recipe[php::default]
  recipe[php::module_mysql]
  recipe[mariadb::default]

```

Now, let's assign a role to our centos node (server-73):

```bash
knife node run_list add server-73 'role[lamp-centos]'

server-73:
  run_list: role[lamp-centos]
```

If you don't want to wait, just exec "chef-client" on server-73 console, and see what happens !.

Ok... after a while, you'll see how your chef-client returns eveything OK:

```bash
Chef Client finished, 139/139 resources updated in 34 seconds
```

Ok, now, let's do the same with the Ubuntu node (server-74), but, because the node already has a run list, let's change it with the following command in our chef workstation:

```bash
knife node edit server-74
```

After the last command, an editor (normally vi or vim, or whatever you have set as your $EDITOR environment variable) will show you this:

```bash
{
	"name": "server-74",
	"chef_environment": "_default",
	"normal": {
		"tags": [

		]
	},
	"policy_name": null,
	"policy_group": null,
	"run_list": [
		"recipe[apache2::default]"
	]
}
```

Change the line that says "recipe[apache2::default]" to "role[lamp-centos]" and save the file (with whatever command use your editor):

```bash
{
	"name": "server-74",
	"chef_environment": "_default",
	"normal": {
		"tags": [

		]
	},
	"policy_name": null,
	"policy_group": null,
	"run_list": [
		"role[lamp-centos]"
	]
}
```

In the node (server-74), the next time chef-client is run, the new role will be applied to your node !. Instead of running the original "apache2::default" recipe, it will run the recipes in the role, and apply the overriden attributes where apply.

So, what's the deal with all this ?. We had just created an automated infrastructure by the use of chef !. Note that we can use the chef GUI available on the chef server to ease our nodes management, roles creation, attribute overrides, etc.


## Creating a Custom "very basic" cookbook.

Let's do something even more complex, but still easy to do and still basic. Let's create a very simple cookbook which includes some extra recipes and specific configurations.

First, let's get mongodb3 cookbook and upload to our server. We also need the "runit specific version 1.7.0", "packagecloud" and "user" dependencies. We can see all related info on the market url for mongodb3 [https://supermarket.chef.io/cookbooks/mongodb3#readme](https://supermarket.chef.io/cookbooks/mongodb3):

```bash
cd /root/chef-repo/cookbooks
knife cookbook site download mongodb3
knife cookbook site download runit 1.7.0
knife cookbook site download packagecloud
knife cookbook site download user

for i in `ls *.tar.gz`; do tar -xzvf $i; done
rm -f *.tar.gz

knife cookbook upload packagecloud
knife cookbook upload user
knife cookbook upload runit
knife cookbook upload mongodb3
```

Now, with our base cookbooks uploaded, let's create our own cookbook that will include mongodb3 with some modifications using the command `chef generate cookbook mongodb3custom01`:

```bash
cd /root/chef-repo/cookbooks
chef generate cookbook mongodb3custom01
```

The last command will generate our basic bookbook structure. Now, let's begin to do "things" here. First, edit the metadata.rb file in order to include our mongodb3 cookbook:

```bash
vi /root/chef-repo/cookbooks/mongodb3custom01/metadata.rb
```

And add to the end:

```bash
depends "mongodb3"
```

Save the file. Now, edit the recipes/default.rb file in order to add our mongodb default recipe:

```bash
vi /root/chef-repo/cookbooks/mongodb3custom01/recipes/default.rb
```

Add to the end:

```bash
include_recipe "mongodb3::default"
```

Save the file, and finally to get some custom attributes for our mongo server, edit the file (create the directory for attributes first):

```bash
mkdir /root/chef-repo/cookbooks/mongodb3custom01/attributes
vi /root/chef-repo/cookbooks/mongodb3custom01/attributes/default.rb
```

And add:

```bash
default['mongodb3']['config']['mongod']['net']['bindIp'] = '127.0.0.1'
default['mongodb3']['config']['mongod']['net']['maxIncomingConnections'] = 100
```

And save the file. The last file we modified (attributes/default.rb) will override the original attributes in the original mongodb3 cookbook, and, use specific settings for our new cookbook. With everything ready, upload the cookbook to our server:

```bash
knife cookbook upload mongodb3custom01
```

Ok, now, let's include our recipe in one of our nodes, by editing it with the command `knife node edit NODENAME`:

```bash
knife node edit server-74
```

Change the run list to include the original role and the new recipe (yes, we can have both recipes and roles combined):

```
{
	"name": "server-74",
	"chef_environment": "_default",
	"normal": {
		"tags": [
		]
	},
	"policy_name": null,
	"policy_group": null,
	"run_list": [
		"role[lamp-centos]",
		"recipe[mongodb3custom01::default]"
	]
}
```

Save the file, then either wait until the crontab runs the chef-client on the server-74 node, or, run it manually as root (or with sudo).

When the recipes are applied, you can check your mongodb service running at IP 172.0.0.1:

```bash
root@server-74:~# ss -ltn

State      Recv-Q Send-Q                                            Local Address:Port                                              Peer Address:Port
LISTEN     0      128                                                           *:22                                                           *:*
LISTEN     0      128                                                   127.0.0.1:27017                                                        *:*
LISTEN     0      100                                                   127.0.0.1:3306                                                         *:*
LISTEN     0      128                                                          :::80                                                          :::*
LISTEN     0      128 
```

The mongodb3 default is to allow the service to be available to "0.0.0.0", but, we changed on our recipe to use localhost (127.0.0.1).

What we acomplished here ?. We created a very very basic cookbook using another as base (included) and forced new attributes for our recipes. Note that we could have done this too be just including a new role with overriden attributes or just include the attributes directly on the node.


## Where to go from here ??.

CHEF is a monster with a lot of ways to do things. If you don't want to learn ruby (in order to do your very customized cookbooks and recipes), you can resort to use the recipes/cookbooks from the community, and make your own adjustments using the attributes !. Also, CHEF support "environments", where, depending of your environment, you can change specific attributes or use specific recipes. A example of how could we have roles that change the run_list depending of the environment:


```bash
{
	"name": "lamp-ubuntu",
	"default_attributes": {
	},
	"json_class": "Chef::Role",
	"run_list": [
		"recipe[apt::default]",
		"recipe[apache2::default]",
		"recipe[php::default]",
		"recipe[php::module_mysql]"
	],
	"env_run_lists": {
		"development": [
			"recipe[mariadbcustom::development]"
		],
		"staging": [
			"recipe[mariadbcustom::staging]"
		],
		"production": [
			"recipe[mariadbcustom::production]"
		]
	},
	"description": "An Ubuntu-based LAMP Server",
	"chef_type": "role",
	"override_attributes": {
		"mariadb": {
			"use_default_repository": "True"
		}
	}
}
```

In this example, we have in our chef server a cookbook called "mariadbcustom" with specifc recipes for our environments (development, staging and production). Just we need to create the environments, and change the nodes from the default one (_default) to the specific environment where the node will be located. Also, you can include "override_attributes" list to your environments, enabling more customization of your recipes directly from the environment.

From this point, we recommend the reader to see the actual chef documentation, available from the following site:

- [CHEF Online Documentation.](https://docs.chef.io/)

END.-