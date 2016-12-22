# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - EXTRA - SOLR INSTEAD OF LUCENE FOR FTS (DOVECOT)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## About SOLR and FULL TEXT SEARCH (FTS)

Our default POP-IMAP-LDA deployment was installed with lucene FTS. Lucene use all their data and indexes in the same NFS user mailbox. This can and will use more of your very precious disk I/O, and considering we are using NFS, maybe it's a good idea to use another FTS solution not needing to store indexes in the same mailbox space as the user e-mail.

In order to test a better option than lucene, we'll proceed to install SOLR and adapt it to Dovecot.


## SOLR Installation.

Those installation steps can be done in a dedicated SOLR server, or, in the same server where POP-IMAP-SMTP-Delivery is installed.

First, we need to install OpenJDK 8:

```bash
yum install java-1.8.0-openjdk
```

Download an install SOLR (Please adjust the version numbers according to your actual environment. At the moment we deployed this solution, SOLR 4.10.4 was the last stable version, but, more recent versions are available here: https://archive.apache.org/dist/lucene/solr/):

```bash
mkdir -p /opt/solr/core/

mkdir /workdir
cd /workdir

wget https://archive.apache.org/dist/lucene/solr/4.10.4/solr-4.10.4.tgz

tar -xzvf solr-4.10.4.tgz

cd /workdir/solr-4.10.4/example/

cp -vR * /opt/solr/core/

cp /usr/share/doc/dovecot-2.2.10/solr-schema.xml /opt/solr/core/solr/collection1/conf/schema.xml
```

**NOTE:** If newer versions of SOLR gives you any trouble, stick with 4.10.4:

```bash
wget https://archive.apache.org/dist/lucene/solr/4.10.4/solr-4.10.4.tgz
```

Please note that the `solr-schema.xml` file obtained from Dovecot is needed for SOLR in order to be compatible with Dovecot FTS IMAP implementation.

Download, activate and enable the "solr" sysv init script:

```bash
wget https://raw.githubusercontent.com/extremeshok/solr-init/master/solr.centos -O /etc/init.d/solr

chmod 755 /etc/init.d/solr

chkconfig --add solr
chkconfig solr on
service solr start
```

NOTE: If for some reason the "init script" becomes unavailable, it's original contents follow:

```bash
#!/bin/bash
#
# chkconfig: 2345 20 20
# short-description: Solr
# description: Startup script for Apache Solr Server by Adrian Jon Kriel

### BEGIN INIT INFO
# Provides:          vnstat
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:
# Default-Stop:
# Short-Description: lightweight network traffic monitor
### END INIT INFO
#

# Source function library.
. /etc/rc.d/init.d/functions

prog="solr"
RETVAL=0
PIDFILE="/var/run/solr.pid"
SOLR_DIR="/opt/solr/core"
LOG_FILE="/var/log/solr.log"
JAVA="/usr/bin/java"
OPTIONS="-Xmx1024m -DSTOP.PORT=8079 -DSTOP.KEY=stopkey -jar start.jar"

start()
{
  echo -n $"Starting $prog: "
  if [ -e "$PIDFILE" ] && [ -e /proc/`cat "$PIDFILE"` ]; then
    echo -n $"already running.";
    success "$prog is already running.";
    echo
    return 0
  fi
  cd $SOLR_DIR
  nohup $JAVA $OPTIONS > $LOG_FILE 2>&1 &
  echo $! > $PIDFILE
  sleep 2
  RETVAL=$?
  if [ $RETVAL = 0 ]; then
    echo "done."
  else
    echo "failed. See error code for more information."
  fi
  return $RETVAL
}

stop()
{
  echo -n $"Shutting down $prog: "
  killproc -p $PIDFILE
  #pkill -f start.jar > /dev/null
  RETVAL=$?
  echo
  rm -f $pidfile

  if [ $RETVAL = 0 ]; then
    echo "done."
  else
    echo "failed. See error code for more information."
  fi

  return $RETVAL
}

##NOT USED, purely for reference or if there are future bugs with status $progs
mystatus()
{
  if [ -e "$PIDFILE" ] && [ -e /proc/`cat "$PIDFILE"` ]; then
    echo -n $"$prog is already running.";
    success "$prog is already running.";
    echo
    return 0
  else
    echo -n $"Not running.";
    echo
    return 0
  fi


}

case "$1" in
start)
  start
  ;;
stop)
  stop
  ;;
restart)
  stop
  start
  ;;
status)
  #mystatus
  status $prog
  ;;
*)
  echo $"Usage: solr {start|stop|restart|status}" >&2
  RETVAL=3
esac
exit $RETVAL
```

In any case, after we start SOLR server, we can check it by entering to the following URL:

```bash
curl http://172.16.11.96:8983/solr
```

If you can enter to the URL, and, you are installing SOLR in the same server (or servers) used for POP-IMAP-SMTP-Delivery, adjust SOLR to server trough Localhost:

```bash
sed -i 's|name="jetty.host"|name="jetty.host" default="127.0.0.1"|g' /opt/solr/core/etc/jetty.xml
```

And, restart the service:

```bash
service solr stop
service solr start
```

We can check the service is using localhost:

```bash
[root@host-172-16-11-96 log]# netstat -ltn|grep 8983
tcp6       0      0 127.0.0.1:8983          :::*                    LISTEN
```


## Changes in DOVECOT.

You need to change your `/etc/dovecot/dovecot.conf` file:

The following section:

```bash
mail_plugins = acl quota fts fts_lucene
```

Change it to:

```bash
mail_plugins = acl quota fts fts_solr
```

The following section:

```bash
  # FTS Support:
  fts = lucene
  fts_lucene = whitespace_chars=@.
  fts_autoindex = yes
```

Change it to:

```bash
  # FTS Support:
  fts = solr
  fts_solr = break-imap-search url=http://localhost:8983/solr/
  fts_autoindex = yes
```

**NOTE:** If you are using SOLR installed in the same dovecot server, use "localhost". If you are using another server, put here it's IP or FQDN.

Restart dovecot:

```bash
systemctl restart dovecot
```

Dado que los antiguos índices de lucene no nos sirven, procedemos a eliminar los indices de lucene y reindexar todos los buzones:

Due the fact that any previous lucene index is no longer needed, proceed to erase all of them, and also, reindex all mailboxes (this will generate solr indexes):

In any POP-IMAP-SMTP Delivery server run:

```bash
cd /var/vmail

find . -name "lucene-indexes" -exec rm -rf {} ";"

for i in `ls|grep -v shared-mailboxes`; do doveadm -Dv fts rescan -u $i;done
for i in `ls|grep -v shared-mailboxes`; do doveadm -Dv index -u $i *;done
for i in `ls|grep -v shared-mailboxes`; do doveadm -Dv fts rescan -u $i;done
```

All SOLR indexes will be located here:

```bash
/opt/solr/core/solr/collection1/data/
```

Es recomendable como post-configuración mover este directorio a /var:

We need to move this directory to "/var/solr":

```bash
systemctl stop dovecot
systemctl stop solr

mkdir /var/solr
mv /opt/solr/core/solr/collection1/data /var/solr/
ln -s /var/solr/data /opt/solr/core/solr/collection1/data

systemctl start solr
systemctl start dovecot
```

At this point, your system will use SOLR instead of LUCENE for all FTS functions.

END.-
