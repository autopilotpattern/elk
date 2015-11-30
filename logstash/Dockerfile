FROM debian:jessie

RUN apt-get update && \
    apt-get install -y \
    openjdk-7-jre \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# get logstash (install logrotate separately so we can share image
# layers with our ES image)
RUN apt-get update && \
    apt-get install -y \
    logrotate \
    && rm -rf /var/lib/apt/lists/*
RUN export LS_PKG=logstash_2.1.0-1_all.deb && \
    curl -LO https://download.elastic.co/logstash/logstash/packages/debian/${LS_PKG} && \
    dpkg -i ${LS_PKG} && \
    rm ${LS_PKG}

# get Containerbuddy release
RUN export CB=containerbuddy-0.0.2-alpha &&\
    mkdir -p /opt/containerbuddy && \
    curl -Lo /tmp/${CB}.tar.gz \
    https://github.com/joyent/containerbuddy/releases/download/0.0.2-alpha/${CB}.tar.gz && \
	tar -xf /tmp/${CB}.tar.gz && \
    mv /build/containerbuddy /opt/containerbuddy/

# Add our configuration files and scripts
COPY containerbuddy.json /etc/containerbuddy.json
COPY logstash.conf /etc/logstash/conf.d/logstash.conf
COPY onStart.sh /opt/containerbuddy/onStart.sh
