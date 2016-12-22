# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - POP-IMAP-SMTP-DELIVERY LAYER

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Basic Server setup 

The server (or servers) located in this service layer will receive all mail comming from the SMTP-Incomming layer, and also will serve MAILBOX operations trough POP/IMAP protocols.

Server IP: 172.16.11.96

First, we proceed to mount our NFS resource:

```bash
mkdir /MAILBOXES

echo "172.16.11.57:/NFSVOL	/MAILBOXES	nfs	rw,auto,intr,async,rsize=32768,wsize=32768,hard,fg,lock,vers=3,tcp,nordirplus  0 0" >> /etc/fstab

mount /MAILBOXES

mkdir /MAILBOXES/C7
```

By using NFS, we can have multiple servers, all pointed to the same resource. This is a common setup in most POP/IMAP multi-server installations.


## Dovecot Setup for POP-IMAP.

The core of our POP-IMAP-SMTP-Delivery layer is the "Dovecot" suite. We proceed to install the packages:

```bash
yum install dovecot dovecot-pigeonhole clucene-core
```

We proceed to create the user for our virtual mailboxes. In a multi-server setup, this user must have the same UID/GID along all servers:

```bash
groupadd -g 5000 vmail
useradd -m -u 5000 -g 5000 -G mail -s /bin/bash -d /var/vmail -c "DoveCot MAILBOXES User" vmail
```
mv /var/vmail /MAILBOXES/C7/

ln -s /MAILBOXES/C7/vmail /var/vmail

chown -R vmail:vmail /var/vmail /MAILBOXES/C7/vmail
```

We backup the original dovecot config file and reset it's original contents:

```bash
cd /etc/dovecot
cp dovecot.conf dovecot.conf.ORG
> dovecot.conf
```

Then, we edit the file:

```bash
cd /etc/dovecot
vi dovecot.conf
```

New contents:

```bash
#
# NEW DOVECOT CONFIGURATION
#

postmaster_address=root@example.com

# AUTH
disable_plaintext_auth = no
auth_master_user_separator = *
auth_mechanisms = plain

#
# NFS
# The following settings are mandatory in dovecot for a multi-server setup
# with NFS storage
#
mmap_disable = yes
mail_fsync = always
mail_nfs_storage = yes
mail_nfs_index = yes
#
#
# master users
passdb {
  driver = passwd-file
  master = yes
  args = /etc/dovecot/master-users
}
#
# ldap users
passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-mycompany.conf.ext
}
#
userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-mycompany.conf.ext
}
#
# trust on 127.0.0.1
passdb {
 driver = static
 args = nopassword=y allow_nets=127.0.0.1/32
}
#
# LOGGING
# Change auth_verbose to yes in order to diagnose common auth problems
auth_verbose = no
mail_debug = no
plugin {
  # Events to log. Also available: flag_change append
  #mail_log_events = delete undelete expunge copy mailbox_delete mailbox_rename
  # Available fields: uid, box, msgid, from, subject, size, vsize, flags
  # size and vsize are available only for expunge and copy events.
  #mail_log_fields = uid box msgid size
}
#
# MAIL and NAMESPACES
mail_location = maildir:~/maildir
mail_uid = vmail
mail_gid = vmail
mail_plugins = acl quota fts fts_lucene
#
namespace {
  type = private
  separator = /
  prefix =
  inbox = yes
  mailbox INBOX {
    auto = create
  }
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Junk {
    auto = subscribe
    special_use = \Junk
  }
  mailbox Trash {
    auto = subscribe
    special_use = \Trash
  }
  mailbox Sent {
    auto=subscribe
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    auto=subscribe
    special_use = \Sent
  }
}
#
namespace {
  type = shared
  separator = /
  prefix = shared/%%u/
  location = maildir:%%h/maildir:INDEX=~/maildir/shared/%%u
  subscriptions = no
  list = children
}
#
# MASTER
service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }
  # this is suboptimal since imap and imaps will also accept nopass
  inet_listener imap-nopass {
    port = 144
  }
}
service pop3-login {
  inet_listener pop3 {
    #port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}
service lmtp {
  unix_listener lmtp {
    #mode = 0666
  }
  # Create inet listener only if you can't use the above UNIX socket
  inet_listener lmtp {
    # Avoid making LMTP visible for the entire internet
    address = 127.0.0.1
    port = 24
  }
}
#
service imap {
  executable = imap postlogin
}
service auth {
  # auth_socket_path points to this userdb socket by default. It's typically
  # used by dovecot-lda, doveadm, possibly imap process, etc. Its default
  # permissions make it readable only by root, but you may need to relax these
  # permissions. Users that have access to this socket are able to get a list
  # of all usernames and get results of everyone's userdb lookups.
  unix_listener auth-userdb {
    mode = 0660
    user = root
    group = vmail
  }
}
service postlogin {
  executable = script-login -d rawlog
  unix_listener postlogin {
  }
}
#
# SSL/TLS support: yes, no, required. <doc/wiki/SSL.txt>
ssl = no
#ssl_cert = </etc/ssl/certs/dovecot.pem
#ssl_key = </etc/ssl/private/dovecot.pem
#
# LDA
# This is the delivery service.
# Adjust your policy considering the following tips:
# using "quota_full_tempfail=yes" will generate a "Overquota NDR" message
# immediately if the user is in overcuota
# Using "no" will allow the mail to "queue" until the user frees some space
# or the queue max time expires. If the queue max time expires, then, a NDR
# message will be generated.
#
# quota_full_tempfail = yes
quota_full_tempfail = no
protocol lda {
  # Space separated list of plugins to load (default is global mail_plugins).
  #mail_plugins = $mail_plugins
}
#
# PROTOCOLS
protocol imap {
  mail_plugins = $mail_plugins autocreate imap_acl imap_quota
}
protocol lmtp {
  mail_plugins = $mail_plugins sieve
}
#
protocols = $protocols sieve
#
# We are using "sieve" protocol for the advanced filtering features
# provided by common webmail platforms.
service managesieve-login {
  inet_listener sieve {
    port = 4190
    #address = 127.0.0.1
  }
}
service managesieve {
}
protocol sieve {
}
#
plugin {
  quota = maildir:User quota
  acl = vfile
  acl_shared_dict = file:/var/vmail/shared-mailboxes.db
  #
  quota_rule = *:storage=2G:messages=100000
  quota_rule2 = Trash:storage=+100M
  quota = dict:::file:%h/dovecot-quota
  #
  sieve = ~/.dovecot.sieve
  sieve_dir = ~/sieve
  #
  # Sieve Global Filter
  sieve_global_path = /etc/dovecot/sieve/default.sieve
  sieve_global_dir = /etc/dovecot/sieve/
  # End Sieve Global Filter
  #
  # autocreate = Trash
  # autosubscribe = Trash
  # autocreate2 = Drafts
  # autosubscribe2 = Drafts
  # autocreate3 = Sent
  # autosubscribe3 = Sent
  #
  # For Sieve Global JUNK Filter
  # autocreate4 = Junk
  # autosubscribe4 = Junk
  # End Sievel Global JUNK Filter
  #
  # FTS Support:
  fts = lucene
  fts_lucene = whitespace_chars=@.
  fts_autoindex = yes
}
```

Save the file

Next, create the sieve filter directory:

```bash
mkdir /etc/dovecot/sieve/
```

And the file:

```bash
vim /etc/dovecot/sieve/default.sieve
```

Containing:

```bash
require "fileinto";
if exists "X-Spam-Flag" {
	if header :contains "X-Spam-Flag" "NO" {
		} else {
	fileinto "Junk";
		stop;
	}
}
if header :contains "subject" ["***SPAM***"] {
	fileinto "Junk";
	stop;
}
```

Save the file and run the following commands:

```bash
chown -R vmail:vmail /etc/dovecot/sieve
sievec /etc/dovecot/sieve/default.sieve
```

This filter will enforce the following policy: Any "marked-as-a-spam" mail comming from the SMTP-Incomming layer, will be transfered to the "Junk" folder in the user mailbox.

Change to dovecot directory:

```bash
cd /etc/dovecot
```

And create the file:

```bash
vi dovecot-ldap-mycompany.conf.ext
```

Containing:

```bash
hosts = 172.16.11.63:389
dn = cn=correoapp,ou=mailapps,dc=domain01,dc=dom
dnpass = Pass2016Mail
tls = no
ldap_version = 3
base = dc=domain01,dc=dom
auth_bind = yes
# user_attrs = sAMAccountName=home=/var/vmail/%$,=quota_rule=*:bytes=%{ldap:info}
user_attrs = sAMAccountName=home=/var/vmail/%1M$/%2.1M$/%$,=quota_rule=*:bytes=%{ldap:info}
pass_filter = (|(&(sAMAccountName=%n)(mail=%n@domain01.dom))(&(sAMAccountName=%n)(mail=%n@domain02.dom)))
user_filter = (|(&(sAMAccountName=%n)(mail=%n@domain01.dom))(&(sAMAccountName=%n)(mail=%n@domain02.dom)))
```

Save the file.

**PLEASE Note something here:** We are using a survival technique here: Directory Hashing. Normally, your mailboxes will live in the same directory:

```bash
/MAILBOXES/C7/vmail/user01
/MAILBOXES/C7/vmail/user02
/MAILBOXES/C7/vmail/user03
```

This can be OK for a few users, but, for... let's say... millions of users... this will impose a severe performance penalty on "dir stats" operations in your mailbox NFS storage. With directory hashing, you'll have instead:

```bash
/MAILBOXES/C7/vmail/r/s/N/user01
/MAILBOXES/C7/vmail/5/B/j/user02
/MAILBOXES/C7/vmail/m/7/D/user03
```

Basically this creates some extra directory layers, preventing a lot of entries in the same directory space.

**ABOUT THE Mailbox Quota:** We are using LDAP quota here (=quota_rule=*:bytes=%{ldap:info}). For this to work, we are using "Active Directory" "info" LDAP attribute. Ensure your mail users will have this attribute set to the actual quota in bytes. This will allow your per-user quotas in your mail platform.

Next, run the following commands:

```bash
touch /var/log/dovecot.message
chown vmail:mail /var/log/dovecot.message
touch /etc/dovecot/master-users

systemctl restart dovecot
```

At this point, POP-IMAP is ready to go. You can add the server (or servers if you did this in many servers) to your LBaaS access points (pools) for POP and IMAP.


## Dovecot Setup with POSTFIX for SMTP-Delivery (LDA Service).

Install postfix, erase sendmail, and reinstall postfix:

```bash
yum install postfix
yum erase sendmail-*
yum reinstall postfix
```

Change to the postfix dir, stop the service, backup the original config, and reset it:

```bash
cd /etc/postfix
systemctl stop postfix
cp main.cf main.cf.ORG
> main.cf
```

Edit the configuration:

```bash
vi main.cf
```

New contents:

```bash
#
# POSTFIX CONFIG FOR LDA-POP-IMAP LAYER (POP-IMAP-SMTP-Delivery).
#
smtpd_banner = $myhostname ESMTP $mail_name (MYCOMPANY Mail System)
biff = no
#
# appending .domain is the MUA's job.
append_dot_mydomain = no
#
# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h
#
readme_directory = no
#
#
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
#
# Set the following variable to the server fqdn in the cloud:
myhostname = vm-172-16-11-96.cloud0.hc.mycompany.dom
#
# Alias maps.. all LDAP:
alias_maps = ldap:/etc/postfix/aliases-mycompany.ldap
alias_database = ldap:/etc/postfix/aliases-mycompany.ldap
# myorigin = /etc/mailname
# Set "mydomain" to your primary domain:
mydomain = domain01.dom
mydestination = localhost, $myhostname, $mydomain, domain02.dom
#
# NDR's trough SMTP-OUT
#
# Set here your SMTP-Outgoing IP or LBaaS FQDN In the cloud DNS Space:
# You can use the LBaaS VIP too, or if you have only one SMTP-Out server
# put it's IP like this sample:
relayhost = 172.16.11.95
# In normal production conditions, put the LBaaS VIP or DNS FQDN !.
#
# Set your mail networks here - only server networks
mynetworks = 127.0.0.0/8, 172.16.10.0/24, 172.16.11.0/24
#
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
# More LDAP maps.
virtual_alias_maps = ldap:/etc/postfix/aliases-mycompany.ldap
virtual_mailbox_maps = ldap:/etc/postfix/people-mycompany.ldap
local_recipient_maps = ldap:/etc/postfix/people-mycompany.ldap $alias_maps
#
# This is where postfix send the e-mail to dovecot LDA service:
mailbox_transport = lmtp:127.0.0.1:24
# Main queue directory.
# This is an important point. Ensure you have proper disk space for your queuing needs.
queue_directory = /var/spool/postfix
#
# Tweaks for protection and performance
#
smtpd_recipient_limit = 200
message_size_limit = 26214400
smtpd_error_sleep_time = 1s
smtpd_soft_error_limit = 10
smtpd_hard_error_limit = 20
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 60
default_process_limit = 200
#
# Queue Control and Bouncing
#
bounce_queue_lifetime = 1d
maximal_queue_lifetime = 1d
soft_bounce = no
#
#
# Add missing headers, specially "from" address
always_add_missing_headers = yes
#
#
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
#
# END.-
#
```

Save the file, and run the following command:

```bash
echo "domain01.dom" > /etc/mailname
```

In the same directory, create the LDAP maps:

```bash
vi people-mycompany.ldap
```

Containing:

```bash
version = 3
server_port = 389
timeout = 60
search_base = dc=domain01,dc=dom
query_filter = (|(&(objectClass=person)(mail=%s)(mail=*@domain01.dom))(&(objectClass=person)(mail=%s)(mail=*@domain02.dom)))
result_attribute = cn
bind = yes
bind_dn = cn=correoapp,ou=mailapps,dc=domain01,dc=dom
bind_pw = Pass2016Mail
server_host = ldap://172.16.11.63:389/
```

Save the file, and next:

```bash
vi aliases-mycompany.ldap
```

Containing:

```bash
version = 3
server_port = 389
timeout = 60
search_base = dc=domain01,dc=dom
query_filter = (|(&(objectClass=group)(mail=%s)(mail=*@domain01.dom))(&(objectClass=group)(mail=%s)(mail=*@domain02.dom)))
special_result_attribute = member
leaf_result_attribute = mail
bind = yes
bind_dn = cn=correoapp,ou=mailapps,dc=domain01,dc=dom
bind_pw = Pass2016Mail
server_host = ldap://172.16.11.63:389/
```

Save the file, and enable/start postfix and enable dovecot:

```bash
systemctl start postfix
systemctl enable postfix
systemctl enable dovecot
```

At this point, our POP-IMAP-SMTP-Delivery layer is ready.

As a extra note, you can update your postfix to 2.11 series by using the following command:

```bash
yum update http://repos.oostergo.net/7/postfix-2.11/postfix-2.11.8-1.el7.centos.x86_64.rpm
```

This step is optional

END.-

