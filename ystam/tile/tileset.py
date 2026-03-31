"""TileSet: manages tile type population with weighted random selection."""

from __future__ import annotations

import numpy as np

from ystam.helpers import combinations
from ystam.tile.glue import (
    Glue,
    NULL,
    enum_glues,
    eval_tile_defn,
    is_direction,
    is_turning,
    same_corner,
    same_dir,
    same_side,
)

# 8 radial directions
RADIAL_DIRS = ["NL", "NR", "SR", "SL", "WU", "WD", "EU", "ED"]


class TileSet:
    """Manages tile types and their concentrations for weighted random selection.

    A tile definition is a 6-element list:
        [fwd_in, bwd_in, fwd_out1, fwd_out2, bwd_out1, bwd_out2]
    where fwd_out2/bwd_out2 are None for standard (non-branching) tiles.
    """

    def __init__(
        self,
        mode: str = "radial",
        use_tile_conc: bool = False,
        kd: float = 1.0,
        conc_max: float = 100.0,
        rng: np.random.Generator | None = None,
    ) -> None:
        self.kd = kd
        self.conc_max = conc_max
        self.use_tile_conc = use_tile_conc
        self.rng = rng or np.random.default_rng()

        if mode == "radial":
            self.tile_types, self.concs = self._init_radial_tile_set(conc_max)
        else:
            raise ValueError(f"Unsupported mode: {mode}")

    # ------------------------------------------------------------------
    # Concentration modifiers
    # ------------------------------------------------------------------

    def dec_conc(self, defn: list[Glue | None]) -> None:
        """Decrease concentration of matching tile type by 1."""
        idx = self._find_defn_index(defn)
        if idx is not None and self.concs[idx] > 0:
            self.concs[idx] -= 1

    def inc_conc(self, defn: list[Glue | None]) -> None:
        """Increase concentration of matching tile type by 1."""
        idx = self._find_defn_index(defn)
        if idx is not None:
            self.concs[idx] += 1

    def buffer(self, num: float) -> None:
        """Increase all tile concentrations by num."""
        self.concs = [c + num for c in self.concs]

    def apply_branching_factor(self, b: float) -> None:
        """Scale concentration of branching tiles by factor b."""
        for i, defn in enumerate(self.tile_types):
            if defn[3] is not None and defn[5] is not None:
                self.concs[i] *= b

    def apply_turning_factor(self, t: float) -> None:
        """Scale concentration of turning tiles by factor t."""
        for i, defn in enumerate(self.tile_types):
            if is_turning(defn):
                self.concs[i] *= t

    def apply_direction_bias(self, d: list[float]) -> None:
        """Scale concentrations by output direction.

        d indices: [NL, NR, EU, ED, SR, SL, WD, WU].
        """
        dir_map = {
            "NL": 0, "NR": 1, "EU": 2, "ED": 3,
            "SR": 4, "SL": 5, "WD": 6, "WU": 7,
        }
        for i, defn in enumerate(self.tile_types):
            if eval_tile_defn(defn) == "branching":
                continue
            out = defn[2]
            if out is not None:
                direction = out.direction
                if direction in dir_map:
                    self.concs[i] *= d[dir_map[direction]]

    # ------------------------------------------------------------------
    # Random tile selection
    # ------------------------------------------------------------------

    def get_weighted_random(self) -> list[Glue | None]:
        """Select a random tile type weighted by concentration."""
        total = sum(self.concs)
        if total <= 0:
            return [None] * 6
        probs = [c / total for c in self.concs]
        idx = self.rng.choice(len(self.tile_types), p=probs)
        return list(self.tile_types[idx])

    def get_weighted_filtered_random(self, input_glue: Glue) -> list[Glue | None] | None:
        """Select a random compatible tile type that accepts the given input glue.

        Returns the tile definition or None if no valid tile exists / binding check fails.
        """
        filtered, filtered_concs = self._filter_by_input(input_glue)
        if not filtered:
            return None

        # Weight by Michaelis-Menten or linear
        conc_arr = np.array(filtered_concs, dtype=float)
        if self.use_tile_conc:
            weights = conc_arr / (self.kd + conc_arr)
        else:
            total = conc_arr.sum()
            if total <= 0:
                return None
            weights = conc_arr / total

        total_w = weights.sum()
        if total_w <= 0:
            return None

        # CDF-based selection matching MATLAB behavior
        cdf = np.concatenate(([0.0], np.cumsum(weights)))
        x = cdf[0] + self.rng.random() * (cdf[-1] - cdf[0])
        selected_idx = 0
        for j in range(1, len(cdf)):
            if cdf[j - 1] < x <= cdf[j]:
                selected_idx = j - 1
                break

        defn = list(filtered[selected_idx])

        # If tile concentration enabled, apply binding probability check
        if self.use_tile_conc:
            tile_conc = filtered_concs[selected_idx]
            p_binding = tile_conc / (self.kd + tile_conc)
            if self.rng.random() >= p_binding:
                return None

        return defn

    # ------------------------------------------------------------------
    # Tile set initialization
    # ------------------------------------------------------------------

    @staticmethod
    def _init_radial_tile_set(
        concentration: float,
    ) -> tuple[list[list[Glue | None]], list[float]]:
        """Generate all valid radial tile types with their concentrations."""
        tile_list: list[list[Glue | None]] = []
        concs: list[float] = []

        fwd_in = enum_glues("F", "I", RADIAL_DIRS)
        fwd_out = enum_glues("F", "O", RADIAL_DIRS)
        bwd_in = enum_glues("B", "I", RADIAL_DIRS)
        bwd_out = enum_glues("B", "O", RADIAL_DIRS)

        # Standard tiles: 1 input -> 1 output
        for i, fi in enumerate(fwd_in):
            for o, fo in enumerate(fwd_out):
                if not same_side(fi, fo) and not same_corner(fi, fo):
                    tile_list.append([fi, bwd_in[i], fo, None, bwd_out[o], None])
                    concs.append(concentration)

        # Branching tiles: 1 input -> 2 outputs
        fwd_combos = combinations(fwd_out, fwd_out)
        bwd_combos = combinations(bwd_out, bwd_out)

        for i, fi in enumerate(fwd_in):
            for (fo1, fo2), (bo1, bo2) in zip(fwd_combos, bwd_combos):
                if (
                    not same_side(fi, fo1)
                    and not same_side(fi, fo2)
                    and same_side(fo1, fo2)
                    and not same_dir(fo1, fo2)
                    and not same_corner(fi, fo1)
                    and not same_corner(fi, fo2)
                ):
                    tile_list.append([fi, bwd_in[i], fo1, fo2, bo1, bo2])
                    concs.append(concentration)

        return tile_list, concs

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _filter_by_input(
        self, input_glue: Glue
    ) -> tuple[list[list[Glue | None]], list[float]]:
        """Return tile types whose first input matches the given glue."""
        filtered = []
        filtered_concs = []
        for defn, conc in zip(self.tile_types, self.concs):
            if defn[0] is not None and defn[0] == input_glue:
                filtered.append(defn)
                filtered_concs.append(conc)
        return filtered, filtered_concs

    def _find_defn_index(self, defn: list[Glue | None]) -> int | None:
        """Find index of a tile definition in the tile set."""
        for i, td in enumerate(self.tile_types):
            if td == defn:
                return i
        return None
