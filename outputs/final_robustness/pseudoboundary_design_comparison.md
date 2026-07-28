# Pseudo-boundary design comparison

The implementation was confirmed directly: cells satisfy `abs(signed_distance_km - centre) <= 10`; signed distances below the centre are park-facing and distances at or above the centre are outward-facing.

- At +5 km the park-facing band is [-5, 5) km and crosses the legal boundary; it mixes inside-park and outside-park cells and is excluded from candidate reporting designs.
- At +10 km the park-facing band is [0, 10) km and the outward band is [10, 20] km. Both are outside under the authoritative signed-distance coding, and the park-facing band touches the legal boundary.
- At +15 km the park-facing band is [5, 15) km and avoids both boundary crossing and immediate 0-5 km adjacency.
- Dense 5 km offsets share cells. Pairwise Jaccard overlap is reported in `pseudoboundary_pairwise_overlap.csv`; the offsets are not independent.

## Reporting recommendation

Retain +15 to +60 km in 5 km increments as the complete descriptive sensitivity. Use +15, +25, +35, +45, and +55 km as the parsimonious primary subset because it avoids boundary crossing, avoids immediate adjacency, and spreads coverage without outcome-based selection. Report +10 km only as a boundary-adjacent sensitivity. Exclude +5 km for the 10 km-per-side design. The historical +20/+40/+60 km set may remain for continuity.

Ranks, event support, balance, fit validity, and profile-level classifications are machine-readable in the accompanying CSV files. Agriculture remains inferentially support-sensitive; ranks are descriptive and are not used to select offsets.
