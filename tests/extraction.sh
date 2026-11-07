#!/usr/bin/env bash
# Offline extraction checks; all files and mocked sudo operations stay in fixtures.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/input"
printf 'fixture font\n' > "$fixture/input/font.ttf"
tar -cJf "$fixture/font.tar.xz" -C "$fixture/input" font.ttf

for global in false true; do
    for scenario in success mkdir-failure tar-failure corrupt-archive sudo-failure; do
        if [[ "$global" == false && "$scenario" == sudo-failure ]]; then continue; fi
        # The sourced installation functions invoke these mocks indirectly.
        # shellcheck disable=SC2329,SC2034
        (
            case_dir="$fixture/$global-$scenario"
            export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
            # shellcheck source=/dev/null
            source <(sed '$d' "$repo_root/getnf")
            FONT_DIR="$case_dir/fonts"
            DOWN_DIR="$case_dir/downloads"
            OPERATE_GLOBALLY="$global"
            RELEASE=vTEST
            marker=$(get_font_release_file Hack)
            command mkdir -p "$FONT_DIR" "$DOWN_DIR" "$FONT_RELEASES_DIR"
            if [[ "$scenario" == corrupt-archive ]]; then
                command mkdir -p "$FONT_DIR/Hack"
                printf 'old font\n' > "$FONT_DIR/Hack/old.ttf"
                printf 'vOLD\n' > "$marker"
            fi
            download_font() {
                if [[ "$scenario" == corrupt-archive ]]; then
                    printf 'not an archive\n' > "$DOWN_DIR/Hack.tar.xz"
                else
                    cp "$fixture/font.tar.xz" "$DOWN_DIR/Hack.tar.xz"
                fi
            }
            mkdir() {
                touch "$case_dir/mkdir-called"
                [[ "$scenario" != mkdir-failure ]] || return 13
                command mkdir "$@"
            }
            tar() {
                touch "$case_dir/tar-called"
                [[ "$scenario" != tar-failure ]] || return 2
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
                if [[ "$scenario" == corrupt-archive ]]; then
                    test "$(cat "$marker")" = vOLD
                    test "$(cat "$FONT_DIR/Hack/old.ttf")" = 'old font'
                else
                    test ! -e "$marker"
                fi
            fi
            case "$scenario" in
                mkdir-failure)
                    test "$status" = 13
                    test ! -e "$case_dir/tar-called"
                    ;;
                sudo-failure)
                    test "$status" = 1
                    test ! -e "$case_dir/mkdir-called"
                    test ! -e "$case_dir/tar-called"
                    ;;
                *)
                    test -e "$case_dir/mkdir-called"
                    test -e "$case_dir/tar-called"
                    ;;
            esac
            if [[ "$global" == true ]]; then
                test -e "$case_dir/sudo-called"
            else
                test ! -e "$case_dir/sudo-called"
            fi
        )
    done
done
printf 'Extraction tests passed\n'
