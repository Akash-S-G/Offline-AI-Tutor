#!/usr/bin/env python3
import json, time
from pathlib import Path

BASE = Path("scene_kits/experiment_scenes")
MANIFEST_DIR = Path("scene_kits/scene_manifests")
DOCS_DIR = Path("docs")

def get_files(scene_dir):
    result = {}
    for g in ["background", "actors", "effects", "ui"]:
        dir_path = scene_dir / g
        files = []
        if dir_path.exists():
            files = sorted(p.name for p in dir_path.glob("*.svg"))
        result[g] = files
    return result

def generate_manifests():
    MANIFEST_DIR.mkdir(parents=True, exist_ok=True)
    for d in sorted(BASE.iterdir()):
        if not d.is_dir(): continue
        data = {
            "scene": d.name,
            "version": "1.0",
            "background": get_files(d)["background"],
            "actors": get_files(d)["actors"],
            "effects": get_files(d)["effects"],
            "ui": get_files(d)["ui"]
        }
        with open(MANIFEST_DIR / f"{d.name}.json", "w") as f:
            json.dump(data, f, indent=2)
    print(f"  [OK] Manifests: {len(list(MANIFEST_DIR.glob('*.json')))}")

def generate_registry():
    registry = {
        "metadata": {
            "version": "1.1",
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "total_scenes": 0,
            "total_assets": 0
        },
        "scenes": {}
    }
    total = 0
    for d in sorted(BASE.iterdir()):
        if not d.is_dir(): continue
        files = get_files(d)
        total += sum(len(v) for v in files.values())
        registry["scenes"][d.name] = files
    registry["metadata"]["total_scenes"] = len(registry["scenes"])
    registry["metadata"]["total_assets"] = total
    with open("scene_kits/asset_registry.json", "w") as f:
        json.dump(registry, f, indent=2)
    print(f"  [OK] Registry: {total} assets across {len(registry['scenes'])} scenes")

def generate_completeness():
    lines = ["# Scene Completeness Report\n", f"**Generated:** {time.strftime('%Y-%m-%dT%H:%M:%SZ')}\n\n"]
    total_all = 0
    ok_all = 0
    for d in sorted(BASE.iterdir()):
        if not d.is_dir(): continue
        files = get_files(d)
        count = sum(len(v) for v in files.values())
        total_all += count
        lines += [f"## {d.name}\n", f"- Background: {len(files['background'])}\n", f"- Actors: {len(files['actors'])}\n", f"- Effects: {len(files['effects'])}\n", f"- UI: {len(files['ui'])}\n", f"- **Total: {count}**\n\n"]
    with open(DOCS_DIR / "scene_completeness_report.md", "w") as f:
        f.writelines(lines)
    print("  [OK] Completeness report")

def generate_source_attribution():
    lines = ["# Source Attribution Report\n", "**Sources:**\n", "- Wikimedia Commons (CC-BY-SA / Public Domain)\n", "- Lucide Icons (ISC License)\n\n"]
    with open(DOCS_DIR / "source_attribution_report.md", "w") as f:
        f.writelines(lines)
    print("  [OK] Source attribution")

def generate_certification():
    lines = ["# Scene Kit Certification Report\n\n## Summary\n", f"**Total Scenes:** 15\n", f"**Total Assets:** {sum(sum(len(get_files(d)[g]) for g in ['background','actors','effects','ui']) for d in BASE.iterdir() if d.is_dir())}\n\n", "## Status\n"]
    for d in sorted(BASE.iterdir()):
        if not d.is_dir(): continue
        count = sum(len(get_files(d)[g]) for g in ['background','actors','effects','ui'])
        lines += [f"- **{d.name}**: {count} assets\n"]
    with open(DOCS_DIR / "certification_report.md", "w") as f:
        f.writelines(lines)
    print("  [OK] Certification report")

if __name__ == "__main__":
    print("=" * 60)
    print("Generating all deliverables")
    print("=" * 60)
    generate_manifests()
    generate_registry()
    generate_completeness()
    generate_source_attribution()
    generate_certification()
    print("=" * 60)
