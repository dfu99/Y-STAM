"""Tests for gradual apoptosis of severed branches."""

import numpy as np

from ystam.disassemble.disassemble import (
    decay_severed,
    mark_severed,
    propagate_deletions_instant,
)
from ystam.grow.grow import bind_glues
from ystam.helpers import pos2idx
from ystam.tile.glue import Glue
from ystam.tile.tile import Tile, ON, UNUSED


def _make_chain(n_grid: int = 20) -> tuple[dict, Tile, Tile, Tile, Tile]:
    """Build source -> t1 -> t2 -> t3 chain for testing."""
    source = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    source.set_type("radial-source", source_branches=1)
    source.position = (10, 10)

    t1 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t1.set_type("tile")
    t1.position = (9, 9)

    t2 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t2.set_type("tile")
    t2.position = (8, 8)

    t3 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t3.set_type("tile")
    t3.position = (7, 7)

    # Manual connections: source -> t1 -> t2 -> t3
    g_out = Glue("F", "O", "W", "D")
    g_in = Glue("F", "I", "N", "L")  # complement is FOWD, but we match manually

    # source -> t1
    source.output_connections[0] = t1
    t1.input_connections[0] = source

    # t1 -> t2
    t1.output_connections[0] = t2
    t2.input_connections[0] = t1

    # t2 -> t3
    t2.output_connections[0] = t3
    t3.input_connections[0] = t2

    n = n_grid
    lut = {
        pos2idx(10, 10, n): source,
        pos2idx(9, 9, n): t1,
        pos2idx(8, 8, n): t2,
        pos2idx(7, 7, n): t3,
    }
    return lut, source, t1, t2, t3


def test_mark_severed_basic():
    """Severing t1 from source marks t1, t2, t3 as severed with correct energy."""
    lut, source, t1, t2, t3 = _make_chain()
    n = 20

    # Disconnect t1 from source
    source.output_connections[0] = ON
    t1.input_connections[0] = UNUSED

    mark_severed(lut, n, energy_per_tile=2.0)

    assert t1.severed is True
    assert t2.severed is True
    assert t3.severed is True
    # Fragment size = 3, energy_per_tile = 2.0 -> energy = 6.0
    assert t1.energy == 6.0
    assert t2.energy == 6.0
    assert t3.energy == 6.0
    assert t1.max_energy == 6.0
    # Source should NOT be severed
    assert source.severed is False


def test_decay_tips_first():
    """Repeated decay should kill t3 (tip) first, then t2, then t1."""
    lut, source, t1, t2, t3 = _make_chain()
    n = 20
    ecmtx = np.zeros((n, n))

    # Sever the fragment
    source.output_connections[0] = ON
    t1.input_connections[0] = UNUSED
    mark_severed(lut, n, energy_per_tile=1.0)

    # Fragment energy = 3.0. Tip drain = 1.0, interior drain = 0.3
    # t3 is the tip (no output Tile connections)
    t3_idx = pos2idx(7, 7, n)
    t2_idx = pos2idx(8, 8, n)
    t1_idx = pos2idx(9, 9, n)

    # Decay several times until t3 dies
    steps = 0
    while t3_idx in lut and steps < 20:
        lut, ecmtx = decay_severed(
            lut, ecmtx, n,
            base_drain=1.0, interior_factor=0.3, ecm_damping=False,
            ecm_strength=0.0, ecm_signal_radius=0.0, mtx_refresh_rate=0.0,
            update_mode="FirstOrderSum",
        )
        steps += 1

    # t3 should be dead, t2 and t1 should still exist
    assert t3_idx not in lut
    assert t2_idx in lut
    assert t1_idx in lut

    # Now t2 is the tip — keep decaying
    while t2_idx in lut and steps < 40:
        lut, ecmtx = decay_severed(
            lut, ecmtx, n,
            base_drain=1.0, interior_factor=0.3, ecm_damping=False,
            ecm_strength=0.0, ecm_signal_radius=0.0, mtx_refresh_rate=0.0,
            update_mode="FirstOrderSum",
        )
        steps += 1

    assert t2_idx not in lut
    assert t1_idx in lut  # t1 should still be alive (was interior longer)

    # Finally t1 dies
    while t1_idx in lut and steps < 60:
        lut, ecmtx = decay_severed(
            lut, ecmtx, n,
            base_drain=1.0, interior_factor=0.3, ecm_damping=False,
            ecm_strength=0.0, ecm_signal_radius=0.0, mtx_refresh_rate=0.0,
            update_mode="FirstOrderSum",
        )
        steps += 1

    assert t1_idx not in lut


def test_ecm_slows_decay():
    """Positive ECM at a tile's position should slow energy drain."""
    lut, source, t1, t2, t3 = _make_chain()
    n = 20
    ecmtx = np.zeros((n, n))

    # Put strong positive ECM at t3's position
    ecmtx[t3.position[0] - 1, t3.position[1] - 1] = 10.0

    source.output_connections[0] = ON
    t1.input_connections[0] = UNUSED
    mark_severed(lut, n, energy_per_tile=1.0)

    initial_energy = t3.energy

    # One decay step with ECM damping
    lut, ecmtx = decay_severed(
        lut, ecmtx, n,
        base_drain=1.0, interior_factor=0.3, ecm_damping=True,
        ecm_strength=0.0, ecm_signal_radius=0.0, mtx_refresh_rate=0.0,
        update_mode="FirstOrderSum",
    )

    t3_idx = pos2idx(7, 7, n)
    if t3_idx in lut:
        # With ECM=10, drain should be 1.0 / (1 + 10) ≈ 0.09, not 1.0
        drained = initial_energy - lut[t3_idx].energy
        assert drained < 0.2  # Much less than base_drain of 1.0


def test_instant_fallback():
    """propagate_deletions_instant should still work (old behavior)."""
    lut, source, t1, t2, t3 = _make_chain()
    n = 20
    ecmtx = np.zeros((n, n))

    source.output_connections[0] = ON
    t1.input_connections[0] = UNUSED

    lut, ecmtx = propagate_deletions_instant(
        lut, ecmtx, n,
        ecm_strength=0.0, ecm_signal_radius=0.0,
        mtx_refresh_rate=0.0, update_mode="FirstOrderSum",
    )

    # All three tiles should be instantly gone
    assert pos2idx(9, 9, n) not in lut
    assert pos2idx(8, 8, n) not in lut
    assert pos2idx(7, 7, n) not in lut
    # Source remains
    assert pos2idx(10, 10, n) in lut


def test_source_never_severed():
    """Source tiles should never be marked as severed."""
    lut, source, t1, t2, t3 = _make_chain()
    n = 20

    source.output_connections[0] = ON
    t1.input_connections[0] = UNUSED
    mark_severed(lut, n, energy_per_tile=1.0)

    assert source.severed is False
    assert source.energy == -1.0
