# A HEAT TEMPLATE WITH AUTOSCALING AND LBAAS V2 FOR OPENSTACK MITAKA

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

In AWS, the way you normally automate the deployment of a complete infrastructure, is by the use of **Cloudformation** templates. With [Cloudformation](https://aws.amazon.com/cloudformation/), you can provision almost anything that will live in the cloud, and define events and structures that will allow your platform to adapt automatically ("auto-scale") to changes in the incomming load.

Of course, OpenStack has it's own "Cloudformation" implementation, called "Orchestration", and performed by the "HEAT" component.

Heat supports many [AWS Cloudformation objects](http://docs.openstack.org/developer/heat/template_guide/cfn.html), but, it also supplies it's [own collection of objects](http://docs.openstack.org/developer/heat/template_guide/openstack.html). Those objects allow you to create any kind of resource in the cloud: instances, networks, security groups, ports, load balancers, ceilometer alarms, etc.

The same way yo do in AWS, you can define a AutoScaling group in HEAT. This AutoScaling group will "scale-up" and "scale-down" (add and delete instances to the group) in response to events (alarms) defined in the same HEAT template. Those alarms, are based on ceilometer/aodh, and they trigger following changes on measured metrics inside ceilometer.

So, for this to work properly, you need: Heat, Ceilometer and aodh along common OpenStack components.

The other important item on a HEAT AutoScaling group is the Load Balancer. If you plan to allow your "Orchestrated" solution to load-balance itself, you must also include a LBaaS definition in the HEAT template, and, ensure the instances, once they become available (and install by themselves the proper software by meaning of user-data), are registered as "members" of the LBaaS in the OpenStack cloud.

If you want to read more about current HEAT implementation, click on the following links:

* http://docs.openstack.org/developer/heat/index.html
* http://docs.openstack.org/developer/heat/template_guide/index.html


## Why LBaaS V2 ?:

From Mitaka, most LBaaS implementations changed to V2. As a consecuence, the way we construct a LBaaS in OpenStack changed, and this is also reflected on HEAT. The objects from LBaaSV1 and LBaaSV2 are very different, so, any template needing to define LBaaSV2 components must be adapted accordingly.


## What this template does ?:

This template basically create the following objects:

* A Security group allowing icmp, and ports "tcp" and "80" (port "80" can be changed in the template by modifying the proper parameters).
* A LBaaS V2, with pool and listener.
* A AutoScaling group which will contain the instances. Initially, the autoscaling group will spawn one instance, and allow bewteen one and five instances according to pre-defined events.
* Two AutoScaling policies, one for spawning extra instances, and one for deleting instances.
* One "cpu-high" alarm, which, if the instances in the autoscaling group exceeds a predetermined cpu usage percent threshold, will call the "scale-up" policy in the autoscaling group in order to add more instances, up to 5, with each threshold violation.
* One "cpu-low" alarm, which, if the instances in the autoscaling group fall bellow a predetermined cpu usage percent threshold, will call the "scale-down" policy in the autoscaling group in order to delete instances, up to leave the group with only one instances with each threshold violation.
* A server-definition which function is to create the nova-based instances, and pass to it proper configuration values including "user-data" bootstrap scripts which will install the web application (apache or nginx) according with parameters set on the main HEAT template. This definition also has a "trick" that will (if you don't comment it out) artificially create a "high cpu usage" inside the instance in order to demostrate the "scape-up" policy. Please modify this part of the template when you use it for production systems.

After you pass this template to HEAT, it will create your objects and define your scale-up/scale-down events, so, any change in the load will reflect a change in your provisioned platform.


## How can I use this template ?: 

Our template main template is the following file:

* [AutoScaling with LBaaS V2 Heat MAIN Template.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/autoscaling-with-lbaasv2/Template-AutoScaling-LBaaSV2.yaml)

This template is the core of our AutoScaling+LBaaSV2 implementation. It will also require one of the two following files:

* [AutoScaling Environment File - For use with heat "CLI" and locally copied "Server File".](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/autoscaling-with-lbaasv2/Template-AutoScaling-LBaaSV2-ENV-LocalCLI.yaml)
* [AutoScaling Environment File - For use with heat "CLI" or Horizon and Web-Stored "Server File".](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/autoscaling-with-lbaasv2/Template-AutoScaling-LBaaSV2-ENV-HTTP-Server.yaml)

And, the following file, which defines the server instance and the LBaaS member:

* ["Server File" with "Nova Instance" and "LBaaS Member" definitions](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/openstack/autoscaling-with-lbaasv2/webserver_lb.yaml)

You can use those templates with HEAT cli, or with Horizon.

If you want to use the HEAT cli, copy all files to a specific location, source your keystone credentials, modify the parameters in the main template, and execute the following command:

```bash
heat stack-create \
-f Template-AutoScaling-LBaaSV2.yaml \
-e Template-AutoScaling-LBaaSV2-ENV-LocalCLI.yaml \
-r \
my-stack-with-lbaasv2-and-autoscaling
```

NOTE: You need to have all files in the same directory, specially the file "webserver_lb.yaml".

If you don't want to change the parameters inside the main template, you can set the parameters from heat. Sample:

```bash
heat stack-create \
-f Template-AutoScaling-LBaaSV2.yaml \
-e Template-AutoScaling-LBaaSV2-ENV-LocalCLI.yaml \
-P my_flavor="m1.normal"\
-P my_accesskey="my-super-ssh-key"\
-P my_image="Ubuntu-1404lts-32-Cloud"\
-r \
my-stack-with-lbaasv2-and-autoscaling
```

See the main heat template section where all possible parameters are described.

If you want to use Horizon, you need to do some extra things:

* First, copy your "webserver_lb.yaml" file to a web server, so Heat can reach it using an URL.
* Second, modify the "webserver_lb.yaml" URL in the "autoscaling-with-lbaasv2/Template-AutoScaling-LBaaSV2-ENV-HTTP-Server.yaml" environment template.
* Next, in horizon, use the main template file (Template-AutoScaling-LBaaSV2.yaml) and the environment file you just modified (Template-AutoScaling-LBaaSV2-ENV-HTTP-Server.yaml). The HEAT web panel will allow you to choose the proper parameters and launch the HEAT Stack from those two files, and the "web located" "webserver_lb.yaml" file.

**VERY IMPORTANT NOTE:** The bootstrap secuence in the "webserver_lb.yaml" file consider options to install apache or nginx in the following possible linux distros: Centos 6, Centos 7, Debian 7 and Ubuntu 14.04lts. If you plan to use any other distro, please make the proper changes to the bootstrap secuence.


## About ceilometer:

In it's default form, Ceilometer take metrics every 600 seconds (10 minutes). This means, your alarms will trigger potentially every 10 minutes. This can be slow if you want your system to react faster to changes on system loads.

If you want ceilometer to report every less seconds, change the pipeline definitions:

```bash
sed -r -i 's/600/60/g' /etc/ceilometer/pipeline.yaml
```

Then restart ceilometer !. With this change, ceilometer will take measurements every 60 seconds (one minute) making your templates able to act quickly !. Take into account that this also means more pressure over your ceilometer installation, specially in terms of database space and I/O. 

You can see the state of your metrics and alarms by using the following commands (remember to source your keystone credentials):

```bash
ceilometer statistics -m cpu_util -q metadata.user_metadata.stack=`heat stack-list|grep my-stack-with-lbaasv2-and-autoscaling|awk '{print $2}'` -p 60 -a avg

+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 60     | 2016-02-23T18:39:43 | 2016-02-23T18:40:43 | 52.4237288136 | 0.0      | 2016-02-23T18:40:09 | 2016-02-23T18:40:09 |
| 60     | 2016-02-23T18:40:43 | 2016-02-23T18:41:43 | 99.9333333333 | 0.0      | 2016-02-23T18:41:09 | 2016-02-23T18:41:09 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

This sample assumes you named your stack "my-stack-with-lbaasv2-and-autoscaling". Change the name to suit your real stack name !.

END.-
