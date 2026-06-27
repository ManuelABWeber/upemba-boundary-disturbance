# Run Analysis

The upstream analytical workflow depends on nonredistributable external inputs and is not a one-command clean-machine reproduction. The publication-generation workflow is self-contained in this private repository because it consumes retained authoritative analytical tables and publication assets.

One-time acquisition and preprocessing: scripts/acquisition/00_acquire_remote_sensing_gee.txt, scripts/preprocessing/01_preprocess_fire_agriculture_sources.R, scripts/preprocessing/02_construct_landscape_groups.R, and scripts/preprocessing/03_prepare_cell_year_data.R.

Required final analysis from prepared inputs: scripts/preprocessing/04_harmonize_fire_2021_2022.R, scripts/analysis/01_fit_governance_profile_models.R, scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R, and scripts/analysis/03_refine_fire_10km_optimizer.R.

Final robustness analyses: scripts/sensitivity/01_run_spatial_threshold_sensitivity.R, scripts/sensitivity/02_audit_measurement_harmonization.R, and scripts/sensitivity/03_run_revised_boundary_falsification.R.

The source-preparation script preserves historical logic but is not authoritative for final 2021-2022 fire reconstruction. The sparse-outcome script is required for final tree-cover-loss and agriculture estimates. No further model search is part of the workflow. Manual GEE exports remain necessary unless future automation replaces them.

## Publication workflow

Run these scripts from the repository root in this order:

1. `Rscript --vanilla scripts/publication/06_generate_main_figures_tables.R`
2. `Rscript --vanilla scripts/publication/08_generate_figure2_chronology_time_series.R`
3. `Rscript --vanilla scripts/publication/07_generate_supplementary_material.R`

Script 06 regenerates the main tables, Figures 3-4, and the canonical Figure 2 source-data files:

- `outputs/publication/figure_source_data/Figure_2_annual_trajectories.csv`
- `outputs/publication/figure_source_data/Figure_2_profile_chronology.csv`

The approved Figure 1 is retained as a publication asset because its restricted geospatial source layers are documented but not redistributed. Script 08 validates the locked event totals and generates the final 600 dpi PNG and vector PDF for Figure 2. Script 07 regenerates supplementary outputs without overwriting the verified final supplementary DOCX.

Then run:

1. `Rscript --vanilla tests/scripts/compare_frozen_results.R`
2. `Rscript --vanilla tests/scripts/run_downstream_validation.R`

The `--vanilla` flag is intentional for publication-only clean-clone validation: it uses the installed package versions recorded in Table S18 without bootstrapping an empty project library. Use `renv::restore()` before the full upstream analytical workflow.
