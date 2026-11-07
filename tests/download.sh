#!/usr/bin/env bash
# Contract tests for download failures; no network, sudo, or installed fonts.
set -u
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
fixture=$(mktemp -d) || exit 1
trap 'command rm -rf -- "$fixture"' EXIT
failures=0

for platform in Linux Darwin; do
    for curl_status in 0 22 28; do
        case_dir="$fixture/$platform-$curl_status"
        mkdir -p "$case_dir/home" || exit 1
        # Mocks are invoked indirectly by the sourced script.
        # shellcheck disable=SC2329,SC2030
        (
            export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
            uname() { printf '%s\n' "$platform"; }
            # Load functions without running the CLI or its network setup.
            # shellcheck source=/dev/null
            source <(sed '$d' "$script_dir/getnf")
            cd -- "$case_dir" || exit 1
            curl() {
                printf called > "$case_dir/curl-called"
                [[ " $* " == *' --fail '* && " $* " == *' --show-error '* ]] || return 99
                return "$curl_status"
            }
            sudo() {
                echo 'Unexpected sudo call in download test' >&2
                return 99
            }
            # Output/return status are under test; animation mechanics are not.
            start_loading_animation() { touch "$case_dir/animation-active"; }
            stop_loading_animation() { rm -f "$case_dir/animation-active"; }
            # shellcheck disable=SC2034
            RELEASE=vTEST DOWN_DIR="$case_dir"
            download_font Hack
        ) > "$case_dir/output" 2>&1
        status=$?
        if [[ ! -f "$case_dir/curl-called" ]]; then
            echo "FAIL: $platform/$curl_status did not reach mocked curl" >&2
            cat "$case_dir/output" >&2
            exit 1
        fi
        if ((status != curl_status)); then
            echo "FAIL: $platform/curl=$curl_status returned $status" >&2
            failures=$((failures + 1))
        fi
        if ((curl_status == 0)); then
            if ! grep -q Done "$case_dir/output"; then
                echo "FAIL: $platform successful download did not print Done" >&2
                failures=$((failures + 1))
            fi
        elif grep -q Done "$case_dir/output"; then
            echo "FAIL: $platform/curl=$curl_status printed Done" >&2
            failures=$((failures + 1))
        fi
        if [[ -e "$case_dir/animation-active" ]]; then
            echo "FAIL: $platform/curl=$curl_status left the animation running" >&2
            failures=$((failures + 1))
        fi
    done
done
if ((failures > 0)); then
    printf '%d download assertions failed\n' "$failures" >&2
    exit 1
fi

# Exercise the full install path using a real archive and mocked network calls.
set -e
mkdir -p "$fixture/input"
printf 'fixture font\n' > "$fixture/input/font.ttf"
tar -cJf "$fixture/font.tar.xz" -C "$fixture/input" font.ttf

# The sourced main function calls these mocks indirectly.
# shellcheck disable=SC2329,SC2030,SC2031,SC2034
run_cli() (
    export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
    # shellcheck source=/dev/null
    source <(sed '$d' "$script_dir/getnf")
    DOWN_DIR="$case_dir/downloads"
    FONT_DIR="$case_dir/fonts"
    RELEASE=vTEST
    check_dependencies() { mkdir -p "$DOWN_DIR" "$FONT_DIR" "$FONT_RELEASES_DIR"; }
    get_latest_release_version() { :; }
    get_all_fonts() { ALL_FONTS=(Good Bad Later); }
    curl() {
        local url="${!#}"
        [[ "$url" != */Bad.tar.xz ]] || return 22
        cp "$fixture/font.tar.xz" "${url##*/}"
    }
    sudo() {
        echo 'Unexpected sudo call in download test' >&2
        return 99
    }
    start_loading_animation() { :; }
    stop_loading_animation() { :; }
    local main_status=0
    local -a options=(-i "$selection")
    if [[ "$keep_archives" == true ]]; then options=(-k "${options[@]}"); fi
    main "${options[@]}" || main_status=$?
    # Preserve main's result even when it returns instead of exiting.
    [[ "$PWD" == "$start_dir" ]] || exit 1
    exit "$main_status"
)

for keep_archives in false true; do
    for scenario in success fresh-failure update-failure mixed failed-first; do
        case_dir="$fixture/$scenario-$keep_archives"
        records="$case_dir/data/getnf/releases"
        mkdir -p "$records"
        case "$scenario" in
            success)
                selection=Good
                installed=Good
                expected_status=0
                ;;
            fresh-failure | update-failure)
                selection=Bad
                installed=none
                expected_status=1
                ;;
            mixed)
                selection=Good,Bad,Later
                installed='Good Later'
                expected_status=1
                ;;
            failed-first)
                selection=Bad,Later
                installed=Later
                expected_status=1
                ;;
        esac
        if [[ "$scenario" != fresh-failure ]]; then
            mkdir -p "$case_dir/fonts/Bad"
            printf 'old font\n' > "$case_dir/fonts/Bad/old.ttf"
            printf 'vOLD\n' > "$records/Bad_release.txt"
        fi
        start_dir=$PWD
        status=0
        run_cli > "$case_dir/stdout" 2> "$case_dir/stderr" || status=$?
        if ((status != expected_status)); then
            cat "$case_dir/stdout" "$case_dir/stderr" >&2
            echo "FAIL: $scenario returned $status, expected $expected_status" >&2
            exit 1
        fi
        if ((expected_status == 0)); then
            grep -q 'Enjoy your new fonts!' "$case_dir/stdout"
            if [[ -s "$case_dir/stderr" ]]; then
                cat "$case_dir/stderr" >&2
                exit 1
            fi
        else
            grep -Fxq "Installed: $installed" "$case_dir/stdout"
            grep -Fxq 'Failed to install: Bad.' "$case_dir/stderr"
            if grep -q 'Enjoy your new fonts!' "$case_dir/stdout"; then exit 1; fi
        fi
        archive_notice="The downloaded font archives can be found in $case_dir/downloads"
        if [[ "$keep_archives" == true ]]; then
            test "$(grep -Fxc "$archive_notice" "$case_dir/stdout")" = 1
            test -d "$case_dir/downloads"
        else
            if grep -Fq "$archive_notice" "$case_dir/stdout"; then exit 1; fi
            test ! -e "$case_dir/downloads"
        fi
        if [[ "$scenario" == fresh-failure ]]; then
            test ! -e "$case_dir/fonts/Bad"
            test ! -e "$records/Bad_release.txt"
        else
            test "$(cat "$case_dir/fonts/Bad/old.ttf")" = 'old font'
            test "$(cat "$records/Bad_release.txt")" = vOLD
        fi
        for font in Good Later; do
            if [[ " $installed " == *" $font "* ]]; then
                cmp "$fixture/input/font.ttf" "$case_dir/fonts/$font/font.ttf"
                test "$(cat "$records/${font}_release.txt")" = vTEST
                if [[ "$keep_archives" == true ]]; then
                    cmp "$fixture/font.tar.xz" "$case_dir/downloads/$font.tar.xz"
                fi
            else
                test ! -e "$case_dir/fonts/$font"
                test ! -e "$records/${font}_release.txt"
            fi
        done
    done
done

# A failed archive removal must stop before any subsequent installation step.
# Mocks and sourced globals are intentionally confined to this subshell.
# shellcheck disable=SC2329,SC2031,SC2034
(
    case_dir="$fixture/removal-failure"
    export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
    # shellcheck source=/dev/null
    source <(sed '$d' "$script_dir/getnf")
    DOWN_DIR="$case_dir/downloads"
    mkdir -p "$DOWN_DIR" "$FONT_RELEASES_DIR"
    printf 'old archive\n' > "$DOWN_DIR/Bad.tar.xz"
    printf 'vOLD\n' > "$FONT_RELEASES_DIR/Bad_release.txt"
    rm() {
        touch "$case_dir/removal-called"
        return 13
    }
    download_font() { touch "$case_dir/download-called"; }
    extract_font() { touch "$case_dir/extract-called"; }
    save_font_release() { printf 'vTEST\n' > "$FONT_RELEASES_DIR/Bad_release.txt"; }
    status=0
    install_font Bad || status=$?
    test "$status" = 13
    test "$PWD" = "$start_dir"
    test -e "$case_dir/removal-called"
    test ! -e "$case_dir/download-called"
    test ! -e "$case_dir/extract-called"
    test "$(cat "$DOWN_DIR/Bad.tar.xz")" = 'old archive'
    test "$(cat "$FONT_RELEASES_DIR/Bad_release.txt")" = vOLD
)
printf 'Download tests passed\n'
