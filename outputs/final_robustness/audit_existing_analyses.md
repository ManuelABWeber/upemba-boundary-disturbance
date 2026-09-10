# Audit of existing analyses

Audit commit: `43e09c19323d23af085aacc87203ea5b799c83fe`. The authoritative primary workflow was rerun successfully and the frozen-result validator reported zero scalar, classification, and locked-event-total failures.

## Repository and data architecture

- Restricted raw rasters and large prepared geospatial inputs are outside Git under the configured `UPEMBA_DATA_ROOT`; `data/manifests/required_external_inputs.csv` inventories them.
- `run_2026_05_27/SESU_covariates_500m.tif`, `SESU_ID_500m.tif`, and `rs_surfaces_long.csv` are the principal prepared inputs.
- `scripts/preprocessing/01_preprocess_fire_agriculture_sources.R` through `04_harmonize_fire_2021_2022.R` contain acquisition/preparation logic. Raw authoritative inputs were not modified.
- Primary categorical-profile models are produced by `scripts/analysis/01_fit_governance_profile_models.R`; sparse two-stage, chronology, and episode analyses by `02_fit_sparse_outcomes_and_profile_robustness.R`; the selected 10 km fire optimizer by `03_refine_fire_10km_optimizer.R`.
- Threshold and corridor sensitivities are produced by `scripts/sensitivity/01_run_spatial_threshold_sensitivity.R`; measurement reconciliation by `02_audit_measurement_harmonization.R`; pseudo-boundaries by `03_run_revised_boundary_falsification.R`.
- Publication tables and figures are produced by `scripts/publication/06_generate_main_figures_tables.R`, `08_generate_figure2_chronology_time_series.R`, and `07_generate_supplementary_material.R`.
- `config/analysis_config.R`, `config/disturbance_threshold_manifest.csv`, `config/fire_harmonized_2001_2022_manifest.csv`, and `config/disturbance_measurement_versions.csv` control years, thresholds, paths, and measurement versions. The prior code duplicated model/risk-set helpers across scripts.

## Exact current implementations

- Fire: beta-binomial logit model `cbind(y,n-y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park`, with the retained BFGS-refined 10 km fit.
- Tree-cover loss and agriculture: SESU-year inside-minus-outside corrected log-odds contrasts followed by `lm(contrast ~ governance_profile + SESU_ID)`, inverse-variance weights, and manually computed HC3 covariance.
- Haldane–Anscombe correction: 0.5 is added to each of the four event/non-event cells, equivalently adding 1 to each side total.
- Approximate variance is `1/yi + 1/(ni-yi) + 1/yo + 1/(no-yo)` and its reciprocal is the primary sparse-outcome weight.
- Pairwise contrasts are differences of profile prediction contrast vectors.
- Strict fire validity requires convergence code zero, positive-definite Hessian, full-rank model matrix, finite coefficients/SEs/contrasts, maximum gradient below 0.001, and no SE above 10.
- Fire cells remain recurrently eligible each year. Event-year outcomes include a cell through its first crossing year and exclude it thereafter; no-event cells remain eligible.

## Direct comparability

- The retained fire 10 km BFGS estimates and the `tau025`/`buffer_10km` weighted-HC3 sparse estimates are directly comparable with the final primary specification.
- Existing threshold/corridor results are matched in model form, but standalone 25% fire and tree-loss rasters are not identical to the canonical embedded 25% primary layers. The repository audit reports 28,196 differing fire cell-years and 881 differing tree-loss cells. These are measurement-version sensitivities, not exact primary reproductions.
- Existing transition-year and leave-one-episode-out outputs use the all-cell canonical surface in `rs_surfaces_long.csv`, whereas the manuscript primary spatial estimand is the symmetric 10 km corridor. They are therefore non-comparable legacy chronology results for the current question.
- Existing pseudo-boundary analyses use compatible risk-set definitions and sparse HC3 models, but pseudo-side labels are interior-facing/exterior-facing and fire fitting includes offset-specific optimizer selection. Dense offsets overlap and are not independent.

## Discrepancies and limitations

- `config/analysis_config.R` historically set the Phase 3 reference spatial design to `all_cells`, which conflicts with the manuscript's 10 km primary design when chronology outputs are reused without refitting.
- Historical terminology uses `Neither actor dominant`, `Militia dominant`, and `Park dominant`; these map to fragmented, militia-centred, and park-centred profiles but should not be interpreted as actor-specific causal effects.
- The initial audit lacked annual cropland fractions. This was superseded by script 09, which reconstructs the retained AFCD annual stack and validates canonical first crossings. See docs/submission/ch1-analysis-handover.md for the reproduced persistence fit and its unresolved follow-up limitation. No validated annual regrowth-sensitive canopy series was located; event-year rasters alone cannot identify recovery.
- The primary run emitted known empty-bootstrap-file warnings (bootstrap disabled) and many sparse beta-binomial diagnostic warnings; failed or non-strict fits are retained in diagnostic tables.
- Reproduction depends on restricted inputs and cannot be performed on a clean public clone without restoring the manifest-listed data.

## Baseline status

The existing primary analysis reproduced. Numerical estimates are recorded in `baseline_primary_results.csv`; dataset hashes, row counts, R version, package versions, commands, and session details are recorded in `session_info.txt`.
