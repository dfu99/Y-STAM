#!/usr/bin/env python3
"""Physarum-style shortest path: two food sources connected by optimized network.

Inspired by the Physarum polycephalum Tokyo railway experiment.
The fungus explores broadly, then prunes to an efficient transport network.
"""

from ystam.fungal.colony import FungalColony
from ystam.fungal.config import FungalConfig


def main() -> None:
    config = FungalConfig(
        grid_size=120,
        colony_position=(60, 60),
        food_positions=[(30, 30), (90, 90)],
        num_food_sources=2,
        # Barrier between the two food sources
        obstacles=[
            (0.45, 0.20, 0.02, 0.25),  # Upper barrier segment
            (0.45, 0.55, 0.02, 0.25),  # Lower barrier segment
            # Gap in the middle for the shortest path
        ],
        branching_probability=0.2,
        turning_probability=0.08,
        recycling_rate=0.96,
        colony_branches=4,
        chemical_memory=True,
        memory_strength=6.0,
        memory_radius=3.0,
        memory_decay=0.015,
        memory_decay_on_hypha=0.08,
        memory_refresh=0.6,
        chemotropism=True,
        chemotropism_strength=4.0,
        chemotropism_radius=25.0,
        nutrient_feedback=True,
        time_limit=1000,
        seed=7,
    )

    colony = FungalColony(config)
    result = colony.run(
        output_path="physarum_paths.mp4",
        show_ecm=True,
        interval_ms=40,
        skip_frames=3,
    )

    print(f"Found {result.food_found_count}/{result.total_food} food sources")
    print(f"Food found at timesteps: {result.food_found}")
    print(f"Final network size: {result.final_network_size}")
    print(f"Exploration coverage: {result.exploration_coverage:.1%}")


if __name__ == "__main__":
    main()
