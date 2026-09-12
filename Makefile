SHELL := /bin/bash
.DEFAULT_GOAL := help

PKGDIR := dist
OUTDIR := $(PKGDIR)/packages
SEMVER := $(shell sed -nE 's/^readonly VERSION="([^"-]+([^-"][^"]*)?)(-dev)?"$$/\1/p' ./getnf)

UBUNTU_VERSION := 24.04
FEDORA_VERSION := 44
UBUNTU_IMAGE := getnftest-ubuntu:$(UBUNTU_VERSION)-$(SEMVER)
FEDORA_IMAGE := getnftest-fedora:$(FEDORA_VERSION)-$(SEMVER)

help:
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(PKGDIR):
	mkdir -p $@

$(OUTDIR): | $(PKGDIR)
	mkdir -p $@

# Fix env-script-interpreter error from rpmlint and remove dev suffix from VERSION
$(PKGDIR)/getnf: getnf | $(PKGDIR)
	sed -E \
		-e '1s|#!/usr/bin/env bash|#!/bin/bash|' \
		-e 's/^(readonly VERSION="[^"]+)-dev"$$/\1"/' \
		$< > $@
	chmod +x $@

$(PKGDIR)/getnf.1.gz: man/getnf.1 | $(PKGDIR)
	gzip -n -9 -c $< > $@

packages: $(PKGDIR)/getnf $(PKGDIR)/getnf.1.gz | $(OUTDIR) ## Build DEB and RPM packages
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-deb.yaml \
		--packager deb --target "$(OUTDIR)"
	SEMVER="$(SEMVER)" nfpm pkg --config ./packaging/nfpm-rpm.yaml \
		--packager rpm --target "$(OUTDIR)"

images: packages  ## Build Ubuntu and Fedora package-test images
	docker build --build-arg BASE_VERSION="$(UBUNTU_VERSION)" --build-arg SEMVER="$(SEMVER)" \
		-f ./docker/Dockerfile.ubuntu -t "$(UBUNTU_IMAGE)" .
	docker build --build-arg BASE_VERSION="$(FEDORA_VERSION)" --build-arg SEMVER="$(SEMVER)" \
		-f ./docker/Dockerfile.fedora -t "$(FEDORA_IMAGE)" .

test: images ## Open an Ubuntu test shell
	docker run --rm -it "$(UBUNTU_IMAGE)"

ftest: images ## Open a Fedora test shell
	docker run --rm -it "$(FEDORA_IMAGE)"

clean: ## Delete the packages
	rm -rf $(PKGDIR)

clean-images: ## Delete both images
	docker image rm "$(UBUNTU_IMAGE)" -f
	docker image rm "$(FEDORA_IMAGE)" -f

rebuild: clean clean-images images ## Rebuild artifacts and test images

release: ## Print commit messages since last tag
	@LAST_TAG="$$(git describe --tags --abbrev=0 2>/dev/null || true)"; \
	echo "## Whats New since $$LAST_TAG:"; \
	COMMITS="$$(git log "$$LAST_TAG"..HEAD --pretty=format:'- %s' --reverse)"; \
	echo "$$COMMITS"

.PHONY: help packages images test ftest clean clean-images rebuild release
