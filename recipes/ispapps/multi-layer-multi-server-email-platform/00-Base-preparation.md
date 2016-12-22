# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD - Base LAB preparation

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## NFS Services.

We prepared an Centos 7 base instance with a 2Terabyte Cinder extra-volume which we exported using NFS:

```bash
172.16.11.57:/NFSVOL
```

The NFS Server IP is 172.16.11.57, and the NFS resource name is "/NFSVOL". The cinder volume device (/dev/vdb) is mounted inside the NFS Server in the "/NFSVOL" directory.


## A/D Services.

Our MS Active Directory Server (Windows 2008 R2 64 bits) serve the A/D domain "domain01.dom". IP: 172.16.11.63

We created a "bind" account for most ldap operations (read-only):

cn=correoapp,ou=mailapps,dc=domain01,dc=dom
Password: Pass2016Mail

This LDAP account will be used by all OpenSource components in order to interface with the active directory.

We also created the following users in order to test the platform:

Users: usuario01, usuario02, usuario03, all with domain "domain01.dom" and password "P@ssw0rd".


##  Service Instances.

We started using one instance by layer, all Centos 7 with EPEL repository, firewalld and selinux disabled, full updated:

- 172.16.11.97: SMTP-Incomming.
- 172.16.11.95: SMTP-Outgoing.
- 172.16.11.96: POP-IMAP-SMTP-Delivery (POP-IMAP-LDA).
- 172.16.11.98: SOGO GROUPWARE WEBMAIL.
- 172.16.11.99: TINE 2 GROUPWARE WEBMAIL.


## Our DNS Domains.

This platform will serve two domains, that for privacy reasons, we called "domain01.dom" and "domain02.dom". 

Our Cloud instances and LBaaS accesspoints are located in the following DNS domain:

```
cloud0.hc.mycompany.dom
```

Our LBaaS access points DNS in the OpenStack cloud are:

- SMTP-Incomming: smtp-in.cloud0.hc.mycompany.dom (dns aliases for MX ingress: smtp-in.domain01.dom and smtp-in.domain02.dom)
- SMTP-Out: smtp-out.cloud0.hc.mycompany.dom (dns alias in the external world: mail.mycompany.dom).
- POP-IMAP-SMTP-Delivery SMTP Access: smtp-delivery.cloud0.hc.mycompany.dom.
- POP Access: pop.cloud0.hc.mycompany.dom (dns alias in the external world: pop.mycompany.dom).
- IMAP Access: imap.cloud0.hc.mycompany.dom (dns alias in the external world: imap.mycompany.dom).
- Webmail: webmail.cloud0.hc.mycompany.dom (dns alias in the external world: webmail.mycompany.dom).


## LBaaS.

If you are going to use OpenStack LBaaS, we recommend to update your systems to Mitaka LBaaSV2, as you will be able to include multiple listeners (and ports) in a single VIP. Also, remember you can termitate SSL-HTTP traffic with LBaaS V2, that will allow you a more simpler SSL configuration for your services.

FIN.-
