#!/usr/bin/env bash
# Offline metadata failures and recovery, with no installed-font access.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'command rm -rf -- "$fixture"' EXIT

for endpoint in release catalog; do
    for scenario in http404 http429 http500 transport empty error malformed unusable stage write rename; do
        case_dir="$fixture/$endpoint-$scenario"
        mkdir -p "$case_dir/home"
        # Functions below are invoked indirectly by main.
        # shellcheck disable=SC2329,SC2034
        (
            export HOME="$case_dir/home" XDG_DATA_HOME="$case_dir/data"
            # shellcheck source=/dev/null
            source <(sed '$d' "$repo_root/getnf")
            mkdir -p "$GETNF_DIR"
            printf 'v1.0.0\n' > "$RELEASE_FILE"
            printf 'OldFont\n' > "$ALL_FONTS_FILE"
            failing=true
            check_dependencies() { return 0; }
            sudo() {
                touch "$case_dir/unexpected"
                return 99
            }
            install_font() { touch "$case_dir/unexpected"; }
            get_installed_fonts() { touch "$case_dir/unexpected"; }
            curl() {
                [[ "$*" == *--fail* ]] || return 99
                local target=catalog
                [[ "$*" != */latest ]] || target=release
                if [[ "$failing" == true && "$endpoint" == "$target" ]]; then
                    case "$scenario" in
                        http*)
                            printf '{"message":"HTTP error"}'
                            return 22
                            ;;
                        transport)
                            printf '{"tag_name":"v2.0.0","name":"Hack"}'
                            return 28
                            ;;
                        empty) return 0 ;;
                        malformed)
                            printf "not JSON"
                            return 0
                            ;;
                        error)
                            printf '{"message":"API error"}'
                            return 0
                            ;;
                        unusable)
                            printf '{"tag_name":"../bad","name":"../bad"}'
                            return 0
                            ;;
                    esac
                fi
                if [[ "$target" == release ]]; then
                    printf '{"tag_name":"v2.0.0"}'
                else
                    printf '[{"name":"Hack"},{"name":"FiraCode"}]'
                fi
            }
            failure_path="$RELEASE_FILE"
            [[ "$endpoint" != catalog ]] || failure_path="$ALL_FONTS_FILE"
            mktemp() {
                if [[ "$failing" == true && "$1" == "$failure_path".tmp.* ]]; then
                    case "$scenario" in
                        stage) return 1 ;;
                        write)
                            command mkdir -p "$case_dir/write-target"
                            printf '%s\n' "$case_dir/write-target"
                            return 0
                            ;;
                    esac
                fi
                command mktemp "$@"
            }
            mv() {
                if [[ "$failing" == true && "$scenario" == rename && "${*: -1}" == "$failure_path" ]]; then return 1; fi
                command mv "$@"
            }
            if main -i Hack > "$case_dir/output" 2>&1; then
                echo "Unexpected metadata success: $endpoint/$scenario" >&2
                exit 1
            fi
            test ! -e "$case_dir/unexpected"
            test "$(cat "$RELEASE_FILE")" = v1.0.0
            # Catalog promotion precedes marker persistence; marker failures retry it.
            if [[ "$endpoint" == catalog || ! "$scenario" =~ ^(stage|write|rename)$ ]]; then
                test "$(cat "$ALL_FONTS_FILE")" = OldFont
            fi
            failing=false
            get_latest_release_version
            get_all_fonts
            test "$(cat "$RELEASE_FILE")" = v2.0.0
            test "${ALL_FONTS[*]}" = 'Hack FiraCode'
            # A blank existing catalog must refresh even at the current release.
            printf '\n' > "$ALL_FONTS_FILE"
            get_latest_release_version
            get_all_fonts
            test "${ALL_FONTS[*]}" = 'Hack FiraCode'
            # Load exactly the normalized text that passed validation.
            printf Hack > "$ALL_FONTS_FILE"
            get_all_fonts
            test "${#ALL_FONTS[@]}" = 1
            test "${ALL_FONTS[0]}" = Hack
            printf 'Hack\n\n' > "$ALL_FONTS_FILE"
            get_all_fonts
            test "${#ALL_FONTS[@]}" = 1
            test "${ALL_FONTS[0]}" = Hack
            test -z "$(find "$GETNF_DIR" -name '*.tmp.*' -print)"
        )
    done
done
printf 'Metadata failure and recovery tests passed\n'
