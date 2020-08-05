#!/bin/bash

OUTDIR="$HOME/.local/bin/"
[ -e "$OUTDIR" ] || mkdir -p $OUTDIR
state1=$(ls -1 "$OUTDIR" | grep -E "getnf")
CurrentDIR=$(pwd)
PCurrentDir=$(echo "$CurrentDIR")

[ -n "$state1" ] && rm "$OUTDIR"getnf

cp "$PCurrentDir"/getnf "$OUTDIR"

