#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. Installing it..."
  sudo apt-get update
  sudo apt-get install -y python3
fi

chmod +x run-web.sh 2>/dev/null || true

cat <<'MSG'
WhiteHolewithASM Codespaces setup complete.

Run the browser version with:

  bash run-web.sh

Then open the forwarded port 8000.
MSG
