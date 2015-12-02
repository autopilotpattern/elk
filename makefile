MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail
.DEFAULT_GOAL := build

PHONY: *

# -------------------------------------------
# build and release

build:
	cd kibana && docker build --tag 0x74696d/triton-kibana .
	cd logstash && docker build --tag 0x74696d/triton-logstash .

ship:
	docker push 0x74696d/triton-kibana
	docker push 0x74696d/triton-logstash


# -------------------------------------------
# run on Triton

run: export LOGSTASH = n/a
run:
	./start.sh

# with 3 ES data nodes and 2 kibana app instances
scale: export LOGSTASH = n/a
scale:
	docker-compose -p elk scale elasticsearch=3
	docker-compose -p elk scale kibana=2

# run test for test-syslog, test-gelf (or test-fluentd once it works)
test-%:
	./start.sh test $*


# -------------------------------------------
# run against a local Docker environment

local: export LOGSTASH = n/a
local:
	-docker-compose -p elk stop || true
	-docker-compose -p elk rm -f || true
	docker-compose -p elk -f local-compose.yml pull
	docker-compose -p elk -f local-compose.yml build
	./start.sh -f local-compose.yml

# test for local-test-syslog, local-test-gelf
# (or local-test-fluentd once it works)
local-test-%:
	./start.sh -f local-compose.yml test $*
