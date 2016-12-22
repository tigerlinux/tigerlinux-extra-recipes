# AN ASTERISK BASED VOIP GATEWAY SUPPORTING MFC-R2 PROTOCOL ON CENTOS 7

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

A physical server with asterisk-supported telephony card, Centos 7, EPEL repository installed, SELINUX and FIREWALLD Firewall disabled. 


## How we constructed the whole thing ?:


### Basic server setup:

Install EPEL (if you did'nt already) and perform a full update:

```bash
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum clean all
yum -y update
```

Ensure SELINUX and FIREWALLD are disabled:

```bash
setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld
```

Then, reboot your server:

```bash
reboot
```

### Dependencies installation:

Now, we are going to install some dependencies:

```bash
yum -y groupinstall core
yum -y groupinstall base "Development Tools"

yum -y install gcc gcc-c++ lynx bison mariadb-devel mariadb-server mariadb-libs mariadb \
php php-mysql php-pear php-mbstring tftp-server httpd make ncurses-devel libtermcap-devel \
sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
audiofile-devel gtk2-devel subversion kernel-devel git subversion kernel-devel php-process \
crontabs cronie cronie-anacron doxygen kernel-headers-`uname -r` kernel-devel-`uname -r` \
glibc-headers sqlite sqlite-devel ntp ntpdate cpp make automake autoconf php-pear-MDB2 \
php-pear-MDB2-Driver-mysql php-pear-MDB2-Driver-mysqli php-pear-DB perl-DBD-MySQL \
python python-devel texinfo uuid uuid-devel libuuid libuuid-devel jansson jansson-devel \
gmime-devel gmime
```

Some of those dependencies would only be needed if later you decide to include FreePBX in your gateway (like mysql and httpd).

More dependencies:

```bash
cd /usr/local/src/
git clone https://github.com/meduketto/iksemel

cd /usr/local/src/iksemel/

./autogen.sh
./configure
make
make install

cd /
```

We ensure NTP is active and running (disable chrony... for now):

```bash
systemctl stop chrony
systemctl disable chrony
systemctl enable ntpdate
systemctl enable ntpd
systemctl stop ntpd
systemctl start ntpdate
systemctl start ntpd
```

**NOTE: You are free to let ntp/ntpdate out of the picture if you prefer chrony instead of good-old ntp/ntpdate combo. It's completelly up to you**


### OPTIONAL: MariaDB configuration

If you plan to use MariaDB for CDR storage, or for other reasons (FreePBX backend), then proceed to configure it and activate it:

```bash
systemctl enable mariadb
systemctl start mariadb

/usr/bin/mysqladmin -u root password 'P@ssw0rd'
```

Create the file: `/root/.my.cnf`:

```bash
echo "[client]" > /root/.my.cnf
echo "user=root" >> /root/.my.cnf
echo "password=P@ssw0rd" >> /root/.my.cnf
```

And change its mode:

```bash
chmod 0400 /root/.my.cnf
```

**NOTE: This is completelly optional !. It's up to you and your requirements.**


### Asterisk Installation

We are going to install asterisk and r2 components from source so firs, we download the sources:

```bash
mkdir /workdir
cd /workdir
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/openr2/openr2-1.3.3.tar.gz
```

Un-compress all files:

```bash
tar -xzvf dahdi-linux-complete-current.tar.gz -C /usr/local/src/
tar -xzvf libpri-current.tar.gz -C /usr/local/src/
tar -xzvf asterisk-13-current.tar.gz -C /usr/local/src/
tar -xzvf openr2-1.3.3.tar.gz -C /usr/local/src/
```

Proceed to compile and install dahdi:

```bash
cd /usr/local/src/dahdi-linux-complete-*
make all
make install
make config
cp /usr/local/src/dahdi-linux-complete-*/tools/dahdi.init /etc/init.d/dahdi
cd /
```

Proceed to compile and install libopenr2:

```bash
cd /usr/local/src/openr2-*
./configure --prefix=/usr
make
make install

cd /
```

Proceed to compile and install libpri:

```bash
cd /usr/local/src/libpri-*
make
make install

cd /
```

Then, proceed to compile and install Asterisk:


```bash
cd /usr/local/src/asterisk-*
./contrib/scripts/install_prereq install
./configure --with-pjproject-bundled
ldconfig -v
./contrib/scripts/get_mp3_source.sh
make menuselect.makeopts
menuselect/menuselect --enable-category MENUSELECT_ADDONS \
--enable format_mp3 \
--enable res_config_mysql \
--enable app_mysql \
--enable cdr_mysql \
--enable app_meetme \
--enable MOH-OPSOUND-GSM \
--enable CORE-SOUNDS-EN-GSM \
--enable CORE-SOUNDS-ES-GSM \
--enable EXTRA-SOUNDS-EN-GSM
make
make addons
make install
make addons-install
make config
make progdocs
cd /
ldconfig -v
```

Then we proceed to copy the sample config files:

```bash
cp /usr/local/src/asterisk-13*/configs/samples/* /etc/asterisk/
cd /etc/asterisk/
for i in `ls`;do echo $i;mv $i `echo $i|sed 's/.sample//'`;done
cd /
```

We need to create an asterisk user:

```bash
adduser -M -c "Asterisk User" -d /var/lib/asterisk/ asterisk
```

And setup permissions for asterisk and this user:

```bash
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib/asterisk
```

Set the "sysconfig" file for asterisk (previouslly backup the original):

```bash
cp /etc/sysconfig/asterisk /etc/sysconfig/asterisk-ORIGINAL-DONTERASE
echo "AST_USER=\"asterisk\"" > /etc/sysconfig/asterisk
echo "AST_GROUP=\"asterisk\"" >> /etc/sysconfig/asterisk
```

Also, run the following command in order to "force" safe_asterisk to run asterisk with the user/group "asterisk/asterisk". Note that this seems to be now redundant on asterisk 13. See the note bellow:

```bash
sed -r -i 's/ASTARGS\=\"\"/ASTARGS\=\"-U\ asterisk\ -G\ asterisk\ \"/g' /usr/sbin/safe_asterisk
```

**NOTE: The last "patch" seems to be unnecesary on asterisk 13. Apply it if you see your "asterisk" not running with the proper user/group**

Run the following command:

```bash
ldconfig -v
```

Proceed to set on autostart the following services:

```bash
systemctl enable dahdi
systemctl enable asterisk
```

Create the following files:

```bash
echo "" > /etc/asterisk/sip_custom.conf
echo "" > /etc/asterisk/extensions_custom.conf
```

At the end of file `/etc/asterisk/sip.conf` add the following line (by running the command bellow):

```bash
echo "#include sip_custom.conf" >> /etc/asterisk/sip.conf
```

At the end of file `/etc/asterisk/extensions.conf` add the following file (by running the command bellow):

```bash
echo "#include extensions_custom.conf" >> /etc/asterisk/extensions.conf
```

Proceed to reset the permissions:

```bash
chown -R asterisk.asterisk /etc/asterisk
```

Start dahdi:

```bash
/etc/init.d/dahdi start
dahdi_genconf
/etc/init.d/dahdi restart
```

Reset dahdi devices permissions:

```bash
chown -R asterisk.asterisk /dev/dahdi
```

Please stop a moment here. The "dahdi_genconf" command will create the following files:


```bash
/etc/dahdi/system.conf
/etc/asterisk/chan_dahdi.conf
/etc/asterisk/dahdi-channels.conf
```

You must modify those files in order to set your "correct" configuration, specially if you are going to use MFC-R2. Also, set your SIP accounts/trunks in sip_custom.conf and dialplan/extensions on extensions_custom.conf:

```bash
/etc/asterisk/sip_custom.conf
/etc/asterisk/extensions_custom.conf
```

In order to allow the configuration to be active, proceed to restart dahdi and start asterisk:

```bash
/etc/init.d/dahdi restart
/etc/init.d/asterisk start
```

Now, it's time to create our log rotate in order to keep our logs at bay !:

```bash
echo "/var/log/asterisk/messages" > /etc/logrotate.d/asterisk
echo "/var/log/asterisk/queue_log" >> /etc/logrotate.d/asterisk
echo "/var/log/asterisk/cdr-csv/Master.csv" >> /etc/logrotate.d/asterisk
echo "{" >> /etc/logrotate.d/asterisk
echo -e "\tmissingok" >> /etc/logrotate.d/asterisk
echo -e "\trotate 5" >> /etc/logrotate.d/asterisk
echo -e "\tdaily" >> /etc/logrotate.d/asterisk
echo -e "\tcreate 0640 asterisk asterisk" >> /etc/logrotate.d/asterisk
echo -e "\tcompress" >> /etc/logrotate.d/asterisk
echo -e "\tpostrotate" >> /etc/logrotate.d/asterisk
echo -e "\t\t/usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null" >> /etc/logrotate.d/asterisk
echo -e "\tendscript" >> /etc/logrotate.d/asterisk
echo "}" >> /etc/logrotate.d/asterisk
```

We are ready to go. A Gateway is ready to work. In the following section, I'll show you an R2 configuration example.


### A typical MFC-R2 configuration example.

Le's see this scenario:

A Gateway installed using this recipe. The gateway has a VoIP Telephony card with 4 ports, all connected to a "Venezuelan" PSTN, of course, using R2. First thing to note is that the Venezuelan R2 version is not full R2... mean... the inbound lines are R2-Compelled (CAS Signalling), but, the outbound lines are DTMF over CAS signalling (yes... a Frankenstein...).

But we are very lucky, as libopenr2 supports this specific situation !.

What is the configuration for this scenario ??.

First: Dahdi: We need to reconfigure `/etc/dahdi/system.conf` file with the proper settings for those lines:

file `/etc/dahdi/system.conf`:

```bash
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

```bash
/etc/init.d/dahdi restart
```

Now, we need to configure asterisk with R2. First file to change:

File: `/etc/asterisk/chan_dahdi.conf`:

```bash
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

```bash
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

```bash
/etc/init.d/asterisk restart
```

In this example, the first two E1's are inbound, and the other two are outbound. The context for the inbound calls is "inbound" so you need to adjust your dial plan in "extensions_custom.conf" file accordingly. Likewise, the outbound channels are placed in "group 1" (g1) so you need to adjust your dial plan in order to use that group. Those are samples of course... you are free to change this in order to suit your real environment. Just let me tell you: This recipe is currently working on several gateways with 8 ports each one, and it just works flawlessly !. Just ensure to buy a good telephony card, and if possible, with hardware-based echo canceller and you're done !.

So that's all with this recipe. Eventually I'll put one more updated with Centos 7 (one we are testing where I currently work) so stay tuned for more !.

END.-
