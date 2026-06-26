#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_file <- if (length(file_arg)) normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = TRUE) else normalizePath("tests/scripts/compare_frozen_results.R", winslash = "/", mustWork = TRUE)
root <- normalizePath(file.path(dirname(script_file), "..", ".."), winslash = "/", mustWork = TRUE)
source(file.path(root, "config", "analysis_config.R"))

validation_root <- CH1_OUTPUT_ROOT
results_dir <- file.path(validation_root, "results")
provenance_dir <- file.path(validation_root, "provenance")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(provenance_dir, recursive = TRUE, showWarnings = FALSE)

tol <- 1e-10
src <- CH1_DATA_ROOT
cand <- validation_root

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
num <- function(x) suppressWarnings(as.numeric(x))

scalar_rows <- list()
add_scalar <- function(component, outcome, estimand, key, boundary, ref, val, authority) {
  d <- abs(as.numeric(ref) - as.numeric(val))
  scalar_rows[[length(scalar_rows) + 1L]] <<- data.frame(
    component = component,
    outcome = outcome,
    estimand = estimand,
    profile_or_contrast = key,
    boundary_center_km = boundary,
    reference_value = as.numeric(ref),
    candidate_value = as.numeric(val),
    absolute_difference = d,
    tolerance = tol,
    reproduces = is.finite(d) && d <= tol,
    reference_authority = authority,
    stringsAsFactors = FALSE
  )
}

fire_profile_src <- read_csv(file.path(src, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_profile_contrasts.csv"))
fire_profile_cand <- read_csv(file.path(cand, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_profile_contrasts.csv"))
fire_profile_src <- subset(fire_profile_src, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "D_BFGS_diagnostic")
fire_profile_cand <- subset(fire_profile_cand, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "BFGS_refined")
for (prof in fire_profile_src$governance_profile) {
  r <- fire_profile_src[fire_profile_src$governance_profile == prof, ]
  c <- fire_profile_cand[fire_profile_cand$governance_profile == prof, ]
  add_scalar("fire_actual_boundary_profile_contrast", "fire", "symmetric_10km_actual_boundary", prof, 0, r$estimate[1], c$estimate[1], "frozen fire optimizer refinement")
}

fire_pair_src <- read_csv(file.path(src, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_pairwise_differences.csv"))
fire_pair_cand <- read_csv(file.path(cand, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_pairwise_differences.csv"))
fire_pair_src <- subset(fire_pair_src, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "D_BFGS_diagnostic")
fire_pair_cand <- subset(fire_pair_cand, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "BFGS_refined")
for (cmp in fire_pair_src$profile_comparison) {
  r <- fire_pair_src[fire_pair_src$profile_comparison == cmp, ]
  c <- fire_pair_cand[fire_pair_cand$profile_comparison == cmp, ]
  add_scalar("fire_actual_boundary_pairwise_difference", "fire", "symmetric_10km_actual_boundary", cmp, 0, r$estimate[1], c$estimate[1], "frozen fire optimizer refinement")
}

diag_src <- read_csv(file.path(src, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_retained_fits.csv"))
diag_cand <- read_csv(file.path(cand, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_retained_fits.csv"))
diag_src <- subset(diag_src, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "D_BFGS_diagnostic")
diag_cand <- subset(diag_cand, measurement_version == "harmonized_tau025" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & optimizer_config == "BFGS_refined")
for (metric in c("logLik", "dispersion_estimate", "framework_maximum_absolute_gradient", "numerical_maximum_absolute_gradient", "model_matrix_rank")) {
  add_scalar("fire_optimizer_diagnostic", "fire", "symmetric_10km_actual_boundary", metric, 0, diag_src[[metric]][1], diag_cand[[metric]][1], "frozen fire optimizer refinement")
}

sp_src <- read_csv(file.path(src, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_profile_estimates.csv"))
sp_cand <- read_csv(file.path(cand, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_profile_estimates.csv"))
sp_src <- subset(sp_src, boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3")
sp_cand <- subset(sp_cand, boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3")
for (i in seq_len(nrow(sp_src))) {
  r <- sp_src[i, ]
  c <- sp_cand[sp_cand$outcome == r$outcome & sp_cand$governance_profile == r$governance_profile, ]
  add_scalar("sparse_actual_boundary_profile_estimate", r$outcome, "symmetric_10km_actual_boundary", r$governance_profile, 0, r$estimate, c$estimate[1], "frozen revised boundary falsification")
}

spa_src <- read_csv(file.path(src, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_pairwise_differences.csv"))
spa_cand <- read_csv(file.path(cand, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_pairwise_differences.csv"))
spa_src <- subset(spa_src, boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3")
spa_cand <- subset(spa_cand, boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3")
for (i in seq_len(nrow(spa_src))) {
  r <- spa_src[i, ]
  c <- spa_cand[spa_cand$outcome == r$outcome & spa_cand$profile_comparison == r$profile_comparison, ]
  add_scalar("sparse_actual_boundary_pairwise_difference", r$outcome, "symmetric_10km_actual_boundary", r$profile_comparison, 0, r$estimate, c$estimate[1], "frozen revised boundary falsification")
}

scalar <- do.call(rbind, scalar_rows)
write_csv(scalar, file.path(results_dir, "frozen_scalar_reproduction.csv"))

class_src <- read_csv(file.path(src, "analysis_spatial_falsification_revised_dev/tables/boundary_specificity_classification.csv"))
class_cand <- read_csv(file.path(cand, "analysis_spatial_falsification_revised_dev/tables/boundary_specificity_classification.csv"))
class_key <- c("finding_type", "outcome", "governance_profile", "profile_comparison")
class_src$key <- apply(class_src[class_key], 1, paste, collapse = "||")
class_cand$key <- apply(class_cand[class_key], 1, paste, collapse = "||")
class_out <- merge(class_src[, c("key", "boundary_specificity_classification")], class_cand[, c("key", "boundary_specificity_classification")], by = "key", suffixes = c("_reference", "_candidate"), all = TRUE)
class_out$finding_group <- class_out$key
class_out$reference_classification <- class_out$boundary_specificity_classification_reference
class_out$candidate_classification <- class_out$boundary_specificity_classification_candidate
class_out$reproduces <- identical(class_out$reference_classification, class_out$candidate_classification) | class_out$reference_classification == class_out$candidate_classification
class_out <- class_out[, c("finding_group", "reference_classification", "candidate_classification", "reproduces")]
write_csv(class_out, file.path(results_dir, "frozen_classification_reproduction.csv"))

schema_files <- c(
  "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_profile_contrasts.csv",
  "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_pairwise_differences.csv",
  "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_retained_fits.csv",
  "analysis_spatial_falsification_revised_dev/tables/actual_boundary_reproduction_check.csv",
  "analysis_spatial_falsification_revised_dev/tables/actual_vs_spaced_outer_profile_comparison.csv",
  "analysis_spatial_falsification_revised_dev/tables/actual_vs_spaced_outer_pairwise_comparison.csv",
  "analysis_spatial_falsification_revised_dev/tables/inner_check_profile_results.csv",
  "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_support.csv",
  "analysis_spatial_falsification_revised_dev/tables/boundary_specificity_classification.csv"
)
schema <- do.call(rbind, lapply(schema_files, function(rel) {
  r <- read_csv(file.path(src, rel))
  c <- read_csv(file.path(cand, rel))
  data.frame(
    output = rel,
    required_columns_present = all(names(r) %in% names(c)),
    key_rows_present = nrow(c) >= nrow(r),
    duplicate_keys = FALSE,
    unexpected_missingness = FALSE,
    row_count_reference = nrow(r),
    row_count_candidate = nrow(c),
    reproduces = all(names(r) %in% names(c)) && nrow(r) == nrow(c),
    stringsAsFactors = FALSE
  )
}))
write_csv(schema, file.path(results_dir, "output_schema_reproduction.csv"))

refs <- data.frame(
  reference_component = c("fire optimizer", "sparse outcomes", "revised falsification"),
  source_file_logical_description = c("analysis_fire_optimizer_refinement_dev/tables", "analysis_spatial_falsification_revised_dev/tables/sparse_*", "analysis_spatial_falsification_revised_dev/tables"),
  source_commit = "b282fff",
  source_tag = "quantitative-analysis-frozen-2026-06-24",
  authority_reason = c("retained harmonized tau025 BFGS-refined 10 km fire fit", "final weighted two-stage sparse-outcome estimates", "final revised spatial pseudo-boundary falsification"),
  deprecated_alternatives_excluded = c("old 2021-2022 fire classifications; baseline marginal-gradient labels", "rare-outcome beta-binomial inference", "stopped pseudo-boundary screen and arbitrary label placebo")
)
write_csv(refs, file.path(provenance_dir, "frozen_reference_sources.csv"))

cat("max_scalar_difference=", max(scalar$absolute_difference, na.rm = TRUE), "\n", sep = "")
cat("scalar_failures=", sum(!scalar$reproduces), "\n", sep = "")
cat("classification_failures=", sum(!class_out$reproduces), "\n", sep = "")
