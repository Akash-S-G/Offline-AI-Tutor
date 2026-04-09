#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup_hotspot_ap.sh [wifi_interface] [ssid] [password]
# Example:
#   ./setup_hotspot_ap.sh wlan0 SchoolContent School@1234

WIFI_IFACE="${1:-wlan0}"
SSID="${2:-SchoolContent}"
PASSWORD="${3:-School@1234}"
CONN_NAME="school-content-hotspot"
HOTSPOT_IP_CIDR="192.168.50.1/24"

if ! command -v nmcli >/dev/null 2>&1; then
  echo "nmcli is required. Install NetworkManager first."
  exit 1
fi

if [[ ${#PASSWORD} -lt 8 ]]; then
  echo "Password must be at least 8 characters for WPA2 hotspot."
  exit 1
fi

echo "Creating/updating hotspot connection: ${CONN_NAME}"

# Recreate cleanly so repeated runs are predictable.
if nmcli connection show "${CONN_NAME}" >/dev/null 2>&1; then
  nmcli connection delete "${CONN_NAME}" >/dev/null 2>&1 || true
fi

nmcli device wifi hotspot \
  ifname "${WIFI_IFACE}" \
  con-name "${CONN_NAME}" \
  ssid "${SSID}" \
  password "${PASSWORD}"

# Force deterministic subnet for app default URL (192.168.50.1).
nmcli connection modify "${CONN_NAME}" \
  ipv4.method shared \
  ipv4.addresses "${HOTSPOT_IP_CIDR}" \
  ipv6.method ignore

nmcli connection up "${CONN_NAME}"

echo "Hotspot is up."
echo "SSID: ${SSID}"
echo "Gateway/IP: 192.168.50.1"
echo "Connect student devices to this SSID, then use: http://192.168.50.1:8080/catalog.json"
