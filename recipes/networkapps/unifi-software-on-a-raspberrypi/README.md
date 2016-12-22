# UNIFI SOFTWARE INSTALL ON A RASPBERRY PI 2 (RASPBIAN WHEEZY 2015)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

If you have an Unifi Wireless Access Point, you know that those devices need an external control software in order to configure them. Being aimed at enterprises and hotels, normally you should have a server o station running the control software most of the time, or at least when you need to make changes or monitor your access point.

The control software gives you a web interface in the machine port "tcp 8843" where you can enter and administer your A/P or A/P's (the software can control all your devices).

Being myself the owner of both a unify A/P and a raspberry PI 2 (arm v7 with raspbian wheezy 2015), I've found one of the possible uses of my raspberry to be the "unifi control server".


## What we want to acomplish here ?:

This recipe (a very short one) will show you how to install the needed software in your "raspberry pi 2" in order to have the unify software running all the time. This is by far a cheap solution compared on a server running the software all the time.


## What do you need to acomplish the task ?:

Minimun requirement: A raspberry PI 2 (arm v7) with raspbian wheezy 2015. Note that newer raspbian versions exists (based on Jessie) so you can easily adapt this recipe to raspbian 2016.


## How do we constructed the solution ?:

First, and again thinking on Raspbian Wheezy 2015, do a full update and install some extra packages:

```bash
apt-get update
apt-get upgrade

apt-get install oracle-java7-jdk git-core build-essential scons \
libpcre++-dev libboost-dev libboost-program-options-dev \
libboost-thread-dev libboost-filesystem-dev
```

Change to the "/usr/local/src" directory, download mongo for PI using git, and install it:

```bash
cd /usr/local/src

git clone git://github.com/devinbabb/mongopi.git
cd mongopi
scons

scons --prefix=/opt/mongo install

echo "export PATH=\$PATH:/opt/mongo/bin/" > /etc/profile.d/mongo-profile.sh

export PATH=$PATH:/opt/mongo/bin/
```

**NOTE:** The mongo installation will take very long. Last time I did it toke me on the PI-2 about an hour.

Now, we proceed to download the "Unifi for Unix" software:

```bash
cd /opt
wget http://dl.ubnt.com/unifi/3.2.10/UniFi.unix.zip
```

**NOTE:** At the moment I installed this for the first time, I used UniFi v 3.2.10. There are newer versions you can try:

- Lattest 4.8.19:

```bash
wget https://www.ubnt.com/downloads/unifi/4.8.19/UniFi.unix.zip
```

- Lattest 5.0.7:

```bash
wget https://www.ubnt.com/downloads/unifi/5.0.7/UniFi.unix.zip
```

If you have problems with newer versions, go to 3.2.10.

Unzip and prepare your software:

```bash
cd /opt

unzip UniFi.unix.zip

cd /opt/UniFi/bin

ln -fs /opt/mongo/bin/mongod mongod
```

Verify that your software starts correctly:

```bash
java -jar /opt/UniFi/lib/ace.jar start &
```

After few seconds, the service will open ports TCP 8880, 8843, 8080 and 27117.

Use a browser and enter with https to the IP of your raspberry and port 8843 but DO NOT LOG to the admin page:

```bash
https://IP_OR_FQDN:8843
```

Back on your raspberry ssh console, stop the software with the following command:

```bash
java -jar /opt/UniFi/lib/ace.jar stop &
```

You need to create a sysvinit start-stop script:

```bash
vi /etc/init.d/unifi
```

Containing:

```bash
#!/bin/sh
### BEGIN INIT INFO
# Provides: unifi
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Starts the UniFi admin interface
# Description: Starts the UniFi admin interface.
### END INIT INFO

DAEMON=/usr/bin/java
UNIFI_DIR=/opt/UniFi
DAEMON_ARGS="-jar lib/ace.jar start"

start() {
    # need unifi_dir, because the logs are in <unifi_dir>/logs
    echo "Starting unifi"
    start-stop-daemon -b -o -c unifi -S -u unifi -d $UNIFI_DIR -x $DAEMON -- $DAEMON_ARGS
}

stop() {
    dbpid=`pgrep -fu unifi $DAEMON`
    if [ ! -z "$dbpid" ]; then
        echo "Stopping unifi"
        start-stop-daemon -o -c unifi -K -u unifi -d $UNIFI_DIR -x $DAEMON -- $DAEMON_ARGS
    fi
}

status() {
    dbpid=`pgrep -fu unifi $DAEMON`
    if [ -z "$dbpid" ]; then
        echo "unifi: not running."
    else
        echo "unifi: running (pid $dbpid)"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload|force-reload)
        stop
        sleep 3
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: /etc/init.d/unifi {start|stop|reload|force-reload|restart|status}"
        exit 1
esac

exit 0
```

Save the file, make it exec, and enable it but **DO NOT** start it yet:

```bash
chmod 755 /etc/init.d/unifi

update-rc.d unifi defaults
update-rc.d unifi enable
```

You don't want the software running as root do you ???. Let's create an user and set the right permissions:

```bash
useradd -c "UniFi System User" -d /opt/UniFi -s /bin/bash unifi
chown -R unifi.unifi /opt/UniFi
```

Now, it's ok to launch your UniFi service with the sysvinit script:

```bash
/etc/init.d/unifi start
```


## Important note in order to allow you better A/P registration using L3 services:

The UniFi access points try to use L2 (layer 2) or L3 (layer 3) network services in order to find and enroll itself on to the control software. Normally, you need a DHCP in your network in order to let the A/P to get an IP. If your DHCP also configures "dns" domain to your dhcp clients, and you have your own-internal DNS service, try to create a hostname (DNS "A" Record) in your domain with name "unifi" pointing to the Raspberry PI IP address (the raspberry running your unifi software). This will allow the UniFi access points to use L3 services in order to register to the control software.

Sometimes, L3 services work's better than L2 ones.

END.-
