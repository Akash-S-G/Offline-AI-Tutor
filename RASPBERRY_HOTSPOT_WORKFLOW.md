# Raspberry Hotspot + Content Sync Workflow

This document covers the implemented app workflow and all commands required to run it on a laptop or Raspberry Pi.

## What Is Implemented

- Content Pack Installer includes:
  - `Discover Servers`
  - `Check Catalog`
  - `Install Missing Required`
  - `Hotspot Health Check`
- Hotspot Health Check reports:
  - Connected SSID
  - Gateway/hotspot reachability checks (TCP + catalog)
  - Catalog reachability
  - Estimated remaining download size/time
- Discovery behavior:
  - Dynamic gateway scanning from active local interfaces
  - Known hotspot gateway defaults (`192.168.50.1`)
  - mDNS discovery where runtime supports it

## Laptop Demo Commands (current machine)

Run from project root:

```bash
cd /home/akash/Desktop/IDP/offline_tutor_app
```

### 1) Build `.otpack` + `catalog.json`

```bash
/home/akash/Desktop/IDP/.venv/bin/python tools/prepare_school_content.py \
  --textbooks-root /home/akash/Desktop/IDP/TEXTBOOKS \
  --output-root /home/akash/Desktop/IDP/school_server \
  --base-url http://10.52.199.193:8080 \
  --version 1
```

### 2) Start local content server

```bash
cd /home/akash/Desktop/IDP/school_server
/home/akash/Desktop/IDP/.venv/bin/python -m http.server 8080 --bind 0.0.0.0
```

### 3) Verify endpoints

```bash
curl -s http://10.52.199.193:8080/catalog.json | head -n 40
curl -I http://10.52.199.193:8080/packs/curriculum_all_in_one_v1.otpack | head -n 5
```

### 4) App-side flow

- Open `Content Pack Installer`
- In `Raspberry Pi Catalog Sync`:
  - Tap `Discover Servers`
  - Tap `Check Catalog`
  - Tap `Hotspot Health Check`
  - Tap `Install Missing Required`

## Raspberry Pi Hotspot Mode Commands

Copy project scripts to Pi (or clone project), then run:

```bash
cd /path/to/offline_tutor_app
```

### 1) Create hotspot AP on Pi

```bash
bash tools/pi_hotspot/setup_hotspot_ap.sh wlan0 SchoolContent School@1234
```

This configures AP gateway IP as `192.168.50.1`.

### 2) Build content pack and catalog for hotspot URL

```bash
python3 tools/prepare_school_content.py \
  --textbooks-root /path/to/TEXTBOOKS \
  --output-root /home/pi/school_server \
  --base-url http://192.168.50.1:8080 \
  --version 1
```

### 3) Run server on Pi

```bash
bash tools/pi_hotspot/run_school_content_server.sh /home/pi/school_server 8080
```

### 4) Student device flow

- Join SSID: `SchoolContent`
- Open app -> `Content Pack Installer`
- Keep default catalog URL: `http://192.168.50.1:8080/catalog.json`
- Tap `Discover Servers` or directly `Check Catalog`
- Tap `Hotspot Health Check`
- Tap `Install Missing Required`

## Notes

- Offline local download requires users to join Pi hotspot/LAN.
- Users not connected to hotspot/LAN need internet path (public server/VPN/tunnel).
- Large packs can be >1 GB; first install may take time.
