Sys.setenv(UPEMBA_POSTEVENT_RULE_VERSION = "historical_2026_08")
#!/usr/bin/env Rscript
# Reproduce the EXISTING post-event analysis in an isolated output directory.
# No outcome definition, censoring policy, model specification or year is changed.
suppressPackageStartupMessages(library(data.table))
source("config/final_robustness_config.R")
audit_dir <- file.path(CH1_PROJECT_ROOT, "outputs", "_validation", "submission-postevent")
evidence_dir <- file.path(CH1_PROJECT_ROOT, "docs", "submission", "validation")
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
cache_preexisted <- dir.exists(file.path(audit_dir, "cache"))
Sys.setenv(UPEMBA_POSTEVENT_OUTPUT_DIR = audit_dir)
source("scripts/analysis/09_hansen_gain_and_agriculture_persistence.R")

csvs <- list.files(audit_dir, pattern = "\\.csv$", full.names = FALSE)
comparisons <- rbindlist(lapply(csvs, function(nm) {
  actual <- fread(file.path(audit_dir, nm))
  reference <- fread(file.path(FINAL_SPEC$output_dir, nm))
  same_shape <- identical(names(actual), names(reference)) && nrow(actual) == nrow(reference)
  max_diff <- 0
  pass <- same_shape
  if (same_shape) for (col in names(actual)) {
    a <- actual[[col]]; b <- reference[[col]]
    if (is.numeric(a) && is.numeric(b)) {
      ok <- identical(is.na(a), is.na(b))
      finite <- is.finite(a) & is.finite(b)
      delta <- if (any(finite)) max(abs(a[finite] - b[finite])) else 0
      max_diff <- max(max_diff, delta)
      pass <- pass && ok && delta <= 1e-8
    } else pass <- pass && identical(as.character(a), as.character(b))
  }
  data.table(file = nm, rows = nrow(actual), max_numeric_difference = max_diff, pass = pass)
}))
fwrite(comparisons, file.path(evidence_dir, "postevent_reproduction.csv"))
stopifnot(all(comparisons$pass))

# The historical helper returned summaries, not its lm object. Recreate that
# exact lm from its returned, aggregated contrasts and retain it as NEW audit evidence.
w <- copy(persistent_fit$contrasts)
audit_model <- lm(FINAL_SPEC$sparse_formula, data = w,
                  weights = inverse_variance_weight)
saveRDS(list(model = audit_model, hc3 = fr_hc3(audit_model),
             provenance = "Reproduced from script 09 during submission audit; not a historical saved model"),
        file.path(evidence_dir, "agriculture_persistent_refit_audit.rds"))
fwrite(persistent_surface, file.path(evidence_dir, "persistent_model_surface.csv"))
fwrite(w, file.path(evidence_dir, "persistent_model_contrasts.csv"))
fwrite(persistent_surface[, .(risk_cell_years = sum(n), events = sum(y)),
                          by = .(year, governance_profile)],
       file.path(evidence_dir, "persistent_year_profile_support.csv"))
fwrite(expanded_events[, .(events = .N),
                      by = .(corridor_domain, park_side, postevent_class)],
       file.path(evidence_dir, "agriculture_domain_class_counts.csv"))

dating <- data.table(canonical_year = canonical_first_025[match10],
                     persistent_year = persistent_ev10, SESU_ID = geom10$SESU_ID,
                     side = geom10$side)
fwrite(dating[, .(cells = .N), by = .(canonical_year, persistent_year, SESU_ID, side)],
       file.path(evidence_dir, "persistent_event_dating_counts.csv"))
missing <- rbindlist(lapply(seq_along(required_afcd_years), function(j) {
  rbindlist(lapply(c("full", "10km"), function(domain) {
    idx <- if (domain == "full") seq_len(nrow(frac_mat)) else match10
    data.table(domain = domain, year = required_afcd_years[j], cells = length(idx),
               missing = sum(!is.finite(frac_mat[idx, j])),
               above_25pct = sum(frac_mat[idx, j] >= 0.25, na.rm = TRUE))
  }))
}))
fwrite(missing, file.path(evidence_dir, "annual_afcd_coverage.csv"))

# Reproduce primary sparse estimates from their retained authoritative surfaces.
primary <- fread(file.path(CH1_PROJECT_ROOT,
  "analysis_spatial_falsification_revised_dev", "tables", "boundary_surface_summary.csv"))
primary <- primary[boundary_id == "actual_c000" & threshold_tag == "tau025" &
                     outcome %in% c("agriculture", "tree_cover_loss")]
primary[, side := fcase(side == "interior_facing", "inside",
                       side == "exterior_facing", "outside", default = side)]
primary_checks <- rbindlist(lapply(unique(primary$outcome), function(o) {
  fit <- fr_fit_sparse(primary[outcome == o], run_id = paste0(o, "_audit"))
  ref <- fread(file.path(FINAL_SPEC$output_dir, "baseline_primary_results.csv"))[outcome == o]
  cmp <- merge(fit$profile, ref, by = c("outcome", "governance_profile"), suffixes = c("_audit", "_reference"))
  cmp[, .(outcome, governance_profile,
          estimate_difference = estimate_audit - estimate_reference,
          lower_difference = conf_low - lower_95_ci,
          upper_difference = conf_high - upper_95_ci)]
}))
primary_checks[, pass := abs(estimate_difference) < 1e-8 & abs(lower_difference) < 1e-8 & abs(upper_difference) < 1e-8]
fwrite(primary_checks, file.path(evidence_dir, "primary_sparse_reproduction.csv"))
stopifnot(all(primary_checks$pass))
input_paths <- c(afcd_path, spatial$cov_path, spatial$sesu_path, aoi_path,
                 gain_files, loss_files, CH1_GOVERNANCE_PROFILE_PATH)
fwrite(data.table(input = basename(input_paths), bytes = file.info(input_paths)$size,
                 sha256 = vapply(input_paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))),
       file.path(evidence_dir, "reproduction_input_checksums.csv"))
writeLines(c("Command: Rscript --vanilla tests/scripts/audit_submission_reproduction.R",
             if (cache_preexisted) "Verification reused the isolated projection cache; see handover for first-pass raw-input reproduction." else
               "Raw-input reprojection used a fresh isolated cache.",
             "The existing 2001-2022 model, including its unresolved follow-up limitation, was reproduced without alteration.",
             trimws(capture.output(sessionInfo()), which = "right")),
           file.path(evidence_dir, "reproduction_session.txt"))
message("Submission numerical reproduction passed; see handover for scientific limitations.")
