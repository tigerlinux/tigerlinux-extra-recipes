# A SQUID INSTALLATION WITH STEROIDS (C-ICAP/SQUIDCLAMAV/SQUIDGUARD) ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to install a Squid proxy services on Centos 7, and enable extra features for site-blocking and virus scanning.


## What kind of hardware and software do we need ?:

A Centos 7 machine with [EPEL repository](https://fedoraproject.org/wiki/EPEL) installed. Fully updated. SELinux and FirewallD disabled.


## How it was constructed the whole solution ?:

### Server basic requeriments:

As mentioned before, ensure your Centos 7 server has [EPEL repository](https://fedoraproject.org/wiki/EPEL) enabled and available, and **SELinux/FirewallD are disabled**.

Our machine FQDN is: vm-172-16-11-70.mydomain.dom

Install the following dependencies:

```bash
yum -y groupinstall core
yum -y groupinstall base
yum -y install cpp gcc make automake autoconf kernel-devel kernel-headers
```


### Squid installation:

Install squid, but do not enable yet:

```bash
yum -y install squid
```


### Clamav installation and configuration:

Install clamav support:

```bash
yum -y install clamav-server clamav-server-systemd clamav-update
cp /usr/share/doc/clamav-server*/clamd.conf /etc/clamd.d/squid.conf
```

Edit the file:

```bash
vi /etc/clamd.d/squid.conf
```

And change the following items:

Comment:

```bash
# Example
```

Change:

```bash
LogFile /var/log/clamd.squid
PidFile /var/run/clamd.squid/clamd.pid
TemporaryDirectory /var/tmp 
DatabaseDirectory /var/lib/clamav
LocalSocket /var/run/clamd.squid/clamd.sock
TCPSocket 3310
User squidclamav
```

Save the file.

Run the following commands:

```bash
useradd -M -d /var/tmp -s /sbin/nologin squidclamav
mkdir /var/run/clamd.squid
chown squidclamav.squidclamav /var/run/clamd.squid
cp /usr/share/doc/clamav-server*/clamd.sysconfig /etc/sysconfig/clamd.squid
```

Edit the file:

```bash
vi /etc/sysconfig/clamd.squid 
```

Uncomment/Change:

```bash
CLAMD_CONFIGFILE=/etc/clamd.d/squid.conf
CLAMD_SOCKET=/var/run/clamd.squid/clamd.sock
```

Save the file.

Create the file:

```bash
vi /etc/tmpfiles.d/clamd.squid.conf
```

Containing:

```bash
d /var/run/clamd.squid 0755 squidclamav squidclamav -
```

Edit the file:

```bash
vi /usr/lib/systemd/system/clamd@.service
```

Add at the end:

```bash
[Install]
WantedBy=multi-user.target
```

Save the file and run the following commands:

```bash
touch /var/log/clamd.squid
chown squidclamav.squidclamav /var/log/clamd.squid
chmod 600 /var/log/clamd.squid
systemctl start clamd@squid
systemctl enable clamd@squid
systemctl status clamd@squid
```

Now, we need to update the antivirus database. Edit the file:

```bash
vi /etc/freshclam.conf
```

Change/Comment/Update:

```bash
# Example
DatabaseDirectory /var/lib/clamav
NotifyClamd /etc/clamd.d/squid.conf
```

Save the file and run:

```bash
freshclam
```

Create the following logrotate file:

```bash
vi /etc/logrotate.d/clamdsquid
```

Containing:

```bash
/var/log/clamd.squid {
    weekly
    rotate 5
    compress
    notifempty
    missingok
    sharedscripts
    create 600 squidclamav squidclamav
    postrotate
        killall -HUP clamd 2>/dev/null || :
    endscript
}
```

**NOTE:** The "clamav-update" package include a crontab that will keep your virus-signatures fully updated.


### C-Icap installation:

Download c-icap sources and compile it:

```bash
mkdir /workdir
cd /workdir
wget https://sourceforge.net/projects/c-icap/files/c-icap/0.4.x/c_icap-0.4.3.tar.gz/download -O /workdir/c_icap-0.4.3.tar.gz
tar -xzvf c_icap-0.4.3.tar.gz -C /usr/local/src/
cd /usr/local/src/c_icap-0.4.3/
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install
```

Edit the main configuration file:

```bash
vi /etc/c-icap.conf
```

And change/update/comment the following values:

```bash
# use the actual admin e-mail
ServerAdmin admin@mydomain.dom
# use the actual fqdn of your server
ServerName vm-172-16-11-70.mydomain.dom
LoadMagicFile /etc/c-icap.magic
ModulesDir /usr/lib/c_icap
ServicesDir /usr/lib/c_icap
TemplateDir /usr/share/c_icap/templates/
ServerLog /var/log/c-icap/server.log
AccessLog /var/log/c-icap/access.log
```

Search for the line:

```bash
Service echo srv_echo.so
```

Add below:

```bash
Service squidclamav squidclamav.so
```

Save the file.

Next, we need to create the systemd unit support file:

Create the file:

```bash
vi /etc/tmpfiles.d/c-icap.conf
```

Containing:

```bash
d /var/run/c-icap 0755 root root -
```

Save the file, and create the next one.

```bash
vi /usr/lib/systemd/system/c-icap.service
```

Containing:

```bash
[Unit]
Description=c-icap service
After=network.target

[Service]
Type=forking
PIDFile=/var/run/c-icap/c-icap.pid
ExecStart=/usr/bin/c-icap -f /etc/c-icap.conf
KillMode=process

[Install]
WantedBy=multi-user.target
```

Save the file and create the following directory:

```bash
mkdir /var/log/c-icap
```

Create the following logrotate file:

```bash
vi /etc/logrotate.d/c-icap
```

Containing:

```bash
/var/log/c-icap/*.log {
    weekly
    rotate 5
    compress
    notifempty
    missingok
    sharedscripts
    postrotate
        killall -HUP clamd 2>/dev/null || :
        killall -HUP c-icap 2>/dev/null || :
    endscript
}
```


### SquidClamav installation and configuration:

Download the squidclamav sources, compile and install:

```bash
cd /workdir
wget https://sourceforge.net/projects/squidclamav/files/squidclamav/6.15/squidclamav-6.15.tar.gz/download -O /workdir/squidclamav-6.15.tar.gz
tar -xzvf squidclamav-6.15.tar.gz -C /usr/local/src/
cd /usr/local/src/squidclamav-6.15/
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install
ldconfig -v
```

For any virus encountered by the squid-cicap-squidclamav combo, we need to provide an error-redirect page. This need's apache installed on the server:

```bash
yum -y install httpd
systemctl enable httpd
systemctl start httpd
echo "ERROR: Virus Detected" > /var/www/html/virus-detected.html
```

Those simple steps will create a "Virus Detected" page in your server (http://vm-172-16-11-70.mydomain.dom/virus-detected.html). Next, we need to configure squidclamav:

```bash
vi /etc/squidclamav.conf
```

Change:

```bash
redirect http://vm-172-16-11-70.mydomain.dom/virus-detected.html
clamd_local /var/run/clamd.squid/clamd.sock
whitelist .*\.clamav.net
```

**NOTE:** Adjust the http redirect URL according to the FQDN or IP of your server.

Save the file.


### Squid Configuration:

Edit the file:

```bash
vi /etc/squid/squid.conf
```

And add to the end of the file:

```bash
#
# C-ICAP/Squidclamav config:
icap_enable on
icap_send_client_ip on
icap_send_client_username on
icap_client_username_header X-Authenticated-User
icap_service service_req reqmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_req allow all
icap_service service_resp respmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_resp allow all
```

Save the file and enable/start the services:

```bash
systemctl start c-icap
systemctl enable c-icap
systemctl start squid
systemctl enable squid
systemctl status c-icap
systemctl status squid
```

At this point, you have a fully-working SQUID installation with **Clamav-Virus-Scanner support**.

You can test the Squid/SquidClamav/C-Icap combo doing it's job by configuring any browser to use your proxy, and try to download the EICAR test virus from the site:

* [EICAR Virus Test File](http://www.eicar.org/85-0-Download.html)


### SquidGuard integration.

Now, we need to integrate SquidGuard with our installation.

First, install the packages:

```bash
yum -y install squidGuard 
```

**NOTE:** SquidGuard packages are part of EPEL repository.

Backup your original config:

```bash
mv /etc/squid/squidGuard.conf /etc/squid/squidGuard.conf.ORG
```

And create a new one:

```bash
vi /etc/squid/squidGuard.conf
```

Containing:

```bash
# Squidguard Config
# TigerLinux AT gmail DOT com
# based on other examples from the Internet
#

### Path configuration
dbhome /var/lib/squidguard
logdir /var/log/squidGuard

#
# Extra groups

dest redirector {
        logfile redirector.log

        domainlist      redirector/domains
        urllist         redirector/urls
}

dest spyware {
        logfile spyware.log

        domainlist      spyware/domains
        urllist         spyware/urls
}

dest suspect {
        logfile suspect.log

        domainlist      suspect/domains
        urllist         suspect/urls
}

### Generated blacklist definitions
### Group 'ads' containing entries for 'ads, publicite'
dest ads {
	logfile ads.log

	domainlist	ads/domains
	urllist		ads/urls
}

### Group 'adult' containing entries for 'adult, porn'
dest porn {
	logfile porn.log

	domainlist	porn/domains
	urllist		porn/urls
}

### Group 'aggressive' containing entries for 'aggressive, agressif'
dest aggressive {
	logfile aggressive.log

	domainlist	aggressive/domains
	urllist		aggressive/urls
}

### Group 'audio-video' containing entries for 'audio-video'
dest audio-video {
	logfile audio-video.log

	domainlist	audio-video/domains
	urllist		audio-video/urls
}

### Group 'drugs' containing entries for 'drugs, drogue'
dest drugs {
	logfile drugs.log

	domainlist	drugs/domains
	urllist		drugs/urls
}


### Group 'gambling' containing entries for 'gambling'
dest gambling {
	logfile gambling.log

	domainlist	gambling/domains
	urllist		gambling/urls
}

### Group 'hacking' containing entries for 'hacking'
dest hacking {
	logfile hacking.log

	domainlist	hacking/domains
	urllist		hacking/urls
}

### Group 'mail' containing entries for 'mail'
dest mail {
	logfile mail.log

	domainlist	mail/domains
}

### Group 'proxy' containing entries for 'proxy, redirector, strict_redirector'
dest proxy {
	logfile proxy.log

	domainlist	proxy/domains
	urllist		proxy/urls
}

### Group 'violence' containing entries for 'violence'
dest violence {
	logfile violence.log

	domainlist	violence/domains
	urllist		violence/urls
}

### Group 'warez' containing entries for 'warez'
dest warez {
	logfile warez.log

	domainlist	warez/domains
	urllist		warez/urls
}

### Define your local blacklists here
#dest bad {
#	logfile localbad.log
#
#	domainlist	local/bad/domains
#	urllist		local/bad/urls
#	expressionlist	local/bad/expressions
#}

#dest good {
#	domainlist	local/good/domains
#	urllist		local/good/urls
#	expressionlist	local/good/expressions
#}

### ACL definition
acl {
	default {
		#pass good !bad !adult !aggressive !hacking !warez !porn !redirector !spyware !suspect any
		pass !aggressive !hacking !warez !porn !redirector !spyware !suspect any
		redirect http://vm-172-16-11-70.mydomain.dom/blocked-content.html
	}
}
```

Save the file.

We need to create our redirect file:

```bash
echo "ALERT: Blocked Content Site Detected" > /var/www/html/blocked-content.html
```

Create the signatures directory:

```bash
mkdir /var/lib/squidguard
```

Create the following script. This script will do the update part:

```bash
vi /usr/local/bin/squidguard-update-db.sh
```

Containing:

```bash
#!/bin/bash
# SquidGuard update file.
# Reynaldo R. Martinez P.
# TigerLinux@Gmail.com
# http://squidguard.mesd.k12.or.us/blacklists.tgz
#

# Some basic variables first
PATH=$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin
updatefilesource="http://squidguard.mesd.k12.or.us/blacklists.tgz"

#
# Basic Cleanup Firts
#

date > /var/log/squidguard-db-update.log

rm -f /var/tmp/blacklists.tgz
rm -Rf /var/tmp/blacklists/

cd /var/tmp
wget $updatefilesource -O /var/tmp/blacklists.tgz >> /var/log/squidguard-db-update.log

if [ -f /var/tmp/blacklists.tgz ]
then
	tar -xzvf /var/tmp/blacklists.tgz -C /var/tmp/ >> /var/log/squidguard-db-update.log
else
	echo "Download Failed"
	echo "Blacklist Download Failed" >> /var/log/squidguard-db-update.log
	exit 0
fi

cd /var/tmp/blacklists
rsync -avzr * /var/lib/squidguard/ >> /var/log/squidguard-db-update.log
squidGuard -C all >> /var/log/squidguard-db-update.log
chown -R squid.squid /var/lib/squidguard
chown -R squid.squid /var/log/squidGuard

cd /

systemctl restart c-icap >> /var/log/squidguard-db-update.log
systemctl restart squid >> /var/log/squidguard-db-update.log

rm -f /var/tmp/blacklists.tgz >> /var/log/squidguard-db-update.log
rm -fR /var/tmp/blacklists/ >> /var/log/squidguard-db-update.log
```

Set exec permissions on the file:

```bash
chmod 755 /usr/local/bin/squidguard-update-db.sh
```

And run it the first time:

```bash
/usr/local/bin/squidguard-update-db.sh
```

This will download the squidguard blacklist from the url: http://squidguard.mesd.k12.or.us/blacklists.tgz and rsync the blacklist to the squidguard database location.

Next, we need to include squidguard into squid. Edit the squid config file:

```bash
vi /etc/squid/squid.conf
```

Add at the end:

```bash
url_rewrite_program /usr/bin/squidGuard
```

Set some permissions:

```bash
chown -R squid.squid /var/lib/squidguard
chown -R squid.squid /var/log/squidGuard
```

And restart squid:

```bash
systemctl restart squid
```

Last thing we need to do, is to include our updater script into a crontab:

```bash
vi /etc/cron.d/squidguard.crontab
```

Containing:

```bash
# Update SquidGUARD lists
15 02 * * * root /usr/local/bin/squidguard-update-db.sh
```

And restart your crontab:

```bash
systemctl restart crond
```

At this point, you'll have a ready-to-go Squid, with antivirus protection and blacklist's and proper crontabs for both blacklist and virus-signatures updates.


### OPTIONAL: Statistics generator for Squid.

This is optional and up to you: Statistics generation based on [SARG](https://sourceforge.net/projects/sarg/).

First, install some dependencies:

```bash
yum install -y gcc gd gd-devel perl-GD wget pcre pcre-devel
```

Download SARG sources:

```bash
cd /workdir
wget https://sourceforge.net/projects/sarg/files/sarg/sarg-2.3.10/sarg-2.3.10.tar.gz/download -O /workdir/sarg-2.3.10.tar.gz
```

Compile and install:

```bash
tar -xzvf /workdir/sarg-2.3.10.tar.gz -C /usr/local/src/
cd /usr/local/src/sarg-2.3.10/
autoreconf -fi
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install
```

**NOTE:** The `autoreconf -fi` is vital in order to fix some "gettext" version mismatchs between the source and the OS.

After the installation is done, we need to configure "sarg" for our SQUID installation:

Edit the file:

```bash
vi /etc/sarg.conf
```

Change/Update/Uncomment:

```bash
access_log /var/log/squid/access.log
output_dir /var/www/html/squid-reports
date_format e
index yes
overwrite_report yes
squidguard_conf /etc/squid/squidGuard.conf
```

**NOTE:** Explore all options in `/etc/sarg.conf` file for further customize your SARG installation.

Save the file and create the following dir:

```bash
mkdir /var/www/html/squid-reports
```

In order to make things safer, we'll create an Apache definition with http simple auth:

Create the file:

```bash
vi /etc/httpd/conf.d/squidreports.conf
```

Containing:

```bash
Alias /squid-reports /var/www/html/squid-reports

<Location /squid-reports>
	AuthType Basic
	AuthName "Squid Reports"
	AuthUserFile /var/www/squidreports.htpasswd
	Require valid-user
</Location>
```

Save the file, and run the following command in order to create your user and set it's password:

```bash
htpasswd -c /var/www/squidreports.htpasswd sarg
```

**NOTE:** For our LAB, we set the user "sarg" with password "P@ssw0rd".

Next, reload or restart apache:

```bash
systemctl restart httpd
```

Let's generate our very first report:

```bash
/usr/bin/sarg -x
```

You can enter with any browser to the SARG URL in your server (remember it will ask for authentication):

> http://SERVER_IP_OR_FQDN/squid-reports

The final task, is create our crontab:

```bash
vi /etc/cron.d/sarg.crontab
```

Containing:

```bash
# Update SARG reports
05 */1 * * * root /usr/bin/sarg -x > /var/log/last-sarg-run.log 2>&1
```

And, restart/reload your crontab:

```bash
systemctl restart crond
```

Every hour at the "05" minute, sarg will regenerate your reports.


## Extra notes for production systems:

* Re-enable your firewall (firewalld) and enable the squid port (3128 tcp). If you change your squid port, change your firewall-d definition.
* You can do some fine-tunning in your squidguard config file in order to extend the ACL's for your administrator, and/or include working-hours and disable access completelly to ordinary users and non-working hours. Also, you can include your own blacklists (and white lists).
* This solution can be very deployed in a cloud. Think of a "proxy-in-the-cloud" solution, which you can even horizontally load-balance using common load-balancers in the cloud (AWS Elastic Load Balancer or OpenStack LBaaS).

END.-
