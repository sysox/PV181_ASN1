#!/usr/bin/env bash

# macOS: double-click this file in Finder to start the classic Notebook.
# Terminal runs it from the home folder, so call the launcher by its full path.

exec "$(cd "$(dirname "$0")" && pwd)/start_jupyter.sh" "$@"
