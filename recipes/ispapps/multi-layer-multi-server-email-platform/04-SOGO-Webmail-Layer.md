# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - SOGO WEBMAIL/GROUPWARE.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Basic Server Setup - Database

SoGo is more than a webmail-access software. It's a complete groupware solution, including calendar, global and local address books, and activesync components which you can use with your smart phone.

SoGo needs 4 external dependencies in order to work:

- An authentication platform (we are using Ldap-based auth against a MS Active Directory).
- A SMTP service for SMTP-Out (with Authentication too).
- A IMAP Service.
- A Database for groupware elements storage.

For the Database, we are going to install it in the server, but, for a more-robust and production/H.A. deployment, you should use a Database Cluster. One of our recipes is perfectly well suited for this task:

* [A MariaDB Multi-master Active/Active Cluster](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/databases/mariadb-cluster-centos7)

In any case, and considering a "single server" deployment, let's install the database software and prepare our database:

Server IP: 172.16.11.98

Install and enable the software:

```bash
yum install mariadb-server mariadb

systemctl start mariadb.service
systemctl enable mariadb.service
```

Execute mysql_secure_installation:

```bash
mysql_secure_installation
```

Our mysql/mariadb root password is: "P@ssw0rd"

Create the file:

```bash
vi /root/.my.cnf
```

Containing:

```bash
[client]
user=root
password=P@ssw0rd
```

Change the file permissions:

```bash
chmod 0600 /root/.my.cnf
```

Then, enter to the engine with the "mysql" command and create our SoGo database:

```bash
mysql

MariaDB [(none)]> CREATE DATABASE `sogo` CHARACTER SET='utf8';
MariaDB [(none)]> CREATE USER 'sogo'@'localhost' IDENTIFIED BY 'Pass2016Mail';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON `sogo`.* TO 'sogo'@'localhost' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;
```

Add the SoGo repo:

```bash
vi /etc/yum.repos.d/SOGo.repo
```

Containing:

```
[sogo-rhel7]
name=Inverse SOGo Repository
baseurl=http://inverse.ca/downloads/SOGo/RHEL7/$basearch
gpgcheck=0
```

Also add RPMFORGE repo:


```bash
yum install http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
```

Edit "rpmforge" repo and activate "extras":

```bash
vi /etc/yum.repos.d/rpmforge.repo
```

```bash
[rpmforge-extras]
name = RHEL $releasever - RPMforge.net - extras
baseurl = http://apt.sw.be/redhat/el7/en/$basearch/extras
mirrorlist = http://mirrorlist.repoforge.org/el7/mirrors-rpmforge-extras
#mirrorlist = file:///etc/yum.repos.d/mirrors-rpmforge-extras
enabled = 1
protect = 0
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag
gpgcheck = 1
```

Force a general server update:

```bash
yum clean all
yum update
```

Then, install SoGo:

```bash
yum install sogo sogo-activesync sogo-ealarms-notify sogo-tool sope49-gdl1-mysql
```

Save SoGo original file, and reconfigure it:

```bash
cd /etc/sogo
cp sogo.conf sogo.conf.ORG

vi sogo.conf
```

Changes:

```bash
{
    SOGoUserSources = (
        {
          CNFieldName = cn;
          IDFieldName = cn;
          UIDFieldName = sAMAccountName;
          baseDN = "dc=domain01,dc=dom";
          bindDN = "cn=correoapp,ou=mailapps,dc=domain01,dc=dom";
          bindFields = (sAMAccountName);
          bindPassword = "Pass2016Mail";
          canAuthenticate = YES;
          displayName = "Shared Addresses";
          hostname = "ldap://172.16.11.63:389/";
          filter = "(mail='*@domain01.dom' OR mail='*@domain02.dom')";
          id = public;
          isAddressBook = YES;
          type = ldap;
        }
    );
    SOGoAppointmentSendEMailNotifications = YES;
    //SOGoSuperUsernames = (sogo3);

    SOGoProfileURL = "mysql://sogo:Pass2016Mail@localhost:3306/sogo/sogo_user_profile";
    OCSFolderInfoURL = "mysql://sogo:Pass2016Mail@localhost:3306/sogo/sogo_folder_info";
    OCSEMailAlarmsFolderURL = "mysql://sogo:Pass2016Mail@localhost:3306/sogo/sogo_alarms_folder";
    OCSSessionsFolderURL = "mysql://sogo:Pass2016Mail@localhost:3306/sogo/sogo_sessions_info";

    SOGoSieveScriptsEnabled = YES;
    SOGoForwardEnabled = YES;
    SOGoVacationEnabled = YES;
    SOGoEnableEMailAlarms = YES;
    //Our Timezone
    SOGoTimeZone = America/Caracas;
    //Our IMAP Server - Port 143 and 4190 (sieve protocol)
    //If you have only one server, put it's IP. If you have
    //multiple servers loadbalanced by LBaaS, put here the LBaaS VIP or FQDN
    SOGoIMAPServer = 172.16.11.96:143;
    //If your LBaaS cannot have multiple ports for a same VIP, create a
    //specific LBaaS VIP for Sieve and use it here:
    SOGoSieveServer = sieve://172.16.11.96:4190;
    SOGoMailingMechanism = smtp;
    SOGoSMTPAuthenticationType = PLAIN;
    SOGoForceExternalLoginWithEmail = NO;
    SOGoMailSpoolPath = /var/spool/sogo;
    NGImap4ConnectionStringSeparator = "/";
    //Your SMTP-OUT Server. Again, if you have a single server, put it's IP here, but
    //if you have your layer behind a LBaaS, put the LBaaS VIP or FQDN:
    SOGoSMTPServer = 172.16.11.95;
    SOGoMailDomain = domain01.dom;

    SOGoDraftsFolderName = Drafts;
    SOGoSentFolderName = Sent;
    SOGoTrashFolderName = Trash;
    SxVMemLimit = 1024;
    SOGoMemcachedHost = 127.0.0.1;
    WOPidFile = "/var/run/sogo/sogo.pid";

    /* Web Interface */
    SOGoPageTitle = MYCOMPANY-MAIL-WEB-ACCESS;
    SOGoVacationEnabled = YES;
    SOGoForwardEnabled = YES;
    SOGoSieveScriptsEnabled = YES;
    
    SOGoCalendarDefaultRoles = ("PublicDAndTViewer");
    /* Debugging */
    //LDAPDebugEnabled = YES;
    //MySQL4DebugEnabled = YES;
    //OCSFolderManagerSQLDebugEnabled = YES;
    //PGDebugEnabled = YES;
    //SOGoDebugRequests = YES;
    //WODebugTakeValues = YES;
    //SOGoUIxDebugEnabled = YES;
    //SaxDebugReaderFactory = YES;
    //SaxObjectDecoderDebugEnabled = YES;
    //SoDebugObjectTraversal = YES;
    //SoSecurityManagerDebugEnabled = YES;
    //VSSaxDriverDebugEnabled = YES;
    //WODebugResourceLookup = YES;
    //WEResourceManagerDebugEnabled = YES;
    //WEResourceManagerComponentDebugEnabled = YES;
}
```

Save the file and edit the following:

```bash
vi /etc/sysconfig/sogo
```

Modify the following value:

```bash
PREFORK=20
```

Save the file, and start/enable the services:

```bash
systemctl enable sogod
systemctl start sogod
systemctl enable memcached
systemctl start memcached
```

We need to perform some changes in the SoGo apache config:

```bash
vi /etc/httpd/conf.d/SOGo.conf
```
Uncomment the activesync section:

```bash
ProxyPass /Microsoft-Server-ActiveSync \
 http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync \
 retry=60 connectiontimeout=5 timeout=360
```

La sección para el proxy del servicio debe quedar:
Modify proxy section. Your section must be set as follows:

```bash
<Proxy http://127.0.0.1:20000/SOGo>
## adjust the following to your configuration
  # RequestHeader set "x-webobjects-server-port" "443"
  RequestHeader set "x-webobjects-server-port" "80"
  # RequestHeader set "x-webobjects-server-name" "yourhostname"
  # RequestHeader set "x-webobjects-server-url" "https://yourhostname"

## When using proxy-side autentication, you need to uncomment and
## adjust the following line:
  RequestHeader unset "x-webobjects-remote-user"
#  RequestHeader set "x-webobjects-remote-user" "%{REMOTE_USER}e" env=REMOTE_USER
  RequestHeader set "x-webobjects-remote-host" %{REMOTE_HOST}e env=REMOTE_HOST
  RequestHeader set "x-webobjects-server-protocol" "HTTP/1.0"

  AddDefaultCharset UTF-8

  Order allow,deny
  Allow from all
</Proxy>
```

Save the changes, and enable/start apache:

```bash
systemctl enable httpd
systemctl restart httpd
```

Create the following file:

```bash
vi /var/www/html/index.html

```

Containing:

```html
<HTML>
<HEAD>
<META HTTP-EQUIV="refresh" CONTENT="0;URL=/SOGo">
</HEAD>
<BODY>
</BODY>
</HTML>
```

And save the file.

Then, your sogo is ready !


## SOGO Notes for LBaaS deployments:

When configuring a LBaaS for SoGo, use "weighted least connections" and ensure "session persistence" based on source IP.

END.-

