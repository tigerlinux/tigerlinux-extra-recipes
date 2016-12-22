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
