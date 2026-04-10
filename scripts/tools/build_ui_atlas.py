#!/usr/bin/env python3
"""Build fixed-layout UI atlases from the Kenney UI pack."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LAYOUT = ROOT / "scripts" / "tools" / "ui_atlas_layout.json"
OUTPUT_DIR = ROOT / "assets" / "ui" / "atlas"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build fixed-layout UI atlases")
    parser.add_argument("--layout", type=Path, default=DEFAULT_LAYOUT)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    return parser.parse_args()


def load_layout(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def resolve_source(slot: dict[str, Any], source_roots: list[Path]) -> Path:
    source_name = slot["source"]
    for root in source_roots:
        candidate = root / source_name
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"Unable to find source PNG for slot: {source_name}")


def image_rect(image: Image.Image, position: list[int]) -> list[int]:
    width, height = image.size
    return [position[0], position[1], width, height]


def build_single_atlas(
    atlas_name: str, atlas_data: dict[str, Any], source_roots: list[Path], output_dir: Path
) -> None:
    width, height = atlas_data["size"]
    background = tuple(atlas_data.get("background", [0, 0, 0, 0]))
    atlas = Image.new("RGBA", (width, height), background)
    manifest_slots: dict[str, Any] = {}

    for slot_name, slot_data in atlas_data["slots"].items():
        source_path = resolve_source(slot_data, source_roots)
        with Image.open(source_path) as source_image:
            image = source_image.convert("RGBA")
            position = slot_data["position"]
            atlas.alpha_composite(image, tuple(position))
            slot_manifest = {
                "source": str(source_path.relative_to(ROOT)).replace("\\", "/"),
                "rect": image_rect(image, position),
            }
            if "slice" in slot_data:
                slot_manifest["slice"] = slot_data["slice"]
            manifest_slots[slot_name] = slot_manifest

    atlas_filename = f"ui_{atlas_name}_atlas.png"
    atlas_path = output_dir / atlas_filename
    atlas.save(atlas_path)

    manifest = {
        "atlas": str(atlas_path.relative_to(ROOT)).replace("\\", "/"),
        "size": [width, height],
        "padding": atlas_data.get("padding", 0),
        "slots": manifest_slots,
    }
    manifest_path = output_dir / f"ui_{atlas_name}_manifest.json"
    with manifest_path.open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2, ensure_ascii=True)
        handle.write("\n")


def main() -> None:
    args = parse_args()
    layout = load_layout(args.layout)
    source_roots = [ROOT / entry for entry in layout["meta"]["source_roots"]]
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    for atlas_name, atlas_data in layout["atlases"].items():
        build_single_atlas(atlas_name, atlas_data, source_roots, output_dir)

    print(f"Built atlases in {output_dir}")


if __name__ == "__main__":
    main()
