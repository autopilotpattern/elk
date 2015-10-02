FROM debian:jessie

RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# If we wanted the development version we could pull that instead but we
# want to run a production environment here
RUN export PKG=kibana-4.1.2-linux-x64.tar.gz && \
    curl -Lo ${PKG} "https://download.elastic.co/kibana/kibana/${PKG}" && \
    tar -xzf ${PKG} && \
    mkdir -p /usr/share/kibana && \
    mv kibana-4.1.2-linux-x64/* /usr/share/kibana

EXPOSE 5601

# get Containerbuddy release
RUN export CB=containerbuddy-0.0.2-alpha &&\
    mkdir -p /opt/containerbuddy && \
    curl -Lo /tmp/${CB}.tar.gz \
    https://github.com/joyent/containerbuddy/releases/download/0.0.2-alpha/${CB}.tar.gz && \
	tar -xf /tmp/${CB}.tar.gz && \
    mv /build/containerbuddy /opt/containerbuddy/

# Add our configuration files and scripts
ADD containerbuddy.json /etc/containerbuddy.json
ADD onStart.sh /opt/containerbuddy/onStart.sh
