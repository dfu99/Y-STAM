"""Integration test: run a small simulation and verify basic behavior."""

from ystam.sim import SimConfig, run_simulation
from ystam.tile.tileset import TileSet


def test_tileset_radial_generation():
    ts = TileSet(mode="radial", conc_max=100.0)
    # Should have many tile types
    assert len(ts.tile_types) > 50
    assert len(ts.concs) == len(ts.tile_types)


def test_tileset_branching_factor_zero():
    ts = TileSet(mode="radial", conc_max=100.0)
    ts.apply_branching_factor(0.0)
    # All branching tiles should have 0 concentration
    for defn, conc in zip(ts.tile_types, ts.concs):
        if defn[3] is not None and defn[5] is not None:
            assert conc == 0.0


def test_small_simulation_runs():
    """Run a tiny simulation and verify it produces tiles."""
    config = SimConfig(
        n=20,
        branching_factor=0.3,
        turning_factor=0.1,
        g_se=0.95,
        source_branches=4,
        feedback=False,
        continuous=False,
        ecm=(0.0, 0.0, 0.0, 1.0, 0.0),
        num_sources=1,
        num_goals=0,
        source_positions=[(10, 10)],
        time_limit=20,
        seed=42,
    )

    steps = list(run_simulation(config))
    assert len(steps) > 0
    # Should have grown some tiles
    assert steps[-1].assembly_size > 0


def test_simulation_with_ecm():
    """Run simulation with ECM enabled."""
    config = SimConfig(
        n=20,
        branching_factor=0.3,
        g_se=0.97,
        source_branches=4,
        feedback=False,
        continuous=False,
        ecm=(3.0, 2.0, 0.02, 0.1, 0.5),
        num_sources=1,
        num_goals=0,
        source_positions=[(10, 10)],
        time_limit=15,
        seed=42,
    )

    steps = list(run_simulation(config))
    assert len(steps) > 0


def test_glue_update_boundaries():
    """Test the glue update rate function at boundary conditions."""
    from ystam.update_rules.glue_update import glue_update

    # memory=0 should return the strength itself
    assert abs(glue_update(0.5, 0.0) - 0.5) < 1e-10

    # Large positive memory should approach 1.0
    assert glue_update(0.5, 100.0) > 0.9

    # Large negative memory should approach 0.0
    assert glue_update(0.5, -100.0) < 0.1
