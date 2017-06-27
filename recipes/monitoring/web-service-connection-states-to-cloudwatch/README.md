# [MONITORING WEB SERVICES CONNECTION STATES WITH AWS CLOUDWATCH](http://tigerlinux.github.io)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Part of properly monitoring a web server include not only the visit counter (that can reveal general popularity of your web site), but also counting the simultaneous connections against the web server on different tcp-connection states. Those connection counters can and will allow you to really monitor your service, and potentially, allow you to detect problems too (bottlenecks, attacks, etc.).

It is not our intention to make this article a full book about TCP/IP. Our intention here is just show you how to obtain those connection counters, and then publish them in AWS Cloudwatch.

You can read more information about tcp connection states in the following links or make good use of "google":

- [http://www.rfc-editor.org/rfc/rfc793.txt](http://www.rfc-editor.org/rfc/rfc793.txt)
- [https://en.wikipedia.org/wiki/Transmission_Control_Protocol](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)


## AWS Cloudwatch and its limitations.

AWS includes its very own set of monitoring tools and metrics for all your virtual machines (instances). These metrics include anything that can be obtained from outside the instance, like general cpu usage, I/O rates on our virtual volumes, network usage, etc., but, it can't obtain things that happens inside the virtual machines like detailed cpu usage (system, user, waiting for i/o), disk space usage, ram usage, and anything related to actual connections established against services running inside the instance (like apache or nginx).

Why is that ?.. why AWS can't give us these metrics ?: Because the shared responsability model on the cloud does not allow amazon to violate your privacy. Amazon will administer the infrastructure, but the data inside your instance is private, your property and your sole responsability!. Because these special extra metrics we need are only obtainable from inside the instance, then AWS cannot take responsability of obtaining them.


## The good news: AWS Cloudwatch is extensible by nature.

If you have used before monitoring solutions like net-snmp, zabbix, cacti and the like, you surelly know that all of them can be extended with non-default metrics defined by you. Well, it happens that AWS Cloudwatch allows you to do the same. You can create new metrics from inside the instance, then publish them in cloudwatch at regular intervals (5 minutes or 1 minute periods between each refresh).

Then, for our specific situation here where we need to monitor connection states, we can easily use a simple shell script that runs inside a crontab every 5 minutes, get the connection counters, and then using the "aws cli", send those counters to AWS Cloudwatch.


## Ok good. It can be done, but how ?.

The first part is aws and its roles. It is normal to use roles assigned to aws instances in order to use the "aws cli" without the need to include specific credentials inside the instance. The role should have the proper policies allowing the instance to write cloudwatch metrics.

The first part is, of course, to install (and configure) the aws cli. You can install it with pip (if you want the most recent version) or with the operating system package manager. The following example automates the installation and configuration of the aws client on an ubuntu machine:

```bash
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y install awscli
mkdir -p /root/.aws
echo "[default]" > /root/.aws/config
echo "output = text" >> /root/.aws/config
echo "region = us-east-1" >> /root/.aws/config
```

The last lines from above will install, in a fully automated way (use this in a bootstrap script), and configure too, the aws client.

The second part is the role. Create a IAM role (which you will attach to the instance) that include the following policy:

```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

Normally, you should only need "PutMetricData", but, if you want to do more manipulations that include listing metrics and stats for specific tags, then you'll probably need the other actions in the policy document described above.

The third part is the script. The following shell script will do the actual work (it is included along this document with more inline comments):

```bash
#!/bin/bash
#
# Web Service connection states
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

ec2namespace="EC2:WEB-Services"

established=`ss -ant -o state established "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
timewait=`ss -ant -o state time-wait "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
finwait1=`ss -ant -o state fin-wait-1 "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
finwait2=`ss -ant -o state fin-wait-2 "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`

instanceid=`curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null`

aws cloudwatch put-metric-data \
        --metric-name "http-cons-established" \
        --unit Count \
        --value $established \
        --dimensions InstanceId=$instanceid \
        --namespace $ec2namespace

aws cloudwatch put-metric-data \
        --metric-name "http-cons-timewait" \
        --unit Count \
        --value $timewait \
        --dimensions InstanceId=$instanceid \
        --namespace $ec2namespace

aws cloudwatch put-metric-data \
        --metric-name "http-cons-finwait1" \
        --unit Count \
        --value $finwait1 \
        --dimensions InstanceId=$instanceid \
        --namespace $ec2namespace

aws cloudwatch put-metric-data \
        --metric-name "http-cons-finwait2" \
        --unit Count \
        --value $finwait2 \
        --dimensions InstanceId=$instanceid \
        --namespace $ec2namespace

```

What this script does ?:

* It obtains the actual connection number for 4 specific connection states (Established, Time-Wait, Fin-Wait-1 and Fin-Wait-2). It obtain the connection numbers against services running on ports 80 and 443.
* It obtains the instance ID from the metadata service.
* With the gathered data, it publish all four metrics in AWS Cloudwatch for the instance with the obtained ID, and inside a specific Cloudwatch namespace, defined at the start of the script as "EC2:WEB-Services".

The final part is, as you probably already figured out, to include the script inside a crontab. Let's assume our script (made it exec, mode 755) is inside the "/usr/local/bin" path, and it's file name is "http-https-cons-to-aws.sh". Then the crontab would be:

```bash
######################################
#
# Connection States to AWS Cloudwatch 
#
# Every five minutes
#
*/5 * * * * root /usr/local/bin/http-https-cons-to-aws.sh > /var/log/last-http-cons.log 2>&1
#
```

Note that, for this script to properly do its job, you need the following tools installed inside the instance:
- curl.
- aws client (properly configured).
- ss.
- grep
- wc

Normally, most AWS instances already includes those tools, but, always ensure you have them already installed.


## That's good for Web Services but, can I use it for other application ports ?.

The answer is: Yes. You can change the "( sport = :80 | sport = :443 )" part if you want to include other ports, or, include other applications. Another example here that you can include in the same script in order to obtain connections against a MariaDB database engine running on port tcp 3306:

```bash
ec2dbnamespace="EC2:Database-Services"

dbestablished=`ss -ant -o state established "( sport = :3306 )"|grep -v "Address:Port"|wc -l`
dbtimewait=`ss -ant -o state time-wait "( sport = :3306 )"|grep -v "Address:Port"|wc -l`
dbfinwait1=`ss -ant -o state fin-wait-1 "( sport = :3306 )"|grep -v "Address:Port"|wc -l`
dbfinwait2=`ss -ant -o state fin-wait-2 "( sport = :3306 )"|grep -v "Address:Port"|wc -l`

instanceid=`curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null`

aws cloudwatch put-metric-data \
        --metric-name "db-cons-established" \
        --unit Count \
        --value $dbestablished \
        --dimensions InstanceId=$instanceid \
        --namespace $ec2dbnamespace

aws cloudwatch put-metric-data \
        --metric-name "db-cons-timewait" \
        --unit Count \
        --value $dbtimewait \
        --dimensions InstanceId=$instanceid \
        --namespace $ecdb2namespace

aws cloudwatch put-metric-data \
        --metric-name "db-cons-finwait1" \
        --unit Count \
        --value $dbfinwait1 \
        --dimensions InstanceId=$instanceid \
        --namespace $ecdb2namespace

aws cloudwatch put-metric-data \
        --metric-name "db-cons-finwait2" \
        --unit Count \
        --value $dbfinwait2 \
        --dimensions InstanceId=$instanceid \
        --namespace $ecdb2namespace
```

A final note: This method is for TCP connections only. You can obtain UDP sockets in other ways, but for now this is out of the scope of this article.

END.-
