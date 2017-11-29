# WAZUH AUTOMATED INSTALLER FOR CENTOS7

This script will do a basic distribution setup with some usefull packages, then install and configure ElasticSearch 5, LogStash 5 and Kibana 5 (Full ELK 5 Stack) with all required dependencies, and WAZUH with configured with ELK. It will also configure all required SSL Certificates inside the directory "/etc/pki/CA-ELK/". You'll find there the CA (already integrated to the centos7 operating system), the server certificate and keys, and a "client1" certificate and keys. The "pki" infrastructure was generated using easyrsa. You'll find easyrsa directory with the source PKI at "/root/easy-rsa-master/easyrsa3/".

The web frontend (using nginx) is password-protected. The credentiales are stored on the file "/root/wazuh-server-credentials.txt". All tasks outputs performed by this script are logged to the file "/var/log/wazuh-server-automated-install.log".

# WAZUH API

After the installation is done, see your credentials inside the file "/root/wazuh-server-credentials.txt" and enter to the web browser with the user/pass for Kibana. Go to the "wazuh" section, and add the API using the information inside the "/root/wazuh-server-credentials.txt" file. The data you'll need will be:

- Username: wazuhapiadm
- Password: The one included in the credentials file (API User Password: XXXXXXXX). Remember this password is auto-generated and will be different each time you use this script.
- URL: http://127.0.0.1
- PORT: 55000

Please note that this script will disable selinux.

# OPENED PORTS

FirewallD allow traffic for the following ports only (input traffic):

- 80 tcp (http).
- 443 tcp (https).
- 22 tcp (ssh).
- 5044 tcp (logstash forwarder - encrypted).
- 1514 tcp/udp (ossec).

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 4GB
- CPU: 2 Cores/Threads.
- FREE DISK SPACE: 5GB.

