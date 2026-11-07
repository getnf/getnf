#!/usr/bin/env bash
# Offline bootstrap regression checks; all writes stay in private fixtures.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT

# Every line-truncated stream before the final call must have no side effects.
mkdir -p "$fixture/truncated/work"
line_count=$(wc -l < "$repo_root/install.sh")
for ((lines = 1; lines < line_count; lines++)); do
    (
        cd "$fixture/truncated/work"
        head -n "$lines" "$repo_root/install.sh" | HOME="$fixture/truncated/home" bash
    ) > "$fixture/truncated/output" 2>&1 || :
    [[ ! -e "$fixture/truncated/home" ]]
    if grep -q 'Installing getnf' "$fixture/truncated/output"; then exit 1; fi
done

for mode in default silent; do
    for scenario in partial write empty invalid mkdir mktemp chmod replacement directory interrupted success; do
        case_dir="$fixture/$mode-$scenario"
        mkdir -p "$case_dir/home/.local/bin" "$case_dir/work"
        printf '#!/usr/bin/env bash\necho working\n' > "$case_dir/original"
        cp "$case_dir/original" "$case_dir/home/.local/bin/getnf"
        chmod 755 "$case_dir/home/.local/bin/getnf"
        printf '#!/usr/bin/env bash\necho updated\n' > "$case_dir/expected"
        printf 'unrelated\n' > "$case_dir/sentinel"
        ln -s "$case_dir/sentinel" "$case_dir/work/getnf.tmp"
        if [[ "$scenario" == directory ]]; then
            rm "$case_dir/home/.local/bin/getnf"
            mkdir "$case_dir/home/.local/bin/getnf"
            cp "$case_dir/original" "$case_dir/home/.local/bin/getnf/sentinel"
        fi
        # Exported mocks are invoked by the installer subprocess.
        # shellcheck disable=SC2317,SC2329
        (
            export HOME="$case_dir/home"
            cd "$case_dir/work"
            curl() {
                case "$scenario" in
                    partial)
                        printf partial > "${@: -1}"
                        return 22
                        ;;
                    write) return 23 ;;
                    empty) : > "${@: -1}" ;;
                    invalid) printf 'if\n' > "${@: -1}" ;;
                    interrupted)
                        printf partial > "${@: -1}"
                        kill -TERM "$$"
                        ;;
                    *) command cp "$case_dir/expected" "${@: -1}" ;;
                esac
            }
            mkdir() { [[ "$scenario" != mkdir ]] && command mkdir "$@"; }
            mktemp() {
                if [[ "$scenario" == mktemp ]]; then
                    # Failed command output must never become a cleanup target.
                    printf '%s\n' "$case_dir/sentinel"
                    return 1
                fi
                command mktemp "$@"
            }
            chmod() { [[ "$scenario" != chmod ]] && command chmod "$@"; }
            mv() { [[ "$scenario" != replacement ]] && command mv "$@"; }
            # Keep status/output assertions independent of host terminal setup.
            tput() { return 0; }
            sudo() {
                echo 'Unexpected sudo' >&2
                return 99
            }
            export -f curl mkdir mktemp chmod mv sudo tput
            export scenario case_dir
            args=()
            [[ "$mode" != silent ]] || args+=(-s)
            bash "$repo_root/install.sh" "${args[@]}"
        ) > "$case_dir/output" 2>&1 && status=0 || status=$?
        if [[ "$scenario" == success ]]; then
            [[ "$status" == 0 ]]
            cmp "$case_dir/expected" "$case_dir/home/.local/bin/getnf"
            [[ -x "$case_dir/home/.local/bin/getnf" ]]
            if [[ "$mode" == default ]]; then
                grep -q 'Installation finished' "$case_dir/output"
            else
                [[ ! -s "$case_dir/output" ]]
            fi
        else
            [[ "$status" != 0 ]]
            if grep -q 'Installation finished' "$case_dir/output"; then exit 1; fi
            if [[ "$scenario" == directory ]]; then
                cmp "$case_dir/original" "$case_dir/home/.local/bin/getnf/sentinel"
                [[ ! -e "$case_dir/home/.local/bin/getnf/getnf" ]]
            else
                cmp "$case_dir/original" "$case_dir/home/.local/bin/getnf"
                [[ -x "$case_dir/home/.local/bin/getnf" ]]
            fi
        fi
        [[ "$(cat "$case_dir/sentinel")" == unrelated ]]
        [[ -L "$case_dir/work/getnf.tmp" ]]
        [[ -z "$(find "$case_dir/home/.local/bin" -name '.getnf.*' -print)" ]]
    done
done
printf 'Installer safety checks passed\n'
