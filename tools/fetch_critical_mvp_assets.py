#!/usr/bin/env python3
"""
Fetch ONLY critical Virtual Laboratory MVP assets.
Targets are defined in the critical gap list.
Replaces corrupted files if present.
"""

import json, subprocess, time, urllib.parse
from pathlib import Path

BASE = Path("scene_kits/experiment_scenes")


def get_url_via_api(title: str) -> str:
    """Get direct upload URL for a Wikimedia Commons file."""
    api = ("https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo"
           f"&iiprop=url&titles=File:{title}&format=json")
    try:
        r = subprocess.run(["curl", "-L", "-s", api], capture_output=True, text=True, timeout=30)
        data = json.loads(r.stdout)
        pages = data["query"]["pages"]
        for p in pages.values():
            infos = p.get("imageinfo", [{}])
            if infos and "url" in infos[0]:
                return infos[0]["url"]
    except Exception:
        return ""
    return ""


def search_wikimedia(query: str, limit=5) -> list:
    """Search Wikimedia Commons for SVG files."""
    q = urllib.parse.quote(f"{query} filetype:svg")
    url = ("https://commons.wikimedia.org/w/api.php?action=query&list=search"
           f"&srnamespace=6&srsearch={q}&srlimit={limit}&format=json")
    try:
        r = subprocess.run(["curl", "-L", "-s", url], capture_output=True, text=True, timeout=30)
        data = json.loads(r.stdout)
        return data["query"]["search"]
    except Exception:
        return []
    return []


def download_svg(url: str, dest: Path) -> bool:
    if not url or "upload.wikimedia.org" not in url:
        return False
    try:
        r = subprocess.run(["curl", "-L", "-s", "-o", str(dest), url], timeout=60)
        return r.returncode == 0 and dest.exists() and dest.stat().st_size > 100
    except Exception:
        return False


# ========================================================================
#  CRITICAL ASSET DEFINITIONS
#  Each: (scene, group, filename, search_query, backup_search_query)
# ========================================================================

TARGETS = [
    # Circuit Effects
    ("circuit", "effects", "current_flow", "electric current flow arrow", None),
    ("circuit", "effects", "current_arrows", "current electricity arrows", None),
    ("circuit", "effects", "bulb_glow", "light bulb glow halo", None),

    # Plant Growth
    ("plant_growth", "actors", "watering_can", "watering can garden", None),
    ("plant_growth", "effects", "water_droplets", "water droplets drops rain", None),

    # Heart Rate
    ("heart_rate", "actors", "human_outline", "human body outline silhouette", "human figure person"),
    ("heart_rate", "actors", "treadmill", "treadmill exercise machine", None),
    ("heart_rate", "effects", "pulse_ring", "pulse wave ring heartbeat", "heartbeat pulse"),

    # Matter
    ("matter", "actors", "heater_plate", "hot plate electric heater laboratory", None),
    ("matter", "actors", "thermometer", "thermometer temperature mercury", None),
    ("matter", "effects", "phase_transition", "phase transition melting boiling", "matter phase change solid liquid gas"),

    # Lens
    ("lens", "actors", "screen", "projection screen optics", "screen whiteboard"),
    ("lens", "effects", "light_beam", "light beam ray optics", "light ray ray"),

    # Mirror
    ("mirror", "actors", "curved_mirror", "concave convex mirror curved", None),
    ("mirror", "effects", "reflected_light_beam", "reflected light beam mirror", "reflection light ray mirror"),

    # Water Cycle
    ("water_cycle", "background", "lake", "lake landscape water pond", None),
    ("water_cycle", "background", "water_body", "river water flowing landscape", "lake pond water blue"),
    ("water_cycle", "effects", "evaporation", "evaporation water vapor steam", None),
    ("water_cycle", "effects", "ripple", "water ripple circle wave", None),
]


def fetch_critical_asset(scene, group, filename, keyword, backup):
    dest = BASE / scene / group / f"{filename}.svg"
    dest.parent.mkdir(parents=True, exist_ok=True)

    # If already exists and is valid, skip
    if dest.exists() and dest.stat().st_size > 500:
        print(f"  SKIP: {scene}/{group}/{filename}.svg (already valid)")
        return True

    # Try main keyword
    print(f"  [FETCH] {scene}/{group}/{filename} (keyword: '{keyword}')")
    results = search_wikimedia(keyword, limit=5)

    # Fallback to backup if main fails
    if not results and backup:
        print(f"    [FALLBACK] trying '{backup}'")
        results = search_wikimedia(backup, limit=5)

    for r in results:
        title = r.get("title", "")
        if not title.startswith("File:"):
            continue
        title_clean = title.split(":", 1)[1]
        if not title_clean.lower().endswith(".svg"):
            continue
        url = get_url_via_api(title_clean)
        if not url:
            continue
        if download_svg(url, dest):
            kb = round(dest.stat().st_size / 1024.0, 1)
            print(f"    OK:   {filename}.svg ({kb} KB) from {title_clean}")
            return True
        else:
            print(f"    FAIL: download failed for {title_clean}")

    print(f"    FAIL: {filename} could not be fetched")
    return False


def update_registry():
    registry = {"metadata": {"version": "1.2", "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"), "description": "IDP Scene Kit Asset Registry"}, "scenes": {}}
    for d in sorted(BASE.iterdir()):
        if not d.is_dir():
            continue
        data = {}
        for g in ["background", "actors", "effects", "ui"]:
            gd = d / g
            data[g] = sorted(p.name for p in gd.glob("*.svg")) if gd.exists() else []
        registry["scenes"][d.name] = data
    with open("scene_kits/asset_registry.json", "w") as f:
        json.dump(registry, f, indent=2)
    print("\n  [OK] Updated asset_registry.json")


def generate_report(attempted, ok, rejected):
    report = f"""# Critical Asset Acquisition Report
**Generated:** {time.strftime("%Y-%m-%dT%H:%M:%SZ")}

## Summary
| Metric | Count |
|--------|-------|
| Target | {len(TARGETS)} |
| Attempted | {attempted} |
| Successful | {ok} |
| Rejected/Failed | {len(rejected)} |

## Downloaded Assets
"""
    for item in ok:
        report += f"- `{item['scene']}/{item['group']}/{item['filename']}.svg` — {item['size_kb']} KB (from {item['source']})\n"

    report += "\n## Rejected Assets\n"
    for item in rejected:
        reason = f" ({item.get('reason', 'download failed')})"
        report += f"- `{item['scene']}/{item['group']}/{item['filename']}`.svg`{reason}\n"

    with open("docs/critical_asset_acquisition_report.md", "w") as f:
        f.write(report)
    print("  [OK] Generated docs/critical_asset_acquisition_report.md")


def main():
    print("=" * 60)
    print("CRITICAL MVP ASSET ACQUISITION (Wikimedia Commons)")
    print("=" * 60)

    ok = []
    rejected = []
    for t in TARGETS:
        success = fetch_critical_asset(*t)
        if success:
            dest = BASE / t[0] / t[1] / f"{t[2]}.svg"
            kb = round(dest.stat().st_size / 1024.0, 1)
            ok.append({"scene": t[0], "group": t[1], "filename": t[2], "size_kb": kb, "source": "Wikimedia Commons"})
            time.sleep(0.5)
        else:
            rejected.append({"scene": t[0], "group": t[1], "filename": t[2], "reason": "no valid search result or download failed"})
        time.sleep(0.3)

    count_attempted = len(TARGETS)
    count_ok = len(ok)
    count_rejected = len(rejected)

    print("\n" + "=" * 60)
    print(f"  Total:    {count_attempted}")
    print(f"  OK:       {count_ok}")
    print(f"  Rejected: {count_rejected}")
    print("=" * 60)

    update_registry()
    generate_report(count_attempted, ok, rejected)


if __name__ == "__main__":
    main()
