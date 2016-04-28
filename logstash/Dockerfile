FROM debian:jessie

RUN apt-get update && \
    apt-get install -y \
    openjdk-7-jre-headless \
    curl \
    logrotate \
    jq \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# get logstash
RUN export LS_PKG=logstash-2.2.2.tar.gz \
    && export LS_SHA1=2a485859afe596914dcccc6a0c17a7e1f27ad71c \
    && curl -Ls --fail -o /tmp/${LS_PKG} https://download.elastic.co/logstash/logstash/${LS_PKG} \
    && echo "${LS_SHA1}  /tmp/${LS_PKG}" | sha1sum -c \
    && tar zxf /tmp/${LS_PKG} -C /opt \
    && mv /opt/logstash-2.2.2 /opt/logstash \
    && rm /tmp/${LS_PKG}

# Add ContainerPilot and set its configuration
ENV CONTAINERPILOT_VER 2.1.0
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=e7973bf036690b520b450c3a3e121fc7cd26f1a2 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Create and take ownership over required directories
RUN mkdir -p /etc/logstash \
    && mkdir -p /var/log/logstash

# Add our configuration files and scripts
COPY containerpilot.json /etc/containerpilot.json
COPY logstash.conf /etc/logstash/conf.d/logstash.conf
COPY onStart.sh /usr/local/bin/onStart.sh

EXPOSE 514
EXPOSE 12201
EXPOSE 24224
