FROM alpine:3.3

RUN apk --update add \
    openjdk8-jre \
    curl

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk

# install deps for logstash and our tools, but run separately from the above
# so we can share image layers with another Java image
RUN apk --update add \
    jq \
    logrotate \
    ca-certificates \
    bash

ENV LD_LIBRARY_PATH /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/jli

# get logstash
RUN export LS_PKG=logstash-2.2.2.tar.gz \
    && export LS_SHA1=2a485859afe596914dcccc6a0c17a7e1f27ad71c \
    && curl -Ls --fail -o /tmp/${LS_PKG} https://download.elastic.co/logstash/logstash/${LS_PKG} \
    && echo "${LS_SHA1}  /tmp/${LS_PKG}" | sha1sum -c \
    && mkdir /opt \
    && tar zxf /tmp/${LS_PKG} -C /opt \
    && mv /opt/logstash-2.2.2 /opt/logstash \
    && rm /tmp/${LS_PKG}

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.2.0
RUN export CB_SHA1=a20e0fb550e98abc9ca8b9ce80bf433a814eed41 \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Create and take ownership over required directories
RUN mkdir -p /etc/logstash \
    && mkdir -p /var/log/logstash

# Add our configuration files and scripts
COPY containerbuddy.json /etc/containerbuddy.json
COPY logstash.conf /etc/logstash/conf.d/logstash.conf
COPY onStart.sh /bin/onStart.sh

EXPOSE 514
EXPOSE 12201
EXPOSE 24224
