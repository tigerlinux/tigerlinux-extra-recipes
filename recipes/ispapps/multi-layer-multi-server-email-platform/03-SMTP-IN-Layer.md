# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - SMTP-INCOMMING LAYER

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Basic POSTFIX Setup.

The server (or servers) located in this service layer will receive all mail comming from the Internet, and apply to those mails antivirus/antispam policies in order to discard (or tag) bad mail, and, forward all surviving mail to the POP-IMAP-SMTP-Delivery layer.

Server IP:172.16.11.97

First, ensure postfix is installed and sendmail not:

```bash
yum erase sendmail-*
yum install postfix
yum reinstall postfix
yum install telnet
```

Change to postfix directory, stop postfix, backup the config and reset it:

```bash
cd /etc/postfix
systemctl stop postfix
cp main.cf main.cf.ORG
> main.cf
```

Edit the config:

```bash
vi main.cf
```

New contents:

```
#
# SMTP-IN CONFIGURATION FILE
#
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
# Again, set this to the actual server fqdn:
myhostname = vm-172-16-11-97.cloud0.hc.mycompany.dom
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
# Set it to your primary domain
mydomain = domain01.dom
myorigin = $myhostname
mydestination = $myhostname, localhost.$mydomain, localhost
relayhost =
# Set your mail networks here - only server networks
mynetworks = 127.0.0.0/8, 172.16.10.0/24, 172.16.11.0/24
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
# Set your domains here:
relay_domains = domain01.dom domain02.dom
# LDAP Map:
relay_recipient_maps = ldap:/etc/postfix/people-mycompany.ldap
inet_protocols = all
queue_directory = /var/spool/postfix
transport_maps = hash:/etc/postfix/transport_maps
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
# Primary antispam protection:
#
smtpd_helo_required = yes
disable_vrfy_command = yes
# strict_rfc821_envelopes = yes
invalid_hostname_reject_code = 554
multi_recipient_bounce_reject_code = 554
non_fqdn_reject_code = 554
relay_domains_reject_code = 554
unknown_address_reject_code = 554
unknown_client_reject_code = 554
unknown_hostname_reject_code = 554
unknown_local_recipient_reject_code = 554
unknown_relay_recipient_reject_code = 554
unknown_virtual_alias_reject_code = 554
unknown_virtual_mailbox_reject_code = 554
unverified_recipient_reject_code = 554
unverified_sender_reject_code = 554
#
# DNSBL Protection
smtpd_recipient_restrictions =
            reject_invalid_hostname,
            reject_unknown_address,
            reject_unknown_sender_domain,
            reject_unauth_pipelining,
            permit_mynetworks,
            reject_rbl_client truncate.gbudb.net,
            reject_rbl_client dnsbl-1.uceprotect.net,
            reject_rbl_client dnsbl-2.uceprotect.net,
            reject_rbl_client dnsbl-3.uceprotect.net,
            reject_rbl_client dul.dnsbl.sorbs.net,
            reject_rbl_client sbl-xbl.spamhaus.org,
            reject_rbl_client dnsbl.sorbs.net,
            reject_rbl_client cbl.abuseat.org,
            permit
#
#
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
#
# END.-
#

Save the file, and create the transport map:

```bash
echo "domain01.dom smtp:[172.16.11.96]:25" > /etc/postfix/transport_maps
echo "domain02.dom smtp:[172.16.11.96]:25" >> /etc/postfix/transport_maps
postmap -c /etc/postfix/ hash:/etc/postfix/transport_maps
```

This transport map is CRITICAL. The IP (or FQDN) is the actual VIP or FQDN LBaaS Access point for your "POP-IMAP-SMTP-Delivery" SMTP Service. If you have only one server, put it's IP or FQDN here without the brackets. Sample (using LBaaS DNS name:)

```bash
echo "domain01.dom smtp:smtp-delivery.cloud0.hc.mycompany.dom:25" > /etc/postfix/transport_maps
echo "domain01.dom smtp:smtp-delivery.cloud0.hc.mycompany.dom:25" >> /etc/postfix/transport_maps
postmap -c /etc/postfix/ hash:/etc/postfix/transport_maps
```

In the same directory, create the file:

```bash
vi people-mycompany.ldap
```

Containing:

```bash
version = 3
server_port = 389
timeout = 60
search_base = dc=domain01,dc=dom
query_filter = (|(&(mail=%s)(mail=*@domain01.dom))(&(mail=%s)(mail=*@domain02.dom)))
result_attribute = cn
bind = yes
bind_dn = cn=correoapp,ou=mailapps,dc=domain01,dc=dom
bind_pw = Pass2016Mail
server_host = ldap://172.16.11.63:389/
```

Save the file, and enable/start postfix:

```bash
systemctl enable postfix
systemctl start postfix
```

At this point, postfix is ready with basic antispam protection.


## AntiSpam extended protection - Amavis/Spamassassin/Clamav

Proceed to install the following packages:

```bash
yum install \
perl-MailTools perl-MIME-EncWords perl-Email-Valid perl-Test-Pod \
perl-Mail-Sender perl-Log-Log4perl \
amavisd-new clamav perl-Razor-Agent \
opendkim crypto-utils clamav-update \
lrzip lzop  arj  unzoo cabextract p7zip \
spamassassin pax unzip zip cpio tnef \
pypolicyd-spf clamav-server-systemd

yum install http://pkgs.repoforge.org/unrar/unrar-5.0.3-1.el7.rf.x86_64.rpm
```

Edit the file:

```bash
vim /etc/sysconfig/freshclam
```

Comment the line at the end:

```bash
# FRESHCLAM_DELAY=disabled-warn # REMOVE ME
```

Save the file and edit:

```bash
vim /etc/freshclam.conf
```

Comment the line:

```bash
# Example
```

Also uncomment the lines:

```bash
AllowSupplementaryGroups yes
SafeBrowsing yes
Bytecode yes
```

Save the file and run:

```bash
freshclam
```

Wait until freshclam downloads all the updated antivirus signatures.

Copy the file (the actual dir chan change from 0.98.7 to something more new):

```bash
cp /usr/share/doc/clamav-server-0.98.7/clamd.sysconfig /etc/sysconfig/clamd.amavis
```

Edit the file:

```bash
vi /etc/sysconfig/clamd.amavis
```

Modify:

```bash
CLAMD_CONFIGFILE=/etc/clamd.d/amavisd.conf
CLAMD_SOCKET=/var/run/clamd.amavisd/clamd.sock
```

Save the file and create the following one:

```bash
vi /etc/tmpfiles.d/clamd.amavisd.conf
```

Containing:

```bash
d /var/run/clamd.amavisd 0755 amavis amavis -
```

Save the file and modify the following one:

```bash
vi /usr/lib/systemd/system/clamd@.service
```
Contents:

```bash
[Unit]
Description = clamd scanner (%i) daemon
After = syslog.target nss-lookup.target network.target

[Service]
Type = simple
ExecStart = /usr/sbin/clamd -c /etc/clamd.d/%i.conf --nofork=yes
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target
```

Save the file and start/enable the service:

```bash
systemctl start clamd@amavisd
systemctl enable clamd@amavisd
```

This conclude clamav config. Time for amavis:

Edit amavis main config:

```bash
vim /etc/amavisd/amavisd.conf
```

And make the changes:

```bash
$max_servers = 16;
$mydomain = 'domain01.dom';
$sa_tag_level_deflt  = -999;
$sa_tag2_level_deflt = 9.0;
$sa_kill_level_deflt = 12.0;
$sa_dsn_cutoff_level = 15;
$sa_crediblefrom_dsn_cutoff_level = 18;
$final_virus_destiny      = D_DISCARD;
$final_banned_destiny     = D_DISCARD;
$final_spam_destiny       = D_DISCARD;
$final_bad_header_destiny = D_PASS;
$sa_local_tests_only = 0;
# $sa_local_tests_only = 1;
$myhostname = 'vm-172-16-11-97.cloud0.hc.mycompany.dom';
```

**NOTES:**

- Set the hostname to the actual server FQDN.
- With this configuration, all detected viruses will be discarded. Also, spam with very high scores will be dicarded.
- Spam detected, but not discarded (spam level's low, but still spam) will me tagged. Those tags will be used by dovecot filters in order to put the email's in the user's junk folder.
- Bad header (malformed mails) is up to you if you want to discard them or not. In this configuration, we allow it to pass, but, you may want to discard them too.
- In this amavis/postfix model, you cannot use other options but "D_DISCARD" and "D_PASS". Do not try to use other available options like reject. Only if you configure amavis trouch a milter you can use such options. For this configuration, postfix is using amavis as a content filter (not a mail-filter or "milter").
- Adjust your "kill" and "cutoff" levels if you need to be more restrictive (lower the score), but, remember this can cause your system to detect more "false positives" and you'll border "censorship". Protect yourself, but not at the cost of censor your own users.
- Yo can disable SpamAssassin amavis component remote tests, by uncommenting the key/value "$sa_local_tests_only = 1;". Just do this if your internet traffic is too high, or if your platform is taking too much time to check incomming mail.

Save the file and start/enable amavis:

```bash
systemctl start amavisd.service
systemctl enable amavisd.service
```

Init your bayesian filter (the 3.4.0 dir can change depending of the most actual version):

```bash
sa-learn --spam /usr/share/doc/spamassassin-3.4.0/sample-spam.txt
sa-learn --ham /usr/share/doc/spamassassin-3.4.0/sample-nonspam.txt
```

Verify your log in /var/log/maillog in order to validate amavis status with clamav included.

We need to integrate postfix with amavis.

Edit the file:

```bash
vim /etc/postfix/main.cf
```

And add at the end:

```bash
content_filter=smtp-amavis:[127.0.0.1]:10024
```

Save the file and edit:

```bash
vim /etc/postfix/master.cf
```

At the end of the file add:

```bash
#
# AMAVIS CONFIG
#
smtp-amavis unix -      -       n       -       16       smtp
        -o smtp_data_done_timeout=1200
        -o smtp_send_xforward_command=yes
        -o disable_dns_lookups=yes
127.0.0.1:10025 inet n  -       n      -        -       smtpd
        -o content_filter=
        -o local_recipient_maps=
        -o relay_recipient_maps=
        -o smtpd_restriction_classes=
        -o smtpd_client_restrictions=
        -o smtpd_helo_restrictions=
        -o smtpd_sender_restrictions=
        -o smtpd_recipient_restrictions=permit_mynetworks,reject
        -o mynetworks=127.0.0.0/8
        -o strict_rfc821_envelopes=yes
        -o smtpd_error_sleep_time=0
        -o smtpd_soft_error_limit=1001
        -o smtpd_hard_error_limit=1000
#
# END AMAVIS CONFIG
#
```

**VERY IMPORTANT NOTE:** The "16" value at the end of the line "smtp-amavis unix" MUST BE the same value as "max_servers" in the amavisd.conf file. Set this wrong and you'll break your setup.

Save the file and restart postfix:

```bash
systemctl restart postfix
```

Create the following crontab:

```bash
vi /etc/cron.d/amavis-cleanup-crontab
```

Containing:

```
#
# Amavis CleanUP Crontab
#
*/15 * * * * root /usr/bin/find /var/spool/amavisd/tmp/ -name "amavis-*" -mmin +30 -type d -exec rm -rf "{}" ";" > /dev/null 2>&1
#
#
```

Save the file and reload crond:

```bash
systemctl reload crond
```

At this point, postfix with amavis/clamav and bayesian filters is ready to go !.


## SPF Protection (OPTIONAL BUT RECOMMENDED):

In order to enable the spf protection directly in postfix at filter lever, edit the file:

```bash
vim /etc/postfix/master.cf:
```

Add to the end:

```bash
#
# SPF Policy
#
policyd-spf  unix  -       n       n       -       -       spawn
  user=nobody argv=/usr/libexec/postfix/policyd-spf
#
# END SPF Policy
#
```

And in the file "main.cf" modify:

```bash
vim /etc/mail/main.cf
```

Specific modifications:

In the RBL's section, before the "permit", add

```bash
check_policy_service unix:private/policyd-spf,
```

And at the end of the configuration add:

```bash
policyd-spf_time_limit = 3600
```

Save the file.

Modify the spf control file:

```bash
vi /etc/python-policyd-spf/policyd-spf.conf
```

With the contents:

```bash
debugLevel = 1
defaultSeedOnly = 1

HELO_reject = Fail
Mail_From_reject = Fail

PermError_reject = False
TempError_Defer = False

skip_addresses = 127.0.0.0/8,::ffff:127.0.0.0/104,::1

Lookup_Time = 5
Header_Type = SPF
Mail_From_reject = Softfail
```

Save and restart postfix:

```bash
systemctl restart postfix
```

Now, our SMTP-IN platform is ready with most commons antispam protections.

END.-

