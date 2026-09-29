#!/usr/bin/env bash

# Usage: ./start_jupyter.sh [notebook] [classic|lab]

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV="$ROOT/.venv"
MARKER="$VENV/.installed"
NOTEBOOK="${1:-}"
STYLE="${2:-classic}"

if [ "$NOTEBOOK" = "classic" ] || [ "$NOTEBOOK" = "lab" ]; then
    STYLE="$NOTEBOOK"
    NOTEBOOK=""
fi

case "$STYLE" in
    classic) COMMAND="nbclassic" ;;
    lab) COMMAND="lab" ;;
    *) echo "Style must be classic or lab" >&2; exit 1 ;;
esac

# Turn a path from the caller's current directory into an absolute path.
if [ -n "$NOTEBOOK" ]; then
    NOTEBOOK_DIR="$(dirname "$NOTEBOOK")"
    if [ ! -d "$NOTEBOOK_DIR" ]; then
        echo "Notebook folder not found: $NOTEBOOK_DIR" >&2
        exit 1
    fi
    NOTEBOOK="$(cd "$NOTEBOOK_DIR" && pwd)/$(basename "$NOTEBOOK")"
fi

cd "$ROOT"

if command -v sha256sum >/dev/null 2>&1; then
    REQUIREMENTS_HASH="$(sha256sum requirements.txt | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    REQUIREMENTS_HASH="$(shasum -a 256 requirements.txt | awk '{print $1}')"
else
    echo "A SHA-256 tool (sha256sum or shasum) is required" >&2
    exit 1
fi

INSTALLED_HASH=""
if [ -f "$MARKER" ]; then
    INSTALLED_HASH="$(cat "$MARKER")"
fi

# Rebuild the venv when it is missing or its base Python was removed or changed.
if ! "$VENV/bin/python" --version >/dev/null 2>&1; then
    if ! python3 -m venv --clear "$VENV"; then
        echo "Could not create the virtual environment." >&2
        echo "On Debian/Ubuntu install it with: sudo apt install python3-venv" >&2
        exit 1
    fi
    INSTALLED_HASH=""
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "Warning: openssl not found - !openssl cells will fail. Install it or use keys_sample." >&2
fi

if [ "$INSTALLED_HASH" != "$REQUIREMENTS_HASH" ]; then
    "$VENV/bin/python" -m pip install -r requirements.txt
    printf '%s\n' "$REQUIREMENTS_HASH" > "$MARKER"
fi

if [ -n "$NOTEBOOK" ]; then
    "$VENV/bin/jupyter" "$COMMAND" "$NOTEBOOK"
else
    "$VENV/bin/jupyter" "$COMMAND"
fi
