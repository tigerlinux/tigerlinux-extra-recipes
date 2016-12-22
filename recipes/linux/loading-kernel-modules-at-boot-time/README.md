# LOADING LINUX KERNEL MODULES AT BOOT TIME.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Sometimes, we need our linux machine to load some non-standard or non-common kernel modules at boot time (things like "dummy", "snd-dummy", "loop", or others similar cases). Every distro have a way to do this, and we are going to show in this recipe how do that the most commonly used distros out there.


## RHEL Based series 6/7 (Including Centos 6, Centos 7, SL 6, SL 7, etc).

You need to add a file in your `/etc/sysconfig/modules` directory with the name of the module and the extension "modules". Example (for the snd-dummy module):

```bash
vi /etc/sysconfig/modules/snd-dummy.modules
```

Then, in the file you should include the "/sbin/modprobe" command followed by your module:

File "/etc/sysconfig/modules/snd-dummy.modules" contents:

```bash
/sbin/modprobe snd-dummy
```

Finally, make exec your file:

```bash
chmod 755 /etc/sysconfig/modules/snd-dummy.modules
```

Everytime your O/S boots, it will exec all ".modules" files in the "/etc/sysconfig/modules/", loading your desired modules.


## Debian 7, Debian 8, Ubuntu 14.04lts, Ubuntu 16.04lts:

Debian's and Ubuntu's are simpler. Just edit the following file:

```bash
vi /etc/modules
```

And include the modules:

```bash
snd-dummy
dummy
loop
```

Our last sample included the modules: snd-dummy, dummy and loop.

NOTE: In some of those distros, you'll find the file "/etc/modules-load.d/modules.conf" which actually is a "symlink" to /etc/modules. This is becoming common on "systemd" based distros.


## Fedora 21, 22 and 23.

For Fedora based distros using "systemd", you just need to create a ".conf" file inside the "/etc/modules-load.d/" directory and put the module name inside the file. Example:

```bash
vi /etc/modules-load.d/snd-dummy.conf
```

Containing:

```bash
snd-dummy
```

End.-
