"""Line-based renderer: draws hyphae as smooth weighted tree branches."""

from __future__ import annotations

from typing import TYPE_CHECKING

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.patches import Circle, Rectangle

if TYPE_CHECKING:
    from ystam.viz.animation import FrameData


BG_COLOR = "#0a0a0a"
HYPHA_RGB = (0.77, 0.65, 0.42)
HYPHA_TIP_RGB = (0.91, 0.84, 0.64)
FEEDBACK_RGB = (1.0, 0.84, 0.0)
SEVERED_RGB = (0.85, 0.35, 0.20)
SOURCE_COLOR = "#d4513a"
FOOD_COLOR = "#4caf50"
OBSTACLE_COLOR = "#2a2a2a"


def _smooth_path(points: list[tuple[float, float]], resolution: int = 4) -> np.ndarray:
    """Catmull-Rom spline interpolation for smooth curves."""
    pts = np.array(points, dtype=float)
    if len(pts) < 3:
        return pts
    padded = np.vstack([pts[0], pts, pts[-1]])
    n = len(padded)
    smoothed = []
    for i in range(1, n - 2):
        p0, p1, p2, p3 = padded[i - 1], padded[i], padded[i + 1], padded[i + 2]
        for t_step in range(resolution):
            t = t_step / resolution
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2*p1[0]) + (-p0[0]+p2[0])*t + (2*p0[0]-5*p1[0]+4*p2[0]-p3[0])*t2 + (-p0[0]+3*p1[0]-3*p2[0]+p3[0])*t3)
            y = 0.5 * ((2*p1[1]) + (-p0[1]+p2[1])*t + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2 + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3)
            smoothed.append((x, y))
    smoothed.append(tuple(pts[-1]))
    return np.array(smoothed)


def _jitter(x: float, y: float, scale: float = 0.2) -> tuple[float, float]:
    """Deterministic spatial jitter for organic feel."""
    h = hash((round(x * 1000), round(y * 1000)))
    jx = ((h % 1000) / 500.0 - 1.0) * scale
    jy = (((h >> 10) % 1000) / 500.0 - 1.0) * scale
    return x + jx, y + jy


class SimRenderer:
    """Renders hyphae as a weighted branching tree with smooth curves."""

    def __init__(self, n: int, show_ecm: bool = True,
                 figsize: tuple[float, float] = (10, 10)) -> None:
        self.n = n
        ncols = 1 + int(show_ecm)
        self.fig, axes = plt.subplots(
            1, ncols, figsize=(figsize[0] * ncols * 0.55, figsize[1]),
            facecolor=BG_COLOR,
        )
        if ncols == 1:
            axes = [axes]
        self.axes = list(axes)
        self.ax_main = self.axes[0]
        self.ax_ecm = self.axes[1] if show_ecm else None

        for ax in self.axes:
            ax.set_facecolor(BG_COLOR)
            ax.set_xlim(0, n)
            ax.set_ylim(0, n)
            ax.set_aspect("equal")
            ax.set_xticks([])
            ax.set_yticks([])
            for spine in ax.spines.values():
                spine.set_visible(False)

    def render_frame(self, frame: FrameData) -> None:
        bounds = self._compute_bounds(frame)
        self._draw_network(frame, bounds)
        if self.ax_ecm is not None:
            self._draw_ecm(frame.ecmtx, bounds)

    def _compute_bounds(self, frame: FrameData) -> tuple[float, float, float, float]:
        """Compute tight bounding box from all content with padding."""
        all_y, all_x = [], []
        for y, x in frame.source_positions + frame.goal_positions + frame.tip_positions:
            all_y.append(y)
            all_x.append(x)
        for branch_data in frame.branches:
            for pos in branch_data[0]:
                all_y.append(pos[1])  # y from (x,y) tuple
                all_x.append(pos[0])  # x from (x,y) tuple
        if not all_y:
            return 0, self.n, 0, self.n
        pad = self.n * 0.05
        return (
            max(0, min(all_y) - pad), min(self.n, max(all_y) + pad),
            max(0, min(all_x) - pad), min(self.n, max(all_x) + pad),
        )

    def _draw_network(self, frame: FrameData, bounds: tuple) -> None:
        ax = self.ax_main
        ax.clear()
        ax.set_facecolor(BG_COLOR)
        y_lo, y_hi, x_lo, x_hi = bounds
        ax.set_xlim(y_lo, y_hi)
        ax.set_ylim(x_lo, x_hi)
        ax.set_aspect("equal")
        ax.set_xticks([])
        ax.set_yticks([])
        for spine in ax.spines.values():
            spine.set_visible(False)

        # Obstacles
        for y, x in frame.obstacle_positions:
            ax.add_patch(Rectangle((y - 0.5, x - 0.5), 1, 1,
                                   facecolor=OBSTACLE_COLOR, edgecolor="none"))

        max_w = max(frame.max_weight, 1)

        # Draw each tree branch as a smooth curve with weight-dependent thickness
        for branch_data in frame.branches:
            path_positions, weight, is_fb = branch_data[0], branch_data[1], branch_data[2]
            is_severed = branch_data[3] if len(branch_data) > 3 else False
            energy_ratio = branch_data[4] if len(branch_data) > 4 else 1.0

            if len(path_positions) < 2:
                continue

            jittered = [_jitter(float(pos[1]), float(pos[0])) for pos in path_positions]
            smooth = _smooth_path(jittered, resolution=3)
            if len(smooth) < 2:
                continue

            n_pts = len(smooth)
            segments = [[smooth[i], smooth[i + 1]] for i in range(n_pts - 1)]

            w_frac = np.log1p(weight) / np.log1p(max_w)

            if is_severed:
                # Interpolate from HYPHA_RGB toward SEVERED_RGB as energy drops
                t = max(0.0, min(1.0, 1.0 - energy_ratio))
                rgb = tuple(h * (1 - t) + s * t for h, s in zip(HYPHA_RGB, SEVERED_RGB))
                base_w = 0.2 + w_frac * 1.5
                tip_w = 0.1 + w_frac * 0.3
                alpha = max(0.1, 0.2 + energy_ratio * 0.45 + w_frac * 0.2)
                glow_alpha = max(0.01, 0.01 + energy_ratio * 0.03)
            elif is_fb:
                base_w = 1.0 + w_frac * 3.0
                tip_w = 0.8 + w_frac * 1.5
                rgb = FEEDBACK_RGB
                alpha = 0.7 + w_frac * 0.25
                glow_alpha = 0.06 + w_frac * 0.06
            else:
                base_w = 0.3 + w_frac * 2.0
                tip_w = 0.15 + w_frac * 0.5
                rgb = HYPHA_RGB
                alpha = 0.3 + w_frac * 0.45
                glow_alpha = 0.02 + w_frac * 0.04

            widths = np.linspace(base_w, tip_w, len(segments))
            colors = [(*rgb, alpha)] * len(segments)

            # Glow
            glow_widths = widths * 3.5
            glow_colors = [(*rgb, glow_alpha)] * len(segments)
            ax.add_collection(LineCollection(
                segments, linewidths=glow_widths, colors=glow_colors,
                zorder=1, capstyle="round"))

            # Core
            ax.add_collection(LineCollection(
                segments, linewidths=widths, colors=colors,
                zorder=4 if not is_fb else 5, capstyle="round"))

        # Growth tips
        if frame.tip_positions:
            tips_y, tips_x = zip(*frame.tip_positions)
            jt = [_jitter(ty, tx) for ty, tx in zip(tips_y, tips_x)]
            jty, jtx = zip(*jt)
            ax.scatter(jty, jtx, s=3, c=[HYPHA_TIP_RGB],
                       alpha=0.8, zorder=7, edgecolors="none")
            ax.scatter(jty, jtx, s=18, c=[(*HYPHA_RGB, 0.08)],
                       zorder=6, edgecolors="none")

        # Colony
        for y, x in frame.source_positions:
            ax.add_patch(Circle((y, x), self.n * 0.012,
                                facecolor=SOURCE_COLOR, edgecolor="#ff8866",
                                linewidth=1.0, alpha=0.95, zorder=10))
            ax.add_patch(Circle((y, x), self.n * 0.04,
                                facecolor=SOURCE_COLOR, edgecolor="none",
                                alpha=0.07, zorder=9))

        # Food
        for y, x in frame.goal_positions:
            ax.add_patch(Circle((y, x), self.n * 0.008,
                                facecolor=FOOD_COLOR, edgecolor="#88cc88",
                                linewidth=0.8, alpha=0.9, zorder=10))
            ax.add_patch(Circle((y, x), self.n * 0.025,
                                facecolor=FOOD_COLOR, edgecolor="none",
                                alpha=0.05, zorder=9))

        ax.set_title(f"t = {frame.timestep}", color="#555555",
                     fontsize=9, pad=4, loc="right")

    def _draw_ecm(self, ecmtx: np.ndarray, bounds: tuple) -> None:
        ax = self.ax_ecm
        ax.clear()
        ax.set_facecolor(BG_COLOR)
        y_lo, y_hi, x_lo, x_hi = bounds
        ax.set_xlim(y_lo, y_hi)
        ax.set_ylim(x_lo, x_hi)
        ax.set_aspect("equal")
        ax.set_xticks([])
        ax.set_yticks([])
        for spine in ax.spines.values():
            spine.set_visible(False)
        vmax = max(abs(ecmtx.max()), abs(ecmtx.min()), 0.1)
        ax.imshow(ecmtx, cmap="inferno", vmin=0, vmax=vmax,
                  origin="lower", extent=(0, self.n, 0, self.n), alpha=0.85)
        ax.set_title("Chemical Memory", color="#555555", fontsize=9, pad=4, loc="right")

    def save_frame(self, path: str) -> None:
        self.fig.savefig(path, dpi=200, facecolor=BG_COLOR, bbox_inches="tight")

    def close(self) -> None:
        plt.close(self.fig)
