#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(data.table))
source("config/final_robustness_config.R")

out <- FINAL_SPEC$output_dir
read_out <- function(name) {
  path <- file.path(out, name)
  stopifnot(file.exists(path), file.info(path)$size > 0)
  fread(path)
}

h_native <- read_out("hansen_native_loss_gain_overlap_summary.csv")
h_overall <- read_out("hansen_loss_gain_overlap_overall.csv")
h_diag <- read_out("hansen_loss_gain_overlap_diagnostics.csv")
agri <- read_out("agriculture_postevent_classification.csv")
agri_sens <- read_out("agriculture_persistence_sensitivity.csv")
agri_model <- read_out("agriculture_persistent_event_model.csv")
agri_diag <- read_out("agriculture_persistent_event_diagnostics.csv")

stopifnot(
  nrow(h_native) == 1L,
  h_native$loss_pixels > 0L,
  h_native$gain_pixels > 0L,
  h_native$overlap_pixels > 0L,
  h_native$overlap_pixels <= h_native$loss_pixels,
  h_native$overlap_pixels <= h_native$gain_pixels,
  h_diag[diagnostic == "gain_loss_native_geometry_identical", value] == "TRUE",
  h_diag[diagnostic == "hansen_500m_geometry_matches_canonical", value] == "TRUE",
  h_diag[diagnostic == "temporal_order_identifiable", value] == "FALSE"
)

stopifnot(
  all(h_overall$loss_crossing_cells_with_any_overlap <=
        h_overall$loss_crossing_cells_with_any_gain),
  all(h_overall$loss_crossing_cells_with_any_gain <=
        h_overall$loss_crossing_cells_by_2012),
  all(h_overall$proportion_with_any_overlap >= 0 &
        h_overall$proportion_with_any_overlap <= 1)
)

allowed_classes <- c("persistent", "transient/reversed", "intermittent",
                     "right-censored", "missing/uncertain")
stopifnot(
  nrow(agri) == 2685L,
  sum(agri$in_10km) == 518L,
  all(agri$postevent_class %in% allowed_classes),
  sum(table(agri$postevent_class)) == nrow(agri),
  agri_diag$annual_fraction_validation_mismatches[1] == 0L,
  isTRUE(agri_diag$support_rule_passed[1]),
  agri_diag$fit_status[1] == "valid"
)

primary_rule <- agri_sens[
  rule_id == "two_of_three_including_plus1_or_plus2_tau025"]
stopifnot(
  nrow(primary_rule) == 4L,
  all(primary_rule$status == "estimated"),
  all(primary_rule$numerator <= primary_rule$denominator),
  all(primary_rule$proportion >= 0 & primary_rule$proportion <= 1)
)

stopifnot(
  nrow(agri_model[contrast_type == "profile"]) == 3L,
  nrow(agri_model[contrast_type == "pairwise"]) == 3L,
  all(is.finite(agri_model$estimate)),
  all(is.finite(agri_model$standard_error)),
  all(agri_model$conf_low <= agri_model$estimate),
  all(agri_model$estimate <= agri_model$conf_high)
)

required_figures <- c(
  "fig_hansen_loss_gain_overlap.pdf",
  "fig_hansen_loss_gain_overlap.png",
  "fig_agriculture_persistence.pdf",
  "fig_agriculture_persistence.png"
)
stopifnot(
  all(file.exists(file.path(out, required_figures))),
  all(file.info(file.path(out, required_figures))$size > 0)
)

message("Post-event diagnostics validation passed.")
