#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# hooks/validate-a2ml.sh — Pre-commit hook for A2ML manifest validation
#
# Called by the pre-commit framework with staged .a2ml files as arguments.
# Validates each file for:
#   1. Required identity fields (agent-id, name, or project)
#   2. Version field presence
#   3. SPDX-License-Identifier header
#   4. Attestation block structure (if present)
#
# Exit codes:
#   0 — All files valid
#   1 — Validation errors found

set -euo pipefail

ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# ---------------------------------------------------------------------------
# Validate a single .a2ml file
# ---------------------------------------------------------------------------
validate_file() {
    local file="$1"
    local file_errors=0
    FILES_CHECKED=$((FILES_CHECKED + 1))

    local basename
    basename="$(basename "$file")"
    local is_manifest=false
    if [[ "$basename" == *"AI-MANIFEST"* ]]; then
        is_manifest=true
    fi

    # --- SPDX header (first 10 lines) ---
    local has_spdx=false
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        [[ $line_num -gt 10 ]] && break
        if [[ "$line" == *"SPDX-License-Identifier"* ]]; then
            has_spdx=true
            break
        fi
    done < "$file"

    if [[ "$has_spdx" == "false" ]]; then
        echo "  WARNING: ${file}: Missing SPDX-License-Identifier in first 10 lines"
        WARNINGS=$((WARNINGS + 1))
    fi

    # --- Required identity and version fields ---
    local has_identity=false
    local has_version=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*(agent[-_]id|name|project)[[:space:]]*= ]]; then
            has_identity=true
        fi
        if [[ "$line" =~ ^[[:space:]]*(version|schema_version)[[:space:]]*= ]]; then
            has_version=true
        fi
    done < "$file"

    if [[ "$has_identity" == "false" && "$is_manifest" == "false" ]]; then
        echo "  ERROR: ${file}: Missing required identity field (agent-id, name, or project)"
        file_errors=$((file_errors + 1))
    fi

    if [[ "$has_version" == "false" && "$is_manifest" == "false" ]]; then
        echo "  WARNING: ${file}: Missing version or schema_version field"
        WARNINGS=$((WARNINGS + 1))
    fi

    # --- Attestation block structure ---
    local in_attestation=false
    local attestation_has_content=false
    local attestation_found=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^\[attestation\] ]] || [[ "$line" =~ ^##[[:space:]]+[Aa]ttestation ]]; then
            in_attestation=true
            attestation_found=true
            continue
        fi
        if [[ "$in_attestation" == "true" ]]; then
            if [[ "$line" =~ ^\[.+\] ]] || [[ "$line" =~ ^##[[:space:]] ]]; then
                in_attestation=false
                continue
            fi
            if [[ "$line" =~ (proof|signature|verified|hash)[[:space:]]*= ]]; then
                attestation_has_content=true
            fi
        fi
    done < "$file"

    if [[ "$attestation_found" == "true" && "$attestation_has_content" == "false" ]]; then
        echo "  WARNING: ${file}: Attestation block missing proof/signature/hash fields"
        WARNINGS=$((WARNINGS + 1))
    fi

    ERRORS=$((ERRORS + file_errors))
    return "$file_errors"
}

# ---------------------------------------------------------------------------
# Main: validate all files passed as arguments
# ---------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    echo "No .a2ml files to validate."
    exit 0
fi

echo "Validating ${#} A2ML file(s)..."

for file in "$@"; do
    if [[ -f "$file" ]]; then
        validate_file "$file" || true
    fi
done

echo ""
echo "A2ML validation: ${FILES_CHECKED} files, ${ERRORS} error(s), ${WARNINGS} warning(s)"

if [[ $ERRORS -gt 0 ]]; then
    echo "FAILED: A2ML validation errors found."
    exit 1
fi

exit 0
