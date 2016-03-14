#!/bin/bash

onStart() {
    initLogstash
    initIndex
    reload
}

# write an initial log entry into logstash so that we can use
# dynamic field mapping.
initLogstash() {
    echo 'Writing initial log entry into logstash'
    getServiceIp logstash
    logstash=${ip}
    while :
    do
        echo $(printf '%s localhost kibana: initializing index' "$(date '+%b %d %H:%M:%S')") | \
            nc -u ${logstash} 514 && break
        sleep 1
        echo -ne .
    done
    echo 'Done!'
}

# Kibana currently requires manual intervention to create index patterns:
# https://github.com/elastic/kibana/issues/5199
# We'll work around this via writing directly to ES
# ref https://github.com/elastic/kibana/issues/3709#issuecomment-140453042
initIndex() {
    echo 'Writing initial index patterns into Elasticsearch'
    getServiceIp elasticsearch-master
    es_master=${ip}
    curl -XPUT -s --fail \
         -d '{"title" : "logstash-*",  "timeFieldName": "@timestamp"}' \
         "http://${es_master}:9200/.kibana/index-pattern/logstash-*"

    curl -XPOST -v --fail \
         -d $(printf '{"doc":{"doc":{"buildNum":%s,"defaultIndex":"%s"},"defaultIndex":"%s"}}' \
                     9369 "logstash-*" "logstash-*") \
         "http://${es_master}:9200/.kibana/config/4.4.1/_update"
    echo 'Done!'
}

# inject the ES master node into the kibana config file
reload() {
    echo 'Rewriting Kibana config file'
    getServiceIp elasticsearch-master
    es_master=${ip}

    # update elasticsearch_url configuration
    REPLACEMENT=$(printf 's/^.*elasticsearch\.url.*$/elasticsearch.url: "http:\/\/%s:9200"/' ${es_master})
    sed -i "${REPLACEMENT}" /usr/share/kibana/config/kibana.yml
}

# --------------------------------------
# utility functions

getServiceIp() {
    echo "Getting service IP for $1"
    ip= # clear previous calls
    while true
    do
        ip=$(curl -Ls --fail http://${CONSUL}:8500/v1/catalog/service/$1 | jq -r '.[0].ServiceAddress')
        if [[ -n ${ip} ]] && [[ ${ip} != "null" ]]; then
            break
        fi
        # no nodes up yet, so wait and retry
        sleep 1.7
    done
}

help() {
    echo "Usage: ./manage.sh onStart  => first-run configuration for Kibana"
    echo "       ./manage.sh reload   => update Kibana config on upstream changes"
}

if [[ -z ${CONSUL} ]]; then
    echo "Missing CONSUL environment variable"
    exit 1
fi

until
    cmd=$1
    if [ -z "$cmd" ]; then
        help
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    help
    exit
done
