# ANSIBLE TUTORIAL - CONFIGURATION MANAGEMENT MADE EASY

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

Along all modern things used in cloud deployments, and in general in SysOps/DevOps environments, configuration management is one of the most critical aspects of "how to keep your infrastructure under control, fully updated, and in general, organized".

One of the first tools used to acomplish this was cf-engine (the oldest one), and after it's widespread adoption, other tools, easier to use, and with more features and more cloud-orientation have been released to the OpenSource world. On of those tools is "Ansible".

Note that the word means, and I will quote the [wikipedia article](https://en.wikipedia.org/wiki/Ansible):

*"An ansible is a fictional device capable of instantaneous or superluminal (faster than light) communication. It can send and receive messages to and from a corresponding device over any distance whatsoever with no delay."*

Well... You'll see during this brief tutorial that there is no better choice for the Ansible tool but that definition !.


## Our lab environment:

We'll show how ansible can do things in different unix distros, so for our LAB we'll have a central infrastructure server running Centos 6.8 with [EPEL](https://fedoraproject.org/wiki/EPEL) repo installed (EPEL is mandatory in Centos/RHEL in order to install Ansible) and 3 virtual instances (all 3 deployed in a OpenStack cloud), one being Centos 7, other Ubuntu 16.04lts, and the final one Debian 8.

Central Centos Infrastructure Server IP: 192.168.1.1
Centos 7 instance IP: 192.168.1.230
Ubuntu 16.04lts instance IP: 192.168.1.233
Debian 8 instance IP: 192.168.1.232

Note that Ansible uses ssh in order to interact with it's controlled machines, so, we'll need to create a secure ssh environment with sudo later.


## Main server (Centos 192.168.1.1) ansible setup and ssh configuration on remote servers (192.168.1.230,232 and 233):

First, we need to install ansible. Remember again, the server (a Centos 6 64 bits machine) needs EPEL repository in order to have access to Ansible packages. Then:

```bash
yum -y install ansible
```

Also, we'll install crudini in order to ease our ansible configuration:

```bash
yum -y install crudini
```

**NOTE: Crudini is also part of EPEL repo.**

With ansible installed, let's do a simple test of "ping":

```bash
ansible localhost -u root -k -m ping
SSH password: 
 [WARNING]: provided hosts list is empty, only localhost is available

localhost | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

Now, we need to set our secure environment. We'll setup ansible to use a "non-root" account with ssh-keys and sudo.

First, in our server, let's create a ssh-key with the following commands:

```bash
mkdir /etc/ansible/keys
cd /etc/ansible/keys
ssh-keygen -t rsa -f ansible -P ""
```

In the 3 machines we are going to use with ansible (192.168.1.230, 232 and 233), we'll create the user and sudo for it.

In all 3 machines run the following commands:

```bash
useradd -c "Ansible Account" -d /home/ansible -m -s /bin/bash ansible
echo 'Defaults:ansible !requiretty' > /etc/sudoers.d/ansible
echo 'ansible ALL=(ALL)       NOPASSWD:ALL' >> /etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible
echo "ansible:ansible"|chpasswd
```

**NOTE: Don't freak out !!!. The "ansible" password is temporary. We'll discard it as soon as we copy our secure key.**

Again in the main Centos server, we'll propagate the key. Use the following commands, and when prompted use the "ansible" password previouslly set:

```bash
ssh-copy-id -i /etc/ansible/keys/ansible.pub ansible@192.168.1.230
ssh-copy-id -i /etc/ansible/keys/ansible.pub ansible@192.168.1.232
ssh-copy-id -i /etc/ansible/keys/ansible.pub ansible@192.168.1.233
```

Just to ensure the key is OK, do a test:

```bash
ssh -i /etc/ansible/keys/ansible ansible@192.168.1.230 "date"
ssh -i /etc/ansible/keys/ansible ansible@192.168.1.232 "date"
ssh -i /etc/ansible/keys/ansible ansible@192.168.1.233 "date"
```

Now, in all 3 servers, let's remove the "very insecure" password for the ansible account:

```bash
passwd -l ansible
```

**NOTE: Please please please !. Automate this part. If you have a cloud environment using openstack or aws, you can bootstrap this, or even instruct cloud-init to do it for you.**

Now it's time to configure ansible to use the account and key. In the file /etc/ansible/ansible.cfg set the following options. Because the config is an "ini" file, we can safely use "crudini" to set our config options:

```bash
crudini --set /etc/ansible/ansible.cfg defaults remote_user ansible
crudini --set /etc/ansible/ansible.cfg defaults executable bash
crudini --set /etc/ansible/ansible.cfg defaults private_key_file "/etc/ansible/keys/ansible"
crudini --set /etc/ansible/ansible.cfg defaults sudo_user root
```

Ok, now, let's put our servers in a basic group in ansible, so we can begin doing some tests. Ansible "host" file is normaly "/etc/ansible/hosts":

```bash
echo "" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "# Our first group" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "[cloudgroup]" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "192.168.1.230" >> /etc/ansible/hosts
echo "192.168.1.232" >> /etc/ansible/hosts
echo "192.168.1.233" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
```

This define our 3 servers as managed by ansible, and now we can do a basic "ping" test to them:

```bash
ansible 192.168.1.230 -m ping

192.168.1.230 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

ansible 192.168.1.232 -m ping

192.168.1.232 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

ansible 192.168.1.233 -m ping

192.168.1.233 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

And, in order to fully test sudo, run the following commands:

```bash
ansible 192.168.1.230 -b -m command -a 'id -a'
ansible 192.168.1.232 -b -m command -a 'id -a'
ansible 192.168.1.233 -b -m command -a 'id -a'
```

All should reply the same:

```bash
192.168.1.X | SUCCESS | rc=0 >>
uid=0(root) gid=0(root) groups=0(root)
```

The options used in those commands explained here:

- -b: "become": This is the sudo part. Instructs ansible to "become" the sudo_user indicated in the configuration.
- -m command -a: Exec in the server the command followed by the "-a" part. -m calls a "module" (command is an ansible built-in module) which function is to exec commands on the remote machine.

Basically our command instructed ansible to use the key/ssh/sudo/account config previously setup in /etc/ansible/ansible.cfg, and run in the remote machines the "id -a" command.


## Let's "play" with ansible - basic commands:

Ok, ansible is configured and it has full root (sudo) access to your 3 servers. Now, let's do some tests, and then create actual things !.

Remember when we used "-m" command ?. Now let's use another command which will give us "facts" about our remote machines:

```bash
ansible 192.168.1.230 -b -m setup
ansible 192.168.1.232 -b -m setup
ansible 192.168.1.233 -b -m setup
```

The setup module basicaly shows "a LOT" of technical information about your machines. I'm not showing the output here, as it is really a long list !.

Note that the last command return a lot of "ansible_" variables. Those variables can be used later in order to query our machines and take decisions later.

Another module we can use is "file". It basically renders information about files or directories in our remote machines:

```bash
ansible 192.168.1.230 -b -m file -a "path=/etc/profile"
ansible 192.168.1.232 -b -m file -a "path=/etc/profile"
ansible 192.168.1.233 -b -m file -a "path=/etc/profile"
ansible 192.168.1.230 -b -m file -a "path=/etc"
ansible 192.168.1.232 -b -m file -a "path=/etc"
ansible 192.168.1.233 -b -m file -a "path=/etc"
```

You can obtain a list of every available module in ansible, and ask for help:

This lists all available modules:

```bash
ansible-doc -l
```

And this shows the help for a specific module:

```bash
ansible-doc MODULENAME
```

A practical example here:

```bash
ansible-doc hostname

> HOSTNAME

  Set system's hostname. Currently implemented on Debian, Ubuntu, Fedora, RedHat, openSUSE, Linaro,
  ScientificLinux, Arch, CentOS, AMI. Any distribution that uses systemd as their init system. Note, this
  module does *NOT* modify /etc/hosts. You need to modify it yourself using other modules like template or
  replace.

Options (= is mandatory):

= name
        Name of the host

Requirements:  hostname

EXAMPLES:
- hostname: name=web01


MAINTAINERS: Hiroaki Nakamura (@hnakamur), Hideki Saito (@saito-hideki)
```


## Let's "play" more... use of playbooks:

The actual "production" work with ansible is done by the use of playbooks. A "playbook" in ansible is a "yaml" formatted file with instructions of how to do things in ansible.

Let's create a file:

```bash
vi ~/helloworld.yaml
```

containing:

```bash
---
- hosts: cloudgroup
  user: ansible
  become: yes
  become_method: sudo
  vars:
    hello_message: "HELLO WORLD\n"
  tasks:
    - name: Setup a hello world file
      copy:
        dest: /etc/hello-world.txt
        content: "{{ hello_message }}"
```

Explanation:

- The "hosts" section includes the group where we are going to apply the playbook (defined in /etc/ansible/hosts). The user, become and become_method options instruct ansible to use the "ansible" account we previously created, and become root with sudo.
- The "vars" section defines variables that we are going to use in our playbook. In our file, we asigned the "HELLO WORLD" string to the "hello_message" variable.
- The "tasks" section create the tasks we are going to execute on the remote machine. For our example, we are using the "copy" module, with destionation file "/etc/hello-world.txt", containing the text indicated on the "hello_message" variable.

Next, exec the playbook:

```bash
ansible-playbook ~/helloworld.yaml
```

Your output should be:

```bash
PLAY [cloudgroup] **************************************************************

TASK [setup] *******************************************************************
ok: [192.168.1.230]
ok: [192.168.1.232]
ok: [192.168.1.233]

TASK [Setup a hello world file] ************************************************
changed: [192.168.1.233]
changed: [192.168.1.232]
changed: [192.168.1.230]

PLAY RECAP *********************************************************************
192.168.1.230              : ok=2    changed=1    unreachable=0    failed=0   
192.168.1.232              : ok=2    changed=1    unreachable=0    failed=0   
192.168.1.233              : ok=2    changed=1    unreachable=0    failed=0 
```

In any of the 3 servers you can see the file:

```bash
[root@server-230 ~]# cat /etc/hello-world.txt 
HELLO WORLD
```

If you run the command `ansible-playbook ~/helloworld.yaml` again, the part where "changed=1" will change to "changed=0" as the file is already there and with the desired contents. Ansible is said to be [**"idempotent"**](https://en.wikipedia.org/wiki/Idempotence), meaning that it will not change anything unless really needed !. If the change was done the first time in the file, and following runs of the playbook determine the file is the same and does not need to be re-edited again, then it will not be touched !.

Let's do something more complex now. We'll ensure the install of software here (namely, apache), but, we need to know the environment of the server in order to use the right installation module (apt or yum). Remember the ansible_ variables returned by the setup module ??.. See this:

```bash
ansible 192.168.1.230 -b -m setup|grep ansible_os_family
        "ansible_os_family": "RedHat", 

ansible 192.168.1.232 -b -m setup|grep ansible_os_family
        "ansible_os_family": "Debian", 

ansible 192.168.1.233 -b -m setup|grep ansible_os_family
        "ansible_os_family": "Debian", 
```

Yeeesss !!!... The "ansible_os_family" variable returns "RedHat" for the RHEL's and derivatives (centos, scientific linux, etc.) and "Debian" for the DEBIAN derivatibes (Debians, Ubuntuses, Mints, etc.).


Then, let's create our file:

```bash
vi ~/webserver.yaml
```

Containing:

```bash
---
- hosts: webservers
  user: ansible
  become: yes
  become_method: sudo
  tasks:
    - name: Install apache, in a yum-based machine
      yum:
        name: httpd
        state: installed
      when: ansible_os_family == "RedHat"

    - name: Install apache, in a apt-based machine
      apt:
        name: apache2
        state: installed
      when: ansible_os_family == "Debian"
```

See something in the file: First, we are conditioning our tasks with the "when" statement. The "yum" task will trigger when the "ansible_os_family" is "RedHat", and the apt's when it's Debian.

Also, we are using another host group here... "webservers"... Let's exec the playbook and see what happens:

```bash
ansible-playbook ~/webserver.yaml 

PLAY [webservers] **************************************************************
skipping: no hosts matched

PLAY RECAP *********************************************************************
```

BOOM !!!.. The playbook did not found any host matching the "webservers" host group. Let's add one of our servers to the group:

```bash
echo "" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "# Our Second group - for webservers" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "[webservers]" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
echo "192.168.1.232" >> /etc/ansible/hosts
```

And, call the playbook again:

```bash
ansible-playbook ~/webserver.yaml 

PLAY [webservers] **************************************************************

TASK [setup] *******************************************************************
ok: [192.168.1.232]

TASK [Install apache, in a yum-based machine] **********************************
skipping: [192.168.1.232]

TASK [Install apache, in a apt-based machine] **********************************
changed: [192.168.1.232]

PLAY RECAP *********************************************************************
192.168.1.232              : ok=2    changed=1    unreachable=0    failed=0   
```

The output shows how the task with "yum" was skipped. Our 192.168.1.232 server is a Debian 8.6 machine. In the debian, you can see the apache working:

```bash
root@server-232:~# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr fa:16:3e:45:b5:a4  
          inet addr:192.168.1.232  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::f816:3eff:fe45:b5a4/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1454  Metric:1
          RX packets:51996 errors:0 dropped:0 overruns:0 frame:0
          TX packets:70976 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:6552038 (6.2 MiB)  TX bytes:17009663 (16.2 MiB)

root@server-232:~# /etc/init.d/apache2 status
● apache2.service - LSB: Apache2 web server
   Loaded: loaded (/etc/init.d/apache2)
  Drop-In: /lib/systemd/system/apache2.service.d
           └─forking.conf
   Active: active (running) since Fri 2016-10-21 12:28:38 VET; 2min 24s ago
   CGroup: /system.slice/apache2.service
           ├─2710 /usr/sbin/apache2 -k start
           ├─2713 /usr/sbin/apache2 -k start
           └─2714 /usr/sbin/apache2 -k start

Oct 21 12:28:37 server-232.stack.gatuvelus.home apache2[2689]: Starting web server: apache2AH00558: apache2: Could not reliab...sage
Oct 21 12:28:38 server-232.stack.gatuvelus.home apache2[2689]: .
Oct 21 12:28:38 server-232.stack.gatuvelus.home systemd[1]: Started LSB: Apache2 web server.
Hint: Some lines were ellipsized, use -l to show in full.
```

Now, let's extend more our webserver template and include other packages. Also, lets explore the concept of looping and, use multiple conditionals (you'll see why). Edit the template:

```bash
vi ~/webserver.yaml
```

And change it to:

```bash
---
- hosts: webservers
  user: ansible
  become: yes
  become_method: sudo
  tasks:
    - name: Install apache, in a yum-based machine
      yum:
        name: "{{ item }}"
        state: installed
      with_items:
        - httpd
        - httpd-manual
        - httpd-tools
        - php
      when: ansible_os_family == "RedHat"

    - name: Install apache, in a apt-based machine with Debian 8
      apt:
        name: "{{ item }}"
        state: installed
      with_items:
        - apache2
        - apache2-doc
        - apache2-utils
        - libapache2-mod-php5
      when: ansible_distribution == "Debian" and ansible_distribution_major_version == "8"

    - name: Install apache, in a apt-based machine with Ubuntu 16
      apt:
        name: "{{ item }}"
        state: installed
      with_items:
        - apache2
        - apache2-doc
        - apache2-utils
        - libapache2-mod-php
      when: ansible_distribution == "Ubuntu" and ansible_distribution_major_version == "16"
```

Let's include on the hosts file our two other servers in the webservers group:

```bash
echo "192.168.1.230" >> /etc/ansible/hosts
echo "192.168.1.233" >> /etc/ansible/hosts
echo "#" >> /etc/ansible/hosts
```

Then, run the playbook:

```bash
ansible-playbook ~/webserver.yaml 
```

The playbook will install the needed software on all 3 machines. We changed the "when" statement in order to correctly install the "mod-php" package due the fact that the package name in debian 8 is different than the name in ubuntu 16. Conditionals in ansible works like in other languages... and/or/etc. Also, we demostrated the use of a loop. The "{{ item }}" and "with_items:" combo is the basic contruct for looping in ansible.

While we wanted to show the use of looping, we really don't need it for yum/apt modules as we can use a list. Also, we'll introduce here the statemens for service startup/enabling and the handlers concept. Let's change our webserver playbook:

```bash
vi ~/webserver.yaml
```

And change it to:

```bash
---
- hosts: webservers
  user: ansible
  become: yes
  become_method: sudo
  tasks:
    - name: Install apache, in a yum-based machine
      yum:
        name:
          - httpd
          - httpd-manual
          - httpd-tools
          - php
          - mod_wsgi
        state: latest
      notify: restart httpd
      when: ansible_os_family == "RedHat"

    - name: Install apache, in a apt-based machine with Debian 8
      apt:
        name:
          - apache2
          - apache2-doc
          - apache2-utils
          - libapache2-mod-php5
          - libapache2-mod-python
        state: latest
      notify: restart apache2
      when: ansible_distribution == "Debian" and ansible_distribution_major_version == "8"

    - name: Install apache, in a apt-based machine with Ubuntu 16
      apt:
        name:
          - apache2
          - apache2-doc
          - apache2-utils
          - libapache2-mod-php
          - libapache2-mod-python
        state: latest
      notify: restart apache2
      when: ansible_distribution == "Ubuntu" and ansible_distribution_major_version == "16"

    - name: Apache - RHELs
      service:
        name:
          httpd
        enabled:
          yes
        state:
          started
      when: ansible_os_family == "RedHat"

    - name: Apache - Debians
      service:
        name:
          apache2
        enabled:
          yes
        state:
          started
      notify: restart apache2
      when: ansible_os_family == "Debian"

  handlers:

    - name: restart httpd
      service:
        name:
          httpd
        state:
          restarted

    - name: restart apache2
      service:
        name:
          apache2
        state:
          restarted
```

This demostrate in more "production and practical" terms the way to ensure our packages are installed and the services are running. Also, note that we changed "installed" by "latest", ensuring the last updated version will be always installed/updated. When the package is updated, the "notify" section triggers an action to call the "handlers" section with the specific name, then executes the action, for this example, a service reload !.

In other words... if our package is upgraded (httpd or apache2), a call to the respective handler is sent in order to ensure the service is restarted.


## Extending ansible more and more with the use of roles:

Ansible can organize the playbooks and related files (we'll also introduce some "templates" and "includes" here) in a directory structure which defines "roles" for our servers.

In order to use roles, we need to create a "role" directory for every role we want. Those subdirs must be located under the /etc/ansible/roles directory, and should contain the following directories inside: files, handlers, meta, tasks, templates, and vars. For our LAB, we created the roles "common" and "webserver":

```bash
.
├── common
│   ├── files
│   ├── handlers
│   ├── meta
│   ├── tasks
│   ├── templates
│   └── vars
└── webserver
    ├── files
    ├── handlers
    ├── meta
    ├── tasks
    ├── templates
    └── vars
```

What means those structures ?. Explanation follows:

- tasks: This directory contains the "main.yml" file, with all tasks that the role will run. Other files included in the "main.yml" as "includes" should be in this directory too.
- files: This will be the directory which the "copy" module will use as default location for the files.
- templates: This will be the directory which the "templates" module will use as default location for, of course, the templates.
- handlers: This directory contains the "main.yml" file with the handlers (we'll explained this before) that the playbook will use. Also, any "includes" called by the main.yml will be located here.
- vars: This directory should contain a "main.yml" file with all defined variables for the role.
- meta: This directory should contain a "main.yml" file with all settings used by the role and a list of dependencies.

Let's begin some construction. First, let's create the files in our "common" role:

- Variables:

```bash
vi /etc/ansible/roles/common/vars/main.yml
```

Containing:

```bash
---
# Our variables
layer_message: "Infrastucture Server\n"
layer_filename: /etc/layer-infra-common
```

- Tasks. Here we'll play with includes:

```bash
vi /etc/ansible/roles/common/tasks/main.yml
```

Containing:

```bash
---
# Task called by include - add users from the list
- include: useradd.yml user={{ item }}
  with_items:
    - kiki
    - rayita
    - negrito
# Task for the file copy - use variables defined
# in ./vars/main.yml
- name: copy a file and set its contents
  copy:
    dest: "{{ layer_filename }}"
    content: "{{ layer_message }}"
# LSB package install:
- include: lsbinstall.yml
# Set the server information in a file from a jinja2 template
# using template module
- name: set the server info template
  template:
    src: layer-infra-server-spec.j2
    dest: /etc/layer-infra-server-spec
```

- Our useradd.yml include:

```bash
vi /etc/ansible/roles/common/tasks/useradd.yml
```

Containing:

```bash
---
# Create the user group:
- name: Create user group
  group:
    name: "{{ user }}"
    state: present

# Create an user and set its properties
- name: Create user account
  user:
    name: "{{ user }}"
    group: "{{ user }}"
    shell: /bin/bash
    state: present

# For the user, it creates a password using external commands
- name: Set user password using external commands
  shell:
    echo "{{ user | quote }}":"{{ user | quote }}"|chpasswd

# And, set sudo for the user
- name: Set sudo for the user
  copy:
    dest: /etc/sudoers.d/{{ user }}
    content: "{{ user }} ALL=(ALL) NOPASSWD:ALL\n"

# Then, set the file permissions to 0440
- name: Set permissions for sudoder file
  file:
    path: /etc/sudoers.d/{{ user }}
    owner: root
    group: root
    mode: 0440
```

- Our lsbinstall.yml include:

```bash
vi /etc/ansible/roles/common/tasks/lsbinstall.yml
```

Containing:

```bash
---
- name: Install lsb support, in a yum-based machine
  yum:
    name: redhat-lsb-core
    state: installed
  when: ansible_os_family == "RedHat"

- name: Install lsb support, in a apt-based machine
  apt:
    name: lsb-release
    state: installed
  when: ansible_os_family == "Debian"
```


About the templates, they need to be created in "jinja2" format. Let's create one and see it's usage:

```bash
vi /etc/ansible/roles/common/templates/layer-infra-server-spec.j2
```

Containing:

```bash
# {{ ansible_managed }}
Server IP: {{ ansible_default_ipv4.address }}
Server Distro: {{ ansible_distribution }}
Server Distro Mayor Version: {{ ansible_distribution_major_version }} 
```

Now, let's create our "site01" playbook inside the roles dir:

```bash
vi /etc/ansible/roles/site01.yml
```

Containing:

```bash
---
- name: Our Site01
  hosts: cloudgroup
  user: ansible
  become: yes
  become_method: sudo
  roles:
    - common
```

And, let's play it:

```bash
ansible-playbook /etc/ansible/roles/site01.yml
```

In resume, this "common" role will:

- Create the users "kiki", "negrito", and "rayita", with their respective groups and passwords set with the same username.
- Set sudo permissions for the created users.
- Install the lsb_release utility.
- Create the files "/etc/layer-infra-server-spec" and "/etc/layer-infra-common" with some information inside.

Please note the contents of the file "/etc/layer-infra-server-spec" in one of the servers:

```bash
cat /etc/layer-infra-server-spec 
# Ansible managed: /etc/ansible/roles/common/templates/layer-infra-server-spec.j2 modified on 2016-10-21 17:23:25 by root on proxy.gatuvelus.home
Server IP: 192.168.1.230
Server Distro: CentOS
Server Distro Mayor Version: 7 
```

Basically, the j2 template can use variables from the "setup" module. The j2 files can include conditionals and some form of loops. See the j2 development documentation for more info about those functions: 

- [Template Designer Documentation](http://jinja.pocoo.org/docs/dev/templates/)


Now, let's work with the other role: webserver

Let's create the task file first, which will ensure proper apache instalation:

```bash
vi /etc/ansible/roles/webserver/tasks/main.yml
```

Containing:

```bash
---
- name: Install apache, in a yum-based machine
  yum:
    name:
      - httpd
      - httpd-manual
      - httpd-tools
      - php
      - mod_wsgi
    state: latest
  notify: restart httpd
  when: ansible_os_family == "RedHat"

- name: Install apache, in a apt-based machine with Debian 8
  apt:
    name:
      - apache2
      - apache2-doc
      - apache2-utils
      - libapache2-mod-php5
      - libapache2-mod-python
    state: latest
  notify: restart apache2
  when: ansible_distribution == "Debian" and ansible_distribution_major_version == "8"

- name: Install apache, in a apt-based machine with Ubuntu 16
  apt:
    name:
      - apache2
      - apache2-doc
      - apache2-utils
      - libapache2-mod-php
      - libapache2-mod-python
    state: latest
  notify: restart apache2
  when: ansible_distribution == "Ubuntu" and ansible_distribution_major_version == "16"

- name: Apache - RHELs
  service:
    name:
      httpd
    enabled:
      yes
    state:
      started
  when: ansible_os_family == "RedHat"

- name: Apache - Debians
  service:
    name:
      apache2
    enabled:
      yes
    state:
      started
  notify: restart apache2
  when: ansible_os_family == "Debian"

- name: copy main index
  copy:
    src: index.html
    dest: /var/www/html/index.html

- name: set special usage template
  template:
    src: server-extra-info.j2
    dest: /var/www/html/server-extra-info.html
```

You probably noticed something here: We are calling "handlers" here when the apache packages are updated. Let's define our handlers then:

```bash
vi /etc/ansible/roles/webserver/handlers/main.yml
```

Containing:

```bash
---
- name: restart httpd
  service:
    name:
      httpd
    state:
      restarted

- name: restart apache2
  service:
    name:
      apache2
    state:
      restarted
```

Our index file, in the "files" directory:

```bash
vi /etc/ansible/roles/webserver/files/index.html
```

Containing:

```bash
<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
   <HEAD>
      <TITLE>
         HELLO WORLD
      </TITLE>
   </HEAD>
<BODY>
   <H1>Hi</H1>
   <P>This is a basic "hello world".</P>
</BODY>
</HTML>
```

And, out template file:

```bash
vi /etc/ansible/roles/webserver/templates/server-extra-info.j2
```

Containing:

```bash
<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
   <HEAD>
      <TITLE>
         SERVER HOSTNAME INFO
      </TITLE>
   </HEAD>
<BODY>
   <H1>Hi</H1>
   <P>My name is {{ ansible_fqdn }}, and my MAC is {{ ansible_default_ipv4.macaddress }}.</P>
</BODY>
</HTML>
```

Ok our new role is ready. Now, let's include in out site file. Edit:

```bash
vi /etc/ansible/roles/site01.yml
```

And modify it too:

```bash
---
- name: Our Site01
  hosts: cloudgroup
  user: ansible
  become: yes
  become_method: sudo
  roles:
    - common
    - webserver
```

Run the playbook and see what happens !:

```bash
ansible-playbook /etc/ansible/roles/site01.yml
```

Your new "site01.yml" playbook will execute all tasks/files/templates from the "common" role first, then "webserver" role second.

Our web servers will have an index file, and, another html (http://SERVER/server-extra-info.html) showing the server FQDN and MAC address.

Note that you can still extend this as much as you want and include other roles, with more and more variables and modules, and even set your own variables at role creation inside the site01.yml file.


## Ok.. what now ??

This is a basic tutorial !. You can do a lot more with ansible. There are a lot of modules, including cloud-based ones used to interact with AWS, Google Cloud, Azure, OpenStack, CloudStack, and other interesting uses like: Docker !.

Just a reminder here: You can always see the modules list with:

```bash
ansible-doc -l
```

And also, the online documentation is at:

- [Ansible Online Documentation.](http://docs.ansible.com/)
- [Ansible Module Documentation Index.](http://docs.ansible.com/ansible/modules_by_category.html)

**NOTE: All files used in this tutorial are included here. You'll find them in the ansible directory.**


END.-
