# Measurement Harmonization Validation

Generated in the measurement-harmonization phase on 2026-06-24.

## Repository State

- Starting commit: `def9462 Add spatial and threshold sensitivity analyses`.
- Phase 3 completion tag: `post-spatial-threshold-phase3-2026-06-24`.
- Workflow script: `scripts/08_measurement_harmonization.R`.
- Measurement manifest: `config/disturbance_measurement_versions.csv`.
- Output directory: `analysis_measurement_harmonization_dev/`.

## Workflow Checks

All validation checks passed:

- Canonical embedded tau025 exact reproduction.
- Tree-cover-loss forest mask identical across standalone thresholds.
- All model inputs match the canonical template grid.
- Agriculture tau025 identical after event-year coding.
- Agriculture paths do not resolve to tree-cover-loss rasters.
- Threshold tags are not silently recycled.

Machine-readable validation is in `analysis_measurement_harmonization_dev/tables/measurement_harmonization_validation_checks.csv`.

## Provenance Hashes

Input hashes were written to `analysis_measurement_harmonization_dev/provenance/measurement_input_hashes.csv`. Hashes include the canonical embedded run stack, SESU raster, threshold products, and the scripts inspected for measurement provenance.

## Reproduction

The canonical embedded tau025 analytical summaries reproduce exactly from:

- `run_2026_05_27/SESU_covariates_500m.tif`
- `run_2026_05_27/SESU_ID_500m.tif`
- `run_2026_05_27/rs_surfaces_long.csv`

The reproduction check contains 264 rows and all rows agree exactly.

## Event Support

All-cells event counts:

- Fire: canonical tau025 2,468,094; standalone tau010 2,709,012; standalone tau025 2,496,290; standalone tau050 2,201,052.
- Tree-cover loss: canonical tau025 5,460; standalone tau010 19,736; standalone tau025 5,460; standalone tau050 753.
- Agriculture: canonical tau025 2,685; standalone tau010 6,405; standalone tau025 2,685; standalone tau050 1,224.

Ten-kilometer buffer event counts:

- Fire: canonical tau025 502,560; standalone tau010 554,273; standalone tau025 508,332; standalone tau050 445,518.
- Tree-cover loss: canonical tau025 519; standalone tau010 1,978; standalone tau025 519; standalone tau050 79.
- Agriculture: canonical tau025 518; standalone tau010 882; standalone tau025 518; standalone tau050 227.

## Model Fits

Fire beta-binomial fits attempted: 8.

Strict-valid fire fits:

- `canonical_embedded_tau025`, all cells.
- `canonical_embedded_tau025`, 10 km buffer.
- `standalone_tau010`, all cells.
- `standalone_tau025`, all cells.

The 10 km standalone tau010 and tau025 fire fits converged with positive-definite Hessians but exceeded the strict gradient threshold. The standalone tau050 all-cell fit also exceeded the strict gradient threshold. The standalone tau050 10 km fit returned optimizer convergence code 1.

Tree-cover-loss and agriculture used the SESU-year two-stage contrast workflow as the primary sparse-outcome analysis. Rare-outcome beta-binomial inference was not promoted or rerun in this phase.

## Measurement Effects

Pipeline-version sensitivity at tau025 is small in the model-ready results:

- Fire all-cell tau025 shifts are near zero; Park dominant changes by -0.0067 log-odds units.
- Tree-cover-loss all-cell tau025 estimates are unchanged after harmonization in the study-period model-ready summaries.
- Agriculture tau025 estimates are unchanged because products are identical.

Within-pipeline threshold sensitivity is larger than pipeline-version sensitivity for several sparse-outcome estimates, especially agriculture and the Neither tree-cover-loss profile. Fire all-cell profile signs remain stable across standalone thresholds.

## Warnings And Limitations

- Exact canonical GEE script revision, export settings, and task history were not recovered locally.
- Fire 2021-2022 is the only source of the standalone tau025 fire discrepancy.
- Tree-cover-loss standalone thresholds are harmonized with the canonical forest mask, but this does not prove identical GFC export provenance.
- HC3 covariance is used for sparse-outcome two-stage models; CR2 clustered covariance was not used in this workflow.

## Output Files

Primary outputs:

- `analysis_measurement_harmonization_dev/tables/fire_pipeline_comparison.csv`
- `analysis_measurement_harmonization_dev/tables/tree_cover_loss_pipeline_comparison.csv`
- `analysis_measurement_harmonization_dev/tables/agriculture_pipeline_comparison.csv`
- `analysis_measurement_harmonization_dev/tables/measurement_algorithm_decision_matrix.csv`
- `analysis_measurement_harmonization_dev/tables/pipeline_version_profile_contrasts.csv`
- `analysis_measurement_harmonization_dev/tables/pipeline_version_pairwise_differences.csv`
- `analysis_measurement_harmonization_dev/tables/harmonized_threshold_profile_contrasts.csv`
- `analysis_measurement_harmonization_dev/tables/harmonized_threshold_pairwise_differences.csv`
- `analysis_measurement_harmonization_dev/tables/measurement_effect_summary.csv`

## Unresolved Scientific Decision

The previous recommendation to retain canonical embedded tau025 as primary is superseded for fire by the 2021-2022 rebuild in `scripts/09_fire_2021_2022_harmonization.R`. The harmonized 2001-2022 fire series is now the recommended primary fire measurement candidate, with canonical embedded fire retained as pipeline-version sensitivity. For tree-cover loss, the primary measurement decision remains conditional on recovered GFC export provenance or researcher review. Agriculture remains unchanged because canonical and standalone tau025 are identical.
