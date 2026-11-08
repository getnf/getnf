#!/usr/bin/env bash
# Offline marker persistence and reporting; sudo only touches fixture paths.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT

for global in false true; do
    for scenario in success stage failed-stage-output write rename directory; do
        # These functions are called indirectly by the sourced main.
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
            command mkdir -p "$FONT_DIR" "$DOWN_DIR" "$FONT_RELEASES_DIR"
            marker=$(get_font_release_file Hack)
            other="$FONT_RELEASES_DIR/Hack_release.global.txt"
            [[ "$global" != true ]] || other="$FONT_RELEASES_DIR/Hack_release.txt"
            printf 'other scope\n' > "$other"
            printf 'vOLD\n' > "$marker"
            if [[ "$scenario" == directory ]]; then
                command rm "$marker"
                command mkdir "$marker"
                printf 'keep\n' > "$marker/keep"
            fi
            printf 'unrelated\n' > "$case_dir/sentinel"
            check_dependencies() { :; }
            get_latest_release_version() { :; }
            get_all_fonts() { ALL_FONTS=(Hack Good); }
            download_font() { echo "Downloading $1"; }
            tar() {
                # Simulate extraction changing installed files before marker persistence.
                printf 'new font\n' > "$FONT_DIR/${2%.tar.xz}/font.ttf"
            }
            sudo() {
                printf 'sudo\n' >> "$case_dir/sudo-called"
                case "$1" in mkdir | tar) ;; *) return 99 ;; esac
                local arg
                for arg in "$@"; do
                    case "$arg" in /*) [[ "$arg" == "$case_dir"/* ]] || return 99 ;; esac
                done
                "$@"
            }
            mktemp() {
                if [[ "$1" == "$marker".tmp.* ]]; then
                    case "$scenario" in
                        stage) return 1 ;;
                        failed-stage-output)
                            printf '%s\n' "$case_dir/sentinel"
                            return 1
                            ;;
                    esac
                fi
                command mktemp "$@"
            }
            printf() {
                if [[ "$scenario" == write && "${temporary:-}" == "$marker".tmp.* ]]; then
                    # Simulate a partial write followed by failure.
                    builtin printf partial
                    return 1
                fi
                # Forward other calls unchanged.
                # shellcheck disable=SC2059
                builtin printf "$@"
            }
            mv() {
                if [[ "${*: -1}" == "$marker" ]]; then
                    [[ "$scenario" != rename ]] || return 1
                    # The family must not have been announced installed yet.
                    if grep -q 'Installing Hack.*Done' "$case_dir/output"; then return 99; fi
                fi
                command mv "$@"
            }
            confirm() {
                if [[ "$1" == Done ]]; then
                    # main supplies the current family through its local font.
                    # shellcheck disable=SC2154
                    test "$(cat "$(get_font_release_file "$font")")" = vTEST || return 99
                fi
                echo "$1"
            }
            status=0
            args=(-i 'Hack Good')
            [[ "$global" != true ]] || args+=(-g)
            (main "${args[@]}") > "$case_dir/output" 2>&1 || status=$?
            if [[ "$scenario" == success ]]; then
                if [[ "$status" != 0 ]]; then
                    cat "$case_dir/output"
                    exit 1
                fi
                grep -q 'Installing Hack.*Done' "$case_dir/output"
                test "$(cat "$marker")" = vTEST
            else
                test "$status" != 0
                if grep -q 'Installing Hack.*Done' "$case_dir/output"; then exit 1; fi
                if grep -q 'Enjoy your new fonts!' "$case_dir/output"; then exit 1; fi
                grep -q 'Failed to install: Hack' "$case_dir/output"
                grep -q 'Installed: Good' "$case_dir/output"
                if [[ "$scenario" == directory ]]; then
                    test "$(cat "$marker/keep")" = keep
                    test "$(find "$marker" -type f | wc -l)" -eq 1
                else
                    test "$(cat "$marker")" = vOLD
                fi
            fi
            test "$(cat "$FONT_DIR/Hack/font.ttf")" = 'new font'
            test "$(cat "$other")" = 'other scope'
            test "$(cat "$case_dir/sentinel")" = unrelated
            test -z "$(find "$FONT_RELEASES_DIR" -name '*.tmp.*' -print)"
            if [[ "$global" == true ]]; then test -s "$case_dir/sudo-called"; fi
        )
    done
done
printf 'Marker persistence tests passed\n'
