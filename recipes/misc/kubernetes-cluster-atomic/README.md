# [CLUSTERING DOCKER CONTAINERS WITH KUBERNETES ON ATOMIC (CENTOS 7)](http://tigerlinux.github.io)

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Introduction:

This article will explore how to build and operate a Kubernetes cluster using as a base operating system Atomic Centos 7. We'll go trough all stages on the cluster construction and configuration, up to how to aunch and manage dockerized services inside the cluster.


## Base environment:

Five virtual machines (OpenStack based), IP's: 192.168.150.12, 192.168.150.20, 192.168.150.22, 192.168.150.24 and 192.168.150.26

OS: Centos Atomic 7.

The IP's .12 and .20 will be our cluster masters, and the IP's .22, .24 and .26 our worker nodes.

Our hostnames:
server-12.virtualstack2.gatuvelus.home (192.168.150.12)
server-20.virtualstack2.gatuvelus.home (192.168.150.20)
server-22.virtualstack2.gatuvelus.home (192.168.150.22)
server-24.virtualstack2.gatuvelus.home (192.168.150.24)
server-26.virtualstack2.gatuvelus.home (192.168.150.26)


## Initial OS Setup:

Our first task is to ensure our atomic hosts are fully updated. In all hosts, (inside the root account) run the following command:

NOTE: From now, all actions will be performed from the root account ("sudo su -" from the centos account on the machines in order to become root):

```bash
sudo su -
atomic host upgrade --reboot
```

After all servers come back online, we can check our versions with the "atomic host status" command:

```bash
atomic host status
State: idle
Deployments:
* centos-atomic-host:centos-atomic-host/7/x86_64/standard
             Version: 7.1705.1 (2017-06-20 18:46:11)
              Commit: 550d13d3e1fda491afab6d368adc13e307512ea51734055d83f0cc4d9049e91d
        GPGSignature: 1 signature
                      Signature made Tue 20 Jun 2017 02:47:45 PM -04 using RSA key ID F17E745691BA8335
                      Good signature from "CentOS Atomic SIG <security@centos.org>"

  centos-atomic-host:centos-atomic-host/7/x86_64/standard
             Version: 7.20170405 (2017-04-10 20:31:05)
              Commit: 91fe03fef75652f68a9974261b391faaeb5bd20f33abf09bb1d45511ba2df04e
        GPGSignature: 1 signature
                      Signature made Mon 10 Apr 2017 05:19:14 PM -04 using RSA key ID F17E745691BA8335
                      Good signature from "CentOS Atomic SIG <security@centos.org>"

```


## ETCD Cluster boot and flannel config:

The next task, and one of the most important ones, is the creation of our "service discovery" layer. In "real world" production environments, it is recommended to have our discovery layer in their own servers, but because this is a small cluster, we'll deploy our clustered discovery services in the same servers where our kubernetes master will run.

In the server "server-12.virtualstack2.gatuvelus.home (192.168.150.12)", run the following commands:

```bash
mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.original

cat <<EOF >/etc/etcd/etcd.conf
# [member]
ETCD_NAME=server-12
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.150.12:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.150.12:2380"
ETCD_INITIAL_CLUSTER="etcd-kube-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="cluster-cluster-cluster-01"
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_INITIAL_CLUSTER="server-12=http://192.168.150.12:2380,server-20=http://192.168.150.20:2380"
EOF

mkdir /etc/systemd/system/etcd.service.d

cat <<EOF >/etc/systemd/system/etcd.service.d/restart.conf
[Service]
Restart=on-failure
RestartSec=1
EOF

mv /etc/sysconfig/flanneld /etc/sysconfig/flanneld.original
cat <<EOF >/etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.150.12:2379,http://192.168.150.20:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

In the server "server-20.virtualstack2.gatuvelus.home (192.168.150.20)", run the following commands:

```bash
mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.original

cat <<EOF >/etc/etcd/etcd.conf
# [member]
ETCD_NAME=server-20
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.150.20:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.150.20:2380"
ETCD_INITIAL_CLUSTER="etcd-kube-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="cluster-cluster-cluster-01"
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_INITIAL_CLUSTER="server-20=http://192.168.150.20:2380,server-12=http://192.168.150.12:2380"
EOF

mkdir /etc/systemd/system/etcd.service.d

cat <<EOF >/etc/systemd/system/etcd.service.d/restart.conf
[Service]
Restart=on-failure
RestartSec=1
EOF

mv /etc/sysconfig/flanneld /etc/sysconfig/flanneld.original
cat <<EOF >/etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.150.20:2379,http://192.168.150.12:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

We can check the etcd cluster with the command "etcdctl cluster-health" on any of the master servers (192.168.150.12 and .20):

```bash
[root@server-12 etcd]# etcdctl cluster-health
member 864b9bc59be4ce4 is healthy: got healthy result from http://192.168.150.20:2379
member 20f3105769754bbd is healthy: got healthy result from http://192.168.150.12:2379
cluster is healthy
```

In the "server-12" machine (192.168.150.12) run the following commands:

```bash
cat <<EOF >/root/flanneld-conf.json
{
  "Network": "172.16.0.0/12",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan"
  }
}
EOF

curl -L http://localhost:2379/v2/keys/atomic.io/network/config -XPUT --data-urlencode value@/root/flanneld-conf.json
```

The last command will create the flannel configuration items on our service discovery cluster.

Now, check that the flannel config has been sent to both members of the cluster with the commands:

```bash
curl -L http://192.168.150.12:2379/v2/keys/atomic.io/network/config | python -m json.tool

curl -L http://192.168.150.20:2379/v2/keys/atomic.io/network/config | python -m json.tool
```

You should get the following output:

```bash
{
    "action": "get",
    "node": {
        "createdIndex": 7,
        "key": "/atomic.io/network/config",
        "modifiedIndex": 7,
        "value": "{\n  \"Network\": \"172.16.0.0/12\",\n  \"SubnetLen\": 24,\n  \"Backend\": {\n    \"Type\": \"vxlan\"\n  }\n}\n"
    }
}
```

Now, in both master servers (192.168.150.12 and .20) enable and start flanneld service:

```bash
systemctl enable flanneld
systemctl start flanneld
```


## Local registry setup.

In order to cache all our images localy, we'll proceed to create a local registry on each master. Run the following commands in both servers (192.168.150.12 and .20):

```bash
systemctl enable docker
systemctl start docker
docker pull registry:2

mkdir -p /var/lib/local-registry
chcon -Rvt svirt_sandbox_file_t /var/lib/local-registry

docker create -p 5000:5000 \
-v /var/lib/local-registry:/var/lib/registry \
-e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
--name=local-registry registry:2

cat <<EOF >/etc/systemd/system/local-registry.service
[Unit]
Description=Local Docker Mirror registry cache
Requires=docker.service
After=docker.service

[Service]
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/docker start -a %p
ExecStop=-/usr/bin/docker stop -t 2 %p

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable local-registry
systemctl start local-registry

```

Eventually, we'll configure docker in our worker nodes to let it use the local registry on the masters.


## Generate Certificates:

In the first master, let's generate our certificates by running the following commands:

```bash
MASTER01IP=192.168.150.12
MASTER02IP=192.168.150.20

cd /root
curl -L -O https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz
tar xzf easy-rsa.tar.gz
cd /root/easy-rsa-master/easyrsa3/
./easyrsa init-pki
./easyrsa --batch "--req-cn=${MASTER01IP}@`date +%s`" build-ca nopass
./easyrsa --subject-alt-name="IP:${MASTER01IP}" --subject-alt-name="IP:${MASTER02IP}" build-server-full server nopass
mkdir /etc/kubernetes/certs
for i in {pki/ca.crt,pki/issued/server.crt,pki/private/server.key}; do cp $i /etc/kubernetes/certs; done
chown -R kube:kube /etc/kubernetes/certs
```

The certificates on "/etc/kubernetes/certs" need to be copied to the other master. We'll use a temporary "http" container for this task.

Run the following commands on the first master (192.168.150.12) in order to allow copying the certificates to the other master:

```bash
docker pull httpd:2.4-alpine

docker run --name apache-temp \
-v /etc/kubernetes/certs:/usr/local/apache2/htdocs \
-p 80:80 \
-d httpd:2.4-alpine
chmod 666 /etc/kubernetes/certs/*
```

On the second master (192.168.150.20), run the following commands

```bash
mkdir /etc/kubernetes/certs
cd /etc/kubernetes/certs/
curl -L -O http://192.168.150.12/ca.crt
curl -L -O http://192.168.150.12/server.crt
curl -L -O http://192.168.150.12/server.key
chown -R kube:kube /etc/kubernetes/certs
chmod 600 /etc/kubernetes/certs/*

```

Back on the first master (192.168.150.12), run the following command:

```bash
chmod 600 /etc/kubernetes/certs/*
docker rm -f apache-temp

```


### Kubernetes API, Controller Manager and Scheduler Services setup:

On both master servers, run the following commands:

```bash
docker pull registry.centos.org/centos/kubernetes-apiserver
docker pull registry.centos.org/centos/kubernetes-controller-manager
docker pull registry.centos.org/centos/kubernetes-scheduler

cat <<EOF >/etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull registry.centos.org/centos/kubernetes-apiserver
ExecStart=/usr/bin/docker run --rm -p 443:443 -p 8080:8080 -v /etc/kubernetes:/etc/kubernetes:z --name %n registry.centos.org/centos/kubernetes-apiserver

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull registry.centos.org/centos/kubernetes-controller-manager
ExecStart=/usr/bin/docker run --rm -p 10252:10252 -v /etc/kubernetes:/etc/kubernetes:z --name %n registry.centos.org/centos/kubernetes-controller-manager

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler Plugin
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull registry.centos.org/centos/kubernetes-scheduler
ExecStart=/usr/bin/docker run --rm -p 10251:10251 -v /etc/kubernetes:/etc/kubernetes:z --name %n registry.centos.org/centos/kubernetes-scheduler

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
```

The last commands will create the "systemd" service definitions for the main kubernetes services: apiserver, controller manager and the scheduller.

Next, we need to configure the services on both masters. Again, run the following commands on the masters. 

First, in the master #1 "192.168.150.12":

```bash
cp /etc/kubernetes/config /etc/kubernetes/config.original
cp /etc/kubernetes/kubelet /etc/kubernetes/kubelet.original
cp /etc/kubernetes/proxy /etc/kubernetes/proxy.original

cat <<EOF >/etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBE_ETCD_SERVERS="--etcd_servers=http://192.168.150.12:2379,http://192.168.150.20:2379"
KUBE_MASTER="--master=http://192.168.150.12:8080"
EOF

cat <<EOF >/etc/kubernetes/apiserver
KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0 --bind-address=0.0.0.0"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_API_ARGS="--tls-cert-file=/etc/kubernetes/certs/server.crt --tls-private-key-file=/etc/kubernetes/certs/server.key --client-ca-file=/etc/kubernetes/certs/ca.crt --service-account-key-file=/etc/kubernetes/certs/server.crt --secure-port=443 --admission_control=AlwaysAdmit"
EOF
```

Second, the master #2 "192.168.150.20":

```bash
cp /etc/kubernetes/config /etc/kubernetes/config.original
cp /etc/kubernetes/kubelet /etc/kubernetes/kubelet.original
cp /etc/kubernetes/proxy /etc/kubernetes/proxy.original

cat <<EOF >/etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBE_ETCD_SERVERS="--etcd_servers=http://192.168.150.20:2379,http://192.168.150.12:2379"
KUBE_MASTER="--master=http://192.168.150.20:8080"
EOF

cat <<EOF >/etc/kubernetes/apiserver
KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0 --bind-address=0.0.0.0"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_API_ARGS="--tls-cert-file=/etc/kubernetes/certs/server.crt --tls-private-key-file=/etc/kubernetes/certs/server.key --client-ca-file=/etc/kubernetes/certs/ca.crt --service-account-key-file=/etc/kubernetes/certs/server.crt --secure-port=443 --admission_control=AlwaysAdmit"
EOF
```

Now, run the following commands on BOTH masters (192.168.150.12 and .20):

```bash
cat <<EOF >/etc/kubernetes/controller-manager
KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/etc/kubernetes/certs/server.key --root-ca-file=/etc/kubernetes/certs/ca.crt --cluster-signing-cert-file=/etc/kubernetes/certs/ca.crt --cluster-signing-key-file=/etc/kubernetes/certs/server.key --leader-elect=true --address=0.0.0.0"
EOF

cat <<EOF >/etc/kubernetes/scheduler
KUBE_SCHEDULER_ARGS="--leader-elect=true --address=0.0.0.0"
EOF

```

And finally, let's start the services on both masters (192.168.150.12 and .20):

```bash
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

The last command will start your cluster with both masters. We are ready for either include a load balancer and configure our worker nodes.


## Load balancing the masters.

Our two masters are exposing 3 ports: 5000 (for the local registry cache), and 8080/443 for the API. If you want to truly load balance your masters, you should put all your masters behind a VIP.

For the rest of this article, and because we are running inside an OpenStack based cloud with "LBaaS" included, we'll create a load balancer which will "load-balance" ports 5000, 443 and 8080. The VIP assigned for us by OpenStack was: 192.168.150.23, and it's serving ports 5000, 8080 and 443.

**NOTE: Our OpenStack cloud is "Ocata-based", with LBaaS V2 that allows having multiples listener ports on the same VIP.**

If for some reason you are replicating this article on an environment without a load balancer, just use one of the master's IP on the following sections of this article.


## Adding our worker nodes part 1: Initial setup. Registry cache and Flannel:

With our masters running, and properly load-balanced, the next part is to add our 3 nodes (192.168.150.22, 24 and 26) to the cluster.

We need to tell the docker service on our nodes to use the local registry on the masters. Run the following commands to do so on all your worker nodes (192.168.150.22, 24 and 26):

```bash
cp /etc/sysconfig/docker /etc/sysconfig/docker.ORIGINAL

cat <<EOF >/etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --registry-mirror=http://192.168.150.23:5000'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
EOF

systemctl restart docker

```

**NOTE: If you don't have a load-balanced master VIP, then use any of the masters IP instead of 192.168.150.23.**

And flannel need to be configured too on all 3 worker nodes:

```bash
mv /etc/sysconfig/flanneld /etc/sysconfig/flanneld.original
cat <<EOF >/etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.150.12:2379,http://192.168.150.20:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
EOF

systemctl enable flanneld
systemctl start flanneld

```


## Adding our worker nodes part 2: Node kubernetes services (Kubelet and Kube-proxy):

With flannel and docker configured on our worker nodes, let's configure kubernetes services. First, in all our worker nodes, let's download the pod infraestructure image:

```bash
docker pull registry.access.redhat.com/rhel7/pod-infrastructure:latest
```

**NOTE: If you don't have a load-balanced master VIP, then use any of the masters IP instead of 192.168.150.23 in the following lines.**

Now, we need to configure the kubelet service on each node.

Worker node 192.168.150.22:

```bash
cp /etc/kubernetes/kubelet /etc/kubernetes/kubelet.original

cat <<EOF >/etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=192.168.150.22"
KUBELET_HOSTNAME="--hostname-override=192.168.150.22"
KUBELET_API_SERVER="--api-servers=http://192.168.150.23:8080"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
KUBELET_ARGS=""
EOF

``` 

Worker node 192.168.150.24:

```bash
cp /etc/kubernetes/kubelet /etc/kubernetes/kubelet.original

cat <<EOF >/etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=192.168.150.24"
KUBELET_HOSTNAME="--hostname-override=192.168.150.24"
KUBELET_API_SERVER="--api-servers=http://192.168.150.23:8080"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
KUBELET_ARGS=""
EOF

``` 

Worker node 192.168.150.26:

```bash
cp /etc/kubernetes/kubelet /etc/kubernetes/kubelet.original

cat <<EOF >/etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=192.168.150.26"
KUBELET_HOSTNAME="--hostname-override=192.168.150.26"
KUBELET_API_SERVER="--api-servers=http://192.168.150.23:8080"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
KUBELET_ARGS=""
EOF

``` 

Run the following commands on all 3 nodes in order to finish our nodes configuration:

```bash
cp /etc/kubernetes/config /etc/kubernetes/config.original

cat <<EOF >/etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBE_ETCD_SERVERS="--etcd_servers=http://192.168.150.20:2379,http://192.168.150.12:2379"
KUBE_MASTER="--master=http://192.168.150.23:8080"
EOF

systemctl enable kubelet kube-proxy
systemctl start kubelet kube-proxy

```

Wait a few seconds (maybe a minute) in order to let the services to fully start and register to the masters, then go to any of your masters and use the "kubectl get node" command to check the status of your cluster:

```bash
 kubectl get node
NAME             STATUS    AGE
192.168.150.22   Ready     2m
192.168.150.24   Ready     1m
192.168.150.26   Ready     1m
```

At this stage, your kubernetes cluster is up and running, and ready to deploy services.


## Deploying a simple docker container with a yaml file.

Lets begin to play with our cluster. The first thing we are going to do is create a single containerized apache in a single pod.

In any of our masters, run the following commands:

```bash

cat <<EOF >/root/apache-single-01.yaml
apiVersion: v1
kind: Pod
metadata:
  name: apache-single-01
spec:
  containers:
    - name: apache-single-01
      image: httpd:2.4-alpine
      ports:
        - containerPort: 80
          hostPort: 80
EOF

kubectl create -f /root/apache-single-01.yaml

```

The last command (kubectl create) will return the message: **"pod "apache-single-01" created".**

We can check this "pod" with the following commands in any of our masters:

```bash
 kubectl get pods
NAME               READY     STATUS              RESTARTS   AGE
apache-single-01   0/1       ContainerCreating   0          2m

```

Meanwhile docker is downloading the image and constructing the service, our status will be "ContainerCreating". Eventually our status will change to "Running":

```bash
kubectl get pods
NAME               READY     STATUS    RESTARTS   AGE
apache-single-01   1/1       Running   0          4m
```

We can obtain more data about our "pod" with the command "kubectl describe pods PODNAME":

```bash
kubectl describe pods apache-single-01

Name:           apache-single-01
Namespace:      default
Node:           192.168.150.26/192.168.150.26
Start Time:     Sat, 01 Jul 2017 18:30:54 -0400
Labels:         <none>
Status:         Running
IP:             172.17.0.2
Controllers:    <none>
Containers:
  apache-single-01:
    Container ID:               docker://16c8d7136a179875515e60d9b4a29b1e8b1d18e64bcf1b49c5f0fafd9e308472
    Image:                      httpd:2.4-alpine
    Image ID:                   docker-pullable://docker.io/httpd@sha256:ede229b2b6e290b4ce4af3efcff7402bb249818ac6f38728cb381ed2d4cd6993
    Port:                       80/TCP
    State:                      Running
      Started:                  Sat, 01 Jul 2017 18:34:58 -0400
    Ready:                      True
    Restart Count:              0
    Volume Mounts:              <none>
    Environment Variables:      <none>
Conditions:
  Type          Status
  Initialized   True
  Ready         True
  PodScheduled  True
No volumes.
QoS Class:      BestEffort
Tolerations:    <none>
Events:
  FirstSeen     LastSeen        Count   From                            SubObjectPath                           Type            Reason                  Message
  ---------     --------        -----   ----                            -------------                           --------        ------                  -------
  7m            7m              1       {default-scheduler }                                                    Normal          Scheduled               Successfully assigned apache-single-01 to 192.168.150.26
  6m            6m              1       {kubelet 192.168.150.26}        spec.containers{apache-single-01}       Normal          Pulling                 pulling image "httpd:2.4-alpine"
  3m            3m              1       {kubelet 192.168.150.26}        spec.containers{apache-single-01}       Normal          Pulled                  Successfully pulled image "httpd:2.4-alpine"
  7m            3m              2       {kubelet 192.168.150.26}                                                Warning         MissingClusterDNS       kubelet does not have ClusterDNS IP configured and cannot create Pod using "ClusterFirst" policy. Falling back to DNSDefault policy.
  3m            3m              1       {kubelet 192.168.150.26}        spec.containers{apache-single-01}       Normal          Created                 Created container with docker id 16c8d7136a17; Security:[seccomp=unconfined]
  3m            3m              1       {kubelet 192.168.150.26}        spec.containers{apache-single-01}       Normal          Started                 Started container with docker id 16c8d7136a17

```
  
If we need to see just in what node is being run our container, use "kubectl describe pods PODNAME|grep "Node:":
  
```bash
kubectl describe pods apache-single-01|grep "Node:"
Node:           192.168.150.26/192.168.150.26
```

Then, our little apache is running on our third node (192.168.150.26). Let's check apache default web page:

```bash
curl http://192.168.150.26

<html><body><h1>It works!</h1></body></html>
```

You can deploy resources in many ways. The most accepted way on production systems is trough "yaml" files.


## Deploying a simple replicated container.

Now let's do create a simple apache, with 3 replicas and exposing another port different than 80. This time we'll not use a "yaml". Instead, we'll directly use the "kubectl run" command:

```bash
kubectl run apache-simple-replicated \
--image=httpd:2.4-alpine \
--replicas=3 \
--port=80 \
--hostport=8081
``` 

The command will return "deployment "apache-simple-replicated" created".

Again, we can check our pods (and deployment) with kubectl:

```bash
kubectl get pods
NAME                                        READY     STATUS              RESTARTS   AGE
apache-simple-replicated-2271137449-9j0jn   1/1       Running             0          1m
apache-simple-replicated-2271137449-bp038   1/1       Running             0          1m
apache-simple-replicated-2271137449-kjvv0   1/1       Running             0          1m
apache-single-01                            1/1       Running             0          35m

kubectl get deployments
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
apache-simple-replicated   3         3         3            3           2m

```

Using the "-o wide" option on "kubectl get pods", we can see more information about our pods:

```bash
kubectl get pods -o wide
NAME                                        READY     STATUS    RESTARTS   AGE       IP           NODE
apache-simple-replicated-2271137449-9j0jn   1/1       Running   0          15m       172.17.0.2   192.168.150.24
apache-simple-replicated-2271137449-bp038   1/1       Running   0          15m       172.17.0.2   192.168.150.22
apache-simple-replicated-2271137449-kjvv0   1/1       Running   0          15m       172.17.0.3   192.168.150.26
apache-single-01                            1/1       Running   0          50m       172.17.0.2   192.168.150.26
```

We can change the replica factor of our deployment. Let's change (scale-down) our "apache-simple-replicated" to 2 replicas:

```bash
kubectl scale --current-replicas=3 --replicas=2 deployment/apache-simple-replicated
```

The las command will return "deployment "apache-simple-replicated" scaled". Let's see our deployments and pods now:

```bash
kubectl get deployments
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
apache-simple-replicated   2         2         2            2           23m

kubectl get pods -o wide
NAME                                        READY     STATUS        RESTARTS   AGE       IP           NODE
apache-simple-replicated-2271137449-9j0jn   1/1       Terminating   0          24m       172.17.0.2   192.168.150.24
apache-simple-replicated-2271137449-bp038   1/1       Running       0          24m       172.17.0.2   192.168.150.22
apache-simple-replicated-2271137449-kjvv0   1/1       Running       0          24m       172.17.0.3   192.168.150.26
apache-single-01                            1/1       Running       0          58m       172.17.0.2   192.168.150.26
```

The status of one of our pods is "Terminating". Eventually we'll just have:

```bash
kubectl get pods -o wide
NAME                                        READY     STATUS    RESTARTS   AGE       IP           NODE
apache-simple-replicated-2271137449-bp038   1/1       Running   0          26m       172.17.0.2   192.168.150.22
apache-simple-replicated-2271137449-kjvv0   1/1       Running   0          26m       172.17.0.3   192.168.150.26
apache-single-01                            1/1       Running   0          1h        172.17.0.2   192.168.150.26
```

Now, let's kill our deployments and pods with "kubectl delete":

```bash
kubectl delete deployments apache-simple-replicated
kubectl delete pods apache-single-01

```


## Adding shared storage with NFS.

In the next example, we'll create a replicated service using persistent storage from a NFS Server, and let our pods to use the shared storage to mount a default web page on apache.

Our NFS Shared storage address/path is: 192.168.1.1:/data/kub-nfs/apache. Inside the "/data/kub-nfs/apache" directory we have a "index.html" file with the text "HELLO KUBEWORLD".

First, let's create our NFS volume definition. Remember to run all the following commands inside any of the master servers (note you can specify mount options for NFS):

```bash
cat <<EOF >/root/nfs-volume-01.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol01
  annotations:
    volume.beta.kubernetes.io/mount-options: "rw,hard,intr,timeo=90,bg,vers=3,proto=tcp,rsize=32768,wsize=32768"
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.1.1
    path: "/data/kube-nfs/apache"
EOF

kubectl create -f /root/nfs-volume-01.yaml

```
The command returns: "persistentvolume "nfsvol01" created".

Second, we need to create a "Persistent Volume Claim" definition:

```bash
cat <<EOF >/root/nfs-volumeclain-01.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfsvol01
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF

kubectl create -f /root/nfs-volumeclain-01.yaml

```

The command returns: "persistentvolumeclaim "nfsvol01" created".

Third, we proceed to create our replication controller indicating 2 replicas for our service. We'll have two pods running apache, both using the same NFS storage:

```bash
cat <<EOF >/root/webserver-nfs-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: web-nfs-01
spec:
  replicas: 2
  selector:
    role: webserver
  template:
    metadata:
      labels:
        role: webserver
    spec:
      containers:
      - name: apacheserver
        image: httpd:2.4-alpine
        ports:
          - containerPort: 80
        volumeMounts:
            - name: nfsvol01
              mountPath: "/usr/local/apache2/htdocs"
      volumes:
      - name: nfsvol01
        persistentVolumeClaim:
          claimName: nfsvol01
EOF

kubectl create -f /root/webserver-nfs-rc.yaml

```

The command returns: "replicationcontroller "web-nfs-01" created".

Finally, the service definition:

```bash
cat <<EOF >/root/webserver-nfs-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nfs-service-01
spec:
  ports:
    - port: 80
      protocol: TCP
      name: http
  externalIPs:
    - 192.168.150.22
    - 192.168.150.24
    - 192.168.150.26
  selector:
    role: webserver
  type: LoadBalancer
EOF

kubectl create -f /root/webserver-nfs-service.yaml

```

The command returns: "service "web-nfs-service-01" created".

Observe something here. The replication controller clearly specify two replicas, but, we are exposing the http port trough all our worker nodes with the "externalIps" section inside the yaml file.

Let's test the service with curl:

```bash
curl http://192.168.150.22
HELLO KUBEWORLD

curl http://192.168.150.24
HELLO KUBEWORLD

curl http://192.168.150.26
HELLO KUBEWORLD
```

All the pods are servicing the http port, as specified in the "externalIps" section.

Let's see our pods and services:

```bash
get pv -o wide
NAME       CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM              REASON    AGE
nfsvol01   1Gi        RWX           Retain          Bound     default/nfsvol01             37m

kubectl get pvc -o wide
NAME       STATUS    VOLUME     CAPACITY   ACCESSMODES   AGE
nfsvol01   Bound     nfsvol01   1Gi        RWX           36m

kubectl get rc -o wide
NAME         DESIRED   CURRENT   READY     AGE       CONTAINER(S)   IMAGE(S)           SELECTOR
web-nfs-01   2         2         2         22m       apacheserver   httpd:2.4-alpine   role=webserver

kubectl get services -o wide
NAME                 CLUSTER-IP       EXTERNAL-IP                                     PORT(S)        AGE       SELECTOR
kubernetes           10.254.0.1       <none>                                          443/TCP        6h        <none>
web-nfs-service-01   10.254.186.109   ,192.168.150.22,192.168.150.24,192.168.150.26   80:32060/TCP   11m       role=webserver

kubectl get pods -o wide
NAME               READY     STATUS    RESTARTS   AGE       IP            NODE
web-nfs-01-0l1d0   1/1       Running   0          22m       172.16.62.2   192.168.150.22
web-nfs-01-ljpnn   1/1       Running   0          22m       172.16.64.2   192.168.150.24

```

Finally, you can delete all our created resources with the same files that created them:

```bash
kubectl delete -f /root/webserver-nfs-service.yaml
service "web-nfs-service-01" deleted

kubectl delete -f /root/webserver-nfs-rc.yaml
replicationcontroller "web-nfs-01" deleted

kubectl delete -f /root/nfs-volumeclain-01.yaml
persistentvolumeclaim "nfsvol01" deleted

kubectl delete -f /root/nfs-volume-01.yaml
persistentvolume "nfsvol01" deleted

```

You can see more examples at the following site:

- [https://github.com/kubernetes/kubernetes/tree/master/examples](https://github.com/kubernetes/kubernetes/tree/master/examples)


## Operational recommendations.

If you consider the usage of "kubernetes" on real-world production conditions, then follow the recommendations below:

- Set your discovery layer on separate servers from your masters. Start with a minimun of 3 servers.
- Always install the control plane (the masters) in a clustered setup, and load-balance your services.
- Include a local registry in your setup. If you expect to have a lot of load over the registry, consider installing this layer on its own servers (load-balanced too).
- Use external storage for applications that need to share storage. If you are running in a cloud environment, use the block storage available in the cloud.
- Separate your networks. Set the control plane connectivity (etcd cluster, kube masters and kubelets) on a network separated from your service network (where the services will expose ports).
- If possible, use load-balancers for replicated services exposing the same port across different worker nodes.
- Use CI's for your deployments. Your kubernete-based services are based on yaml files that can be easily included on any versioning system (git) and eventually integrated with "jenkins" or any other CI solution.

END.-
