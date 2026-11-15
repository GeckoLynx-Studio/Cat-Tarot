#!/usr/bin/env bash
# Pack, then upload assets.tar.gz + assets.zip to the GitHub Release (tag: assets).
# Requires gh CLI (authenticated) and a GitHub origin remote.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"
py="$(command -v python3 || command -v python || command -v py || true)"
[ -n "$py" ] || { echo "error: Python 3.8+ is required" >&2; exit 1; }
exec "$py" "$here/assets.py" --root "$repo" push
