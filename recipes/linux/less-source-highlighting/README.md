# SOURCE CODE SYNTAX HIGHLIGHTING IN "LESS"

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

If you are a linux specialist, you surelly know the pager program "less". One of the things you can do with less on most modern linux distros, is configure "syntax highlighting" on it. This short recipe will show you how to modify your linux environment in order to add syntax highlighting to the "less" pager.


## YUM Distros (CENTOS/FEDORA):

In Centos/Fedora, first install the source-highligh package:

```bash
yum install source-highlight
```

NOTE: In Centos/RHEL distros, you NEED the [**"EPEL"**](https://fedoraproject.org/wiki/EPEL "EPEL Repo Wiki") repository installed.

### Fedora 2X:

In your Fedora machine (20-23 and later), run the following commands:

```bash
export LESSOPEN="| /bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

echo "export LESSOPEN=\"| /bin/src-hilite-lesspipe.sh %s\"" > /etc/profile.d/less-hl.sh
echo "export LESS=' -R '" >> /etc/profile.d/less-hl.sh
```

### RHEL/CENTOS (Series 6):

In your RHEL/Centos 6.x, run the following commands:

```bash
export LESSOPEN="| /usr/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

echo "export LESSOPEN=\"| /usr/bin/src-hilite-lesspipe.sh %s\"" > /etc/profile.d/less-hl.sh
echo "export LESS=' -R '" >> /etc/profile.d/less-hl.sh
```

### RHEL/CENTOS (Series 7):

In your RHEL/Centos 7.x, run the following commands:

```bash
export LESSOPEN="| /usr/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

echo "export LESSOPEN=\"| /usr/bin/src-hilite-lesspipe.sh %s\"" > /etc/profile.d/less-hl.sh
echo "export LESS=' -R '" >> /etc/profile.d/less-hl.sh
```

## APT DISTROS (DEBIAN/UBUNTU)

### Debian 7 and 8:

Install the package:

```bash
apt-get install source-highlight
```

Run the following commands:

```bash
export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
export LESS=' -R '

echo "export LESSOPEN=\"| /usr/share/source-highlight/src-hilite-lesspipe.sh %s\"" > /etc/profile.d/less-hl.sh
echo "export LESS=' -R '" >> /etc/profile.d/less-hl.sh
```

### Ubuntu 14.04lts and 16.04lts:

Install the package:

```bash
apt-get install source-highlight
```

Run the following commands:

```bash
export LESS=' -R '

echo "export LESS=' -R '" >> /etc/profile.d/less-hl.sh
```

Create the following file:

```bash
vi /root/.lessfilter
```

Containing:

```bash
#!/bin/sh
file -b -L "$1" | grep -q text && \
/usr/share/source-highlight/src-hilite-lesspipe.sh "$1"
```

Change the file permissions, and copy it to skel directory:

```bash
chmod 755 /root/.lessfilter

cp /root/.lessfilter /etc/skel/

chmod 755 /etc/skel/.lessfilter
```

If you already have users created in your system, copy the `.lessfilter` to their home dirs and adjust the permissions in order to let them have syntax highlighting with less. Any new user will be provided with the filters as it comes directly from the skel.

END.-
