"""Coordinate helpers and combinatorial utilities."""

from __future__ import annotations

from itertools import product


def pos2idx(x: int, y: int, n: int) -> int:
    """Convert 1-based (x, y) position to 1-based linear index (column-major)."""
    return n * (y - 1) + x


def idx2pos(idx: int, n: int) -> tuple[int, int]:
    """Convert 1-based linear index back to 1-based (x, y) position."""
    y = (idx - 1) // n + 1
    x = (idx - 1) % n + 1
    return x, y


def combinations(arr1: list[str], arr2: list[str]) -> list[tuple[str, str]]:
    """All ordered pairs from two lists (cartesian product)."""
    return list(product(arr1, arr2))
