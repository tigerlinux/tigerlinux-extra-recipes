#!/bin/bash
#
# Postgres-DB backup script
#
# By Reinaldo Martinez P.
# Caracas, Venezuela.
# TigerLinux AT gmail DOT com
#

postgresuser="postgres"
postgresgroup="postgres"
basedir="/postgres/data"
backuplogs="/postgres/backup"
backupdir="/mnt/db-backups"
mydatespec=`date +%Y%m%d%H%M`
myname=`hostname -s`
daystoretain="15"

logspec="$backuplogs/$myname-dumplog-$mydatespec.log"

if [ -d $basedir ]
then
    myservicelist=`ls $basedir`
else
    echo ""
    echo "Cannot access $basedir. Aborting"
    echo ""
    exit 0
fi

myuser=`whoami`

case $myuser in
root)
    mysucommand="su - $postgresuser -c "
    ;;
$postgresuser)
    mysucommand="bash -c "
    ;;
*)
    echo "Current user not root nor $postgresuser ... aborting !!"
    exit 0
    ;;
esac

#
# Note: If you change the postgresql version, please adjust this path:
#
PATH=$PATH:/usr/pgsql-9.5/bin/

#
# Main loop
#
for i in $myservicelist
do
    if [ -f $basedir/$i/postgresql.conf ]
    then
        #
        # We determine the port first:
        #
        myport=`grep port.\*= $basedir/$i/postgresql.conf|awk '{print $3}'`
        #
        # Then our database list, just in case the instance is running multiple databases
        #
        dblist=`$mysucommand "psql -U $postgresuser -p $myport -l -x"|grep -i name|awk '{print $3}'|grep -v template`
        #
        # Loop: Run all databases, and make the backup of each and every one.
        #
        for db in $dblist
        do
            if [ -d $backupdir ]
            then
                echo ""  >> $logspec
                echo "Backing Up Database $db on service $i, port $myport"  >> $logspec
                echo ""
                echo "Backing Up Database $db on service $i, port $myport"
                echo ""
                echo "Backup File: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                $mysucommand "pg_dump -U $postgresuser -p $myport -Z 9 $db" > \
                    $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz
            else
                echo ""  >> $logspec
                echo "Cannot access $backupdir in order to create the backup file"  >> $logspec
                echo ""  >> $logspec
            fi
            echo ""
            if [ -f $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz ]
            then
                if [ $myuser == "root" ]
                then
                    chown $postgresuser.$postgresgroup $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz
                fi
                echo ""  >> $logspec
                echo "Backup file created OK: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                echo "Backup file created OK: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"
                echo ""  >> $logspec
            else
                echo ""  >> $logspec
                echo "Failed to create backup file: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"  >> $logspec
                echo "Failed to create backup file: $backupdir/$myname-pgdump-$i-$myport-database-$db-$mydatespec.gz"
                echo ""  >> $logspec
            fi
            echo ""
        done
        #
        # End of loop
        #
    fi
done
#
#
#

if [ $myuser == "root" ]
then
    chown $postgresuser.$postgresgroup $logspec
fi

#
# Now we proceed to delete files older than "daystoretain"
# Backups and Backup Logs.
#

find $backupdir -name "$myname-pgdump-*-database-*.gz" -mtime +$daystoretain -delete
find $backuplogs -name "$myname-dumplog-*.log" -mtime +$daystoretain -delete

#
# END
#
