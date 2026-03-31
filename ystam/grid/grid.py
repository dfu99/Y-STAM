"""Grid: spatial environment and tile population state."""

from __future__ import annotations

import numpy as np

from ystam.grid.ecm import layer_update
from ystam.helpers import pos2idx, idx2pos
from ystam.tile.glue import NULL, parse_glue
from ystam.tile.tile import Tile, ON, LATENT, UNUSED
from ystam.tile.tileset import TileSet


class Grid:
    """n x n spatial grid holding tiles and auxiliary layers (ECM, heatmap).

    Uses 1-based indexing for tile positions to match MATLAB semantics.
    The LUT (lookup table) maps 1-based linear indices to Tile objects.
    """

    def __init__(
        self,
        n: int,
        growth_mode: str,
        source_branches: int,
        g_se: float,
        tile_set: TileSet,
        rng: np.random.Generator | None = None,
    ) -> None:
        self.n = n
        self.growth_mode = growth_mode
        self.source_branches = source_branches
        self.g_se = g_se
        self.tile_set = tile_set
        self.rng = rng or np.random.default_rng()

        # Core state
        self.lut: dict[int, Tile] = {}
        self.ecmtx = np.zeros((n, n))
        self.heatmap = np.zeros((n, n))

        # Source/goal management
        self.t0: list[Tile] = []
        self.tf: list[Tile] = []
        self.source_tiles: list[tuple[int, int]] = [(n // 2, 1)]
        self.goal_tiles: list[tuple[int, int]] = []
        self.source_colors: list[tuple[float, float, float]] | None = None

        # Auxiliary settings
        self.deadzone: list[tuple[float, float, float, float]] = []
        self.has_dead_zone = False
        self.cstrength_source = 0.0
        self.cradius_source = 0.0
        self.cstrength_goal = 0.0
        self.cradius_goal = 0.0
        self.has_trunk = False
        self.track: list[tuple[float, float, float]] = []
        self.has_track = False

    # ------------------------------------------------------------------
    # Reset
    # ------------------------------------------------------------------

    def reset(self) -> None:
        """Clear grid, re-place source/goal/obstacles."""
        self.lut = {}
        self.ecmtx = np.zeros((self.n, self.n))
        self.heatmap = np.zeros((self.n, self.n))
        self.t0 = []
        self.tf = []
        self.add_source_tiles()
        self.add_goal_tiles()
        if self.has_dead_zone:
            self.add_dead_zone()
        if self.has_trunk:
            self.add_trunk()
        if self.has_track:
            self.add_track()

    # ------------------------------------------------------------------
    # Source tiles
    # ------------------------------------------------------------------

    def init_sources(
        self,
        num: int = 1,
        positions: list[tuple[int, int]] | None = None,
    ) -> None:
        """Determine source tile positions."""
        if positions is not None and len(positions) == num:
            self.source_tiles = list(positions)
        elif num == 1:
            center = self.n // 2
            # Ensure checkerboard parity
            if (center + center) % 2 != 1:
                center += 1
            self.source_tiles = [(center, center)]
        else:
            # Random placement with checkerboard parity
            mod_pattern = 1
            tiles = []
            while len(tiles) < num:
                pos = (self.rng.integers(1, self.n + 1), self.rng.integers(1, self.n + 1))
                if (pos[0] + pos[1]) % 2 == mod_pattern:
                    tiles.append(pos)
            self.source_tiles = tiles

    def add_source_tiles(self) -> None:
        """Place source tiles at their positions."""
        for i, (sx, sy) in enumerate(self.source_tiles):
            glue_list = self.tile_set.get_weighted_random()
            t = Tile(glue_list, self.g_se)
            t.set_type("radial-source", self.source_branches)
            t.position = (sx, sy)
            t.color_flag = 2
            if self.source_colors and i < len(self.source_colors):
                t.seed_coloring = i + 1
            idx = pos2idx(sx, sy, self.n)
            self.lut[idx] = t
            self.t0.append(t)

    # ------------------------------------------------------------------
    # Goal tiles
    # ------------------------------------------------------------------

    def init_goals(
        self,
        num: int = 1,
        positions: list[tuple[int, int]] | None = None,
    ) -> None:
        """Determine goal tile positions."""
        if num == 0:
            self.goal_tiles = []
            return

        if positions is not None and len(positions) == num:
            # Adjust parity if needed
            mod_pattern = (self.source_tiles[0][0] + self.source_tiles[0][1]) % 2
            adjusted = []
            for px, py in positions:
                if (px + py) % 2 != mod_pattern:
                    px += 1
                adjusted.append((px, py))
            self.goal_tiles = adjusted
        elif self.growth_mode == "radial":
            mod_pattern = (self.source_tiles[0][0] + self.source_tiles[0][1]) % 2
            # Build exclusion set around sources
            exclusion = set()
            offsets = [(0, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
            for sx, sy in self.source_tiles:
                for dx, dy in offsets:
                    exclusion.add((sx + dx, sy + dy))

            tiles = []
            goal_exclusion = set()
            while len(tiles) < num:
                rx = int(self.rng.integers(1, self.n + 1))
                ry = int(self.rng.integers(1, self.n + 1))
                pos = (rx, ry)
                if pos in exclusion or pos in goal_exclusion:
                    continue
                if (rx + ry) % 2 != mod_pattern:
                    continue
                tiles.append(pos)
                for dx, dy in offsets:
                    goal_exclusion.add((rx + dx, ry + dy))

            self.goal_tiles = tiles
        else:
            raise ValueError("Linear mode not supported")

    def add_goal_tiles(self) -> None:
        """Place goal tiles at their positions."""
        for gx, gy in self.goal_tiles:
            glue_list = self.tile_set.get_weighted_random()
            t = Tile(glue_list, self.g_se)
            t.set_type("radial-goal")
            t.fb_state = 1.0
            t.position = (gx, gy)
            t.color_flag = 3
            idx = pos2idx(gx, gy, self.n)
            self.lut[idx] = t
            self.tf.append(t)

    # ------------------------------------------------------------------
    # Dead zones
    # ------------------------------------------------------------------

    def set_dead_zone(self, zones: list[tuple[float, float, float, float]]) -> None:
        """Set dead zone rectangles as normalized (left, bottom, width, height)."""
        self.deadzone = zones
        self.has_dead_zone = True

    def add_dead_zone(self) -> None:
        """Place dead tiles in all dead zone areas."""
        for left, bottom, width, height in self.deadzone:
            if width + height <= 0:
                continue
            l = max(1, int(np.ceil(self.n * left)))
            b = max(1, int(np.ceil(self.n * bottom)))
            w = int(np.floor(self.n * width))
            h = int(np.floor(self.n * height))
            for col in range(l, l + w + 1):
                for row in range(b, b + h + 1):
                    if 1 <= row <= self.n and 1 <= col <= self.n:
                        idx = pos2idx(row, col, self.n)
                        null_glues = [None] * 6
                        t = Tile(null_glues, 0)
                        t.set_type("dead")
                        t.position = (row, col)
                        self.lut[idx] = t

    # ------------------------------------------------------------------
    # Chemotropism (trunks)
    # ------------------------------------------------------------------

    def set_trunk(self, cmode: tuple[float, float, float, float]) -> None:
        """Set chemotropism parameters: (source_str, source_rad, goal_str, goal_rad)."""
        self.has_trunk = True
        self.cstrength_source = cmode[0]
        self.cradius_source = cmode[1]
        self.cstrength_goal = cmode[2]
        self.cradius_goal = cmode[3]

    def add_trunk(self) -> None:
        """Deposit chemotropic ECM around source and goal tiles."""
        if self.cstrength_source > 0 and self.t0:
            self.ecmtx = layer_update(
                self.ecmtx,
                (self.cstrength_source, self.cradius_source),
                self.t0,
                self.n,
                "FirstOrder",
            )
        if self.cstrength_goal > 0 and self.tf:
            # Emit from ALL goal tiles (improvement over MATLAB which uses only first)
            self.ecmtx = layer_update(
                self.ecmtx,
                (self.cstrength_goal, self.cradius_goal),
                self.tf,
                self.n,
                "FirstOrder",
            )

    # ------------------------------------------------------------------
    # Track
    # ------------------------------------------------------------------

    def set_track(self, track: list[tuple[float, float, float]]) -> None:
        """Set ECM track waypoints: [(y_norm, x_norm, strength), ...]."""
        self.track = track
        self.has_track = True

    def add_track(self) -> None:
        """Draw ECM tracks between consecutive waypoints."""
        for i in range(len(self.track) - 1):
            r0 = round(self.track[i][0] * self.n)
            c0 = round(self.track[i][1] * self.n)
            r1 = round(self.track[i + 1][0] * self.n)
            c1 = round(self.track[i + 1][1] * self.n)
            strength = self.track[i][2]
            if c1 == c0:
                for r in range(min(r0, r1), max(r0, r1) + 1):
                    self.ecmtx = layer_update(
                        self.ecmtx, (strength, 1.5, 1.0), [(r, c0)], self.n, "Flat"
                    )
            else:
                m = (r1 - r0) / (c1 - c0)
                b = r1 - m * c1
                for c in range(min(c0, c1), max(c0, c1) + 1):
                    r = round(m * c + b)
                    self.ecmtx = layer_update(
                        self.ecmtx, (strength, 1.5, 1.0), [(r, c)], self.n, "Flat"
                    )

    # ------------------------------------------------------------------
    # Grid visualization helpers
    # ------------------------------------------------------------------

    def lut_to_grid(self) -> np.ndarray:
        """Convert LUT to visual grid array using ColorFlag values."""
        grid = np.zeros((self.n, self.n))
        for idx, tile in self.lut.items():
            x, y = tile.position
            if tile.seed_coloring != 0:
                grid[x - 1, y - 1] = 4 + tile.seed_coloring
            else:
                grid[x - 1, y - 1] = tile.color_flag
        return grid

    def get_snapshot(self) -> dict[int, Tile]:
        """Return a shallow copy of the LUT for state comparison."""
        return dict(self.lut)
