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
ENV CONTAINERBUDDY_VERSION 1.1.0
RUN export CB_SHA1=5cb5212707b5a7ffe41ee916add83a554d1dddfa \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Add our configuration files and scripts
COPY containerbuddy.json /etc/containerbuddy.json
COPY logstash.conf /etc/logstash/conf.d/logstash.conf
COPY onStart.sh /bin/onStart.sh

EXPOSE 514
EXPOSE 12201
EXPOSE 24224
