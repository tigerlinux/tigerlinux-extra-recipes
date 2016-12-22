# Simple IPTABLES Tricks for Connections RATE Limiting.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

IPTABLES is the packet-filter de-facto implementation in all modern linux distributions. No matter if you use solutions like firewalld, ufw, or plain-old iptables systinit scripts, the final point is the iptables command creating rules in the kernel.

One of the things we can do with IPTABLES, is apply rates to incomming connections, which is very usefull specially for Internet-oriented services. This very short recipe will show how you can use iptables rules in order to protect your application with limits to maximun connections per origin and maximun connections per time unit.


## Limit max connections per client IP:

If you want to limit the maximun connections per origin (IP), use:

```bash
iptables -A INPUT -p tcp --syn --dport APP_PORT -m connlimit --connlimit-above MAX_CONS -j REJECT --reject-with tcp-reset
```

Where:

- APP_PORT: The application TCP port.
- MAX_CONS: The maximun connections allowed.

Example:

```bash
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 20 -j REJECT --reject-with tcp-reset
```

This example will limit to 20 connections from a single IP to the application port 443 (https). Any connection exceeding the limit will receive a tcp-reset.
 

## Limit connections rates (throttling):

You can also limit connections per time unit (connection throttling):

```bash
iptables -A INPUT -p tcp --dport APP_PORT -i NIC -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport APP_PORT -i NIC -m state --state NEW -m recent --update --seconds TIME-IN-SECONDS --hitcount MAX-CONNS -j DROP
```

Where:

- APP_PORT: The application TCP port.
- NIC: The ethernet interface.
- TIME-IN-SECONDS: The time window, in seconds.
- MAX-CONNS: Maximun connection you will allow in the time window (TIME-IN-SECONDS).

Example:

```bash
iptables -A INPUT -p tcp --dport 443 -i eth0 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 443 -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 30 -j DROP
```

This example will drop any connection that exceed the "30 connections every 60 seconds" rate limit to the port 443, comming from the eth0 network interface.


END.-
