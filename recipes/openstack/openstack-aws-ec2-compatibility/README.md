# OPENSTACK AWS EC2 COMPATIBILITY

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

Up to recent OpenStack releases (being kilo the last version oficially supported for EC2), NOVA (the compute component of OpenStack) had very limited EC2 compatibility. On Liberty, this compatibility layer entered in "deprecation" state, and from Mitaka is no longer available in Nova.

Lucky us, a group from the OpenStack community decided to re-include EC2 support, and created a "more robust and complete" AWS-EC2 compatibility layer, even with VPC Support:

* [AWS-EC2 OpenStack Project Site at Github.](https://github.com/openstack/ec2-api)

While is not considered part of the OpenStack core modules (yet), it still offer more than old EC2 compatibility on Nova up to Kilo. The EC2 support can be installed in the last 3 more recents OpenStack versions: Kilo, Liberty and Mitaka.

We'll explore in our recipes how to properlly install it on an already-working cloud, and how to use it for EC2 instance creation, both EC2-Classic and EC2-VPC.


## What recipes you'll find here ?:

In the following links you'll find our two recipes. The first one uses Centos 7 packages (available on Centos Cloud Repo for Liberty and Mitaka), the second one uses the source packages from GIT EC2 Project Site. A full LAB is included in the Centos 7 recipe.

* [RECIPE: OpenStack AWS-EC2 Compatibility and LAB - Centos 7, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/openstack-aws-ec2-compatibility/RECIPE-aws-ec2-openstack-compat-lab.md "OpenStack AWS-EC2 Compat - Centos 7")
* [RECIPE: OpenStack AWS-EC2 Compatibility - Ubuntu 14.04lts, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/openstack-aws-ec2-compatibility/RECIPE-aws-ec2-openstack-compat-ubuntu.md "OpenStack AWS-EC2 Compat - Ubuntu 1404lts")
