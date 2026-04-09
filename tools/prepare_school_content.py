#!/usr/bin/env python3
"""Build a school content pack and catalog from local textbook PDFs."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path


def classify_subject(path_text: str) -> str:
    text = path_text.lower()
    if "math" in text:
        return "Mathematics"
    if "social" in text or "history" in text or "civics" in text:
        return "Social Science"
    if "science" in text:
        return "Science"
    if "english" in text:
        return "English"
    return "All Subjects"


def classify_medium(path_text: str) -> str:
    text = path_text.lower()
    if "kannada" in text or "_kn" in text or " kn " in text:
        return "Kannada Medium"
    if "english" in text or "_en" in text or " en " in text:
        return "English Medium"
    return "Mixed"


def classify_grade(path_text: str) -> int | None:
    text = path_text.lower()
    m = re.search(r"(?<!\d)(12|11|10|[1-9])(?:st|nd|rd|th)?(?!\d)", text)
    if not m:
        return None
    return int(m.group(1))


def build_pack(textbooks_root: Path, output_root: Path, base_url: str, version: int) -> tuple[Path, int]:
    packs_dir = output_root / "packs"
    packs_dir.mkdir(parents=True, exist_ok=True)

    pdf_files = sorted([p for p in textbooks_root.rglob("*") if p.is_file() and p.suffix.lower() == ".pdf"])
    if not pdf_files:
        raise RuntimeError(f"No PDF files found under {textbooks_root}")

    pack_id = "curriculum_all_in_one"
    archive_name = f"{pack_id}_v{version}.otpack"
    archive_path = packs_dir / archive_name

    temp_dir = Path(tempfile.mkdtemp(prefix="school_pack_"))
    content_dir = temp_dir / "content"
    content_dir.mkdir(parents=True, exist_ok=True)

    items = []
    total_size = 0

    try:
        for idx, pdf in enumerate(pdf_files):
            rel = pdf.relative_to(textbooks_root).as_posix()
            target = content_dir / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(pdf, target)

            size_bytes = target.stat().st_size
            total_size += size_bytes
            rel_text = rel.replace("_", " ")
            subject = classify_subject(rel_text)
            medium = classify_medium(rel_text)
            grade = classify_grade(rel_text)

            items.append(
                {
                    "kind": "pdf",
                    "title": rel,
                    "relativePath": rel,
                    "grade": grade,
                    "subject": subject,
                    "medium": medium,
                    "chapterId": None,
                    "languageCode": "kn" if medium == "Kannada Medium" else "en",
                    "orderIndex": idx,
                    "metadataJson": json.dumps({"source": str(pdf)}),
                }
            )

        manifest = {
            "manifest": {
                "packId": pack_id,
                "title": "School Curriculum All-In-One",
                "medium": "Mixed",
                "subject": "All Subjects",
                "gradeMin": 1,
                "gradeMax": 10,
                "version": version,
                "generatedAt": None,
            },
            "items": items,
        }

        manifest_path = temp_dir / "pack_manifest.json"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=True), encoding="utf-8")

        if archive_path.exists():
            archive_path.unlink()

        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.write(manifest_path, arcname="pack_manifest.json")
            for file in content_dir.rglob("*"):
                if file.is_file():
                    arcname = Path("content") / file.relative_to(content_dir)
                    zf.write(file, arcname=str(arcname).replace("\\", "/"))

        catalog = {
            "packs": [
                {
                    "packId": pack_id,
                    "title": "School Curriculum All-In-One",
                    "medium": "Mixed",
                    "subject": "All Subjects",
                    "gradeMin": 1,
                    "gradeMax": 10,
                    "version": version,
                    "archiveUrl": f"{base_url.rstrip('/')}/packs/{archive_name}",
                }
            ]
        }

        (output_root / "catalog.json").write_text(
            json.dumps(catalog, ensure_ascii=True, indent=2),
            encoding="utf-8",
        )
        (output_root / "health").write_text("ok\n", encoding="utf-8")

        return archive_path, len(pdf_files)
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--textbooks-root", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--version", type=int, default=1)
    args = parser.parse_args()

    textbooks_root = Path(args.textbooks_root).resolve()
    output_root = Path(args.output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)

    archive_path, count = build_pack(
        textbooks_root=textbooks_root,
        output_root=output_root,
        base_url=args.base_url,
        version=args.version,
    )

    print(f"Built pack: {archive_path}")
    print(f"PDF count: {count}")
    print(f"Catalog: {output_root / 'catalog.json'}")


if __name__ == "__main__":
    main()
