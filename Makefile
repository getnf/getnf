SHELL := /bin/bash

all:
	@echo 'Type `make help` to see the help menu.'

help: ## Prints this help menu
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

container: ## Build a docker container for testing
	@if ! command -v docker > /dev/null; then echo "Docker not found, install it first"; \
		elif [[ $$(docker images | grep getnftest) ]]; then \
		echo 'Container "getnftest" already exists'; else echo 'Building the "getnftest" container' \
		&& docker build -t getnftest . && echo "Built successfully"; fi

delcontainer: ## Delete the docker container for testing
	@if [[ $$(docker images | grep getnftest) ]]; then echo 'Deleting "getnftest" container' && \
		docker image rm getnftest:latest -f; \
		else echo 'Container "getnftest" not found. Build it with `make container`.'; fi

rebuild: delcontainer container ## Rebuild existing docker container

test: ## Run the getnftest container interactively
	@if [[ $$(docker images | grep getnftest) ]]; then docker run -it getnftest; \
		else echo 'Container "getnftest" not found. Build it with `make container`.'; fi


.PHONY: all help container delcontainer rebuild test
