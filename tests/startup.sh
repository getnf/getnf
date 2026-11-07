#!/usr/bin/env bash
# Offline startup failures; privileged paths and sudo stay inside fixtures.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT

for global in false true; do
    for keep in false true; do
        for scenario in download font state sudo; do
            if [[ "$scenario" == sudo && "$global" == false ]]; then continue; fi
            case_dir="$fixture/$global-$keep-$scenario"
            command mkdir -p "$case_dir/home" "$case_dir/sentinel"
            # Mocks are called indirectly by the sourced startup functions.
            # shellcheck disable=SC2329,SC2034
            (
                export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
                # shellcheck source=/dev/null
                source <(sed '$d' "$repo_root/getnf")
                set +e
                get_font_dir() { FONT_DIR="$case_dir/fonts"; }
                verify_internet_access() { return 0; }
                xdg-user-dir() { printf '%s\n' "$case_dir/downloads"; }
                mktemp() {
                    if [[ "$scenario" == download ]]; then
                        # Failed output must never become a cleanup target.
                        printf '%s\n' "$case_dir/sentinel"
                        return 1
                    fi
                    command mkdir -p "$case_dir/temporary"
                    printf '%s\n' "$case_dir/temporary"
                }
                mkdir() {
                    printf '%s\n' "$*" >> "$case_dir/mkdir-log"
                    case "$scenario:$2" in
                        "download:$case_dir/downloads/getnf" | "font:$case_dir/fonts" | "state:$FONT_RELEASES_DIR") return 1 ;;
                    esac
                    command mkdir "$@"
                }
                sudo() {
                    touch "$case_dir/sudo-called"
                    [[ "$scenario" != sudo ]] || return 1
                    [[ "$*" == "mkdir -p $case_dir/fonts" ]] || return 99
                    "$@"
                }
                curl() {
                    touch "$case_dir/unexpected"
                    return 99
                }
                get_latest_release_version() { touch "$case_dir/unexpected"; }
                get_all_fonts() { touch "$case_dir/unexpected"; }
                install_font() { touch "$case_dir/unexpected"; }
                args=(-i Hack)
                [[ "$global" == false ]] || args+=(-g)
                [[ "$keep" == false ]] || args+=(-k)
                main "${args[@]}" > "$case_dir/output" 2>&1
                status=$?
                exit "$status"
            ) && {
                echo "Unexpected startup success: $case_dir" >&2
                exit 1
            }
            test ! -e "$case_dir/unexpected"
            test ! -e "$case_dir/data/getnf/release.txt"
            test ! -e "$case_dir/data/getnf/all_fonts.txt"
            test -d "$case_dir/sentinel"
            grep -q 'Could not create' "$case_dir/output"
            if [[ "$keep" == false ]]; then
                test ! -e "$case_dir/temporary"
            elif [[ "$scenario" != download ]]; then
                test -d "$case_dir/downloads/getnf"
            fi
            if [[ "$scenario" == download ]]; then
                test ! -e "$case_dir/fonts"
                test ! -e "$case_dir/sudo-called"
            fi
            test ! -e "$case_dir/data/getnf/releases"
        done
    done
done
printf 'Startup failure tests passed\n'
