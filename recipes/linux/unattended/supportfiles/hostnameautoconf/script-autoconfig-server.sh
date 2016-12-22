#!/bin/bash
#
# Hostname autoconfiguration script based on DNS ptr (in-addr.arpa record)
#
# This script will try to determine the server IP, then query the DNS's servers
# in order to find the IP in-addr.arpa (PTR) records, which normally points to
# the hostname, then, set the hostname in the server with the data obtained in
# the dns query.
#
# To be used with: Centos 5, 6, 7, All Fedoras, CoreOS, FreeBSD, Debians and
# Ubuntuses !!.
# Reynaldo R. Martinez P.
# TigerLinux AT Gmail DOT Com
# Caracas, Venezuela.
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# This what the scripts does:
# 1.- Check in which O/S are we running.
# 2.- Try to get our IP.
# 3.- Query DNS based on the located IP.
# 4.- Change our hostname, based on the IP and Hostname found
# 5.- Change oour /etc&/hosts, based on the IP and Hostname found


# Stage 1: Check in which O/S are we running !.

OSFlavor='unknown'

if [ -f /etc/redhat-release ]
then
	OSFlavor='redhat-based'
fi

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
fi

if [ -f /etc/debian_version ]
then
	OSFlavor='debian-based'
fi

if [ -f /etc/freebsd-update.conf ]
then
        OSFlavor='freebsd-based'
fi

if [ -d /etc/coreos ]
then
        OSFlavor='core-os-based'
fi

echo "OS Flavor is: $OSFlavor"

if [ $OSFlavor == "unknown" ]
then
	echo "Unknown OS Flavor - Aborting"
	exit 0
fi

autoconfigoptionsfile='/etc/autoconfig-server-options.conf'
autoconfigfirstrunfile='/etc/autoconfig-server-alreadyran.txt'
RUNPUPPET="no"
FIRSTRUNONLY="no"
NETWORK=""
INTERFACE=""
PUPPETSERVER=""
IPADDRESS=""
MYFQDN=""

# If we have our autoconfig file, normally: /etc/autoconfig-server-options.conf,
# we proceed to parse some options from it. See the readme for more info.

if [ -f $autoconfigoptionsfile ]
then
	echo "Reading autoconfig options from $autoconfigoptionsfile"
	source $autoconfigoptionsfile
else
	echo "No autoconfig file found"
fi

case $FIRSTRUNONLY in
yes)
	if [ -f $autoconfigfirstrunfile ]
	then
		echo "First Run already done - aborting script"
		exit 0
	fi
	;;
*)
	echo "No first run config found - lets continue with autoconfig"
	;;
esac

# NETWORK="192.168.56"
# NETWORK="none-jaja"
# INTERFACE="eth1"
# INTERFACE="lo"

if [ ! -z "$NETWORK" ]
then
	echo "Determining IP for Network $NETWORK"
	IPADDRESS=`ifconfig|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|grep $NETWORK|head -n 1`
elif [ ! -z "$INTERFACE" ]
then
	echo "Determining IP for interface $INTERFACE"
	IPADDRESS=`ifconfig $INTERFACE|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|head -n1`
else
	echo "Determining IP the normal way"
	IPADDRESS=`ifconfig|grep -i "inet"|grep -i -v "inet6"|awk '{print $2}'|cut -d: -f2|sort|grep -v 127.0.0.1|head -n1`
fi

if [ -z "$IPADDRESS" ]
then
	IPADDRESS="127.0.0.1"
fi

echo "My IP Address is $IPADDRESS"


MYFQDN=`host $IPADDRESS|grep -i -v NXDOMAIN|awk '{print $5}'|sed 's/.$//'`

if [ -z $MYFQDN ]
then
	echo "Could not resolve the FQDN using DNS - Constructing new FQDN"
	SHORTHOSTNAME=`echo $IPADDRESS|sed 's/\./\-/g'`
	MYFQDN=$SHORTHOSTNAME.localdomain
fi

if [ $IPADDRESS == "127.0.0.1" ]
then
	MYFQDN="localhost.localdomain"
fi

echo "My FQDN is: $MYFQDN"

# Here we begin to make changes

case $OSFlavor in
redhat-based|centos-based)
	echo "Changing Server personality for $OSFlavor"
	cat /etc/sysconfig/network|grep -v HOSTNAME > /etc/sysconfig/network-temp
	sleep 1
	sync
	cat /etc/sysconfig/network-temp > /etc/sysconfig/network
	sleep 1
	sync
	echo "HOSTNAME=$MYFQDN" >> /etc/sysconfig/network
	rm /etc/sysconfig/network-temp
	sync
	hostname $MYFQDN
	echo $MYFQDN > /etc/hostname
	;;
debian-based)
	echo "Changing Server personality for $OSFlavor"
	echo $MYFQDN > /etc/hostname
	sleep 1
	sync
	if [ -f /etc/init.d/hostname.sh ]
	then
		/etc/init.d/hostname.sh stop
		/etc/init.d/hostname.sh start
	elif [ -f /etc/init.d/hostname ]
	then
		/etc/init.d/hostname stop
		/etc/init.d/hostname start
	fi
	hostname $MYFQDN
	echo $MYFQDN > /etc/hostname
	;;
freebsd-based)
        echo "Changing Server personality for $OSFlavor"
        if [ -f /etc/rc.conf ]
        then
                cat /etc/rc.conf|grep -v "hostname=" > /etc/rc.conf.TEMPORAL-OS
                echo "hostname=$MYFQDN" > /etc/rc.conf
                cat /etc/rc.conf.TEMPORAL-OS >> /etc/rc.conf
                hostname $MYFQDN
        fi
        ;;
core-os-based)
        echo "Changing Server personality for $OSFlavor"
        echo $MYFQDN > /etc/hostname
        sleep 1
        sync
        hostname $MYFQDN
        ;;
*)
	echo "OS Flavor unknown - aborting changes"
	exit 0
	;;
esac

if [ $MYFQDN == "localhost.localdomain" ]
then
	echo "FQDN is localhost based - removing any old reference"
	cat /etc/hosts | grep -v "# Host added by autoconfig" > /etc/hosts.temporal.autoconfig
	cat /etc/hosts.temporal.autoconfig > /etc/hosts
	rm /etc/hosts.temporal.autoconfig
	if [ $OSFlavor == "debian-based" ]
	then
		cat /etc/hosts | grep -v "localhost" > /etc/hosts.temporal.autoconfig
		cat /etc/hosts.temporal.autoconfig > /etc/hosts
		rm /etc/hosts.temporal.autoconfig
		echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts
	fi
else
	echo "Setting entry on /etc/hosts"
	cat /etc/hosts | grep -v "# Host added by autoconfig" > /etc/hosts.temporal.autoconfig
	cat /etc/hosts.temporal.autoconfig > /etc/hosts
	rm /etc/hosts.temporal.autoconfig
	MYSHORTNAME=`hostname -s`
	echo "$IPADDRESS $MYSHORTNAME $MYFQDN # Host added by autoconfig" >> /etc/hosts
fi

case $FIRSTRUNONLY in
yes)
	echo "Setting first run flag on $autoconfigfirstrunfile"
	echo "YES" > $autoconfigfirstrunfile
	echo "script done"
	;;
*)
	echo "No flag for first run - script done"
	;;
esac

if [ $RUNPUPPET == "yes" ]
then
	echo ""
	echo "Calling Puppet Agent with server $PUPPETSERVER"
	puppet agent --server $PUPPETSERVER --test --waitforcert=300
	echo ""
fi

# END


