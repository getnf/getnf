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
                printf 'called\n' >> "$case_dir/curl-called"
                [[ " $* " == *' --fail '* && " $* " == *' --show-error '* ]] || return 99
                [[ " $* " == *' --connect-timeout 15 '* &&
                    " $* " == *' --speed-limit 1 '* &&
                    " $* " == *' --speed-time 120 '* &&
                    " $* " == *' --retry 0 '* &&
                    " $* " != *' --max-time '* ]] || return 99
                if [[ "$platform" == Linux ]]; then
                    [[ " $* " == *' --silent '* ]] || return 99
                else
                    [[ " $* " == *' --progress-bar '* ]] || return 99
                fi
                while [[ "$1" != --output ]]; do shift; done
                printf partial > "$2"
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
            RELEASE=vTEST DOWNLOAD_DIR="$case_dir"
            download_font Hack
        ) > "$case_dir/output" 2>&1
        status=$?
        if [[ ! -f "$case_dir/curl-called" ]]; then
            echo "FAIL: $platform/$curl_status did not reach mocked curl" >&2
            cat "$case_dir/output" >&2
            exit 1
        fi
        if [[ $(wc -l < "$case_dir/curl-called") -ne 1 ]]; then
            echo "FAIL: $platform/$curl_status retried curl" >&2
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
    DOWNLOAD_DIR="$case_dir/downloads"
    FONT_DIR="$case_dir/fonts"
    RELEASE=vTEST
    check_dependencies() { mkdir -p "$DOWNLOAD_DIR" "$FONT_DIR" "$FONT_RELEASES_DIR"; }
    get_latest_release_version() { :; }
    get_all_fonts() { ALL_FONTS=(Good Bad Later); }
    curl() {
        local url="${!#}" output
        while [[ "$1" != --output ]]; do shift; done
        output=$2
        if [[ "$url" == */Bad.tar.xz ]]; then
            printf partial > "$output"
            [[ "$scenario" != timeout ]] || return 28
            return 22
        fi
        cp "$fixture/font.tar.xz" "$output"
    }
    sudo() {
        echo 'Unexpected sudo call in download test' >&2
        return 99
    }
    tar() {
        touch "$case_dir/tar-called"
        command tar "$@"
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
    for scenario in success fresh-failure update-failure timeout mixed failed-first; do
        case_dir="$fixture/$scenario-$keep_archives"
        records="$case_dir/data/getnf/releases"
        mkdir -p "$records"
        case "$scenario" in
            success)
                selection=Good
                installed=Good
                expected_status=0
                ;;
            fresh-failure | update-failure | timeout)
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
        mkdir -p "$case_dir/downloads"
        printf 'old archive\n' > "$case_dir/downloads/Bad.tar.xz"
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
        if [[ "$scenario" == timeout ]]; then
            test ! -e "$case_dir/tar-called"
            if [[ "$keep_archives" == true ]]; then
                test -z "$(find "$case_dir/downloads" -name '.getnf-download.*' -print)"
            fi
        fi
        archive_notice="The downloaded font archives can be found in $case_dir/downloads"
        if [[ "$keep_archives" == true ]]; then
            test "$(grep -Fxc "$archive_notice" "$case_dir/stdout")" = 1
            test -d "$case_dir/downloads"
            test "$(cat "$case_dir/downloads/Bad.tar.xz")" = 'old archive'
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

# Private staging must never expose partial data as a completed archive.
# Platform curl/progress paths and CLI retention are covered above. Exercise
# shared staging failures once, and partial/signal cleanup in both retention modes.
platform=Linux
for fixture_case in true-success true-promotion true-directory true-staging \
    false-partial true-partial false-INT true-INT false-TERM true-TERM false-HUP true-HUP; do
    keep=${fixture_case%%-*}
    scenario=${fixture_case#*-}
    case_dir="$fixture/private-$platform-$keep-$scenario"
    mkdir -p "$case_dir"
    set +e
    # Sourced functions invoke these mocks indirectly.
    # shellcheck disable=SC2329,SC2030,SC2031,SC2034
    (
        set -e
        uname() { echo "$platform"; }
        # shellcheck source=/dev/null
        source <(sed '$d' "$script_dir/getnf")
        DOWNLOAD_DIR="$case_dir/downloads"
        KEEP_FONT_ARCHIVES=$keep
        RELEASE=vTEST
        mkdir -p "$DOWNLOAD_DIR"
        printf old > "$DOWNLOAD_DIR/Hack.tar.xz"
        printf unrelated > "$DOWNLOAD_DIR/unrelated"
        trap cleanup EXIT
        trap handle_interrupt INT
        trap handle_termination TERM
        trap handle_hangup HUP
        start_loading_animation() { :; }
        stop_loading_animation() { :; }
        sudo() { return 99; }
        mktemp() {
            if [[ "$scenario" == staging ]]; then
                printf '%s\n' "$case_dir/innocent"
                return 1
            fi
            command mktemp "$@"
        }
        mv() {
            [[ "$scenario" != promotion ]] || return 13
            command mv "$@"
        }
        curl() {
            [[ " $* " != *' --remote-name '* && " $* " != *' --remote-header-name '* ]] || return 99
            while [[ "$1" != --output ]]; do shift; done
            test "$2" != "$DOWNLOAD_DIR/Hack.tar.xz" || return 99
            test -d "${2%/*}" || return 99
            # Only the permission prefix is inspected, never the filename.
            # shellcheck disable=SC2012
            test "$(LC_ALL=C ls -ld "${2%/*}" | cut -c1-10)" = drwx------ || return 99
            printf complete > "$2"
            if [[ "$scenario" != directory ]]; then
                test "$(cat "$DOWNLOAD_DIR/Hack.tar.xz")" = old || return 99
            fi
            case "$scenario" in
                partial) return 22 ;;
                INT | TERM | HUP) kill -s "$scenario" "$BASHPID" ;;
            esac
        }
        mkdir -p "$case_dir/innocent"
        touch "$case_dir/innocent/keep"
        if [[ "$scenario" == directory ]]; then
            rm "$DOWNLOAD_DIR/Hack.tar.xz"
            mkdir "$DOWNLOAD_DIR/Hack.tar.xz"
        fi
        status=0
        download_font Hack || status=$?
        case "$scenario" in
            success)
                test "$status" = 0
                test "$(cat "$DOWNLOAD_DIR/Hack.tar.xz")" = complete
                ;;
            partial) test "$status" = 22 ;;
            promotion) test "$status" = 13 ;;
            directory | staging) test "$status" = 1 ;;
        esac
        test -f "$case_dir/innocent/keep"
        test -z "$(find "$DOWNLOAD_DIR" -name '.getnf-download.*' -print)"
        if [[ "$scenario" != success && "$scenario" != directory ]]; then
            test "$(cat "$DOWNLOAD_DIR/Hack.tar.xz")" = old
        fi
    ) > "$case_dir/output" 2>&1
    status=$?
    set -e
    case "$scenario" in
        INT) expected=130 ;;
        TERM) expected=143 ;;
        HUP) expected=129 ;;
        *) expected=0 ;;
    esac
    if [[ "$status" != "$expected" ]]; then
        cat "$case_dir/output" >&2
        echo "FAIL: $platform/$keep/$scenario status=$status" >&2
        exit 1
    fi
    if [[ "$keep" == true ]]; then
        test -f "$case_dir/downloads/unrelated"
        test -z "$(find "$case_dir/downloads" -name '.getnf-download.*' -print)"
    else
        test ! -e "$case_dir/downloads"
    fi
done
printf 'Download tests passed\n'
