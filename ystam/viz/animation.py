"""Animation utilities: create mp4/gif from simulation generator."""

from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter

from ystam.sim import SimConfig, run_simulation
from ystam.tile.tile import Tile


@dataclass
class FrameData:
    """Snapshot of one simulation timestep for rendering."""

    timestep: int
    # Tree branches: list of (path_coords, weight, is_feedback)
    # weight = number of downstream tips (thick trunk -> thin twigs)
    branches: list = field(default_factory=list)
    tip_positions: list = field(default_factory=list)
    source_positions: list = field(default_factory=list)
    goal_positions: list = field(default_factory=list)
    obstacle_positions: list = field(default_factory=list)
    ecmtx: np.ndarray = field(default_factory=lambda: np.zeros((1, 1)))
    assembly_size: int = 0
    max_weight: int = 1


def _build_tree_branches(lut: dict) -> tuple[list, list, int]:
    """Build weighted tree branches from the tile connection graph.

    Each edge gets a weight = number of tips reachable downstream.
    Returns: (branches, tip_positions, max_weight)
      branches: list of ([(x,y),...], weight, is_feedback)
    """
    # Build adjacency: parent -> [children]
    children_map: dict[int, list] = defaultdict(list)
    tile_by_id: dict[int, object] = {}
    source_ids = []
    tips = []

    for idx, tile in lut.items():
        if tile is None or tile.color_flag == -1:
            continue
        tid = id(tile)
        tile_by_id[tid] = tile
        if tile.name == "Source":
            source_ids.append(tid)
            continue
        if tile.name == "Goal":
            continue

        # Find parent (input connection)
        parent = None
        for ic in tile.input_connections:
            if isinstance(ic, Tile):
                parent = ic
                break
        if parent is not None:
            children_map[id(parent)].append(tid)

        # Check if tip (no children that are tiles)
        has_child = any(isinstance(oc, Tile) and oc.name not in ("Goal",)
                        for oc in tile.output_connections)
        if not has_child:
            tips.append(tile)

    if not tile_by_id:
        return [], [], 1

    # Count downstream tips for each node via iterative post-order DFS
    downstream_count: dict[int, int] = defaultdict(int)

    for sid in source_ids:
        # Iterative post-order traversal
        stack = [(sid, False)]
        while stack:
            tid, processed = stack.pop()
            kids = children_map.get(tid, [])
            if not kids:
                downstream_count[tid] = 1
                continue
            if processed:
                downstream_count[tid] = sum(downstream_count.get(c, 0) for c in kids)
            else:
                stack.append((tid, True))
                for c in kids:
                    stack.append((c, False))

    # Walk tree from sources, building branches
    # A "branch" is a sequence of nodes until a fork or tip
    branches = []
    max_w = 1

    def walk_branch(start_tid: int, initial_path: list):
        nonlocal max_w
        stack = [(start_tid, list(initial_path))]
        while stack:
            cur_tid, path = stack.pop()
            tile = tile_by_id.get(cur_tid)
            if tile is None:
                if len(path) >= 2:
                    w = downstream_count.get(cur_tid, 1)
                    branches.append((path, w, False, False, 1.0))
                    max_w = max(max_w, w)
                continue

            kids = children_map.get(cur_tid, [])
            is_fb = tile.color_flag == 4
            is_sev = getattr(tile, "severed", False)
            e_ratio = (tile.energy / tile.max_energy) if (is_sev and tile.max_energy > 0) else 1.0

            if len(kids) == 0:
                # Tip: end this branch
                if len(path) >= 2:
                    w = downstream_count.get(cur_tid, 1)
                    branches.append((path, w, is_fb, is_sev, e_ratio))
                    max_w = max(max_w, w)
            elif len(kids) == 1:
                # Continue the branch
                child = tile_by_id.get(kids[0])
                if child is not None:
                    path.append(child.position)
                    stack.append((kids[0], path))
                else:
                    if len(path) >= 2:
                        w = downstream_count.get(cur_tid, 1)
                        branches.append((path, w, is_fb, is_sev, e_ratio))
                        max_w = max(max_w, w)
            else:
                # Fork: end current branch, start new ones for each child
                w = downstream_count.get(cur_tid, 1)
                if len(path) >= 2:
                    branches.append((path, w, is_fb, is_sev, e_ratio))
                    max_w = max(max_w, w)

                for kid_tid in kids:
                    child = tile_by_id.get(kid_tid)
                    if child is not None:
                        stack.append((kid_tid, [tile.position, child.position]))

    for sid in source_ids:
        source = tile_by_id[sid]
        for kid_tid in children_map.get(sid, []):
            child = tile_by_id.get(kid_tid)
            if child is not None:
                walk_branch(kid_tid, [source.position, child.position])

    # Walk severed fragment roots (not reachable from sources)
    visited_tids = set()
    for item in branches:
        for pos in item[0]:
            visited_tids.add(pos)  # approximate tracking by position

    for tid, tile in tile_by_id.items():
        if not getattr(tile, "severed", False):
            continue
        if tile.name in ("Source", "Goal"):
            continue
        # Check if this tile is a severed root (no Tile input connection)
        has_input = any(isinstance(ic, Tile) for ic in tile.input_connections)
        if not has_input and children_map.get(tid):
            for kid_tid in children_map[tid]:
                child = tile_by_id.get(kid_tid)
                if child is not None:
                    walk_branch(kid_tid, [tile.position, child.position])
            # Also add the root itself as a single-node branch if it's a tip
            if not children_map.get(tid):
                pass  # tips are already captured

    # Flatten any nested tuples in paths
    cleaned = []
    for item in branches:
        path, w, fb, sev, er = item
        flat = []
        for p in path:
            if isinstance(p, (list, tuple)) and len(p) == 2 and not isinstance(p[0], (list, tuple)):
                flat.append(tuple(p))
        if len(flat) >= 2:
            cleaned.append((flat, w, fb, sev, er))
    branches = cleaned

    tip_positions = [(t.position[1], t.position[0]) for t in tips]  # (y, x) for plotting

    return branches, tip_positions, max_w


def capture_frame(grid, timestep: int) -> FrameData:
    """Capture current grid state into an immutable frame snapshot."""
    frame = FrameData(timestep=timestep)
    frame.ecmtx = grid.ecmtx.copy()

    for idx, tile in grid.lut.items():
        if tile is None:
            continue
        x, y = tile.position
        if tile.color_flag == -1:
            frame.obstacle_positions.append((y, x))
        elif tile.name == "Source":
            frame.source_positions.append((y, x))
        elif tile.name == "Goal":
            frame.goal_positions.append((y, x))
        else:
            frame.assembly_size += 1

    branches, tip_positions, max_w = _build_tree_branches(grid.lut)
    frame.branches = branches
    frame.tip_positions = tip_positions
    frame.max_weight = max_w

    return frame


def animate_simulation(
    config: SimConfig,
    output_path: str | Path | None = None,
    show_ecm: bool = True,
    interval_ms: int = 50,
    figsize: tuple[float, float] = (10, 10),
    skip_frames: int = 0,
) -> None:
    """Run simulation and produce animated visualization."""
    from ystam.viz.renderer import SimRenderer

    frames: list[FrameData] = []
    gen = run_simulation(config)
    frame_counter = 0
    try:
        while True:
            step = next(gen)
            if skip_frames == 0 or frame_counter % (skip_frames + 1) == 0:
                frames.append(capture_frame(step.grid, step.timestep))
            frame_counter += 1
    except StopIteration:
        pass

    if not frames:
        print("No frames to animate.")
        return

    print(f"Captured {len(frames)} frames, rendering animation...")

    renderer = SimRenderer(n=config.n, show_ecm=show_ecm, figsize=figsize)

    def update(frame_idx: int):
        renderer.render_frame(frames[frame_idx])
        return []

    anim = FuncAnimation(
        renderer.fig, update, frames=len(frames),
        interval=interval_ms, repeat=False,
    )

    if output_path is not None:
        output_path = Path(output_path)
        if output_path.suffix == ".gif":
            writer = PillowWriter(fps=max(1, 1000 // interval_ms))
        else:
            try:
                from matplotlib.animation import FFMpegWriter
                writer = FFMpegWriter(fps=max(1, 1000 // interval_ms), bitrate=3000)
            except Exception:
                output_path = output_path.with_suffix(".gif")
                writer = PillowWriter(fps=max(1, 1000 // interval_ms))
        anim.save(str(output_path), writer=writer, dpi=200,
                  savefig_kwargs={"facecolor": "#0a0a0a"})
        print(f"Animation saved to {output_path}")
    else:
        plt.show()

    renderer.close()
