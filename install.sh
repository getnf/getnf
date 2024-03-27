#!/usr/bin/env bash

DEST="$HOME/.local/bin"
GETNFLOC="$DEST/getnf"

if command -v tput > /dev/null; then
    GREEN=$(tput setaf 2)
    RESET=$(tput sgr0)
fi

# add the -s or --silent flag to suppress output
SILENT='false'
if [[ "$1" == "-s" || "$1" == "--silent" ]]; then
    SILENT='true'
fi

[[ "$SILENT" == "true" ]] || echo "Installing getnf..."

mkdir -p "$DEST"

if [[ "$SILENT" == "true" ]]; then
    curl -fsSL# https://raw.githubusercontent.com/getnf/getnf/main/getnf --output getnf.tmp
else
    curl -fL# https://raw.githubusercontent.com/getnf/getnf/main/getnf --output getnf.tmp
fi

mv -f getnf.tmp "$GETNFLOC"
chmod 755 "$GETNFLOC"

[[ "$SILENT" == "true" ]] || echo "${GREEN}Installation finished${RESET}"
