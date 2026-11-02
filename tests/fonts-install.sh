#!/usr/bin/env bash
# Run from the repository root. Uses the invoking HOME; run only in CI or an isolated test home.
set -euo pipefail

./getnf -i JetBrainsMono,CascadiaCode
./getnf -i "IBMPlexMono Hack"
if [ "${RUNNER_OS:-$(uname)}" == "Linux" ]; then
    fonts="$HOME/.local/share/fonts"
else
    fonts="$HOME/Library/Fonts"
fi
records="${XDG_DATA_HOME:-$HOME/.local/share}/getnf/releases"
for font in JetBrainsMono CascadiaCode IBMPlexMono Hack; do
    test -n "$(find "$fonts/$font" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit)"
    test -s "$records/${font}_release.txt"
done
