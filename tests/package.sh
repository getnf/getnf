#!/usr/bin/env bash
# Runs inside the installed-package test container; EXPECTED_TAG comes from Make.
set -euo pipefail

expected_version=${EXPECTED_TAG#v}
if command -v dpkg-query > /dev/null; then
    metadata=$(dpkg-query -W -f='${Version} ${Architecture}' getnf)
    expected_metadata="$expected_version all"
elif command -v rpm > /dev/null; then
    metadata=$(rpm -q --qf '%{VERSION}-%{RELEASE} %{ARCH}' getnf)
    expected_metadata="$expected_version-1 noarch"
else
    echo 'No supported package manager found for metadata checks' >&2
    exit 1
fi
if [[ "$metadata" != "$expected_metadata" ]]; then
    printf 'Package metadata mismatch: expected <%s>, got <%s>\n' \
        "$expected_metadata" "$metadata" >&2
    exit 1
fi

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
