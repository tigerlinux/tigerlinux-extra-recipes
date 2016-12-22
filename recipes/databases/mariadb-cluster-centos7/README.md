# A MARIADB 10.1 ACTIVE/ACTIVE MULTIMASTER SYNCHRONOUS CLUSTER FOR THE CLOUD.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

This recipe, which I currently use in production in the cloud (OpenStack LBaaS environments), will allow you to create a **"highly available"** mariadb 10.1 synchronous cluster that you can load-balance behind any cloud-lbaas (load balancer as a service).

The installation is pretty simple, but the performance behind lbaas is outstanding. For this recipe, we'll use for the test only 2 servers, but for production systems you should use the magic number of "3 nodes". All is Centos 7 based, but, you can adapt it to other distros supporting MariaDB 10.1.

## What kind of hardware and software you need ?.

We just need 2 servers (virtual or bare-metal), with enouth cpu and ram to suit your needs, and, two hard disks or volumes, one for the operating system, the other one for the database storage.

About the software: Centos 7 with EPEL, selinux and firewalld disabled.

## Why those OS requeriments ?:

* Centos 7: Is the base of our production recipe. Of course you can adapt this to other O/S as long as the components are available. MariaDB 10.1 repos are available for many distros so yo will not have any problem if you want to go ubuntu or debian. Just ensure to work with the last stable version of your prefered distro.
* EPEL: This repo is the best addition to any Centos/RHEL based production system. I strongly recommend to install it !!. Also, really... What is a Centos machine without EPEL ???. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL
* SELINUX: Disabled just to ensure it will not interfere with mariadb 10.1. You can try to enable and adjust it after you have everything running.
* FIREWALLD: Because our LAB was conducted in a private cloud (OpenStack) environment, we prefer to use the "cloud" security groups instead the local firewall inside the servers. Of course, you can reenable firewall-d later and adjust it. Remember to open the MariaDB related ports.

## Why we recommend 3 servers (or more) for production systems ?:

This is not only a active/active solution. This is a fully load-balanced solution where you will put in front of the servers a LBaaS VIP that will distribute the load accross all active nodes. So, the escaling is horizontal, and for that case, 3 or more is best suited for this kind of production database service. You should calculate your load based on N-1, and enable redundancy. That means two servers "minimun" to whitstand all load ("N"), and one extra in order to keep going with the same load and be redundant too "(N-1)". This is also known as "N+1" redundancy. See https://en.wikipedia.org/wiki/N%2B1_redundancy for more information.

## What knowledge should you need to have at hand ?:

* General Linux administration.
* MariaDB administration.
* Optional: Cloud Computing (OpenStack, AWS) just if you are going to deploy this recipe in a cloud.

## What files you'll find here ?:

* [RECIPE-Cluster-MariaDB-10.1-C7.md: Our recipe, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/databases/mariadb-cluster-centos7/RECIPE-Cluster-MariaDB-10.1-C7.md "Our MariaDB Cluster Recipe")
* [scripts: Directory with scripts referenced by our recipe.](https://github.com/tigerlinux/tigerlinux.github.io/tree/master/recipes/databases/mariadb-cluster-centos7/scripts "Our Recipe Support Scripts")

