# Lessons Learned

## 2026-03-29: Python 3.9 compatibility
System Python on macOS is 3.9.6. Had to drop `slots=True` from dataclass decorators
and use `from __future__ import annotations` for `X | Y` type hints.
Changed pyproject.toml to require `>=3.9`.

## 2026-03-29: MATLAB 1-based indexing preserved internally
Tile positions and LUT indices remain 1-based to match MATLAB semantics exactly.
Array indexing into numpy matrices uses `[x-1, y-1]`. This was a deliberate choice
to minimize conversion bugs — the MATLAB source is the reference.

## 2026-03-29: Sparse LUT over flat cell array
MATLAB uses `cell(1, n*n)` with `isempty()` checks. Python uses `dict[int, Tile]`
which is more efficient for sparse grids and avoids None-checking everywhere.
Iteration only visits occupied cells.

## 2026-03-29: Chemotropism from ALL goals
MATLAB `add_goal_trunks()` only emits chemotropic gradient from `tf{1}` (first goal).
For the fungal simulator with scattered food, we emit from ALL goals so each food source
attracts growth independently.
