FROM trivadis/apache-spark-base:2.4.5-hadoop2.8

MAINTAINER Marek Rychly <marek.rychly@gmail.com>

# https://livy.apache.org/download/
ARG LIVY_NAME=apache-livy
ARG LIVY_VERSION=0.7.0-incubating

ARG DOWNLOAD_CACHE
ARG APACHE_ORIG="http://www-eu.apache.org/dist"
#ARG APACHE_MIRROR="ftp://mirror.hosting90.cz/apache"
ARG APACHE_MIRROR="http://archive.apache.org/dist"

ENV LIVY_HOME="/opt/livy"
ENV LIVY_CONF_DIR="${LIVY_HOME}/conf"
ENV \
LIVY_DEF_CONF="${LIVY_CONF_DIR}/livy.conf" \
LIVY_ENV_CONF="${LIVY_CONF_DIR}/livy-env.sh"

COPY scripts /

RUN true \
# make the scripts executable
&& chmod 755 /*.sh \
# sed: scripts to set Livy properties in files require GNU sed (the usage of busybox sed may result into incorrect outputs)
&& apk add --no-cache --update gnupg attr sed \
\
# download keys and trust them
&& ( [ -n "${DOWNLOAD_CACHE}" ] && cp -v "${DOWNLOAD_CACHE}/livy.KEYS" /tmp \
	|| wget -O /tmp/livy.KEYS "${APACHE_ORIG}/incubator/livy/KEYS" ) \
&& gpg --import /tmp/livy.KEYS \
&& echo "trust-model always" > ~/.gnupg/gpg.conf \
\
# download the package
&& ( [ -n "${DOWNLOAD_CACHE}" ] && cp -v "${DOWNLOAD_CACHE}/${LIVY_NAME}-${LIVY_VERSION}-bin.zip" /tmp \
	|| wget -O /tmp/${LIVY_NAME}-${LIVY_VERSION}-bin.zip "${APACHE_MIRROR}/incubator/livy/${LIVY_VERSION}/${LIVY_NAME}-${LIVY_VERSION}-bin.zip" ) \
\
# download and verify signature
&& ( [ -n "${DOWNLOAD_CACHE}" ] && cp -v "${DOWNLOAD_CACHE}/${LIVY_NAME}-${LIVY_VERSION}-bin.zip.asc" /tmp \
	|| wget -O /tmp/${LIVY_NAME}-${LIVY_VERSION}-bin.zip.asc "${APACHE_ORIG}/incubator/livy/${LIVY_VERSION}/${LIVY_NAME}-${LIVY_VERSION}-bin.zip.asc" ) \
&& for SIG in /tmp/*.asc; do gpg --verify "${SIG}" "${SIG%.asc}"; done \
\
# extract the package and remove garbage
&& mkdir -p "${LIVY_HOME%/*}" \
&& unzip -q "/tmp/${LIVY_NAME}-${LIVY_VERSION}-bin.zip" -d "${LIVY_HOME%/*}" \
&& mv "${LIVY_HOME%/*}"/${LIVY_NAME}-* "${LIVY_HOME}" \
\
# fix ISSUE: os::commit_memory failed; error=Operation not permitted
# (AUFS does not support xattr, so we need to set the flag once again after execution of the container in its entrypoint)
# https://en.wikibooks.org/wiki/Grsecurity/Application-specific_Settings#Java
#&& setfattr -n user.pax.flags -v em "${JAVA_HOME}/bin/java" "${JAVA_HOME}/jre/bin/java" \
#\
# create a log directory
&& mkdir -p ${LIVY_HOME}/logs \
\
# integrate with Java, Hadoop, and Spark
&& echo '#!/bin/sh' > ${LIVY_ENV_CONF} \
&& echo "export JAVA_HOME=${JAVA_HOME}" >> ${LIVY_ENV_CONF} \
&& echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ${LIVY_ENV_CONF} \
&& echo "export SPARK_HOME=${SPARK_HOME}" >> ${LIVY_ENV_CONF} \
&& chmod 755 ${LIVY_ENV_CONF} \
\
# set up permissions
&& addgroup -S livy \
&& adduser -h ${LIVY_HOME} -g "Apache Livy" -s /bin/sh -G livy -S -D -H livy \
&& chown -R livy:livy ${LIVY_HOME} \
\
# set path for the shell
&& echo '#!/bin/sh' > /etc/profile.d/path-livy.sh \
&& echo "export PATH=\"\${PATH}:${LIVY_HOME}/bin\"" >> /etc/profile.d/path-livy.sh \
&& chmod 755 /etc/profile.d/path-livy.sh \
\
# clean up
&& apk del gnupg \
&& rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK CMD /healthcheck.sh
