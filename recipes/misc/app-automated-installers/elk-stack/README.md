# ELS STACK (SERIES 5) AUTOMATED INSTALLER FOR CENTOS7

This script will do a basic distribution setup with some usefull packages, then install and configure ElasticSearch 5, LogStash 5 and Kibana 5 (Full ELK 5 Stack) with all required dependencies. It will also configure all required SSL Certificates inside the directory "/etc/pki/CA-ELK/". You'll find there the CA (already integrated to the centos7 operating system), the server certificate and keys, and a "client1" certificate and keys. The "pki" infrastructure was generated using easyrsa. You'll find easyrsa directory with the source PKI at "/root/easy-rsa-master/easyrsa3/".

The web frontend (using nginx) is password-protected. The credentiales are stored on the file "/root/elk-stack-credentials.txt". All tasks outputs performed by this script are logged to the file "/var/log/elk-stack-automated-install.log".

# Filebeat

Filebeat has been installed and configured on the ELK Stack server and it will send all logs to logstash (and from there to elasticsearch). You'll need to creat and index with the pattern "filebeat-*" in your kibana web frontend in order to use the information shipped by filebeat.

Please note that this script will disable both firewalld and selinux. If you want you can install them back after this script finish its run.

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 4GB
- CPU: 2 Cores/Threads.
- FREE DISK SPACE: 5GB.

