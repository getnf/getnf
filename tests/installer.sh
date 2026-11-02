#!/usr/bin/env bash
# Run from the repository root. Uses the invoking HOME; run only in CI or an isolated test home.
set -euo pipefail

# Reset getnf installation if, for any reason, it was cached
[[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/getnf" ]] && rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/getnf" || :
[[ -f "$HOME/.local/bin/getnf" ]] && rm -f "$HOME/.local/bin/getnf" || :
# Exercise the installer using this checkout instead of a published script.
# Invoked by the installer subprocess through the exported function.
# shellcheck disable=SC2329
curl() { cp ./getnf "${@: -1}"; }
export -f curl
bash ./install.sh
unset -f curl
cmp ./getnf "$HOME/.local/bin/getnf"
"$HOME/.local/bin/getnf" -V
