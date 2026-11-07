#!/usr/bin/env bash
# Local entry point; individual scripts remain available to CI as named steps.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/getnf-tests.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT

export HOME="$fixture/home"
export XDG_DATA_HOME="$fixture/data"
export XDG_CONFIG_HOME="$fixture/config"
export XDG_CACHE_HOME="$fixture/cache"
export XDG_STATE_HOME="$fixture/state"
mkdir -p "$HOME" "$fixture/work" "$fixture/tmp"
export TMPDIR="$fixture/tmp"
unset RUNNER_OS

# The bootstrap installer uses getnf.tmp in its working directory. Run copies
# so even that temporary file cannot collide with anything in the checkout.
cp "$repo_root/getnf" "$repo_root/install.sh" "$fixture/work/"
cd -- "$fixture/work"

for test_script in arguments.sh startup.sh download.sh extraction.sh uninstall-safety.sh installer.sh fonts-install.sh fonts-uninstall.sh; do
    printf '\nRunning %s\n' "$test_script"
    bash "$repo_root/tests/$test_script"
done
printf '\nLocal tests passed\n'
