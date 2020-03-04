FROM gitpod/workspace-mysql



USER root
# Install custom tools, runtime, etc.


RUN apt-get update && apt-get install -y \
        git-flow \
	graphviz \
	&& apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

RUN \
  apt-get update && apt-get install -y \
  ssh \
  rsync \
  vim \

RUN \
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod 0600 ~/.ssh/authorized_keys

RUN apt-get update && \
	apt-get install -y openjdk-8-jdk && \
	apt-get install -y ant && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;
	
	RUN apt-get update && \
	apt-get install -y ca-certificates-java && \
	apt-get clean && \
	update-ca-certificates -f && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;
	
	ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
        RUN export JAVA_HOME
	
	
#RUN wget http://archive.cloudera.com/cm5/installer/latest/cloudera-manager-installer.bin 
#RUN chmod u+x cloudera-manager-installer.bin 
#RUN  ./cloudera-manager-installer.bin --i-agree-to-all-licenses --noprompt --noreadme --nooptions

#RUN wget https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/archive.key
#RUN sudo apt-key add archive.key
#RUN sudo add-apt-repository "deb [arch=amd64] http://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt bionic-cm6.3.1 contrib"
#RUN sudo echo ”deb [arch=amd64] http://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt bionic-cm6.3.1 contrib” >> /etc/apt/sources.list
#RUN sudo apt-get update
#RUN sudo apt-get install cloudera-manager-daemons cloudera-manager-server
# download native support
#RUN mkdir -p /tmp/native
#RUN curl -L https://github.com/dvoros/docker-hadoop-build/releases/download/v2.9.0/hadoop-native-64-2.9.0.tgz | tar -xz -C /tmp/native

# hadoop
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-2.9.0//hadoop-2.9.0.tar.gz" \
  | gunzip \
  | tar -x -C /usr/local/
#RUN cd /usr/local && ln -s ./hadoop-2.9.0 hadoop

ENV HADOOP_HOME /usr/local/hadoop-2.9.0
ENV HDFS_NAMENODE_USER root
ENV HDFS_DATANODE_USER root
ENV HDFS_SECONDARYNAMENODE_USER root
ENV YARN_RESOURCEMANAGER_USER root
ENV YARN_NODEMANAGER_USER root
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_YARN_HOME $HADOOP_HOME
ENV HADOOP_CONF_DIR /usr/local/hadoop-2.9.0/etc/hadoop


RUN echo "JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo "HADOOP_HOME=$HADOOP_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_HOME/input
RUN cp $HADOOP_HOME/etc/hadoop/*.xml $HADOOP_HOME/input
RUN chmod -R 777 /usr/local/hadoop-2.9.0

# fixing the libhadoop.so like a boss
#RUN rm -rf /usr/local/hadoop-2.9.0/lib/native
#RUN mv /tmp/native /usr/local/hadoop-2.9.0/lib



# Make Hadoop executables available on PATH
ENV PATH $PATH:$HADOOP_HOME/bin



# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122

ENV SQOOP_HOME /usr/local/sqoop
ENV MYSQL_JAR_VERSION=5.1.40

RUN curl -s https://downloads.apache.org/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz | tar -xz -C /usr/local
RUN ln -s /usr/local/sqoop-1.4.7.bin__hadoop-2.6.0 $SQOOP_HOME

RUN mkdir -p /tmp/jdbc \
    && curl -Lo /tmp/mysql-connector-java-$MYSQL_JAR_VERSION.tar.gz https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-$MYSQL_JAR_VERSION.tar.gz \
    && tar -xvf /tmp/mysql-connector-java-$MYSQL_JAR_VERSION.tar.gz -C /tmp/jdbc \
    && rm /tmp/mysql-connector-java-$MYSQL_JAR_VERSION.tar.gz \
    && mv /tmp/jdbc/mysql-connector-java-$MYSQL_JAR_VERSION/mysql-connector-java-$MYSQL_JAR_VERSION-bin.jar $SQOOP_HOME/lib/ \
    && rm -rf /tmp/mysql-connector-java-$MYSQL_JAR_VERSION/

ENV PATH $PATH:$HADOOP_HOME/bin:$SQOOP_HOME/bin

# SPARK
ENV SPARK_VERSION 2.4.1
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/local/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

# Download Apche Hive-2.3.6
RUN wget -O apache-hive.tar.gz https://downloads.apache.org/hive/hive-2.3.6/apache-hive-2.3.6-bin.tar.gz && \
tar -xzf apache-hive.tar.gz -C /usr/local/ && rm apache-hive.tar.gz

# Create a soft link to make futher upgrade transparent
RUN ln -s /usr/local/apache-hive-2.3.6-bin /usr/local/hive

# Set environment of hive
ENV HIVE_HOME /usr/local/apache-hive-2.3.6-bin
ENV PATH $PATH:$HIVE_HOME/bin


    

USER gitpod
# Apply user-specific settings
	RUN bash -c "npm install -g generator-jhipster \
	&& npm install -g @angular/cli" 
	
RUN bash -c ". /home/gitpod/.sdkman/bin/sdkman-init.sh \
             && sdk install scala \
             && sdk install sbt" 	
	     	     
 RUN bash -c "wget https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/archive.key \
             && sudo apt-key add archive.key \
	     && sudo add-apt-repository 'deb [arch=amd64] http://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt bionic-cm6.3.1 contrib' \
	     && sudo apt-get update \
             && sudo apt-get -y install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"    
	     
#RUN bash -c "sudo echo 'gitpod ALL = NOPASSWD: / bin systemctl start cloudera-scm-server' >> /etc/sudoers"	     

# Give back control
USER root
RUN apt install -y build-essential software-properties-common curl gdebi net-tools wget sqlite3 dirmngr nano lsb-release apt-transport-https -y

#RUN sudo echo "gitpod ALL = NOPASSWD: / bin systemctl start cloudera-scm-server" >> /etc/sudoers

#RUN sudo /home/cloudera/cloudera-manager --express --force
#RUN sudo systemctl start cloudera-scm-agent

# `Z_VERSION` will be updated by `dev/change_zeppelin_version.sh`
ENV Z_VERSION="0.8.2"
ENV LOG_TAG="[ZEPPELIN_${Z_VERSION}]:" \
    Z_HOME="/usr/zeppelin" \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
    
    

RUN echo "$LOG_TAG install tini related packages" && \
    apt-get install -y wget curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb
    
  RUN curl -sL --retry 3 \
  "http://apachemirror.wuchna.com/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz" \
  | gunzip \
  | tar x -C /usr/ \
  && mv /usr/zeppelin-${Z_VERSION}-bin-all ${Z_HOME} \
  #&& rm -rf /usr/zeppelin-${Z_VERSION}-bin-all.tgz \
  #&& chown -R gitpod:gitpod /usr/zeppelin \
  && mkdir /usr/zeppelin/logs \
  && chmod -R 777 /usr/zeppelin/logs \
  && mkdir /usr/zeppelin/run \
  && chmod -R 777 /usr/zeppelin/run   
  
  ENV PATH $PATH:$Z_HOME/bin 
  
    RUN echo "$LOG_TAG Cleanup" && \
    apt-get autoclean && \
    apt-get clean

EXPOSE 8080

ENTRYPOINT [ "/usr/bin/tini", "--" ]
#RUN /usr/zeppelin/bin/zeppelin-daemon.sh start
RUN chmod -R 777 /run
RUN chmod -R 777 /etc
