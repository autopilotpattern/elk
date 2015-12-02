MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail
.DEFAULT_GOAL := build

PHONY: *

build:
	docker-compose -p elk -f local-compose.yml build

# for running against local Docker environment
local: export LOGSTASH = n/a
local:
	-docker-compose -p elk stop || true
	-docker-compose -p elk rm -f || true
	#docker-compose -p elk -f local-compose.yml pull
	docker-compose -p elk -f local-compose.yml build
	./start.sh -f local-compose.yml

# run test for test-syslog, test-gelf, or test-fluentd
test-%:
	./start.sh -f local-compose.yml test $*

ship:
	cd kibana && docker build --tag 0x74696d/triton-kibana .
	docker push 0x74696d/triton-kibana

# run on Triton with 3 ES data nodes and 2 kibana app instances
run:
	./start.sh
	docker-compose -p elk scale elasticsearch=3
	docker-compose -p elk scale kibana=2
