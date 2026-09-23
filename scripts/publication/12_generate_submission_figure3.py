"""Redraw existing Figure 3 estimates; never fit or alter a statistical model."""
from pathlib import Path
import csv
import hashlib
import math
import json
import os
BASE = Path(__file__).resolve().parents[2]
os.environ.setdefault("MPLCONFIGDIR", str(BASE / ".cache/matplotlib"))
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import FuncFormatter
from matplotlib import font_manager
from PIL import Image

# Use actual Times New Roman fonts and fail instead of silently substituting.
for font_name in ["times.ttf", "timesbd.ttf"]:
    font_path = Path("C:/Windows/Fonts") / font_name
    if font_path.exists():
        font_manager.fontManager.addfont(str(font_path))
resolved_fonts = {
    weight: font_manager.findfont(
        font_manager.FontProperties(family="Times New Roman", weight=weight),
        fallback_to_default=False,
    )
    for weight in ["normal", "bold"]
}
assert all(font_manager.FontProperties(fname=p).get_name() == "Times New Roman"
           for p in resolved_fonts.values())

SOURCES = BASE / "analysis_spatial_falsification_revised_dev/tables"
OUT = Path(os.environ.get("UPEMBA_FIGURE_OUTPUT_DIR", str(BASE / "outputs/_validation/current_figures")))
OUT.mkdir(parents=True, exist_ok=True)

PROFILES = ["Neither actor dominant", "Militia dominant", "Park dominant"]
LABELS = ["Fragmented control", "Militia-centred control", "Park-centred control"]
OUTCOMES = ["tree_cover_loss", "fire", "agriculture"]
OUTCOME_LABELS = ["Tree-cover loss", "Fire", "Agricultural expansion"]
# Darker versions of the manuscript's grey, ochre and blue palette.
COLORS = ["#525252", "#917438", "#41658A"]
FILLS = ["#C5C5C5", "#CFBA86", "#AFC2D8"]

def number(text):
    try:
        return float(text)
    except (TypeError, ValueError):
        return math.nan

records = []
source_paths = []
for filename, fire in [("fire_boundary_profile_contrasts.csv", True),
                       ("sparse_boundary_profile_estimates.csv", False)]:
    path = SOURCES / filename
    source_paths.append(path)
    with path.open(encoding="utf-8-sig", newline="") as handle:
        for source in csv.DictReader(handle):
            if source["threshold_tag"] != "tau025":
                continue
            if not fire and source["model_type"] != "inverse_variance_weighted_lm_hc3":
                continue
            distance = number(source["boundary_center_km"])
            if distance not in [0, *range(15, 61, 5)]:
                continue
            lo, hi = number(source["lower_95_ci"]), number(source["upper_95_ci"])
            accepted = (source["retained_status"] == "strict-valid") if fire else True
            draw_ci = accepted and math.isfinite(lo) and math.isfinite(hi)
            records.append(dict(
                outcome=source["outcome"], profile=source["governance_profile"],
                boundary_center_km=distance, estimate=number(source["estimate"]),
                lower_95_ci=lo, upper_95_ci=hi, show_interval=draw_ci,
                fit_status=source.get("retained_status", "accepted two-stage estimate"),
                source_file=filename,
            ))

# Validate the exact selection, main values, intervals and outer ranges against
# retained legal-boundary and outer-range values (rounded to 3 decimals).
expected = {
    ("tree_cover_loss", PROFILES[0]): (-.846, -1.293, -.399, -.393, .520),
    ("tree_cover_loss", PROFILES[1]): (-.898, -1.509, -.287, -.427, .309),
    ("tree_cover_loss", PROFILES[2]): (-1.430, -1.941, -.919, -.568, .547),
    ("fire", PROFILES[0]): (.170, .112, .229, -.324, .422),
    ("fire", PROFILES[1]): (.011, -.054, .075, -.350, .513),
    ("fire", PROFILES[2]): (.068, .008, .128, -.484, .555),
    ("agriculture", PROFILES[0]): (.286, -.164, .737, -.913, .388),
    ("agriculture", PROFILES[1]): (.222, -.048, .492, -1.262, .622),
    ("agriculture", PROFILES[2]): (-.347, -.657, -.037, -.868, .499),
}
assert len(records) == 99
assert len({(r["outcome"], r["profile"], r["boundary_center_km"]) for r in records}) == 99
checks = []
for key, expected_values in expected.items():
    group = [r for r in records if (r["outcome"], r["profile"]) == key]
    legal = next(r for r in group if r["boundary_center_km"] == 0)
    outer = [r for r in group if r["boundary_center_km"] > 0]
    assert len(outer) == 10 and legal["show_interval"]
    values = [legal["estimate"], legal["lower_95_ci"], legal["upper_95_ci"],
              min(r["estimate"] for r in outer), max(r["estimate"] for r in outer)]
    for observed, reported in zip(values, expected_values):
        assert abs(observed - reported) <= .0005001, (key, observed, reported)
    checks.append({"outcome": key[0], "profile": key[1], "table_s17_matches": True})
for r in records:
    assert math.isfinite(r["estimate"])
    if r["show_interval"]:
        assert r["lower_95_ci"] <= r["estimate"] <= r["upper_95_ci"]

with (OUT / "Figure_3_plot_data.csv").open("w", newline="", encoding="utf-8") as handle:
    writer = csv.DictWriter(handle, fieldnames=list(records[0]))
    writer.writeheader()
    writer.writerows(records)

plt.rcParams.update({
    "font.family": "Times New Roman", "font.size": 8,
    "axes.linewidth": .5, "axes.labelsize": 8.5,
    "xtick.labelsize": 7.5, "ytick.labelsize": 7.5,
    "pdf.fonttype": 42, "ps.fonttype": 42, "svg.fonttype": "none",
    "axes.unicode_minus": True,
})
fig, axes = plt.subplots(3, 3, figsize=(180 / 25.4, 159 / 25.4), sharex=True, sharey="row")
fig.subplots_adjust(left=.092, right=.991, top=.90, bottom=.16, wspace=.085, hspace=.45)

limits = [(-2.06, 1.10), (-.58, .66), (-2.16, 1.48)]
ticks = [[-2, -1, 0, 1], [-.5, 0, .5], [-2, -1, 0, 1]]
for r in records:
    lower, upper = limits[OUTCOMES.index(r["outcome"])]
    assert lower < r["estimate"] < upper
    if r["show_interval"]:
        assert lower < r["lower_95_ci"] <= r["upper_95_ci"] < upper
def tick_label(value, _):
    return f"{value:g}".replace("-", "\N{MINUS SIGN}")
def estimate_label(value):
    return f"{value:.2f}".replace("-", "\N{MINUS SIGN}")

for row, outcome in enumerate(OUTCOMES):
    for col, profile in enumerate(PROFILES):
        ax = axes[row, col]
        ax.set_xlim(-5, 63)
        ax.set_ylim(limits[row])
        ax.set_yticks(ticks[row])
        ax.yaxis.set_major_formatter(FuncFormatter(tick_label))
        ax.axvspan(-4.5, 5, facecolor="#F0F0F0", edgecolor="none", zorder=0)
        for tick in ticks[row]:
            ax.axhline(tick, color="#E7E7E7" if tick else "#929292",
                       linewidth=.45 if tick else .7, zorder=1)
        for spine in ["top", "right", "left"]:
            ax.spines[spine].set_visible(False)
        ax.spines["bottom"].set_color("#BBBBBB")
        ax.tick_params(axis="y", length=0, pad=3)
        ax.tick_params(axis="x", length=2, color="#AAAAAA", pad=3)
        group = sorted([r for r in records if r["outcome"] == outcome and r["profile"] == profile],
                       key=lambda r: r["boundary_center_km"])
        legal, outer = group[0], group[1:]
        ax.plot([r["boundary_center_km"] for r in outer], [r["estimate"] for r in outer],
                color="#B5B5B5", linewidth=.65, zorder=2)
        for r in outer:
            x, y = r["boundary_center_km"], r["estimate"]
            if r["show_interval"]:
                ax.vlines(x, r["lower_95_ci"], r["upper_95_ci"], color="#858585", linewidth=.7, zorder=3)
            ax.plot(x, y, marker="o", markersize=3.7, linestyle="none",
                    markeredgecolor=COLORS[col], markeredgewidth=.7,
                    markerfacecolor=FILLS[col] if r["show_interval"] else "white", zorder=4)
        ax.vlines(0, legal["lower_95_ci"], legal["upper_95_ci"], color=COLORS[col], linewidth=1.45, zorder=5)
        ax.hlines([legal["lower_95_ci"], legal["upper_95_ci"]], -1.2, 1.2,
                  color=COLORS[col], linewidth=1.0, zorder=5)
        ax.plot(0, legal["estimate"], marker="D", markersize=5.2, linestyle="none",
                markeredgecolor=COLORS[col], markeredgewidth=.9, markerfacecolor=COLORS[col], zorder=6)
        ax.text(3.5, legal["estimate"], estimate_label(legal["estimate"]),
                va="center", ha="left", fontsize=7.5, weight="bold", color=COLORS[col], zorder=7,
                bbox=dict(facecolor="white", alpha=.9, edgecolor="none", pad=.45))
        ax.set_xticks([0, 15, 30, 45, 60])
        ax.set_xticklabels(["Legal\nboundary", "15", "30", "45", "60"])
        if row < 2:
            ax.tick_params(axis="x", labelbottom=False)
        if col > 0:
            ax.tick_params(axis="y", labelleft=False)

for col, label in enumerate(LABELS):
    position = axes[0, col].get_position()
    fig.text((position.x0 + position.x1) / 2, .968, label, ha="center", va="center",
             fontsize=9, weight="bold", color=COLORS[col])
    fig.add_artist(Line2D([position.x0, position.x1], [.949, .949],
                         transform=fig.transFigure, color=COLORS[col], linewidth=1.35))
for row, label in enumerate(OUTCOME_LABELS):
    position = axes[row, 0].get_position()
    fig.text(position.x0, position.y1 + .013, f"{'ABC'[row]}   {label}",
             ha="left", va="bottom", fontsize=9, weight="bold", color="#252525")

fig.text(.020, .535, "Log-odds contrast (park-facing − outward-facing)",
         rotation=90, ha="center", va="center", fontsize=8.5)
fig.text(.55, .080, "Boundary centre outside the legal boundary (km)", ha="center", fontsize=8.5)
legend_handles = [
    Line2D([0], [0], marker="D", color="#3D3D3D", markerfacecolor="#3D3D3D", markersize=5, linestyle="none", label="Legal boundary"),
    Line2D([0], [0], marker="o", color="#666666", markerfacecolor="#BBBBBB", markersize=4, linestyle="none", label="Outer: 95% CI shown"),
    Line2D([0], [0], marker="o", color="#666666", markerfacecolor="white", markersize=4, linestyle="none", label="Outer: CI not interpreted"),
]
fig.legend(handles=legend_handles, loc="lower center", bbox_to_anchor=(.54, .008),
           ncol=3, frameon=False, fontsize=7.5, handlelength=1.1, columnspacing=1.2, handletextpad=.5)

# Verify text stays within the figure canvas before export.
fig.canvas.draw()
renderer = fig.canvas.get_renderer()
for artist in fig.findobj(matplotlib.text.Text):
    if artist.get_visible() and artist.get_text():
        box = artist.get_window_extent(renderer)
        assert box.x0 >= -1 and box.y0 >= -1, artist.get_text()
        assert box.x1 <= fig.bbox.width + 1 and box.y1 <= fig.bbox.height + 1, artist.get_text()
for suffix in ["pdf", "svg", "png"]:
    fig.savefig(OUT / f"Figure_3.{suffix}", dpi=400, facecolor="white")
fig.savefig(OUT / "Figure_3.tif", dpi=1000, facecolor="white",
            pil_kwargs={"compression": "tiff_lzw"})
# TIFF export uses an opaque RGB colour space; no transparency is needed.
with Image.open(OUT / "Figure_3.tif") as tiff:
    rgb_tiff = tiff.convert("RGB")
rgb_tiff.save(OUT / "Figure_3.tif", compression="tiff_lzw", dpi=(1000, 1000))
rgb_tiff.save(OUT / "Figure_3_1000dpi.png", dpi=(1000, 1000))
rgb_tiff.close()
plt.close(fig)

caption = (
    "Figure 3. Legal-boundary contrasts and outer spatial diagnostics. Diamonds mark legal-boundary "
    "estimates; circles mark ten outer pseudo-boundaries at 5 km increments from +15 to +60 km. "
    "Each contrast compares 10 km bands on either side using the 25% event threshold. Negative values "
    "indicate lower odds on the park-facing side (inside at the legal boundary). Bars show 95% "
    "model-based confidence intervals, using HC3 covariance for tree-cover loss and agriculture. "
    "Open circles show descriptive fire estimates from fits that did not meet the numerical criteria; "
    "their intervals are not interpreted. Connecting lines guide the eye; overlapping comparisons "
    "are not independent. Vertical scales differ among outcomes. Profile labels denote Upemba "
    "historical periods, not authority at outer locations. Table S19 reports agricultural "
    "spatial-bootstrap sensitivity, under which the park-centred legal-boundary interval includes zero. "
    "\n"
)
(OUT / "Figure_3_caption.txt").write_text(caption, encoding="utf-8")
validation = {
    "analytical_base_commit": "600a149eec6886aa1fec7ff47e716bc5869e27c5",
    "n_estimates": len(records), "n_legal_estimates": 9, "n_outer_estimates": 90,
    "n_displayed_intervals": sum(r["show_interval"] for r in records),
    "n_descriptive_points": sum(not r["show_interval"] for r in records),
    "main_estimates_intervals_and_outer_ranges_match_table_s17": checks,
    "source_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths},
    "analysis_changes": "None. Exact CSV estimates retained. No models fitted. Main 25% threshold, weighted rare-outcome models, legal and ten outer boundaries retained.",
    "uncertainty": "Preserves the existing model-based intervals. Agricultural spatial-bootstrap sensitivity remains in Table S19; it is not substituted into this spatial diagnostic.",
    "dimensions_mm": [180, 159], "png_dpi": 400, "tiff_dpi": 1000,
    "minimum_font_size_pt": 7.5,
    "font_family": "Times New Roman",
    "resolved_font_files": {k: Path(v).name for k, v in resolved_fonts.items()},
    "high_resolution_png_dpi": 1000,
    "all_data_and_displayed_intervals_within_axes": True,
    "all_visible_text_within_canvas": True,
}
(OUT / "Figure_3_validation.json").write_text(json.dumps(validation, indent=2), encoding="utf-8")
print(json.dumps({"output_directory": str(OUT), "n_estimates": len(records),
                  "n_intervals": validation["n_displayed_intervals"], "table_s17": "PASS"}))
