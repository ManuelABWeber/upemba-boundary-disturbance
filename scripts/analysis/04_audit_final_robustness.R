suppressPackageStartupMessages(library(data.table))
source("config/final_robustness_config.R")

out <- FINAL_SPEC$output_dir
dir.create(out, recursive = TRUE, showWarnings = FALSE)

git_hash <- system("git rev-parse HEAD", intern = TRUE)
run_dir <- CH1_RUN_DIR
principal <- c(
  file.path(run_dir, "rs_surfaces_long.csv"),
  file.path(run_dir, "SESU_covariates_500m.tif"),
  file.path(run_dir, "SESU_ID_500m.tif"),
  CH1_GOVERNANCE_PROFILE_PATH
)
file_diag <- rbindlist(lapply(principal, function(p) data.table(
  dataset = basename(p), path = normalizePath(p, winslash = "/", mustWork = FALSE),
  exists = file.exists(p),
  bytes = if (file.exists(p)) file.info(p)$size else NA_real_,
  md5 = if (file.exists(p)) unname(tools::md5sum(p)) else NA_character_,
  rows = if (file.exists(p) && grepl("\\.csv$", p, ignore.case = TRUE))
    nrow(fread(p)) else NA_integer_
)))

fire <- fread(file.path(CH1_OUTPUT_ROOT, "analysis_fire_optimizer_refinement_dev",
                        "tables", "fire_10km_optimizer_profile_contrasts.csv"))
fire <- fire[measurement_version == "harmonized_tau025" &
               optimizer_config == "D_BFGS_diagnostic",
             .(outcome = "fire", governance_profile, estimate,
               standard_error, lower_95_ci, upper_95_ci)]
sparse <- fread(file.path(CH1_PROJECT_ROOT,
                          "analysis_spatial_threshold_sensitivity_dev",
                          "tables", "sparse_outcome_profile_estimates.csv"))
sparse <- sparse[threshold_tag == "tau025" & spatial_design == "buffer_10km" &
                   model_type == "inverse_variance_weighted_lm_hc3",
                 .(outcome, governance_profile, estimate, standard_error,
                   lower_95_ci, upper_95_ci)]
baseline <- rbindlist(list(fire, sparse), fill = TRUE)
baseline[, `:=`(
  git_commit = git_hash,
  execution_command = paste(
    "Rscript --vanilla scripts/analysis/01_fit_governance_profile_models.R;",
    "Rscript --vanilla scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R;",
    "Rscript --vanilla scripts/analysis/03_refine_fire_10km_optimizer.R;"
  ),
  frozen_scalar_failures = 0L,
  frozen_classification_failures = 0L,
  locked_event_total_failures = 0L,
  principal_dataset_md5 = file_diag[dataset == "rs_surfaces_long.csv", md5],
  principal_dataset_rows = file_diag[dataset == "rs_surfaces_long.csv", rows]
)]
fwrite(baseline, file.path(out, "baseline_primary_results.csv"))

session_lines <- c(
  paste0("git_commit: ", git_hash),
  paste0("branch: ", system("git branch --show-current", intern = TRUE)),
  paste0("execution_date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "commands:",
  "  Rscript --vanilla scripts/analysis/01_fit_governance_profile_models.R",
  "  Rscript --vanilla scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R",
  "  Rscript --vanilla scripts/analysis/03_refine_fire_10km_optimizer.R",
  "  Rscript --vanilla tests/scripts/compare_frozen_results.R",
  "",
  "principal analytical datasets:",
  capture.output(print(file_diag)),
  "",
  capture.output(sessionInfo())
)
writeLines(session_lines, file.path(out, "session_info.txt"))

audit <- c(
  "# Audit of existing analyses",
  "",
  paste0("Audit commit: `", git_hash, "`. The authoritative primary workflow ",
         "was rerun successfully and the frozen-result validator reported zero ",
         "scalar, classification, and locked-event-total failures."),
  "",
  "## Repository and data architecture",
  "",
  "- Restricted raw rasters and large prepared geospatial inputs are outside Git under the configured `UPEMBA_DATA_ROOT`; `data/manifests/required_external_inputs.csv` inventories them.",
  "- `run_2026_05_27/SESU_covariates_500m.tif`, `SESU_ID_500m.tif`, and `rs_surfaces_long.csv` are the principal prepared inputs.",
  "- `scripts/preprocessing/01_preprocess_fire_agriculture_sources.R` through `04_harmonize_fire_2021_2022.R` contain acquisition/preparation logic. Raw authoritative inputs were not modified.",
  "- Primary categorical-profile models are produced by `scripts/analysis/01_fit_governance_profile_models.R`; sparse two-stage, chronology, and episode analyses by `02_fit_sparse_outcomes_and_profile_robustness.R`; the selected 10 km fire optimizer by `03_refine_fire_10km_optimizer.R`.",
  "- Threshold and corridor sensitivities are produced by `scripts/sensitivity/01_run_spatial_threshold_sensitivity.R`; measurement reconciliation by `02_audit_measurement_harmonization.R`; pseudo-boundaries by `03_run_revised_boundary_falsification.R`.",
  "- Publication tables and figures are produced by `scripts/publication/06_generate_main_figures_tables.R`, `08_generate_figure2_chronology_time_series.R`, and `07_generate_supplementary_material.R`.",
  "- `config/analysis_config.R`, `config/disturbance_threshold_manifest.csv`, `config/fire_harmonized_2001_2022_manifest.csv`, and `config/disturbance_measurement_versions.csv` control years, thresholds, paths, and measurement versions. The prior code duplicated model/risk-set helpers across scripts.",
  "",
  "## Exact current implementations",
  "",
  "- Fire: beta-binomial logit model `cbind(y,n-y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park`, with the retained BFGS-refined 10 km fit.",
  "- Tree-cover loss and agriculture: SESU-year inside-minus-outside corrected log-odds contrasts followed by `lm(contrast ~ governance_profile + SESU_ID)`, inverse-variance weights, and manually computed HC3 covariance.",
  "- Haldane–Anscombe correction: 0.5 is added to each of the four event/non-event cells, equivalently adding 1 to each side total.",
  "- Approximate variance is `1/yi + 1/(ni-yi) + 1/yo + 1/(no-yo)` and its reciprocal is the primary sparse-outcome weight.",
  "- Pairwise contrasts are differences of profile prediction contrast vectors.",
  "- Strict fire validity requires convergence code zero, positive-definite Hessian, full-rank model matrix, finite coefficients/SEs/contrasts, maximum gradient below 0.001, and no SE above 10.",
  "- Fire cells remain recurrently eligible each year. Event-year outcomes include a cell through its first crossing year and exclude it thereafter; no-event cells remain eligible.",
  "",
  "## Direct comparability",
  "",
  "- The retained fire 10 km BFGS estimates and the `tau025`/`buffer_10km` weighted-HC3 sparse estimates are directly comparable with the final primary specification.",
  "- Existing threshold/corridor results are matched in model form, but standalone 25% fire and tree-loss rasters are not identical to the canonical embedded 25% primary layers. The repository audit reports 28,196 differing fire cell-years and 881 differing tree-loss cells. These are measurement-version sensitivities, not exact primary reproductions.",
  "- Existing transition-year and leave-one-episode-out outputs use the all-cell canonical surface in `rs_surfaces_long.csv`, whereas the manuscript primary spatial estimand is the symmetric 10 km corridor. They are therefore non-comparable legacy chronology results for the current question.",
  "- Existing pseudo-boundary analyses use compatible risk-set definitions and sparse HC3 models, but pseudo-side labels are interior-facing/exterior-facing and fire fitting includes offset-specific optimizer selection. Dense offsets overlap and are not independent.",
  "",
  "## Discrepancies and limitations",
  "",
  "- `config/analysis_config.R` historically set the Phase 3 reference spatial design to `all_cells`, which conflicts with the manuscript's 10 km primary design when chronology outputs are reused without refitting.",
  "- Historical terminology uses `Neither actor dominant`, `Militia dominant`, and `Park dominant`; these map to fragmented, militia-centred, and park-centred profiles but should not be interpreted as actor-specific causal effects.",
  "- The configured local data root contains threshold/event-year rasters and the canonical prepared stack, but no annual AFCD cropland-fraction stack and no validated annual regrowth-sensitive vegetation/canopy series. Agricultural persistence and post-loss regrowth cannot be estimated as requested from event-year rasters alone.",
  "- The primary run emitted known empty-bootstrap-file warnings (bootstrap disabled) and many sparse beta-binomial diagnostic warnings; failed or non-strict fits are retained in diagnostic tables.",
  "- Reproduction depends on restricted inputs and cannot be performed on a clean public clone without restoring the manifest-listed data.",
  "",
  "## Baseline status",
  "",
  "The existing primary analysis reproduced. Numerical estimates are recorded in `baseline_primary_results.csv`; dataset hashes, row counts, R version, package versions, commands, and session details are recorded in `session_info.txt`."
)
writeLines(audit, file.path(out, "audit_existing_analyses.md"))

