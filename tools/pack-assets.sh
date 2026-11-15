#!/usr/bin/env bash
# Build assets.tar.gz + assets.zip and refresh assets.sha256.
# Run after changing anything under assets/. Commit the updated assets.sha256.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"
py="$(command -v python3 || command -v python || command -v py || true)"
[ -n "$py" ] || { echo "error: Python 3.8+ is required" >&2; exit 1; }
exec "$py" "$here/assets.py" --root "$repo" pack
