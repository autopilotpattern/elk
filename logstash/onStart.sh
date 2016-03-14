#!/bin/bash

if [[ -z ${CONSUL} ]]; then
    echo "Missing CONSUL environment variable"
    exit 1
fi

MASTER=
while true
do
    # get the list of ES master-only nodes from Consul
    MASTER=$(curl -Ls --fail http://${CONSUL}:8500/v1/catalog/service/elasticsearch-master | jq -r '.[0].ServiceAddress')
    if [[ $MASTER != "null" ]] && [[ -n $MASTER ]]; then
        break
    fi
    # no ES master-only nodes up yet, so wait and retry
    sleep 1.7
done

# update elasticsearch URL configuration
REPLACEMENT=$(printf 's/^.*hosts => \["elasticsearch"\].*$/  elasticsearch { hosts => ["%s:9200"] }/' ${MASTER})
sed -i "${REPLACEMENT}" /etc/logstash/conf.d/logstash.conf
