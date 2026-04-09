#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./run_school_content_server.sh [content_root] [port]
# Example:
#   ./run_school_content_server.sh /home/pi/school_server 8080

CONTENT_ROOT="${1:-$HOME/school_server}"
PORT="${2:-8080}"

if [[ ! -d "${CONTENT_ROOT}" ]]; then
  echo "Content root not found: ${CONTENT_ROOT}"
  exit 1
fi

if [[ ! -f "${CONTENT_ROOT}/catalog.json" ]]; then
  echo "catalog.json is missing in ${CONTENT_ROOT}"
  exit 1
fi

echo "Serving school content from ${CONTENT_ROOT} on port ${PORT}"
cd "${CONTENT_ROOT}"
python3 -m http.server "${PORT}" --bind 0.0.0.0
