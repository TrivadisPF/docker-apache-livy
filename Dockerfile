# select operating system
FROM bde2020/spark-base:2.4.5-hadoop2.7

ENV LIVY_VERSION=0.7.0-incubating

# install operating system packages 
RUN apk add --no-cache git curl gettext unzip wget make 

# add config, init and source files 
# entrypoint
ADD init /opt/docker-init
ADD conf /opt/docker-conf

USER root

# folders
RUN mkdir /var/apache-spark-binaries/

# binaries
# apache livy
RUN wget http://mirror.23media.de/apache/incubator/livy/${LIVY_VERSION}/apache-livy-${LIVY_VERSION}-bin.zip -O /tmp/livy.zip
RUN unzip /tmp/livy.zip -d /opt/
RUN mv /opt/apache-livy-${LIVY_VERSION}-bin /opt/apache-livy-bin

# Logging dir
RUN mkdir /opt/apache-livy-bin/logs

ENV SPARK_MASTER_ENDPOINT=spark-master
ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER=yarn
ENV SPARK_HOME=/spark
 
# expose ports
EXPOSE 8998

# start from init folder
WORKDIR /opt/docker-init
CMD ["./entrypoint"]