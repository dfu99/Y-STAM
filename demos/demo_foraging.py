#!/usr/bin/env python3
"""Fungal foraging: single colony finds scattered food sources.

Watch the mycelium explore, find food, prune dead-end branches,
and reinforce efficient nutrient transport paths.
"""

from ystam.fungal.colony import FungalColony
from ystam.fungal.config import FungalConfig


def main() -> None:
    config = FungalConfig(
        grid_size=100,
        colony_position=(50, 50),
        num_food_sources=6,
        branching_probability=0.3,
        turning_probability=0.1,
        recycling_rate=0.97,
        colony_branches=4,
        chemical_memory=True,
        memory_strength=5.0,
        memory_radius=2.0,
        memory_decay=0.02,
        memory_decay_on_hypha=0.1,
        memory_refresh=0.5,
        chemotropism=True,
        chemotropism_strength=3.0,
        chemotropism_radius=15.0,
        nutrient_feedback=True,
        time_limit=500,
        seed=42,
    )

    colony = FungalColony(config)

    # Save as mp4 (or use output_path=None for live display)
    result = colony.run(
        output_path="fungal_foraging.mp4",
        show_ecm=True,
        interval_ms=50,
        skip_frames=2,
    )

    print(f"Found {result.food_found_count}/{result.total_food} food sources")
    print(f"Food found at timesteps: {result.food_found}")
    print(f"Final network size: {result.final_network_size}")
    print(f"Exploration coverage: {result.exploration_coverage:.1%}")


if __name__ == "__main__":
    main()
