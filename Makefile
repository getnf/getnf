SHELL := /bin/bash
.DEFAULT_GOAL := help

PKGDIR := dist
OUTDIR := $(PKGDIR)/packages
VERSION := $(shell sed -nE 's/^readonly VERSION="([^"]+)"$$/\1/p' ./getnf)
SEMVER := $(patsubst %-dev,%,$(VERSION))
RELEASE_TAG := v$(SEMVER)

UBUNTU_VERSION := 24.04
FEDORA_VERSION := 44
UBUNTU_IMAGE := getnftest-ubuntu:$(UBUNTU_VERSION)-$(SEMVER)
FEDORA_IMAGE := getnftest-fedora:$(FEDORA_VERSION)-$(SEMVER)

NOTES_REF ?= HEAD

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

images: packages ## Build Ubuntu and Fedora package-test images
	docker build --build-arg BASE_VERSION="$(UBUNTU_VERSION)" --build-arg SEMVER="$(SEMVER)" \
		-f ./docker/Dockerfile.ubuntu -t "$(UBUNTU_IMAGE)" .
	docker build --build-arg BASE_VERSION="$(FEDORA_VERSION)" --build-arg SEMVER="$(SEMVER)" \
		-f ./docker/Dockerfile.fedora -t "$(FEDORA_IMAGE)" .

test: images ## Open an Ubuntu test shell
	docker run --rm -it "$(UBUNTU_IMAGE)"

ftest: images ## Open a Fedora test shell
	docker run --rm -it "$(FEDORA_IMAGE)"

ci-test: images ## Build and smoke-test DEB and RPM packages
	@set -euo pipefail; \
	for image in "$(UBUNTU_IMAGE)" "$(FEDORA_IMAGE)"; do \
		printf 'Testing %s\n' "$$image"; \
		docker run --rm \
			-e EXPECTED_TAG="$(RELEASE_TAG)" \
			"$$image" \
			/bin/bash -euo pipefail -c ' \
				command -v getnf; \
				test -x /usr/bin/getnf; \
				actual="$$(getnf -V)"; \
				expected="getnf $$EXPECTED_TAG"; \
				if [[ "$$actual" != "$$expected" ]]; then \
					printf "Version mismatch: expected <%s>, got <%s>\n" \
						"$$expected" "$$actual" >&2; \
					exit 1; \
				fi; \
				getnf -h > /tmp/getnf-help.txt; \
				if ! grep -q "Usage:" /tmp/getnf-help.txt; then \
					echo "Unexpected help output:" >&2; \
					cat /tmp/getnf-help.txt >&2; \
					exit 1; \
				fi; \
				for file in \
					/usr/share/doc/getnf/README.md \
					/usr/share/doc/getnf/LICENSE \
					/usr/share/man/man1/getnf.1.gz; do \
					if [[ ! -r "$$file" ]]; then \
						printf "Missing or unreadable file: %s\n" "$$file" >&2; \
						exit 1; \
					fi; \
				done; \
				gzip -t /usr/share/man/man1/getnf.1.gz; \
			'; \
	done

clean: ## Delete the packages
	rm -rf $(PKGDIR)

clean-images: ## Delete both images
	docker image rm "$(UBUNTU_IMAGE)" -f
	docker image rm "$(FEDORA_IMAGE)" -f

rebuild: clean clean-images images ## Rebuild artifacts and test images

notes: ## Print commit messages and a full changelog link
	@set -euo pipefail; \
	last_tag="$$(git describe --tags --abbrev=0 "$(NOTES_REF)")"; \
	printf '### Whats New\n\n'; \
	commits="$$(git log "$$last_tag"..HEAD --reverse --pretty=format:'- %s [%h](https://github.com/getnf/getnf/commit/%H)')"; \
	echo "$$commits"; \
	printf '\n**Full Changelog**: [%s...%s](https://github.com/getnf/getnf/compare/%s...%s)\n' \
		"$$last_tag" "$(RELEASE_TAG)" "$$last_tag" "$(RELEASE_TAG)"


release: ## Tag the current version and push it to trigger release CI
	@set -euo pipefail; \
	if [[ ! "$(VERSION)" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-dev$$ ]]; then \
		printf 'Invalid VERSION "%s"; expected MAJOR.MINOR.PATCH-dev.\n' "$(VERSION)" >&2; \
		exit 1; \
	fi; \
	git diff --quiet HEAD -- getnf; \
	git tag -a "$(RELEASE_TAG)" -m "Release $(RELEASE_TAG)"; \
	git push origin "refs/tags/$(RELEASE_TAG)"

.PHONY: help packages images test ftest ci-test clean clean-images rebuild notes release
