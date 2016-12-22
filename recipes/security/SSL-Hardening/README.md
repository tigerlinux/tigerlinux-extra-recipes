# SSL HARDENING IN COMMON WEB/MAIL APPLICATIONS.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Since [**"Heartbleed"**](https://en.wikipedia.org/wiki/Heartbleed) ssl vulnerability was discovered, most internet-class applications became potential hacking targets. Of course, the community reacted very fast in order to patch most common vulnerabilities, and, make software adjustments recommendations in order to harden SSL/TLS exposed services.

This short recipe will show you which common configurations you should apply in packages like apache, sendmail, dovecot, postfix, etc., in order to harden your encription configuration.


## Apache.

For versions 2.2 and 2.4, make the following adjustments in the main config:

```bash
ServerTokens ProductOnly
Header unset ETag
FileETag None
ExtendedStatus Off
UseCanonicalName Off
TraceEnable off
ServerSignature Off
```

For 2.2 series, use the following SSL/TLS config:

```bash
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5:!SSLv3:!SSLv2
```

For 2.4 series, use the following SSL/TLS config:

```bash
SSLHonorCipherOrder on
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5:!SSLv3:!SSLv2
```

Para evitar SLOW DOS ATTACKS se debe crear la siguiente configuración (adaptarla segun sea centos o debian):

In order to avoid slow DOS attacks, in Centos/RHEL based installs create the following file:

```bash
vi /etc/httpd/conf.d/reqtimeout.conf
```

Containing:

```bash
LoadModule reqtimeout_module modules/mod_reqtimeout.so

<ifmodule reqtimeout_module>
        RequestReadTimeout header=10-20,minrate=500
        RequestReadTimeout body=10,minrate=500
</ifmodule>
```

For debians/ubuntuses:

```bash
a2enmod reqtimeout
```

And adjust your rates in the following file:

```bash
vi /etc/apache2/mods-available/reqtimeout.conf
```


## Dovecot

For dovecot POP-IMAP-LDAP software you can adjust your file "10-ssl.conf" (may vary depending of version and linux distro) with the following config:

```bash
ssl_cipher_list = ALL:!LOW:!SSLv2:!SSLv3:!EXP:!aNULL
```


## Sendmail

Add to your sendmail.mc the following lines (at the end of the file):

```bash
LOCAL_CONFIG
O CipherList=HIGH
O ServerSSLOptions=+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3 +SSL_OP_CIPHER_SERVER_PREFERENCE
O ClientSSLOptions=+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3
```


## Webmin

If you are using the very popular Webmin "system admin" configuration software, edit the following file:

```bash
vi /etc/webmin/miniserv.conf
```

Add/change:

```bash
ssl_honorcipherorder=0
ssl_redirect=0
ssl_cipher_list=ALL:!ADH:!LOW:!SSLv2:!EXP:+HIGH:+MEDIUM
ssl_version=10
```


## Usermin

For usermin the recipe is almost the same as webmin:

```bash
vi /etc/usermin/miniserv.conf
```

Add/change:

```bash
ssl_honorcipherorder=0
ssl_redirect=0
ssl_cipher_list=ALL:!ADH:!LOW:!SSLv2:!EXP:+HIGH:+MEDIUM
ssl_version=10
```


## Nginx

In your nginx site configuration, change or add:

```bash
    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;
```


## Postfix

In your `/etc/postfix/main.cf` file, add or change:

```bash
smtpd_tls_security_level = may
smtpd_tls_mandatory_ciphers = high
smtpd_tls_mandatory_exclude_ciphers = aNULL, MD5
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_starttls_timeout = 300s
tls_disable_workarounds = 0xFFFFFFFF
tls_disable_workarounds = CVE-2010-4180
tls_ssl_options = no_ticket, no_compression
```

END.-
