"""Tile class: single assembly unit with dual-channel glue system."""

from __future__ import annotations

from typing import TYPE_CHECKING

from ystam.tile.glue import Glue, NULL, parse_glue

if TYPE_CHECKING:
    pass

# Connection state constants
ON = 1       # Active, ready to bind
LATENT = 0   # Waiting for feedback activation
UNUSED = -1  # Glue doesn't exist


class Tile:
    """A single tile in the assembly with dual-channel (forward/backward) glue connections.

    Attributes:
        position: (x, y) 1-based grid coordinates.
        input_glues: [fwd_input, bwd_input] — always same direction, different channels.
        output_glues: [fwd_out1, fwd_out2, bwd_out1, bwd_out2] — up to 4 outputs.
        input_strengths: Binding strength per input glue.
        output_strengths: Binding strength per output glue.
        input_connections: Tile ref or state (ON/LATENT/UNUSED) per input.
        output_connections: Tile ref or state per output.
        color_flag: Visual category (-1=obstacle, 0=empty, 1=tile, 2=source, 3=goal, 4=feedback).
        seed_coloring: Propagated source identity for multi-seed tracking.
        fb_state: Feedback state (-1=disabled, 0.1/0.2=used, 1=available).
        name: Tile type label.
    """

    __slots__ = (
        "position",
        "input_glues",
        "output_glues",
        "input_strengths",
        "output_strengths",
        "input_connections",
        "output_connections",
        "color_flag",
        "seed_coloring",
        "fb_state",
        "name",
        "severed",
        "energy",
        "max_energy",
    )

    def __init__(self, glue_list: list[Glue | str | None], strength: float) -> None:
        self.position: tuple[int, int] = (-1, -1)
        self.color_flag: int = 1
        self.seed_coloring: int = 0
        self.fb_state: float = -1.0
        self.name: str = "Tile"
        self.severed: bool = False
        self.energy: float = -1.0      # -1 = connected (not severed); >=0 = severed with energy
        self.max_energy: float = 0.0   # Energy at time of severing (for viz ratio)

        # Parse glue_list: [fwd_in, bwd_in, fwd_out1, fwd_out2, bwd_out1, bwd_out2]
        glues = [_to_glue(g) for g in glue_list]
        self.input_glues: list[Glue | None] = [glues[0], glues[1]]
        self.output_glues: list[Glue | None] = [glues[2], glues[3], glues[4], glues[5]]

        s = strength
        self.input_strengths: list[float] = [s, s]
        self.output_strengths: list[float] = [s, s, s, s]

        # Default connection states
        self.input_connections: list[Tile | int] = [ON, ON]
        # FO1=ON, FO2=LATENT, BO1/BO2 depend on whether glue exists
        self.output_connections: list[Tile | int] = [
            ON,
            LATENT,
            ON if glues[4] is not None else UNUSED,
            LATENT if glues[5] is not None else UNUSED,
        ]

    def get_defn(self) -> list[Glue | None]:
        """Return full glue definition [in1, in2, out1, out2, out3, out4]."""
        return self.input_glues + self.output_glues

    def get_input_index(self, glue: Glue) -> int:
        """Return 0-based index of the given glue in input_glues."""
        for i, g in enumerate(self.input_glues):
            if g is not None and g == glue:
                return i
        raise ValueError(f"Input glue {glue} not found on tile at {self.position}")

    def get_output_index(self, glue: Glue) -> int:
        """Return 0-based index of the given glue in output_glues."""
        for i, g in enumerate(self.output_glues):
            if g is not None and g == glue:
                return i
        raise ValueError(f"Output glue {glue} not found on tile at {self.position}")

    def set_glues(
        self, inp: list[Tile | int], out: list[Tile | int]
    ) -> None:
        """Directly set input and output connection states."""
        self.input_connections = list(inp)
        self.output_connections = list(out)

    def set_type(self, tile_type: str, source_branches: int = -1) -> None:
        """Configure this tile as a specific type (source, goal, dead, tile)."""
        if tile_type == "radial-goal":
            self._set_radial_goal()
        elif tile_type == "radial-source":
            self._set_radial_source(source_branches)
        elif tile_type == "dead":
            self._set_dead()
        elif tile_type == "tile":
            self._set_standard()
        else:
            raise ValueError(f"Unknown tile type: {tile_type}")

    def _set_radial_goal(self) -> None:
        """Goal tile: all 8 input directions for both channels, no outputs."""
        all_dirs = ["WD", "WU", "SR", "SL", "EU", "ED", "NL", "NR"]
        s = self.input_strengths[0]
        fwd = [parse_glue(f"FI{d}") for d in all_dirs]
        bwd = [parse_glue(f"BI{d}") for d in all_dirs]
        self.input_glues = fwd + bwd
        self.input_strengths = [s] * 16
        self.input_connections = [ON] * 8 + [LATENT] * 8
        self.output_glues = []
        self.output_strengths = []
        self.output_connections = []
        self.name = "Goal"

    def _set_radial_source(self, branches: int) -> None:
        """Source tile: no inputs, N forward+backward output branches."""
        s = self.output_strengths[0] if self.output_strengths else 1.0
        branch_configs = {
            1: ["WD"],
            2: ["WD", "EU"],
            3: ["WD", "SR", "EU"],
            4: ["WD", "SR", "EU", "NL"],
        }
        if branches not in branch_configs:
            raise ValueError(f"SourceBranches must be 1-4, got {branches}")
        dirs = branch_configs[branches]
        fwd = [parse_glue(f"FO{d}") for d in dirs]
        bwd = [parse_glue(f"BO{d}") for d in dirs]
        self.output_glues = fwd + bwd
        self.output_strengths = [s] * len(self.output_glues)
        self.output_connections = [ON] * len(fwd) + [LATENT] * len(bwd)
        self.input_glues = []
        self.input_strengths = []
        self.input_connections = [UNUSED, UNUSED]
        self.name = "Source"

    def _set_dead(self) -> None:
        """Dead tile: all glues off (obstacle)."""
        self.set_glues([UNUSED, UNUSED], [UNUSED, UNUSED, UNUSED, UNUSED])
        self.color_flag = -1
        self.name = "Dead"

    def _set_standard(self) -> None:
        """Standard assembled tile: forward on, backward latent."""
        self.set_glues([ON, LATENT], [ON, ON, LATENT, LATENT])
        self.color_flag = 1
        self.name = "Tile"

    def is_source(self) -> bool:
        return self.name == "Source"

    def is_goal(self) -> bool:
        return self.name == "Goal"

    def eval_class(self) -> str:
        """Return 'branching' if tile has multiple FO glues, else 'standard'."""
        fo_count = sum(
            1 for g in self.output_glues if g is not None and g.channel == "F" and g.io == "O"
        )
        return "branching" if fo_count > 1 else "standard"


def _to_glue(g: Glue | str | None) -> Glue | None:
    """Convert a glue spec to a Glue object, or None for NULL."""
    if g is None or g == NULL:
        return None
    if isinstance(g, Glue):
        return g
    return parse_glue(g)


def is_adjacent(t1: Tile, t2: Tile) -> bool:
    """Check if two tiles are diagonally adjacent (distance = sqrt(2))."""
    dx = abs(t2.position[0] - t1.position[0])
    dy = abs(t2.position[1] - t1.position[1])
    return dx == 1 and dy == 1
