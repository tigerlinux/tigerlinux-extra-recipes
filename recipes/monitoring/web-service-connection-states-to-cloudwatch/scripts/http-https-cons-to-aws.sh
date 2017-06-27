#!/bin/bash
#
# Web Service connection states
#
# By Reynaldo R. Martinez P.
# TigerLinux@Gmail.com
#
# This script, that you should run inside a crontab every 5 minutes, will
# obtain the actual connections in the following states for normal web tcp
# ports:
# - established
# - time-wait
# - fin-wait-1
# - fin-wait-2
# Then, it will publish the conection states as metrics in AWS Cloudwatch.
# More information about connection states here: 
# - http://www.rfc-editor.org/rfc/rfc793.txt
# - https://en.wikipedia.org/wiki/Transmission_Control_Protocol
#
# Requirements:
# - aws client properly configured.
# - IAM roles aplied to the instance. Recommended policy document:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "cloudwatch:PutMetricData",
#         "cloudwatch:GetMetricStatistics",
#         "cloudwatch:ListMetrics",
#         "ec2:DescribeTags"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# - curl, ss, grep and wc installed on the instance
#

# Basic PATH Set here.
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

ec2namespace="EC2:WEB-Services"

#
# Get our four connection states for ports 80 and 443 (web services)
#
# Change your ports or add more if your web app exposes multiple ports
#
# Samples:
# - Single web service running in port tcp 80:
#   "( sport = :80 )"
# - Multiple web services running on ports 80, 8080 and 443
# "( sport = :80 | sport = :443 | sport = :8080 )"
#
established=`ss -ant -o state established "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
timewait=`ss -ant -o state time-wait "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
finwait1=`ss -ant -o state fin-wait-1 "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`
finwait2=`ss -ant -o state fin-wait-2 "( sport = :80 | sport = :443 )"|grep -v "Address:Port"|wc -l`

# Get the instance ID from AWS metadata service
# Two ways. One is by obtaining the instance-id directly from the
# metadata service, the other is by using ec2metadata command.
#
# By default, use "curl".
#
instanceid=`curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null`
#instanceid=`ec2metadata --instance-id`


#
# And finally, send our "web connections" variables to AWS Cloudwatch inside the namespace
# defined in the "$ec2namespace" variable
#
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

#
# END
#

