"""Main simulation loop: orchestrates growth, disassembly, feedback, and ECM updates."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Generator

import numpy as np

from ystam.disassemble.disassemble import (
    decay_severed,
    eval_breaks,
    mark_severed,
    propagate_deletions_instant,
    settle_colors,
    settle_glues,
)
from ystam.feedback.feedback import trigger_feedback
from ystam.grid.ecm import layer_update, refresh_ecmtx, refresh_heatmap
from ystam.grid.grid import Grid
from ystam.grow.grow import add_tiles_to_free_edges, refresh_free_edges
from ystam.termination.termination import is_done
from ystam.tile.tileset import TileSet


@dataclass
class SimConfig:
    """All simulation parameters."""

    n: int = 100
    branching_factor: float = 0.25
    turning_factor: float = 0.05
    g_se: float = 0.95
    source_branches: int = 4
    feedback: bool = True
    continuous: bool = True
    ecm: tuple[float, ...] = (5.0, 2.0, 0.02, 0.1, 0.5)
    tile_conc: tuple[float, float] = (0.0, 0.0)
    cmode: tuple[float, ...] = (0.0, 0.0, 0.0, 0.0)
    dead_zone: list[tuple[float, float, float, float]] = field(default_factory=list)
    dead_zone_ecm: tuple[float, float, float] = (-1.0, 2.0, 0.5)
    num_sources: int = 1
    num_goals: int = 1
    source_positions: list[tuple[int, int]] | None = None
    goal_positions: list[tuple[int, int]] | None = None
    time_limit: int = 1000
    max_trials: int = 1
    buffering: float = 0.0
    seed: int | None = None
    # Apoptosis (gradual die-off of severed branches)
    apoptosis_enabled: bool = True
    apoptosis_base_drain: float = 1.0
    apoptosis_interior_factor: float = 0.3
    apoptosis_energy_per_tile: float = 1.0
    apoptosis_ecm_damping: bool = True
    apoptosis_growth_cost: float = 2.0


@dataclass
class StepResult:
    """Result of a single simulation timestep."""

    timestep: int
    grid: Grid
    assembly_size: int
    hitflag: bool
    hit_time: int


@dataclass
class TrialResult:
    """Result of a single trial."""

    trial: int
    assembly_size: int
    hitflag: bool
    hit_time: int
    timesteps: int


def run_simulation(config: SimConfig) -> Generator[StepResult, None, list[TrialResult]]:
    """Run the Y-STAM simulation as a generator yielding per-timestep state.

    Yields StepResult for each timestep. Returns list of TrialResults when done.
    """
    rng = np.random.default_rng(config.seed)

    # ECM parameters
    ecm_strength = config.ecm[0] if len(config.ecm) > 0 else 0.0
    ecm_radius = config.ecm[1] if len(config.ecm) > 1 else 0.0
    ecm_decay = config.ecm[2] if len(config.ecm) > 2 else 0.0
    ecm_decay_on = config.ecm[3] if len(config.ecm) > 3 else 1.0
    ecm_refresh = config.ecm[4] if len(config.ecm) > 4 else 0.0

    # Tile concentration
    use_tile_conc = config.tile_conc[0] > 0
    kd = config.tile_conc[0] if use_tile_conc else 1.0
    conc_max = config.tile_conc[1] if use_tile_conc else 100.0

    trial_results: list[TrialResult] = []

    for trial in range(config.max_trials):
        # Initialize TileSet
        tile_set = TileSet(
            mode="radial",
            use_tile_conc=use_tile_conc,
            kd=kd,
            conc_max=conc_max,
            rng=rng,
        )
        tile_set.apply_branching_factor(config.branching_factor)
        tile_set.apply_turning_factor(config.turning_factor)

        # Initialize Grid
        grid = Grid(
            n=config.n,
            growth_mode="radial",
            source_branches=config.source_branches,
            g_se=config.g_se,
            tile_set=tile_set,
            rng=rng,
        )

        # Set up sources and goals
        grid.init_sources(
            num=config.num_sources,
            positions=config.source_positions,
        )
        grid.init_goals(
            num=config.num_goals,
            positions=config.goal_positions,
        )

        # Optional features
        if config.dead_zone:
            grid.set_dead_zone(config.dead_zone)
        if any(v > 0 for v in config.cmode):
            grid.set_trunk(config.cmode)

        # Reset grid (places tiles and features)
        grid.reset()

        # Simulation state
        hitflag = False
        hit_time = 0
        timesteps = 0
        last_lut = grid.get_snapshot()

        # Main loop
        while True:
            # --- Disassembly phase ---
            eval_breaks(grid.lut, grid.ecmtx, rng)
            settle_glues(grid.lut)
            if config.apoptosis_enabled:
                mark_severed(grid.lut, grid.n, config.apoptosis_energy_per_tile)
                grid.lut, grid.ecmtx = decay_severed(
                    grid.lut,
                    grid.ecmtx,
                    grid.n,
                    base_drain=config.apoptosis_base_drain,
                    interior_factor=config.apoptosis_interior_factor,
                    ecm_damping=config.apoptosis_ecm_damping,
                    ecm_strength=-abs(ecm_strength) if ecm_strength > 0 else 0.0,
                    ecm_signal_radius=ecm_radius,
                    mtx_refresh_rate=ecm_refresh,
                    update_mode="FirstOrderSum",
                )
            else:
                grid.lut, grid.ecmtx = propagate_deletions_instant(
                    grid.lut,
                    grid.ecmtx,
                    grid.n,
                    ecm_strength=-abs(ecm_strength) if ecm_strength > 0 else 0.0,
                    ecm_signal_radius=ecm_radius,
                    mtx_refresh_rate=ecm_refresh,
                    update_mode="FirstOrderSum",
                )
            settle_colors(grid.lut)

            # --- Growth phase ---
            free_edges = refresh_free_edges(grid.lut)
            grid.lut, grid.ecmtx = add_tiles_to_free_edges(
                grid.lut,
                grid.ecmtx,
                grid.n,
                free_edges,
                tile_set,
                config.g_se,
                use_tile_conc,
                config.dead_zone_ecm,
                rng=rng,
                apoptosis_growth_cost=config.apoptosis_growth_cost,
            )
            timesteps += 1

            # --- Update auxiliary layers ---
            grid.ecmtx = refresh_ecmtx(
                grid.lut,
                last_lut,
                grid.ecmtx,
                ecm_strength=ecm_strength,
                ecm_signal_radius=ecm_radius,
                mtx_refresh_rate=ecm_refresh,
                mtx_decay_rate=ecm_decay,
                mtx_decay_rate_on=ecm_decay_on,
                n=grid.n,
            )

            # Refresh chemotropic gradients each step
            if grid.has_trunk:
                grid.add_trunk()

            grid.heatmap = refresh_heatmap(grid.lut, grid.heatmap, grid.n)

            # Buffering
            if config.buffering > 0:
                tile_set.buffer(config.buffering)

            # Save snapshot for next step's ECM diff
            last_lut = grid.get_snapshot()

            # --- Termination check ---
            should_break, should_feedback, hitflag, hit_time = is_done(
                grid.lut,
                grid.n,
                grid.tf,
                timesteps,
                config.time_limit,
                config.continuous,
                config.feedback,
                hitflag,
                hit_time,
            )

            # Trigger feedback if appropriate
            if should_feedback and config.feedback:
                trigger_feedback(grid.lut, grid.n, grid.tf)

            # Count assembly
            assembly_size = sum(
                1 for t in grid.lut.values() if t.name not in ("Source", "Goal", "Dead")
            )

            yield StepResult(
                timestep=timesteps,
                grid=grid,
                assembly_size=assembly_size,
                hitflag=hitflag,
                hit_time=hit_time,
            )

            if should_break:
                break

        trial_results.append(
            TrialResult(
                trial=trial,
                assembly_size=assembly_size,
                hitflag=hitflag,
                hit_time=hit_time,
                timesteps=timesteps,
            )
        )

    return trial_results
