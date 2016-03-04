FROM debian:jessie

RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# If we wanted the development version we could pull that instead but we
# want to run a production environment here
RUN export PKG=kibana-4.3.0-linux-x64.tar.gz && \
    curl -Lo ${PKG} "https://download.elastic.co/kibana/kibana/${PKG}" && \
    tar -xzf ${PKG} && \
    mkdir -p /usr/share/kibana && \
    mv kibana-4.3.0-linux-x64/* /usr/share/kibana

EXPOSE 5601

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.1.0
RUN export CB_SHA1=5cb5212707b5a7ffe41ee916add83a554d1dddfa \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Add our configuration files and scripts
ADD containerbuddy.json /etc/containerbuddy.json
ADD onStart.sh /bin/onStart.sh
