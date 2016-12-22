#!/bin/bash
#
# Server Backup Script
#
# By Reinaldo Martinez P.
# Caracas, Venezuela.
# TigerLinux AT gmail DOT com
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

directory="/mnt/backups"
myhostname=`hostname -s`
timestamp=`date +%Y%m%d`
daystoremove=5
databasebackupuser="root"
databasebackuppass="P@ssw0rd"

#databases='
#        mysql
#        test
#'
databases=`echo "show databases"|mysql -s -u $databasebackupuser -p$databasebackuppass`

for i in $databases
do
        nice -n 10 ionice -c2 -n7 \
	mysqldump -u $databasebackupuser \
	-p$databasebackuppass \
	--single-transaction \
	--quick \
	--lock-tables=false \
	$i|gzip > $directory/backup-server-db-$i-$myhostname-$timestamp.gz
done

find $directory/ -name "backup-server-*$myhostname*gz" -mtime +$daystoremove -delete
find $directory/ -name "backup-server-db-*$myhostname*gz" -mtime +$daystoremove -delete

echo ""
echo "Server Backup Ready (Configurations and databases)"
echo "Log at: /var/log/server-backup-last-results.log"
echo "Backup file at: $directory/backup-server-$myhostname-$timestamp.tgz"
echo "Databases Backups at $directory/backup-server-db-DBNAME-$myhostname-$timestamp.gz"
echo ""

