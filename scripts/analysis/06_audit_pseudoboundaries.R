suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")

out <- FINAL_SPEC$output_dir
timeline <- fr_timeline()
spatial <- fr_load_spatial()
manifest <- fr_manifest()
centres <- c(0, FINAL_SPEC$pseudo_centres_km)
half_width <- FINAL_SPEC$primary_corridor_km

design_membership <- function(center) {
  if (center == 0) return("legal")
  z <- names(Filter(function(v) center %in% v, FINAL_SPEC$pseudo_designs))
  paste(z, collapse = ";")
}
geometry <- data.table(boundary_center_km = centres)
geometry[, `:=`(
  park_facing_min_km = boundary_center_km - half_width,
  park_facing_max_km = boundary_center_km,
  park_facing_interval = paste0("[", boundary_center_km - half_width,
                                ", ", boundary_center_km, ")"),
  outward_facing_min_km = boundary_center_km,
  outward_facing_max_km = boundary_center_km + half_width,
  outward_facing_interval = paste0("[", boundary_center_km, ", ",
                                   boundary_center_km + half_width, "]"),
  crosses_legal_boundary = boundary_center_km - half_width < 0 &
    boundary_center_km + half_width > 0,
  touches_legal_boundary = boundary_center_km - half_width == 0,
  design_membership = vapply(boundary_center_km, design_membership,
                             character(1)),
  implementation_rule = "abs(signed_distance_km-center)<=10; signed_distance_km<center is park-facing"
)]
fwrite(geometry, file.path(out, "pseudoboundary_geometry.csv"))

boundary_geom <- function(center) {
  x <- spatial$geom[abs(signed_distance_km - center) <= half_width]
  x[, side := fifelse(signed_distance_km < center, "inside", "outside")]
  x
}

feature_names <- intersect(
  c("elevation_m", "slope_deg", "dist_perm_water_m",
    "accessibility_cities", "clim_precip_mean_mm_1981_2010",
    "clim_precip_sd_mm_1981_2010", "clim_aet_mean_mm_1981_2010",
    "clim_pet_mean_mm_1981_2010", "clim_water_balance_mm_1981_2010",
    "clim_aridity_index_p_over_pet_1981_2010",
    "forest2000_ge_30pct", "dist_weighted_urban"),
  names(spatial$cov))
cov_all <- as.data.table(terra::values(spatial$cov[[feature_names]]))
cov_all[, cell := seq_len(.N)]
setkey(cov_all, cell)

support_rows <- list()
estimate_rows <- list()
diag_rows <- list()
cell_sets <- list()
for (center in centres) {
  geom <- boundary_geom(center)
  cell_sets[[as.character(center)]] <- geom$cell
  cd <- cov_all[geom, on = "cell"]
  balance <- rbindlist(lapply(feature_names, function(v) {
    a <- cd[side == "inside", get(v)]
    b <- cd[side == "outside", get(v)]
    sp <- sqrt((var(a, na.rm = TRUE) + var(b, na.rm = TRUE)) / 2)
    data.table(covariate = v, smd = if (is.finite(sp) && sp > 0)
      (mean(a, na.rm = TRUE) - mean(b, na.rm = TRUE)) / sp else NA_real_)
  }))
  bal_summary <- balance[, .(
    median_abs_smd = median(abs(smd), na.rm = TRUE),
    max_abs_smd = max(abs(smd), na.rm = TRUE)
  )]
  for (o in c("fire", "tree_cover_loss", "agriculture")) {
    s <- if (o == "fire") {
      fr_surface_fire("tau025", geom, spatial, manifest, timeline)
    } else {
      fr_surface_event(o, "tau025", geom, spatial, manifest, timeline)
    }
    id <- paste0("boundary_", center, "__", o)
    z <- if (o == "fire") fr_fit_fire(s, id) else fr_fit_sparse(s, TRUE, id)
    sup <- fr_support(s, id)
    side_cells <- geom[, .(eligible_cells = .N),
                       by = .(SESU_ID, side)]
    side_event_support <- s[, .(
      events = sum(y), cell_years = sum(n),
      group_years = uniqueN(paste(SESU_ID, year))
    ), by = .(SESU_ID, side)]
    side_cells <- merge(side_cells, side_event_support,
                        by = c("SESU_ID", "side"), all.x = TRUE)
    side_cells[, `:=`(
      boundary_center_km = center, outcome = o,
      design_membership = design_membership(center),
      median_abs_smd = bal_summary$median_abs_smd,
      max_abs_smd = bal_summary$max_abs_smd
    )]
    support_rows[[id]] <- side_cells
    if (nrow(z$profile)) {
      z$profile[, `:=`(boundary_center_km = center,
                        design_membership = design_membership(center),
                        comparison_direction =
                          "park-facing minus outward-facing")]
      estimate_rows[[paste0(id, "_profile")]] <- z$profile
    }
    if (nrow(z$pair)) {
      z$pair[, `:=`(boundary_center_km = center,
                     design_membership = design_membership(center),
                     comparison_direction =
                       "difference between profile-specific park-facing minus outward-facing contrasts")]
      z$pair[, governance_profile := profile_comparison]
      z$pair[, profile_comparison := NULL]
      estimate_rows[[paste0(id, "_pair")]] <- z$pair[, result_type := "pairwise"]
    }
    if (nrow(z$profile)) estimate_rows[[paste0(id, "_profile")]][,
      result_type := "profile"]
    z$diagnostics[, `:=`(boundary_center_km = center,
                          design_membership = design_membership(center))]
    diag_rows[[id]] <- z$diagnostics
  }
}
support <- rbindlist(support_rows, fill = TRUE)

# Pairwise spatial overlap is deterministic and reported because offsets are
# descriptive, overlapping diagnostics rather than independent replicates.
overlap <- rbindlist(lapply(combn(centres, 2, simplify = FALSE), function(p) {
  a <- cell_sets[[as.character(p[1])]]
  b <- cell_sets[[as.character(p[2])]]
  data.table(center_a_km = p[1], center_b_km = p[2],
             shared_cells = length(intersect(a, b)),
             jaccard_overlap = length(intersect(a, b)) /
               length(union(a, b)))
}))
support[, maximum_overlap_with_another_center := vapply(
  boundary_center_km, function(cc) {
    max(overlap[center_a_km == cc | center_b_km == cc, jaccard_overlap],
        na.rm = TRUE)
  }, numeric(1))]
fwrite(support, file.path(out, "pseudoboundary_design_support.csv"))

est <- rbindlist(estimate_rows, fill = TRUE)
diag <- rbindlist(diag_rows, fill = TRUE)
est <- merge(est, diag[, .(run_id, fit_validity_status = fit_status,
                           warning_messages)],
             by = "run_id", all.x = TRUE)

design_long <- rbindlist(lapply(names(FINAL_SPEC$pseudo_designs), function(d) {
  x <- est[boundary_center_km == 0 |
             boundary_center_km %in% FINAL_SPEC$pseudo_designs[[d]]]
  x[, design := d]
  x
}))
design_long[, legal_rank := {
  legal <- estimate[boundary_center_km == 0]
  if (!length(legal)) NA_integer_ else
    rank(c(legal[1], estimate[boundary_center_km != 0]),
         ties.method = "average")[1]
}, by = .(design, outcome, result_type, governance_profile)]
design_long[, legal_percentile_among_offsets := {
  legal <- estimate[boundary_center_km == 0]
  offs <- estimate[boundary_center_km != 0]
  if (!length(legal) || !length(offs)) NA_real_ else mean(offs <= legal[1])
}, by = .(design, outcome, result_type, governance_profile)]
fwrite(design_long, file.path(out, "pseudoboundary_design_estimates.csv"))

profile_est <- design_long[result_type == "profile"]
classification <- profile_est[, {
  legal <- estimate[boundary_center_km == 0]
  offs <- estimate[boundary_center_km != 0]
  list(
    legal_below_all_offsets = length(legal) == 1 && all(legal < offs),
    legal_within_offset_range = length(legal) == 1 &&
      legal >= min(offs) && legal <= max(offs)
  )
}, by = .(design, outcome, governance_profile)]
class_summary <- classification[, .(
  all_profiles_legal_below_offsets = all(legal_below_all_offsets),
  all_profiles_legal_within_range = all(legal_within_offset_range)
), by = .(design, outcome)]
fwrite(class_summary,
       file.path(out, "pseudoboundary_design_classification.csv"))
fwrite(overlap, file.path(out, "pseudoboundary_pairwise_overlap.csv"))

p <- ggplot(profile_est, aes(boundary_center_km, estimate,
                             colour = governance_profile)) +
  geom_hline(yintercept = 0, colour = "grey75") +
  geom_line() + geom_point(aes(shape = boundary_center_km == 0), size = 2) +
  facet_grid(outcome ~ design, scales = "free_y") +
  scale_shape_manual(values = c(`TRUE` = 19, `FALSE` = 1),
                     labels = c(`TRUE` = "Legal boundary",
                                `FALSE` = "Pseudo-boundary")) +
  labs(x = "Boundary centre (signed distance, km)",
       y = "Park-facing minus outward-facing log-odds contrast",
       colour = "Profile", shape = NULL,
       caption = "Offsets overlap spatially and are descriptive diagnostics, not independent replicates.") +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom")
ggsave(file.path(out, "fig_pseudoboundary_design_comparison.pdf"), p,
       width = 13, height = 9)
ggsave(file.path(out, "fig_pseudoboundary_design_comparison.png"), p,
       width = 13, height = 9, dpi = 300)

md <- c(
  "# Pseudo-boundary design comparison",
  "",
  "The implementation was confirmed directly: cells satisfy `abs(signed_distance_km - centre) <= 10`; signed distances below the centre are park-facing and distances at or above the centre are outward-facing.",
  "",
  "- At +5 km the park-facing band is [-5, 5) km and crosses the legal boundary; it mixes inside-park and outside-park cells and is excluded from candidate reporting designs.",
  "- At +10 km the park-facing band is [0, 10) km and the outward band is [10, 20] km. Both are outside under the authoritative signed-distance coding, and the park-facing band touches the legal boundary.",
  "- At +15 km the park-facing band is [5, 15) km and avoids both boundary crossing and immediate 0-5 km adjacency.",
  "- Dense 5 km offsets share cells. Pairwise Jaccard overlap is reported in `pseudoboundary_pairwise_overlap.csv`; the offsets are not independent.",
  "",
  "## Reporting recommendation",
  "",
  "Retain +15 to +60 km in 5 km increments as the complete descriptive sensitivity. Use +15, +25, +35, +45, and +55 km as the parsimonious primary subset because it avoids boundary crossing, avoids immediate adjacency, and spreads coverage without outcome-based selection. Report +10 km only as a boundary-adjacent sensitivity. Exclude +5 km for the 10 km-per-side design. The historical +20/+40/+60 km set may remain for continuity.",
  "",
  "Ranks, event support, balance, fit validity, and profile-level classifications are machine-readable in the accompanying CSV files. Agriculture remains inferentially support-sensitive; ranks are descriptive and are not used to select offsets."
)
writeLines(md, file.path(out, "pseudoboundary_design_comparison.md"))
message("Pseudo-boundary audit complete.")
