#!/usr/bin/env python3
"""
Wikimedia Commons bulk SVG downloader for IDP Scene Kits.
Uses the Commons API for proper searching and downloading.
"""
import json, os, subprocess, time, urllib.parse
from pathlib import Path

BASE = Path("scene_kits/experiment_scenes")


def _run_cmd(cmd_list):
    return subprocess.run(cmd_list, capture_output=True, text=True, timeout=30)


def search_files(keyword, limit=5):
    """Search Wikimedia Commons for SVG files matching a keyword."""
    q = urllib.parse.quote(f"{keyword} filetype:svg")
    url = f"https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srsearch={q}&srlimit={limit}&format=json"
    resp = _run_cmd(["curl", "-L", "-s", url])
    if resp.returncode != 0:
        return []
    try:
        data = json.loads(resp.stdout)
        return data["query"]["search"]
    except (KeyError, json.JSONDecodeError):
        return []


def get_image_url(title):
    """Get the direct https://upload.wikimedia.org URL for a file."""
    # Remove "File:" prefix if present
    if title.startswith("File:"):
        title = title[5:]
    api = f"https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url&titles=File:{title}&format=json"
    resp = _run_cmd(["curl", "-L", "-s", api])
    if resp.returncode != 0:
        return ""
    try:
        data = json.loads(resp.stdout)
        pages = data["query"]["pages"]
        for item in pages.values():
            infos = item.get("imageinfo", [{}])
            if infos and "url" in infos[0]:
                return infos[0]["url"]
    except (KeyError, json.JSONDecodeError, IndexError):
        pass
    return ""


def download(url, dest):
    if not url or "upload.wikimedia.org" not in url:
        return False
    try:
        result = subprocess.run(["curl", "-L", "-s", "-o", str(dest), url], timeout=60)
        return result.returncode == 0
    except Exception:
        return False


def fetch(scene, group, name, keyword):
    dest_dir = BASE / scene / group
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{name}.svg"

    if dest.exists() and dest.stat().st_size > 100:
        print(f"  SKIP: {scene}/{group}/{dest.name}")
        return True

    print(f"  SEARCH: {scene}/{name}  (keyword='{keyword}')")
    results = search_files(keyword)
    if not results:
        print(f"    FAIL: no search results")
        return False

    for r in results:
        title = r["title"]
        if not title.startswith("File:"):
            continue
        title_clean = title[5:]  # strip "File:"
        # Only try SVGs
        if not title_clean.lower().endswith(".svg"):
            continue

        url = get_image_url(title_clean)
        if not url:
            continue

        if download(url, dest):
            size = dest.stat().st_size
            if size < 100:
                print(f"    FAIL: {title_clean} — too small ({size}b)")
                dest.unlink(missing_ok=True)
                continue
            print(f"    OK:   {dest.name}  ({round(size/1024.0, 1)} KB)  from {title_clean}")
            return True
        else:
            print(f"    FAIL: download error")
            continue

    print(f"    FAIL: no valid download")
    return False


def main():
    targets = [
        ("circuit", "actors", "battery", "battery"),
        ("circuit", "actors", "bulb", "light bulb"),
        ("circuit", "actors", "switch", "toggle switch"),
        ("circuit", "actors", "ammeter", "ammeter"),
        ("circuit", "actors", "voltmeter", "voltmeter"),
        ("circuit", "actors", "resistor", "resistor"),
        ("circuit", "actors", "wire", "electric wire"),

        ("motion", "actors", "ball", "ball"),
        ("motion", "actors", "car", "car"),
        ("motion", "actors", "ramp", "inclined plane"),
        ("motion", "actors", "stopwatch", "stopwatch"),
        ("motion", "actors", "ruler", "ruler"),
        ("motion", "actors", "pulley", "pulley"),

        ("plant_growth", "actors", "seed", "seed"),
        ("plant_growth", "actors", "sprout", "seedling plant"),
        ("plant_growth", "actors", "leaf", "leaf"),
        ("plant_growth", "actors", "soil", "soil"),

        ("chemical_reaction", "actors", "flask", "Erlenmeyer flask"),
        ("chemical_reaction", "actors", "test_tube", "test tube"),
        ("chemical_reaction", "actors", "burner", "Bunsen burner"),

        ("food_chain", "actors", "grass", "grass plant"),
        ("food_chain", "actors", "rabbit", "rabbit"),
        ("food_chain", "actors", "fox", "fox"),

        ("heart_rate", "actors", "heart", "human heart"),
        ("heart_rate", "actors", "stethoscope", "stethoscope"),

        ("human_body", "actors", "brain", "brain"),
        ("human_body", "actors", "lungs", "lungs"),
        ("human_body", "actors", "kidney", "kidney"),

        ("lens", "actors", "prism", "prism optics"),
        ("lens", "actors", "magnifier", "magnifying glass"),

        ("matter", "actors", "molecule", "molecule"),
        ("matter", "actors", "atom", "atom"),
        ("matter", "actors", "ice", "ice cube"),
        ("matter", "actors", "steam", "steam"),

        ("mirror", "actors", "mirror", "mirror"),
        ("mirror", "actors", "optical_bench", "optical bench"),

        ("pendulum", "actors", "protractor", "protractor"),

        ("simple_machines", "actors", "lever", "lever simple machine"),
        ("simple_machines", "actors", "pulley", "pulley"),

        ("water_cycle", "actors", "cloud", "cloud"),
        ("water_cycle", "actors", "rain", "rain"),
        ("water_cycle", "actors", "ocean", "ocean"),
        ("water_cycle", "actors", "mountain", "mountain"),

        ("wave", "actors", "tuning_fork", "tuning fork"),
        ("wave", "actors", "speaker", "loudspeaker"),
    ]

    total = len(targets)
    ok = 0
    print("=" * 60)
    print("IDP Scene Kit — Bulk Wikimedia Acquisition (API Search)")
    print("=" * 60)
    for scene, group, name, keyword in targets:
        if fetch(scene, group, name, keyword):
            ok += 1
        else:
            print(f"    [{scene}/{name}] FAILED")
        time.sleep(0.4)

    print("\n" + "=" * 60)
    print(f"Total:    {total}")
    print(f"OK:       {ok}")
    print(f"Failed:   {total - ok}")
    print("=" * 60)


if __name__ == "__main__":
    main()
