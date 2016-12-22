# AN ASTERISK BASED VOIP GATEWAY SUPPORTING MFC-R2 PROTOCOL ON CENTOS (6 AND 7)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction

Before we start this recipe I want to say something: I REALLY REALLY HATE MFCR2 Telephony Protocol and I REALLY REALLY HATE every and each telephony provider still using it. Having said that, I want to state my motivation about documenting this recipe: In many years of my technical career I have been working with asterisk in my country (Venezuela). The providers here uses this long-forgotten and very obsoleted protocol. That means, we **NEED** to support this R2 protocol on Asterisk if we want asterisk to really work in Venezuela (and other countries still using R2).

In the moment I'm writing this recipe, I'm working for a call-center services company with all their services in OpenStack based cloud's (I'm the cloud arquitech by the way) and all VoIP systems we currently have are asterisk-based. Not all of our asterisk implementations are in the cloud: The gateways are the exception.

Our gateways are, of course, Asterisk based. First we used to have very modified Elastix-based gateways, but then we decided to make our own "asterisk-recipe" based on Centos 6.

Why our gateways are not virtual ??.. Because the VoIP cards !. It is impractical to include in an OpenStack compute server a VoIP card, so, we need to create bare-metal based gateways !.

The recipe is using OpenSource software. Nothing here is licensed so you can replicate this recipe (and adapt it) to whatever environment you have, even if you are not using MFCR2.


## What kind of hardware and software you need ?.

This is aimed to production, so I pass the "testing" recomendations: You need a bare metal !. A physical server. Also you need a telephony card, fully compatible with asterisk/dahdi and with Centos 6 and 7 support.

About the software: You'll need a machine with the following software requeriments:

* Centos 6 (32 or 64 bits) fully updated, or Centos 7 (64 bits) fully updated.
* EPEL Repository installed. For EPEL install instruction see: https://fedoraproject.org/wiki/EPEL.


## What knowledge should you need to have at hand ?:

* General Linux administration.
* Asterisk Knowledge.
* VoIP and Telephony concepts.


## What files you'll find here ?:

* [RECIPE-gateway-asterisk-R2-Centos6.md: Our recipe, in markdown format, for Centos 6.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/asterisk/mfcr2-asterisk-gateway/RECIPE-gateway-asterisk-R2-Centos6.md "Our Asterisk R2 VoIP Gateway Recipe - Centos 6")
* [RECIPE-gateway-asterisk-R2-Centos7.md: Our recipe, in markdown format, for Centos 7.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/asterisk/mfcr2-asterisk-gateway/RECIPE-gateway-asterisk-R2-Centos7.md "Our Asterisk R2 VoIP Gateway Recipe - Centos 7")
* [gw-asterisk-c7-for-cloud.sh: Scripted version of our Centos 7 recipe, fully automated for running in cloud environments.](https://github.com/tigerlinux/tigerlinux.github.io/blob/master/recipes/asterisk/mfcr2-asterisk-gateway/gw-asterisk-c7-for-cloud.sh "Scripted version of our C7 Recipe")

