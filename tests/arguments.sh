#!/usr/bin/env bash
# Run from the repository root: bash tests/arguments.sh
set -euo pipefail

fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT

bash getnf -h > "$fixture/help" 2> "$fixture/stderr"
test -s "$fixture/help"
test ! -s "$fixture/stderr"

expect_usage_error() {
    local message="$1" status=0
    shift
    bash getnf "$@" > "$fixture/stdout" 2> "$fixture/stderr" || status=$?
    if [[ "$status" != 1 ]]; then
        printf 'Expected exit status 1 for <%s>, got %s\n' "$*" "$status" >&2
        exit 1
    fi
    test ! -s "$fixture/stdout"
    printf '%s\n\n' "$message" > "$fixture/expected"
    cat "$fixture/help" >> "$fixture/expected"
    diff -u "$fixture/expected" "$fixture/stderr"
}

expect_usage_error 'Unknown option: -x' -x
expect_usage_error 'Unknown option: -x' -gx
expect_usage_error "Option '-i' requires at least one font name." -i
expect_usage_error "Option '-u' requires at least one font name." -u
expect_usage_error 'Unexpected argument: Other. Quote multiple font names.' -u Hack Other
