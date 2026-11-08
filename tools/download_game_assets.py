#!/usr/bin/env python3
"""Fetch CC0 Poly Haven PBR textures and glTF props for Open Road."""
import json, os, re, time, urllib.request
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path("assets/polyhaven")
API = "https://api.polyhaven.com"
UA = "OpenRoadGameAssetBuilder/1.0 (Godot project)"
ROOT.mkdir(parents=True, exist_ok=True)

def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r)

def download(url, dest):
    dest = Path(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 1024:
        return dest
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as r, open(dest, "wb") as f:
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk: break
            f.write(chunk)
    if dest.stat().st_size < 512:
        raise RuntimeError(f"Suspiciously small download: {dest}")
    print(f"Downloaded {dest} ({dest.stat().st_size / 1024 / 1024:.1f} MiB)")
    return dest

def flatten_files(node, prefix=""):
    out = []
    if isinstance(node, dict):
        if isinstance(node.get("url"), str):
            out.append((prefix, node))
        else:
            for key, value in node.items():
                if key in ("include",): continue
                out.extend(flatten_files(value, f"{prefix}/{key}".strip("/")))
    return out

def choose_resolution(tree, fmt, preferred=("4k", "2k", "1k")):
    for res in preferred:
        candidate = tree.get(res)
        if isinstance(candidate, dict) and fmt in candidate:
            return res, candidate[fmt]
    return None, None

manifest = {"license": "CC0 1.0", "source": "Poly Haven", "models": {}, "textures": {}}
credits = ["# Open Road asset credits", "", "All assets below are from Poly Haven and released under CC0 1.0.", ""]

# Real, detailed environment props. 4K avoids absurdly large 8K foliage payloads on mobile.
model_ids = ["pine_tree_01", "street_lamp_01", "covered_car", "old_tyre", "concrete_road_barrier"]
for slug in model_ids:
    try:
        tree = get_json(f"{API}/files/{slug}")
        branch = tree.get("gltf", {})
        res, item = choose_resolution(branch, "gltf")
        if not item:
            print(f"Skipping {slug}: no glTF download")
            continue
        folder = ROOT / "models" / slug
        folder.mkdir(parents=True, exist_ok=True)
        model_url = item["url"]
        model_name = Path(urlparse(model_url).path).name or "model.gltf"
        download(model_url, folder / "model.gltf")
        downloaded = ["model.gltf"]
        for relpath, dep in item.get("include", {}).items():
            safe = Path(relpath)
            if safe.is_absolute() or ".." in safe.parts:
                raise RuntimeError(f"Unsafe include path for {slug}: {relpath}")
            download(dep["url"], folder / safe)
            downloaded.append(str(safe).replace("\\", "/"))
        manifest["models"][slug] = {
            "scene": f"res://assets/polyhaven/models/{slug}/model.gltf",
            "resolution": res,
            "files": downloaded,
        }
        credits.append(f"- {slug}: https://polyhaven.com/a/{slug} (CC0 1.0)")
    except Exception as exc:
        print(f"Model asset warning ({slug}): {exc}")

# Search by surface intent, then download the full 4K JPG PBR map set.
texture_queries = {
    "asphalt": "asphalt road",
    "grass": "grass ground",
    "dirt": "dry dirt ground",
    "concrete": "weathered concrete",
    "rock": "rock surface",
    "bark": "tree bark",
}
used = set()
for key, query in texture_queries.items():
    try:
        result = get_json(f"{API}/search?q={urllib.parse.quote(query)}&t=textures&limit=10")
        candidates = [x.get("slug") for x in result.get("results", []) if x.get("slug")]
        slug = next((s for s in candidates if s not in used), None)
        if not slug:
            print(f"No unique texture match for {query}")
            continue
        used.add(slug)
        files = get_json(f"{API}/files/{slug}")
        maps = {}
        for map_name, resolutions in files.items():
            if map_name in ("blend", "gltf", "fbx", "usd"):
                continue
            if not isinstance(resolutions, dict):
                continue
            res = next((r for r in ("4k", "2k", "1k") if isinstance(resolutions.get(r), dict)), None)
            if not res:
                continue
            formats = resolutions[res]
            fmt = "jpg" if "jpg" in formats else ("png" if "png" in formats else None)
            if not fmt:
                continue
            entry = formats[fmt]
            dest = ROOT / "textures" / key / Path(urlparse(entry["url"]).path).name
            download(entry["url"], dest)
            maps[map_name.lower()] = f"res://{dest.as_posix()}"
        if maps:
            manifest["textures"][key] = {"slug": slug, "maps": maps}
            credits.append(f"- {slug}: https://polyhaven.com/a/{slug} (CC0 1.0)")
    except Exception as exc:
        print(f"Texture asset warning ({key}): {exc}")

(ROOT / "asset_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(ROOT / "CREDITS.md").write_text("\n".join(credits) + "\n", encoding="utf-8")
if not manifest["models"] and not manifest["textures"]:
    raise SystemExit("No Poly Haven assets were downloaded; refusing to build a fake large APK.")
print("Manifest written:", len(manifest["models"]), "models,", len(manifest["textures"]), "PBR materials")
