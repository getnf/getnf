#!/usr/bin/env bash
# Offline extraction checks; all files and mocked sudo operations stay in fixtures.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/input"
printf 'fixture font\n' > "$fixture/input/font.ttf"
tar -cJf "$fixture/font.tar.xz" -C "$fixture/input" font.ttf

# A large second member lets both GNU and BSD tar extract the first member
# before discovering the truncated compressed stream. Random data prevents the
# payload from compressing into a single small decoder buffer.
dd if=/dev/urandom of="$fixture/input/payload" bs=1024 count=256 2> /dev/null
tar -cJf "$fixture/large.tar.xz" -C "$fixture/input" font.ttf payload
archive_size=$(wc -c < "$fixture/large.tar.xz")
head -c "$((archive_size / 2))" "$fixture/large.tar.xz" > "$fixture/truncated.tar.xz"
mkdir "$fixture/reproduction"
printf 'old font\n' > "$fixture/reproduction/font.ttf"
if tar -xf "$fixture/truncated.tar.xz" -C "$fixture/reproduction" 2> "$fixture/reproduction-error"; then
    echo 'FAIL: truncated fixture extracted successfully' >&2
    exit 1
fi
cmp "$fixture/input/font.ttf" "$fixture/reproduction/font.ttf"
printf 'Reproduced: truncated archive overwrote an installed file before tar failed\n'

for keep in false true; do
    for existing in false true; do
        for global in false true; do
            for scenario in success mkdir-failure tar-failure corrupt-archive truncated-archive sudo-failure; do
                if [[ "$global" == false && "$scenario" == sudo-failure ]]; then continue; fi
                case "$scenario" in
                    corrupt-archive | truncated-archive) ;;
                    *) [[ "$keep" == false && "$existing" == false ]] || continue ;;
                esac
                # The sourced installation functions invoke these mocks indirectly.
                # shellcheck disable=SC2329,SC2034
                (
                    case_dir="$fixture/$keep-$existing-$global-$scenario"
                    export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
                    # shellcheck source=/dev/null
                    source <(sed '$d' "$repo_root/getnf")
                    FONT_DIR="$case_dir/fonts"
                    DOWNLOAD_DIR="$case_dir/downloads"
                    OPERATE_GLOBALLY="$global"
                    KEEP_FONT_ARCHIVES="$keep"
                    RELEASE=vTEST
                    marker=$(get_font_release_file Hack)
                    command mkdir -p "$FONT_DIR" "$DOWNLOAD_DIR" "$FONT_RELEASES_DIR"
                    if [[ "$existing" == true && ("$scenario" == corrupt-archive || "$scenario" == truncated-archive) ]]; then
                        command mkdir -p "$FONT_DIR/Hack"
                        printf 'old font\n' > "$FONT_DIR/Hack/font.ttf"
                        printf 'vOLD\n' > "$marker"
                    fi
                    download_font() {
                        if [[ "$scenario" == corrupt-archive || "$scenario" == truncated-archive ]]; then
                            if [[ "$scenario" == truncated-archive ]]; then
                                cp "$fixture/truncated.tar.xz" "$DOWNLOAD_DIR/Hack.tar.xz"
                            else
                                printf 'not an archive\n' > "$DOWNLOAD_DIR/Hack.tar.xz"
                            fi
                        else
                            cp "$fixture/font.tar.xz" "$DOWNLOAD_DIR/Hack.tar.xz"
                        fi
                    }
                    mkdir() {
                        touch "$case_dir/mkdir-called"
                        [[ "$scenario" != mkdir-failure ]] || return 13
                        command mkdir "$@"
                    }
                    tar() {
                        touch "$case_dir/tar-called"
                        [[ "$1" != -xf ]] || touch "$case_dir/extraction-called"
                        [[ "$scenario" != tar-failure || "$1" != -xf ]] || return 2
                        command tar "$@"
                    }
                    sudo() {
                        touch "$case_dir/sudo-called"
                        [[ "$scenario" != sudo-failure ]] || return 1
                        case "$1" in mkdir | tar) ;; *) return 99 ;; esac
                        local arg
                        for arg in "$@"; do
                            case "$arg" in /*) [[ "$arg" == "$case_dir"/* ]] || return 99 ;; esac
                        done
                        "$@"
                    }
                    curl() {
                        echo 'Unexpected network request' >&2
                        return 99
                    }
                    start_dir=$PWD
                    status=0
                    install_font Hack > "$case_dir/output" 2>&1 || status=$?
                    test "$PWD" = "$start_dir"
                    if [[ "$scenario" == success ]]; then
                        test "$status" = 0
                        grep -q Done "$case_dir/output"
                        cmp "$fixture/input/font.ttf" "$FONT_DIR/Hack/font.ttf"
                        test "$(cat "$marker")" = vTEST
                    else
                        if ((status == 0)); then
                            echo "FAIL: global=$global/$scenario returned success" >&2
                            exit 1
                        fi
                        if grep -q Done "$case_dir/output"; then exit 1; fi
                        if [[ "$scenario" == corrupt-archive || "$scenario" == truncated-archive ]]; then
                            if [[ "$existing" == true ]]; then
                                test "$(cat "$marker")" = vOLD
                                test "$(cat "$FONT_DIR/Hack/font.ttf")" = 'old font'
                            else
                                test ! -e "$marker"
                                test ! -e "$FONT_DIR/Hack"
                            fi
                            cleanup
                            if [[ "$keep" == true ]]; then
                                test -f "$DOWNLOAD_DIR/Hack.tar.xz"
                            else
                                test ! -e "$DOWNLOAD_DIR"
                            fi
                        else
                            test ! -e "$marker"
                        fi
                    fi
                    case "$scenario" in
                        mkdir-failure)
                            test "$status" = 13
                            test ! -e "$case_dir/extraction-called"
                            ;;
                        sudo-failure)
                            test "$status" = 1
                            test ! -e "$case_dir/mkdir-called"
                            test ! -e "$case_dir/extraction-called"
                            ;;
                        corrupt-archive | truncated-archive)
                            test ! -e "$case_dir/mkdir-called"
                            test ! -e "$case_dir/extraction-called"
                            test -e "$case_dir/tar-called"
                            grep -q 'Cannot read archive for Hack' "$case_dir/output"
                            ;;
                        *)
                            test -e "$case_dir/mkdir-called"
                            test -e "$case_dir/tar-called"
                            ;;
                    esac
                    if [[ "$global" == true && "$scenario" != corrupt-archive && "$scenario" != truncated-archive ]]; then
                        test -e "$case_dir/sudo-called"
                    else
                        test ! -e "$case_dir/sudo-called"
                    fi
                )
            done
        done
    done
done
printf 'Extraction tests passed\n'
