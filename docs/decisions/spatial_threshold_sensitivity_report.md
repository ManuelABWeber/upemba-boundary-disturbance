# Spatial and Threshold Sensitivity Report

Phase 3 tested threshold products for `tau010`, `tau025`, and `tau050` and symmetric boundary samples at 5, 10, and 20 km against the existing all-cell estimand. The previous asymmetric closest-border design was not used.

## Phase 4 Superseding Note

The measurement-harmonization phase on 2026-06-24 shows that the Phase 3 threshold grid mixed two measurement-version questions: canonical embedded tau025 versus standalone threshold products, and threshold changes within the standalone pipeline. `scripts/08_measurement_harmonization.R` keeps these questions separate. The harmonized standalone series is sensitivity-only pending recovery of exact GEE export provenance.

## Tau025 Resolution

The final tau025 reference analysis uses the exact canonical embedded layers in `run_2026_05_27/SESU_covariates_500m.tif`: `fireDOY_2001` through `fireDOY_2022`, `year_deforest_masked`, and `year_agri`. With those inputs, tau025 all-cell summaries reproduce exactly for fire, tree-cover loss, and agriculture.

The standalone tau025 products remain inventoried as threshold products, but they are not identical to the canonical embedded run stack for fire and tree-cover loss. The audit found 28,196 differing fire cell-years, 0.627% of compared fire cell-years, and 881 differing tree-cover-loss cells, 0.431% of compared cells. Agriculture was identical. The standalone tau025 fire product has 28,196 more fire events than the canonical embedded fireDOY layers; the standalone tau025 tree-cover-loss product has 735 fewer event cells than the canonical embedded `year_deforest_masked` layer.

## Covariate Comparability

Symmetric buffers improved pooled inside-outside covariate comparability relative to all cells:

- all cells: median abs SMD 0.429, maximum 1.704.
- 5 km buffer: median abs SMD 0.119, maximum 0.371.
- 10 km buffer: median abs SMD 0.187, maximum 0.733.
- 20 km buffer: median abs SMD 0.299, maximum 1.254.

The 5 km buffer gives the strongest covariate comparability but loses the most event support. The 10 km buffer is the clearest compromise between locality, support, and balance. The 20 km buffer retains more support but approaches the all-cell imbalance pattern.

## Event Support

Tau010 substantially improves rare-event support. For all cells, tree-cover-loss events increase from 5,460 at tau025 to 20,490 at tau010; agriculture events increase from 2,685 to 6,405. Tau050 produces severe sparsity, especially in boundary buffers: tree-cover loss has only 64 events in the 5 km buffer and 120 in the 20 km buffer; agriculture has 180 events in the 5 km buffer and 236 in the 20 km buffer.

Fire remains well supported across all thresholds and designs, with 2.20 million to 2.71 million all-cell events depending on threshold.

## Model Diagnostics

Fire beta-binomial models are strict-valid for all-cell tau010, all-cell tau025, and 10 km tau025. Other boundary-buffer fire models generally have positive-definite Hessians but fail the configured gradient threshold. Fire conclusions are most stable for the Neither actor dominant contrast; Militia and Park contrasts are small and can cross zero across thresholds or buffers.

Tree-cover-loss rare-outcome beta-binomial diagnostics became strict-valid only at tau010 for all cells, 10 km, and 20 km. These fits are diagnostic; the primary sparse-outcome analysis remains the SESU-year contrast model.

Agriculture rare-outcome beta-binomial models did not become strict-valid in any threshold or spatial design. Agriculture should remain sensitivity-only for beta-binomial inference.

## Directional Stability

Tree-cover-loss directions are strongest for the Militia dominant contrast, which remains negative across the grid. Neither actor dominant and Park dominant tree-cover-loss estimates are more sensitive to threshold and buffer, with some sign changes in the two-stage estimates.

Park-profile agriculture is not stable across the full grid: the tau025 all-cell weighted estimate is negative, but threshold and buffer choices can change direction. Agriculture remains support-sensitive and should not be treated as settled.

## Decision Implications

The 10 km symmetric boundary design provides the best current tradeoff between the territorial-control estimand, improved covariate comparability, and event support. It should be considered the leading boundary-local sensitivity design, not automatically a replacement for all cells.

Tau025 should remain the primary threshold conditionally because the final reference analysis reproduces the canonical tau025 all-cell summaries exactly. The Phase 4 measurement audit recommends retaining canonical embedded tau025 as primary and reporting the harmonized standalone threshold series as sensitivity unless researcher-supplied GEE provenance establishes that the standalone implementation better matches the intended measurement definition. Tau010 is a useful rare-event sensitivity because it improves support. Tau050 is a sparsity stress test and should not be promoted on model-performance grounds.

Results ready for manuscript use: descriptive support comparisons, covariate-balance comparisons, exact tau025 reproduction audit, and fire all-cell tau025/tau010 beta-binomial sensitivity with strict-valid caveats.

Sensitivity-only results: tree-cover-loss and agriculture SESU-year two-stage estimates, rare-outcome beta-binomial diagnostics, and all boundary-buffer model comparisons until the spatial estimand is selected.

Do not interpret fire directly as poaching. Measured disturbance patterns, plausible mechanisms, and normative interpretation remain separate.
