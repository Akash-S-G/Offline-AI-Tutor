#!/usr/bin/env python3
"""Bulk Asset Acquisition for IDP Scene Kits."""
import json, os, subprocess, time
from pathlib import Path

BASE = Path("scene_kits/experiment_scenes")

def get_url(title: str) -> str:
    api = "https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|mime|size&format=json&titles=File:" + title
    try:
        resp = subprocess.run(["curl", "-L", "-s", api], capture_output=True, text=True, timeout=30)
        data = json.loads(resp.stdout)
        pages = data["query"]["pages"]
        for item in pages.values():
            inf = item.get("imageinfo", [{}])[0]
            return inf.get("url", "")
    except Exception:
        return ""
    return ""

def download(url: str, dest: Path) -> bool:
    if not url or "upload.wikimedia.org" not in url:
        return False
    try:
        subprocess.run(["curl", "-L", "-s", "-o", str(dest), url], timeout=60, check=True)
        return True
    except Exception:
        return False

def fetch_all():
    total = 0
    ok = 0
    skip = 0
    scenes = {
        "circuit": [("actors", "battery", "battery"), ("actors", "bulb", "Light_bulb"), ("actors", "switch", "Switch"), ("actors", "wire", "Wire"), ("actors", "ammeter", "Ammeter"), ("actors", "galvanometer", "Galvanometer")],
        "motion": [("actors", "ball", "Ball"), ("actors", "car", "Car"), ("actors", "ramp", "Inclined_plane"), ("actors", "ruler", "Ruler"), ("actors", "stopwatch", "Stopwatch"), ("actors", "pulley", "Pulley")],
        "plant_growth": [("actors", "seed", "Seed"), ("actors", "seedling", "Seedling"), ("actors", "sun", "Sun"), ("actors", "watering_can", "Watering_can"), ("actors", "leaf", "Leaf")],
        "chemical_reaction": [("actors", "flask", "Erlenmeyer_flask"), ("actors", "test_tube", "Test_tube_holder"), ("actors", "burner", "Bunsen_burner_simple_diagram")],
        "food_chain": [("actors", "grass", "Grass"), ("actors", "rabbit", "Rabbit"), ("actors", "fox", "Fox")],
        "heart_rate": [("actors", "heart", "Heart_anterior_exterior_view"), ("actors", "stethoscope", "Stethoscope")],
        "human_body": [("actors", "brain", "Brain"), ("actors", "lungs", "Lungs"), ("actors", "kidney", "Kidney")],
        "lens": [("actors", "prism", "Prism"), ("actors", "magnifying_glass", "Magnifying_glass")],
        "matter": [("actors", "molecule", "Molecule"), ("actors", "atom", "Atom"), ("actors", "ice_cube", "Ice_cube")],
        "mirror": [("actors", "plane_mirror", "Mirror"), ("actors", "optical_bench", "Optical_bench")],
        "pendulum": [("actors", "protractor", "Protractor")],
        "simple_machines": [("actors", "lever", "Lever_simple_machine"), ("actors", "pulley", "Fixed_pulley_diagram")],
        "water_cycle": [("actors", "cloud", "Cloud"), ("actors", "rain", "Rain"), ("actors", "mountain", "Mountain"), ("actors", "ocean", "Ocean")],
        "wave": [("actors", "tuning_fork", "Tuning_fork"), ("actors", "speaker", "Loudspeaker")],
    }

    for scene, items in scenes.items():
        print("\n=== " + scene.upper() + " ===")
        for group, name, wiki_title in items:
            total += 1
            dest_dir = BASE / scene / group
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest = dest_dir / (name.lower().replace(" ", "_") + ".svg")
            if dest.exists() and dest.stat().st_size > 0:
                print("  SKIP: " + scene + "/" + group + "/" + dest.name)
                skip += 1
                continue
            url = get_url(wiki_title)
            if not url:
                print("  FAIL: " + scene + "/" + dest.name + " (no URL)")
                continue
            if download(url, dest):
                kb = dest.stat().st_size / 1024.0
                if kb < 1:
                    print("  FAIL: " + scene + "/" + dest.name + " (empty)")
                    dest.unlink(missing_ok=True)
                else:
                    print("  OK:   " + scene + "/" + dest.name + " (" + str(round(kb,1)) + " KB)")
                    ok += 1
            else:
                print("  FAIL: " + scene + "/" + dest.name + " (download)")
            time.sleep(0.3)

    print("\n" + "="*60)
    print("Total target:    " + str(total))
    print("Downloaded:      " + str(ok))
    print("Skipped:         " + str(skip))
    print("Missing:         " + str(total - ok - skip))
    print("="*60)

    # Update registry
    print("\nUpdating registry...")
    registry = {"metadata": {"version": "1.1", "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ")}, "scenes": {}}
    for scene_dir in BASE.iterdir():
        if not scene_dir.is_dir():
            continue
        sd = {}
        for grp in ["background", "actors", "effects", "ui"]:
            gdir = scene_dir / grp
            files = []
            if gdir.exists():
                files = sorted([str(p.relative_to(BASE)) for p in gdir.glob("*.svg")])
            sd[grp] = files
        registry["scenes"][scene_dir.name] = sd
    with open("scene_kits/asset_registry.json", "w") as f:
        json.dump(registry, f, indent=2)
    print("Done.")

if __name__ == "__main__":
    fetch_all()
