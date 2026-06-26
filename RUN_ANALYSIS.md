# Run Analysis

This candidate depends on nonredistributable external inputs and is not yet a one-command clean-machine reproduction.

One-time acquisition and preprocessing: scripts/acquisition/00_acquire_remote_sensing_gee.txt, scripts/preprocessing/01_preprocess_fire_agriculture_sources.R, scripts/preprocessing/02_construct_landscape_groups.R, and scripts/preprocessing/03_prepare_cell_year_data.R.

Required final analysis from prepared inputs: scripts/preprocessing/04_harmonize_fire_2021_2022.R, scripts/analysis/01_fit_governance_profile_models.R, scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R, and scripts/analysis/03_refine_fire_10km_optimizer.R.

Final robustness analyses: scripts/sensitivity/01_run_spatial_threshold_sensitivity.R, scripts/sensitivity/02_audit_measurement_harmonization.R, and scripts/sensitivity/03_run_revised_boundary_falsification.R.

The source-preparation script preserves historical logic but is not authoritative for final 2021-2022 fire reconstruction. The sparse-outcome script is required for final tree-cover-loss and agriculture estimates. No further model search is part of the workflow. Manual GEE exports remain necessary unless future automation replaces them.
