# Invoked by script 09 after input/date validation. No raw rasters are exported.
stopifnot(exists("frac_mat"), !historical_rules)
dest <- dirname(out)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
g <- copy(geom10)
fm <- frac_mat[match10, , drop = FALSE]
original <- canonical_first_025[match10]
end_original <- apply(fm, 1, ag_observation_end)
end_persistent <- persistent_observation_end[match10]
xy <- xyFromCell(template, g$cell)
g[, `:=`(x_m = xy[, 1], y_m = xy[, 2])]
# Fixed 5 km UTM tiles; resample whole 23-year trajectories, stratifying only
# by landscape group. A tile crossing the boundary retains both of its sides.
g[, block := paste(SESU_ID, floor(x_m / 5000), floor(y_m / 5000), sep = "_")]
specs <- data.table(
  analysis = c("first_crossing_full", "first_crossing_restricted", "persistence_corrected", "annual_presence"),
  start = 2001L, end = c(2022L, 2019L, 2019L, 2022L),
  response = c("first below-to-at-least-25% crossing", "first below-to-at-least-25% crossing",
    "first crossing with >=2 of 3 valid future years >=25%, including +1 or +2", "annual cropland fraction >=25%"),
  risk_exit = c("after first crossing or first unobserved history", "after first crossing or first unobserved history",
    "after first qualifying persistent crossing or first unobserved history/followup", "no event-based exit; finite annual observations"),
  baseline = "finite 2000 required; baseline agricultural cells retained",
  domain = "absolute signed boundary distance <=10 km; SESU 1 and 3",
  model = "paired landscape-year inside-minus-outside log odds ~ profile + landscape group; inverse-variance weighted lm; 0.5 correction",
  interval = "HC3 normal CI for established comparison; whole-trajectory 5 km spatial tile bootstrap percentile CI for dependence sensitivity",
  bootstrap_replicates = 499L, bootstrap_seed = 20260910L)
blocks <- rbindlist(lapply(seq_len(nrow(specs)), function(i) {
  nm <- specs$analysis[i]
  ev <- if (nm == "persistence_corrected") persistent_ev10 else original
  obs_end <- if (nm == "persistence_corrected") end_persistent else end_original
  rbindlist(lapply(specs$start[i]:specs$end[i], function(yr) {
    if (nm == "annual_presence") {
      v <- fm[, match(yr, required_afcd_years)]
      keep <- is.finite(fm[, 1]) & is.finite(v)
      event <- v >= .25
    } else {
      keep <- yr <= obs_end & (is.na(ev) | yr <= ev)
      event <- !is.na(ev) & ev == yr
    }
    d <- copy(g[keep]); d[, `:=`(year = yr, y_cell = as.integer(event[keep]))]
    d[, .(n = .N, y = sum(y_cell)), by = .(block, SESU_ID, side, year)][, analysis := nm]
  }))
}))
blocks <- merge(blocks, timeline[, .(SESU_ID, year, governance_profile)], by = c("SESU_ID", "year"))
surface <- blocks[, .(n = sum(n), y = sum(y)), by = .(analysis, SESU_ID, side, year, governance_profile)]
surface[, outcome := "agriculture"]
surface[, landscape_group := fifelse(SESU_ID == 1L, "Depression", "Plateau")]
fwrite(surface, file.path(dest, "agriculture_counts_by_side_group_profile_year.csv"))
fwrite(surface[, .(cell_years = sum(n), events_or_presence_cell_years = sum(y),
  inside = sum(y[side == "inside"]), outside = sum(y[side == "outside"])), by = analysis],
  file.path(dest, "agriculture_total_support.csv"))
fwrite(specs, file.path(dest, "agriculture_model_specifications.csv"))
fits <- setNames(lapply(specs$analysis, function(nm) fr_fit_sparse(surface[analysis == nm], run_id = nm)), specs$analysis)
saveRDS(list(fits = fits, specifications = specs, session = sessionInfo()), file.path(dest, "agriculture_models.rds"))
fwrite(rbindlist(lapply(fits, `[[`, "profile")), file.path(dest, "agriculture_profile_estimates_hc3.csv"))
fwrite(rbindlist(lapply(fits, `[[`, "pair")), file.path(dest, "agriculture_pairwise_estimates_hc3.csv"))
fwrite(rbindlist(lapply(fits, `[[`, "diagnostics")), file.path(dest, "agriculture_model_diagnostics.csv"))
coefficients <- rbindlist(lapply(names(fits), function(nm) {
  f <- fits[[nm]]; b <- coef(f$model); se <- sqrt(diag(f$covariance))
  data.table(analysis = nm, term = names(b), estimate = b, standard_error = se,
    conf_low = b - qnorm(.975) * se, conf_high = b + qnorm(.975) * se,
    rank = f$model$rank, residual_df = df.residual(f$model))
}))
fwrite(coefficients, file.path(dest, "agriculture_coefficients_hc3.csv"))

# Exact cell-level reconciliation, including historical classifications.
old <- fread(file.path(FINAL_SPEC$output_dir, "agriculture_postevent_classification.csv"))
now <- copy(spatial$geom)[!is.na(canonical_first_025)]
now[, event_year := canonical_first_025[!is.na(canonical_first_025)]]
coord <- xyFromCell(template, now$cell)
now[, `:=`(x_m = coord[,1], y_m = coord[,2], in_10km = abs(signed_distance_km) <= 10)]
cmp <- merge(now, old[, .(cell, old_event_year = event_year, old_side = park_side,
  old_distance = signed_distance_km, old_in_10km = in_10km)], by = "cell", all = TRUE)
cmp[, matches := event_year == old_event_year & side == old_side &
      abs(signed_distance_km - old_distance) < 1e-9 & in_10km == old_in_10km]
stopifnot(nrow(cmp) == 2685L, all(cmp$matches))
fwrite(cmp, file.path(dest, "agriculture_cell_reconciliation.csv"))
primary <- fread("analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv")[boundary_id == "actual_c000" & outcome == "agriculture"]
primary[, side := fifelse(side == "interior_facing", "inside", "outside")]
check <- merge(surface[analysis == "first_crossing_full"], primary,
  by = c("SESU_ID", "side", "year"), suffixes = c("_reconstructed", "_primary"))
stopifnot(nrow(check) == 88L, all(check$n_reconstructed == check$n_primary), all(check$y_reconstructed == check$y_primary))
fwrite(check[, .(SESU_ID, side, year, n_reconstructed, n_primary, y_reconstructed, y_primary)], file.path(dest, "agriculture_primary_surface_reconciliation.csv"))

events[, reversal_status := ag_reversal(event_year, cropland_fraction_year_plus1, cropland_fraction_year_plus2)]
rev <- rbindlist(list(events[, domain := "full"], copy(events[in_10km == TRUE])[, domain := "10km"]))
revsum <- rev[, .(all_events = .N, eligible = sum(reversal_status %in% c("reversed", "not_reversed")),
  reversed = sum(reversal_status == "reversed"), insufficient_followup = sum(reversal_status == "insufficient_followup"),
  missing_followup = sum(reversal_status == "missing_followup")), by = .(domain, park_side)]
revsum[, reversal_percent := 100 * reversed / eligible]
fwrite(revsum, file.path(dest, "agriculture_reversal_denominators.csv"))
fwrite(rev[, .N, by = .(domain, park_side, SESU_ID, governance_profile_at_event, event_year, reversal_status)], file.path(dest, "agriculture_reversal_counts.csv"))
fwrite(events, file.path(out, "agriculture_postevent_classification.csv"))
dates <- copy(g)
dates[, `:=`(original_event = original, persistent_event = persistent_ev10,
  original_observed_through = end_original, persistent_observed_through = end_persistent,
  baseline_agricultural = fm[,1] >= .25)]
fwrite(dates[!is.na(original_event) | !is.na(persistent_event)], file.path(dest, "agriculture_event_dates.csv"))
fwrite(dates[, .(cells = .N, baseline_agricultural = sum(baseline_agricultural),
  missing_baseline = sum(!is.finite(fm[,1][.I])),
  first_missing_history_censored = sum(original_observed_through < 2022),
  persistent_missing_history_censored = sum(persistent_observed_through < 2019)), by = .(SESU_ID, side)], file.path(dest, "agriculture_eligibility.csv"))

set.seed(20260910)
block_ids <- unique(g[, .(SESU_ID, block)])
draws <- vector("list", 499L)
for (b in seq_along(draws)) {
  sampled <- block_ids[, .(block = sample(block, .N, replace = TRUE)), by = SESU_ID][, .(multiplicity = .N), by = block]
  bd <- merge(blocks, sampled, by = "block")
  ss <- bd[, .(n = sum(n * multiplicity), y = sum(y * multiplicity)), by = .(analysis, SESU_ID, side, year, governance_profile)]
  ss[, outcome := "agriculture"]
  draws[[b]] <- rbindlist(lapply(specs$analysis, function(nm) {
    ff <- fr_fit_sparse(ss[analysis == nm], run_id = nm)
    ff$profile[, .(analysis = run_id, governance_profile, estimate)]
  }))[, replicate := b]
}
draws <- rbindlist(draws)
fwrite(draws, file.path(dest, "agriculture_spatial_bootstrap_draws.csv"))
boot <- draws[, .(replicates = .N, bootstrap_se = sd(estimate),
  conf_low = quantile(estimate, .025), conf_high = quantile(estimate, .975)), by = .(analysis, governance_profile)]
fwrite(boot, file.path(dest, "agriculture_spatial_bootstrap_intervals.csv"))
fwrite(block_ids[, .(spatial_blocks = .N), by = SESU_ID], file.path(dest, "agriculture_spatial_block_support.csv"))
wide <- dcast(draws, replicate + governance_profile ~ analysis, value.var = "estimate")
changes <- rbindlist(list(wide[, .(replicate, governance_profile, comparison = "period: restricted minus full", change = first_crossing_restricted - first_crossing_full)],
  wide[, .(replicate, governance_profile, comparison = "definition: persistence minus restricted", change = persistence_corrected - first_crossing_restricted)]))
change_summary <- changes[, .(bootstrap_mean_change = mean(change), conf_low = quantile(change,.025), conf_high = quantile(change,.975)), by = .(comparison, governance_profile)]
point <- dcast(rbindlist(lapply(fits, `[[`, "profile")), governance_profile ~ run_id, value.var = "estimate")
point_changes <- rbindlist(list(
  point[, .(governance_profile, comparison = "period: restricted minus full", point_change = first_crossing_restricted - first_crossing_full)],
  point[, .(governance_profile, comparison = "definition: persistence minus restricted", point_change = persistence_corrected - first_crossing_restricted)]))
fwrite(merge(point_changes, change_summary, by = c("comparison", "governance_profile")), file.path(dest, "agriculture_paired_changes_bootstrap.csv"))
writeLines(c("Rscript --vanilla scripts/analysis/09_hansen_gain_and_agriculture_persistence.R", capture.output(sessionInfo())), file.path(dest, "execution_session.txt"))
message("Corrected agricultural comparisons and 499 whole-trajectory spatial bootstrap replicates complete.")
