# DNS-BASED HOSTNAME AUTOCONFIG SCRIPT

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

This script can be used to auto-configure the hostname of a linux server, provided that the DNS service has the reverse records (in-addr.arpa ptr's) correctly configured with the hostnames.


## Usage.

Copy the "script-autoconfig-server.sh" to /usr/local/bin and make it executable (mode 755 will do).
Copy the config file autoconfig-server-options.conf to /etc/ and make it mode 644.

```bash
chmod 755 /usr/local/bin/script-autoconfig-server.sh
chmod 644 /etc/autoconfig-server-options.conf
```

On **CoreOS**, both the script and the conf file should be placed on `/etc` directory.

On most linux distros (with the exception of CoreOS), include the script in your rc.local if you want it to run at every boot.

Sample line in your /etc/rc.local:

```bash
/usr/local/bin/script-autoconfig-server.sh > /var/log/script-autoconf-server-last-run.log
```

## CoreOS

CoreOS does not use any rc.local, so, you need to create a "systemd" based script in order to use the hostname autoconf script. In your CoreOS machine, issue the following commands:

```bash
echo "[Unit]" > /etc/systemd/system/hostnameautoconf.service
echo "Description=Hostname AutoConf Service" >> /etc/systemd/system/hostnameautoconf.service
echo "After=network.target" >> /etc/systemd/system/hostnameautoconf.service
echo "Requires=network.target" >> /etc/systemd/system/hostnameautoconf.service
echo "" >> /etc/systemd/system/hostnameautoconf.service
echo "[Service]" >> /etc/systemd/system/hostnameautoconf.service
echo "Type=oneshot" >> /etc/systemd/system/hostnameautoconf.service
echo "RemainAfterExit=true" >> /etc/systemd/system/hostnameautoconf.service
echo "ExecStartPre=/usr/bin/sleep 10" >> /etc/systemd/system/hostnameautoconf.service
echo "ExecStart=/usr/bin/bash -c \"/etc/script-autoconfig-server.sh\"" >> /etc/systemd/system/hostnameautoconf.service
echo "ExecStop=/usr/bin/bash -c \"/etc/script-autoconfig-server.sh\"" >> /etc/systemd/system/hostnameautoconf.service
echo "" >> /etc/systemd/system/hostnameautoconf.service
echo "[Install]" >> /etc/systemd/system/hostnameautoconf.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/hostnameautoconf.service

systemctl enable hostnameautoconf.service
systemctl start hostnameautoconf.service
```

## Dependencies:

**NOTE: ENSURE YOU HAVE the "host" utility installed, or the script will fail.**

This script has been tested on:

Centos 5
Centos 6
Centos 7
Debian 6
Debian 7
Debian 8
Ubuntu Server 14.04lts
Ubuntu Server 16.06lts
CoreOS
FreeBSD
Some Fedoras

END.-
