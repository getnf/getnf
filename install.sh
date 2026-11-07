#!/usr/bin/env bash

# shellcheck disable=SC2155

# Defer execution until a streamed installer reaches the final call.
main() {
    readonly DEST="$HOME/.local/bin"
    readonly GETNFLOC="$DEST/getnf"

    if command -v tput > /dev/null; then
        readonly GREEN=$(tput setaf 2)
        readonly RESET=$(tput sgr0)
    fi

    SILENT='false'
    TAG='main'

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s | --silent) readonly SILENT='true' ;;
            -t | --tag)
                if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
                    readonly TAG="$2"
                    shift
                else
                    echo "Option --tag requires an argument"
                    exit 1
                fi
                ;;
            --tag=?*)
                readonly TAG="${1#*=}"
                ;;
            *) echo "Invalid argument: $1" && exit 1 ;;
        esac
        shift
    done

    if [[ "$TAG" != "main" && ! "$TAG" =~ ^v0\.[1-9]\.[0-9]+$ ]]; then
        echo "Tag $TAG does not exist."
        exit 1
    fi

    [[ "$SILENT" == "true" ]] || echo "Installing getnf..."

    fail() {
        echo "Installation failed: $*" >&2
        exit 1
    }

    mkdir -p "$DEST" || fail "cannot create $DEST"
    # Stage on the destination filesystem so the final rename is atomic.
    staging=''
    # Invoked by the EXIT trap.
    # shellcheck disable=SC2329
    cleanup() {
        [[ -z "$staging" ]] || rm -rf -- "$staging"
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    if ! staging=$(mktemp -d "$DEST/.getnf.XXXXXX"); then
        staging=''
        fail "cannot create download staging directory"
    fi
    download="$staging/getnf"

    if [[ "$SILENT" == "true" ]]; then
        curl -fsSL# "https://raw.githubusercontent.com/getnf/getnf/$TAG/getnf" --output "$download" || fail "download failed"
    else
        curl -fL# "https://raw.githubusercontent.com/getnf/getnf/$TAG/getnf" --output "$download" || fail "download failed"
    fi

    if [[ ! -s "$download" ]] || ! bash -n "$download"; then
        fail "download is not a valid nonempty Bash script"
    fi
    chmod 755 "$download" || fail "cannot prepare executable permissions"
    # mv treats directory destinations specially; never install inside one.
    [[ ! -d "$GETNFLOC" ]] || fail "$GETNFLOC is a directory"
    mv -f "$download" "$GETNFLOC" || fail "cannot replace $GETNFLOC"

    if [[ "$SILENT" != "true" ]]; then
        echo "${GREEN}Installation finished${RESET}"
    fi
    exit 0
}

main "$@"
