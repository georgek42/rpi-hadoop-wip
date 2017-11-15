FROM armv7/armhf-ubuntu_core:latest

RUN apt-get update && apt-get install -y --no-install-recommends openssh-server openssh-client vim curl dnsutils wget && apt-get clean

ENV HADOOP_PREFIX /usr/local/hadoop

RUN mkdir -p /usr/local/java && curl -L 'http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-arm32-vfp-hflt.tar.gz' -H 'Cookie: oraclelicense=accept-securebackup-cookie' --insecure | tar -xz -C /usr/local/java/

ENV JAVA_HOME /usr/local/java/jdk1.8.0_151
ENV PATH $JAVA_HOME/bin:$PATH

RUN curl -L http://mirror.apache-kr.org/hadoop/common/hadoop-2.8.2/hadoop-2.8.2.tar.gz | tar -xz -C /usr/local/ 
RUN cd /usr/local && ln -s ./hadoop-2.8.2 hadoop && rm -rf /usr/local/hadoop/lib/native
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/local/java/jdk1.8.0_151\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN chown -R root:root /usr/local/hadoop-2.8.2 

WORKDIR /root

ADD entry.sh /root/entry.sh

ENV HADOOP_HOME=/usr/local/hadoop 
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin 

RUN rm -rf ~/.ssh/*
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN mkdir -p ~/hdfs/namenode && \ 
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

COPY config/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/run-wordcount.sh ~/run-wordcount.sh

RUN chmod +x ~/start-hadoop.sh && \
    chmod +x ~/run-wordcount.sh && \
    chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    chmod +x $HADOOP_HOME/sbin/start-yarn.sh 

CMD [ "bash", "-c", "/root/entry.sh"]
