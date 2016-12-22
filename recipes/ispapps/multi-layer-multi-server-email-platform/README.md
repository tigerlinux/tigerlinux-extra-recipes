# A MULTI LAYER / MULTI SERVER E-MAIL PLATFORM FOR THE CORPORATE PRIVATE CLOUD

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Today, many companies opted to discard their own mail-platforms in favor of an ISP-provider maintained platform, or any other cloud-provided e-mail solution. But for some companies, due strategic, legal, or "whatever" reasons, this option is not feasible, so they need to maintain their own "in-house" solutions.

But... what about scalability ??.. what about survivability ?. What if, you are modernizing your systems, and converting all your stuff in a "private-cloud" based solution ?. What to do with the e-mail platform ?. It can be moved to a private cloud ?.

The answer is YES..... but "yes" if you think of "scalability" and "survivability".

This entire recipe, is not only about the construction of common e-mail platform components.. is also about what you should take into account when designing and implementing your e-mail platform in a cloud environment.


## Think about layers and servers.

If you pretend to be scalable, the first thing you should do is to consider a multi-layer/multi-server approach, where every layer contains its own servers with specific missions and also, those layers, are "load balanced" using a LBaaS solution in the cloud (like OpenStack LBaaS V1 or V2).

Each layer will have a specific function: SMTP-Outgoing, SMTP-Incomming, POP-IMAP-SMTP-Delivery, WebMail, etc. With this approach you can isolate traffic types, and exercise a more precise control of those different traffic and implement different security policies by layer.


## SMTP-Incomming Layer.

Our first layer is the "SMTP Incomming". This one will have a LBaaS entry point (tcp port 25) and it will be exposed to the Internet in order to receive all incomming mail. If your cloud has no public IP's, you should forward an external IP tcp 25 port to the VIP defined in the LBaaS entry point.

This layer will have all common anti-spam/anti-virus/dnsbl/spf policies so it will be your first line of defense. All e-mail surviving this layer (meaning, "not-spam") will continue to the next layer (POP-IMAP-SMTP-Delivery).


## POP-IMAP-SMTP-Delivery Layer.

This layer is the one that will interface with your mailbox storage (mounted NFS in this solution). Why NFS ?. Will talk in more detail later, but, for now, let's say that the only way to have multiple POP/IMAP/Delivery servers against the same shared storage is by using shared storage protocols, meaning: NFS.

Why pop, imap and smtp-delivery in the same server layer ?. Just in order to simplify layers. Due the fact those 3 protocols use the same software and also interacts with the same mailbox storage, we can combine them in the same service. You of course can separate smtp-delivery from pop/imap at later stages.

About smtp-delivery: This service layer will get all mail comming from the SMTP-Incomming layer, and deliver to the mailboxes. This layer also does "aliases/distribution-lists" expansion (group1@mydomain.dom -> user1, user2, user3, etc) and manages mailbox quota policies comming from ldap per-user or hard-coded for all users.

About POP/IMAP: Those are the "mail-retrieval" protocols used by most mail clients (including the Webmail).

Talking about LBaaS: POP, IMAP and SMTP-Delivery services will need each it's own LBaaS listener or VIP. Normally:

* SMTP-Delivery: TCP 25.
* POP: TCP 110.
* IMAP: TCP 143 and TCP 4190. The last port is for the SIEVE protocol.


## SMTP-Out Layer.

This layer will "relay" user-email from your corporate users. The relaying include internal messaging (corporate mail) and external destinations (outbound e-mail). Of course, this layer includes authentication, so, no mail from non-authorized origins will be able to traverse this layer.

Common e-mail control methods like antivirus and dkim will be included in this layer, just in order to avoid your users to "contamine" the Internet !.

Like the other layers, this one will need a dedicated LBaaS Access point (TCP 25).


## Webmail access Layer.

What is an e-mail platform without a proper webmail ?. This layer will contain your Web access software, of course Load Balanced with it's own LBaaS access point. This layer WILL NEED access to the IMAP interface in your POP-IMAP-SMTP-Delivery layer.


## NFS Storage.

You have many ways to add NFS storage to the whole solution:

* Dedicated high-speed NAS.
* NFS Server using a Cloud Storage backend (like OpenStack CINDER).
* File Sharing as a Service Solution (like OpenStack MANILA).

Whatever solution you choose, remember to have proper networking for it. Meaning, no less than gigabit-class interfaces or you'll suffer high I/O-Wait CPU Loads in your POP-IMAP-SMTP-Delivery servers.


## Authentication.

Let's be honest: While this e-mail platform is using common OpenSource solutions, we design it to be capable to use existing "Microsoft Active Directory" as a user-database and authentication system. Most companies out there use a lot of MS A/D services for their core corporate networks, so, instead of "reinventing the wheel", we prefer to show you how to connect all opensource-based solutions we are using in this e-mail system to your existing A/D.

Of course, if you don't have an MS A/D, you can still use LDAP, or, emulate a MS A/D with Samba 4 or Zentyal (which also uses Zamba 4 for A/D emulation).


## Software components.

All we are using here is OpenSource. The base distribution is CENTOS 7 with EPEL installed, firewalld and selinux disabled. Due the fact that we installed all this solution in OpenStack based instances, we used openstack security groups instead of firewalld/selinux to secure our machines.

The components used here (we deployed this solution first time in July 2015.. some versions probably changed):

SMTP-OUT:

- Postfix 2.10 (optional: 2.11)
- Clamav 0.98.7
- OpenDKIM 2.10
- cyrus-sasl 2.1

SMTP-IN:

- Postfix 2.10 (optional: 2.11)
- Clamav 0.98.7
- amavisd-new 2.10
- spamassassin 3.4.0

POP-IMAP-LDA:

- Postfix 2.10 (optional: 2.11)
- Dovecot 2.2.10

SOGO:

- sogo 2.3.1
- httpd (apache) 2.4.6


## Our recipes:

We devided our recipes "by layer" in the following order:

* [Base Environment Preparation](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/00-Base-preparation.md)
* [POP-IMAP-SMTP Delivery Services](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/01-POP-IMAP-LDA-Layer.md)
* [SMTP-OUT Services](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/02-SMTP-OUT-Layer.md)
* [SMTP-IN Services](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/03-SMTP-IN-Layer.md)
* [SoGo-Based WEBMAIL/Groupware Services](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/04-SOGO-Webmail-Layer.md)
* [EXTRA: SOLR for FTS at IMAP Level](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/05-EXTRA-SOLR-FTS.md)
* [EXTRA: SSL Encrypted Services](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/ispapps/multi-layer-multi-server-email-platform/06-EXTRA-SSL-Services.md)

END.-
