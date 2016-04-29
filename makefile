MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail
.DEFAULT_GOAL := build

PHONY: *

# -------------------------------------------
# build and release

build:
	docker-compose -f local-compose.yml -p elk build kibana logstash
	cd nginx && docker build -t="elk_nginx_demo" .

ship:
	docker tag -f elk_kibana autopilotpattern/kibana
	docker tag -f elk_logstash autopilotpattern/logstash
	docker tag -f elk_nginx_demo autopilotpattern/elk-nginx-demo
	docker push autopilotpattern/kibana
	docker push autopilotpattern/logstash
	docker push autopilotpattern/elk-nginx-demo


# -------------------------------------------
# run on Triton

run:
	./test.sh

# with 3 ES data nodes and 2 kibana app instances
scale:
	docker-compose -p elk scale elasticsearch=3
	docker-compose -p elk scale kibana=2

# run test for test-syslog, test-gelf (or test-fluentd once it works)
test-%:
	./test.sh test $*


# -------------------------------------------
# run against a local Docker environment

local:
	-docker-compose -p elk stop || true
	-docker-compose -p elk rm -f || true
	docker-compose -p elk -f local-compose.yml pull
	docker-compose -p elk -f local-compose.yml build
	./test.sh -f local-compose.yml

# test for local-test-syslog, local-test-gelf
# (or local-test-fluentd once it works)
local-test-%:
	./test.sh -f local-compose.yml test $*
