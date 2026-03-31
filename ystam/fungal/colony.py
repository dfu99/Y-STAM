"""FungalColony: high-level interface for running fungal foraging simulations."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from ystam.fungal.config import FungalConfig
from ystam.sim import SimConfig, StepResult, run_simulation
from ystam.viz.animation import animate_simulation


@dataclass
class ForagingResult:
    """Results from a fungal foraging simulation."""

    food_found: list[int]           # Timestep each food was first reached
    total_food: int                 # Total food sources
    network_size_history: list[int] # Assembly size per timestep
    final_network_size: int
    total_timesteps: int
    exploration_coverage: float     # Fraction of grid explored at some point

    @property
    def food_found_count(self) -> int:
        return len(self.food_found)

    @property
    def efficiency(self) -> float:
        """Fraction of food sources found."""
        return self.food_found_count / max(self.total_food, 1)


class FungalColony:
    """High-level interface for fungal intelligence simulation."""

    def __init__(self, config: FungalConfig | None = None) -> None:
        self.config = config or FungalConfig()
        self.sim_config = self.config.to_sim_config()

    def run(
        self,
        output_path: str | Path | None = None,
        show_ecm: bool = True,
        show_heatmap: bool = False,
        interval_ms: int = 50,
        skip_frames: int = 0,
    ) -> ForagingResult:
        """Run the simulation with animation.

        Args:
            output_path: Save animation to file (.mp4 or .gif). None = show live.
            show_ecm: Show chemical memory panel.
            show_heatmap: Show exploration heatmap panel.
            interval_ms: Animation speed (ms between frames).
            skip_frames: Render every N+1 frames.

        Returns:
            ForagingResult with metrics.
        """
        renderer = animate_simulation(
            self.sim_config,
            output_path=output_path,
            show_ecm=show_ecm,
            show_heatmap=show_heatmap,
            interval_ms=interval_ms,
            skip_frames=skip_frames,
        )
        # Run again to collect metrics (animation consumes the generator)
        return self._collect_metrics()

    def run_headless(self) -> ForagingResult:
        """Run without visualization, return metrics only."""
        return self._collect_metrics()

    def _collect_metrics(self) -> ForagingResult:
        """Run simulation and collect foraging metrics."""
        gen = run_simulation(self.sim_config)
        size_history = []
        food_found: list[int] = []
        found_set: set[int] = set()
        explored: set[tuple[int, int]] = set()

        try:
            while True:
                step = next(gen)
                size_history.append(step.assembly_size)

                # Track explored positions
                for tile in step.grid.lut.values():
                    if tile is not None:
                        explored.add(tile.position)

                # Track food discovery
                for gi, goal in enumerate(step.grid.tf):
                    if gi not in found_set:
                        # Check if any adjacent tile exists
                        from ystam.feedback.feedback import check_inputs

                        results = check_inputs(goal, step.grid.lut, step.grid.n)
                        if any(has for has, _, _ in results):
                            food_found.append(step.timestep)
                            found_set.add(gi)

        except StopIteration:
            pass

        total_cells = self.sim_config.n * self.sim_config.n
        coverage = len(explored) / total_cells

        return ForagingResult(
            food_found=food_found,
            total_food=self.sim_config.num_goals,
            network_size_history=size_history,
            final_network_size=size_history[-1] if size_history else 0,
            total_timesteps=len(size_history),
            exploration_coverage=coverage,
        )
