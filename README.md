# Team 1 - Project 3

Edmond Zalenski, George Karchenko, George Poulos, Jeff Kaleshi, Kevin Liu , Kunal Shah, Tim Choh
* * *

## Versions
| Name          | Version       |
| ------------- |:-------------:|
| Hypriot       | v1.6          |
| Kubernetes    | v1.8.3        |
| Flannel       | v0.9          |
| Hadoop        | v2.8.2        |
* * *

## Individual Raspberry Pi
For this project we utilized the Raspberry Pi 3 (RPi3) which runs on a 64 bit ARM architecture and we paired it with a 32gb microSD storage solution. Additionally, a heat sink was required in order to provide adequate cooling to the Raspberry Pi when under heavy load.  The RPi3 will have power provided from a 12 amp USB hub and wall sockets in order to ensure consistent current and power is provided to the pie. As for networking, the pie will be connected to the internet via an ethernet cable which connects to the router.  Lastly, the RPi3 will have Hypriot OS and Kubernetes installed on the microSD card.
* * *

## Octa-Pie Cluster
The cluster made for this project consists of 8 RPi3’s. Each of which follows the specifications defined above.  We 3D printed two racks where each rack holds four RPi3’s.  The racks are designed in such a way that there are four RPi3’s stacked on top of each other with enough clearance for each RPi3 to not touch the one above or below it.  Each RPi3 has one heat sink on the CPU to enable better airflow to cool down the RPi3’s due to their close positioning on the rack. Their close positioning allows for us to be able to connect all the RPi3’s to a power source, which consists of two USB hubs with eight USB ports at a total of 60W or 12A for each hub.  To connect each RPi3 via ethernet connection, we are utilizing a 10/100 Mbps connection router. We chose not to go with a wireless connection due to the lack of reliability from experiences with Arduinos in previous classes.
* * *

## Deploying Map/Reduce
In order to deploy our Map/Reduce (M/R) program onto the Octa-Pie cluster, there are a couple of steps we had to take involving various services. Firstly, after we had the Octa-Pie Cluster physically set up on the racks and connected via ethernet, we had to load an operating system onto the cluster. For each RPi3 we installed Hypriot OS and on top of Hypriot we installed Kubernetes as a container manager. Additionally, assigned each container an IP address using Flannel. Thus, the assigned Kubernetes master node will thereafter communicate with the other nodes within the cluster in order to successfully run our M/R implementation with other nodes once we upload it. Lastly, Hadoop also had to be installed on our cluster in order for the cluster to successfully run our M/R implementation.

Descriptions of steps taken and commands required are provided below.

### Commands to Init Cluster
[Source for initializing cluster](http://www.ecliptik.com/Raspberry-Pi-Kubernetes-Cluster/)
```sh
# Initialize cluster on master, save the args for the kubeadm join command outputted
$ sudo kubeadm init --pod-network-cidr 10.244.0.0/16 # cidr is for flannel
# Save kubernetes config file
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
$ echo "export KUBECONFIG=${HOME}/.kube/config" >> ~/.bashrc
$ source ~/.bashrc
# Add flannel related resources to cluster
$ curl -sSL https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml | sed "s/amd64/arm64/g" | kubectl create -f -
# On all nodes flannel related traffic will need to be forwarded, it is recommended to use something like netfilter-persistent to save the rules between sessions.
$ sudo iptables -P FORWARD ACCEPT
$ sudo iptables -t nat -A POSTROUTING -s 10.244.0.0/16 ! -d 10.244.0.0/16 -j MASQUERADE
$ sudo iptables -I FORWARD 1 -i cni0 -j ACCEPT -m comment --comment "flannel subnet"
$ sudo iptables -I FORWARD 1 -o cni0 -j ACCEPT -m comment --comment "flannel subnet"
# Now on each of the other nodes run the kubeadm command saved earlier
$ sudo kubeadm join $ARGS
# Check to see them back on master node
$ kubectl get nodes
```

At this point all the nodes should have joined the cluster. The output should look something like this
| Name          | Status        | Roles  |
| ------------- |:-------------:|:------:|
| master        | Ready         | master |
| slave1        | Ready         | <none> |
| slave2        | Ready         | <none> |
| slave3        | Ready         | <none> |
| slave4        | Ready         | <none> |
| slave5        | Ready         | <none> |
| slave6        | Ready         | <none> |
If the nodes aren't all ready yet, don't panic. It takes a few minutes for their pods to come online.
You can check pod status with `kubectl get pods --all-namespaces`

```sh
# Now we'll start the hadoop services on the master
$ git clone
$ cd rpi-hadoop-wip
$ for file in $( ls | grep service ); do kubectl create -f $file; done
$ for file in $( ls | grep controller ); do kubectl create -f $file; done
# Wait until all the pods are up
$ kubectl get pods
```
| Name                            | Ready | Status  |
| ------------------------------- |:-----:|:-------:|
| hadoop-master-controller-XXXXX  | 1/1   | Running |
| hadoop-slave1-controller-XXXXX  | 1/1   | Running |
| hadoop-slave2-controller-XXXXX  | 1/1   | Running |
| hadoop-slave3-controller-XXXXX  | 1/1   | Running |
| hadoop-slave4-controller-XXXXX  | 1/1   | Running |
Now we can run a map reduce job!

### Running a Map Reduce Job
```sh
# Enter the master pod
$ kubectl exec -it $(kubectl get po | grep master | awk '{ print $1 }') -- /bin/bash

# Add slave ips to /etc/hosts
root@hadoop-master:~# for slave in $( cat $HADOOP_HOME/etc/hadoop/slaves ); do echo "$(nslookup $slave | grep -m2 Address | tail -n1 | awk '{ print $2 }') $slave" >> /etc/hosts; done;

# restart sshd and start hadoop
root@hadoop-master:~# service ssh restart
root@hadoop-master:~# ./start-hadoop.sh
# Run map reduce job
root@hadoop-master:~# hadoop jar $PATH_TO_JAR $ARGS
# success!
root@hadoop-master:~# hdfs dfs -cat output/part-00000
```

**Hadoop Set-Up Script**
![](https://imgur.com/ArA2MDN.png)

**Map Reduce Successfully Running**
![](https://imgur.com/3YyhNKo.png)
![](https://imgur.com/9f15R3q.png)
* * *

## Limitations of Our Implementation

One significant limitation we faced earlier on in the construction of our cluster concerned the versions of Hypriot and Flannel we were using. We found that that nodes were occasionally dropping out and there were large start-up times for the cluster. We eventually found this issue to be rooted in the Hypriot v1.4 and Flannel v0.7. Thus, we were limited to using Hypriot v1.6 and Flannel v0.9.

Another limitations of the implementation was the issue we faced regarding the port assigned to each of our slave nodes being chosen from a pool of 30,000 possible port numbers. The port which would get assigned to the slave node would have to be opened on the node itself. Thus, each time we had to go through and open a new port on each of our nodes. Thus, our initial fix was to open all ports on each of the nodes. However, that would take up resources that our RPi3’s required for M/R. Thus, instead we decided to go to the source of the issue which was the node manager port and the yarn child port we assigned to port 3000 and the range of ports 3000-3008 respectively.

Additionally, we had a memory limitation with Map Reduce. Yarn was assigning 8GB of memory to each node. However, each node had only 1GB of memory available. Therefore, the cluster was experiencing large amounts of memory swapping due to the its limited memory. Thus, we had to limit the node and resource manager's memory requirements to be 1GB per node and 512MB per Map Reduce process.

Lastly, when we initially set up our cluster, we had the IPs being assigned to our cluster dynamically. Thus, when moved our cluster to a network which did not have the same IP address space, originally 10.0.0.1, the cluster could not connect to the internet. Thus, we had to have a static IP resolution for our cluster. Thereafter, when we moved our cluster to a new network, we rectified it by having our cluster connected to our own router, and our own router connected to the network.

* * *

## Team Members
![alt text](https://i.imgur.com/s5MeYOX.png 'Edmond Zalenski')
![alt text](https://i.imgur.com/WBljN2W.png 'George Kharchenko')
![alt text](https://i.imgur.com/vJaKvek.png 'George Poulos')
![alt text](https://imgur.com/kC9YR9l.png 'Jeff Kaleshi')
![alt text](https://imgur.com/Y0XF2Zd.png 'Kevin Liu')
![alt text](https://imgur.com/93jdJll.png 'Kunal Shah')
![alt text](https://imgur.com/EHiIEM4.png 'Tim Choh')
