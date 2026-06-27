#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_file <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("tests/scripts/compare_frozen_results.R", winslash = "/", mustWork = TRUE)
}
ROOT <- normalizePath(file.path(dirname(script_file), "..", ".."), winslash = "/", mustWork = TRUE)
OUT <- file.path(ROOT, "reports", "repository")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
num <- function(x) suppressWarnings(as.numeric(x))

reference <- read_csv(file.path(ROOT, "tests", "reference", "frozen_result_checks.csv"))

fire_profile <- read_csv(file.path(
  ROOT,
  "analysis_fire_optimizer_refinement_dev", "tables",
  "fire_10km_optimizer_profile_contrasts.csv"
))
fire_profile <- subset(
  fire_profile,
  measurement_version == "harmonized_tau025" &
    threshold_tag == "tau025" &
    spatial_design == "buffer_10km" &
    optimizer_config == "D_BFGS_diagnostic"
)
fire_profile <- data.frame(
  outcome = "fire",
  estimand = "profile",
  key = fire_profile$governance_profile,
  observed_estimate = num(fire_profile$estimate),
  observed_lower_95 = num(fire_profile$lower_95_ci),
  observed_upper_95 = num(fire_profile$upper_95_ci)
)

fire_pairwise <- read_csv(file.path(
  ROOT,
  "analysis_fire_optimizer_refinement_dev", "tables",
  "fire_10km_optimizer_pairwise_differences.csv"
))
fire_pairwise <- subset(
  fire_pairwise,
  measurement_version == "harmonized_tau025" &
    threshold_tag == "tau025" &
    spatial_design == "buffer_10km" &
    optimizer_config == "D_BFGS_diagnostic"
)
fire_pairwise <- data.frame(
  outcome = "fire",
  estimand = "pairwise",
  key = fire_pairwise$profile_comparison,
  observed_estimate = num(fire_pairwise$estimate),
  observed_lower_95 = num(fire_pairwise$lower_95_ci),
  observed_upper_95 = num(fire_pairwise$upper_95_ci)
)

sparse_profile <- read_csv(file.path(
  ROOT,
  "analysis_spatial_threshold_sensitivity_dev", "tables",
  "sparse_outcome_profile_estimates.csv"
))
sparse_profile <- subset(
  sparse_profile,
  threshold_tag == "tau025" &
    spatial_design == "buffer_10km" &
    model_type == "inverse_variance_weighted_lm_hc3"
)
sparse_profile <- data.frame(
  outcome = sparse_profile$outcome,
  estimand = "profile",
  key = sparse_profile$governance_profile,
  observed_estimate = num(sparse_profile$estimate),
  observed_lower_95 = num(sparse_profile$lower_95_ci),
  observed_upper_95 = num(sparse_profile$upper_95_ci)
)

sparse_pairwise <- read_csv(file.path(
  ROOT,
  "analysis_spatial_threshold_sensitivity_dev", "tables",
  "sparse_outcome_pairwise_differences.csv"
))
sparse_pairwise <- subset(
  sparse_pairwise,
  threshold_tag == "tau025" &
    spatial_design == "buffer_10km" &
    model_type == "inverse_variance_weighted_lm_hc3"
)
sparse_pairwise <- data.frame(
  outcome = sparse_pairwise$outcome,
  estimand = "pairwise",
  key = sparse_pairwise$profile_comparison,
  observed_estimate = num(sparse_pairwise$estimate),
  observed_lower_95 = num(sparse_pairwise$lower_95_ci),
  observed_upper_95 = num(sparse_pairwise$upper_95_ci)
)

diagnostics <- read_csv(file.path(
  ROOT,
  "analysis_fire_optimizer_refinement_dev", "tables",
  "fire_10km_optimizer_retained_fits.csv"
))
diagnostics <- subset(
  diagnostics,
  measurement_version == "harmonized_tau025" &
    threshold_tag == "tau025" &
    spatial_design == "buffer_10km" &
    optimizer_config == "D_BFGS_diagnostic"
)
diagnostic_keys <- reference$key[reference$estimand == "diagnostic"]
diagnostic_observed <- data.frame(
  outcome = "fire",
  estimand = "diagnostic",
  key = diagnostic_keys,
  observed_estimate = vapply(diagnostic_keys, function(key) num(diagnostics[[key]][1]), numeric(1)),
  observed_lower_95 = NA_real_,
  observed_upper_95 = NA_real_
)

observed <- rbind(
  fire_profile,
  fire_pairwise,
  sparse_profile,
  sparse_pairwise,
  diagnostic_observed
)
validation <- merge(
  reference,
  observed,
  by = c("outcome", "estimand", "key"),
  all.x = TRUE,
  sort = FALSE
)
validation$estimate_difference <- abs(num(validation$expected_estimate) - num(validation$observed_estimate))
validation$lower_difference <- abs(num(validation$expected_lower_95) - num(validation$observed_lower_95))
validation$upper_difference <- abs(num(validation$expected_upper_95) - num(validation$observed_upper_95))
interval_required <- validation$estimand != "diagnostic"
validation$pass <- is.finite(validation$estimate_difference) &
  validation$estimate_difference <= validation$tolerance &
  (!interval_required | (
    is.finite(validation$lower_difference) &
      is.finite(validation$upper_difference) &
      validation$lower_difference <= validation$tolerance &
      validation$upper_difference <= validation$tolerance
  ))
write.csv(validation, file.path(OUT, "frozen_result_validation.csv"), row.names = FALSE, na = "")

class_reference <- read_csv(file.path(
  ROOT,
  "tests", "reference", "frozen_classification_checks.csv"
))
class_observed <- read_csv(file.path(
  ROOT,
  "analysis_spatial_falsification_revised_dev", "tables",
  "boundary_specificity_classification.csv"
))
class_observed$key <- ifelse(
  class_observed$finding_type == "profile-specific contrasts",
  class_observed$governance_profile,
  class_observed$profile_comparison
)
class_observed <- class_observed[, c(
  "finding_type", "outcome", "key",
  "boundary_specificity_classification"
)]
names(class_observed)[4] <- "observed_classification"
class_validation <- merge(
  class_reference,
  class_observed,
  by = c("finding_type", "outcome", "key"),
  all.x = TRUE,
  sort = FALSE
)
class_validation$pass <- class_validation$expected_classification ==
  class_validation$observed_classification
class_validation$pass[is.na(class_validation$pass)] <- FALSE
write.csv(
  class_validation,
  file.path(OUT, "frozen_classification_validation.csv"),
  row.names = FALSE,
  na = ""
)

surface <- read_csv(file.path(
  ROOT,
  "analysis_spatial_falsification_revised_dev", "tables",
  "boundary_surface_summary.csv"
))
surface <- subset(
  surface,
  boundary_id == "actual_c000" &
    threshold_tag == "tau025" &
    ((outcome == "fire" & measurement_version == "harmonized_tau025") |
      outcome %in% c("tree_cover_loss", "agriculture"))
)
events <- aggregate(y ~ outcome, surface, sum)
expected_events <- c(fire = 508320, tree_cover_loss = 519, agriculture = 518)
events$expected <- unname(expected_events[events$outcome])
events$pass <- events$y == events$expected
write.csv(events, file.path(OUT, "frozen_event_total_validation.csv"), row.names = FALSE)

failures <- sum(!validation$pass) + sum(!class_validation$pass) + sum(!events$pass)
cat("frozen_scalar_failures=", sum(!validation$pass), "\n", sep = "")
cat("frozen_classification_failures=", sum(!class_validation$pass), "\n", sep = "")
cat("locked_event_total_failures=", sum(!events$pass), "\n", sep = "")
if (failures) quit(status = 1)
