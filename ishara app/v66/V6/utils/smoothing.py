from collections import deque
from dataclasses import dataclass
from time import time
from typing import Deque, List, Optional, Tuple

import numpy as np


@dataclass
class TemporalSmoother:
    """
    Temporal smoothing for classification logits/probabilities.

    Keeps a fixed-size window of predictions and applies:
    - mean probability over the window
    - confidence threshold
    - cooldown control for UI updates
    """

    window_size: int
    confidence_threshold: float
    cooldown_seconds: float

    def __post_init__(self) -> None:
        self._probs_window: Deque[np.ndarray] = deque(maxlen=self.window_size)
        self._last_accept_time: float = 0.0

    def reset(self) -> None:
        self._probs_window.clear()
        self._last_accept_time = 0.0

    def update(self, probs: np.ndarray) -> Tuple[Optional[int], Optional[float]]:
        """
        Update the window with a new probability vector.

        Returns:
            (predicted_index, confidence) if a smoothed prediction is accepted,
            otherwise (None, None).
        """
        if probs.ndim != 1:
            raise ValueError("Expected 1D probability vector.")

        self._probs_window.append(probs.astype(np.float32))

        if len(self._probs_window) < self.window_size:
            return None, None

        mean_probs = np.mean(np.stack(list(self._probs_window), axis=0), axis=0)
        pred_idx = int(np.argmax(mean_probs))
        confidence = float(mean_probs[pred_idx])

        now = time()
        if (
            confidence >= self.confidence_threshold
            and (now - self._last_accept_time) >= self.cooldown_seconds
        ):
            self._last_accept_time = now
            return pred_idx, confidence

        return None, None

