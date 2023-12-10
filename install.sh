#!/usr/bin/env bash

DEST="$HOME/.local/bin"
GETNFLOC="$DEST/getnf"

GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

echo "${BLUE}Installing getnf...${RESET}"

mkdir -p "$DEST"
rm -f "$GETNFLOC"
curl -fLO# https://raw.githubusercontent.com/ronniedroid/getnf/master/getnf --output-dir "$DEST"
chmod 755 "$GETNFLOC"

echo "${GREEN}Installation finished${RESET}"
