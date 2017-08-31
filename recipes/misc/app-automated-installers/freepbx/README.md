# FREEPBX AUTOMATED INSTALLER FOR CENTOS 7

This script (that can be used either manually on a baremetal machine or as user-data/bootstrap in a cloud-init based server) will automate the installation and basic setup for FreePBX. Note that firewalld will have opened only the ports 22 and 80. If you want to open additional ports, you can do it using firewalld commands (or freepbx gui).

After the installation is completed, you can enter to your server using any browser and set your admin account: http://SERVER_NAME_OR_IP. Please, after setting your admin account, reboot the server in order to let all modules (specifically the ones for the conference bridge) to properly load.

Most of the tasks performed by the script are logged to the file "/var/log/freepbx-automated-installer.log". If you are deploying freepbx with this script inside a cloud-init environment (a cloud server, a digital ocean droplet or a packet.net baremetal server) you can also check the log file "/var/log/cloud-init-output.log".

This script will run only on Centos 7 machines !

# GENERAL REQUIREMENTS:

This script will fail if the following requirements are not meet:

- Operating System: Centos 7.
- Architecture: x86_64/amd64.
- INSTALLED RAM: 1024Mb (1GB).
- CPU: 1 Core/Thread.
- FREE DISK SPACE: 15GB.
