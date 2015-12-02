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


# ---------------------------------------------------
# Kibana configuration

echo 'Initializing Kibana indexes...'

# write an initial log entry so that we can use dynamic field mapping.
while :
do
    echo $(printf '%s localhost kibana: initializing index' "$(date '+%b %d %H:%M:%S')") | \
        nc $(echo $(getIpPort logstash 514) | awk '{split($0,a,":"); print a[1],a[2]}') && break
    sleep 1
    echo -ne .
done
echo

# Kibana currently requires manual intervention to create index patterns:
# https://github.com/elastic/kibana/issues/5199
# We'll work around this via writing directly to ES
# ref https://github.com/elastic/kibana/issues/3709#issuecomment-140453042

curl -XPUT -s --fail \
     -d '{"title" : "logstash-*",  "timeFieldName": "@timestamp"}' \
     "http://$(getIpPort elasticsearch_master 9200)/.kibana/index-pattern/logstash-*"

curl -XPOST -s --fail \
     -d $(printf '{"doc":{"doc":{"buildNum":%s,"defaultIndex":"%s"},"defaultIndex":"%s"}}' \
                 9369 "logstash-*" "logstash-*") \
     "http://$(getIpPort elasticsearch_master 9200)/.kibana/config/4.3.0/_update"

# poll Kibana for liveness and then open the page
echo
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
        fluentd)
            port=24224 ;;
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
