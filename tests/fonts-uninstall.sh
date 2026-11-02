#!/usr/bin/env bash
# Run from the repository root. Uses the invoking HOME; run only in CI or an isolated test home.
set -euo pipefail

./getnf -u JetBrainsMono,CascadiaCode
./getnf -u "IBMPlexMono Hack"
if [ "${RUNNER_OS:-$(uname)}" == "Linux" ]; then
    fonts="$HOME/.local/share/fonts"
else
    fonts="$HOME/Library/Fonts"
fi
records="${XDG_DATA_HOME:-$HOME/.local/share}/getnf/releases"
for font in JetBrainsMono CascadiaCode IBMPlexMono Hack; do
    test ! -d "$fonts/$font"
    test ! -e "$records/${font}_release.txt"
done
