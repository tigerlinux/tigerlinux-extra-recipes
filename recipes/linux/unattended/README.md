# UNATTENDED INSTALLATION TEMPLATES FOR CENTOS, DEBIAN AND UBUNTU.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction.

Both RHEL and DEBIAN based distros can be installed non-interactivelly by the use of "templates" which include all installation options. Those options include:

- Basic console configuration (keyboard, locales, etc).
- User creation, root account password.
- Disk partitioning.
- Package source (AKA: Installation Mirror).
- Package selections
- And, custom command to be executed after normall installation, AKA: Postinstall scripts.

Debian-based distros use "preseed", while RHEL based use "anaconda".

Each of those installation tools (preseed/anaconda) have it's own rules and config options that when used with a "preseed file" (debian's) or "kickstart file" (rhel's), basically produces the same results: A ready-to-use machine !.

This is basically an "unattended" installation !. This installation philosophy have many advantages over interactive installations. We can mention a few:

- All machines follow a common standard !. There is no risk of missing steps due "human error". This is specially usefull for disk partitioning and package selection.
- We can provision many machines at the same time, or in general in shorter times than doing it interactivelly.
- It's perfect in order to provision server with applications ready to go. The postinstall can be used not only for specialized application installation, but also for restoring states from applications (like restoring a previous database backup).
- Recovery of a downed/destroyed machine is easier. Just use the same preseed/kickstart file used to originally provision the machine.
- Combined with a local mirror infrastructure, deployment times of bare-metal servers can be shortened a lot !.
- It's also a good option (but not the only one) for the creation of cloud-based images (specially for OpenStack) that you want to fine-tune for your private cloud.
- You can include in your template automated configutation tools like puppet, or ansible, ready to start at first-boot in order to keep up-to-date latest changes to your server infraestructure.


## What will you find here ?.

The "unattended" section here contains the following directories:

- centos6: Templates for centos 6 (32 and 64 bits).
- centos7: Templates for centos 7 (64 bits).
- debian7: Templates for debian 7 (32/64 bits).
- debian8: Templates for debian 8 (32/64 bits).
- ubuntu1404lts: Templates for Ubuntu 14.04LTS (32/64 bits).
- ubuntu1604lts: Templates for Ubuntu 16.06LTS (32/64 bits).
- supportfiles: Support scripts used by the preseed/kickstart templates.

In each template directory, you'll find templates that includes:

- Installation templates for servers without LVM (/boot and /). Swap is auto-calculated by the O/S.
- Installation templates for servers with LVM (/boot, /usr, /, /var). Swap is auto-calculated bythe O/S.
- Installation templates for cloud-init based cloud-images (specially for OpenStack) and no SWAP (again, specially for OpenStack, that provides a dedicated swap disk).

Each template file is very well documented, with usage instructions for each case.


## Template usage - Normal "non-cloudinit" servers:

In each template you'll find the instructions very well commented at the beginning of the file, but basically you'll need to boot your machine with the "netinstall" installation disk (or ISO if you are using any virtalization tool like kvm/qemu, virtmanager o virtualbox), then press ESCAPE (or "TAB" in the case of Ubuntu 16.04lts), then input the installation options as mentioned on the template.

From there, just go for a coffee and enjoy the show !.


## Template usage - Cloud-init templates:

The "cloud-init" based templates (the one's with "openstack-seed-cloud" as part of their filename) are a special case. Those are used specifically for openstack-glance images generation (not bare-metal server).

Normally, what we want to do is create a "qcow" file that later we'll include on OpenStack. So.. how do we use those templates ?. Easy:

First, using qemu-img, create a image file. Example:

```bash
qemu-img create -f qcow2 centos-6-32-cloud.qcow2 30G
```

That last command created the file "centos-6-32-cloud.qcow2" image, representing a "virtual hard disk" with 30 Gigabytes max space.

Then, using qemu/kvm, create a virtual machine that will use this image as main hard disk. This command assumes you have the NetInstall ISO at hand in the same directory where your "qcow" file is located (CentOS-6.7-i386-netinstall.iso):

```bash
kvm \
-m 2048 \
-cdrom CentOS-6.7-i386-netinstall.iso \
-drive file=centos-6-32-cloud.qcow2,if=virtio \
-net nic,model=virtio \
-net user \
-nographic \
-vnc :9 \
-k es \
-usbdevice tablet \
-smp cpus=2 \
-balloon virtio
```

Stop here in order to understand some of the options we passed to the kvm command:

- -m 2048: This is the virtualized ram. Use a high value here. Remember the template will not create a swap !.
- -cdrom CentOS-6.7-i386-netinstall.iso: We are assigning the NetInstall ISO file to the virtualized cdrom. That's our installation boot CD !.
- -net options using user and virtio: OpenStack requires the "virtio" driver infrastructure for networking. Also, the "user" option will grant "nat" based networking to the virtual machine.
- -drive file=centos-6-32-cloud.qcow2,if=virtio: Our actual main hard drive (virtualized), mapped used "virtio" to the qcow2 file previouslly created by use using "qemu-img create".
- -ballon virtio: Again, OpenStack uses virtio for everything... including the memory management trough the ballon driver.
- -nographic and -vnc :9: We are starting our VM "headless" with access trough VNC in local VNC display 9. If your "real" machine where you are starting the KVM command is, by example, IP: 192.168.20.45, you'll need to use a VNC client to 192.168.20.45:9 to connect to the actual KVM-based virtual machine.
- -smp cpus=2: KVM will virtualiza 2 vcpu's.

After you start your KVM based VM, connect to it using VNC (any windows-or-linux vnc client will do), to the real-machine IP and display 9 (unless you changed -vnc :X to another display).

Then once you're inside your KVM-Based Virtual Machine, just use the template with the instructions at the beggining of the kickstart/preseed file (press ESC or TAB depending on the case, and input the options needed for the automated installation).

The cloud-init-openstack based template will do all it's stuff, and then "poweroff" the machine, so, when finish the "kvm" command you just used will exit normally.

The resulting qcow2 file is basically your server image. The next step is, compress the server image. You can doit using the following command:

```bash
qemu-img convert -c -O qcow2 -p centos-6-32-cloud.qcow2 centos-6-32-cloud-compressed.qcow2
```

Finally, include your qcow2 "compressed" image to OpenStack glance (asumming newer openstack versions and using openstack cli instead of glance cli):

```bash
openstack image create "Centos-6-32-Cloud" \
	--disk-format qcow2 \
	--public \
	--container-format bare \
	--project YOUR_OPENSTACK_PROJECT \
	--protected \
	--file centos-6-32-cloud-compressed.qcow2
```

The OpenStack cloud images contain specific options for a cloud-init based cloud (specially OpenStack):

- The partitions are "/boot" and "/" so it's easier to resize "/" with different filesystem sizes configured at cloud-level (flavor disks).
- There is no swap partition. Normally, the recommendation is to let OpenStack provide a dedicated swap disk.
- Cloud-init packages are installed and configured in order to get ssh-key and other things from the metadata server.
- The console output (from boot) is redirected to tty in order to let OpenStack (and similar cloud solutions) to send the output to instance logs.
- Auto-Swap and auto-resize options are configured in the template.


## Installation sources.

All templates uses mirrors from the distribution. That ensures the installed server will be up-to-date with all O/S updates at creation time. The apt/yum also keeps those mirrors so you can ensure your server will be always updated (as long as you remember to do proper maintenance of course !).

You can, using those templates as base, create your own internal infrastructure with no internet-dependency, just by creating a local copy of my "unattended" structure, create a local mirror for your desired distros, and modifying the url's inside the templates in order to use your local mirror and local copies of the unattended support files.

Please note the following for each O/S if you want to have your own mirror infrastructure:

- Centos (6 and 7, not cloud): I'm using EPEL as an extra repository. As a matter of facts, it is my very personal opinion that a redhat-based machine without EPEL repo is not complete !. That's just my personal opinion. Use your best judgement if you want to create your own templates based from mine's. Please note that for OpenStack-based templates, EPEL is mandatory !.
- Centos (6 and 7, cloud): EPEL is mandatory. period !.
- Debian (7 and 8, not cloud): Only standard Debian repos needed.
- Debian 7, CLOUD: wheezy-backports is needed for cloud-init. No wheezy-backports, no cloud-init packages !.

Finally, if you want to create your own cloud-init-based-to-be-used-with-openstack templates, remember: DO NOT use lvm if you intend to use the auto-resize options in your openstack instances. Also, try to stick with EXT4 in "at least" "/boot" and "/" partitions. You can use other filesystems in your secondary disks, but, for the primary-root-disk, use ext4 !.


## Software-RAID Templates.

Along the templates for LVM, you'll find some software-raid-lvm templates too. Those are hard-coded with sda/sdb, so, if your device mapping is different, clone the repo and make your own adjustments.


End.-
