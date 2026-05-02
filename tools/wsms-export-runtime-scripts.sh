#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - EXPORT RUNTIME MODULES FROM INSTALLERS
# Usage: ./tools/wsms-export-runtime-scripts.sh [output_dir] [--only script1,script2,...]
# =================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$REPO_ROOT/scripts/runtime-preview}"
ONLY_LIST=""

if [ "${1:-}" = "--only" ]; then
    OUTPUT_DIR="$REPO_ROOT/scripts/runtime-preview"
    ONLY_LIST="${2:-}"
elif [ "${2:-}" = "--only" ]; then
    ONLY_LIST="${3:-}"
fi

is_selected_module() {
    local module="$1"

    if [ -z "$ONLY_LIST" ]; then
        return 0
    fi

    IFS=',' read -r -a selected <<< "$ONLY_LIST"
    for item in "${selected[@]}"; do
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
}

EN_INSTALLER="$REPO_ROOT/installers/install_wsms.sh"
PL_INSTALLER="$REPO_ROOT/installers/install_wsms_pl.sh"
EN_OUT="$OUTPUT_DIR/en"
PL_OUT="$OUTPUT_DIR/pl"

if [ ! -f "$EN_INSTALLER" ] || [ ! -f "$PL_INSTALLER" ]; then
    echo "ERROR: Installers not found under $REPO_ROOT/installers" >&2
    exit 1
fi

rm -rf "$EN_OUT" "$PL_OUT"

extract_modules "$EN_INSTALLER" "$EN_OUT" "EN"
extract_modules "$PL_INSTALLER" "$PL_OUT" "PL"

echo ""
echo "Export complete"
echo "Output directory: $OUTPUT_DIR"
echo "EN preview: $EN_OUT"
echo "PL preview: $PL_OUT"
