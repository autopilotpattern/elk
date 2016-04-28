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

# Add ContainerPilot and set its configuration
ENV CONTAINERPILOT_VER 2.1.0
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=e7973bf036690b520b450c3a3e121fc7cd26f1a2 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add our configuration files and scripts
ADD containerpilot.json /etc/containerpilot.json
ADD manage.sh /usr/local/bin/manage.sh
