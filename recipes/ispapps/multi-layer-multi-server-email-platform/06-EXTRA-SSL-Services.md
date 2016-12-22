# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - EXTRA - SSL/TLS Encryption for your services.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Even if you really-really-really-really trust in your network and users (that's a Joke of course), it's a good idea to encript all primary services, specialy those exposing to the Internet.

if you have a LBaaS (or any other non-cloud load balancer) capable of terminate SSL traffic, you are basically set and don't need to do any other extra configurations in your software, but, if you don't have such kind of feature in your network, then, you should protect your services with ssl/tls encription.

We are not going trough the stages of creating a certificate, etc. That's very "101" and there is plenty of information about how to do this in the Internet. Instead, we'll go layer-by-layer with the configuration steps for postfix, dovecot and sogo.

For our setup, we created our key and pem in the following locations:

- Certificate: **/etc/pki/CA/certs/allservers.crt**.
- Key: **/etc/pki/CA/private/allservers.key**.


## Webmail Service (SoGo).

In order to use SoGo with SSL, we need to change apache for nginx. Sogo does not work right with SSL and apache:

```bash
yum -y install nginx
systemctl disable httpd
systemctl stop httpd
```

Copy our certificate/key:


```bash
cat /etc/pki/CA/certs/allservers.crt > /etc/nginx/cert.pem
cat /etc/pki/CA/private/allservers.key > /etc/nginx/cert.key
```

Create the following file:

```bash
vi /etc/nginx/conf.d/sogo.conf
```

Containing:

```bash
server {
    listen 443 ssl;

    ssl_certificate      /etc/nginx/cert.pem;
    ssl_certificate_key  /etc/nginx/cert.key;

    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;

    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;

    # Add below lines for SOGo
    # SOGo
    location ~ ^/sogo { rewrite ^ https://$host/SOGo; }
    location ~ ^/SOGO { rewrite ^ https://$host/SOGo; }

    # For IOS 7
    location = /principals/ {
        rewrite ^ https://$server_name/SOGo/dav;
        allow all;
    }

    location ^~ /SOGo {
      proxy_pass http://127.0.0.1:20000;
      proxy_redirect http://127.0.0.1:20000 default;
      # forward user's IP address 
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;
      proxy_set_header x-webobjects-server-protocol HTTP/1.0;
      proxy_set_header x-webobjects-remote-host 127.0.0.1;
      proxy_set_header x-webobjects-server-name $server_name;
      proxy_set_header x-webobjects-server-url $scheme://$host;
      proxy_set_header x-webobjects-server-port $server_port;
      proxy_connect_timeout 90;
      proxy_send_timeout 90;
      proxy_read_timeout 90;
      proxy_buffer_size 4k;
      proxy_buffers 4 32k;
      proxy_busy_buffers_size 64k;
      proxy_temp_file_write_size 64k;
      client_max_body_size 50m;
      client_body_buffer_size 128k;
      break;
    }

    location ^~ /Microsoft-Server-ActiveSync {
        proxy_pass http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync;
        proxy_redirect http://127.0.0.1:20000/Microsoft-Server-ActiveSync /;
    }

    location ^~ /SOGo/Microsoft-Server-ActiveSync {
        proxy_pass http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync;
        proxy_redirect http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync /;
    }

    location /SOGo.woa/WebServerResources/ {
        alias /usr/lib64/GNUstep/SOGo/WebServerResources/;
    }
    location /SOGo/WebServerResources/ {
        alias /usr/lib64/GNUstep/SOGo/WebServerResources/;
    }
    location ^/SOGo/so/ControlPanel/Products/([^/]*)/Resources/(.*)$ {
        alias /usr/lib64/GNUstep/SOGo/$1.SOGo/Resources/$2;
    }
}
```

Save the file and start/enable nginx:

```bash
systemctl start nginx
systemctl enable nginx
```

And, run the following commands:

```bash
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.ORG
cp /var/www/html/index.html /usr/share/nginx/html/
```

Change your LBaaS service for Webmail in order to use port 443 instead of port 80.


## POP/IMAP Services (Dovecot).

Copy our certificate/key:

```bash
cat /etc/pki/CA/certs/allservers.crt > /etc/pki/dovecot/certs/dovecot.pem
cat /etc/pki/CA/private/allservers.key > /etc/pki/dovecot/private/dovecot.pem
```

Edit your `/etc/dovecot/dovecot.conf` file, and add the following config items at the beggining of the file:

```bash
ssl = yes
ssl_cert = </etc/pki/dovecot/certs/dovecot.pem
ssl_key = </etc/pki/dovecot/private/dovecot.pem
ssl_cipher_list = ALL:!LOW:!SSLv2:!SSLv3:!EXP:!aNULL
```
>

And in the listener sections, activate the SSL/TLS services:

```bash
# MASTER
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
  # this is suboptimal since imap and imaps will also accept nopass
  inet_listener imap-nopass {
    port = 144
  }
}
service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}
```

Save your file and restart dovecot:

```bash
systemctl restart dovecot
```

You can verify the connection:

```bash
openssl s_client -connect localhost:995
openssl s_client -connect localhost:993
```

Change your LBaaS definitions in order to use ports 995 and 993 for your POP and IMAP services.

Also, you should modify SOGO in order to use IMAP over SSL:

```bash
vi /etc/sogo/sogo.conf
```

```
SOGoIMAPServer = imaps://IMAP_VIP_OR_FQDN:993;
```

Save the file and restart SoGo:

```bash
systemctl restart sogod
```


## SMTP Services (Postfix).

For your SMTP services exposed to the internet (SMTP-IN and SMTP-OUT), you should enable SSL/TLS too. Also you can enable this on the postfix installed on POP-IMAP-SMTP-Delivery services:

Copy your certificate and key:

```bash
cat /etc/pki/CA/certs/allservers.crt > /etc/postfix/cert.pem
cat /etc/pki/CA/private/allservers.key > /etc/postfix/cert.key
```

Edit your postfix configuration file:

```bash
vi /etc/postfix/main.cf
```

Add at the end:

```bash
# SSL/TLS Options
smtpd_tls_cert_file = /etc/postfix/cert.pem
smtpd_tls_key_file = /etc/postfix/cert.key
smtpd_tls_security_level = may
smtpd_tls_mandatory_ciphers = high
smtpd_tls_mandatory_exclude_ciphers = aNULL, MD5
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_starttls_timeout = 300s
tls_disable_workarounds = 0xFFFFFFFF
tls_disable_workarounds = CVE-2010-4180
tls_ssl_options = no_ticket, no_compression
#
```

Save the file and restart postfix:

```bash
systemctl restart postfix
```

This config will enable TLS over standard port TCP 25 (using starttls) so there is no need to change your LBaaS definitions.

A little test:

```bash
[root@vm-172-16-10-142 postfix]# telnet 0 25
Trying 0.0.0.0...
Connected to 0.
Escape character is '^]'.
220 vm-172-16-10-142.cloud0.hc.mycompany.dom ESMTP Postfix (MYCOMPANY Mail System)
ehlo c
250-vm-172-16-10-142.cloud0.hc.mycompany.dom
250-PIPELINING
250-SIZE 26214400
250-VRFY
250-ETRN
250-STARTTLS
250-AUTH PLAIN LOGIN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
quit
221 2.0.0 Bye
Connection closed by foreign host.
```

As you can see in the above test, "starttls" is available for use.

At this point, all your primary services are SSL/TLS encrypted using strong cyphers.

END.-
