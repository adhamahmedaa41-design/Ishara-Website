"""
Cleanup utility to remove sequences with mismatched keypoint shapes.
Run this after updating the extraction code to fix old data.
"""

from pathlib import Path
import numpy as np
from config import PathsConfig


def check_and_clean_sequences(base_dir: Path) -> None:
    """
    Check all sequences for shape inconsistencies and delete bad ones.
    Prints a report of what was cleaned.
    """
    data_dir = base_dir / "MP_Data_Custom"
    
    if not data_dir.exists():
        print("No data directory found!")
        return
    
    removed_count = 0
    
    for word_dir in sorted(data_dir.iterdir()):
        if not word_dir.is_dir():
            continue
        
        word = word_dir.name
        bad_seqs = []
        
        for seq_dir in sorted(word_dir.iterdir()):
            if not seq_dir.is_dir() or not seq_dir.name.isdigit():
                continue
            
            shapes = []
            for frame_idx in range(30):  # sequence_length = 30
                npy_path = seq_dir / f"{frame_idx}.npy"
                if npy_path.exists():
                    arr = np.load(str(npy_path))
                    shapes.append(arr.shape[0])
            
            # Check if all frames have the same shape (1692)
            if shapes and (len(set(shapes)) > 1 or shapes[0] != 1692):
                bad_seqs.append((seq_dir.name, shapes))
        
        if bad_seqs:
            print(f"\n{word}:")
            for seq_name, shapes in bad_seqs:
                seq_dir = word_dir / seq_name
                print(f"  Sequence {seq_name}: shapes {set(shapes)} - REMOVING")
                
                # Remove all files in the sequence directory
                for npy_file in seq_dir.glob("*.npy"):
                    npy_file.unlink()
                seq_dir.rmdir()
                removed_count += 1
        else:
            print(f"\n{word}: ✓ All sequences OK")
    
    print(f"\n{'='*50}")
    print(f"Total sequences removed: {removed_count}")
    print(f"Re-record these sequences and everything will work!")


if __name__ == "__main__":
    cfg = PathsConfig()
    check_and_clean_sequences(cfg.base_dir)
