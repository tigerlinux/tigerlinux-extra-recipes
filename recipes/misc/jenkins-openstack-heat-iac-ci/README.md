# USING JENKINS, GIT AND HEAT TO CREATE INFRASTRUCTURE AS CODE IN OPENSTACK (CI/IaC)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

Modern cloud platforms are fully capable of deploying complete infrastructures based on declarative languages with template files. Those files basically contains all the instructions that the cloud software need in order to create resources (instances, network ports, block storage, object storage, bootstraping for the instances, etc.).

In AWS, it's called "Cloudformation". In OPENSTACK, it's called "HEAT", who also "speaks" the AWS Cloudformation language along its own set of declarative instructions.

OpenStack HEAT use template files (and optionally, template environment files) in order to create a "stack" of resources. The stack also can be updated and eventually deleted like any other code-based thing. This is basically the concept of [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_Code).

Because this code is simple declarative language in yaml o json files, we can keep it in a [SCM](https://en.wikipedia.org/wiki/Software_configuration_management) like "git".

Now, if we want to glue HEAT and GIT to make the system smart, more automated and basically "integrated", we need to use a ["continuos integration"](https://en.wikipedia.org/wiki/Continuous_integration) tool, like "Jenkins".


## Procedures:

So.. what are we going to do here ?. We'll use a Jenkins server and a git repo in order to create a build job which will monitor the changes in the repo (which contains HEAT templates), and, for every change, it will deploy/update the HEAT stack in a OpenStack environment.


## Our environment:

- For the jenkins part, we'll use the last docker image for jenkins:alpine. We'll run the container in a Centos 6.x server with IP: 192.168.1.1.
- For the openstack part, we'll use a MITAKA-Based OpenStack cloud. Our keystone/controller IP is: 192.168.1.4.
- And, for the git, we'll use a local git repo service (also in the Centos server), with the basic git-daemon working trough xinetd. We can use more complex git platforms here (like github or gitolite), but for now, the local git server is OK.


### Dockerized jenkins installation (on server 192.168.1.1, Centos 6.x with EPEL and docker 1.7.x):

Our dockerized jenkins solution will be deployed in a Centos 6 server (with EPEL installed), running docker 1.7.x. We can also set a CoreOS instance in the OpenStack server if we want. Just we need something running docker !!.

In the server where the jenkins docker container will be located (our centos with IP 192.168.1.1), we proceed to create the jenkins directory and container:

```bash
mkdir /var/jenkins-data

docker pull jenkins:alpine
docker run -d --name jenkins-tiger -u root -p 8080:8080 -p 50000:50000 -v /var/jenkins-data:/var/jenkins_home jenkins:alpine
```

After the containerized jenkins is ready, enter to the server (real) IP and port 8080 to complete the online install, set your admin account/users, etc:

- http://192.168.1.1:8080

Use the administrator password from the file "/var/jenkins-data/secrets/initialAdminPassword" (or use docker logs jenkins-tiger to see it).

Accept the standard plugins recommended by the installation and set your first admin account (user/pass/name/email), then click on "start using jenkins".


### OpenStack server and deployment environment:

Our openstack server IP is: 192.168.1.4 (OpenStack Mitaka). Our credentials:

```bash
OS_USERNAME=ec2testing
OS_PASSWORD=ec2testing
OS_TENANT_NAME=ec2testing
OS_PROJECT_NAME=ec2testing
OS_AUTH_URL=http://192.168.1.4:5000/v3
OS_IDENTITY_API_VERSION=3
OS_PROJECT_DOMAIN_NAME=default
OS_USER_DOMAIN_NAME=default
```

In the server 192.168.1.4, we had created an account "jenkins" with the openstack source rc with all authentication data from above:

```bash
/home/jenkins/keystonerc_ec2
```

Also, we have a ssh key previouslly created (with ssh-keygen -t rsa). The public part of the key is already on the jenkins account ./ssh/authorized_keys. We'll use this account in order to let jenkins to log with ssh "passwordless" to the jenkins account in the openstack server.

In the same server, we have the "heat" client, which we'll use for the deployment. All deployments will be launched from the jenkins account in the server. The jenkins server will use the keys to ssh to the jenkins account in the openstack server, then run the heat commands in order to create or update the stack.


### Git repository setup:

We have a local git with the following repo url:

- **git://192.168.1.1/openstack-heat-cfn.git**

The repository contains the following files:

```bash
+-- heat-stack-deploy.sh
+-- heat-template-env.yaml
+-- heat-template.yaml
+-- keys
¦   +-- id_rsa
¦   +-- id_rsa.pub
¦   +-- ssh-config
+-- README.md
```

And the files present in the repo:

- README.md: A basic readme.... this document really !!.
- heat-template.yaml: A common "OpenStack HEAT" template, that will just create a single server.
- heat-template-env.yaml: The environment file for the heat template.
- keys/id_rsa and keys/id_rsa.pub: Key pair created for the "jenkins" account in the OpenStack server.
- keys/ssh-config: Client config for "ssh/scp" commands. Contains:

```bash
Host *
StrictHostKeyChecking no
UserKnownHostsFile=/dev/null
```

- heat-stack-deploy.sh: Our heat deployment script. This script creates a stack (if it does not previouslly exist), or, update the stack if its already created. Contains:

```bash
#!/bin/bash
#
# Stack create/update script
#
# By Reinaldo Martinez P.
# Caracas, Venezuela.
# TigerLinux AT gmail DOT com
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
# Source our OpenStack credentials
#
source keystonerc_ec2

stackname=$1
stacktemplate=$2
stackenviro=$3

stackhere=`heat stack-list -f stack_name=$stackname|grep -v grep|grep -c $stackname`

if [ $stackhere == 0 ]
then
        echo "Creating new stack"
        heat stack-create -f $stacktemplate -e $stackenviro -t 2 --poll 10 -r $stackname
else
        echo "Updating already existent stack"
        heat stack-update -f $stacktemplate -e $stackenviro -t 2 -r $stackname
fi

heat stack-show $stackname
```

Basically, our source directory (in git) contains the code used to create and deploy our openstack service, and keep changes on the heat fully updated.


### The "Jenkins" job:

Now, is time to go "Jenkins" !!.

Create a new "freestyle project", and set the name (sample: heat-test).

- In the "General" tab, set "Discard old builds".
- In the "Source Code Management" tab, ckeck on "git", and use the repo url: git://192.168.1.1/openstack-heat-cfn.git
- In the "Build Triggers" tab, select "Poll SCM" and for the schedulle set: * * * * * (that is, run every minute). This will look for changes in the repo, then trigger the build proccess.
- In the "Build" tab, add a build step, type "execute shell", and in the text box add the following line:

```bash
echo "Building Stack"
ls
chmod 0600 keys/id_rsa
chmod 755 heat-stack-deploy.sh
scp -i keys/id_rsa -F keys/ssh-config *.yaml jenkins@192.168.1.4:~/
scp -i keys/id_rsa -F keys/ssh-config *.sh jenkins@192.168.1.4:~/
ssh -i keys/id_rsa -F keys/ssh-config jenkins@192.168.1.4 "ls -la"
ssh -i keys/id_rsa -F keys/ssh-config jenkins@192.168.1.4 "./heat-stack-deploy.sh stack-x01 heat-template.yaml heat-template-env.yaml"
ssh -i keys/id_rsa -F keys/ssh-config jenkins@192.168.1.4 "source ~/keystonerc_ec2;heat stack-show stack-x01"
```

The instruction on the text box will perform the following steps:

- After the workspace is syncronized (git clone/git pull), the build task will do a ls, and set permissions for the files keys/id_rsa and heat-stack-deploy.sh
- Using scp, the templates and the heat deploy script will be copied to the jeninks account in the openstack server.
- Just to check if everything is there, we do in the remote jenkins account a "ls -la"
- Then, in the remote jenkins account we run the "heat-stack-deploy.sh" script, with the parameters set for the stack template, template environment, and stack name. If the stack is not existent in the openstack installation, the script will create as new. If it does exist, the script just update it.
- Finally, in the remote jenkins account we perform a "stack-show stackname" command in order to check the stack status.

If there is no error (exit code 0), the build is marked as successfull. If any of the command fails, the build is marked as failed.

Using those techniques, we are basically converting a cloud infrastructure in controlled code. GIT does the part of "source code control", heat does the part of "Cloud formation", and jenkins unify both things !. That's the principle of continuos integration, not applied to a program/application, but to an infrastructure in the cloud.


### Where to use this ??:

This recipe adjust very well to staging/Q.A and development environments. For production it can be also used, but, don't use the "Poll SCM" part. Automatic updates on the stack can lead to service disruption. Instead, let the job to be called manually, mean, apply "change management" ITIL techniques here, or you'll risk your main production environment !.


### This can be used for AWS ??:

OF COURSE !. Modify the "heat-stack-deploy.sh" script so it will use "aws cloudformation" with the "create-stack/update-stack" subcommands. For this to work, the jenkins account in the deploying environment must have access to the "aws" cli, and the key/secret for AWS.


### In "real-production", how can we use this ??.

For a production environment, is better if you use a dedicated deploying server instead of running the heat commands directly in the openstack server. For this, you can create an instance in your cloud which will contain the "jenkins" account with the openstack/aws clients installed, and with the dockerized Jenkins running inside too.

Also remember you can set slave nodes for Jenkins, which will run your builds and distribute your load.

END.-