#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - EXPORT RUNTIME MODULES FROM INSTALLERS
# Usage: ./tools/wsms-export-runtime-scripts.sh [output_dir] [--only script.sh] [--only script2.sh]
#    or: ./tools/wsms-export-runtime-scripts.sh [output_dir] [--only script1.sh,script2.sh,...]
# =================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/scripts/runtime-preview"
declare -a ONLY_ITEMS=()

show_usage() {
    echo "Usage: $0 [output_dir] [--only script.sh] [--only script2.sh]"
    echo "       $0 [output_dir] [--only script1.sh,script2.sh,...]"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    show_usage
    exit 0
fi

args=("$@")
idx=0

if [ ${#args[@]} -gt 0 ] && [ "${args[0]}" != "--only" ]; then
    OUTPUT_DIR="${args[0]}"
    idx=1
fi

while [ $idx -lt ${#args[@]} ]; do
    arg="${args[$idx]}"
    case "$arg" in
        --only)
            idx=$((idx + 1))
            if [ $idx -ge ${#args[@]} ]; then
                echo "ERROR: --only requires a value" >&2
                show_usage >&2
                exit 1
            fi
            IFS=',' read -r -a chunk <<< "${args[$idx]}"
            for item in "${chunk[@]}"; do
                [ -n "$item" ] && ONLY_ITEMS+=("$item")
            done
            ;;
        *)
            echo "ERROR: Unknown argument: $arg" >&2
            show_usage >&2
            exit 1
            ;;
    esac
    idx=$((idx + 1))
done

is_selected_module() {
    local module="$1"

    if [ ${#ONLY_ITEMS[@]} -eq 0 ]; then
        return 0
    fi

    for item in "${ONLY_ITEMS[@]}"; do
        [ "$item" = "$module" ] && return 0
    done

    return 1
}

extract_modules() {
    local installer_path="$1"
    local target_dir="$2"
    local label="$3"

    local current_file=""
    local terminator=""
    local temp_body=""
    local count=0

    mkdir -p "$target_dir"

    while IFS= read -r line || [ -n "$line" ]; do
        if [ -z "$current_file" ]; then
            if [[ "$line" == deploy\ \"* ]] && [[ "$line" == *"<<"* ]]; then
                current_file="${line#deploy \"}"
                current_file="${current_file%%\"*}"

                terminator="${line##*<< }"
                terminator="${terminator#\'}"
                terminator="${terminator%\'}"

                if [ -n "$current_file" ] && [ -n "$terminator" ]; then
                    temp_body="$(mktemp)"
                    continue
                fi
            fi
        else
            if [ "$line" = "$terminator" ]; then
                if is_selected_module "$current_file"; then
                    mv "$temp_body" "$target_dir/$current_file"
                    chmod +x "$target_dir/$current_file" 2> /dev/null || true
                    count=$((count + 1))
                else
                    rm -f "$temp_body"
                fi
                current_file=""
                terminator=""
                temp_body=""
            else
                printf '%s\n' "$line" >> "$temp_body"
            fi
        fi
    done < "$installer_path"

    if [ -n "$current_file" ]; then
        echo "ERROR: Unterminated heredoc while parsing $installer_path" >&2
        [ -n "$temp_body" ] && rm -f "$temp_body"
        exit 1
    fi

    echo "$label modules exported: $count"
    EXPORTED_COUNT=$((EXPORTED_COUNT + count))
}

EN_INSTALLER="$REPO_ROOT/installers/install_wsms.sh"
PL_INSTALLER="$REPO_ROOT/installers/install_wsms_pl.sh"
EN_OUT="$OUTPUT_DIR/en"
PL_OUT="$OUTPUT_DIR/pl"
EXPORTED_COUNT=0

if [ ! -f "$EN_INSTALLER" ] || [ ! -f "$PL_INSTALLER" ]; then
    echo "ERROR: Installers not found under $REPO_ROOT/installers" >&2
    exit 1
fi

if [ -z "$EN_OUT" ] || [ -z "$PL_OUT" ] || [ "$EN_OUT" = "/" ] || [ "$PL_OUT" = "/" ]; then
    echo "ERROR: Output paths are invalid: EN=$EN_OUT PL=$PL_OUT" >&2
    exit 1
fi

rm -rf "$EN_OUT" "$PL_OUT"

extract_modules "$EN_INSTALLER" "$EN_OUT" "EN"
extract_modules "$PL_INSTALLER" "$PL_OUT" "PL"

if [ ${#ONLY_ITEMS[@]} -gt 0 ] && [ "$EXPORTED_COUNT" -eq 0 ]; then
    echo "ERROR: No modules matched selection: ${ONLY_ITEMS[*]}" >&2
    exit 1
fi

echo ""
echo "Export complete"
echo "Output directory: $OUTPUT_DIR"
echo "EN preview: $EN_OUT"
echo "PL preview: $PL_OUT"
