#!/bin/bash
#
# Reynaldo R. Martinez P.
# tigerlinux@gmail.com
# http://tigerlinux.github.io
# https://github.com/tigerlinux
# Minio-S3 installation script
# For Centos 7 and Ubuntu 16.04lts, 64 bits.
# Release 1.1
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

lgfile="/var/log/minio-s3-docker-install.log"
echo "Start Date/Time: `date`" &>>$lgfile
export OSFlavor='unknown'
export nginxport='8080'

if [ $nginxport == "9000" ]
then
	nginxport='8080'
fi

if [ -f /etc/centos-release ]
then
	OSFlavor='centos-based'
	yum clean all
	yum -y install coreutils grep curl wget redhat-lsb-core net-tools git findutils iproute grep openssh sed gawk openssl which xz bzip2 util-linux procps-ng which lvm2 sudo hostname
	setenforce 0
	sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
	yum -y erase firewalld
fi

if [ -f /etc/debian_version ]
then
	OSFlavor='debian-based'
	apt-get -y clean
	apt-get -y update
	cat<<EOF >/etc/apt/apt.conf.d/99aptget-reallyunattended
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF

	export DEBIAN_FRONTEND=noninteractive
	apt-get \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		-y install \
		coreutils grep debianutils base-files lsb-release curl wget net-tools git \
		iproute openssh-client sed openssl xz-utils bzip2 util-linux procps mount \
		lvm2 hostname sudo
fi

kr64inst=`uname -p 2>/dev/null|grep x86_64|head -n1|wc -l`

if [ $kr64inst != "1" ]
then
	echo "Not a 64 bits machine. Aborting !" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

# Note: Minio access key need to be from 5 to 20 chars. hex 10 give us 20 chars
export minioaccesskey=`openssl rand -hex 10`
# Note: Minio secret need to be from 10 to 40 chars. hex 20 give us 40 chars
export miniosecret=`openssl rand -hex 20`

cpus=`lscpu -a --extended|grep -ic yes`
instram=`free -m -t|grep -i mem:|awk '{print $2}'`
avusr=`df -k --output=avail /usr|tail -n 1`
avvar=`df -k --output=avail /var|tail -n 1`

if [ $cpus -lt "1" ] || [ $instram -lt "900" ] || [ $avusr -lt "5000000" ] || [ $avvar -lt "5000000" ]
then
	echo "Not enough hardware for Minio-S3. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

if [ `grep -c swapfile /etc/fstab` == "0" ]
then
	myswap=`free -m -t|grep -i swap:|awk '{print $2}'`
	if [ $myswap -lt 2000 ]
	then
		fallocate -l 2G /swapfile
		chmod 600 /swapfile
		mkswap /swapfile
		swapon /swapfile
		echo '/swapfile none swap sw 0 0' >> /etc/fstab
	fi
fi

case $OSFlavor in
centos-based)
	amicen=`lsb_release -i|grep -ic centos`
	crel7=`lsb_release -r|awk '{print $2}'|grep ^7.|wc -l`
	if [ $amicen != "1" ] || [ $crel7 != "1" ]
	then
		echo "This is NOT a Centos 7 machine. Aborting !"
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi

	# Kill packet.net repositories if detected here.
	yum -y install yum-utils
	repotokill=`yum repolist|grep -i ^packet|cut -d/ -f1`
	for myrepo in $repotokill
	do
		echo "Disabling repo: $myrepo" &>>$lgfile
		yum-config-manager --disable $myrepo &>>$lgfile
	done
	
	yum -y install epel-release
	yum -y install yum-utils device-mapper-persistent-data
	yum-config-manager \
	--add-repo \
	https://download.docker.com/linux/centos/docker-ce.repo

	yum -y update --exclude=kernel*
	yum -y install docker-ce

	systemctl start docker
	systemctl enable docker

	yum -y install nginx

	cat /etc/nginx/nginx.conf >> /etc/nginx/nginx.conf.original

	cat <<EOF >/etc/nginx/nginx.conf
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    client_max_body_size 1000m;
    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
    server {
        listen       $nginxport default_server;
        listen       [::]:$nginxport default_server;

        server_name `hostname`;
        location / {
           proxy_buffering off;
           proxy_set_header Host \$http_host;
           proxy_pass http://127.0.0.1:9000;
        }
    }
}
EOF

	systemctl start nginx
	systemctl enable nginx

	yum -y install jq

	;;
debian-based)
	amiubuntu1604=`cat /etc/lsb-release|grep DISTRIB_DESCRIPTION|grep -i ubuntu.\*16.04.\*LTS|head -n1|wc -l`
	if [ $amiubuntu1604 != "1" ]
	then
		echo "This is NOT an Ubuntu 16.04LTS machine. Aborting !" &>>$lgfile
		echo "End Date/Time: `date`" &>>$lgfile
		exit 0
	fi
	apt-get -y update
	apt-get -y remove docker docker-engine
	apt-get -y install \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"

	apt-get -y update
	apt-get -y install docker-ce
	systemctl enable docker
	systemctl start docker
	systemctl restart docker
	
	apt-get -y install jq
	
	DEBIAN_FRONTEND=noninteractive apt-get -y install nginx-full
	cat /etc/nginx/sites-available/default > /etc/nginx/sites-available/default-original

	cat <<EOF >/etc/nginx/sites-available/default
server {
        listen $nginxport default_server;
        listen [::]:$nginxport default_server;
		root /var/www/html;
		index index.html index.htm index.nginx-debian.html;
		server_name `hostname`;
		location / {
			try_files $uri $uri/ =404;
			proxy_buffering off;
			proxy_set_header Host \$http_host;
			proxy_pass http://127.0.0.1:9000;
		}
}
EOF

	systemctl enable nginx
	systemctl restart nginx

	;;
unknown)
	echo "Unkown/Unsupported operating system. Aborting!" &>>$lgfile
	exit 0
	;;
esac

devicelist=`lsblk -do NAME|grep -v NAME`

nxsto=''
for blkst in $devicelist
do
	if [ `lsblk -do NAME,TYPE|grep -v NAME|grep disk|awk '{print $1}'|grep -v da|grep -c ^$blkst` == "1" ] \
	&& [ `blkid |grep $blkst|grep -ci swap` == 0 ] \
	&& [ `grep -v cloudconfig /etc/fstab |grep -ci ^/dev/$blkst` == 0 ]
	then
		echo "Device $blkst usable" &>>$lgfile
		nxsto=$blkst
	fi
done

mkdir -p /var/minio-storage

if [ -z $nxsto ]
then
	echo "No usable extra storage found" &>>$lgfile
else
	echo "Extra storage found: $nxsto" &>>$lgfile
	cat /etc/fstab > /etc/fstab.ORG
	umount /dev/$nxsto >/dev/null 2>&1
	cat /etc/fstab |egrep -v "($nxsto|minios3sto)" > /etc/fstab.NEW
	cat /etc/fstab.NEW > /etc/fstab
	mkfs.ext4 -F -F -L minios3sto /dev/$nxsto
	echo 'LABEL=minios3sto /var/minio-storage ext4 defaults 0 0' >> /etc/fstab
	mount /var/minio-storage
fi

mkdir -p /var/minio-storage/minioserver01/data
mkdir -p /var/minio-storage/minioserver01/config

docker pull minio/minio

docker run \
--detach -it \
--name minioserver01 \
--restart unless-stopped \
-e "MINIO_ACCESS_KEY=$minioaccesskey" \
-e "MINIO_SECRET_KEY=$miniosecret" \
-p 127.0.0.1:9000:9000 \
-v /var/minio-storage/minioserver01/data:/export \
-v /var/minio-storage/minioserver01/config:/root/.minio \
minio/minio server /export

echo "Waiting 10 seconds for Minio Server to start" &>>$lgfile
sync
sleep 10
sync
if [ ! -f /var/minio-storage/minioserver01/config/config.json ]
then
	echo "Minio-S3 failed to install. Aborting!" &>>$lgfile
	echo "End Date/Time: `date`" &>>$lgfile
	exit 0
fi

wget https://dl.minio.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/miniocli
chmod 755 /usr/local/bin/miniocli

if [ -f /usr/local/bin/miniocli ]
then
	miniocli config host add minioserver01 \
	http://127.0.0.1:9000 \
	`cat /var/minio-storage/minioserver01/config/config.json |jq '.credential.accessKey'|cut -d\" -f2` \
	`cat /var/minio-storage/minioserver01/config/config.json |jq '.credential.secretKey'|cut -d\" -f2` \
	S3v4
else
	echo "Minio client failed to install. Just an alert!" &>>$lgfile
fi

export minioaccess=`cat /var/minio-storage/minioserver01/config/config.json |jq '.credential.accessKey'|cut -d\" -f2`
export miniosecret=`cat /var/minio-storage/minioserver01/config/config.json |jq '.credential.secretKey'|cut -d\" -f2`

echo "Minio credentials:" > /root/minios3-credentials.txt
echo "Access Key: $minioaccess" >> /root/minios3-credentials.txt
echo "Secret: $miniosecret" >> /root/minios3-credentials.txt
echo "URL's:" >> /root/minios3-credentials.txt

allipaddr=`ip -4 -o addr| awk '{gsub(/\/.*/,"",$4); print $4}'`
mycount=1

for myip in $allipaddr
do
	mycount=$[mycount+1]
	echo "- http://$myip:$nginxport" >> /root/minios3-credentials.txt
done

echo "- http://`hostname`:$nginxport" >> /root/minios3-credentials.txt
mycount=$[mycount+1]

publicip=`curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`
publichostname=`curl http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null`

if [ -z $publicip ]
then
	echo "No metadata-based public IP detected" &>>$lgfile
else
	echo "- http://$publicip:$nginxport" >> /root/minios3-credentials.txt
	mycount=$[mycount+1]
fi

if [ -z $publichostname ]
then
	echo "No metadata-based public hostname detected" &>>$lgfile
else
	echo "- http://$publichostname:$nginxport" >> /root/minios3-credentials.txt
	mycount=$[mycount+1]
fi

if [ -f /root/minios3-credentials.txt ]
then
	echo "Your MINIO-S3 credentials are stored on the file /root/minios3-credentials.txt" &>>$lgfile
	cat /root/minios3-credentials.txt &>>$lgfile
else
	echo "Credentials file not found. Installation failed" &>>$lgfile
fi

echo "End Date/Time: `date`" &>>$lgfile

#END
