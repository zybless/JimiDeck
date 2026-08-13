#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FORBIDDEN_PATHS=(
    "$ROOT_DIR/website"
    "$ROOT_DIR/site"
    "$ROOT_DIR/next.config.js"
    "$ROOT_DIR/next.config.mjs"
    "$ROOT_DIR/next.config.ts"
    "$ROOT_DIR/vite.config.js"
    "$ROOT_DIR/vite.config.mjs"
    "$ROOT_DIR/vite.config.ts"
)

for forbidden_path in "${FORBIDDEN_PATHS[@]}"; do
    if [[ -e "$forbidden_path" ]]; then
        printf 'App/website boundary violation: %s\n' "$forbidden_path" >&2
        exit 1
    fi
done

if find "$ROOT_DIR/dist" -type f \( -name 'index.html' -o -name 'og.png' \) -print -quit 2> /dev/null | grep -q .; then
    printf 'App/website boundary violation: website output found under app dist/.\n' >&2
    exit 1
fi

printf 'App/website boundary check passed.\n'
