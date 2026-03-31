"""Disassembly mechanics: stochastic detachment, settling, and gradual apoptosis."""

from __future__ import annotations

from collections import deque

import numpy as np

from ystam.grid.ecm import layer_update
from ystam.helpers import pos2idx
from ystam.tile.glue import Glue
from ystam.tile.tile import Tile, ON, LATENT, UNUSED
from ystam.update_rules.glue_update import glue_update


def eval_breaks(lut: dict[int, Tile], ecmtx: np.ndarray, rng: np.random.Generator) -> None:
    """Stochastically evaluate glue breakage for all tiles in the LUT."""
    for idx, u in list(lut.items()):
        if u.name in ("Source", "Goal") or u.color_flag in (3, -1):
            continue

        # Forward channel
        if isinstance(u.input_connections[0], Tile):
            strength = u.input_strengths[0]
            x, y = u.position
            memory = ecmtx[x - 1, y - 1]
            if rng.random() > glue_update(strength, memory):
                prev_tile = u.input_connections[0]
                complement_glue = u.input_glues[0].complement()
                for oi, og in enumerate(prev_tile.output_glues):
                    if og is not None and og == complement_glue:
                        prev_tile.output_connections[oi] = ON
                        break
                u.input_connections[0] = ON

        # Backward channel
        if len(u.input_connections) > 1 and isinstance(u.input_connections[1], Tile):
            strength = u.input_strengths[1]
            x, y = u.position
            memory = ecmtx[x - 1, y - 1]
            if rng.random() > glue_update(strength, memory):
                prev_tile = u.input_connections[1]
                complement_glue = u.input_glues[1].complement()
                for oi, og in enumerate(prev_tile.output_glues):
                    if og is not None and og == complement_glue:
                        prev_tile.output_connections[oi] = ON
                        break
                u.input_connections[1] = ON


def settle_glues(lut: dict[int, Tile]) -> None:
    """Attempt reattachment when one channel is connected and the other is detached.

    Skips severed tiles to prevent accidental reconnection.
    """
    for idx, u in list(lut.items()):
        if u.name in ("Source", "Goal"):
            continue
        if u.severed:
            continue
        if len(u.input_connections) < 2:
            continue

        if (
            isinstance(u.input_connections[0], Tile)
            and not isinstance(u.input_connections[1], Tile)
            and u.input_connections[1] == ON
        ):
            prev_tile = u.input_connections[0]
            fwd_complement = u.input_glues[0].complement()
            bwd_glue_name = Glue("B", fwd_complement.io, fwd_complement.compass, fwd_complement.side)
            for oi, og in enumerate(prev_tile.output_glues):
                if og is not None and og == bwd_glue_name:
                    prev_tile.output_connections[oi] = u
                    u.input_connections[1] = prev_tile
                    break

        elif (
            isinstance(u.input_connections[1], Tile)
            and not isinstance(u.input_connections[0], Tile)
            and u.input_connections[0] == ON
        ):
            prev_tile = u.input_connections[1]
            bwd_complement = u.input_glues[1].complement()
            fwd_glue_name = Glue("F", bwd_complement.io, bwd_complement.compass, bwd_complement.side)
            for oi, og in enumerate(prev_tile.output_glues):
                if og is not None and og == fwd_glue_name:
                    prev_tile.output_connections[oi] = u
                    u.input_connections[0] = prev_tile
                    break


def disconnect_detach(pathway_tile: Tile, detached_tile: Tile) -> None:
    """Detach detached_tile from pathway_tile's output connections."""
    for i, oc in enumerate(pathway_tile.output_connections):
        if isinstance(oc, Tile) and oc is detached_tile:
            pathway_tile.output_connections[i] = ON
    for i, ic in enumerate(detached_tile.input_connections):
        if isinstance(ic, Tile) and ic is pathway_tile:
            detached_tile.input_connections[i] = UNUSED


# ---------------------------------------------------------------------------
# Gradual apoptosis (new system)
# ---------------------------------------------------------------------------


def mark_severed(lut: dict[int, Tile], n: int, energy_per_tile: float) -> None:
    """Find newly orphaned tiles and mark their entire downstream fragment as severed.

    Each tile in the fragment receives energy = fragment_size * energy_per_tile.
    Internal connections within the fragment are preserved for outside-in decay.
    """
    # Find orphan roots: tiles with no input Tile connections, not already severed
    orphan_roots: list[int] = []
    for idx, u in list(lut.items()):
        if u.name in ("Source", "Goal") or u.color_flag in (3, -1):
            continue
        if u.severed:
            continue
        has_input = any(isinstance(ic, Tile) for ic in u.input_connections)
        if not has_input:
            orphan_roots.append(idx)

    # For each orphan root, BFS to find the full fragment
    for root_idx in orphan_roots:
        root = lut.get(root_idx)
        if root is None or root.severed:
            continue

        # BFS to collect all tiles in the fragment
        fragment: list[int] = []
        queue: deque[int] = deque([root_idx])
        visited: set[int] = {root_idx}

        while queue:
            cur_idx = queue.popleft()
            tile = lut.get(cur_idx)
            if tile is None:
                continue
            fragment.append(cur_idx)

            for oc in tile.output_connections:
                if isinstance(oc, Tile) and oc.name != "Goal":
                    oc_idx = pos2idx(oc.position[0], oc.position[1], n)
                    if oc_idx not in visited:
                        visited.add(oc_idx)
                        queue.append(oc_idx)

        # Assign energy proportional to fragment size
        total_energy = len(fragment) * energy_per_tile
        for frag_idx in fragment:
            tile = lut.get(frag_idx)
            if tile is not None and not tile.severed:
                tile.severed = True
                tile.energy = total_energy
                tile.max_energy = total_energy


def decay_severed(
    lut: dict[int, Tile],
    ecmtx: np.ndarray,
    n: int,
    base_drain: float,
    interior_factor: float,
    ecm_damping: bool,
    ecm_strength: float,
    ecm_signal_radius: float,
    mtx_refresh_rate: float,
    update_mode: str,
) -> tuple[dict[int, Tile], np.ndarray]:
    """Drain energy from severed tiles. Tips drain faster. Remove depleted tiles.

    The outside-in behavior emerges naturally: tips die first, their parents
    become the new tips next timestep.
    """
    to_delete: list[int] = []

    for idx, tile in list(lut.items()):
        if not tile.severed:
            continue
        if tile.name in ("Source", "Goal") or tile.color_flag in (3, -1):
            continue

        # Classify as tip or interior
        is_tip = not any(isinstance(oc, Tile) for oc in tile.output_connections)

        # Compute drain
        drain = base_drain if is_tip else base_drain * interior_factor

        # ECM damping: positive ECM slows death
        if ecm_damping:
            x, y = tile.position
            ecm_val = ecmtx[x - 1, y - 1]
            if ecm_val > 0:
                drain *= 1.0 / (1.0 + ecm_val)

        tile.energy -= drain

        if tile.energy <= 0:
            to_delete.append(idx)

    # Delete depleted tiles
    for idx in to_delete:
        tile = lut.get(idx)
        if tile is None:
            continue

        # Deposit negative ECM
        if ecm_strength < 0:
            ecmtx = layer_update(
                ecmtx,
                (ecm_strength, ecm_signal_radius, mtx_refresh_rate),
                [tile],
                n,
                update_mode,
            )

        # Disconnect from parent within fragment
        for i, ic in enumerate(tile.input_connections):
            if isinstance(ic, Tile):
                for j, oc in enumerate(ic.output_connections):
                    if isinstance(oc, Tile) and oc is tile:
                        ic.output_connections[j] = ON
                tile.input_connections[i] = UNUSED

        # Disconnect from children (they become new orphan roots within the fragment)
        for i, oc in enumerate(tile.output_connections):
            if isinstance(oc, Tile):
                for j, ic in enumerate(oc.input_connections):
                    if isinstance(ic, Tile) and ic is tile:
                        oc.input_connections[j] = UNUSED
                tile.output_connections[i] = ON

        del lut[idx]

    return lut, ecmtx


# ---------------------------------------------------------------------------
# Instant cascade deletion (legacy fallback)
# ---------------------------------------------------------------------------


def propagate_deletions_instant(
    lut: dict[int, Tile],
    ecmtx: np.ndarray,
    n: int,
    ecm_strength: float,
    ecm_signal_radius: float,
    mtx_refresh_rate: float,
    update_mode: str,
) -> tuple[dict[int, Tile], np.ndarray]:
    """Original instant cascade deletion of orphaned branches."""
    stack: deque[int] = deque()
    for idx, u in list(lut.items()):
        if u.name in ("Source", "Goal") or u.color_flag in (3, -1):
            continue
        has_input = any(isinstance(ic, Tile) for ic in u.input_connections)
        if not has_input:
            stack.append(idx)

    while stack:
        pop_idx = stack.popleft()
        tile = lut.get(pop_idx)
        if tile is None:
            continue
        if ecm_strength < 0:
            ecmtx = layer_update(
                ecmtx,
                (ecm_strength, ecm_signal_radius, mtx_refresh_rate),
                [tile],
                n,
                update_mode,
            )
        if tile.name == "Goal":
            continue
        for oc in tile.output_connections:
            if isinstance(oc, Tile):
                disconnect_detach(tile, oc)
                next_idx = pos2idx(oc.position[0], oc.position[1], n)
                stack.append(next_idx)
        del lut[pop_idx]

    return lut, ecmtx


def settle_colors(lut: dict[int, Tile]) -> None:
    """Revert feedback coloring when no longer connected to feedback branch."""
    for idx, u in list(lut.items()):
        if u.name in ("Source", "Goal"):
            continue
        if u.color_flag == 4:
            connected = any(
                isinstance(v, Tile) and v.color_flag >= 3
                for v in u.output_connections
            )
            if not connected:
                u.color_flag = 1
