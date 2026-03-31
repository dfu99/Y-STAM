# Conversion Plan

## Phase 1: Project scaffolding
- [x] Create Python package structure (`ystam/` with subpackages)
- [x] Set up pyproject.toml with dependencies (numpy, matplotlib, etc.)
- [x] Create test scaffold (pytest)

## Phase 2: Core data structures
- [x] Convert `Tile.m` -> `ystam/tile/tile.py`
- [x] Convert `TileSet.m` -> `ystam/tile/tileset.py`
- [x] Convert `Grid.m` -> `ystam/grid/grid.py`
- [x] Convert glue/binding enums and helpers (`enum_glues.m`, `binding_rules.m`, etc.)

## Phase 3: Simulation logic
- [x] Convert growth mechanics (`Grow/`) -> `ystam/grow/grow.py`
- [x] Convert disassembly mechanics (`Disassemble/`) -> `ystam/disassemble/disassemble.py`
- [x] Convert feedback propagation (`Feedback/`) -> `ystam/feedback/feedback.py`
- [x] Convert update rules (`UpdateRules/`) -> `ystam/update_rules/glue_update.py`
- [x] Convert termination logic (`Termination/`) -> `ystam/termination/termination.py`

## Phase 4: Visualization
- [x] Line-based hypha renderer (`ystam/viz/renderer.py`)
- [x] Animation/mp4 export (`ystam/viz/animation.py`)

## Phase 5: Fungal domain layer
- [x] FungalConfig -> SimConfig mapping (`ystam/fungal/config.py`)
- [x] FungalColony high-level API (`ystam/fungal/colony.py`)
- [x] Demo scripts: foraging, maze, physarum (`demos/`)

## Phase 6: Validation & polish
- [ ] Run demo_foraging.py end-to-end, verify video output
- [ ] Validate parity with MATLAB on eg_2d_fb_ecm parameters
- [ ] CLI entry point
- [ ] CI setup
