#!/usr/bin/env python3
"""
Asset Acquisition Pipeline for IDP Experiment Engine.

Automatically fetches open-license SVG assets from public providers
(Lucide, OpenMoji, Wikimedia Commons, direct URLs) and organizes them
into scene folders.  The pipeline is idempotent: re-running will skip
assets that already exist unless --force is passed.

Usage:
    python tools/asset_pipeline.py [--config tools/asset_sources.json] [--force]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
#  CONSTANTS
# ---------------------------------------------------------------------------

BASE_DIR = Path("assets")
SCENES_DIR = BASE_DIR / "experiment_scenes"
REPORT_JSON = BASE_DIR / "asset_pipeline_report.json"
REPORT_MD = BASE_DIR / "asset_pipeline_report.md"
REGISTRY = BASE_DIR / "asset_registry.json"

CACHE_DIR = Path(".asset_cache")
MAX_SIZE = 200 * 1024  # 200 KB
USER_AGENT = "IDP-Asset-Pipeline/1.0"
SLEEP = 0.5            # seconds between requests to the same provider

# ---------------------------------------------------------------------------
#  DEFAULT CONFIG (inline so the script is self-contained)
# ---------------------------------------------------------------------------

DEFAULT_CONFIG: Dict[str, Any] = {
    "scenes": {
        "circuit": [
            {"name": "battery",   "sources": [{"provider": "lucide", "id": "battery"}]},
            {"name": "bulb",      "sources": [{"provider": "lucide", "id": "lightbulb"}]},
            {"name": "switch",    "sources": [{"provider": "lucide", "id": "toggle-right"}]},
            {"name": "wire",      "sources": [{"provider": "lucide", "id": "minus"}]},
            {"name": "resistor",  "sources": [{"provider": "lucide", "id": "zap"}]},
            {"name": "ammeter",   "sources": [{"provider": "lucide", "id": "gauge"}]},
        ],
        "solar_system": [
            {"name": "sun",     "sources": [{"provider": "lucide", "id": "sun"}]},
            {"name": "earth",   "sources": [{"provider": "lucide", "id": "globe"}]},
            {"name": "moon",    "sources": [{"provider": "lucide", "id": "moon"}]},
            {"name": "orbit",   "sources": [{"provider": "lucide", "id": "orbit"}]},
            {"name": "planet",  "sources": [{"provider": "lucide", "id": "circle"}]},
            {"name": "star",    "sources": [{"provider": "lucide", "id": "star"}]},
        ],
        "water_cycle": [
            {"name": "sun",    "sources": [{"provider": "lucide", "id": "sun"}]},
            {"name": "cloud",  "sources": [{"provider": "lucide", "id": "cloud"}]},
            {"name": "rain",   "sources": [{"provider": "lucide", "id": "cloud-rain"}]},
            {"name": "water",  "sources": [{"provider": "lucide", "id": "waves"}]},
            {"name": "arrow",  "sources": [{"provider": "lucide", "id": "arrow-down"}]},
        ],
        "pendulum": [
            {"name": "pendulum", "sources": [{"provider": "lucide", "id": "arrow-up-down"}]},
            {"name": "support",  "sources": [{"provider": "lucide", "id": "arrow-down-to-line"}]},
            {"name": "weight",   "sources": [{"provider": "lucide", "id": "disc"}]},
        ],
        "plant_growth": [
            {"name": "sun",   "sources": [{"provider": "lucide", "id": "sun"}]},
            {"name": "plant", "sources": [{"provider": "lucide", "id": "sprout"}]},
            {"name": "water", "sources": [{"provider": "lucide", "id": "droplets"}]},
            {"name": "soil",  "sources": [{"provider": "lucide", "id": "layers"}]},
        ],
        "heart_rate": [
            {"name": "heart", "sources": [{"provider": "lucide", "id": "heart"}]},
            {"name": "ecg",   "sources": [{"provider": "lucide", "id": "activity"}]},
        ],
        "free_fall": [
            {"name": "ball",         "sources": [{"provider": "lucide", "id": "circle"}]},
            {"name": "ground",       "sources": [{"provider": "lucide", "id": "minus"}]},
            {"name": "height_scale", "sources": [{"provider": "lucide", "id": "ruler"}]},
        ],
    }
}

# ---------------------------------------------------------------------------
#  UTILITIES
# ---------------------------------------------------------------------------

RequestCache: Dict[str, bytes] = {}


def _http_get(url: str, timeout: int = 30) -> Optional[bytes]:
    """Fetch a URL, returning raw bytes on success or None on failure."""
    if url in RequestCache:
        return RequestCache[url]

    headers = {"User-Agent": USER_AGENT}
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
    except urllib.error.HTTPError as exc:
        print(f"  HTTP {exc.code} for {url}")
        return None
    except Exception as exc:
        print(f"  Error fetching {url}: {exc}")
        return None

    time.sleep(SLEEP)
    RequestCache[url] = data
    return data


def is_valid_svg(data: bytes) -> bool:
    """Basic validation: must start with an XML/SVG signature and contain <svg."""
    text = data[:512].decode("utf-8", errors="ignore").lower()
    # Reject obvious raster images
    if data[:4] == b"\x89PNG":
        return False
    if data[:3] == b"\xff\xd8\xff":
        return False
    if data[:4] == b"GIF8":
        return False
    if b"<svg" in data.lower():
        return True
    if "<?xml" in text and "svg" in text:
        return True
    return False


def normalize_name(name: str) -> str:
    """Normalize an asset name to lowercase_underscore.svg."""
    base = os.path.basename(name).lower()
    if not base.endswith(".svg"):
        base += ".svg"
    # Replace any non-alphanumeric (except .) with underscore
    base = re.sub(r"[^a-z0-9.]", "_", base)
    # Collapse multiple underscores
    base = re.sub(r"_+", "_", base)
    base = base.strip("_")
    return base


def file_hash(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# ---------------------------------------------------------------------------
#  PROVIDERS
# ---------------------------------------------------------------------------

def fetch_lucide(icon_name: str) -> Tuple[Optional[bytes], Optional[str]]:
    url = f"https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/{icon_name}.svg"
    data = _http_get(url)
    return data, url


def fetch_openmojo(keyword_or_hex: str) -> Tuple[Optional[bytes], Optional[str]]:
    # Try treating the argument as a hex code first
    hex_code = keyword_or_hex.upper().replace(" ", "_")
    url = f"https://raw.githubusercontent.com/hfg-gmuend/openmoji/master/color/svg/{hex_code}.svg"
    data = _http_get(url)
    if data:
        return data, url

    # Fallback: try to resolve via keyword using the OpenMoji JSON map
    om_data = _get_openmoji_map()
    if om_data:
        kw = keyword_or_hex.lower()
        for entry in om_data:
            annotation = entry.get("annotation", "").lower()
            tags = entry.get("tags", "")
            if isinstance(tags, str):
                tags = tags.split(",")
            tag_text = " ".join(tags).lower()
            if kw in annotation or kw in tag_text:
                hex_found = entry["hexcode"]
                url = f"https://raw.githubusercontent.com/hfg-gmuend/openmoji/master/color/svg/{hex_found}.svg"
                data = _http_get(url)
                if data:
                    return data, url
                break
    return None, None


def _get_openmoji_map() -> Optional[List[Dict[str, Any]]]:
    cache_file = CACHE_DIR / "openmoji.json"
    if cache_file.exists():
        try:
            return json.loads(cache_file.read_text(encoding="utf-8"))
        except Exception:
            pass
    url = "https://raw.githubusercontent.com/hfg-gmuend/openmoji/master/data/openmoji.json"
    data = _http_get(url)
    if not data:
        return None
    try:
        parsed = json.loads(data.decode("utf-8"))
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        cache_file.write_text(json.dumps(parsed), encoding="utf-8")
        return parsed
    except Exception:
        return None


def fetch_wikimedia(query: str) -> Tuple[Optional[bytes], Optional[str]]:
    # Step 1: search
    search_url = (
        "https://commons.wikimedia.org/w/api.php?"
        "action=query&list=search&srnamespace=6&format=json"
        f"&srsearch={urllib.parse.quote(query + ' filetype:svg')}&srlimit=5"
    )
    search_data = _http_get(search_url)
    if not search_data:
        return None, None

    try:
        results = json.loads(search_data.decode("utf-8"))
        hits = results["query"]["search"]
    except Exception:
        return None, None

    if not hits:
        return None, None

    # Try each hit until we get a valid SVG image
    for hit in hits:
        title = hit["title"]  # e.g. "File:Sun icon.svg"
        if not title.lower().endswith(".svg"):
            continue

        info_url = (
            "https://commons.wikimedia.org/w/api.php?"
            "action=query&prop=imageinfo&iiprop=url|size|mediatype&format=json"
            f"&titles={urllib.parse.quote(title)}"
        )
        info_data = _http_get(info_url)
        if not info_data:
            continue

        try:
            pages = json.loads(info_data.decode("utf-8"))["query"]["pages"]
            page = next(iter(pages.values()))
            img_info = page.get("imageinfo", [{}])[0]
            url = img_info.get("url")
            mime = img_info.get("mime", "")
            size = img_info.get("size", 0)
            if url and ("svg" in mime or size < MAX_SIZE):
                data = _http_get(url)
                if data:
                    return data, url
        except Exception:
            continue

    return None, None


def fetch_direct(url: str) -> Tuple[Optional[bytes], Optional[str]]:
    data = _http_get(url)
    return data, url


PROVIDERS = {
    "lucide": fetch_lucide,
    "openmoji": fetch_openmojo,
    "wikimedia": fetch_wikimedia,
    "direct": fetch_direct,
}


# ---------------------------------------------------------------------------
#  PIPELINE
# ---------------------------------------------------------------------------

class Pipeline:
    def __init__(self, config: Dict[str, Any], force: bool = False) -> None:
        self.config = config
        self.force = force
        self.downloaded: List[Dict[str, Any]] = []
        self.failed: List[Dict[str, Any]] = []
        self.duplicates: List[Dict[str, Any]] = []
        self.existing_files_before: set = set()

    def run(self) -> None:
        print("=" * 60)
        print("IDP Asset Acquisition Pipeline")
        print("=" * 60)

        # Build set of files present before this run (for safety)
        if SCENES_DIR.exists():
            self.existing_files_before = {p.resolve() for p in SCENES_DIR.rglob("*")}

        for scene_name, assets in self.config.get("scenes", {}).items():
            self._process_scene(scene_name, assets)

        self._deduplicate_new_files()
        self._generate_registry()
        self._generate_report()

        print("\n" + "=" * 60)
        print("Pipeline complete.")
        print(f"  Downloaded: {len(self.downloaded)}")
        print(f"  Failed:     {len(self.failed)}")
        print(f"  Duplicates: {len(self.duplicates)}")
        print("=" * 60)

    # ................................. process scene ...........................

    def _process_scene(self, scene_name: str, assets: List[Dict[str, Any]]) -> None:
        scene_dir = SCENES_DIR / scene_name
        scene_dir.mkdir(parents=True, exist_ok=True)

        for asset in assets:
            name = asset.get("name", "unnamed")
            category = asset.get("category", "actors")
            sources = asset.get("sources", [])
            normalized = normalize_name(name)
            
            cat_dir = scene_dir / category
            cat_dir.mkdir(parents=True, exist_ok=True)
            
            target_path = cat_dir / normalized

            # Idempotency: skip if exists
            if target_path.exists() and not self.force:
                print(f"[SKIP] {scene_name}/{normalized} already exists")
                continue

            data, source_url = self._try_sources(sources)
            if not data:
                self.failed.append({
                    "scene": scene_name,
                    "name": normalized,
                    "reason": "All sources failed",
                })
                print(f"[FAIL] {scene_name}/{normalized} — no source succeeded")
                continue

            # Validate
            if not is_valid_svg(data):
                self.failed.append({
                    "scene": scene_name,
                    "name": normalized,
                    "reason": "Not a valid SVG",
                    "source_url": source_url,
                })
                print(f"[FAIL] {scene_name}/{normalized} — invalid SVG from {source_url}")
                continue

            if len(data) > MAX_SIZE:
                self.failed.append({
                    "scene": scene_name,
                    "name": normalized,
                    "reason": f"File size {len(data)} > {MAX_SIZE}",
                    "source_url": source_url,
                })
                print(f"[FAIL] {scene_name}/{normalized} — exceeds 200KB")
                continue

            h = file_hash(data)
            dup = self._find_duplicate(scene_dir, h)
            if dup:
                self.duplicates.append({
                    "scene": scene_name,
                    "category": category,
                    "name": normalized,
                    "duplicate_of": dup.name,
                    "source_url": source_url,
                })
                print(f"[DUP]  {scene_name}/{category}/{normalized} is identical to {dup.name}; skipping")
                continue

            # Write file
            target_path.write_bytes(data)
            self.downloaded.append({
                "scene": scene_name,
                "category": category,
                "name": normalized,
                "size": len(data),
                "sha256": h,
                "source_url": source_url,
            })
            print(f"[OK]   {scene_name}/{category}/{normalized} ({len(data)} bytes) from {source_url}")

    def _try_sources(self, sources: List[Dict[str, Any]]) -> Tuple[Optional[bytes], Optional[str]]:
        """Try each source definition until one succeeds."""
        for source in sources:
            provider = source.get("provider", "direct")
            handler = PROVIDERS.get(provider)
            if not handler:
                print(f"  Unknown provider {provider}, skipping")
                continue

            if provider == "lucide":
                data, url = handler(source.get("id", ""))
            elif provider == "openmoji":
                data, url = handler(source.get("keyword") or source.get("hex") or source.get("id", ""))
            elif provider == "wikimedia":
                data, url = handler(source.get("query", ""))
            elif provider == "direct":
                data, url = handler(source.get("url", ""))
            else:
                data, url = None, None

            if data and is_valid_svg(data):
                return data, url
        return None, None

    def _find_duplicate(self, scene_dir: Path, data_hash: str) -> Optional[Path]:
        """Check if a file with the same hash already exists in the scene."""
        for p in scene_dir.rglob("*"):
            if p.is_file() and p.stat().st_size < MAX_SIZE:
                try:
                    existing = p.read_bytes()
                    if file_hash(existing) == data_hash:
                        return p
                except Exception:
                    continue
        return None

    # ................................. dedup new ...........................

    def _deduplicate_new_files(self) -> None:
        """Remove duplicate files created during this run (among themselves)."""
        for scene_dir in SCENES_DIR.iterdir():
            if not scene_dir.is_dir():
                continue
            seen: Dict[str, Path] = {}
            for p in sorted(scene_dir.rglob("*")):
                if not p.is_file():
                    continue
                # Only touch files created by this run (not pre-existing)
                if p.resolve() in self.existing_files_before:
                    continue
                try:
                    data = p.read_bytes()
                except Exception:
                    continue
                h = file_hash(data)
                if h in seen:
                    self.duplicates.append({
                        "scene": scene_dir.name,
                        "name": p.name,
                        "duplicate_of": seen[h].name,
                        "action": "removed",
                    })
                    p.unlink()
                    print(f"[DEDUP] {scene_dir.name}/{p.name} removed (same as {seen[h].name})")
                else:
                    seen[h] = p

    # ................................. registry ...........................

    def _generate_registry(self) -> None:
        registry: Dict[str, Dict[str, Dict[str, str]]] = {}
        for scene_dir in SCENES_DIR.iterdir():
            if not scene_dir.is_dir():
                continue
            scene_name = scene_dir.name
            
            categories: Dict[str, Dict[str, str]] = {
                "background": {},
                "actors": {},
                "effects": {}
            }
            
            for p in sorted(scene_dir.rglob("*")):
                if p.is_file() and p.suffix.lower() == ".svg":
                    key = p.stem
                    cat = p.parent.name
                    if cat not in categories:
                        categories[cat] = {}
                    categories[cat][key] = str(p.relative_to(BASE_DIR))
                    
            if any(categories.values()):
                registry[scene_name] = categories

        REGISTRY.write_text(json.dumps(registry, indent=2), encoding="utf-8")
        print(f"\n[INFO] Registry written to {REGISTRY}")

    # ................................. report ...........................

    def _generate_report(self) -> None:
        now = datetime.now(timezone.utc).isoformat()
        report: Dict[str, Any] = {
            "timestamp": now,
            "summary": {
                "total_attempted": len(self.downloaded) + len(self.failed) + len(self.duplicates),
                "downloaded": len(self.downloaded),
                "failed": len(self.failed),
                "duplicates": len(self.duplicates),
            },
            "downloaded": self.downloaded,
            "failed": self.failed,
            "duplicates": self.duplicates,
        }
        REPORT_JSON.write_text(json.dumps(report, indent=2), encoding="utf-8")

        md_lines = [
            "# Asset Acquisition Pipeline Report\n",
            f"**Timestamp:** {now}\n",
            "## Summary\n",
            f"- **Downloaded:** {len(self.downloaded)}\n",
            f"- **Failed:** {len(self.failed)}\n",
            f"- **Duplicates:** {len(self.duplicates)}\n",
            "## Downloaded Assets\n",
        ]
        for item in self.downloaded:
            md_lines.append(
                f"- `{item['scene']}/{item['name']}` ({item['size']} bytes) — "
                f"[source]({item['source_url']})\n"
            )

        if self.failed:
            md_lines.append("\n## Failed Assets\n")
            for item in self.failed:
                md_lines.append(f"- `{item['scene']}/{item['name']}` — {item['reason']}\n")

        if self.duplicates:
            md_lines.append("\n## Duplicate Assets\n")
            for item in self.duplicates:
                md_lines.append(
                    f"- `{item['scene']}/{item['name']}` — duplicates `{item['duplicate_of']}`\n"
                )

        REPORT_MD.write_text("".join(md_lines), encoding="utf-8")

        print(f"[INFO] Report JSON: {REPORT_JSON}")
        print(f"[INFO] Report MD:   {REPORT_MD}")


# ---------------------------------------------------------------------------
#  MAIN
# ---------------------------------------------------------------------------

def load_config(path: Optional[Path]) -> Dict[str, Any]:
    if path and path.exists():
        print(f"[INFO] Loading config from {path}")
        return json.loads(path.read_text(encoding="utf-8"))
    print("[INFO] Using built-in default config")
    return DEFAULT_CONFIG


def main() -> None:
    parser = argparse.ArgumentParser(description="IDP Asset Acquisition Pipeline")
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Path to asset_sources.json (default: built-in config)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-download assets even if they already exist",
    )
    args = parser.parse_args()

    config = load_config(args.config)
    pipeline = Pipeline(config, force=args.force)
    pipeline.run()


if __name__ == "__main__":
    main()
