"""Termination logic: check if simulation should stop or trigger feedback."""

from __future__ import annotations

from ystam.feedback.feedback import check_inputs
from ystam.tile.tile import Tile


def is_done(
    lut: dict[int, Tile],
    n: int,
    goals: list[Tile],
    timesteps: int,
    time_limit: int,
    continuous: bool,
    use_feedback: bool,
    hitflag: bool,
    hit_time: int,
) -> tuple[bool, bool, bool, int]:
    """Check termination conditions.

    Returns:
        (should_break, should_feedback, hitflag, hit_time)
    """
    should_break = False
    should_feedback = False

    # Time limit check (applies to all modes)
    if time_limit > 0 and timesteps >= time_limit:
        return True, False, hitflag, hit_time

    if continuous:
        # Check if any goal has adjacent tiles
        if goals:
            for goal in goals:
                results = check_inputs(goal, lut, n)
                any_adjacent = any(has for has, _, _ in results)
                if any_adjacent:
                    hit_time += 1
                    hitflag = True
                    break

        if use_feedback:
            should_feedback = True

    else:
        # Non-continuous: check if any goal was reached
        if goals:
            for goal in goals:
                results = check_inputs(goal, lut, n)
                any_adjacent = any(has for has, _, _ in results)
                if any_adjacent:
                    return True, False, True, hit_time + 1

    return should_break, should_feedback, hitflag, hit_time
