#!/usr/bin/env bash

# shellcheck disable=SC2155

readonly DEST="$HOME/.local/bin"
readonly GETNFLOC="$DEST/getnf"

if command -v tput > /dev/null; then
    readonly GREEN=$(tput setaf 2)
    readonly RESET=$(tput sgr0)
fi

SILENT='false'
BRANCH='main'

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s | --silent) readonly SILENT='true' ;;
        -b | --branch)
            if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
                readonly BRANCH="$2"
                shift
            else
                echo "Option --branch requires an argument"
                exit 1
            fi
            ;;
        --branch=?*)
            readonly BRANCH="${1#*=}"
            ;;
        *) echo "Invalid argument: $1" && exit 1 ;;
    esac
    shift
done

if [[ "$BRANCH" != "main" && ! "$BRANCH" =~ ^release-0\.[1-9]$ ]]; then
    echo "Branch $BRANCH does not exist."
    exit 1
fi

[[ "$SILENT" == "true" ]] || echo "Installing getnf..."

mkdir -p "$DEST"

if [[ "$SILENT" == "true" ]]; then
    curl -fsSL# "https://raw.githubusercontent.com/getnf/getnf/$BRANCH/getnf" --output getnf.tmp
else
    curl -fL# "https://raw.githubusercontent.com/getnf/getnf/$BRANCH/getnf" --output getnf.tmp
fi

mv -f getnf.tmp "$GETNFLOC"
chmod 755 "$GETNFLOC"

[[ "$SILENT" == "true" ]] || echo "${GREEN}Installation finished${RESET}"
