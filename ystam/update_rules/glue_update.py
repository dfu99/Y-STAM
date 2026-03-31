"""Glue update rule: ECM-modulated retention probability."""

from __future__ import annotations

import numpy as np


def glue_update(strength: float, memory: float) -> float:
    """Compute retention probability given glue strength and ECM memory.

    Args:
        strength: Glue binding strength in [0, 1]. Higher = more stable.
        memory: ECM signal at tile position.
            Positive memory stabilizes (increases retention).
            Negative memory destabilizes (decreases retention).

    Returns:
        Retention probability in [0, 1].
    """
    sigmoid = 2.0 / (1.0 + np.exp(-memory)) - 1.0
    r_pos = (1.0 - strength) * sigmoid
    r_neg = strength * sigmoid
    rate = strength + (memory > 0) * r_pos + (memory < 0) * r_neg
    return float(rate)
