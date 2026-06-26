# Spatial Threshold Phase 3 Validation

## Scope

- Branch: `publication-revision/spatial-threshold-sensitivity`.
- Starting commit: `a12172a Diagnose governance-profile models and add historical sensitivities`.
- Starting tag: `post-profile-robustness-2026-06-23`.
- Input manifest: `config/disturbance_threshold_manifest.csv`.
- Output directory: `analysis_spatial_threshold_sensitivity_dev`.

## Raster Compatibility

All manifest rasters exist and match the canonical 500 m grid in resolution, extent, origin, row count, and column count. CRS labels were normalized because the manifest uses `EPSG:32735` while `terra` reports code `32735`.

Annual fire band coverage is complete for 2001-2020 stacks and 2021-2022 annual binary rasters. Event-year products contain valid study years or no-event values. No threshold products were flagged as byte-identical within the same outcome/file type.

## Tau025 Reproduction

Final tau025 reference analyses use the exact canonical embedded layers in `run_2026_05_27/SESU_covariates_500m.tif`.

Tau025 all-cell reproduction status:

- Agriculture: exact agreement for 88/88 rows.
- Fire: exact agreement for 88/88 rows.
- Tree-cover loss: exact agreement for 88/88 rows.

The reproduction audit also compares the canonical embedded tau025 objects with the standalone tau025 threshold products. Fire differs in 28,196 cell-years, tree-cover loss differs in 881 cells, and agriculture is identical. Machine-readable details are in `tau025_input_comparison.csv`, `tau025_cell_value_discrepancies_summary.csv`, and `tau025_allcell_reproduction_check.csv`.

## Sample Sizes and Balance

Pooled inside/outside cell counts and median absolute standardized mean differences:

- all cells: 37,963 inside; 166,448 outside; median abs SMD 0.429.
- 5 km: 11,187 inside; 11,418 outside; median abs SMD 0.119.
- 10 km: 20,548 inside; 22,006 outside; median abs SMD 0.187.
- 20 km: 33,130 inside; 42,022 outside; median abs SMD 0.299.

## Event Counts

All-cell event counts by threshold:

- Fire: tau010 2,709,012; tau025 2,468,094; tau050 2,201,052.
- Tree-cover loss: tau010 20,490; tau025 5,460; tau050 753.
- Agriculture: tau010 6,405; tau025 2,685; tau050 1,224.

Event support declines sharply in the 5 km buffer, especially for tau050 rare outcomes.

## Model Fits

Fire beta-binomial fits attempted: 12. Strict-valid fits: all-cells tau010, all-cells tau025, and 10 km tau025.

Rare-outcome beta-binomial diagnostics attempted: 24. Strict-valid tree-cover-loss fits occurred for tau010 all-cells, tau010 10 km, and tau010 20 km. No agriculture rare-outcome beta-binomial fit was strict-valid.

Sparse-outcome SESU-year two-stage models ran for every tree-cover-loss and agriculture threshold/design combination using HC3 covariance.

## Warnings

The complete workflow produced `sqrt(diag(vcovs))` and contrast-variance warnings for problematic beta-binomial fits. These warnings are retained in fit diagnostics and are the reason rare-outcome beta-binomial intervals are not treated as primary evidence unless strict-valid.

## Output Files

Main tables are under `analysis_spatial_threshold_sensitivity_dev/tables/`. Diagnostic figures were generated under `analysis_spatial_threshold_sensitivity_dev/figures/` but are not intended for version control.

## Unresolved Scientific Decisions

- Whether all-cells or a boundary-local design should be primary.
- Whether 10 km is the preferred boundary-local compromise.
- Whether standalone tau025 threshold products should be treated as revised tau025 products in a later measurement-validity phase.
- Spatially coherent placebo redesign remains excluded.
