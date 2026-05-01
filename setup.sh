#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
WhiteHolewithASM Codespaces setup

This repository contains the original Windows x64 Assembly/OpenGL build plus a
browser-friendly WebGL preview for GitHub Codespaces.

Run the browser version with:

  ./run-web.sh

Then open the forwarded port 8000.
MSG

chmod +x run-web.sh 2>/dev/null || true
