triton-elk
==========

[Elasticsearch-Logstash-Kibana (ELK)](https://www.elastic.co/products) stack designed for container-native deployment on Joyent's Triton platform.

### Architecture

![Diagram of Triton-ELK architecture](./doc/triton-elk.png)

### Setup

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent CloudAPI CLI tools](https://apidocs.joyent.com/cloudapi/#getting-started) (including the `smartdc` and `json` tools).
1. Make sure GNU make is installed.

### Running the test rig

```sh

# make sure Docker client is pointing at Triton beta
$ env | grep DOCKER_HOST
DOCKER_HOST=tcp://us-east-3b.docker.joyent.com:2376

# using the makefile just makes sure the LOGSTASH variable
# is set so we supress a bunch of docker-compose warnings
$ make run
./start.sh
Starting example application
project prefix:      elk
docker-compose file:
Creating elk_consul_1
Creating elk_kibana_1
Creating elk_elasticsearch_master_1
Creating elk_elasticsearch_1
Creating elk_logstash_1
Waiting for Consul...
......
Opening Consul console... Refresh the page to watch services register.
Waiting for Elasticsearch...
.......
Opening cluster status page.
Initializing Kibana indexes...
.....................
{"_index":".kibana","_type":"index-pattern","_id":"logstash-*","_version":1,"_shards":{"total":2,"successful":1,"failed":0},"created":true}
{"_index":".kibana","_type":"config","_id":"4.3.0","_version":2,"_shards":{"total":2,"successful":1,"failed":0}}
Waiting for Kibana to register as healthy...

Opening Kibana console.

```

At this point we have a cluster of 1 ES master, 1 ES data-only node, Kibana, and Logstash (along with the Consul discovery service). The Consul console, the ES status page, and the Kibana console will be open in your browser. Now we can run a test with the log driver:

```sh
# launch an Nginx container using the syslog driver and open in the browser
$ make test-syslog
./start.sh test syslog
Starting Nginx log source...
Recreating elk_consul_1
Creating elk_nginx_syslog_1
Waiting for Nginx to register as healthy...

Opening web page.


# launch an Nginx container using the gelf driver and open in the browser
$ make test-gelf
./start.sh test gelf
Starting Nginx log source...
Recreating elk_consul_1
Creating elk_nginx_gelf_1
Waiting for Nginx to register as healthy...

Opening web page.

```
