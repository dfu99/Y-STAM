"""Extracellular matrix (ECM): spatial memory layer with signal deposition and decay."""

from __future__ import annotations

import numpy as np

from ystam.helpers import pos2idx


def layer_update(
    ecmtx: np.ndarray,
    ecm_vars: tuple[float, ...],
    tiles: list,
    n: int,
    profile: str,
) -> np.ndarray:
    """Deposit signal into ECM around tile positions.

    Args:
        ecmtx: n x n ECM matrix.
        ecm_vars: (strength, radius) or (strength, radius, refresh_rate).
        tiles: List of Tile objects or (x, y) tuples.
        n: Grid dimension.
        profile: Signal profile type (FirstOrder, FirstOrderSum, FlatSum, Flat, etc.).

    Returns:
        Updated ECM matrix.
    """
    signal_strength = ecm_vars[0]
    signal_radius = ecm_vars[1]
    mrr = ecm_vars[2] if len(ecm_vars) >= 3 else 0.0

    for item in tiles:
        if item is None:
            continue
        # Get position from Tile object or tuple
        if hasattr(item, "position"):
            trow, tcol = item.position
        else:
            trow, tcol = item[0], item[1]

        # Define bounding box around tile within radius
        r_lo = max(1, int(np.floor(trow - signal_radius)))
        r_hi = min(n, int(np.ceil(trow + signal_radius)))
        c_lo = max(1, int(np.floor(tcol - signal_radius)))
        c_hi = min(n, int(np.ceil(tcol + signal_radius)))

        for r in range(r_lo, r_hi + 1):
            for c in range(c_lo, c_hi + 1):
                # 1-based to 0-based for array indexing
                ri, ci = r - 1, c - 1
                d = np.sqrt((r - trow) ** 2 + (c - tcol) ** 2)
                current = ecmtx[ri, ci]

                if profile == "FirstOrder":
                    signal = signal_strength * np.exp(-d / max(signal_radius, 1e-10))
                elif profile == "FirstOrderSum":
                    signal = current + (signal_strength - current) * np.exp(
                        -d / max(signal_radius, 1e-10)
                    ) * mrr
                elif profile == "UnboundFirstOrderSum":
                    signal = current + signal_strength * np.exp(
                        -d / max(signal_radius, 1e-10)
                    )
                elif profile == "Linear":
                    signal = signal_strength * abs(signal_radius - d) / max(signal_radius, 1e-10)
                elif profile == "LinearSum":
                    signal = current + (signal_strength - current) * abs(
                        signal_radius - d
                    ) / max(signal_radius, 1e-10) * mrr
                elif profile == "Flat":
                    signal = signal_strength
                elif profile == "FlatSum":
                    signal = current + (signal_strength - current) * mrr
                else:
                    signal = signal_strength

                if signal > current:
                    ecmtx[ri, ci] = signal
                elif signal < 0:
                    ecmtx[ri, ci] = signal

    return ecmtx


def refresh_ecmtx(
    lut: dict[int, object],
    last_lut: dict[int, object],
    ecmtx: np.ndarray,
    ecm_strength: float,
    ecm_signal_radius: float,
    mtx_refresh_rate: float,
    mtx_decay_rate: float,
    mtx_decay_rate_on: float,
    n: int,
) -> np.ndarray:
    """Per-timestep ECM decay and deposition at newly placed tiles.

    Occupied cells decay slower than empty cells, preserving memory
    where hyphae are present.
    """
    # Build occupancy grids from last state
    last_grid = np.zeros((n, n))
    for idx, tile in last_lut.items():
        if tile is not None:
            x, y = tile.position
            last_grid[x - 1, y - 1] = 1.0

    # Differential decay: occupied cells decay slower
    occupied_factor = 1.0 / (2.0 ** (mtx_decay_rate * mtx_decay_rate_on))
    empty_factor = 1.0 / (2.0 ** mtx_decay_rate)
    ecmtx = (last_grid > 0) * ecmtx * occupied_factor + (last_grid == 0) * ecmtx * empty_factor

    # Build current occupancy grid
    curr_grid = np.zeros((n, n))
    for idx, tile in lut.items():
        if tile is not None and hasattr(tile, "color_flag"):
            x, y = tile.position
            if tile.color_flag == -1:
                curr_grid[x - 1, y - 1] = -1
            else:
                curr_grid[x - 1, y - 1] = 1

    # Find newly placed tiles (in current but not in last)
    delta = (curr_grid > 0).astype(float) - (last_grid > 0).astype(float)
    new_positions = np.argwhere(delta > 0)

    if ecm_strength > 0 and len(new_positions) > 0:
        profile = "FlatSum" if ecm_signal_radius == 0 else "FirstOrderSum"
        new_tiles = [(int(r) + 1, int(c) + 1) for r, c in new_positions]
        ecmtx = layer_update(
            ecmtx,
            (ecm_strength, ecm_signal_radius, mtx_refresh_rate),
            new_tiles,
            n,
            profile,
        )

    return ecmtx


def refresh_heatmap(lut: dict[int, object], heatmap: np.ndarray, n: int) -> np.ndarray:
    """Update heatmap: 0 where tile exists, increment where empty."""
    occupied = set()
    for idx, tile in lut.items():
        if tile is not None:
            x, y = tile.position
            occupied.add((x - 1, y - 1))

    for r in range(n):
        for c in range(n):
            if (r, c) in occupied:
                heatmap[r, c] = 0
            else:
                heatmap[r, c] += 1

    return heatmap
