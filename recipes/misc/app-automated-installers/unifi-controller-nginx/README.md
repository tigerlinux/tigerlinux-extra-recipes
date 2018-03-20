# UNIFI CONTROLLER AUTOMATED INSTALLATION WITH NGINX FRONTAL HTTP/HTTPS SERVER

## The Components.

This script will install the UniFi 5.6.x controller on Centos 7 with the following components:

- MongoDB 3.4.
- UniFi series 5.6 latest (5.6.30 at the moment of producing this script).
- OpenJDK 1.8.
- Nginx 1.12.

All actions performed by this script will be logged on the file "/var/log/unifi-nginx-server-automated-installer.log".

The installation will use proxypass from nginx to serve all controller-related components (wss included) trough https standard port 443.

## Why NGINX?

You can use this recipe on a public network (yes.. exposed to the Internet). Because of that, we added a "nginx" based front end. This ensures the best performance and protection for your controller. Also, you don't need to use and/or expose the default UniFi controller ports. All is done trough https 443!

## SELINUX.

Please note that this script will disable selinux.

## LETSENCRYPT

This script installs "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on nginx is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.

## OPENED PORTS

FirewallD is configured to allow traffic for the following ports only (incoming traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).

**NOTE: All http requests will be autoforwarded to https!**

## SYSTEMD SERVICE.

The UniFi controller runs as a "systemd" unit:

```bash
systemctl status unifi
systemctl restart unifi
systemctl start unifi
systemctl stop unifi
```

## GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.