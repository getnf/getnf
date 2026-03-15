SHELL := /bin/bash

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

PKGDIR := dist
SEMVER := $(shell sed -nE 's/^readonly VERSION="([^"]+)"/\1/p' ./getnf)
packages: $(PKGDIR)/getnf $(PKGDIR)/getnf.1.gz ## Build deb and rpm packages
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-deb.yaml --packager deb --target .
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-rpm.yaml --packager rpm --target .

$(PKGDIR)/getnf: getnf | $(PKGDIR) # fix env-script-interpreter error from rpmlint
	sed '1s|#!/usr/bin/env bash|#!/bin/bash|' $< > $@
	chmod +x $@

$(PKGDIR)/getnf.1.gz: man/getnf.1 | $(PKGDIR)
	gzip -n -9 -c $< > $@

$(PKGDIR):
	mkdir -p $(PKGDIR)

clean: ## Delete the packages
	rm -rf $(PKGDIR) *.rpm *.deb

cont: ## Build 2 docker containers for testing
	docker build --build-arg SEMVER="$(SEMVER)" -f ./docker/Dockerfile.ubuntu -t getnftest-ubuntu .
	docker build --build-arg SEMVER="$(SEMVER)" -f ./docker/Dockerfile.fedora -t getnftest-fedora .

delc: ## Delete both containers
	docker image rm getnftest-ubuntu:latest -f
	docker image rm getnftest-fedora:latest -f

rebuild: clean packages delc cont ## Rebuild both packages and containers

test: ## Run the getnftest-ubuntu container interactively
	docker run -it getnftest-ubuntu

ftest: ## Run the getnftest-fedora container interactively
	docker run -it getnftest-fedora

.PHONY: help packages clean cont delc rebuild test ftest
