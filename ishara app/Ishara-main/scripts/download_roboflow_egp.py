"""Download an Egyptian-Pound currency dataset from Roboflow Universe.

Outputs a folder layout that `scripts/train_egp_classifier.py` expects:

    data/egp/
        train/<denomination>/*.jpg
        val/<denomination>/*.jpg
        test/<denomination>/*.jpg

Usage:

    pip install roboflow pillow tqdm
    export ROBOFLOW_API_KEY=...     # Windows: set ROBOFLOW_API_KEY=...
    python scripts/download_roboflow_egp.py

The script tries the pinned project first, then falls back to a list of
alternates (in case any project is set to private). Edit `PROJECTS` if a
better dataset becomes available.

Class folder names match the keys in `denominationToEgp` in
`lib/src/features/vision/data/currency_classifier.dart` so training can
emit a TFLite that drops straight into the app.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

# (workspace, project, version) tuples — first hit wins.
# Edit if any project is renamed / removed on Roboflow.
PROJECTS = [
    ("egyptian-currency", "egyptian-currency-detection", 1),
    ("ahmed-1pwzr", "egyptian-pound-bank-notes", 2),
    ("egyptian-currency-y4qoz", "egyptian-currency-2", 3),
]

# Maps Roboflow class names → canonical Ishara denomination buckets.
# Anything not listed here is dropped.
ALIASES = {
    # banknotes
    "1": "1 EGP",
    "1_pound": "1 EGP",
    "1_egp": "1 EGP",
    "5": "5 EGP",
    "5_pound": "5 EGP",
    "5_egp": "5 EGP",
    "10": "10 EGP",
    "10_pound": "10 EGP",
    "10_egp": "10 EGP",
    "20": "20 EGP",
    "20_pound": "20 EGP",
    "20_egp": "20 EGP",
    "50": "50 EGP",
    "50_pound": "50 EGP",
    "50_egp": "50 EGP",
    "100": "100 EGP",
    "100_pound": "100 EGP",
    "100_egp": "100 EGP",
    "200": "200 EGP",
    "200_pound": "200 EGP",
    "200_egp": "200 EGP",
    # coins
    "25_piaster": "25 piaster",
    "25piaster": "25 piaster",
    "50_piaster": "50 piaster",
    "50piaster": "50 piaster",
    "1_pound_coin": "1 EGP coin",
    "1pound_coin": "1 EGP coin",
    "background": "background",
}


def normalise_class_dirs(root: Path) -> None:
    """Rename every Roboflow class folder under root/{train,val,test}/ to the
    canonical Ishara name. Unknown classes are deleted."""
    for split in ("train", "val", "test"):
        split_dir = root / split
        if not split_dir.is_dir():
            continue
        for d in list(split_dir.iterdir()):
            if not d.is_dir():
                continue
            target_name = ALIASES.get(d.name.lower().strip())
            if target_name is None:
                # not a denomination we care about → skip
                shutil.rmtree(d, ignore_errors=True)
                continue
            target = split_dir / target_name
            target.mkdir(parents=True, exist_ok=True)
            for f in d.iterdir():
                shutil.move(str(f), target / f.name)
            shutil.rmtree(d, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-key", default=os.environ.get("ROBOFLOW_API_KEY", ""))
    parser.add_argument("--out", default="data/egp")
    args = parser.parse_args()

    if not args.api_key:
        print("ROBOFLOW_API_KEY not set. Get a free key at https://app.roboflow.com.")
        return 1

    try:
        from roboflow import Roboflow  # type: ignore
    except ImportError:
        print("Run: pip install roboflow pillow tqdm")
        return 1

    rf = Roboflow(api_key=args.api_key)

    out_root = Path(args.out)
    if out_root.exists():
        print(f"Removing existing {out_root}")
        shutil.rmtree(out_root)
    out_root.mkdir(parents=True)

    last_err: Exception | None = None
    for ws, proj, ver in PROJECTS:
        try:
            print(f"Trying {ws}/{proj} v{ver}…")
            project = rf.workspace(ws).project(proj)
            dataset = project.version(ver).download("folder", location=str(out_root), overwrite=True)
            print(f"OK — downloaded into {dataset.location}")
            break
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            print(f"  failed: {exc}")
            continue
    else:
        print(f"All projects failed; last error: {last_err}")
        return 1

    # Roboflow "folder" format already produces train/val/test subfolders.
    normalise_class_dirs(out_root)
    print(f"Cleaned dataset at {out_root.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
