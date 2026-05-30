"""Download the KArSL Arabic-Sign-Language dataset (or its public mirror).

The official KArSL requires a researcher request form. This script tries
the public KArSL-100 / KArSL-502 mirrors on Kaggle and HuggingFace first;
fall back to the official tar after you place the credentials it needs.

Usage:

    pip install kaggle huggingface-hub tqdm
    # Either:
    export KAGGLE_USERNAME=...
    export KAGGLE_KEY=...
    # Or:
    huggingface-cli login

    python scripts/karsl/download_karsl.py --variant karsl-100 --out data/karsl

Output layout (matches what `extract_holistic_keypoints.py` expects):

    data/karsl/
        videos/<class_name>/<signer>_<rep>.mp4
        meta.csv          # one row per video: path, class, signer
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
import zipfile
from pathlib import Path

KAGGLE_DATASETS = {
    "karsl-100": "tareqsouhihasan/karsl-100",  # 100 isolated signs
    "karsl-502": "khalid20/karsl-502",         # full set
}

HF_DATASETS = {
    "karsl-100": "AhmedSSoliman/KArSL-100",
    "karsl-502": "AhmedSSoliman/KArSL-502",
}


def from_kaggle(slug: str, dest: Path) -> bool:
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi  # type: ignore
    except ImportError:
        print("Kaggle SDK not installed (pip install kaggle).")
        return False
    if not (os.environ.get("KAGGLE_USERNAME") and os.environ.get("KAGGLE_KEY")):
        return False
    api = KaggleApi()
    api.authenticate()
    print(f"Downloading {slug} from Kaggle…")
    api.dataset_download_files(slug, path=str(dest), unzip=True, quiet=False)
    return True


def from_hf(slug: str, dest: Path) -> bool:
    try:
        from huggingface_hub import snapshot_download  # type: ignore
    except ImportError:
        print("huggingface-hub not installed (pip install huggingface-hub).")
        return False
    print(f"Downloading {slug} from HuggingFace…")
    snapshot_download(repo_id=slug, repo_type="dataset", local_dir=str(dest), allow_patterns="*")
    return True


def build_meta(dest: Path) -> None:
    """Walk dest/videos/<class>/<file> and write a meta.csv."""
    videos_root = dest / "videos"
    if not videos_root.is_dir():
        # Some mirrors flatten everything into root — try to locate.
        for cand in dest.rglob("*.mp4"):
            videos_root = cand.parents[1]
            break
    rows: list[tuple[str, str, str]] = []
    for cls_dir in sorted(videos_root.iterdir()):
        if not cls_dir.is_dir():
            continue
        for video in cls_dir.glob("*.mp4"):
            stem = video.stem
            signer = stem.split("_")[0] if "_" in stem else "unknown"
            rows.append((str(video.relative_to(dest)), cls_dir.name, signer))
    meta = dest / "meta.csv"
    with meta.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["path", "class", "signer"])
        writer.writerows(rows)
    print(f"Wrote {meta} ({len(rows)} videos)")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=list(KAGGLE_DATASETS), default="karsl-100")
    parser.add_argument("--out", default="data/karsl")
    parser.add_argument("--source", choices=("auto", "kaggle", "hf"), default="auto")
    args = parser.parse_args()

    dest = Path(args.out)
    dest.mkdir(parents=True, exist_ok=True)

    ok = False
    if args.source in ("auto", "kaggle"):
        ok = from_kaggle(KAGGLE_DATASETS[args.variant], dest)
    if not ok and args.source in ("auto", "hf"):
        ok = from_hf(HF_DATASETS[args.variant], dest)
    if not ok:
        print("All sources failed. Place the dataset manually under", dest)
        return 1

    # Some Kaggle archives ship as nested zips; flatten any *.zip.
    for z in list(dest.rglob("*.zip")):
        with zipfile.ZipFile(z) as zf:
            zf.extractall(z.parent)
        z.unlink()

    build_meta(dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
