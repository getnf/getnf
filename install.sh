#!/usr/bin/env bash

DEST="$HOME/.local/bin"
GETNFLOC="$DEST/getnf"

GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

# add the -s or --silent flag to suppress output
SILENT=$([[ "$1" == "-s" ]] || [[ "$1" == "--silent" ]] && echo true || echo false)

$SILENT || echo "Installing getnf..."

mkdir -p "$DEST"
rm -f "$GETNFLOC"

if $SILENT; then
    curl -fsSL# https://raw.githubusercontent.com/getnf/getnf/main/getnf --output getnftemp
else
    curl -fL# https://raw.githubusercontent.com/getnf/getnf/main/getnf --output getnftemp
fi

mv getnftemp "$GETNFLOC"
chmod 755 "$GETNFLOC"

$SILENT || echo "${GREEN}Installation finished${RESET}"
