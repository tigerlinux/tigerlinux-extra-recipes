# A Redmine Installation with Gitolite Integration ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to install a Redmine series 3.1 with Gitolite integration and A/D authentication on Centos 7.


## What kind of hardware and software do we need ?:

A Centos 7 machine with [EPEL repository](https://fedoraproject.org/wiki/EPEL) installed. Fully updated. SELinux and FirewallD disabled. For this Recipe, we used a OpenStack based virtual machine:

IP Server: 172.16.10.121
FQDN: vm-172-16-10-121.mydomain.dom

The Server is fully updated (yum -y update; reboot).


## How it was constructed the whole solution ?:


### Server basic requeriments:

We proceed to install the following packages with yum:

```bash
yum install make gcc gcc-c++ zlib-devel ruby-devel rubygems \
ruby-libs apr-devel apr-util-devel httpd-devel mysql-devel \
mysql-server automake autoconf ImageMagick ImageMagick-devel \
curl-devel mariadb-server git httpd
```

Next, more packages but this time with gem:

```bash
gem install bundle
gem install bundler
```


### Redmine Packages Download and initial setup:

Run the following commands:

```bash
cd /var/www
wget http://www.redmine.org/releases/redmine-3.1.1.tar.gz
tar -xzvf redmine-3.1.1.tar.gz
mv redmine-3.1.1 redmine
rm -f redmine-3.1.1.tar.gz
cd /var/www/redmine
bundle install --without postgresql sqlite test development
```

**NOTES:**
* At the moment we performed this installation, the lattest stable version was redmine 3.1.1. There are more recent versions in series 3.1, 3.2 and 3.3, but, prior to adventure yourself to use those versions, check for plugin compatibility with the version you want to use.
* We are using MariaDB as Database Backend, and only production environment. That's the reason for the parameters `"--without postgresql sqlite test development"`.


### Database Software Installation and Redmine database Creation:

Before we start our database engine, we need to ensure "max_allowed_packet" is set to 32M, or, your redmine could eventualy fail.

Edit the file:

```bash
vi /etc/my.cnf.d/server.cnf
```

And in the "[mysqld]" section set:

```bash
[mysqld]
max_allowed_packet = 32M
```

This is vital !. Fail to set max allowed packet to at least 32M, and you'll eventually run into troubles !.

Run the following commands in order to start and enable MariaDB server:

```bash
systemctl enable mariadb.service
systemctl start mariadb.service
```

Then, run the "mysql_secure_installation" and set the password. For this document, we'll set "P@ssw0rd" for the mariadb root account:

```bash
mysql_secure_installation
```

Run the following commands. Adjust the password to the one you configured on "mysql_secure_installation".

```bash
echo "[client]" > /root/.my.cnf
echo "user=root" >> /root/.my.cnf
echo "password=P@ssw0rd" >> /root/.my.cnf
```

Using the mysql command, create the redmine database

```bash
mysql

MariaDB [(none)]> create database redmine character set utf8;
MariaDB [(none)]> grant all privileges on redmine.* to 'redmine'@'localhost' identified by 'r3dm1n3-2015';
MariaDB [(none)]> flush privileges;
MariaDB [(none)]> quit
```


### Redmine Database Configuration:

Run the following commands:

```bash
cd /var/www/redmine/config
cp database.yml.example database.yml
```

Edit the file:

```bash
vi database.yml
```

In the "production" section, set the database configuration:

```bash
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: "r3dm1n3-2015"
  encoding: utf8
```

Save the file. With the following command, we proceed to populate the database:

```bash
cd /var/www/redmine
bundle install
rake generate_session_store
rake generate_secret_token
rake db:migrate RAILS_ENV="production"
rake redmine:load_default_data RAILS_ENV="production"
```

Install the following gem. This will be usefull for bash syntax highlighting:

```bash
gem install coderay_bash
```

Then, change again to redmine directory:

```bash
cd /var/www/redmine
```

Edit the file:

```bash
vi Gemfile
```

In the "gems" section, include coderay_bash at the end of the gem list:

```bash
gem "rails", "4.2.0"
gem "jquery-rails", "~> 3.1.1"
gem "coderay", "~> 1.1.0"
gem "builder", ">= 3.0.4"
gem "request_store", "1.0.5"
gem "mime-types"
gem "protected_attributes"
gem "actionpack-action_caching"
gem "actionpack-xml_parser"
gem "coderay_bash"
```

Save the file, and run:

```bash
bundle install
```


### Main configuration file and E-Mail configuration:

Run the following commands:

```bash
cd /var/www/redmine/config
cp configuration.yml.example configuration.yml
```

This will copy the sample configuration file to the actual-production config file.

If you are going to use mail (highly advisable if you need your redmine-tickets to generate mail's to proper users), edit the file:

```bash
vi configuration.yml
```

And set the proper parameters for your mail platform. Tthe following example is for an office365-based e-mail in the cloud:

```bash
email_delivery:
  delivery_method: :smtp
  smtp_settings:
    enable_starttls_auto: true
    address: "smtp.office365.com"
    port: 587
    domain: "mycompanydomain.dom"
    authentication: :login
    user_name: "redmine@mycompanydomain.dom"
    password: "My-Email-Password"
```

Save the file.


### Stand-alone test:

Before we continue configuring our server, let's do a little test. Run the following commands:

```bash
cd /var/www/redmine/
ruby bin/rails server -e production -b 0.0.0.0
```

Enter to your server using the URL: http://IP_OR_FQDN:3000. Example:

> http://172.16.10.121:3000

The default access is:

* User: admin
* Password: admin

Logout, and in the ssh console, press ctrl+c or ctrl+break to shutdown the "rails server".

**NOTE:** This step is not mandatory. It is just a test in order to check that redmine has been properly installed.


### CKEDITOR Plugin Installation.

Run the following commands:

```bash
cd /var/www/redmine/plugins
git clone https://github.com/a-ono/redmine_ckeditor
cd /var/www/redmine
bundle install --without postgresql sqlite test development
rake redmine:plugins:migrate RAILS_ENV=production
bundle pack
bundle install --path vendor/cache
```

Temporarily, activate the redmine server:

```bash
cd /var/www/redmine/
ruby bin/rails server -e production -b 0.0.0.0
```

Enter to your server using the URL: http://IP_OR_FQDN:3000. Example:

> http://172.16.10.121:3000

Login with "admin", password "admin".

Go to the sectin: "Administration > Settings > General > Text formatting". Change the Text formation to **"CKEditor"**.

Logout, and in the ssh console, press ctrl+c or ctrl+break to shutdown the "rails server".


### Apache/Thin integration.

We should not serve redmine directly. Instead, we'll use thin and apache proxypass.

We proceed to install thin:

```bash
cd /var/www/redmine
gem install thin
mkdir /var/log/thin
chmod 755 /var/log/thin
mkdir /var/run/redmine
mkdir /var/run/redmine/sockets
mkdir /etc/thin
mkdir /var/run/thin
chown -R apache.apache /var/log/thin /var/run/redmine /var/run/thin
```

We proceed to create a thin configuration:

```bash
thin config --config /tmp/redmine.yml --chdir /var/www/redmine \
    --environment production --address 0.0.0.0 --port 3000 \
    --daemonize --log /var/log/thin/redmine.log --pid /var/run/thin/redmine.pid \
    --user apache --group apache --servers 1 --prefix /redmine
    
mv /tmp/redmine.yml /etc/thin/redmine.yml
chown root:root /etc/thin/redmine.yml
chmod 644 /etc/thin/redmine.yml
touch /var/www/redmine/log/production.log
chown -R apache.apache /var/www/redmine
```

We then create the sysinit service for thin with the following command:

```bash
thin install
```

This last step create the script: `/etc/rc.d/thin`

We must move the script:

```bash
mv /etc/rc.d/thin /etc/init.d/thin
```

And edit it:

```bash
vi /etc/init.d/thin
```

We need to change this:

```bash
SCRIPT_NAME=/etc/rc.d/thin
```

For this:

```bash
SCRIPT_NAME=/etc/init.d/thin
```

We proceed to activate the service:

```bash
chkconfig thin on
```

We need to create an environment file for our redmine service:

```bash
cp /var/www/redmine/config/additional_environment.rb.example /var/www/redmine/config/additional_environment.rb
```

Then edit the file:

```bash
vi /var/www/redmine/config/additional_environment.rb
```

And add to the end of the file:

```bash
config.relative_url_root = '/redmine'
```

As we did previously with coderay_bash, we need to include thin in the main gemfile:

```bash
vi /var/www/redmine/Gemfile
```

And add thin to the end of gem list, just after coderay_bash:

```bash
gem "rails", "4.2.0"
gem "jquery-rails", "~> 3.1.1"
gem "coderay", "~> 1.1.0"
gem "builder", ">= 3.0.4"
gem "request_store", "1.0.5"
gem "mime-types"
gem "protected_attributes"
gem "actionpack-action_caching"
gem "actionpack-xml_parser"
gem "coderay_bash"
gem "thin"
```

Then run the commands:

```bash
cd /var/www/redmine
bundle install --without postgresql sqlite test development
chown -R apache.apache /var/www/redmine
chkconfig thin on
service thin start
```

We need to enter again with a browser to: http://IP_OR_FQDN:3000/redmine. Example:

> http://172.16.10.121:3000/redmine

User: admin, password: admin

We proceed to enter on section: "Administration > Settings > General > PROTOCOL", and delete both the hostname and path just over "PROTOCOL".

Now, we need to create an apache definition file for redmine:

```bash
vi /etc/httpd/conf.d/redmine.conf
```

Containing:

```bash
<Location /redmine/>
    RequestHeader set X_FORWARDED_PROTO 'http'
    ProxyPass           http://localhost:3000/redmine/
    ProxyPassReverse    http://localhost:3000/redmine/
</Location>

<Location /redmine>
    RequestHeader set X_FORWARDED_PROTO 'http'
    ProxyPass           http://localhost:3000/redmine
    ProxyPassReverse    http://localhost:3000/redmine
</Location>
```

Then, we enable and activate apache:

```bash
systemctl enable httpd
systemctl restart httpd
```

At this point you can enter directly to the normal webserver without the 3000: http://IP_OR_FQDN/redmine. Example:

> http://172.16.10.121/redmine

We should create a logrotate definition for both redmine and thin:

```bash
vi /etc/logrotate.d/thin
```

Containing:

```bash
/var/log/thin/*.log
/var/www/redmine/log/*.log
{
        daily
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
        create 640 apache apache
        sharedscripts
        postrotate
                /etc/init.d/thin restart >/dev/null
        endscript
}
```

Finaly, and this is completely optional, create the file:

```bash
vi /var/www/html/index.html
```

Containing:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/redmine">
</HEAD>
<BODY>
</BODY>
</HTML>
```

This is just if you want to enter to the web server root and be automaticaly redirected to the /redmine webdir.

Then, and again, optional:

```bash
ln -s /var/www/redmine/log /var/log/redmine
```


### Aditional Plugins.

This part is, again, optional but recommended:

```bash
mkdir -p /workdir/redmine

cd /var/www/redmine/plugins/
git clone https://github.com/paginagmbh/redmine_lightbox2.git
cd /var/www/redmine/plugins/redmine_lightbox2/
git checkout tags/v0.2.7
cd /var/www/redmine
RAILS_ENV=production rake redmine:plugins:migrate
/etc/init.d/thin restart
sleep 30

cd /workdir/redmine
wget https://github.com/jgraichen/redmine_dashboard/releases/download/v2.7.0/redmine_dashboard-v2.7.0.tar.gz
tar -xzvf redmine_dashboard-v2.7.0.tar.gz -C /var/www/redmine/plugins/
cd /var/www/redmine
bundle install --without postgresql sqlite test development
RAILS_ENV=production rake redmine:plugins:migrate
/etc/init.d/thin restart
sleep 30
```

**NOTE:** If you go for a newer redmine version than the one we used in this document, ensure those plugins are compatible with your desired redmine version.


### GIT Hosting Support Installation:

If you want to include GIT repository provisioning in your REDMINE, then proceed with this section.

First, install the following packages:

```bash
yum groupinstall "Development Tools"
yum install libssh2 libssh2-devel cmake libgpg-error-devel
yum install gitolite3
```

Sorry for repeating this again, but, ensure the version of redmine you are using is compatible with the version of the plugins you are going to use. If unsure, stick with series 3.1.x.

We proceed to run the following commands:

```bash
cd /var/www/redmine/plugins/
git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
cd redmine_bootstrap_kit/
git checkout 0.2.3

cd /var/www/redmine/plugins
git clone https://github.com/jbox-web/redmine_git_hosting.git
cd redmine_git_hosting/
git checkout 1.1.4
```

Edit the file:

```bash
vi /var/www/redmine/plugins/redmine_git_hosting/Gemfile
```

Change the line:

```bash
gem 'redcarpet', '~> 3.1.2'
```

To:

```bash
gem 'redcarpet', '~> 3.3.2'
```

Save the file and run:

```bash
cd /var/www/redmine
gem install rdoc
gem install rdoc-data
rdoc-data --install --verbose
```

Again, we need to include a GEM in our Gemfile: 

```bash
vi /var/www/redmine/Gemfile
```

We need to add this after the last gem (normally, gem "thin"):

```bash
gem "rdoc", ">= 2.4.2"
```

Then we proceed to execute:

```bash
cd /var/www/redmine
bundle install --without postgresql sqlite test development
bundle pack
bundle install --path vendor/cache
RAILS_ENV=production rake redmine:plugins:migrate
bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_git_hosting
```

Also, we need to downgrade rails to 4.2.3 with the following commands:

```bash
cd /var/www/redmine
gem uninstall rails
gem install rails -v=4.2.3
```

And edit (again) the main Gemfile to set rails version to 4.2.3:


```bash
cd /var/www/redmine
vi Gemfile
```

Set:

```bash
gem "rails", "4.2.3"
```

Then:

```bash
cd /var/www/redmine
bundle update rails
bundle update
bundle install --without postgresql sqlite test development
bundle pack
bundle install --path vendor/cache
RAILS_ENV=production rake redmine:plugins:migrate
```

Now, we proceed to run the following commands:

```bash
ln -s /var/www/redmine/plugins/redmine_git_hosting/ssh_keys /var/www/redmine/
chown -R apache.apache /var/www/redmine
sudo -u apache  ssh-keygen -N '' -f /var/www/redmine/ssh_keys/redmine_gitolite_admin_id_rsa
```

And restart thin:

```
/etc/init.d/thin restart
sleep 30
```

We need an user for GIT:

```bash
useradd -c "Git User" -d /var/lib/git-repos -s /bin/bash git
```

And also we need the following directories:

```bash
mkdir -p /var/www/redmine/tmp/redmine_git_hosting/git
mkdir -p /usr/share/httpd/.gitolite/logs

chown -R apache.apache /var/www/redmine/ /usr/share/httpd/.gitolite
chown apache.apache /usr/share/httpd
```

We proceed to "su" to git user:

```bash
su - git
```

And inside the git user, run the following command:

```bash
gitolite setup -pk /var/www/redmine/ssh_keys/redmine_gitolite_admin_id_rsa.pub
```

Still inside the "git" account, we proceed to edit the file:

```bash
vi .gitolite.rc
```

And modify the variables:

```bash
GIT_CONFIG_KEYS  =>  '.*',

LOCAL_CODE       =>  "$ENV{HOME}/local",
```

Save the file, and run "exit" to return to the root account (exit git account):

```bash
exit
```

We proceed to create the sudo file:

```bash
vi /etc/sudoers.d/apacheredmine
```

Containing:

```bash
Defaults:apache !requiretty
apache ALL=(git) NOPASSWD:ALL
```

Then we save the file and set it's proper permissions:

```bash
chmod 440 /etc/sudoers.d/apacheredmine
```

Now, we run the following command and accept the key:

```bash
sudo -u apache ssh -i /var/www/redmine/ssh_keys/redmine_gitolite_admin_id_rsa git@localhost info
```

And run the command:

```bash
chmod 755 /var/lib/git-repos
```

In the `/etc/init.d/thin` file, we need to include "export HOME=/var/lib/git-repos" in the start and restart sections:

```bash
vi /etc/init.d/thin
```

Modifications:

```bash
case "$1" in
  start)
        export HOME=/var/lib/git-repos/
        $DAEMON start --all $CONFIG_PATH
        ;;
  stop)
        $DAEMON stop --all $CONFIG_PATH
        ;;
  restart)
        export HOME=/var/lib/git-repos/
        $DAEMON restart --all $CONFIG_PATH
        ;;
  *)
        echo "Usage: $SCRIPT_NAME {start|stop|restart}" >&2
        exit 3
        ;;
esac
```

Save the file, and restart thin:

```bash
/etc/init.d/thin restart
sleep 30
```

After the restart is completed, with a browser enter to your redmine installation, and configure the plugin. Section: "Administration->Plugins->Redmine Git Hosting Plugin->Configure".

* In the plugin "global" TAB, the path must be set to: /var/www/redmine/tmp/redmine_git_hosting/
* In the plugin "hooks" TAB, the URL must be set to: http://localhost:3000/redmine. Apply the change, and click on "install hooks".
* In the plugin "config test" TAB, ensure all is in the green. If not, you probably missed a step.

Logout and restart thin (again):

```bash
/etc/init.d/thin restart
sleep 30
```

With a browser, log in again to your Redmine, and go to section: "Administration->Settings->Repositories", and ensure ONLY "git" and "Xitolite" are checked.

Next we need to apply a "patch" in order to allow proper access to user_keys panel. We proceed to create the following directory:

```bash
mkdir -p /var/www/html/my/public_keys/
```

And create the file:

```bash
vi /var/www/html/my/public_keys/index.html
```

Containing:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/redmine/my/public_keys">
</HEAD>
<BODY>
</BODY>
</HTML>
```

Then, Save the file. That's it. You have a redmine with git provisioning fully working at this point.


### LDAP Authentication with a MS A/D:

If you are installing this solution in an enterprise, is more than proable you'll want to integrate the redmine authentication with your current active directory or any other ldap you have.

In order to enable A/D-Ldap auth, go to section "Administration -> Authentication Modes", and create a new authentication module, type "LDAP". Set the following data:

* Name: MyCompanyAD **(Name your auth module)**
* Host: 172.16.1.160 **(This is your LDAP Server or MS Domain Controller)**
* Port: 389 **(LDAPS disabled, unless you are really using Secure LDAP)**
* Account: CN=git,OU=Users,OU=SysOps,OU=My Company,DC=mycompany,DC=dom **(This is your BIND account created in the A/D)**
* Password: Account-Password **(The Account Password)**
* Base DN: OU=OU=SysOps,OU=My Company,DC=mycompany,DC=dom **(Your LDAP Search Base)**
* LDAP Filter **(set empty)**
* On-The-Fly user creation: **(Enable it)**
* Login Attribute: sAMAccountName
* First Name Attribute: givenName
* Last Name Attribute: sN
* Mail Attribute: mail

The attributes "sAMAccountName, givenName, sN and mail" are common for most MS-A/D implementations, but, again, adjust those fields according to your actual environment.

END.-
