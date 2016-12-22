# A PIRANHA-BASED SIP LOAD BALANCER FOR ASTERISK

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

We want to create a load balancer cluster, perfectly capable of load-balance simple protocols like http (port 80 over tcp), and more complex protocols like SIP over UDP on asterisk machines.


## What kind of hardware and software do we need ?:

This LAB is aimed to production, so, we'll start with a production-like setup.

For the Load Balancers, we'll use a cluster of two virtual machines (OpenStack based):

vm-172-16-11-74.cloud0.mydomain.dom: 172.16.11.74
vm-172-16-11-75.cloud0.mydomain.dom: 172.16.11.75

For our "client" machines, we'll have 3 servers:

vm-172-16-11-76.cloud0.mydomain.dom: 172.16.11.76
vm-172-16-11-77.cloud0.mydomain.dom: 172.16.11.77
vm-172-16-11-78.cloud0.mydomain.dom: 172.16.11.78

All Those machines has Centos 6 (fully updated), with EPEL Repository Installed, SELinux disabled, and IPTABLES initially disabled too.

Also, all our machines has "port-security" disabled on their openstack-based virtual NIC's (neutron ports). This will prevent normal anti-spoofing security rules to block the balancers, and specially, block the SIP protocol.

**NOTE:** In normal conditions, you don't need to disable the "port security" extension in the SIP Servers. It is just for "this balancing scenario" that you will need to do it. The way the whole solution is constructed need the openstack-instance-ports (neutron ports) fully free of normal anti-spoofing control in the SIP servers. About the load balancer, is mandatory to disable the port-security, as it will forward IP packets which source is not the load balancer servers (then, violating anti-spoofing rules).


## How it was constructed the whole solution ?:


### Piranha software installation and basic server setup:

Install the packages on both servers:

```bash
yum install ipvsadm piranha
```

Change piranha password in both servers:

```bash
piranha-passwd 123456
```

This will change the administrative piranha password to "123456". Please set the password with something more "cryptic".

Run the following commands on both servers:

```bash
chkconfig piranha-gui on
chkconfig pulse on
service piranha-gui start
```

Edit the file (both servers):

```bash
vi /etc/sysctl.conf:
```

And change the ip_forward config to "1":

```bash
net.ipv4.ip_forward = 1
```

Save the file and run:

```bash
sysctl -p /etc/sysctl.conf
```

Run the following commands (both servers):


```bash
modprobe ip_vs
chkconfig ipvsadm on
/etc/init.d/ipvsadm start
```

On both servers, create the file:

```bash
vi /etc/sysconfig/modules/ip_vs.modules
```

Containing:

```bash
/sbin/modprobe ip_vs
```

Save the file and make it exec:

```bash
chmod 755 /etc/sysconfig/modules/ip_vs.modules
```

Configure a bi-directional ssh trust between both servers. As this is very basic, we'll not explain it here. Just remember to create your keys with `"ssh-keygen -t rsa"` and deploy them with `"ssh-copy-id"`. You'll end with an `/root/.ssh/authorized_keys` containing the public key.

Finally, we enter to the first server "Piranha" web admin:

* Url: http://172.16.11.74:3636
* Admin user: piranha
* Admin password (the one previouslly set): 123456

Go to "REDUNDANCY" Tab, click on Enable, and set in "redundant server public IP" the IP of our second node: 172.16.11.75


### WEB and SIP services basic setup (Real Servers).

Before we setup our VIP's on the balancer, wee need our 3 servers ready to serve both http and sip.

Our 3 client servers IP's (as mentioned before) are:

172.16.11.76
172.16.11.77
172.16.11.78

All 3 servers are Centos 6 with EPEL, iptables/selinux disabled.

On all 3, we install and enable apache:

```bash
yum -y install httpd
chkconfig httpd on
/etc/init.d/httpd start
```

And enabled a default html file with the server fqdn as only content:

```bash
hostname > /var/www/html/index.html
```

We install/enable asterisk too (for the SIP service part):

```bash
yum -y install asterisk asterisk-sounds-core-en dahdi-tools dahdi asterisk-dahdi asterisk-sounds-core-en-gsm
/etc/init.d/asterisk start
chkconfig asterisk on
```

Our 3 servers will be running both Apache (port 80 tcp) and asterisk (port 5060 udp).


### Balanced Services Creation: Web Service

We will add the VIP 172.16.11.210. This VIP will serve HTTP.

First thing to do, is create a "loopback" alias in all 3 servers (our client machine) with the VIP IP. This is part of the trick for successfull balancing with piranha and ipvs when the VIP's and the RIP's are in the same IP space. Also, is mandatory for SIP balancing:

On the client servers, create the file:

```bash
vi /etc/sysconfig/network-scripts/ifcfg-lo:1
```

Containing:

```bash
DEVICE=lo:1
IPADDR=172.16.11.210
NETMASK=255.255.255.255
ONBOOT=yes
NAME=loopback
```

Save the file.

Also, modify sysctl.conf:

```bash
vi /etc/sysctl.conf:
```

Add/modify:

```bash
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.eth0.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.eth0.arp_announce = 2
net.ipv4.ip_forward = 1
```

Save the file and execute the following commands:

```bash
sysctl -p
ifup lo:1
```

The last two commands will create the "loopback" interface lo:1 with IP 172.16.11.210 and set the extra kernel config items needed for the balancing to work !.

Note: Next is optional if you want a better html file instead of "hostname > /var/www/html/index.html":

On the 3 client servers:

```bash
vi /var/www/html/index.html:
```

Containing:

```html
<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
   <HEAD>
      <TITLE>
         A Small Hello
      </TITLE>
   </HEAD>
<BODY>
   <H1>Hi</H1>
   <P>Server-XX</P>
</BODY>
</HTML>
```

Change the "XX" with 01, 02 and 03 depending of the server.

Go to the balancer web interface (http://172.16.11.74:3636) and create the web service with the following data:

- VIP: 172.16.11.210, port tcp 80
- RIP 1: Server-01, 172.16.11.75
- RIP 2: Server-02, 172.16.11.76
- RIP 2: Server-03, 172.16.11.77

Activate the Virtual and Real Servers.

In the 172.16.11.74 Piranha Server, activate pulse service:

```bash
chkconfig pulse on
/etc/init.d/pulse start
```

Then, copy the LVS configuration from the piranha server 172.16.11.74 to the .75:

```bash
scp /etc/sysconfig/ha/lvs.cf 172.16.11.75:/etc/sysconfig/ha/
```

And, in the piranha server 172.16.11.75, start "pulse" service:

```bash
chkconfig pulse on
/etc/init.d/pulse start
```

At this point, the WEB service is fully active in the VIP: http://172.16.11.210.

Also, if the first piranha service goes down, the second one will take the VIP and LVS service.


### Balanced Services Creation: SIP Service

First, and because we want to include some stress testing, let's create some items in our asterisk's

Add a sip account on asterisk (on all 3 client servers):

```bash
vi /etc/asterisk/sip.conf
```

Add at the end:

```bash
[777]
type=friend
host=dynamic
secret=password
context=piranha
disallow=all
allow=ulaw
allow=alaw
```

And an extension:

```bash
vi /etc/asterisk/extensions.conf
```

Add at the end:

```bash
[piranha]
; extn 100
exten => 100,1,Answer()
exten => 100,n,Playback(demo-thanks)
exten => 100,n,Playback(hello-world)
exten => 100,n,Playback(tt-monkeys)
exten => 100,n,Hangup()
```

Restart asterisk:

```bash
/etc/init.d/asterisk restart
```

Remember: You must do this on all 3 asterisk's.

Next, we'll create our VIP for the SIP Service: VIP IP: 172.16.11.211.

Enter to the balancer web interface (http://172.16.11.74:3636) and create the service:

- VIP: 172.16.11.211, port udp 5060, mode "firewall mark", mark: 3.
- RIP 1: SIP-Server-01, 172.16.11.75, 5060
- RIP 2: SIP-Server-02, 172.16.11.76, 5060
- RIP 3: SIP-Server-03, 172.16.11.77, 5060

For SIP, we should use "firewal mark" mode, and set the mark with something we'll use later in IPTABLES.

Web creating the service, set the following as "monitoring script":

- Sending Program: /usr/local/bin/test-sip-server.sh %h
- Send (click on "blank send")
- Expect: OK

Create the script on the piranha server 172.16.11.75:

```bash
vi /usr/local/bin/test-sip-server.sh
```

Containing:

```bash
#!/bin/bash
#

PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

mytest=`nmap -v -sU $1 -p 5060|grep -c "open"`

case $mytest in
1)
        echo "OK"
        ;;
*)
        echo "FAIL"
        ;;
esac
```

Save the file and make it exec:

```bash
chmod 755 /usr/local/bin/test-sip-server.sh
```

This script will be our basic "keepalive" script. If any of the asterisk servers die and stop serving udp port 5060, the script will return "FAIL" instead of "OK" and the lvs service will cease sending connections to the failed/dead server.

In the piranha web interface activate both real and virtual servers.

From the 172.16.11.74 server, copy (with scp) both the config and the keepalive script to the .75:

```bash
scp /etc/sysconfig/ha/lvs.cf 172.16.11.75:/etc/sysconfig/ha/

scp /usr/local/bin/test-sip-server.sh 172.16.11.75:/usr/local/bin/
```

Then, in both piranha servers (172.16.11.74 and 75) execute the following commands:

```bash
/etc/init.d/iptables start

iptables -t mangle -A PREROUTING -p tcp -d 172.16.11.211 --dport 5060 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p tcp -d 172.16.11.211 --dport 5061 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p udp -d 172.16.11.211 --dport 5060 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p udp -d 172.16.11.211 --dport 5061 -j MARK --set-mark 3

/etc/init.d/iptables save
chkconfig iptables on

/etc/init.d/pulse restart
```

In the 3 real servers (our Asterisk Servers), create the loopback with the IP 172.16.11.211:

```bash
vi /etc/sysconfig/network-scripts/ifcfg-lo:2
```

Containing:

```bash
DEVICE=lo:2
IPADDR=172.16.11.211
NETMASK=255.255.255.255
ONBOOT=yes
NAME=loopback
```

And, activate the new loopback:

```bash
ifup lo:2
```

At this point, our VIP "172.16.11.211" is serving SIP (port udp 5060). We connected a SIP phone to the VIP "172.16.11.211" with the previouslly created sip account (777) and made a call to the extension "100". Of course, everything worked OK.

**NOTE:** If you add aditional SIP services, use a different firewall-mark for each one.

If we see our LVS configuration:

File: /etc/sysconfig/ha/lvs.cf

Contents:

```bash
serial_no = 70
primary = 172.16.11.74
service = lvs
backup_active = 1
backup = 172.16.11.75
heartbeat = 1
heartbeat_port = 539
keepalive = 6
deadtime = 18
network = direct
debug_level = NONE
monitor_links = 0
syncdaemon = 0
virtual web01 {
     active = 1
     address = 172.16.11.210 eth0:1
     port = 80
     send = "GET / HTTP/1.0\r\n\r\n"
     expect = "HTTP"
     use_regex = 0
     load_monitor = none
     scheduler = wlc
     protocol = tcp
     timeout = 6
     reentry = 15
     quiesce_server = 0
     server server-01 {
         address = 172.16.11.76
         active = 1
         port = 80
         weight = 1
     }
     server server-02 {
         address = 172.16.11.77
         active = 1
         port = 80
         weight = 1
     }
     server server-03 {
         address = 172.16.11.78
         active = 1
         port = 80
         weight = 1
     }
}
virtual sipserver {
     active = 1
     address = 172.16.11.211 eth0:2
     vip_nmask = 0.0.0.0
     fwmark = 3
     port = 5060
     persistent = 400
     expect = "OK"
     use_regex = 0
     send_program = "/usr/local/bin/test-sip-server.sh %h"
     load_monitor = none
     scheduler = wlc
     protocol = udp
     timeout = 6
     reentry = 15
     quiesce_server = 0
     server SIP-Server-01 {
         address = 172.16.11.76
         active = 1
         weight = 1
     }
     server SIP-Server-02 {
         address = 172.16.11.77
         active = 1
         weight = 1
     }
     server SIP-Server-03 {
         address = 172.16.11.78
         active = 1
         weight = 1
     }
}
```

Note that the setting "persistent = 400" was added directly in the config file. Depending of your service, you'll want to include session-persistence for your clients. That's where "persistent = SECONDS" enters. You can avoid the piranha web admin usage and set everything directly in the configuration file if you want. Just remember to "scp" your file from the active piranha server to the standby one and later restart the pulse service (service pulse restart).


### SIP Service stress test with SIPP

We are going to do some stress testing with SIPP, but first we'll modify some settings in piranha config (lvs.cf):

```bash
syncdaemon = 1
syncd_iface = eth0
syncd_id = 0
tcp_timeout = 10
tcpfin_timeout = 10
udp_timeout = 10
```


Also, the SIP service load-balancing mode was changed to "Weighted Least Connections":

```bash
     scheduler = wlc
```

And removed the "persistent = 400" from the SIP Service too.

This was done on both piranha servers, then we restarted the "pulse" service:

```bash
/etc/init.d/pulse restart
```

For the SIPP software, we used a Fedora 22 workstation (IP: 172.16.0.236) and installed SIPP on the machine:

```bash
dnf install sipp
```

In all 3 asterisk servers, we proceed to include the accounts an extensions that we'll use SIPP:

Sip account:

```bash
vi /etc/asterisk/sip.conf
```

Add:

```bash
[sipp]
type=friend
context=sipp
host=dynamic
user=sipp
insecure=invite,port
canreinvite=no
disallow=all
allow=ulaw
allow=alaw
```

Extension:

```bash
vi /etc/asterisk/extensions.conf
```

```bash
[sipp]
exten => 200,1,Answer
exten => 200,n,SetMusicOnHold(default)
exten => 200,n,WaitMusicOnHold(30)
exten => 200,n,Hangup
```

Then, restart asterisk:

```bash
/etc/init.d/asterisk restart
```

We the 3 asterisk's ready, we proceed to execute the test in the Fedora machine:

```bash
sipp -sn uac -d 20000 -s 200 -l 200 -r 20 -t un -i 172.16.0.236 172.16.11.211
```

In the active piranha node, we proceed to watch the connections running the command:

```bash
watch -n 1 ipvsadm -L -n
```

The result:

```bash
Every 1,0s: ipvsadm -L -n         Tue Jul 14 14:14:16 2015

IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.11.210:80 wlc
  -> 172.16.11.76:80              Route   1     0          0
  -> 172.16.11.77:80              Route   1     0          0
  -> 172.16.11.78:80              Route   1     0          0
FWM  3 wlc
  -> 172.16.11.76:5060            Route   1     0          69
  -> 172.16.11.77:5060            Route   1     0          69
  -> 172.16.11.78:5060            Route   1     0          69
```

This show's the proper balancing across all members of the SIP service.

Our command: "sipp -sn uac -d 20000 -s 200 -l 100 -r 20 -t un -i 172.16.0.236 172.16.11.211" means:

* -sn uac: Default test scenario "uac" (Standard SipStone UAC (default)).
* -d 20000: Maximun call duration (20 seconds).
* -s 200: Extension to call (this was defined on asterisk).
* -l 100: Simultaneous calls limit.
* -r 20: Call rate: The calls are generated at a rate of 20 each second.
* -t un: Each call has it's own socket in the client (this is needed in order to test the load balancing).
* -i 172.16.0.236: Origin IP in the SIP messages.
* 172.16.11.211: SIP Server.

The lvs.cf configuration for our test:

```bash
serial_no = 76
primary = 172.16.11.74
service = lvs
rsh_command = ssh
backup_active = 1
backup = 172.16.11.75
heartbeat = 1
heartbeat_port = 539
keepalive = 6
deadtime = 18
network = direct
debug_level = NONE
monitor_links = 0
syncdaemon = 1
syncd_iface = eth0
syncd_id = 0
tcp_timeout = 10
tcpfin_timeout = 10
udp_timeout = 10
virtual web01 {
     active = 1
     address = 172.16.11.210 eth0:1
     port = 80
     send = "GET / HTTP/1.0\r\n\r\n"
     expect = "HTTP"
     use_regex = 0
     load_monitor = none
     scheduler = wlc
     protocol = tcp
     timeout = 6
     reentry = 15
     quiesce_server = 0
     server server-01 {
         address = 172.16.11.76
         active = 1
         port = 80
         weight = 1
     }
     server server-02 {
         address = 172.16.11.77
         active = 1
         port = 80
         weight = 1
     }
     server server-03 {
         address = 172.16.11.78
         active = 1
         port = 80
         weight = 1
     }
}
virtual sipserver {
     active = 1
     address = 172.16.11.211 eth0:2
     fwmark = 3
     port = 5060
     expect = "OK"
     use_regex = 0
     send_program = "/usr/local/bin/test-sip-server.sh %h"
     load_monitor = none
     scheduler = wlc
     protocol = udp
     timeout = 6
     reentry = 15
     quiesce_server = 0
     server SIP-Server-01 {
         address = 172.16.11.76
         active = 1
         weight = 1
     }
     server SIP-Server-02 {
         address = 172.16.11.77
         active = 1
         weight = 1
     }
     server SIP-Server-03 {
         address = 172.16.11.78
         active = 1
         weight = 1
     }
}
```

After you finish your tests, you can add again "persistent = 400" to the SIP Service (or whatever persistence you consider appropriate for your environment).


## Extra notes for multi port services.

You can add multi-port services in piranha too, mean, services with only a VIP, but with multiple ports. For that to work, define the service with a "firewall mark". Sample:

```bash
virtual multiportservice01 {
     active = 1
     address = 172.16.31.204 eth0:2
     vip_nmask = 0.0.0.0
     fwmark = 80
     port = 80
     persistent = 3600
     send = "GET / HTTP/1.0\r\n\r\n"
     expect = "HTTP"
     use_regex = 0
     load_monitor = none
     scheduler = wlc
     protocol = tcp
     timeout = 6
     reentry = 15
     quiesce_server = 0
     server multiport-server-01 {
         address = 172.16.31.78
         active = 1
         port = 80
         weight = 1
     }
     server multiport-server-02 {
         address = 172.16.31.79
         active = 1
         port = 80
         weight = 1
     }
}
```

And add an iptable line for each port with the same firewall mark:

```bash
iptables -t mangle -A PREROUTING -p tcp -d 172.16.31.204 --dport 80 -j MARK --set-mark 80
iptables -t mangle -A PREROUTING -p tcp -d 172.16.31.204 --dport 6969 -j MARK --set-mark 80
iptables -t mangle -A PREROUTING -p tcp -d 172.16.31.204 --dport 6970 -j MARK --set-mark 80
```

This will load balance all ports with the same VIP and the same firewall mark (80 for this example).

END.-
