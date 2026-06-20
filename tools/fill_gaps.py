#!/usr/bin/env python3
"""Fill missing scene kit assets using Lucide icons (guaranteed availability)."""

import os, time, json
from pathlib import Path
import subprocess

BASE = Path("scene_kits/experiment_scenes")

def lucide_download(name, dest):
    url = f"https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/{name}.svg"
    if dest.exists() and dest.stat().st_size > 0:
        return True
    r = subprocess.run(["curl", "-L", "-s", "-o", str(dest), url], timeout=30)
    if r.returncode == 0 and dest.exists() and dest.stat().st_size > 100:
        kb = round(dest.stat().st_size / 1024.0, 1)
        print(f"  OK:   {dest.name} ({kb} KB)")
        time.sleep(0.3)
        return True
    return False

def main():
    gaps = {
        # Circuit — fill missing even if some already exist
        "circuit/actors": [
            ("battery", "battery"), ("bulb", "lightbulb"), ("switch", "toggle-right"),
            ("wire", "minus"), ("ammeter", "gauge"), ("voltmeter", "gauge"), ("resistor", "zap")
        ],
        # Motion
        "motion/actors": [
            ("car", "car-front"), ("ball", "circle"), ("ruler", "ruler"),
            ("stopwatch", "timer"), ("ramp", "triangle"), ("pulley", "percent")
        ],
        # Plant Growth
        "plant_growth/actors": [
            ("sun", "sun"), ("sprout", "sprout"), ("water", "droplets"),
            ("soil", "layers"), ("leaf", "leaf")
        ],
        # Water Cycle background/actors (missing from Wikimedia batch)
        "water_cycle/background": [
            ("sky", "cloud"), ("mountain", "mountain"), ("ocean", "waves")
        ],
        "water_cycle/actors": [
            ("sun", "sun"), ("cloud", "cloud"), ("rain", "cloud-rain"), ("arrow", "arrow-down")
        ],
        # Chemical Reaction — extra
        "chemical_reaction/actors": [
            ("test_tube", "flask-conical"), ("burner", "flame"), ("mix", "blend"),
        ],
        # Food Chain
        "food_chain/actors": [
            ("grass", "flower"), ("rabbit", "rabbit"), ("fox", "cat"),
            ("sun", "sun")  # energy source
        ],
        # Heart Rate
        "heart_rate/actors": [
            ("heart", "heart"), ("pulse", "activity"), ("heart_beat", "heart-pulse")
        ],
        # Human Body
        "human_body/actors": [
            ("brain", "brain"), ("lungs", "wind"), ("heart", "heart"),
            ("bones", "bone"), ("circulation", "activity")
        ],
        # Lens
        "lens/actors": [
            ("lens", "scan-eye"), ("prism", "pyramid"), ("magnifier", "search")
        ],
        # Mirror
        "mirror/actors": [
            ("mirror", "square"), ("light", "lightbulb"), ("eye", "eye")
        ],
        # Matter
        "matter/actors": [
            ("solid", "box"), ("liquid", "droplets"), ("gas", "cloud-fog"),
            ("molecule", "atom"), ("molecule2", "orbit")
        ],
        # Pendulum
        "pendulum/actors": [
            ("pendulum_bob", "disc"), ("support", "arrow-down-to-line"),
            ("swing_arc", "circle-dashed"), ("clock", "clock")
        ],
        # Simple Machines
        "simple_machines/actors": [
            ("lever", "equal"), ("pulley", "percent"), ("wedge", "triangle"),
            ("wheel", "circle"), ("screw", "minus"), ("inclined_plane", "trending-down")
        ],
        # Wave
        "wave/actors": [
            ("speaker", "speaker"), ("sound", "audio-lines"),
            ("microphone", "mic"), ("oscilloscope", "activity")
        ],
        # Solar System
        "solar_system/actors": [
            # already has planets.svg, add a few icons for individual planets
            ("sun", "sun"), ("earth", "globe"), ("star", "star"), ("orbit", "orbit")
        ],
    }

    print("=" * 60)
    print("Filling gaps with Lucide icons")
    print("=" * 60)
    total = 0
    ok = 0
    for subdir, files in gaps.items():
        dest_dir = BASE / subdir
        dest_dir.mkdir(parents=True, exist_ok=True)
        for name, icon in files:
            total += 1
            dest = dest_dir / f"{name}.svg"
            if lucide_download(icon, dest):
                ok += 1

    print(f"\nTotal: {total}, OK: {ok}, Failed: {total - ok}")

    # Update registry
    print("\nUpdating asset_registry.json...")
    registry = {
        "metadata": {
            "version": "1.1",
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "description": "IDP Scene Kit Asset Registry"
        },
        "scenes": {}
    }
    for scene_dir in sorted(BASE.iterdir()):
        if not scene_dir.is_dir():
            continue
        scene_data = {}
        for group in ["background", "actors", "effects", "ui"]:
            gdir = scene_dir / group
            if gdir.exists():
                files = sorted(p.name for p in gdir.glob("*.svg"))
                scene_data[group] = files
            else:
                scene_data[group] = []
        registry["scenes"][scene_dir.name] = scene_data

    with open("scene_kits/asset_registry.json", "w") as f:
        json.dump(registry, f, indent=2)
    print("Done.")


if __name__ == "__main__":
    main()
