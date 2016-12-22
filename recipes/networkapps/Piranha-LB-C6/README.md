# A PIRANHA-BASED SIP LOAD BALANCER FOR ASTERISK

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

If you have worked with SIP before and tried to load-balance it with any standard layer4 IP load balancer, the you probably know how difficult it is to perform such task due the nature of SIP behaviour. Not only due the fact that SIP is (normally) UDP based, but also because the way SIP works.

I'm not entering here in the very-complex details of SIP. Instead, I'll go directly to a SIP load balancer solution perfectly usable in production environments with asterisk and other opensource SIP implementations.


## What kind of hardware and software do we need ?:

This is based on Centos 6. The solution used (piranha) is no longer available on Centos 7, but it works flawlessly on Centos 6 so you can stick with this distro as long as you want. The solution is clusterized, so, two servers (mine are Virtual, OpenStack based) are needed.


## What about the security system if I'm running this in OpenStack ?:

Normally, the anti-spoofing rules in OpenStack will prevent any "IP Network Load Balancer" to do it's job. Lucky us, from KILO Series, OpenStack has the way to disable the anti-spoofing security for ports that will be part of any "special network appliance", namely, "IP Load Balancers". This is called "port security extension" and you can disable it "per-port" without affecting other openstack services or machine instances (vm's).

Basically, after you create your instances, search for they port ID's, and update them the following way:

```bash
neutron port-update --port-security-enabled=False INSTANCE_PORT_UUID
```

If you have a cluster of load balancers (two servers), and each one is using 1 NIC's (most common config), you'll have to do this on all 2 port's. Before you disable "port security", you need to remove all security groups on the instance. Also, in the SIP servers, you'll probably need to do the same (remove all security groups and disable port security). Due the way we'll going to load-balance SIP, is better if OpenStack security system does not get in the way.


## Our recipe.

This recipe is based on Centos 6 **"piranha"** load balancer, and, for the sake of completeness we'll include a complete lab with both web and sip (asterisk) server, including some stressing.

I have to let you know: I have this kind of balancer working in production, load-balacing tousands of daily calls, and everything is "piranha" and "asterisk" (call-center application). The whole stuff works, and works pretty well !.

With no more delay, find our recipe in the following link:

* [A Piranha-Based SIP Load Balancer for Aterisk](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/networkapps/Piranha-LB-C6/RECIPE-Piranha-LB-For-SIP.md "A Piranha-Based SIP Load Balancer for Asterisk")
