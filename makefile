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
	docker-compose -p elk -f local-compose.yml up -d
	open "http://$(shell docker-machine ip default):8500/ui/"

ship:
	cd kibana && docker build --tag 0x74696d/triton-kibana .
	docker push 0x74696d/triton-kibana

# run on Triton with 3 ES data nodes and 2 kibana app instances
# TODO: might need to add script for inject consul data on this instead
run:
	docker-compose -p elk up -d
	docker-compose -p elk scale elasticsearch=3
	docker-compose -p elk scale kibana=2
