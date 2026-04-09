# Raspberry Pi Hotspot Workflow (Offline School Mode)

This setup lets nearby devices download materials without school Wi-Fi or internet.

## 1) Prepare content pack + catalog on the Pi

From the project root:

```bash
python3 tools/prepare_school_content.py \
  --textbooks-root /path/to/TEXTBOOKS \
  --output-root /home/pi/school_server \
  --base-url http://192.168.50.1:8080 \
  --version 1
```

Required output:
- `/home/pi/school_server/catalog.json`
- `/home/pi/school_server/packs/*.otpack`

## 2) Start hotspot on Raspberry Pi

```bash
bash tools/pi_hotspot/setup_hotspot_ap.sh wlan0 SchoolContent School@1234
```

This creates a hotspot with gateway IP `192.168.50.1`.

## 3) Start local content server

```bash
bash tools/pi_hotspot/run_school_content_server.sh /home/pi/school_server 8080
```

Catalog URL for the app:
- `http://192.168.50.1:8080/catalog.json`

## 4) Student app steps

- Join Wi-Fi SSID: `SchoolContent`
- Open app -> Content Pack Installer
- In Raspberry Pi Catalog Sync:
  - Tap `Discover Servers` (or keep default URL)
  - Tap `Check Catalog`
  - Tap `Install Missing Required`

## Notes

- Devices must connect to the Pi hotspot SSID to download locally.
- If you need downloads for users *not connected* to Pi hotspot/LAN, use an internet endpoint (VPN/tunnel/public server).
