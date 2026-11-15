#!/usr/bin/env bash
# Restore assets/ from a local bundle or the GitHub Release (tag: assets).
# Env: ASSETS_FORMAT=auto|tar|zip
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"
py="$(command -v python3 || command -v python || command -v py || true)"
[ -n "$py" ] || { echo "error: Python 3.8+ is required" >&2; exit 1; }
exec "$py" "$here/assets.py" --root "$repo" fetch --format "${ASSETS_FORMAT:-auto}" "$@"
