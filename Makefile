SHELL := /bin/bash

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

PKGDIR := dist
SEMVER := $(shell sed -nE 's/^readonly VERSION="([^"-]+([^-"][^"]*)?)(-dev)?"$$/\1/p' ./getnf)
packages: $(PKGDIR)/getnf $(PKGDIR)/getnf.1.gz ## Build deb and rpm packages
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-deb.yaml --packager deb --target .
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-rpm.yaml --packager rpm --target .

# Fix env-script-interpreter error from rpmlint and remove dev suffix from VERSION
$(PKGDIR)/getnf: getnf | $(PKGDIR)
	sed -E \
		-e '1s|#!/usr/bin/env bash|#!/bin/bash|' \
		-e 's/^(readonly VERSION="[^"]+)-dev"$$/\1"/' \
		$< > $@
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

build: clean packages delc cont ## [Re]build both packages and containers

test: ## Run the getnftest-ubuntu container interactively
	docker run -it getnftest-ubuntu

ftest: ## Run the getnftest-fedora container interactively
	docker run -it getnftest-fedora

release: ## Print commit messages since last tag
	@LAST_TAG="$$(git describe --tags --abbrev=0 2>/dev/null || true)"; \
	echo "Commits since $$LAST_TAG:"; \
	COMMITS="$$(git log "$$LAST_TAG"..HEAD --pretty=format:'- %s')"; \
	echo "$$COMMITS"

.PHONY: help packages clean cont delc build test ftest release
