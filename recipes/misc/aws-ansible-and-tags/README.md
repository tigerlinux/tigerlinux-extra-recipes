# USING AWS TAGS FOR SERVICES DISCOVERY - A SIMPLE EXERCISE USING AWS CLI AND ANSIBLE AND SOME SMART SCRIPTING TO AUTOMATE TASKS.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## The exercise target. What we want to acomplish here ?:

This is a simple exercise that will show you many different ideas for your day-to-day in AWS:

- Usage of "tags" as a basic way to discover things running in the AWS cloud (without the need of a dedicated discovery layer solution like consul, etcd, etc.).
- Usage of Ansible as a tool to quickly provision AWS instances, autoscaling groups, load balancers, etc., in AWS as an alternative to cloudformation templates.
- How to keep changes on a the running instances in an application layer, then using those changes to rebuild the configuration of a specific software and reload it.


## Services discovery in the cloud. Why are so important ?:

One of the best features or all modern clouds is the [AutoScaling](https://en.wikipedia.org/wiki/Autoscaling). Using this feature, you can set alarms on specific metrics that will trigger scale-up or scale-down events, making your deployment completely elastic and capable to adapt to changing load conditions. This behaviour though, can imply extra chalenges if you have specific applications that need to know which specific instances are running in a moment in time, or, during all the time your system is running. This is where services discovery enters.

The "services discovery" software (or layer) will keep a up-to-date list of all running machines in your deployment, so statefull components in your cloud can now, by example, all the IP's of the currently run servers in a specific application layer.


## But, we really need a service discovery layer like consul, etcd, etc ?:

Normally, when a stateless load balancer or reverse proxy needs to know about which servers need to interact with, a service discovery mechanism is needed so the reverse-proxy software can "query" the discovery system and obtain the IP or IP's that will be attached to a specific service in a VIP on in a load-balancing group.

This almost always means the following, specially if the application layer which the reverse-proxy will load-balance is into an "auto-scaling group" in any cloud service:

- The servers can be spawned and deleted without any control from the reverse proxy layer. This is an actual feature of AutoScaling in the cloud.
- Each time a new server is spawned (scale-out) in the application layer autoscale group, its IP must be included in the discovery layer. The reverse proxy layer (each server on it) must be informed of the change, or at least, it must be able to, from time-to-time (crontab based maybe) query the discovery layer in order to reconstruct its configuration and include the new servers.
- Likewise, if the app layer shrinks (scale-down events, or any other event which destroys servers in the app layer), the proxy layer must be informed, so their configuration gets refreshed too.
- If the service discovery layer does not have a feasible way to refresh the changes on the appliction layer, the cloud must, by using notification services, rest-api calls or a combination of both, inform the discovery service about the changes. If for any reason the api call fails, or, the discovery service is unavailable in the moment the cloud is trying to communicate with it, we can end with an inconsistency in the IP list that will propagate to the proxy layer.

Think also in other solutions like a VoIP autoscalable platform with Kamailio as a front-end and multiple asterisk-based ACD's (automatic call distributors). Consider the ACD layer as your "application" layer, and kamailio as your load-balancing layer. How can we inform kamailio to re-configure itself (obtaining the IP's of all currently running ACD's) during a scale-up or scale-down event ?. This is the task of the services discovery component of your cloud deployment.

In the following sections we'll describe a solution where you'll have the following scenario:

```bash
            (AWS ELB)
                |
                |
    (HAPROXY)   +   (HAPROXY)
     |          |         |
[(HTTP APP) (HTTP APP) (HTTP APP)] <-(AutoScaling group)
```

Our deployment entry-point will be a AWS ELB (Elastic Load Balancer). The ELB will distribute traffic to both HAPROXY servers. Each HAPROXY will also distribute traffic to all http servers in the APP layer.

Here, you can probably see that something is missing: If the servers on the app layer (in a autoscaling group) changes, how the proxy servers will refresh their IP lists ?... moreover: Where is the service discovery layer here ?.

In the following sections we'll explore a way to use the AWS API as a simple but effective way to have a discovery layer without the need of additional servers or cloud elements.


## **The solution part 1: The AWS-Based service discovery layer.**

For our discovery layer, we'll explain in separate the 3 components we need to use: The controlling layer, the TAGS and the ROLES.


### The first part of the discovery solution: The cloud controlling layer. The "natural" service discovery layer in the cloud.

All modern clouds systems (public, private or hybrid) have a form of "controlling layer" which keeps absolute and realistic information and state about what is running, where is running and how it's running.

This controlling layer is by far, the best and more trusted source of information about the whole cloud state. This layer can be "invisible" to the end-user, only shown itself through API's or web-dashboards.

In the case of AWS, the controlling layer knows everything about the virtual instances, including their IP's (both public and private), and specially, the "tags". You can interact with this "controlling" layer using the AWS web console, or, the aws python client (awscli).


### The second part of the discovery solution: The TAGS.

One of the most powerful means to organize your items in the AWS cloud is the TAGS. The tag is just that: "a tag"... a key-value pair that you can assign to all items in your cloud (vpc's, subnets, and for our solution: The instances).

By using tags you can group instances in groups by function. An example:

```bash
tag key: environment
tag value: development
```

The example above, applied to an instance, shows that the instance belong to the "development" environment (you could think on: development, testing-or-staging, production).

Also, in a real-life multi-layer platform (example: a mail platform) you could have this:

```bash
tag key: smtp-out
tag value: server-01

tag key: smtp-in
tag value: server-04

tag key: pop-imap
tag value: server-23
```

Those tags can be used with the python AWS client (either running directly as "aws" command or by using it inside a python script with botocore library). By example: If anyone want to obtain all the public IP's in a specific layer called "applayer", you can issue the command:

```bash
aws ec2 describe-instances \
--filter "Name=tag-key, Values=applayer" \
--query "Reservations[*].Instances[*].PublicIpAddress" --output=text
```

The command from above will search for all instances in which tag-key is "applayer", and query specifically the "public IP address". The result of this command will be a list of IP's. You can use this list inside a bash-based loop like this:

```bash
for i in `aws ec2 describe-instances \
--filter "Name=tag-key, Values=applayer" \
--query "Reservations[*].Instances[*].PublicIpAddress" --output=text`; do echo "Server $i"; done

Server 35.164.190.65
Server 35.164.223.79
```

Of course, you can use the private IPs too. Just change "PublicIpAddress" by "PrivateIpAddress" in the query.


### The third part of the discovery solution: The ROLES.

Differently from other private-cloud solutions, one of the most powerful ways to control what an instance can do with the cloud controlling layer is the role. While is completely true that all moderns clouds are RBAC based, AWS take the concept further, by enabling the cloud to apply "roles" not only to user and groups, but to instance objects too.

What this mean ?. In a practical way, the SysAdmin can configure a role that allows a specific set of instances to, by example, get access to S3 (object storage) files without the need of having the AWS client configured in the machine with the keys/secret. That have two big advantages here:

1. Because the aws client inside the virtual instance does not have any authentication information, if the instance is somehow compromised, the "hackers" will be unable to obtain the AWS credentials.
2. The roles can include any policy that allows the instance to perform specific and very delimited/discrete actions on the cloud. Example: Query EC2 in order to obtain the IP's of all instances which match a specific TAG.

A role for allowing the instances to perform read-only queries to EC2 would be like:

```bash
{
  "Version": "2012-10-17",
  "Statement": [
	{
  	"Effect": "Allow",
  	"Action": "ec2:Describe*",
  	"Resource": "*"
	},
	{
  	"Effect": "Allow",
  	"Action": "elasticloadbalancing:Describe*",
  	"Resource": "*"
	},
	{
  	"Effect": "Allow",
  	"Action": [
    	"cloudwatch:ListMetrics",
    	"cloudwatch:GetMetricStatistics",
    	"cloudwatch:Describe*"
  	],
  	"Resource": "*"
	},
	{
  	"Effect": "Allow",
  	"Action": "autoscaling:Describe*",
  	"Resource": "*"
	}
  ]
}
```

In other words, we can completely get rid of an additional discovery layer in our cloud deployment, if what we want to discover is the IP addresses of the servers in a group defined with a TAG. Please not that this is a very simplistic approach. If you need more complex things in your discovery tool, you'l probably need something like [consul](https://www.consul.io/) or [etcd](https://github.com/coreos/etcd).


## **The solution part 2: The haproxy-based completely stateless self-serviceable layer.**

We want to keep things very simple and use "haproxy" as our proxy layer software. HAPROXY will have in its configuration the IP's of all servers in the app layer. For this to work, we need a way to let haproxy to query AWS and obtain all the IP's in the layer. The servers running in the haproxy-based layer will have the following components running inside, and they will be using the ROLE previously described, so they can "ask" the "AWS Based" discovery solution about the running instances and their IP's in the applayer TAG:

1. The AWS client, properly configured during the instance bootstrap sequence.
2. HAPROXY, with their original /etc/haproxy/haproxy.cfg and a header file "/etc/haproxy/haproxy.cfg.HEADER" copied from a S3 bucket during the bootstrap sequence.
3. A script running inside a crontab each minute. This script will use the "aws" client to reconstruct the /etc/haproxy/haproxy.cfg using the original "/etc/haproxy/haproxy.cfg.HEADER" file as header, and, assigning the servers it discovers in the TAG group in order to add it to the final haproxy config. Finally, it just send a reload to haproxy in order to let it know its new config, but only if the configuration suffers any change (mean, a scale-up or scale-down event got triggered). 

Note that, while the script will be run each minute by crontab, it has been made idempotent, so, if no changes are detected in the new list compared to the last one, it will leave haproxy untouched, decreasing the chance of a "murphy attacking us" scenario:

```bash
#!/bin/bash
#
# HAPROXY Autoconfig script
# Based on AWS as natural discovery solution
# Reynaldo R. Martinez P.
#
#

#
#
# Declare the PATH so we can find all commands in the O/S
#
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
#
# If our aws-discovery-layer.txt file exist, we run the autoconfig sequence
#
if [ -f /etc/aws-discovery-layer.txt ]
then
  #
  # By reading the layer file, we set our layer variable
  #
  mylayer=`/bin/cat /etc/aws-discovery-layer.txt`
  
  #
  # We save our original haproxy.cfg into a .OLD file that we'll use later for comparison
  #
  /bin/cat /etc/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg.OLD
  
  #
  # Then, create our "NEW" file with our original HEADER that we obtained at bootstrap time
  #
  /bin/cat /etc/haproxy/haproxy.cfg.HEADER > /etc/haproxy/haproxy.cfg.NEW
  
  #
  # This is where the actual work is donde. Using aws cli inside the instance, we obtain the IP's from the app layer
  #
  for i in `aws ec2 describe-instances --filter "Name=tag-key, Values=$mylayer" --query "Reservations[*].Instances[*].PublicIpAddress" --output=text|sort`
  do
    #
	# With the IP's, we complete our haproxy configuration.
	#
    echo "    server server-$i $i:80 weight 1 check inter 5s fall 3" >> /etc/haproxy/haproxy.cfg.NEW
  done
  
  #
  # Here, we compare our original file with the new one. If they are the same, we let haproxy be, otherwise, a change
  # in our instance list has happened and we need to reconfig and reload haproxy.
  #
  mydif=`diff /etc/haproxy/haproxy.cfg.OLD /etc/haproxy/haproxy.cfg.NEW`
  if [ $mydif == "0" ]
  then
    echo "No changes here"
  else
    #
    # Old and New config are different, meaning, a change in our instance list happened.
	#
    /bin/cat /etc/haproxy/haproxy.cfg.NEW > /etc/haproxy/haproxy.cfg
    systemctl reload haproxy
  fi
else
  echo "No layer spec file found"
fi

```

The script can be already contained in the server (if we use a golden-image) or can be downloaded from a local bucket in S3 (best scenario) during the bootstrap sequence. In that case, we should include a policy in the role that allows the server to read-only access the S3 bucket in order to download both the script and the crontab file.

A typical bootstrap sequence included in the user-data section of our instances should be something like that (assuming an Ubuntu 16.04lts AMI):

```bash
#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install awscli
DEBIAN_FRONTEND=noninteractive apt-get -y install haproxy haproxyctl
cp -v /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.HEADER
systemctl stop haproxy
mkdir -p /root/.aws
echo "[default]" > /root/.aws/config
echo "output = text" >> /root/.aws/config
echo "region = us-west-2" >> /root/.aws/config
aws s3 cp s3://awsdiscoverybucket/haproxy-provisioning-script.sh /usr/local/bin/
chmod 755 /usr/local/bin/haproxy-provisioning-script.sh
systemctl start haproxy
systemctl enable haproxy
/usr/local/bin/haproxy-provisioning-script.sh
aws s3 cp s3://awsdiscoverybucket/haproxy-control-crontab /etc/cron.d/
chmod 644 /etc/cron.d/haproxy-control-crontab
systemctl restart cron
```

After the proxy-machine starts, it will run the crontab-controlled "/usr/local/bin/haproxy-provisioning-script.sh" script a first time, then let the crontab to keep it running each minute (or whatever time we decide to run it).

**Note something here:** The proxy server will maintain a list of their balanced machines and it will be configured with the proper keepalives in order to disallow traffic to non-responding instances in the APP layer, either if they are unable to answer by networks conditions (or if an asteroid vaporized a complete AZ in amazon) or if it was just "deleted" by a scale-down event triggered in the cloud.

This layer can also be in an autoscale group spawned across multiple AZ so it can also be protected when an asteroid or godzilla decides to strike a datacenter and disolve a complete AZ. For our little tests, we'll just deploy one proxy on a AZ, and the other on a different AZ.


## **Extending the solution to a real-life scenario.**

### Provisioning the TAG from outside:

If this solution will be used in different proxy layers and with different app layers, the first task to do is "not include" any specific hard-coded TAG in the HAPROXY self-provisining script, and let the script to use an external variable (or file) to use as a TAG reference. In the bootstrap secuence the following can be included at the very first line after the shebang:

```bash
#!/bin/bash
echo "applayer" > /etc/aws-discovery-layer.txt
```

Then, the "/usr/local/bin/haproxy-provisioning-script.sh" will get the applayer TAG from the value inside aws-discovery-layer.txt

**NOTE:** We may also use a TAG assigned to the instance that the script will always query, but, this can create a SPOF. A file provisioned at bootstrap time is more trustable that an additional query to AWS. The less queries we do, the faster and better for all the solution.

### Running the APP layer inside a VPC with no public IP's.

If we are already using HAPROXY, there is no need to expose the private IP's using the floating-public IP's amazon provides. If both the haproxy layer and the app layer are inside the VPC's, we can keep the instances in the app layer without public IP's and let HAPROXY to do its "reverse proxy" work using the private IP's in the APP instances (a-la nginx or apache's proxypass). The only special consideration here is, due the fact that without public IP's the instances would not be able to access the package repositories, and unless we want to include a NAT instance for internet access (a wasted resource), is best if we use a golden-image for the APP layer.

Note that, we can do the same for the proxy layer and let only the EBS service to have public access or an EIP (elastic IP) assigned. In the same context, we should use a golden-image with the haproxy packages already installed.

Auto Scaling considerations, connection limits and connection ports.

HAPROXY can be configured in order limit the maximum established http connections. This also can be provisioned from the outside the same way we proposed for the app layer tag:

```bash
#!/bin/bash
echo "applayer" > /etc/aws-discovery-layer.txt
echo "128" > /etc/aws-discovery-layer-max-cons.txt
```

Even the http port (if it's not 80 by default) can be provisioned too, at both the virtual-service in haproxy and the real-servers in the app layer:

```bash
#!/bin/bash
echo "applayer" > /etc/aws-discovery-layer.txt
echo "128" > /etc/aws-discovery-layer-max-cons.txt
echo "8080" > /etc/aws-discovery-layer-virtual-service-port.txt
echo "8085" > /etc/aws-discovery-layer-real-servers-port.txt
```

About the auto scaling considerations: At a minimum default requirement, we can use cpu-usage measured by AWS cloudwatch as a trigger for the scale-up and scale-down in both our proxy layer and app layer. This works the same way as an hydraulic system in a plane or a home water-system with a pressure reservoir vessel: We'll define a "threshold" in which the system will leave without adding or deleting instances, surrounded by a max-cpu usage (minimum pressure in the hydraulic pipeline) where the cloud will add instances, and a min-cpu usage (maximum pressure in the hydraulic pipeline) where the cloud will delete the instances.

This is done in the auto scaling group definition. A typical scenario would be:

- ASG Behind an ELB: Yes (for the proxys), NO for the APP layer servers (they'll be behind the haproxy's)
- ASG group minimum instances: 2
- ASG group maximum instances: 4
- Placement group policy: Different availability zones in the region.
- Scale-up trigger event: Add an instance when the CPU reach 80% during 10 minutes (two 5-minutes measurement cycles).
- Scale-down trigger event: Destroy an instance when the CPU falls below 15% during 20 minutes (four 5-minutes measurement cycles).
- Instance add policy: One instance per scale-up event.
- Instance destroy policy: One instance per scale-down event.

A little explanation here:

- First, most monitoring systems are not continually polling the monitored servers. This is impractical and can lead to the servers being "killed" by the monitoring system. Normally, most monitoring solutions use monitoring cycles (1 minute, 5 minutes or more) to take measurements in the monitored servers. If we consider cloudwatch monitoring every 5 minutes, and our CPU usage keeps above 80% continuously (or at least for the two cycles we defined here), the scale-up event will trigger and add a single instance. In the next two cycles, if the CPU usage is still above 80%, another instance will be added until the maximum instances is reached, or, the CPU falls below 80%.
- Why two cycles ?.. Because we want to include more servers if the load is continuous, not by single transient peaks.
- Now, when the load begin to ease (the day after a "black friday"), and the cpu in all instances falls below 15% during 20 minutes (for cycles), the cloud will begin to terminate instances, until there are only the original two instances (ASG minimum instances).
- Why four cycles ?.. Because we want to be completely sure that the load has really stabilized. Normally, on autoscale system the general recommendation is: Act more quickly to add instances when the load rises, but, be more conservative when the load "apparently" decreases.

**NOTE:** Remember the final goal of this whole exercise: To demostrate ideas like: using aws-tags for service discovery, using ansible and script automation to make deployments simpler and more controlled... we are not taking into account here anything else !.


### The LAB experiment constructed

First task to do is to construct the basic AWS environment and check our facts. For our LAB deployment, we choose us-west-2 region, and the default VPC (still available with their subnets) in all 3 AZ's (us-west-2a, 2b and 2c):

```bash
aws ec2 describe-availability-zones --output=text
AVAILABILITYZONES       us-west-2       available       us-west-2a
AVAILABILITYZONES       us-west-2       available       us-west-2b
AVAILABILITYZONES       us-west-2       available       us-west-2c
```

```bash
aws ec2 describe-vpcs --output=text
VPCS    172.31.0.0/16   dopt-9731def2   default True    available       vpc-bc52e9d9

aws ec2 describe-subnets --output=text
SUBNETS us-west-2c      4091    172.31.0.0/20   True    True    available       subnet-b34591ea vpc-bc52e9d9
SUBNETS us-west-2b      4091    172.31.32.0/20  True    True    available       subnet-4960d13e vpc-bc52e9d9
SUBNETS us-west-2a      4091    172.31.16.0/20  True    True    available       subnet-f1b12294 vpc-bc52e9d9
```

With those basic facts verified, the next task was to create the security groups, load our keys, and set our roles.

For the security group:

```bash
aws ec2 create-security-group --group-name tigerlinux-01-secgrp --description "TigerLinux LAB Sec group" --vpc-id vpc-bc52e9d9
----------------------------
|    CreateSecurityGroup   |
+----------+---------------+
|  GroupId |  sg-ea0d3993  |
+----------+---------------+

Ingress-rules:

aws ec2 authorize-security-group-ingress --group-name tigerlinux-01-secgrp --protocol icmp --port -1 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name tigerlinux-01-secgrp --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name tigerlinux-01-secgrp --protocol tcp --port 80 --cidr 0.0.0.0/0
```

For the key, just create a new one or import your already existing public pem.

About the roles, we created 3 policy documents with the needed configuration and loaded using the cli. See the directory "role-json-files" inside this repository if you want to check the documents and the files, but basically you need to create an instance profile with the provided roles used in this solution. Those roles allow the instances inside the instance profile to:

1. Copy files from the S3 buckets.
2. Use the "describe-instances" subcommand in the aws cli.

Our files (in the "role-json-files" directory):

- role-instance-basic.json: Main role document that will be used at role-creation.
- ec2-describe.json: Role policy document for read-only access to "aws ec2".
- s3-list-role.json: Role policy document for read-only access to S3 buckets.

After we created the documents, we proceeded to create the role and attach the policies using the following commands:

```bash
aws iam create-role --role-name tigerlinux-01-s3-ro-ec2-ro --assume-role-policy-document file://~/role-json-files/role-instance-basic.json
aws iam put-role-policy --role-name tigerlinux-01-s3-ro-ec2-ro --policy-name s3-ro-access --policy-document file://~/role-json-files/s3-list-role.json
aws iam put-role-policy --role-name tigerlinux-01-s3-ro-ec2-ro --policy-name ec2-ro-access --policy-document file://~/role-json-files/ec2-describe.json
aws iam create-instance-profile --instance-profile-name tigerlinux-01-s3-ro-ec2-ro-profile
aws iam add-role-to-instance-profile --instance-profile-name tigerlinux-01-s3-ro-ec2-ro-profile --role-name tigerlinux-01-s3-ro-ec2-ro
```

Those last commands will create our instance profile "tigerlinux-01-s3-ro-ec2-ro-profile" containing the role "tigerlinux-01-s3-ro-ec2-ro" which allows our instances to make read-only operations con EC2 and S3.

Next in our task list is the bucket creation:

```bash
aws s3api create-bucket  --acl private --bucket aws-tigerlinux-01-lab
```

Inside this bucket we copied the files needed in the bootstrap secuence for the proxy layer. Especifically:

- haproxy.cfg.HEADER: The configuration header for our HAPROXY based implementation.
- haproxy-provisioning-script.sh: The self-configuration script running inside the proxy servers each minute.
- haproxy-control-crontab: The crontab file controlling the self-configuration script.

With those basic pre-flight steps done, we created two yaml files for Ansible:

- ansible-app-layer.yaml: This playbook will create the autoscaling group with all it's dependencies (launch configurations, alarms, policies, etc.). Each server in the "app" layer will have apache2 configured and with a simple index.html file containing the short hostname of the server. All servers will spawn across two availability zones in the region.
- ansible-proxy-layer.yaml: This playbook will create the proxy layer and the ELB in front of both servers. Note that, each server will be in a separated availability zone. Also note that the servers in this layer will use the instance profile "tigerlinux-01-s3-ro-ec2-ro-profile", enabling both servers to download the required files from the S3 bucket at bootstrap time, and, make read-only queries to the AWS cli in order to obtain all IP's in the application layer.

The provisioning stage should be done in order. First, the app-layer, then, the proxy layer:

```bash
ansible-playbook ansible-app-layer.yaml
ansible-playbook ansible-proxy-layer.yaml
```

In the moment each proxy starts, it will self-service by running a first time the `haproxy-provisioning-script.sh`, then detecting all APP servers matching the specific tag name (applayer), and reconfiguring the localy running haproxy with all the public IP's from the detected servers.

When the ELB is launched, it will detect both proxy servers http ports active and send traffic to them.

Any time an Autoscaling event is triggered, and different servers are spawned (or deleted) in the APP layer, the script inside the haproxy machines will just reconfigure and reload haproxy with the new list of servers.

The same way we use this with haproxy, we can replicate the recipe with other applications like apache, nginx, and Kamailio (in a VoIP distributed deployment).

END.-

