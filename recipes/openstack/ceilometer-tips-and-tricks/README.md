# CEILOMETER TIPS AND TRICKS

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

OpenStack is a moster cloud-computing set of many modules, each one with a very specific task in the cloud environment. One of the tasks needed on any system you run as sysadmin, and of course needed by OpenStack too, is the proper monitoring of your infrastructure, and if you are running a multi-tenant system, the proper metric gathering for posible billing purposes. 

This is the specific task of "Ceilometer": The collection and storage of system metrics oriented to resource usage in your cloud environment.


## What recipes you'll find here ?:

Mostly, practical usage of ceilometer metrics and alarms. Normally, most users beggining in OpenStack just see the metrics displayed on the Horizon Web-Dashboard, but, this is very limiting as the "client tools" (AKA: "cli") "really extends" all the operations you can perform in order to obtain the collected metrics in the most efficient and complete way.

Then, for the moment, we'll show you two recipes here: One who will show you the most usefull tips-and-trics for obtain what you need, and the other, for eficient and creative use of ceilometer alarming system.

* [RECIPE: Ceilometer tips-and-tricks, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/ceilometer-tips-and-tricks/RECIPE-ceilometer-tips-and-tricks.md "Ceilometer Tips-and-Trics Recipe")
* [RECIPE: Ceilometer Alarms, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/ceilometer-tips-and-tricks/RECIPE-ceilometer-alarms.md "Ceilometer Alarms - A practical Example")
