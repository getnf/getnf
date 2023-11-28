#!/usr/bin/env bash

DEST="$HOME/.local/bin"
GETNFLOC="$DEST/getnf"

# -p will not error if the directory already exists
mkdir -p "$DEST"

rm -f "$GETNFLOC"

# -f: fail fast with no output at all on server errors
# -s: be silent
# -S: but show an error message if it fails
# -L: follow redirects
# -O: write output to a local file named like the remote file
curl -fsSLO https://raw.githubusercontent.com/ronniedroid/getnf/master/getnf --output-dir "$DEST"

# make the script executable
chmod 755 "$GETNFLOC"
