#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Oct 18, 2016
# TigerLinux AT Gmail DOT Com
# AWS ACCESS WITH BOTOCORE.
#
# PRE-FLIGHT CHECK:
#
# Ensure you previouslly installed python aws cli (with python-pip):
# pip install awscli
# pip2 install awscli
# pip3 install awscli
#
# "pip-installing" awscli will also install botocore.
#
# Then, ensure you have an AWS account at hand, and using the aws client
# configure it with:
#
# aws configure
#
# NOTE: You can check the entire botocore documentation in the following
#       link: https://botocore.readthedocs.io/en/latest/index.html
#

print ("")

# In this example we'll use botocore in order to query some data from our
# AWS account. In order to get the most from this sample ensure you have meet
# the following pre-requeriments:
#
# - Your aws client is fully configured with key, secret and default region.
# - Have at lease one vpc (the default is OK).. if you have more than one, the
#   better !.
#


# first, import botocore.session. This is the only class we are going to use from
# botocore

import botocore.session

# Always, always, always.... start by creating a session:
session = botocore.session.get_session()
# And with the session ready, create a client. For our example,
# we'll use the "ec2" client:
client = session.create_client("ec2")

# All functions referenced in "aws cli" are available as objects (Love OOP... really)
# Here, we'll just use the aws-cli equivalent to "aws ec2 describe-vpcs".
# The function returns a dictionary:
vpcstruct = client.describe_vpcs()

# Here, you can see that our "vpcstruct" type is "dict":
print ("Response type is "+ str(type(vpcstruct))+ "\n")

# Like any other dictionary, we can create a list with the keys,
# then sort it and use it later in a loop:
mykeys=list(vpcstruct.keys())
mykeys.sort()

#
# You'll see the keys and the complete list of items inside all
# keys
for mykey in mykeys:
    print ("Key name is: " + str(mykey) + ", Containing:\n")
    print (str(mykey) +" => " + str(vpcstruct[mykey]))
    print ("\n")


#
# Now, what we really want to see, is our VPC's. The dictionary item
# "Vpcs" contains a list of vpc's with additional dictionaries:
myvpc=list(vpcstruct["Vpcs"])
myvpc.sort()

#
# Our loop will run trough all the keys, and print specific
# details from our vpc's
#
vpccounter=1
for item in myvpc:
    print ("********** VPC NUMBER " + str(vpccounter) + " **********\n")
    print ("+++ Basic VPC details follow: +++")
    print ("\tVPC ID: " + str(item["VpcId"]) )
    print ("\tVPC CIDR: " + str(item["CidrBlock"]))
    if bool(item["IsDefault"]):
        print ("\tNOTE: \"This is the DEFAULT VPC\"\n")
    else:
        print ("\n")
    vpccounter +=1
    # Let's play a little more... let's create inside the loop
    # a variable and set to the VPC ID
    vpcid=str(item["VpcId"])
    # Now, we'll call the "describe subnets" function, but, specifying
    # a filter with the vpc ID:
    mysubnets=client.describe_subnets( Filters=
        [
            {
                "Name": "vpc-id",
                "Values": [
                    vpcid,
                ]
            },
        ]   

    )
    # Basically, the last command is equivalent to:
    # aws ec2 describe-subnets --filters "Name=vpc-id,Values=VPC-ID-STRING"
    # See the above method usage in the following link:
    # https://botocore.readthedocs.io/en/latest/reference/services/ec2.html#EC2.Client.describe_subnets
    print ("Subnets in VPC \"" + vpcid + "\"\n")
    # The last commands returns a dictionary too. The key "Subnets" contains
    # the list of subnets, and each list also contains a dictionary with
    # the subnet relevant info:
    subs=list(mysubnets["Subnets"])
    subs.sort()
    subnetcounter=1
    # Here, running trough a loop, we print our subnets ID's, CIDR and Availability Zones
    for sbitem in subs:
        print ("Subnet number " + str(subnetcounter))
        print ("\tSubnet ID: " + str(sbitem["SubnetId"]))
        print ("\tSubnet CIDR: " + str(sbitem["CidrBlock"]))
        print ("\tSubnet AZ: " + str(sbitem["AvailabilityZone"]) + "\n")
        subnetcounter +=1
    # Clean up things... delete the "mysubnets" object:
    del mysubnets

# More clean up, paranoically delete the remaining objects
del vpcstruct
del client
del session


print ("")

#END.-
