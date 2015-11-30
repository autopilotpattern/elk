MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail
.DEFAULT_GOAL := build

build:
	docker-compose -p elk -f local-compose.yml build

# for testing against Docker locally
test:
	-docker-compose -p elk stop || true
	-docker-compose -p elk rm -f || true
	docker-compose -p elk -f local-compose.yml build
	./start.sh -f local-compose.yml

ship:
	cd kibana && docker build --tag 0x74696d/triton-kibana .
	docker push 0x74696d/triton-kibana

# run on Triton with 3 ES data nodes and 2 kibana app instances
run:
	./start.sh
	docker-compose -p elk scale elasticsearch=3
	docker-compose -p elk scale kibana=2
