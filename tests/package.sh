#!/usr/bin/env bash
# Runs inside the installed-package test container; EXPECTED_TAG comes from Make.
set -euo pipefail

command -v getnf
test -x /usr/bin/getnf
actual="$(getnf -V)"
expected="getnf $EXPECTED_TAG"
if [[ "$actual" != "$expected" ]]; then
    printf 'Version mismatch: expected <%s>, got <%s>\n' \
        "$expected" "$actual" >&2
    exit 1
fi
getnf -h > /tmp/getnf-help.txt
if ! grep -q 'Usage:' /tmp/getnf-help.txt; then
    echo 'Unexpected help output:' >&2
    cat /tmp/getnf-help.txt >&2
    exit 1
fi
for file in \
    /usr/share/doc/getnf/README.md \
    /usr/share/doc/getnf/LICENSE \
    /usr/share/man/man1/getnf.1.gz; do
    if [[ ! -r "$file" ]]; then
        printf 'Missing or unreadable file: %s\n' "$file" >&2
        exit 1
    fi
done
gzip -t /usr/share/man/man1/getnf.1.gz
