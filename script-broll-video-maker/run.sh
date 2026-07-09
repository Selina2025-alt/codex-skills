#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUEST_PATH="${1:?Usage: run.sh <request.json> [workspace] [response.json]}"
WORKSPACE="${2:-$(pwd)}"
RESPONSE_PATH="${3:-}"

if [[ -n "$RESPONSE_PATH" ]]; then
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run.ps1" \
    -RequestPath "$REQUEST_PATH" \
    -Workspace "$WORKSPACE" \
    -ResponsePath "$RESPONSE_PATH"
else
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run.ps1" \
    -RequestPath "$REQUEST_PATH" \
    -Workspace "$WORKSPACE"
fi
