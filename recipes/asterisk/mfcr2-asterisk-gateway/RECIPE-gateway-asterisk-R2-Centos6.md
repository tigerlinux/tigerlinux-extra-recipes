# AN ASTERISK BASED VOIP GATEWAY SUPPORTING MFC-R2 PROTOCOL ON CENTOS 6

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish ?:

Create a VoIP gateway, asterisk based, with MFCR2 support.


## Where are we going to install it ?:

A physical server with asterisk-supported telephony card, Centos 6 (32 or 64 bits), EPEL repository installed, SELINUX and IPTABLES Firewall disabled. 


## How we constructed the whole thing ?:


### Basic server setup:

Install EPEL (if you did'nt already) and perform a full update:

```
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

yum clean all
yum -y update
```

Ensure SELINUX and IPTABLES are disabled:

```
setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

chkconfig iptables off
/etc/init.d/iptables stop
```

Then, reboot your server:

```
reboot
```

### Dependencies installation:

Now, we are going to install some dependencies:

```
yum groupinstall core
yum groupinstall base

yum install gcc gcc-c++ lynx bison mysql-devel mysql-server php php-mysql php-pear php-mbstring \
tftp-server httpd make ncurses-devel libtermcap-devel sendmail sendmail-cf caching-nameserver \
sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel subversion kernel-devel \
git subversion kernel-devel php-process crontabs cronie cronie-anacron doxygen \
kernel-headers-`uname -r` kernel-devel-`uname -r` glibc-headers sqlite sqlite-devel \
ntp ntpdate php-digium_register cpp make automake autoconf

yum install php-pear-MDB2 php-pear-MDB2-Driver-mysql php-pear-MDB2-Driver-mysqli php-pear-DB
```

Some of those dependencies would only be needed if later you decide to include FreePBX in your gateway (like mysql and httpd).

More dependencies:

```
cd /usr/local/src/
git clone https://github.com/meduketto/iksemel

cd /usr/local/src/iksemel/

./autogen.sh
./configure
make
make install

cd /
```

We ensure NTP is active and tunning:

```
chkconfig ntpdate on
chkconfig ntpd on
service ntpd stop
service ntpdate start
service ntpd start
```

### OPTIONAL: MySQL configuration

If you plan to use MySQL for CDR storage, or for other reasons (FreePBX backend), then proceed to configure it and activate it:

```
chkconfig mysqld on
service mysqld start

/usr/bin/mysqladmin -u root password 'P@ssw0rd'
```

Create the file: `/root/.my.cnf`

```
vim /root/.my.cnf
```

With the content:

```
[client]
user=root
password=P@ssw0rd
```

Save the file and change its mode:

```
chmod 0400 /root/.my.cnf
```

**NOTE: This is completelly optional !. It's up to you and your requirements.**


### Asterisk Installation

We are going to install asterisk and r2 components from source so firs, we download the sources:

```
mkdir /workdir
cd /workdir
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-11-current.tar.gz
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/openr2/openr2-1.3.3.tar.gz
```

Un-compress all files:

```
tar -xzvf dahdi-linux-complete-current.tar.gz -C /usr/local/src/
tar -xzvf libpri-current.tar.gz -C /usr/local/src/
tar -xzvf asterisk-11-current.tar.gz -C /usr/local/src/
tar -xzvf openr2-1.3.3.tar.gz -C /usr/local/src/
```

Proceed to compile and install dahdi:

```
cd /usr/local/src/dahdi-linux-complete-*
make all
make install
make config

cd /
```

Proceed to compile and install libopenr2:

```
cd /usr/local/src/openr2-*
./configure --prefix=/usr
make
make install

cd /
```

Proceed to compile and install libpri:

```
cd /usr/local/src/libpri-*
make
make install

cd /
```

Then, proceed to compile and install Asterisk:

**NOTE: Ensure to select on the "make menuselect" stage all needed options, specially, languaje core/extra sounds you should need. Also, you would like to include app_meetme, app_confbridge and res_config_mysql if you plan to include FreePBX later**


```
cd /usr/local/src/asterisk-*
./configure
./contrib/scripts/get_mp3_source.sh
make menuselect
make
make install
make config
make progdocs
```

If for some reason you forgot to include the sounds, you can include now. Those lines download and install english and spanish sounds:

```
cd /var/lib/asterisk/sounds
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-gsm-current.tar.gz

tar -xzvf asterisk-core-sounds-en-gsm-current.tar.gz -C ./en/
tar -xzvf asterisk-extra-sounds-en-gsm-current.tar.gz -C ./en/

tar -xzvf asterisk-extra-sounds-en-gsm-current.tar.gz -C ./es/
tar -xzvf asterisk-core-sounds-es-gsm-current.tar.gz -C ./es/

rm -rf *.tar.gz
```

Then we proceed to copy the sample config files:

```
cp /usr/local/src/asterisk-11*/configs/* /etc/asterisk/
cd /etc/asterisk/
for i in `ls`;do echo $i;mv $i `echo $i|sed 's/.sample//'`;done
```

We need to create an asterisk user:

```
adduser -M -c "Asterisk User" -d /var/lib/asterisk/ asterisk
```

And setup permissions for asterisk and this user:

```
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib/asterisk
```

Proceed to modify the following file:

```
vi /etc/sysconfig/asterisk
```
And set the user and group to the asterisk user/group previouslly created:

```
AST_USER="asterisk"
AST_GROUP="asterisk"
```

We save the file, and modify the next one:

```
vi /usr/sbin/safe_asterisk
```

Near the line 116, we need to modify the **"astargs"** variable in order to include the asterisk user and group:

```
ASTARGS="-U asterisk -G asterisk "
```

Save the file and run the following command:

```
ldconfig -v
```

Proceed to set on autostart the following services:

```
chkconfig dahdi on
chkconfig asterisk on
```

Create the following files:

```
echo "" > /etc/asterisk/sip_custom.conf
echo "" > /etc/asterisk/extensions_custom.conf
```

At the end of file `/etc/asterisk/sip.conf` add the following file:

```
#include sip_custom.conf
```

At the end of file `/etc/asterisk/extensions.conf` add the following file:

```
#include extensions_custom.conf
```

Proceed to reset the permissions:

```
chown -R asterisk. /etc/asterisk
```

Start dahdi:

```
dahdi_genconf
/etc/init.d/dahdi start
```

We reset dahdi devices permissions:

```
chown -R asterisk.asterisk /dev/dahdi
```

Proceed to execute the command:

```
dahdi_genconf
```

This command will detect and configure the dahdi sub-system and it's related files:

```
/etc/dahdi/system.conf
/etc/asterisk/chan_dahdi.conf
/etc/asterisk/dahdi-channels.conf
```

And the following files can be used by you for yous customized SIP Devices and Dialplans:

```
/etc/asterisk/sip_custom.conf
/etc/asterisk/extensions_custom.conf
```

In order to allow the configuration to be active, proceed to restart dahdi and asterisk:

```
/etc/init.d/dahdi restart
/etc/init.d/asterisk start
```

Now, it's time to create our log rotate in order to keep our logs at bay !:

```
vi /etc/logrotate.d/asterisk
```

With the contents:

```
/var/log/asterisk/messages
/var/log/asterisk/queue_log
/var/log/asterisk/cdr-csv/Master.csv
{
        missingok
        rotate 5
        daily
        create 0640 asterisk asterisk
        compress
        postrotate
                /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
        endscript
}
```

Save the file and we are ready to go. A Gateway is ready to work. In the following section, I'll show you an R2 configuration example.


### A typical MFC-R2 configuration example.

Le's see this scenario:

A Gateway installed using this recipe. The gateway has a VoIP Telephony card with 4 ports, all connected to a "Venezuelan" PSTN, of course, using R2. First thing to note is that the Venezuelan R2 version is not full R2... mean... the inbound lines are R2-Compelled (CAS Signalling), but, the outbound lines are DTMF over CAS signalling (yes... a Frankenstein...).

But we are very lucky, as libopenr2 supports this specific situation !.

What is the configuration for this scenario ??.

First: Dahdi: We need to reconfigure `/etc/dahdi/system.conf` file with the proper settings for those lines:

file `/etc/dahdi/system.conf`:

```
# Autogenerated by /usr/sbin/dahdi_genconf on Fri Sep 18 12:07:11 2015
# If you edit this file and execute /usr/sbin/dahdi_genconf again,
# your manual changes will be LOST.
# Dahdi Configuration File
#
# This file is parsed by the Dahdi Configurator, dahdi_cfg
#
# Span 1: TE4/0/1 "T4XXP (PCI) Card 0 Span 1" (MASTER) 
span=1,1,0,cas,hdb3
# termtype: te
# bchan=1-15,17-31
# dchan=16
cas=1-15,17-31:1101
echocanceller=mg2,1-15,17-31

# Span 2: TE4/0/2 "T4XXP (PCI) Card 0 Span 2" 
span=2,2,0,cas,hdb3
# termtype: te
# bchan=32-46,48-62
# dchan=47
cas=32-46,48-62:1101
echocanceller=mg2,32-46,48-62

# Span 3: TE4/0/3 "T4XXP (PCI) Card 0 Span 3" 
span=3,3,0,cas,hdb3
# termtype: te
# bchan=63-77,79-93
# dchan=78
cas=63-77,79-93:1101
echocanceller=mg2,63-77,79-93

# Span 4: TE4/0/4 "T4XXP (PCI) Card 0 Span 4" 
span=4,4,0,cas,hdb3
# termtype: te
# bchan=94-108,110-124
# dchan=109
cas=94-108,110-124:1101
echocanceller=mg2,94-108,110-124
```

here, the channels are changed to "cas" with bits: 1101 and hdb3 line coding, no crc4 (typical of Venezulan PSTN providers).

After those changes we of course need to restart dahdi:

```
/etc/init.d/dahdi restart
```

Now, we need to configure asterisk with R2. First file to change:

File: `/etc/asterisk/chan_dahdi.conf`:

```
[trunkgroups]
[channels]
language=es
context=default
signalling=mfcr2
pridialplan=local
prilocaldialplan=local
usecallerid=yes
hidecallerid=no
callwaiting=yes
usecallingpres=yes
callwaitingcallerid=yes
threewaycalling=yes
transfer=yes
cancallforward=yes
callreturn=yes
relaxdtmf=yes
echocancel=yes
echocancelwhenbridged=yes
echotraining=yes 
resetinterval=never
rxgain=0.0
txgain=0.0
callgroup=1
pickupgroup=1
immediate=no
#include dahdi-channels.conf
```

Second file to change (and the most important one):

File: `/etc/asterisk/dahdi-channels.conf`:

```
; Span 1
; Inbound
group=2
context=inbound
signalling=mfcr2
mfcr2_variant=ve
mfcr2_get_ani_first=yes
mfcr2_immediate_accept=no
mfcr2_max_ani=15
mfcr2_max_dnis=4
mfcr2_category=national_subscriber
mfcr2_logdir=pstnprovider
mfcr2_logging=all
mfcr2_mfback_timeout=-1
channel => 1-15,17-31
;
; Span 2
; Inbound
group=2
context=inbound
signalling=mfcr2
mfcr2_variant=ve
mfcr2_get_ani_first=yes
mfcr2_immediate_accept=no
mfcr2_max_ani=15
mfcr2_max_dnis=4
mfcr2_category=national_subscriber
mfcr2_logdir=pstnprovider
mfcr2_logging=all
mfcr2_mfback_timeout=-1
channel => 32-46,48-62
;
; Span 3
; outbound
group=1
context=outbound
signalling=mfcr2
mfcr2_variant=ve
mfcr2_get_ani_first=yes
mfcr2_immediate_accept=yes
mfcr2_dtmf_detection=1
mfcr2_dtmf_dialing=1
mfcr2_max_ani=15
mfcr2_max_dnis=15
mfcr2_category=national_subscriber
mfcr2_logdir=pstnprovider
mfcr2_logging=all
mfcr2_mfback_timeout=-1
channel => 63-77,79-93
;
; Span 4
; outbound
group=1
context=outbound
signalling=mfcr2
mfcr2_variant=ve
mfcr2_get_ani_first=yes
mfcr2_immediate_accept=yes
mfcr2_dtmf_detection=1
mfcr2_dtmf_dialing=1
mfcr2_max_ani=15
mfcr2_max_dnis=15
mfcr2_category=national_subscriber
mfcr2_logdir=pstnprovider
mfcr2_logging=all
mfcr2_mfback_timeout=-1
channel => 94-108,110-124
;
;
```

After changing both files, proceed to restart your asterisk:

```
/etc/init.d/asterisk restart
```

In this example, the first two E1's are inbound, and the other two are outbound. The context for the inbound calls is "inbound" so you need to adjust your dial plan in "extensions_custom.conf" file accordingly. Likewise, the outbound channels are placed in "group 1" (g1) so you need to adjust your dial plan in order to use that group. Those are samples of course... you are free to change this in order to suit your real environment. Just let me tell you: This recipe is currently working on several gateways with 8 ports each one, and it just works flawlessly !. Just ensure to buy a good telephony card, and if possible, with hardware-based echo canceller and you're done !.

So that's all with this recipe. Eventually I'll put one more updated with Centos 7 (one we are testing where I currently work) so stay tuned for more !.

END.-
