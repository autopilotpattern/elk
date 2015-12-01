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

# write an initial log entry so that we can use dynamic field mapping
echo 'Initializing Kibana indexes...'
nc $(echo $(getIpPort logstash 514) | awk '{split($0,a,":"); print a[1],a[2]}') <<EOF
echo $(printf '%s localhost kibana: initializing index' "$(date '+%b %d %H:%M:%S')") |
EOF


echo 'Starting Nginx log source...' && \
     LOGSTASH=$(getPrivateIpPort logstash 514) \
     CONTAINERBUDDY="$(cat ./nginx/containerbuddy.json)" \
     NGINX_CONF="$(cat ./nginx/nginx.ctmpl)" \
     docker-compose up -d nginx
