# Statically resolve master
echo "$(nslookup $MASTER_HOSTNAME | grep -m2 Address | tail -n1 | awk '{ print $2 }') hadoop-master" >> /etc/hosts;
# Statically resolve slave
for slave in $( cat $HADOOP_HOME/etc/hadoop/slaves ); do echo "$(nslookup $slave | grep -m2 Address | tail -n1 | awk '{ print $2 }') $slave" >> /etc/hosts; done;
# Start sshd
service ssh start
bash
