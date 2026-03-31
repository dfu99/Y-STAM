"""Tests for Tile class."""

from ystam.tile.tile import Tile, is_adjacent, ON, LATENT, UNUSED
from ystam.tile.glue import Glue


def test_tile_construction():
    glue_list = ["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"]
    t = Tile(glue_list, 0.95)
    assert t.input_glues[0].code == "FINL"
    assert t.input_glues[1].code == "BINL"
    assert t.output_glues[0].code == "FOSR"
    assert t.output_glues[1] is None


def test_set_type_radial_source():
    glue_list = ["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"]
    t = Tile(glue_list, 0.95)
    t.set_type("radial-source", source_branches=4)
    assert t.name == "Source"
    assert len(t.output_glues) == 8  # 4 FO + 4 BO
    assert all(ic == UNUSED for ic in t.input_connections)


def test_set_type_radial_goal():
    glue_list = ["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"]
    t = Tile(glue_list, 0.95)
    t.set_type("radial-goal")
    assert t.name == "Goal"
    assert len(t.input_glues) == 16  # 8 FI + 8 BI


def test_set_type_dead():
    glue_list = ["NULL", "NULL", "NULL", "NULL", "NULL", "NULL"]
    t = Tile(glue_list, 0)
    t.set_type("dead")
    assert t.name == "Dead"
    assert t.color_flag == -1


def test_is_adjacent():
    t1 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t1.position = (5, 5)
    t2 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t2.position = (6, 6)
    assert is_adjacent(t1, t2)

    t3 = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    t3.position = (5, 7)
    assert not is_adjacent(t1, t3)


def test_eval_class():
    # Standard tile
    t = Tile(["FINL", "BINL", "FOSR", "NULL", "BOSR", "NULL"], 0.95)
    assert t.eval_class() == "standard"

    # Manually add a second FO output
    t.output_glues.insert(1, Glue("F", "O", "S", "L"))
    assert t.eval_class() == "branching"
