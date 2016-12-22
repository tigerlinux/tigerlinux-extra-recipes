# A SQUID INSTALLATION WITH STEROIDS (C-ICAP/SQUIDCLAMAV/SQUIDGUARD) ON CENTOS 7.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

By far, squid is the most widely used web-caching proxy solution in the OpenSource world. If you work on a company and need to provide control over your user's internet access, and prefer to use OpenSource, then this recipe is for you.

This recipe uses not only squid, but also:

* SquidClamav/Clamav/C-Icap for AntiVirus filtering: Every and each file your users try to access will be scanned, and if a content is detected as "malign", it will be blocked and the user will be redirected to an alert page.
* SquidGuard for URL-and-Domain black/white-listing: The SquidGuard component will check if the url is blacklisted, and again, will block the access to the site and redirect the user to an alert page.

Both components work's slaved to Squid, so, you don't need to configure extra things on the client side, but only the proxy access.


## What kind of software or hardware do we need ?:

For starter, you need a capable centos-7 based machine with [EPEL repository](https://fedoraproject.org/wiki/EPEL) enabled and available, and **SELinux/FirewallD are disabled**. You can also deploy this solution in a cloud environment and even load-balance it accross multiple server's using any cloud-based load-balancer (example: OpenStack LBaaS).

If you go for bare-metal, document yourself about squid common hardware needs and sizing before proceed.


## Our recipe.

This recipe is based on Centos 7 with EPEL repo. Of course you can use RHEL or Scientific Linux too if you want, but, the EPEL repo is **mandatory** due the fact that some of the packages used by our recipe are located in EPEL.

With no more delay, find our recipe in the following link:

* [A Squid Installation with Blacklisting and Virus Scanning](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/networkapps/squid-with-steroids/RECIPE-Squid-with-steroids.md "A Squid Installation with Blacklisting and Virus Scanning")

