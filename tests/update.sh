#!/usr/bin/env bash
# Offline update exit statuses; all font paths and privileged calls are isolated.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT

for global in false true; do
    for scenario in empty current success failure metadata-failure; do
        case_dir="$fixture/$global-$scenario"
        mkdir -p "$case_dir/home"
        status=0
        # Mocks are called indirectly by main.
        # shellcheck disable=SC2329,SC2034
        (
            export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
            # shellcheck source=/dev/null
            source <(sed '$d' "$repo_root/getnf")
            check_dependencies() {
                FONT_DIR="$case_dir/fonts"
                DOWN_DIR="$case_dir/downloads"
                mkdir -p "$FONT_DIR" "$DOWN_DIR" "$FONT_RELEASES_DIR"
            }
            get_latest_release_version() {
                [[ "$scenario" != metadata-failure ]] || return 1
                RELEASE=v2.0.0
            }
            get_all_fonts() { ALL_FONTS=(Hack); }
            sudo() {
                touch "$case_dir/unexpected-sudo"
                return 99
            }
            curl() { return 99; }
            install_font() {
                printf '%s\n' "$1" >> "$case_dir/installations"
                [[ "$scenario" != failure ]]
            }
            if [[ "$scenario" != empty && "$scenario" != metadata-failure ]]; then
                mkdir -p "$case_dir/fonts"
                mkdir "$case_dir/fonts/Hack"
                mkdir -p "$FONT_RELEASES_DIR"
                marker="$FONT_RELEASES_DIR/Hack_release.txt"
                [[ "$global" == false ]] || marker="$FONT_RELEASES_DIR/Hack_release.global.txt"
                version=v1.0.0
                [[ "$scenario" != current ]] || version=v2.0.0
                printf '%s\n' "$version" > "$marker"
            fi
            args=(-U)
            [[ "$global" == false ]] || args=(-gU)
            main "${args[@]}"
        ) > "$case_dir/stdout" 2> "$case_dir/stderr" || status=$?
        case "$scenario" in
            failure | metadata-failure) test "$status" -ne 0 ;;
            *) test "$status" -eq 0 ;;
        esac
        test ! -e "$case_dir/unexpected-sudo"
        case "$scenario" in
            empty)
                if [[ "$global" == true ]]; then
                    grep -Fxq 'No globally installed Nerd Fonts found.' "$case_dir/stdout"
                else
                    grep -Fxq 'No installed Nerd Fonts found.' "$case_dir/stdout"
                fi
                test ! -s "$case_dir/stderr"
                test ! -e "$case_dir/installations"
                ;;
            current)
                grep -q 'are up to date.' "$case_dir/stdout"
                test ! -e "$case_dir/installations"
                ;;
            metadata-failure) test ! -e "$case_dir/installations" ;;
            success | failure) test "$(cat "$case_dir/installations")" = Hack ;;
        esac
    done
done
printf 'Update exit-status tests passed\n'
