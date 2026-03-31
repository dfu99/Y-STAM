"""Fungal-domain configuration that maps biological parameters to simulation internals."""

from __future__ import annotations

from dataclasses import dataclass, field

from ystam.sim import SimConfig


@dataclass
class FungalConfig:
    """User-friendly fungal simulation parameters.

    Maps biological concepts to the underlying Y-STAM simulation engine.
    """

    # Environment
    grid_size: int = 100
    colony_position: tuple[int, int] | None = None  # Default: center
    food_positions: list[tuple[int, int]] | None = None  # Default: random
    num_food_sources: int = 5
    obstacles: list[tuple[float, float, float, float]] = field(default_factory=list)

    # Growth behavior
    branching_probability: float = 0.25  # Lower = more branching
    turning_probability: float = 0.05    # Lower = more turning
    recycling_rate: float = 0.95         # Maps to G_se (higher = more pruning)
    colony_branches: int = 4             # Initial branches from colony (1-4)

    # Chemical memory
    chemical_memory: bool = True
    memory_strength: float = 5.0
    memory_radius: float = 2.0
    memory_decay: float = 0.02
    memory_decay_on_hypha: float = 0.1   # Slower decay where hyphae exist
    memory_refresh: float = 0.5

    # Chemotropism
    chemotropism: bool = True
    chemotropism_strength: float = 3.0
    chemotropism_radius: float = 15.0

    # Feedback (nutrient transport signaling)
    nutrient_feedback: bool = True

    # Gradual dieback (severed branches die tips-first instead of instantly)
    gradual_dieback: bool = True
    dieback_rate: float = 1.0            # How fast severed tips lose energy
    dieback_nutrient_delay: bool = True   # Positive ECM slows die-off

    # Resource limits
    growth_energy: float = 0.0  # 0 = unlimited. >0 = Michaelis-Menten Kd

    # Simulation
    time_limit: int = 1000
    max_trials: int = 1
    seed: int | None = None

    def to_sim_config(self) -> SimConfig:
        """Convert fungal parameters to internal SimConfig."""
        n = self.grid_size

        # Colony position
        if self.colony_position is not None:
            source_pos = [self.colony_position]
        else:
            center = n // 2
            if (center + center) % 2 != 1:
                center += 1
            source_pos = [(center, center)]

        # ECM parameters
        ecm = (0.0, 0.0, 0.0, 1.0, 0.0)
        if self.chemical_memory:
            ecm = (
                self.memory_strength,
                self.memory_radius,
                self.memory_decay,
                self.memory_decay_on_hypha,
                self.memory_refresh,
            )

        # Chemotropism
        cmode = (0.0, 0.0, 0.0, 0.0)
        if self.chemotropism:
            cmode = (0.0, 0.0, self.chemotropism_strength, self.chemotropism_radius)

        # Tile concentration (growth energy)
        tile_conc = (0.0, 0.0)
        if self.growth_energy > 0:
            tile_conc = (self.growth_energy, 100.0)

        return SimConfig(
            n=n,
            branching_factor=self.branching_probability,
            turning_factor=self.turning_probability,
            g_se=self.recycling_rate,
            source_branches=self.colony_branches,
            feedback=self.nutrient_feedback,
            continuous=True,
            ecm=ecm,
            tile_conc=tile_conc,
            cmode=cmode,
            dead_zone=self.obstacles,
            num_sources=1,
            num_goals=self.num_food_sources,
            source_positions=source_pos,
            goal_positions=self.food_positions,
            time_limit=self.time_limit,
            max_trials=self.max_trials,
            seed=self.seed,
            apoptosis_enabled=self.gradual_dieback,
            apoptosis_base_drain=self.dieback_rate,
            apoptosis_ecm_damping=self.dieback_nutrient_delay,
        )
