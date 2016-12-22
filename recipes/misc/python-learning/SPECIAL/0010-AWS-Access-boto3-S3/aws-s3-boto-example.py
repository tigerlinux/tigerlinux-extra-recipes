#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Oct 19, 2016
# TigerLinux AT Gmail DOT Com
# AWS ACCESS WITH BOTOCORE. S3 BUCKETS
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
    
# In this example we'll use botocore in order to make some S3 operations,
# namelly: create a bucket, list buckets, copy a file to a bucket, list
# buckets contents, delete the file from the bucket, and, delete the bucket
#

# First, from sys we are going to use configparser

import sys

if sys.version_info.major == 2:
    # from Tkinter import Button, mainloop
    # import Tkinter as tkinter
    from ConfigParser import *
else:
    # from tkinter import Button, mainloop
    # import tkinter
    from configparser import *

# Our config file:

configfilename="s3info.ini"

# Let's parse our filename:

myconfig = ConfigParser(allow_no_value=True)
myconfig.read(configfilename)

bucketname = myconfig.get("s3info", "bucketname")
bucketregion = myconfig.get("s3info", "bucketregion")
bucketfile = myconfig.get("s3info", "bucketfile")

# Now, import botocore.session. This is the only class we are going to use from
# botocore

import botocore.session

# Always, always, always.... start by creating a session:
session = botocore.session.get_session()
# And with the session ready, create a client. For our example,
# we'll use the "s3" client:
client = session.create_client("s3")
# All info regarding "s3" usage in botocore can be obtained from:
# https://botocore.readthedocs.io/en/latest/reference/services/s3.html

# First, lets get our bucket list:

bucketlist = client.list_buckets()
# This is equivalent to:
# aws s3api list-buckets

# the method/function called before returns a dict type.

# See the complete dictionary here:
print (str(bucketlist))
print ("")

# Let's define a function which will be called many times later. This
# function will list our buckets and it's contents:
def bucketquery(s3client):
    print ("\nLISTING BUCKETS AND ITS CONTENTS\n")
    bucketstruct=s3client.list_buckets()
    bucketcount=1
    # What we really need is in the "Buckets" key, which contain a list of dicts
    # with the buckets info:
    mybuckets=list(bucketstruct["Buckets"])
    mybuckets.sort()
    # If you have no buckets, your list will be empty. Here, we'll check if you
    # have no buckets and send a message indicating that. Else, we'll proccess
    # the data and lits all buckets and their contents
    if len(mybuckets) == 0:
        print ( "\nYou have NO buckets to list\n" )
    else:
        print ("\nYou have \""+str(len(mybuckets))+"\" Bucket(s) !!")
    # And let's loop trough all the list:
        for bucket in mybuckets:
            print ("\nBucket number \""+str(bucketcount)+"\"")
            # The dictionary key "Name" contains the Bucket name.
            print ("\tBucket name: "+str(bucket["Name"])+"\n")
            print ("\tBucket contents (maximun 5 items listed): \n")
            bucketcount+=1
            # Now, we'll use another function/method which returns a
            # listing of the contents in a bucket. We are using here
            # the "MaxKeys=5" option in order to limit our list of
            # files and not saturate the screen:
            fileliststruct = s3client.list_objects_v2(
                Bucket=str(bucket["Name"]),
                Delimiter=",",
                EncodingType="url",
                MaxKeys=5,
                FetchOwner=False
            )
            # this function is equivalent to:
            # aws s3 ls s3://BUCKET-NAME
            # and
            # aws s3api list-objects --bucket BUCKET-NAME \
            # --delimiter "," \
            # --max-items 5 \
            # --encoding-type "url"
            # The above function returns, yes you guessed, a "dict".
            # The key "Contents" has all our files, but, we need to
            # check the key existence. If the bucket does not contains
            # anything, the "Contents" key will not ber present:
            if "Contents" in fileliststruct.keys():
                myfskeys=list(fileliststruct["Contents"])
                myfskeys.sort()
                for myfile in myfskeys:
                    # The keys "Key" and "Size" contains the file name and size:
                    print ("\t\tFile: " + str(myfile["Key"]) + ", size: " + str(myfile["Size"]) + " Bytes")
            else:
                # Ther is no "Contents" key, so, your bucket is empty:
                print ( "\t\tThe bucket is empty"  )
        

# Let's call our function a first time !.
# The only argument to pass, is the client object:
bucketquery(client)

# If you had buckets in your aws account, the function will display them
# and list their contents with sizes, limited to a max of 5 keys.


# Now, let's create a bucket, put a file on it, and list again our buckets:

print ("\nCREATING A NEW BUCKET NAMED:" + str(bucketname))

myanswer = client.create_bucket(
    ACL="private",
    Bucket=str(bucketname),
    CreateBucketConfiguration={
        "LocationConstraint": str(bucketregion)
    }
)
# The above call is equivalent to:
# aws s3api create-bucket --bucket BUCKET-NAME

# And, again, let's list our buckets:

bucketquery(client)

print ("\nCOPYING AN OBJECT INTO THE BUCKET NAMED: " + str(bucketname))

# Let's copy a file inside the bucket:

myanswer = client.put_object(
    ACL="private",
    Body=bucketfile,
    Bucket=str(bucketname),
    Key=str(bucketfile)
)
# The above call is equivalent to:
# aws s3 cp FILENAME s3://BUCKETNAME
# and
# aws s3api put-object --bucket BUCKETNAME --acl private --body FILENAME --key FILENAME

# See our buckets... again.. jejeje:

bucketquery(client)

print ("\nDELETING THE BUCKET NAMED: " + str(bucketname) + " AND IT'S CONTENTS")

# Now, prior to delete the bucket, we need to delete the file or we'll be unable
# to delete the bucket:

myanswer = client.delete_object(
    Bucket=str(bucketname),
    Key=str(bucketfile)
)
# The above call is equivalent to:
# aws s3 rm s3://BUCKET-NAME/FILENAME
# and
# aws s3api delete-object --bucket BUCKETNAME --key FILENAME

# Ok.. Let's delete the bucket:

myanswer = client.delete_bucket(
    Bucket=str(bucketname)
)
# The above call is equivalent to:
# aws s3api delete-bucket --bucket BUCKET-NAME

# And, list our buckets again

bucketquery(client)


print ("")
# END
