#!/usr/bin/env bash
# Run from the repository root: bash tests/uninstall-safety.sh
set -euo pipefail
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT
export HOME="$fixture/home" XDG_DATA_HOME="$fixture/data"
export TEST_ROOT="$fixture"
fonts="$HOME/.local/share/fonts"
records="$XDG_DATA_HOME/getnf/releases"
mkdir -p "$fonts/Hack" "$records" "$fonts/../victim"
touch "$fonts/Hack/keep" "$records/Hack_release.txt" "$fonts/../victim/keep"
# Redirect global fonts in a test copy; sudo must never touch system paths.
sed -e "s|/usr/local/share/fonts|$fixture/global|g" \
    -e "s|/Library/Fonts|$fixture/global|g" getnf > "$fixture/getnf"
uname() { echo Linux; }
curl() {
    touch "$TEST_ROOT/network"
    return 1
}
sudo() {
    touch "$TEST_ROOT/sudo"
    "$@"
}
rm() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -*) ;;
            "$TEST_ROOT"/*) ;;
            *)
                echo "Unsafe test removal: $arg" >&2
                return 1
                ;;
        esac
        [[ "$arg" != "${FAIL_REMOVE:-}" ]] || return 1
    done
    command rm "$@"
}
export -f uname curl sudo rm
expect_failure() {
    if bash "$TEST_ROOT/getnf" "$@" > "$TEST_ROOT/output" 2>&1; then
        echo "Unexpected success: $*" >&2
        exit 1
    fi
    ! grep -q Done "$TEST_ROOT/output"
}

# Invalid selections must leave the valid family and sibling untouched.
cd "$fixture"
touch Hack # Make wildcard expansion observable.
for invalid in '../victim' . .. '*' 'H?ck' Missing '' ' ' 'Hack,' \
    'Hack,,Other' $'Hack\nOther' 'Hack/other'; do
    expect_failure -u "Hack,$invalid"
    test -f "$fonts/Hack/keep"
    test -f "$records/Hack_release.txt"
    test -f "$fonts/../victim/keep"
done
expect_failure -u ''
mkdir "$fonts/Unmanaged"
expect_failure -u Unmanaged

# Failed removal must retain the saved record and never print Done.
export FAIL_REMOVE="$fonts/Hack"
expect_failure -u Hack
test -f "$fonts/Hack/keep"
test -f "$records/Hack_release.txt"
unset FAIL_REMOVE

# Both separators work without a catalog, including a retired family name.
for font in RetiredFamily Other; do
    mkdir "$fonts/$font"
    touch "$records/${font}_release.txt"
done
bash "$fixture/getnf" -u 'Hack, RetiredFamily Other'
for font in Hack RetiredFamily Other; do
    test ! -d "$fonts/$font"
    test ! -f "$records/${font}_release.txt"
done

# All global option orders must leave the user's copy alone.
mkdir "$fonts/Hack"
touch "$records/Hack_release.txt"
for order in before after grouped; do
    mkdir -p "$fixture/global/Hack"
    touch "$records/Hack_release.global.txt"
    case "$order" in
        before) bash "$fixture/getnf" -g -u Hack ;;
        after) bash "$fixture/getnf" -u Hack -g ;;
        grouped) bash "$fixture/getnf" -gu Hack ;;
    esac
    test ! -d "$fixture/global/Hack"
    test ! -f "$records/Hack_release.global.txt"
    test -d "$fonts/Hack"
    test -f "$records/Hack_release.txt"
done
test -f "$fixture/sudo"
test ! -e "$fixture/network"
