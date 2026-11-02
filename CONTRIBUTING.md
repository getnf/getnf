# Contributing to GetNF

Welcome to the GetNF contributing guide.

## Development

- Follow the [Shell Style Guide](https://google.github.io/styleguide/shellguide.html) from Google
- Format the code with [shfmt](https://github.com/mvdan/sh) by running `shfmt -w getnf tests/*.sh`
- Make sure [shellcheck](https://github.com/koalaman/shellcheck) shows no errors when running `shellcheck getnf tests/*.sh`
- Format the README with [Prettier](https://prettier.io/) by running `prettier --write README.md`

## Testing

Run these commands from the repository root:

- `make test` runs uninstall safety, installer, and live font installation/removal tests in a temporary HOME and working directory, which are cleaned up afterward. Requires internet access for font downloads; your installed fonts and getnf configuration are left untouched.
- `make ci-test` builds DEB/RPM packages and Ubuntu/Fedora test images, then checks the installed packages inside disposable containers. Requires Docker, [nFPM](https://nfpm.goreleaser.com/), and internet access. Build artifacts are written to `dist/`.
- `make test-all` runs both suites and requires all dependencies above.

For an interactive package-test container, use `make utest` (Ubuntu) or `make ftest` (Fedora). These targets also build the packages and images first.

Run individual scripts such as `bash tests/uninstall-safety.sh` for focused checks. The installer and font integration scripts use the invoking HOME directly; use `make test` for an isolated run. `tests/package.sh` runs inside the package-test containers through `make ci-test`.
