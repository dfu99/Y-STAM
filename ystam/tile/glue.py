"""Glue system: naming, complement, binding rules, and tile classification predicates."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

# Compass opposites and side opposites for binding / complement
_COMPASS_OPP = {"N": "S", "S": "N", "E": "W", "W": "E"}
_SIDE_OPP = {"U": "D", "D": "U", "L": "R", "R": "L"}

# Corner pairs: glues that share the same physical corner of the tile
_CORNER_PAIRS = frozenset(
    {("SR", "ED"), ("ED", "SR"), ("NR", "EU"), ("EU", "NR"),
     ("NL", "WU"), ("WU", "NL"), ("SL", "WD"), ("WD", "SL")}
)

NULL = "NULL"


@dataclass(frozen=True)
class Glue:
    """A single glue label: <Channel><I/O><Compass><Side>."""

    channel: Literal["F", "B"]
    io: Literal["I", "O"]
    compass: Literal["N", "S", "E", "W"]
    side: Literal["U", "D", "L", "R"]

    @property
    def code(self) -> str:
        return f"{self.channel}{self.io}{self.compass}{self.side}"

    @property
    def direction(self) -> str:
        """The two-char compass+side direction, e.g. 'NR'."""
        return f"{self.compass}{self.side}"

    def complement(self) -> Glue:
        """Binding complement: same channel, opposite I/O, diagonal-opposite direction."""
        return Glue(
            channel=self.channel,
            io="O" if self.io == "I" else "I",
            compass=_COMPASS_OPP[self.compass],
            side=_SIDE_OPP[self.side],
        )

    def __str__(self) -> str:
        return self.code

    def __repr__(self) -> str:
        return self.code


def parse_glue(code: str) -> Glue:
    """Parse a 4-char glue code string into a Glue object."""
    if code == NULL or code is None:
        raise ValueError("Cannot parse NULL glue")
    return Glue(channel=code[0], io=code[1], compass=code[2], side=code[3])


# ---------------------------------------------------------------------------
# Enumeration
# ---------------------------------------------------------------------------

def enum_glues(
    channel: str, io: str, directions: list[str]
) -> list[Glue]:
    """Generate all glues for given channel, I/O, and direction list."""
    return [Glue(channel=channel, io=io, compass=d[0], side=d[1]) for d in directions]


# ---------------------------------------------------------------------------
# Binding rules
# ---------------------------------------------------------------------------

def can_bind(g1: Glue, g2: Glue) -> bool:
    """Check whether two glues can bind (same channel, opposite I/O, diagonal-opposite dir)."""
    if g1.channel != g2.channel:
        return False
    if not ((g1.io == "I" and g2.io == "O") or (g1.io == "O" and g2.io == "I")):
        return False
    if _COMPASS_OPP.get(g1.compass) != g2.compass:
        return False
    if _SIDE_OPP.get(g1.side) != g2.side:
        return False
    return True


# ---------------------------------------------------------------------------
# Predicate functions for tile classification
# ---------------------------------------------------------------------------

def same_side(g1: Glue | str, g2: Glue | str) -> bool:
    """True if two glues share the same compass (edge side of tile)."""
    c1 = g1.compass if isinstance(g1, Glue) else g1[2]
    c2 = g2.compass if isinstance(g2, Glue) else g2[2]
    return c1 == c2


def same_dir(g1: Glue | str, g2: Glue | str) -> bool:
    """True if two glues share the same compass+side direction."""
    d1 = g1.direction if isinstance(g1, Glue) else g1[2:4]
    d2 = g2.direction if isinstance(g2, Glue) else g2[2:4]
    return d1 == d2


def same_corner(g1: Glue | str, g2: Glue | str) -> bool:
    """True if two glues occupy the same physical corner (e.g. SR and ED)."""
    d1 = g1.direction if isinstance(g1, Glue) else g1[2:4]
    d2 = g2.direction if isinstance(g2, Glue) else g2[2:4]
    return (d1, d2) in _CORNER_PAIRS


def is_turning(defn: list[Glue | str]) -> bool:
    """True if a tile definition represents a turning tile (non-opposite compass dirs)."""
    inp = defn[0]
    out = defn[2]
    ic = inp.compass if isinstance(inp, Glue) else inp[2]
    oc = out.compass if isinstance(out, Glue) else out[2]
    return _COMPASS_OPP.get(ic) != oc


def is_direction(defn: list[Glue | str], direction: str) -> bool:
    """True if tile's first forward output points in the given direction."""
    out = defn[2]
    d = out.direction if isinstance(out, Glue) else out[2:4]
    return d == direction


def eval_tile_defn(defn: list[Glue | str]) -> str:
    """Classify a tile definition as 'branching' or 'standard' based on FO glue count."""
    fo_count = 0
    for g in defn:
        if g is None or g == NULL:
            continue
        code = g.code if isinstance(g, Glue) else str(g)
        if len(code) >= 2 and code[:2] == "FO":
            fo_count += 1
    return "branching" if fo_count > 1 else "standard"


# ---------------------------------------------------------------------------
# Growth direction offset from glue
# ---------------------------------------------------------------------------

def grow_offset(glue: Glue) -> tuple[int, int]:
    """Return (dx, dy) offset for growing a new tile from the given output glue.

    Compass: N→dx+1, S→dx-1, E→dy+1, W→dy-1
    Side:    U→dx+1, D→dx-1, R→dy+1, L→dy-1
    """
    dx = 0
    dy = 0
    if glue.compass == "N":
        dx = 1
    elif glue.compass == "S":
        dx = -1
    elif glue.compass == "E":
        dy = 1
    elif glue.compass == "W":
        dy = -1

    if glue.side == "U":
        dx = 1
    elif glue.side == "D":
        dx = -1
    elif glue.side == "R":
        dy = 1
    elif glue.side == "L":
        dy = -1

    return dx, dy
