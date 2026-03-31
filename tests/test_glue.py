"""Tests for the glue system."""

from ystam.tile.glue import (
    Glue,
    can_bind,
    enum_glues,
    grow_offset,
    same_corner,
    same_dir,
    same_side,
    is_turning,
    eval_tile_defn,
)


def test_glue_code():
    g = Glue("F", "O", "N", "R")
    assert g.code == "FONR"
    assert g.direction == "NR"


def test_complement_symmetry():
    g = Glue("F", "O", "N", "R")
    c = g.complement()
    assert c.code == "FISL"
    assert c.complement() == g


def test_complement_preserves_channel():
    g = Glue("B", "I", "W", "D")
    c = g.complement()
    assert c.channel == "B"
    assert c.io == "O"


def test_can_bind_valid():
    g1 = Glue("F", "O", "N", "R")
    g2 = Glue("F", "I", "S", "L")
    assert can_bind(g1, g2)
    assert can_bind(g2, g1)


def test_can_bind_wrong_channel():
    g1 = Glue("F", "O", "N", "R")
    g2 = Glue("B", "I", "S", "L")
    assert not can_bind(g1, g2)


def test_can_bind_same_io():
    g1 = Glue("F", "O", "N", "R")
    g2 = Glue("F", "O", "S", "L")
    assert not can_bind(g1, g2)


def test_same_side():
    g1 = Glue("F", "I", "N", "L")
    g2 = Glue("F", "O", "N", "R")
    assert same_side(g1, g2)


def test_same_dir():
    g1 = Glue("F", "I", "N", "L")
    g2 = Glue("B", "O", "N", "L")
    assert same_dir(g1, g2)


def test_same_corner():
    g1 = Glue("F", "I", "S", "R")
    g2 = Glue("F", "O", "E", "D")
    assert same_corner(g1, g2)


def test_not_same_corner():
    g1 = Glue("F", "I", "N", "L")
    g2 = Glue("F", "O", "E", "D")
    assert not same_corner(g1, g2)


def test_enum_glues():
    glues = enum_glues("F", "I", ["NL", "NR", "SR", "SL"])
    assert len(glues) == 4
    assert glues[0].code == "FINL"
    assert glues[3].code == "FISL"


def test_grow_offset():
    # N+R should give dx=+1, dy=+1
    g = Glue("F", "O", "N", "R")
    assert grow_offset(g) == (1, 1)

    # S+L should give dx=-1, dy=-1
    g = Glue("F", "O", "S", "L")
    assert grow_offset(g) == (-1, -1)

    # E+U should give dx=+1, dy=+1
    g = Glue("F", "O", "E", "U")
    assert grow_offset(g) == (1, 1)

    # W+D should give dx=-1, dy=-1
    g = Glue("F", "O", "W", "D")
    assert grow_offset(g) == (-1, -1)


def test_is_turning():
    # N->S is not turning (opposite compass)
    defn = [Glue("F", "I", "N", "L"), None, Glue("F", "O", "S", "R"), None, None, None]
    assert not is_turning(defn)

    # N->E is turning (adjacent compass)
    defn = [Glue("F", "I", "N", "L"), None, Glue("F", "O", "E", "U"), None, None, None]
    assert is_turning(defn)


def test_eval_tile_defn_standard():
    defn = [
        Glue("F", "I", "N", "L"),
        Glue("B", "I", "N", "L"),
        Glue("F", "O", "S", "R"),
        None,
        Glue("B", "O", "S", "R"),
        None,
    ]
    assert eval_tile_defn(defn) == "standard"


def test_eval_tile_defn_branching():
    defn = [
        Glue("F", "I", "N", "L"),
        Glue("B", "I", "N", "L"),
        Glue("F", "O", "S", "R"),
        Glue("F", "O", "S", "L"),
        Glue("B", "O", "S", "R"),
        Glue("B", "O", "S", "L"),
    ]
    assert eval_tile_defn(defn) == "branching"
