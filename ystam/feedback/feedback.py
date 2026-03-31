"""Feedback: backward channel signal propagation from goal to source."""

from __future__ import annotations

from ystam.helpers import pos2idx
from ystam.tile.glue import Glue, can_bind
from ystam.tile.tile import Tile, is_adjacent


def check_inputs(
    goal_tile: Tile, lut: dict[int, Tile], n: int
) -> list[tuple[bool, int, Tile | None]]:
    """Check all 4 diagonal neighbors of a goal tile for adjacent tiles with valid output glues.

    Returns list of (has_tile, lut_index, tile_or_None) for NW, NE, SE, SW.
    """
    gx, gy = goal_tile.position
    # Diagonal neighbors: (dx, dy) and expected FO glues at that position
    neighbors = [
        (1, -1, ("FOED", "FOSR")),   # NW: x+1, y-1
        (1, 1, ("FOWD", "FOSL")),    # NE: x+1, y+1
        (-1, 1, ("FOWU", "FONL")),   # SE: x-1, y+1
        (-1, -1, ("FOEU", "FONR")),  # SW: x-1, y-1
    ]

    results = []
    for dx, dy, valid_glues in neighbors:
        nx, ny = gx + dx, gy + dy
        if not (1 <= nx <= n and 1 <= ny <= n):
            results.append((False, -1, None))
            continue
        idx = pos2idx(nx, ny, n)
        tile = lut.get(idx)
        if tile is None:
            results.append((False, idx, None))
            continue
        # Check if tile has a matching output glue
        has_valid = False
        for og in tile.output_glues:
            if og is not None and og.code in valid_glues:
                has_valid = True
                break
        results.append((has_valid, idx, tile if has_valid else None))

    return results


def probe_glues(tile_to_source: Tile, tile_to_goal: Tile) -> tuple[Glue, Glue]:
    """Find which FO glue on tile_to_source can connect to tile_to_goal based on position."""
    x1, y1 = tile_to_source.position
    x2, y2 = tile_to_goal.position
    dx, dy = x2 - x1, y2 - y1

    # Map relative position to expected FO glues
    candidates_map = {
        (1, 1): ("FONR", "FOEU"),
        (1, -1): ("FONL", "FOWU"),
        (-1, 1): ("FOSR", "FOED"),
        (-1, -1): ("FOSL", "FOWD"),
    }

    candidates = candidates_map.get((dx, dy))
    if candidates is None:
        raise ValueError(f"Tiles not diagonally adjacent: [{x1},{y1}] -> [{x2},{y2}]")

    glue1 = None
    for code in candidates:
        for og in tile_to_source.output_glues:
            if og is not None and og.code == code:
                glue1 = og
                break
        if glue1 is not None:
            break

    if glue1 is None:
        raise ValueError(f"No matching FO glue found for direction ({dx}, {dy})")

    glue2 = glue1.complement()
    # Verify glue2 is on tile_to_goal
    found = False
    for ig in tile_to_goal.input_glues:
        if ig is not None and ig == glue2:
            found = True
            break
    if not found:
        raise ValueError(f"Goal tile cannot reciprocate connection with {glue2}")

    return glue1, glue2


def trigger_feedback(lut: dict[int, Tile], n: int, goals: list[Tile]) -> None:
    """Check if any goal tiles have adjacent tiles and trigger backward propagation."""
    for goal in goals:
        if goal.fb_state != 1.0:
            continue
        results = check_inputs(goal, lut, n)
        for has_tile, idx, tile in results:
            if has_tile and tile is not None and tile.color_flag != 4:
                _propagate(tile, goal)
                break  # Only trigger once per goal


def _propagate(tile_to_source: Tile, tile_to_goal: Tile) -> None:
    """Connect backward channels from goal back to source along the pathway."""
    if tile_to_goal.name != "Goal":
        raise ValueError("Non-Goal tile cannot initiate backward signal propagation")
    if not is_adjacent(tile_to_source, tile_to_goal):
        raise ValueError("Tile must be adjacent to Goal to trigger feedback")

    # Connect forward channel to goal
    glue1, glue2 = probe_glues(tile_to_source, tile_to_goal)
    idx1 = tile_to_source.get_output_index(glue1)
    idx2 = tile_to_goal.get_input_index(glue2)
    tile_to_source.output_connections[idx1] = tile_to_goal
    tile_to_goal.input_connections[idx2] = tile_to_source

    # Mark as feedback-active
    tile_to_source.color_flag = 4

    # Propagate backward toward source
    current = tile_to_source
    while True:
        if not isinstance(current.input_connections[0], Tile):
            raise ValueError(
                f"Traceback hit a break at tile position {current.position}"
            )

        prev = current.input_connections[0]

        # Stitch backward channel
        if len(current.input_glues) > 1 and current.input_glues[1] is not None:
            bwd_glue = current.input_glues[1]
            complement = bwd_glue.complement()
            output_idx = prev.get_output_index(complement)
            current.input_connections[1] = prev
            prev.output_connections[output_idx] = current

        current = prev

        if current.name == "Source":
            break
        else:
            current.color_flag = 4
