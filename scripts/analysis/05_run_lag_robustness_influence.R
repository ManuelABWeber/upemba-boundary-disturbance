suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")

set.seed(FINAL_SPEC$seeds$main)
out <- FINAL_SPEC$output_dir
dir.create(out, recursive = TRUE, showWarnings = FALSE)
timeline <- fr_timeline()
episodes <- fr_episode_table(timeline)
spatial <- fr_load_spatial()
manifest <- fr_manifest()
# Record the immutable pre-suite manuscript baseline. The suite's own code
# version is carried separately in FINAL_SPEC$pipeline_version.
pipeline_commit <- system("git rev-parse main", intern = TRUE)

fit_one <- function(surface, run_id, weighted = TRUE) {
  z <- if (unique(surface$outcome) == "fire") fr_fit_fire(surface, run_id) else
    fr_fit_sparse(surface, weighted, run_id)
  support <- fr_support(surface, run_id)
  list(profile = z$profile, pair = z$pair, diagnostics = z$diagnostics,
       support = support)
}

base_surfaces <- setNames(lapply(c("fire", "tree_cover_loss", "agriculture"),
  function(o) fr_build_surface(o, "tau025", 10, spatial, manifest, timeline)),
  c("fire", "tree_cover_loss", "agriculture"))

# ------------------------- temporal lag -------------------------
lag_runs <- list(
  lag0 = list(lag = 0L, exclude = 0L),
  lag1 = list(lag = 1L, exclude = 0L),
  lag2 = list(lag = 2L, exclude = 0L),
  exclude_first_posttransition = list(lag = 0L, exclude = 1L),
  exclude_first_two_posttransition = list(lag = 0L, exclude = 2L)
)
lag_results <- list()
for (nm in names(lag_runs)) {
  rr <- lag_runs[[nm]]
  for (o in names(base_surfaces)) {
    s <- fr_assign_profiles(base_surfaces[[o]], timeline, rr$lag, rr$exclude)
    id <- paste(nm, o, sep = "__")
    z <- fit_one(s, id, TRUE)
    meta <- list(specification = nm, lag = rr$lag,
                 transition_years_excluded = rr$exclude)
    for (part in names(z)) {
      for (k in names(meta)) set(z[[part]], j = k, value = meta[[k]])
    }
    lag_results[[id]] <- z
  }
}
bind_part <- function(x, part) rbindlist(lapply(x, `[[`, part), fill = TRUE)
lag_profile <- bind_part(lag_results, "profile")
lag_pair <- bind_part(lag_results, "pair")
lag_support <- bind_part(lag_results, "support")
lag_diag <- bind_part(lag_results, "diagnostics")
fwrite(lag_profile, file.path(out, "temporal_lag_profile_estimates.csv"))
fwrite(lag_pair, file.path(out, "temporal_lag_pairwise_contrasts.csv"))
fwrite(lag_support, file.path(out, "temporal_lag_support.csv"))
fwrite(lag_diag, file.path(out, "temporal_lag_diagnostics.csv"))

p_lag <- ggplot(lag_profile[specification %in% paste0("lag", 0:2)],
  aes(estimate, governance_profile, colour = factor(lag))) +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high),
                position = position_dodge(width = .55), width = .15,
                orientation = "y", na.rm = TRUE) +
  geom_point(aes(shape = lag == 0), position = position_dodge(width = .55),
             size = 2.2) +
  facet_wrap(~outcome, scales = "free_x") +
  scale_shape_manual(values = c(`TRUE` = 19, `FALSE` = 1),
                     labels = c(`TRUE` = "Primary lag 0",
                                `FALSE` = "Lag sensitivity")) +
  labs(x = "Inside-minus-outside log-odds contrast", y = NULL,
       colour = "Profile lag (years)", shape = NULL,
       caption = "Intervals are conditional model-based intervals; absent intervals indicate a non-strict fire fit.") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(file.path(out, "fig_temporal_lag_sensitivity.pdf"), p_lag,
       width = 10, height = 6)
ggsave(file.path(out, "fig_temporal_lag_sensitivity.png"), p_lag,
       width = 10, height = 6, dpi = 300)

# ---------------- directly matched robustness registry ----------------
registry <- rbindlist(list(
  data.table(run_id = "primary", comparison_class = "directly_matched",
             threshold_tag = "tau025", corridor_km = 10,
             weighting = "inverse_variance", chronology_version = "primary",
             lag = 0L, omitted_episode = NA_character_),
  data.table(run_id = c("threshold_tau010", "threshold_tau050"),
             comparison_class = "directly_matched",
             threshold_tag = c("tau010", "tau050"), corridor_km = 10,
             weighting = "inverse_variance", chronology_version = "primary",
             lag = 0L, omitted_episode = NA_character_),
  data.table(run_id = c("domain_5km", "domain_20km", "domain_full"),
             comparison_class = "directly_matched", threshold_tag = "tau025",
             corridor_km = c(5, 20, Inf), weighting = "inverse_variance",
             chronology_version = "primary", lag = 0L,
             omitted_episode = NA_character_),
  data.table(run_id = "weight_unweighted",
             comparison_class = "directly_matched", threshold_tag = "tau025",
             corridor_km = 10, weighting = "unweighted",
             chronology_version = "primary", lag = 0L,
             omitted_episode = NA_character_),
  data.table(run_id = c("lag_1", "lag_2"),
             comparison_class = "directly_matched", threshold_tag = "tau025",
             corridor_km = 10, weighting = "inverse_variance",
             chronology_version = "primary", lag = 1:2,
             omitted_episode = NA_character_)
), fill = TRUE)

# Documented plausible transition-year alternatives: one year earlier/later.
trans <- timeline[order(SESU_ID, year),
  .(year, governance_profile,
    prior_profile = shift(governance_profile)), by = SESU_ID][
      !is.na(prior_profile) & governance_profile != prior_profile]
alt_timelines <- list()
for (i in seq_len(nrow(trans))) {
  tr <- trans[i]
  for (direction in c("earlier", "later")) {
    id <- paste0("transition_SESU", tr$SESU_ID, "_", tr$year, "_", direction)
    tl <- copy(timeline)
    if (direction == "earlier") {
      tl[SESU_ID == tr$SESU_ID & year == tr$year - 1L,
         governance_profile := tr$governance_profile]
    } else {
      tl[SESU_ID == tr$SESU_ID & year == tr$year,
         governance_profile := tr$prior_profile]
    }
    alt_timelines[[id]] <- tl
    registry <- rbind(registry, data.table(
      run_id = id, comparison_class = "directly_matched",
      threshold_tag = "tau025", corridor_km = 10,
      weighting = "inverse_variance", chronology_version = id, lag = 0L,
      omitted_episode = NA_character_))
  }
}

# Leave one of the 11 contiguous historical episodes out.
ep_defs <- unique(episodes[, .(episode_id, SESU_ID,
                               governance_profile,
                               start_year = min(year), end_year = max(year)),
                           by = episode_id])
for (ep in ep_defs$episode_id) {
  registry <- rbind(registry, data.table(
    run_id = paste0("omit_", ep), comparison_class = "directly_matched",
    threshold_tag = "tau025", corridor_km = 10,
    weighting = "inverse_variance", chronology_version = "primary", lag = 0L,
    omitted_episode = ep))
}
registry[, `:=`(pipeline_version = FINAL_SPEC$pipeline_version,
                 pipeline_commit = pipeline_commit)]

rob <- list()
surface_cache <- new.env(parent = emptyenv())
get_surface <- function(o, tag, corridor) {
  key <- paste(o, tag, corridor, sep = "__")
  if (!exists(key, surface_cache, inherits = FALSE)) {
    assign(key, fr_build_surface(o, tag, corridor, spatial, manifest, timeline),
           surface_cache)
  }
  get(key, surface_cache, inherits = FALSE)
}
for (i in seq_len(nrow(registry))) {
  rr <- registry[i]
  for (o in names(base_surfaces)) {
    s <- get_surface(o, rr$threshold_tag, rr$corridor_km)
    tl <- if (rr$chronology_version %in% names(alt_timelines))
      alt_timelines[[rr$chronology_version]] else timeline
    s <- fr_assign_profiles(s, tl, rr$lag)
    if (!is.na(rr$omitted_episode)) {
      omit <- episodes[episode_id == rr$omitted_episode, .(SESU_ID, year)]
      s <- s[!omit, on = .(SESU_ID, year)]
    }
    id <- paste(rr$run_id, o, sep = "__")
    z <- fit_one(s, id, rr$weighting == "inverse_variance")
    meta <- rr[, setdiff(names(rr), "run_id"), with = FALSE]
    for (part in names(z)) {
      for (k in names(meta)) set(z[[part]], j = k, value = meta[[k]][1])
      z[[part]][, robustness_run_id := rr$run_id]
    }
    rob[[id]] <- z
  }
}
rob_profile <- bind_part(rob, "profile")
rob_pair <- bind_part(rob, "pair")
rob_support <- bind_part(rob, "support")
rob_diag <- bind_part(rob, "diagnostics")
fit_status <- rob_diag[, .(fit_validity_status = first(fit_status),
                           warning_messages = paste(unique(warning_messages[nzchar(warning_messages)]),
                                                    collapse = " | ")),
                       by = .(robustness_run_id, outcome)]
registry_out <- merge(CJ(robustness_run_id = registry$run_id,
                         outcome = names(base_surfaces)),
                      registry, by.x = "robustness_run_id",
                      by.y = "run_id", all.x = TRUE)
registry_out <- merge(registry_out, rob_support[, .(
  robustness_run_id, outcome, eligible_cells, cell_years, events,
  group_years, historical_episodes)], by = c("robustness_run_id", "outcome"),
  all.x = TRUE)
registry_out <- merge(registry_out, fit_status,
                      by = c("robustness_run_id", "outcome"), all.x = TRUE)
fwrite(registry_out, file.path(out, "robustness_run_registry.csv"))
fwrite(rob_profile, file.path(out, "robustness_profile_estimates.csv"))
fwrite(rob_pair, file.path(out, "robustness_pairwise_contrasts.csv"))
fwrite(rob_support, file.path(out, "robustness_support.csv"))
fwrite(rob_diag, file.path(out, "robustness_fit_diagnostics.csv"))

wide <- dcast(rob_profile,
  outcome + governance_profile ~ robustness_run_id,
  value.var = "estimate")
fwrite(wide, file.path(out, "robustness_matrix_wide.csv"))
figure_ids <- c("primary", "threshold_tau010", "threshold_tau050",
                "domain_5km", "domain_20km", "domain_full",
                "weight_unweighted", "lag_1", "lag_2")
plot_core <- rob_profile[robustness_run_id %in% figure_ids]
range_row <- function(pattern, label) {
  rob_profile[grepl(pattern, robustness_run_id), .(
    estimate = median(estimate, na.rm = TRUE),
    standard_error = NA_real_,
    conf_low = min(estimate, na.rm = TRUE),
    conf_high = max(estimate, na.rm = TRUE),
    odds_ratio = exp(median(estimate, na.rm = TRUE)),
    robustness_run_id = label,
    comparison_class = "directly_matched"
  ), by = .(outcome, governance_profile)]
}
plot_ranges <- rbindlist(list(
  range_row("^transition_", "chronology_alternative_range"),
  range_row("^omit_", "episode_omission_range")
), fill = TRUE)
plot_rob <- rbindlist(list(plot_core, plot_ranges), fill = TRUE)
plot_rob <- merge(plot_rob, fit_status,
                  by = c("robustness_run_id", "outcome"), all.x = TRUE)
plot_rob[robustness_run_id %in% c("chronology_alternative_range",
                                  "episode_omission_range"),
         fit_validity_status := "range_summary"]
plot_rob[, evidence_state := fifelse(
  fit_validity_status %in% c("invalid_fit", "insufficient_support"),
  "invalid or unsupported",
  fifelse(is.na(conf_low) | is.na(conf_high), "invalid or unsupported",
  fifelse(conf_low > 0 | conf_high < 0, "interval excludes zero",
          "interval includes zero")))]
primary_sign <- plot_rob[robustness_run_id == "primary",
                         .(primary_sign = sign(estimate)),
                         by = .(outcome, governance_profile)]
plot_rob <- merge(plot_rob, primary_sign,
                  by = c("outcome", "governance_profile"), all.x = TRUE)
plot_rob[evidence_state != "invalid or unsupported" &
           sign(estimate) == primary_sign,
         evidence_state := paste0(evidence_state, "; direction retained")]
p_rob <- ggplot(plot_rob[comparison_class == "directly_matched"],
  aes(estimate, factor(robustness_run_id, levels = rev(c(
    figure_ids, "chronology_alternative_range", "episode_omission_range"))),
      colour = evidence_state)) +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high), width = .15,
                orientation = "y", na.rm = TRUE) + geom_point() +
  facet_grid(governance_profile ~ outcome, scales = "free_x") +
  labs(x = "Inside-minus-outside log-odds contrast", y = NULL,
       colour = "Result classification") +
  theme_minimal(base_size = 8) + theme(legend.position = "bottom")
ggsave(file.path(out, "fig_robustness_matrix.pdf"), p_rob,
       width = 13, height = 10, limitsize = FALSE)
ggsave(file.path(out, "fig_robustness_matrix.png"), p_rob,
       width = 13, height = 10, dpi = 300, limitsize = FALSE)

# ---------------- episode and landscape influence ----------------
episode_profile <- merge(
  rob_profile[grepl("^omit_", robustness_run_id)], fit_status,
  by = c("robustness_run_id", "outcome"), all.x = TRUE)
episode_pair <- merge(
  rob_pair[grepl("^omit_", robustness_run_id)], fit_status,
  by = c("robustness_run_id", "outcome"), all.x = TRUE)
episode_influence <- rbindlist(list(
  episode_profile[, .(record_type = "profile", outcome,
      profile = governance_profile, omitted_episode,
      estimate, standard_error, conf_low, conf_high,
      fit_status = fit_validity_status)],
  episode_pair[, .(record_type = "pairwise", outcome,
      profile = profile_comparison, omitted_episode,
      estimate, standard_error, conf_low, conf_high,
      fit_status = fit_validity_status)]
), fill = TRUE)

landscape <- list()
for (sid in CH1_INCLUDED_SESUS) {
  for (o in names(base_surfaces)) {
    s <- base_surfaces[[o]][SESU_ID == sid]
    id <- paste0("SESU", sid, "__", o)
    z <- fit_one(s, id, TRUE)
    if (nrow(z$profile)) z$profile[, landscape_group := ifelse(
      sid == 1L, "Depression", "Plateau")]
    if (nrow(z$diagnostics)) z$diagnostics[, landscape_group := ifelse(
      sid == 1L, "Depression", "Plateau")]
    landscape[[id]] <- z
  }
}
land_profile <- bind_part(landscape, "profile")
land_diag <- bind_part(landscape, "diagnostics")
land_out <- merge(land_profile,
                  land_diag[, .(run_id, fit_status, warning_messages)],
                  by = "run_id", all = TRUE)
fwrite(land_out, file.path(out, "landscape_specific_estimates.csv"))

ep_support <- rbindlist(lapply(ep_defs$episode_id, function(ep) {
  keys <- episodes[episode_id == ep, .(SESU_ID, year)]
  rbindlist(lapply(base_surfaces, function(s) {
    x <- s[keys, on = .(SESU_ID, year), nomatch = 0]
    data.table(episode_id = ep, outcome = unique(s$outcome),
               events = sum(x$y), cell_years = sum(x$n),
               group_years = uniqueN(x[, .(SESU_ID, year)]),
               zero_event = sum(x$y) == 0,
               nearly_unsupported = sum(x$y) < 5)
  }))
}))
fwrite(ep_support, file.path(out, "episode_support.csv"))

episode_descriptive <- rbindlist(lapply(ep_defs$episode_id, function(ep) {
  keys <- episodes[episode_id == ep, .(SESU_ID, year)]
  rbindlist(lapply(base_surfaces, function(s) {
    x <- s[keys, on = .(SESU_ID, year), nomatch = 0,
           .(y = sum(y), n = sum(n)), by = .(outcome, side)]
    w <- dcast(x, outcome ~ side, value.var = c("y", "n"))
    if (!all(c("y_inside", "y_outside", "n_inside", "n_outside") %in%
             names(w))) return(data.table())
    w[, `:=`(yi = y_inside + .5, ni = n_inside + 1,
             yo = y_outside + .5, no = n_outside + 1)]
    w[, `:=`(
      estimate = log(yi / (ni - yi)) - log(yo / (no - yo)),
      standard_error = sqrt(1 / yi + 1 / (ni - yi) +
                              1 / yo + 1 / (no - yo))
    )]
    w[, .(
      record_type = "episode_descriptive", outcome,
      profile = episodes[episode_id == ep,
                         unique(governance_profile)][1],
      omitted_episode = NA_character_, episode_id = ep,
      estimate, standard_error,
      conf_low = estimate - qnorm(.975) * standard_error,
      conf_high = estimate + qnorm(.975) * standard_error,
      fit_status = ifelse(y_inside + y_outside < 5,
                          "nearly_unsupported_descriptive",
                          "descriptive_not_independent")
    )]
  }))
}))
episode_influence <- rbindlist(list(episode_influence,
                                    episode_descriptive), fill = TRUE)
fwrite(episode_influence, file.path(out, "episode_influence.csv"))

p_ep <- merge(episode_profile,
  rob_profile[robustness_run_id == "primary",
              .(outcome, governance_profile, primary = estimate)],
  by = c("outcome", "governance_profile"), all.x = TRUE)
p_episode <- ggplot(p_ep, aes(estimate, omitted_episode)) +
  geom_vline(aes(xintercept = primary), colour = "grey60") +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high), width = .15,
                orientation = "y", na.rm = TRUE) + geom_point() +
  facet_grid(governance_profile ~ outcome, scales = "free_x") +
  labs(x = "Leave-one-episode-out contrast", y = NULL,
       caption = "Grey reference lines show the corresponding primary estimate.") +
  theme_minimal(base_size = 9)
ggsave(file.path(out, "fig_episode_influence.pdf"), p_episode,
       width = 12, height = 9)
ggsave(file.path(out, "fig_episode_influence.png"), p_episode,
       width = 12, height = 9, dpi = 300)

message("Lag, matched robustness, and influence analyses complete.")
