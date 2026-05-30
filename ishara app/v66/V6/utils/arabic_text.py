import os
from typing import Tuple

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from arabic_reshaper import reshape
from bidi.algorithm import get_display


def put_arabic_text(
    img: np.ndarray,
    text: str,
    position: Tuple[int, int],
    font_size: int = 32,
    text_color: Tuple[int, int, int] = (255, 255, 255),
    bold: bool = True,
) -> np.ndarray:
    """
    Render Arabic text on an OpenCV image with proper shaping and bidi support.

    This is a refactored version of the working V4 implementation, made
    reusable across capture, training overlays, and real-time detection.
    """
    try:
        reshaped_text = reshape(text)
        bidi_text = get_display(reshaped_text)
    except Exception:
        bidi_text = text

    img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)

    font_paths = [
        # Windows Arabic-friendly fonts
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/tahoma.ttf",
        "C:/Windows/Fonts/tahomabd.ttf",
        "C:/Windows/Fonts/arabtype.ttf",
        "C:/Windows/Fonts/simplarab.ttf",
        # Linux
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        # macOS
        "/System/Library/Fonts/Arial.ttf",
        # Fallbacks
        "arial.ttf",
        "tahoma.ttf",
    ]

    font = None
    for path in font_paths:
        try:
            if os.path.exists(path):
                actual_font_size = int(font_size * 1.1)
                if bold and any(k in path.lower() for k in ["bold", "bd"]):
                    font = ImageFont.truetype(path, actual_font_size)
                    break
        except Exception:
            continue

    if font is None:
        for path in font_paths:
            try:
                if os.path.exists(path):
                    actual_font_size = int(font_size * 1.1)
                    font = ImageFont.truetype(path, actual_font_size)
                    break
            except Exception:
                continue

    if font is None:
        font = ImageFont.load_default()

    x, y = position
    outline_color = (0, 0, 0)
    outline_thickness = 2

    # Outline for visibility
    for dx in range(-outline_thickness, outline_thickness + 1, 2):
        for dy in range(-outline_thickness, outline_thickness + 1, 2):
            if dx == 0 and dy == 0:
                continue
            try:
                draw.text((x + dx, y + dy), bidi_text, font=font, fill=outline_color)
            except Exception:
                pass

    try:
        draw.text(position, bidi_text, font=font, fill=text_color)
    except Exception:
        pass

    return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)

