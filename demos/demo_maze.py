#!/usr/bin/env python3
"""Fungal maze navigation: colony navigates around obstacles to find food."""

from ystam.fungal.colony import FungalColony
from ystam.fungal.config import FungalConfig


def main() -> None:
    config = FungalConfig(
        grid_size=100,
        colony_position=(50, 20),
        food_positions=[(50, 80)],
        num_food_sources=1,
        # U-shaped obstacle
        obstacles=[
            (0.35, 0.25, 0.02, 0.50),  # Left wall
            (0.35, 0.25, 0.30, 0.02),  # Bottom wall
            (0.63, 0.25, 0.02, 0.50),  # Right wall
        ],
        branching_probability=0.4,
        turning_probability=0.2,
        recycling_rate=0.98,
        colony_branches=4,
        chemical_memory=True,
        memory_strength=5.0,
        memory_radius=3.0,
        chemotropism=True,
        chemotropism_strength=4.0,
        chemotropism_radius=20.0,
        nutrient_feedback=True,
        time_limit=800,
        seed=123,
    )

    colony = FungalColony(config)
    result = colony.run(
        output_path="fungal_maze.mp4",
        show_ecm=True,
        interval_ms=40,
        skip_frames=2,
    )

    print(f"Found food: {result.food_found_count > 0}")
    if result.food_found:
        print(f"Time to find food: {result.food_found[0]} timesteps")
    print(f"Final network size: {result.final_network_size}")


if __name__ == "__main__":
    main()
