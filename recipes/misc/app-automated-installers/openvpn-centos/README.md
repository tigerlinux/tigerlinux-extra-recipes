# OPENVPN AUTOMATED INSTALLATION FOR CENTOS 7

This script will install and fully configure an OpenVPN OpenSource server with tls authentication and strong ciphers.

The script creates all required certificates (using easyrsa) and also create an usable "first client" in the directory "/etc/openvpn/easy-rsa/keys/client01". All the files there can be used on any openvpn client (windows, linux, etc.):

```bash
ls /etc/openvpn/easy-rsa/keys/client01/ -la
total 24
drwxr-xr-x 2 root root  104 Jul 19 18:55 .
drwxr-xr-x 4 root root   44 Jul 19 18:56 ..
-rw------- 1 root root 1854 Jul 19 18:55 client01-ca.crt
-rw------- 1 root root 7154 Jul 19 18:55 client01.crt
-rw------- 1 root root 3272 Jul 19 18:55 client01.key
-rw-r--r-- 1 root root  375 Jul 19 18:55 client01.ovpn
-rw------- 1 root root  636 Jul 19 18:55 client01-openvpn.tlsauth
```

All those files should be placed on your "config" directory (at your OpenVPN client).

# Helper script "/usr/local/bin/generate-new-openvpn-client.sh".

the script **/usr/local/bin/generate-new-openvpn-client.sh** will help you create new OpenVPN clients (with all the required files). Usage:

```bash
/usr/local/bin/generate-new-openvpn-client.sh name-of-client
```

Example:

```bash
/usr/local/bin/generate-new-openvpn-client.sh client02
```

The example above will create all client files on the directory "/etc/openvpn/easy-rsa/keys/client02"

Try not to use spaces or other wierd strings. Also try to avoid capitals. But you can use any of the following examples:

```bash
/usr/local/bin/generate-new-openvpn-client.sh client.02
/usr/local/bin/generate-new-openvpn-client.sh pepe-trueno
/usr/local/bin/generate-new-openvpn-client.sh jane.doe
/usr/local/bin/generate-new-openvpn-client.sh quick_silver02
```

The client files will be always under the directory "/etc/openvpn/easy-rsa/keys/CLIENTNAME" (where "CLIENTNAME" is the name you used on the script).

# Further customization.

Begining the script you'll see the following section:

```bash
# Begining of Customization
#
# Ensure to set the following variables to the proper values, specially the
# VPN_PUBLIC_IP. If you don't modify "VPN_PUBLIC_IP", the script will default
# to the server main IP. If you use the name "CURL" the script will try to
# determine the VPN IP from the "outside publicly detectable" IP.
#
EASYRSA_REQ_COUNTRY="US"
EASYRSA_REQ_PROVINCE="Michigan"
EASYRSA_REQ_CITY="Chicago"
EASYRSA_REQ_ORG="TigerLinux Company INC"
EASYRSA_REQ_EMAIL="nobody@none.com"
EASYRSA_REQ_OU="Operations"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
#
VPN_PUBLIC_IP="127.0.0.1"
# VPN_PUBLIC_IP="CURL"
#
# Set also OpenVPN protocol. tcp or udp. Our default is udp
# VPN_PROTOCOL="tcp"
VPN_PROTOCOL="udp"
#
# And the OpenVPN port:
VPN_PORT="1194"
#
# End of Customization
```

Those variables can be adjusted to suit your needs:

- EASYRSA VARS: Change your country, province, city, organization name, email and organizational unit according to your environment.
- DNS1 and DNS2: By default we use google on the script but if you need to use a different set of DNS's change both variables with the IP's of your DNS's.
- VPN_PUBLIC_IP: Here you have 3 options. Using "127.0.0.1" will force the script to detect the real IP on the server and use it for the OpenVPN client files. Using "CURL" will force the script to detect the "really public" IP on the server assuming it is behind a NAT/DNAT, then use for the OpenVPN client files. Using another entry (a "real" IP) will force the server to use that IP for the OpenVPN client files.
- VPN_PROTOCOL: Which VPN protocol to use (tcp or udp). By default: udp.
- VPN_PORT: OpenVPN port to use. Our default is 1194.


We are using the network "172.16.27.0/24" as the subnet that the OpenVPN server will use for the clients and "tun0" interface.

# Logs: 

The script will log all the installation steps/results on the file "/var/log/openvpn-server-automated-installer.log". The OpenVPN service will send all its syslog messages to the internal syslog service (normally on /var/log/messages).

# OPENED PORTS

FirewallD allow traffic for the following ports only (input traffic):

- 22 tcp (ssh).
- OpenVPN port (by default 1194 udp). FirewallD will open the proper port/protocol depending of the variables "VPN_PROTOCOL" and "VPN_PORT".

# NAT/DNAT

This recipe is "NAT/DNAT" compatible. If your OpenVPN box is behind a nat, just ensure to forward the port from your external IP's to your internal IP and VPN port. Try to forward the same port you are using for OpenVPN.

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 512Mb.
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 5GB.
