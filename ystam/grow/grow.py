"""Growth mechanics: identify free edges and add tiles."""

from __future__ import annotations

import numpy as np

from ystam.grid.ecm import layer_update
from ystam.helpers import pos2idx
from ystam.tile.glue import Glue, can_bind, grow_offset
from ystam.tile.tile import Tile, ON, LATENT, UNUSED


def refresh_free_edges(lut: dict[int, Tile]) -> list[Tile]:
    """Find all tiles with active (ON) output connections — growth fronts."""
    free_edges: list[Tile] = []
    for tile in lut.values():
        if tile is None:
            continue
        for conn in tile.output_connections:
            if not isinstance(conn, Tile) and conn == ON:
                free_edges.append(tile)
                break  # Only add once per tile
    return free_edges


def can_grow(lut: dict[int, Tile], n: int, x: int, y: int) -> bool:
    """Check if position (x, y) is within bounds and unoccupied."""
    if not (1 <= x <= n and 1 <= y <= n):
        return False
    idx = pos2idx(x, y, n)
    return idx not in lut


def is_dead_tile(lut: dict[int, Tile], n: int, x: int, y: int) -> bool:
    """Check if position (x, y) contains a dead (obstacle) tile."""
    if not (1 <= x <= n and 1 <= y <= n):
        return False
    idx = pos2idx(x, y, n)
    tile = lut.get(idx)
    return tile is not None and tile.color_flag == -1


def bind_glues(tile1: Tile, glue1: Glue, tile2: Tile, glue2: Glue) -> None:
    """Connect tile1's output glue1 to tile2's input glue2."""
    if not can_bind(glue1, glue2):
        raise ValueError(f"{glue1} and {glue2} are non-complementary")

    output_idx = tile1.get_output_index(glue1)
    input_idx = tile2.get_input_index(glue2)
    tile1.output_connections[output_idx] = tile2
    tile2.input_connections[input_idx] = tile1


def grow_tile(
    lut: dict[int, Tile],
    ecmtx: np.ndarray,
    n: int,
    parent: Tile,
    new_defn: list,
    g1: Glue,
    g2: Glue,
    g_se: float,
    dz_params: tuple[float, float, float],
) -> tuple[dict[int, Tile], np.ndarray, bool]:
    """Attempt to grow a new tile from parent via glue g1.

    Returns (lut, ecmtx, success).
    """
    dx, dy = grow_offset(g1)
    tx = parent.position[0] + dx
    ty = parent.position[1] + dy

    if can_grow(lut, n, tx, ty):
        t2 = Tile(new_defn, g_se)
        t2.set_type("tile")
        t2.position = (tx, ty)
        t2.color_flag = 1
        t2.seed_coloring = parent.seed_coloring
        # Inherit severed state from parent
        if parent.severed:
            t2.severed = True
            t2.energy = parent.energy * 0.5
            t2.max_energy = t2.energy
        bind_glues(parent, g1, t2, g2)
        idx = pos2idx(tx, ty, n)
        lut[idx] = t2
        return lut, ecmtx, True
    elif is_dead_tile(lut, n, tx, ty):
        # Deposit negative ECM near parent when hitting obstacle
        dz_str, dz_rad, dz_rr = dz_params
        ecmtx = layer_update(ecmtx, (dz_str, dz_rad, dz_rr), [parent], n, "FirstOrder")
        return lut, ecmtx, False
    else:
        return lut, ecmtx, False


def add_tiles_to_free_edges(
    lut: dict[int, Tile],
    ecmtx: np.ndarray,
    n: int,
    free_edges: list[Tile],
    tile_set,
    g_se: float,
    use_tile_conc: bool,
    dz_params: tuple[float, float, float],
    rng: np.random.Generator | None = None,
    apoptosis_growth_cost: float = 0.0,
) -> tuple[dict[int, Tile], np.ndarray]:
    """For each growth front, probabilistically add new tiles."""
    for u in free_edges:
        # Severed tiles: 50% chance to skip growth, costs energy
        if u.severed:
            if rng is not None and rng.random() < 0.5:
                continue
            if u.energy < apoptosis_growth_cost:
                continue
        tile_class = u.eval_class()

        if tile_class == "branching":
            # Attach at ALL forward output glues
            for glue in u.output_glues:
                if glue is None or glue.channel != "F" or glue.io != "O":
                    continue
                g2 = glue.complement()
                new_defn = tile_set.get_weighted_filtered_random(g2)
                if new_defn is not None:
                    lut, ecmtx, ok = grow_tile(lut, ecmtx, n, u, new_defn, glue, g2, g_se, dz_params)
                    if ok:
                        if use_tile_conc:
                            tile_set.dec_conc(new_defn)
                        if u.severed:
                            u.energy -= apoptosis_growth_cost
        else:
            # Standard tile: first active FO output
            if (
                len(u.output_connections) > 0
                and not isinstance(u.output_connections[0], Tile)
                and u.output_connections[0] == ON
                and len(u.output_glues) > 0
                and u.output_glues[0] is not None
            ):
                glue1 = u.output_glues[0]
                g2 = glue1.complement()
                new_defn = tile_set.get_weighted_filtered_random(g2)
                if new_defn is not None:
                    lut, ecmtx, ok = grow_tile(lut, ecmtx, n, u, new_defn, glue1, g2, g_se, dz_params)
                    if ok:
                        if use_tile_conc:
                            tile_set.dec_conc(new_defn)
                        if u.severed:
                            u.energy -= apoptosis_growth_cost

    return lut, ecmtx
