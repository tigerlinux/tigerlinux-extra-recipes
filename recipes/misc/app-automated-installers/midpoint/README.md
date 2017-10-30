# EVOLVEUM MIDPOINT AUTOMATED INSTALLER FOR CENTOS 7.

This script will install Evolveum Midpoint on a Centos 7 server. The specific stages performed by this script are described next:

- Base Centos utilities installation.
- SeLinux and FirewallD setup.
- Oracle JDK installation.
- Oracle JCE Policy files installation for JDK.
- Tomcat installation and base setup.
- Nginx installation and secure-setup.
- PostgreSQL installation and secure-setup.
- Midpoint PostgreSQL database provisioning.
- Midpoint installation and base-setup with tomcat and nginx.
- It creates an "index.html" file on nginx wich auto-redirect the base URL to the "/midpoint" location. This location is configured inside nginx with proxypass pointing to the app location on Tomcat.

Midpoint works as an tomcat application. Nginx is used as a front-end web layer for the specific midpoint application loaded on Tomcat. That way, we don't expose tomcat directly to the dangers on the Internet.

**THIS SCRIPT IS ONLY FOR CENTOS 7 X86_64**


# TOMCAT AND JDK.

We are using Oracle JDK instead of Centos openjdk. Is not that we don't trust on OpenJDK but we detected some strange things when trying to use midpoint with openjdk-8. In other words: "Play safe".

Tomcat is listening to all the networks trough port 8080 tcp, but in our setup the firewall is closed and we are only exposing "/midpoint" app on Tomcat trough Nginx using a proxypass configuration. If you want to expose Tomcat, you can add the port to firewalld using the following commands:

```bash
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

Also, the tomcat installation does not contain any admin user (is almost base). The only modification we did to Tomcat was on "catalina.sh" script using the following command inside our script (that is requested by midpoing installation):

```bash
sed -r -i "s@Djava.protocol.handler.pkgs=org.apache.catalina.webresources@Djava.protocol.handler.pkgs=org.apache.catalina.webresources -server -Xms256m -Xmx512m  -XX:PermSize=128m -XX:MaxPermSize=256m -Dmidpoint.home=/var/opt/midpoint/ -Djavax.net.ssl.trustStore=/var/opt/midpoint/keystore.jceks -Djavax.net.ssl.trustStoreType=jceks@g" /opt/apache-tomcat/bin/catalina.sh
```

# Software versions for JDK, Tomcat, Midpoint and other components.

At the moment we are publishing this script, the versions used by us are:

- Oracle JDK: 8u151
- Tomcat: 8.5.23
- Midpoint: 3.6.1
- Nginx: Latest version from EPEL-7 repos.
- PostgreSQL: Latest version from CENTOS-7 oficial repos.


# LETSENCRYPT

This script install "certbot" (letsencrypt software) and set the required crontab for automated renewall. The "ssl" certificate on nginx is "self-signed". Use "certbot" to adquire a valid certificate from letsencrypt.


# OPENED PORTS

FirewallD allow traffic for the following ports only (input traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).


# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 4Gb.
- CPU: 2 Core/Thread.
- FREE DISK SPACE: 5GB.

**NOTE:** Ensure that OpenJDK IS NOT INSTALLED on the base machine or your installation will fail.
