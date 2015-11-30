#!/bin/bash
set -e -o pipefail

# default
export COMPOSE_PROJECT_NAME=elk
source common.sh

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
poll-for-page "http://$(getIpPort kibana 5601)/app/kibana" \
              'Waiting for Kibana to register as healthy...' \
              'Opening Kibana console.'

echo 'Starting Nginx log source...' && \
     LOGSTASH=$(getPrivateIpPort logstash 514) \
     CONTAINERBUDDY="$(cat ./nginx/containerbuddy.json)" \
     docker-compose up -d nginx
