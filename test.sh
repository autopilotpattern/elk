#!/bin/bash
set -e -o pipefail

help() {
    echo 'Usage ./test.sh [-f docker-compose.yml] [-p project] [args]'
    echo
    echo 'Optional args'
    echo '  run:            [default] starts up the entire stack and runs the test clients.'
    echo '  check:          verify your local environment is correctly configured.'
    echo '  show:           open web pages of an already running stack.'
    echo '  test <logtype>: run test client against an already running stack. logtype'
    echo '                  should be one of: syslog, gelf'
    echo '  help            help. you are reading it now.'
    echo
    echo 'Optional flags:'
    echo '  -f <filename>   use this file as the docker-compose config file'
    echo '  -p <project>    use this name as the project prefix for docker-compose'
    echo
}


# default values which can be overriden by -f or -p flags
export COMPOSE_PROJECT_NAME=elk
export COMPOSE_FILE=

# give the docker remote api more time before timeout
export COMPOSE_HTTP_TIMEOUT=300


# ---------------------------------------------------
# Top-level commmands

run() {
    docker-compose up -d \
               elasticsearch \
               elasticsearch_master \
               kibana \
               logstash
    show
    test
}

show() {
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
}

# Run test clients
test() {
    local logtype=$1
    local port
    local protocol=tcp
    case $logtype in
        gelf)
            port=12201
            protocol=udp
            ;;
        syslog)
            port=514 ;;
        # Triton supports fluentd but logstash codec support is broken:
        # https://github.com/logstash-plugins/logstash-codec-fluent/issues/2
        # https://github.com/logstash-plugins/logstash-codec-fluent/pull/5
        # fluentd)
        #    port=24224 ;;
        *)
            echo 'logtype arguments required: gelf or syslog'
            exit 1;;
    esac

    echo 'Starting Nginx log source...' && \
        CONSUL=$(getPrivateIpPort consul 8500 tcp) \
        LOGSTASH=$(getPrivateIpPort logstash $port $protocol) \
        CONTAINERBUDDY="$(cat ./nginx/containerbuddy.json)" \
        NGINX_CONF="$(cat ./nginx/nginx.conf)" \
        docker-compose -f test-compose.yml up -d nginx_$logtype

    poll-for-page "http://$(getIpPort nginx_$logtype 80)" \
                  'Waiting for Nginx to register as healthy...' \
                  'Opening web page.'
}



# ---------------------------------------------------
# utility functions

# check for prereqs
check() {
    command -v docker >/dev/null 2>&1 || {
        echo "Docker is required, but does not appear to be installed. See https://docs.joyent.com/public-cloud/api-access/docker"; exit; }
    if [ -z "${COMPOSE_FILE}" ]; then
        command -v sdc-listmachines >/dev/null 2>&1 || {
            echo "Joyent CloudAPI CLI is required to test on Triton, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }
    fi
    command -v json >/dev/null 2>&1 || {
        echo "JSON CLI tool is required, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }
}

# get the IP:port of a container via either the local docker-machine or from
# sdc-listmachines.
getIpPort() {
    if [ -z "${COMPOSE_FILE}" ]; then
        local ip=$(sdc-listmachines --name ${COMPOSE_PROJECT_NAME}_$1_1 | json -a ips.1)
    else
        local ip=$(docker-machine ip default)
    fi
    local port=$(getPort $1 $2 $3)
    echo "$ip:$port"
}

# get the IP:port of a container's private IP via `docker exec`
getPrivateIpPort() {
    local ip=$(docker exec -it ${COMPOSE_PROJECT_NAME}_$1_1 ip addr show eth0 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    local port=$(getPort $1 $2 $3)
    echo "$ip:$port"
}

# get the mapped port number for a given container's port and protocol
getPort() {
    local protocol=$3
    if [ -z $protocol ]; then
        protocol='tcp'
    fi
    if [ -z "${COMPOSE_FILE}" ]; then
        local port=$2
    else
        local port=$(docker inspect ${COMPOSE_PROJECT_NAME}_$1_1 | json -a NetworkSettings.Ports."$2/$protocol" | json -a HostPort | sort -nb | head -1)
    fi
    echo $port
}

# usage: poll-for-page <url> <pre-message> <post-message>
poll-for-page() {
    echo "$2"
    while :
    do
        curl --fail -s -o /dev/null "$1" && break
        sleep 1
        echo -ne .
    done
    echo
    echo "$3"
    open "$1"
}

doStuff() {
    echo doStuff
}

# ---------------------------------------------------
# parse arguments

while getopts "f:p:h" optchar; do
    case "${optchar}" in
        f) export COMPOSE_FILE=${OPTARG} ;;
        p) export COMPOSE_PROJECT_NAME=${OPTARG} ;;
    esac
done
shift $(expr $OPTIND - 1 )

until
    cmd=$1
    if [ ! -z "$cmd" ]; then
        shift 1
        $cmd "$@"
        if [ $? == 127 ]; then
            help
        fi
        exit
    fi
do
    echo
done

# default behavior
check
echo "Starting example application"
echo "project prefix:      $COMPOSE_PROJECT_NAME"
echo "docker-compose file: $COMPOSE_FILE"
run
