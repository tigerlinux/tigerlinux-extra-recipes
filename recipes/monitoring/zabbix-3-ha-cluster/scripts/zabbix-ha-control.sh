#!/bin/bash
#
# Zabbix HA Control Services
#
# By Reinaldo Martinez P.
# Caracas, Venezuela.
# TigerLinux AT Gmail DOT Com
#

case $1 in
start)
        echo "Starting Zabbix Services"
        systemctl start zabbix-server.service
        systemctl start httpd.service
        ;;
stop)
        echo "Stopping Zabbix Services"
        systemctl stop zabbix-server.service
        systemctl stop httpd.service
        ;;
status)
        echo "Zabbix Services Status"
        systemctl status zabbix-server.service
        echo ""
        echo ""
        systemctl status httpd.service
        ;;
esac
