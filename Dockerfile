FROM centos:7

ARG CONFLUENCE_VERSION=5.10.6

ARG ARCHITECTURE=amd64
ARG JAVA8_VERSION=8u102
ARG JAVA8_BUILD_VERSION=b14
ARG GOSU_VERSION=1.9
ARG MYSQL_DRIVER_VERSION=5.1.38
ARG XMLSTARLET_VERSION=1.6.1-1

ENV CONFLUENCE_HOME_DIR=/var/atlassian/confluence
ENV CONFLUENCE_INSTALL_DIR=/opt/atlassian/confluence

ENV USER_ID  9000
ENV GROUP_ID 9000

# Install helper tools
RUN set -x \
    && yum update -y \
    && yum install -y curl wget tar gzip \
    && yum clean all \
    && wget -O xmlstarlet.rpm https://dl.fedoraproject.org/pub/epel/7/x86_64/x/xmlstarlet-${XMLSTARLET_VERSION}.el7.x86_64.rpm \
    && yum localinstall -y xmlstarlet.rpm \
    && rm -f xmlstarlet.rpm

# Install JDK 8
RUN set -x \
    && wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/${JAVA8_VERSION}-${JAVA8_BUILD_VERSION}/jdk-${JAVA8_VERSION}-linux-x64.rpm" \
    && yum localinstall -y jdk-${JAVA8_VERSION}-linux-x64.rpm \
    && rm -f jdk-${JAVA8_VERSION}-linux-x64.rpm \
    && ln -s /usr/java/jdk1.8.0_* /usr/java/jdk1.8.0

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/java/jdk1.8.0
ENV JAVA8_HOME /usr/java/jdk1.8.0

# Install Atlassian Confluence
RUN set -x \
    && mkdir -p ${CONFLUENCE_HOME_DIR} \
    && mkdir -p ${CONFLUENCE_INSTALL_DIR}/conf \
    && curl -Ls http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz | tar -xz --strip-components=1 -C ${CONFLUENCE_INSTALL_DIR} \
    && echo "confluence.home=${CONFLUENCE_HOME_DIR}" > ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/classes/confluence-init.properties \
    && rm -f ${CONFLUENCE_INSTALL_DIR}/lib/mysql-connector-java*.jar  \
    && curl -Ls http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz | tar -xz -C /tmp \
    && cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar ${CONFLUENCE_INSTALL_DIR}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar \
    && rm -rf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}

# Install gosu
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-${ARCHITECTURE}" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-${ARCHITECTURE}.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Expose default HTTP connector port.
EXPOSE 8090

# Create mount point for the Confluence home directory
VOLUME ${CONFLUENCE_HOME_DIR}

# Set the default working directory as the Confluence home directory.
WORKDIR ${CONFLUENCE_HOME_DIR}

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["confluence"]
