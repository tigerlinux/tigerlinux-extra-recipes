# Python Exercises, from basic to not-so-basic - Example use of botocore library for AWS (Amazon Web Services) access.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Python and Botocore 3 - Baby Steps first...

This exercise requires you to have the following things at hand:

- Python AWS client installed and configured, with your default region (example: us-west-2).
- At least the default vpc "not deleted" in your default region.
- Optional but better is you have it: A custom VPC with subnets created on each availability zone.
- Botocore 3 python lib installed (normally this goes at hands with the aws client).


### How do I install aws-cli and botocore ??

Eaassssyyy. First, ensure you have pip installed on your system:

**RHEL's, Fedoras and Centos:**

```bash
yum install python-pip
yum install python3-pip
dnf install python-pip
dnf install python3-pip
```

**Debian and Ubuntu:**

```bash
apt-get update
apt-get install python-pip
```

Also, you may need the devel packages... Again:

**RHEL's, Fedoras and Centos:**

```bash
yum install python-devel
yum install python3-devel
dnf install python-devel
dnf install python3-devel
```

**Debian and Ubuntu:**

```bash
apt-get update
apt-get install python-dev
```

Then, by using pip, proceed to install the aws python client. This will also install botocore3, as it is a dependency of aws cli:

```bash
pip install awscli
pip2 install awscli
pip3 install awscli
```

After you have aws client installed, and with a key/secret at hand (please, DONT use your root account... use a separate user with it's own key/secret), configure your session:

```bash
aws configure
```

Again, please, don't forget to put your default region there !.

It's very very very important that the script contained in this exercise (aws-basic-access.py) runs in the same environment (user, profile) where you have your aws client configured. Botocore will use the information at `~/.aws` directory to access your aws account.


### Ehhh... I forgot how to create aditional VPC's:

Again, easy.. don't worry: Go to your vpc section in your aws web console (networking -> vpc), either use the wizard, or follow the instructions:

- Click on "your VPCS", then create a new vpc. Set a name, a CIDR block (sample: 192.168.0.0/16), then click on "Yes, Create". Ensure your new VPC has the "dns hostname" set to yes (just a recommendation).
- Go to "subnets", and click on "Create Subnets". Ensure to select the right VPC (the new one you just created), set a name and select the availability zone where you want to create the subnet. For your CIDR, use a subnet of the CIDR block from the VPC. Example: 192.168.1.0/24. As a general recomendation, create at least one subnet for each availability zone.
- Ensure to enable auto-assign public IP's in all your new subnets (assuming you want internet access to your instances).
- Click on "Internet Gateways" and create a new one. Ensure it is attached to your new VPC.
- Go to route tables, and select your new VPC's route (you'll see the vpc collumn at the end of the route list). Add a default route (0.0.0.0/0) with the target set to the internet gateway you just created before for your VPC.

That's it !. You are ready and your new VPC too !.


## What this script really does ??

This is just a example on how to use botocore in order to run commands in AWS. Just that !. Nothing less, nothing more. Basically, for each command available at "aws cli", you'll find an equivalent class and methods in botocore.

This script just shows you how to obtain your VPC lists, print if the vpc is the default one, and, list all subnets (along some extra data) from each vpc. **IT WILL NOT create or delete items at your AWS account !**. A sample-output is on the file "sample-output.txt" (that's from my own aws account).

Feel completely free to adapt this script to your own needs. Also, you can see all the botocore documentation in the following link:

* [Botocore online documentation](https://botocore.readthedocs.io/en/latest/index.html)

END.-
