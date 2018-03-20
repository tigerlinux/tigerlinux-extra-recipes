# APACHE TOMCAT APP SERVER WITH NGINX FRONT-END

## The Components.

This script will install and configure an Apache Tomcat application server with an nginx front-end. Tomcat will run on its standard ports, but it will be exposed trough http and https using nginx proxypass.

The following components will be installed by this script:

- Oracle JDK 8 (8u162)
- Tomcat 8.5.29
- Nginx 1.12.
- Maven 3.5.2.

All actions performed by this script will be logged on the file "/var/log/tomcat-nginx-automated-installer.log".

The script will also create the Tomcat manager account. All credentials will be stored on the file "/root/tomcat-nginx-access-credentials.txt".

## Why NGINX?

In order to have the best combination of performance and features we prefer to "not expose" directly anything java-based, instead, use nginx as a front-end.

## TOMCAT AND MAVEN LOCATIONS.

Tomcat will be available on the directory "/opt/apache-tomcat". Maven will be also available on "/opt/apache-maven".

## SELINUX.

Please note that this script will disable selinux.

## DATABASE CONNECTORS.

We are including the database connectors for PostgreSQL and MariaDB on our solution. They are installed/available on /opt/tomcat/libs.

## LETSENCRYPT

This script installs "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on nginx is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.

## OPENED PORTS

FirewallD is configured to allow traffic for the following ports only (incoming traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).

**NOTE: Tomcat will be available trough its standard ports, but because we prefer to not expose it directly to the Internet, we'll use nginx to expose tomcat trough proxypass! If you want you can open tomcat's ports with firewalld.**

## SYSTEMD SERVICE.

Tomcat will be configured and run as a "systemd" unit:

```bash
systemctl status tomcat
systemctl restart tomcat
systemctl start tomcat
systemctl stop tomcat
```

## GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.