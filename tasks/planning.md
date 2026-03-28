# Conversion Plan

## Phase 1: Project scaffolding
- [ ] Create Python package structure (`ystam/` with subpackages)
- [ ] Set up pyproject.toml with dependencies (numpy, matplotlib, etc.)
- [ ] Create test scaffold (pytest)

## Phase 2: Core data structures
- [ ] Convert `Tile.m` -> `ystam/tile/tile.py`
- [ ] Convert `TileSet.m` -> `ystam/tile/tileset.py`
- [ ] Convert `Grid.m` -> `ystam/grid/grid.py`
- [ ] Convert glue/binding enums and helpers (`enum_glues.m`, `binding_rules.m`, etc.)

## Phase 3: Simulation logic
- [ ] Convert growth mechanics (`Grow/`)
- [ ] Convert disassembly mechanics (`Disassemble/`)
- [ ] Convert feedback propagation (`Feedback/`)
- [ ] Convert update rules (`UpdateRules/`)
- [ ] Convert termination logic (`Termination/`)

## Phase 4: Visualization & utilities
- [ ] Convert `Visualize/` to matplotlib
- [ ] Convert `Helper/` utilities
- [ ] Convert `Debug/` tools

## Phase 5: Examples & validation
- [ ] Port example scripts as runnable demos
- [ ] Validate output parity with MATLAB on key examples

## Phase 6: Polish
- [ ] CLI entry point
- [ ] Documentation
- [ ] CI setup
