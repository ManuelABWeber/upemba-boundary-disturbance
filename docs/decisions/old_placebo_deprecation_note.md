# Old Placebo Deprecation Note

Generated for the spatial pseudo-boundary falsification phase on 2026-06-24.

## What The Old Placebo Did

The legacy placebo construction is implemented in `scripts/Script 3_RS data preparation.R` in `append_placebo_np()`. It randomly reassigned inside/outside side labels to cells within each SESU while preserving the observed number of inside cells. The generated label was `National Park placebo (random side)`, with intended replicate labels such as `placebo_r001`.

Historical run directories contain generated placebo model objects, tables, and figures under names such as `PRIMARY_betaBinomial_*__National_Park_placebo__random_side____true.rds` and `RS_ONLY_*__National_Park_placebo__random_side____true.csv`.

## Why It Is Deprecated

The old procedure is spatially incoherent for the current boundary-specific question. It assigns cell labels arbitrarily rather than creating a contiguous pseudo-boundary or preserving spatial autocorrelation, neighborhood structure, distance gradients, and the geometry of the actual protected-area boundary.

Arbitrary cell-label permutations violate the spatial structure of the data because nearby pixels are not exchangeable independent units. The disturbance outcomes, covariates, and SESU assignments are spatially organized; permuting labels within SESUs destroys that structure while preserving only coarse cell counts.

The old implementation also lost replicate identity before final model-ready output: `compute_surface_summary_simple()` aggregated by `SESU_ID`, `year`, `pa_label`, and `side`, but not by `pa_label_rep`. Current documentation therefore treats the old placebo outputs as invalid for manuscript evidence.

## Current Status

The old placebo is retained only for audit and provenance. It must not be used as evidence for boundary-location specificity, causal identification, or robustness of the governance-profile results.

The replacement design is a spatial pseudo-boundary falsification analysis using offset iso-distance corridors. These pseudo-boundaries are deterministic spatial contrasts, not randomized placebo assignments, and their ranks are descriptive rather than formal permutation p-values.

## Audit Files Retained

- `scripts/Script 3_RS data preparation.R`
- `docs/placebo_implementation_audit.md`
- Generated placebo references recorded in `docs/directory_tree.txt`
- Generated legacy run outputs in `run_2026_02_10/`, `run_2026_04_07/`, `run_2026_04_20/`, and `run_2026_05_27/`
- Backup copies under `backup/`

No historical files were deleted in this phase.
