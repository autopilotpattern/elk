#!/bin/bash

# create the ES index and then write an initial log entry into logstash
# so that dynamic field mapping has been configured.
onStart() {
    getServiceIp elasticsearch-master
    es_master=${ip}
    echo 'Writing .kibana index...'
    curl -XPUT -s --fail \
         -d '{"index.mapper.dynamic": true}' \
         "http://${es_master}:9200/.kibana"

    echo
    echo 'Writing initial index patterns into Elasticsearch...'
    while :
    do
        curl -XPUT -s --fail \
             -d '{"title" : "logstash-*",  "timeFieldName": "@timestamp"}' \
             "http://${es_master}:9200/.kibana/index-pattern/logstash-*" && break
        sleep 1
    done
    echo
    getServiceIp logstash
    logstash=${ip}
    echo 'Writing initial log entry into logstash...'
    while :
    do
        echo $(printf '%s localhost kibana: initializing index' "$(date '+%b %d %H:%M:%S')") | \
            nc -u ${logstash} 514 && break
        sleep 1
        echo -ne .
    done
    echo "Done!"
    reload
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

# Kibana currently requires manual intervention to create index patterns:
# https://github.com/elastic/kibana/issues/5199
# We work around this via writing directly to ES but this only works once
# kibana has started because Kibana initializes something in ES.
# So we'll do this on the first health check only.
health() {
    if mkdir /tmp/.kibana-init; then
        echo 'Setting default index for .kibana to logstash-*'
        getServiceIp elasticsearch-master
        es_master=${ip}
        curl -XPOST -s --fail \
             -d '{"doc":{"doc":{"buildNum":9693, "defaultIndex":"logstash-*"},"defaultIndex":"logstash-*"}}' \
             "http://${es_master}:9200/.kibana/config/4.4.1/_update"
        echo
        getServiceIp logstash
        logstash=${ip}
        local now=$(date '+%b %d %H:%M:%S')
        echo $(printf '%s localhost kibana: initializing index' now) | \
                nc -u ${logstash} 514 && break
        echo Done!
    fi
    # typical health check
    /usr/bin/curl --fail -s -o /dev/null http://localhost:5601
}

# --------------------------------------
# utility functions

getServiceIp() {
    echo "Getting service IP for $1..."
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
