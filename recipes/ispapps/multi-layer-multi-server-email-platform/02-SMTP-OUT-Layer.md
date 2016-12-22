# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - SMTP-OUTGOING LAYER

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Basic POSTFIX Setup.

The server (or servers) located in this service layer will receive all mail comming from your users (trough webmail or specific mail-clients) and relay to the proper destinations. This layer will also include antivirus-protection and DKIM (Domain Keys).

Server IP: 172.16.11.95

Again, we prepare our postfix packages and get rid of sendmail:

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

```bash
#
# SMTP-OUT CONFIGURATION FILE
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
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination
#
# Again, set this to the actual server fqdn:
myhostname = vm-172-16-11-95.cloud0.hc.mycompany.dom
#
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydomain = domain01.dom
myorigin = $myhostname
mydestination = $myhostname, localhost.$mydomain, localhost
unknown_local_recipient_reject_code = 550
relayhost =
# Set your mail networks here - only server networks
mynetworks = 127.0.0.0/8, 172.16.10.0/24, 172.16.11.0/24
#
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
# Your main relay domain
relay_domains = domain01.dom
# LDAP Map:
relay_recipient_maps = ldap:/etc/postfix/people-mycompany.ldap
inet_protocols = all
# Queue directory - remember to have proper space for your mail queuing needs:
queue_directory = /var/spool/postfix
# Transport maps:
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
#
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
#
#
# SASLAUTH - SASL Based authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = noanonymous
smtpd_sasl_path= smtpd
smtpd_sasl_local_domain =
smtpd_sasl_authenticated_header = yes
#
# END.-
#
```

Save the file.

In the same directory, let's proceed to create our ldap maps:

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

Start/Enable postfix:

```bash
systemctl enable postfix
systemctl start postfix
```

This transport map ensures all internal mail will go directly to the SMTP Delivery platform.


## SMTP Authentication Setup.

We need to install and configure Cyrus SASL:

```bash
yum install cyrus-sasl-plain cyrus-sasl-ldap cyrus-sasl
```

Edit the saslauthd file and change the authentication mechanism to ldap:

```bash
vi /etc/sysconfig/saslauthd
```

Change:

```bash
# MECH=pam
MECH=ldap
```

Change the file, and create the following one:

```bash
vi /etc/saslauthd.conf
```

Containing.

```bash
ldap_servers: ldap://172.16.11.63:389/
ldap_version: 3
ldap_auth_method: bind
ldap_bind_dn: cn=correoapp,ou=mailapps,dc=domain01,dc=dom
ldap_bind_pw: Pass2016Mail
ldap_search_base: dc=domain01,dc=dom
ldap_filter: sAMAccountName=%U
ldap_scope: sub
```

Save the file, and start/enable the service:

```bash
systemctl enable saslauthd
systemctl start saslauthd
```

Test with the already created users in our A/D:

```bash
testsaslauthd -u usuario01 -p P@ssw0rd

0: OK "Success."
```

Also, test directly in the SMTP service:

Con el usuario "usuario01" y su password "P@ssw0rd" se genera un base64:

With the user "usuario01" and it's password "P@ssw0rd", generate a "base64" string:

```bash
echo -ne '\000usuario01\000P@ssw0rd' | openssl base64

AHVzdWFyaW8wMQBQQHNzdzByZA==
```
With telnet to the smtp port 25, let's test the SMTP auth:

```bash
telnet 0 25
EHLO localhost
AUTH PLAIN AHVzdWFyaW8wMQBQQHNzdzByZA==
```

The complete test:

```bash
[root@vm-172-16-11-95 /]# telnet 0 25
Trying 0.0.0.0...
Connected to 0.
Escape character is '^]'.
220 vm-172-16-11-95.cloud0.hc.mycompany.dom ESMTP Postfix (MYCOMPANY Mail System)
ehlo c
250-vm-172-16-11-95.cloud0.hc.mycompany.dom
250-PIPELINING
250-SIZE 26214400
250-VRFY
250-ETRN
250-AUTH PLAIN LOGIN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
AUTH PLAIN AHVzdWFyaW8wMQBQQHNzdzByZA==
235 2.7.0 Authentication successful
quit
221 2.0.0 Bye
Connection closed by foreign host.
```

At this point, the smtp service contains proper authentication.


## Antivirus Protection

We are going to use "CLamav" Antivirus for our e-mail antivirus protection. First, install the packages:

```bash
yum install clamav-milter-systemd clamav-server-systemd clamav \
clamav-data clamav-milter clamav-server clamav-update \
clamav-scanner clamav-scanner-systemd
```

Modify the file:

```bash
vim /etc/sysconfig/freshclam
```

Comment out the line:

```bash
# FRESHCLAM_DELAY=disabled-warn # REMOVE ME
```

Save the file and edit the next one:

```bash
vim /etc/freshclam.conf
```

Comment the line:

```bash
# Example
```

Un-comment the following lines:

```bash
AllowSupplementaryGroups yes
SafeBrowsing yes
Bytecode yes
```

Save the file and run the command:

```bash
freshclam
```

NOTE: Wait until "freshclam" download's all updated virus signatures.

Edit the file:

```bash
vi /etc/clamd.d/scan.conf
```

Comment the line:

```bash
# Example
```

Modify the following lines:

```bash
PidFile /var/run/clamd.scan/clamd.pid
TemporaryDirectory /var/tmp
DatabaseDirectory /var/lib/clamav
LocalSocket /var/run/clamd.scan/clamd.sock
FixStaleSocket yes
TCPSocket 3310
TCPAddr 127.0.0.1
```

Save the file and enable/start the service:

```bash
systemctl  enable clamd@scan
systemctl  start clamd@scan
systemctl  status clamd@scan
```

We need to configure clamav-milter

Edit the file:

```bash
vi /etc/mail/clamav-milter.conf
```

Comment the following line:

```bash
# Example
```

Modify:

```bash
MilterSocket inet:7357@127.0.0.1
PidFile /var/run/clamav-milter/clamav-milter.pid
TemporaryDirectory /var/tmp
ClamdSocket tcp:127.0.0.1:3310
OnClean Accept
OnInfected Reject
OnFail Accept
RejectMsg %v virus detected
AddHeader Replace
SupportMultipleRecipients yes
```

Save the file and enable/start the service:

```bash
systemctl enable clamav-milter
systemctl start clamav-milter
systemctl status clamav-milter
```

In order to integrate clamav-milter with postfix, edit the file:

```bash
vim /etc/postfix/main.cf
```

And add to the end:

```bash
milter_default_action = accept
smtpd_milters = inet:127.0.0.1:7357
```

Restart postfix:

```bash
systemctl restart postfix
```

## OPTIONAL: DOMAIN KEYS (OpenDKIM)

If you want to include "Domain Keys" in your mail solution, proceed with the following steps:

```bash
yum install opendkim
```

Create a key for each of your domains:

```bash
cd /etc/opendkim/keys
opendkim-genkey --bits=4096 --domain=domain01.dom --selector=domain01.dom --restrict
opendkim-genkey --bits=4096 --domain=domain02.dom --selector=domain02.dom --restrict
chown opendkim:opendkim /etc/opendkim/keys/*.private
```

NOTE: You will eventualluy need to include the key in your DNS public zones. Read more about Domain KEYS in order to complete the task.

Reconfigure OpenDKIM:

```bash
cp /etc/opendkim.conf /etc/opendkim.conf.ORG
> /etc/opendkim.conf

vi /etc/opendkim.conf
```

New file contents:

```bash
PidFile    /var/run/opendkim/opendkim.pid
Mode    sv
Syslog    yes
SyslogSuccess    yes
LogWhy    yes
UserID    opendkim:opendkim
Socket    inet:8891@localhost
Umask    002
Canonicalization    relaxed/relaxed
Selector    default
MinimumKeyBits 1024
KeyTable    refile:/etc/opendkim/KeyTable
SigningTable    refile:/etc/opendkim/SigningTable
ExternalIgnoreList    refile:/etc/opendkim/TrustedHosts
InternalHosts    refile:/etc/opendkim/TrustedHosts
```

Enable and start the service:

```bash
systemctl enable opendkim
systemctl start opendkim
```

Also, add the server IP at the end of the following file:

```bash
vim /etc/opendkim/TrustedHosts
```

Edit the file:

```bash
vim /etc/opendkim/KeyTable
```

And add:

```bash
default._domainkey.domain01.dom domain01.dom:default:/etc/opendkim/keys/domain01.dom.private
default._domainkey.domain02.dom domain02.dom:default:/etc/opendkim/keys/domain02.dom.private
```

And if we are going to sign the outgoing e-mails:

```bash
vim /etc/opendkim/SigningTable
```

And add:

```bash
*@domain01.dom default._domainkey.domain01.dom
*@domain02.dom default._domainkey.domain02.dom
```

After saving all changes, restart the service:

```bash
systemctl restart opendkim.service
```

Finally, we need to add this mail filter along clamav:

Edit:

```bash
vim /etc/postfix/main.cf
```

Changes to the end of the file:

```bash
milter_default_action = accept
smtpd_milters = inet:127.0.0.1:7357, inet:127.0.0.1:8891
```

And restart postfix:

```bash
systemctl restart postfix
```

At this point, your SMTP Ourgoing layer will have: SMTP Authentication, Antivirus Protection and DKIM.

END.-
