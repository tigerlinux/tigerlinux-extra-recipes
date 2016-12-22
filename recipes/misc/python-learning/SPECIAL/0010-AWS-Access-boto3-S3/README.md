# Python Exercises, from basic to not-so-basic - Example use of botocore library for AWS-S3 (Amazon Web Services) basic functions.

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
- Your account must be able to create buckets, delete buckets, copy content to the buckets, and list their contents too.
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


## What this script really does ??

This example will make some buckets operations:

- List all your buckets and their contents (limiting to 5 keys only by bucket).
- Create a bucket.
- Copy a file to the bucket and list the bucket contents.
- Delete the previously copied file, and delete the bucket.

Before using the script, please see the file "s3info.ini". The file contents are:

```bash
[s3info]
bucketname = 177ff04f3ea63354d936
bucketregion = us-west-2
bucketfile = sample-file.txt
```

Change the **"bucketregion"** to the region where you want to create the bucket. Also, regenerate the **"bucketname"** with the following command:

```bash
openssl rand -hex 10
```

Then, run the python script **"aws-s3-boto-example.py"**. A sample output is in the file "sample-output.txt".

Feel completely free to adapt this script to your own needs. Also, you can see all the botocore documentation in the following link:

* [Botocore online documentation](https://botocore.readthedocs.io/en/latest/index.html)

END.-
