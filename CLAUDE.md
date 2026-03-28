# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Y-STAM simulates DNA-based tile assemblies using the Branching Signal-Passing Tile Assembly Model. Published in J. Royal Society Interface (2024). The original codebase is MATLAB (R2022); Python conversion lives on the `pY-STAM` branch.

## Commands

```bash
# MATLAB: load all source directories before running anything
matlab -r "run('setup.m')"

# Python (once scaffolded):
pip install -e ".[dev]"
pytest                    # run all tests
pytest tests/test_tile.py # single test file
pytest -k "test_bind"     # single test by name
ruff check ystam/         # lint
black ystam/              # format
```

## Architecture

**Entry point**: `src/ystam.m` — orchestrates the simulation loop across trials.

**Simulation loop** (per trial):
1. **Init** — create TileSet (weighted tile population), Grid (n×n), place source/goal tiles
2. **Disassembly** — `eval_breaks` (stochastic glue detachment) → `settle_glues` (reattach partial) → `propagate_deletions` (remove orphans) → `settle_colors`
3. **Growth** — `refresh_free_edges` (find active growth fronts) → `add_tiles_to_free_edges` (probabilistic tile binding via TileSet weighted selection)
4. **Update** — refresh ECM memory layer, chemotropic gradients, heatmap
5. **Terminate** — check goal reached or time limit; optionally trigger feedback

**Core classes**:
- **Tile** (`src/Tile/Tile.m`) — single assembly unit with dual-channel (forward/backward) glue system. Glues named as 4-char codes: `<Channel F|B><I|O><Compass N|S|E|W><Side U|D|L|R>`. Binding requires: same channel, opposite I/O, diagonal-opposite direction.
- **TileSet** (`src/Tile/TileSet.m`) — manages tile type population with weighted random selection. Supports Michaelis-Menten kinetics (`P = c/(Kd+c)`), branching/turning factors, directional bias.
- **Grid** (`src/Grid/Grid.m`) — spatial state: `LUT` (cell array mapping positions to Tiles), `ecmtx` (extracellular matrix memory), `heatmap`, source/goal management, dead zones, chemotropism.

**Key mechanics**:
- **Glue update rule** (`UpdateRules/glue_update.m`): detachment rate = f(binding_strength, ECM_memory). Positive ECM reinforces; negative ECM repels.
- **Feedback** (`Feedback/`): when assembly reaches goal, backward-channel propagation activates back to source, enabling secondary disassembly evaluation.
- **ECM** params: `[strength, radius, decay_rate, decay_rate_on, refresh_rate]` — spatially-distributed memory influencing growth/disassembly rates.

**Indexing**: MATLAB uses 1-based; `pos2idx(x,y,n) = n*(y-1)+x` (column-major). Python conversion uses 0-based.

## Conversion Guidelines

- Python 3.10+, NumPy for matrices, Matplotlib for viz
- Each MATLAB subdirectory → Python subpackage under `ystam/`
- MATLAB `handle` class semantics → Python pass-by-reference (classes are reference types by default)
- Verify parity with MATLAB on key examples

## Conventions

- Package: `ystam` | Type hints | Dataclasses | Google-style docstrings
- Formatter: black | Linter: ruff

## Planning

- `tasks.md` — phased conversion plan with progress tracking
- `lessons.md` — pitfalls and decisions log
