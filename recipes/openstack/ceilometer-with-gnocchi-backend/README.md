# OPENSTACK CEILOMETER WITH GNOCCHI STORAGE BACKEND.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

OpenStack Ceilometer is the cloud component which function is to collect and store resource usage metrics comming from all the other components present on the cloud. This include performance metrics from the Nova Compute instances, storage metrics from both Cinder and Swift (Cloud Storage), and some other metrics from Neutron (Networking) and other OpenStack projects (like sahara, trove, etc.).

All those metrics are stored as "samples" in a Database Backend, normally NO-SQL based, being MongoDB as the main option currently used in production environments.

But, even MongoDB being a non-sql solution can "bottleneck" Ceilometer operations, specially in very big environments with a lot of collected data.

Recently, a new component is begining to gain in the "Ceilometer Storage Backend" arena. Its name: [Gnocchi.](https://wiki.openstack.org/wiki/Gnocchi)

Gnocchi, is it's purest form, is more than a storage backend for Ceilometer. It's a "Time Series Database as a Service" (TDBaaS) with a complete RESTFULL API, allowing a degree of distribution and scalability which MongoDB cannot achieve. This means for Ceilometer: No more bottlenecks and more scalability.

While "up to Mitaka release" we still need to stick with Mongo (as some ceilometer functions are not correctly working yet with gnocchi as db backend), still it promises a lot and surelly will be in the following openstack releases the "de-facto" option for Ceilometer in great range of OpenStack deployments.


## What recipes you'll find here ?:

Just one and very simple recipe that will allow you to install Gnocchi on Centos 7 and modify Ceilometer in order to use Gnocchi as storage backend.

* [RECIPE: OpenStack Ceilometer with Gnocchi Storage Backend, in markdown format.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/ceilometer-with-gnocchi-backend/RECIPE-ceilometer-with-gnocchi-backend.md "OpenStack Ceilometer with Gnocchi Backend")

Remember: Gnocchi is not only a database storage solution for Ceilometer... it is a complete solution by itself !!.
