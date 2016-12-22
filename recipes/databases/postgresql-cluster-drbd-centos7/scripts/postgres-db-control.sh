#!/bin/bash
#
# Postgres-DB control script
#
#
# By Reinaldo Martinez P.
# Caracas, Venezuela.
# TigerLinux AT gmail DOT com
#
#

postgressvcdir="/postgres"
postgresuser="postgres"
basedir="/postgres/data/"
#mydblist='
#    database01
#    database02
#'

mydblist=`ls $basedir`

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

PATH=$PATH:/usr/pgsql-9.5/bin/

if [ ! -z $2 ]
then
    mydblist=$2
fi

case $1 in
start)
    echo ""
    for i in $mydblist
    do
        echo "Starting Database Service: $i"
        echo ""
        $mysucommand "pg_ctl start -D /postgres/data/$i > /postgres/data/$i/startlog.log"
        echo ""
        echo "Status:"
        $mysucommand "pg_ctl status -D /postgres/data/$i"
    done
    echo ""
    ;;
stop)
    echo ""
    for i in $mydblist
    do
        echo "Stopping Database Service: $i"
        $mysucommand "pg_ctl stop -D /postgres/data/$i"
    done
    echo ""
    ;;

stopfast)
        echo ""
        for i in $mydblist
        do
                echo "Stopping Database Service - FAST MODE - : $i"
                $mysucommand "pg_ctl stop -D /postgres/data/$i -m fast"
        done
        echo ""
        ;;
status)
    echo ""
    for i in $mydblist
    do
        echo ""
        echo "Status of Database Service: $i"
        $mysucommand "pg_ctl status -D /postgres/data/$i"
        echo ""
    done
    echo ""
    ;;
restart)
    echo ""
    for i in $mydblist
    do
        echo "Restarting Database Service: $i"
        echo ""
        $mysucommand "pg_ctl restart -D /postgres/data/$i > /postgres/data/$i/startlog.log"
        echo ""
        $mysucommand "pg_ctl status -D /postgres/data/$i"
        echo ""
    done
    echo ""
    ;;
*)
    echo ""
    echo "Usage: $0 start|stop|stopfast|status|restart"
    echo ""
    ;;
esac
