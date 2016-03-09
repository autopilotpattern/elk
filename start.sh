#!/bin/bash
set -e -o pipefail

# default
export COMPOSE_PROJECT_NAME=elk
source common.sh

# ---------------------------------------------------
# Main test setup

run() {
docker-compose up -d \
               elasticsearch \
               elasticsearch_master \
               kibana \
               logstash

# poll Consul for liveness and then open the console
poll-for-page "http://$(getIpPort consul 8500)/ui/" \
              'Waiting for Consul...' \
              'Opening Consul console... Refresh the page to watch services register.'

# poll Elasticsearch for liveness
poll-for-page "http://$(getIpPort elasticsearch_master 9200)/_cluster/health?pretty=true" \
              'Waiting for Elasticsearch...' \
              'Opening cluster status page.'

# poll Kibana for liveness and then open the page
poll-for-page "http://$(getIpPort kibana 5601)/app/kibana#discover" \
              'Waiting for Kibana to register as healthy...' \
              'Opening Kibana console.'

} # end main test setup


# ---------------------------------------------------
# Test clients

test() {
    local logtype=$1
    local port
    local protocol=tcp
    case $logtype in
        # fluentd)
        #    port=24224 ;;
        gelf)
            port=12201
            protocol=udp
            ;;
        syslog)
            port=514 ;;
        *)
            port=514 ;;
    esac

    echo 'Starting Nginx log source...' && \
        LOGSTASH=$(getPrivateIpPort logstash $port $protocol) \
        CONTAINERBUDDY="$(cat ./nginx/containerbuddy.json)" \
        NGINX_CONF="$(cat ./nginx/nginx.conf)" \
        docker-compose up -d nginx_$logtype

    poll-for-page "http://$(getIpPort nginx_$logtype 80)" \
                  'Waiting for Nginx to register as healthy...' \
                  'Opening web page.'
}

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

check
prep
run
