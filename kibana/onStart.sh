#!/bin/bash

MASTER=
while true
do
    # get the list of ES master-only nodes from Consul
    MASTER=$(curl -Ls http://consul:8500/v1/catalog/service/elasticsearch-master | jq -r '.[0].ServiceAddress')
    if [[ $MASTER != "null" ]] && [[ -n $MASTER ]]; then
        break
    fi
    # no ES master-only nodes up yet, so wait and retry
    sleep 1.7
done

# update elasticsearch_url configuration
REPLACEMENT=$(printf 's/^elasticsearch_url.*$/elasticsearch_url: "http:\/\/%s:9200"/' ${MASTER})
echo ${REPLACEMENT}
sed -i "${REPLACEMENT}" /usr/share/kibana/src/config/kibana.yml
