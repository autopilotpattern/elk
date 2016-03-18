FROM debian:jessie

RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# If we wanted the development version we could pull that instead but we
# want to run a production environment here
RUN export PKG=kibana-4.4.1-linux-x64.tar.gz \
    && export PKG_SHA1=b4f1b5d89a0854e3fb1e6d31faa1bc78e063b083 \
    && curl -Ls -o /tmp/${PKG} "https://download.elastic.co/kibana/kibana/${PKG}" \
    && echo "${PKG_SHA1}  /tmp/${PKG}" | sha1sum -c \
    && tar zxf /tmp/${PKG} \
    && mv /kibana-4.4.1-linux-x64 /usr/share/kibana \
    && rm /tmp/${PKG}

EXPOSE 5601

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.2.1
RUN export CB_SHA1=aca04b3c6d6ed66294241211237012a23f8b4f20 \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /bin \
    && rm /tmp/containerbuddy.tar.gz

# Add our configuration files and scripts
ADD containerbuddy.json /etc/containerbuddy.json
ADD manage.sh /bin/manage.sh
