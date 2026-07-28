suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")

out <- FINAL_SPEC$output_dir
spatial <- fr_load_spatial()
timeline <- fr_timeline()

# Hansen loss is cumulative. The retained repository inputs include a
# tree-cover-2000 baseline and first-crossing event-year rasters, but no annual
# regrowth-sensitive canopy/vegetation metric.
tree_report <- c(
  "# Tree-cover post-loss/regrowth feasibility",
  "",
  "## Decision",
  "",
  "A post-loss regrowth trajectory is not estimable from the available repository data. No trajectory or recovery percentage has been fabricated.",
  "",
  "## Search and suitability audit",
  "",
  "- The prepared 500 m stack contains `forest2000_ge_30pct` and `year_deforest_masked` but no annual canopy, woody-cover, vegetation-fraction, NDVI, EVI, or annual land-cover series.",
  "- The restricted data root contains `gfc_treecover2000_meanpct_500m_epsg32735.tif` and cumulative Hansen first-crossing products. These establish baseline eligibility and event timing, not regrowth.",
  "- Repository inventories and scripts contain no validated annual regrowth-sensitive product with 2001-2022 coverage aligned to the 500 m analytical grid.",
  "- Hansen Global Forest Change loss is cumulative; reversing or subtracting cumulative loss would not measure regrowth and was not attempted.",
  "",
  "## Data needed",
  "",
  "A defensible analysis would require an annual, consistently processed canopy/woody-cover or vegetation-fraction product spanning at least 1998-2022 (to cover event time -3 to +5 where possible), aligned to the 500 m grid, with documented sensor harmonisation, observation quality/missingness flags, and an ecologically justified recovery rule declared before analysis. A reproducible acquisition and validation workflow would also be required.",
  "",
  "The manuscript estimand therefore remains the first year cumulative mapped Hansen loss crosses 25% among cells with at least 30% tree cover in 2000. This is not an annual forest-condition or recovery estimand."
)
writeLines(tree_report, file.path(out, "tree_regrowth_feasibility.md"))

# The annual AFCD cropland fraction stack used upstream is not retained at the
# configured data root. Preserve every observable event cell and mark the
# requested post-event classification missing/uncertain.
event_year <- as.integer(fr_extract(
  spatial$cov[["year_agri"]], spatial$geom$cell))
event_year[!is.finite(event_year) | event_year <= 0] <- NA_integer_
events <- copy(spatial$geom[!is.na(event_year)])
events[, event_year := event_year[!is.na(event_year)]]
events <- merge(events,
  timeline[, .(SESU_ID, event_year = year,
               governance_profile_at_event = governance_profile)],
  by = c("SESU_ID", "event_year"), all.x = TRUE)
events[, `:=`(
  landscape_group = fifelse(SESU_ID == 1L, "Depression", "Plateau"),
  park_side = side,
  cropland_fraction_year_minus1 = NA_real_,
  cropland_fraction_year0 = NA_real_,
  cropland_fraction_year_plus1 = NA_real_,
  cropland_fraction_year_plus2 = NA_real_,
  cropland_fraction_year_plus3 = NA_real_,
  postevent_class = "missing/uncertain",
  classification_reason =
    "annual AFCD cropland-fraction source unavailable; event-year raster alone is insufficient",
  right_censored_by_calendar = event_year > max(FINAL_SPEC$years) - 2L,
  in_5km = abs(signed_distance_km) <= 5,
  in_10km = abs(signed_distance_km) <= 10,
  in_20km = abs(signed_distance_km) <= 20
)]
setcolorder(events, c("cell", "event_year", "SESU_ID", "landscape_group",
                      "park_side", "signed_distance_km",
                      "governance_profile_at_event", "postevent_class",
                      "classification_reason"))
fwrite(events,
       file.path(out, "agriculture_postevent_classification.csv"))

expanded <- rbindlist(list(
  events[, corridor_domain := "5km"][in_5km == TRUE],
  events[, corridor_domain := "10km"][in_10km == TRUE],
  events[, corridor_domain := "20km"][in_20km == TRUE],
  events[, corridor_domain := "full"]
), fill = TRUE)
summary <- expanded[, .(
  event_cells = .N,
  persistent = sum(postevent_class == "persistent"),
  transient_reversed = sum(postevent_class == "transient/reversed"),
  intermittent = sum(postevent_class == "intermittent"),
  right_censored = sum(postevent_class == "right-censored"),
  missing_uncertain = sum(postevent_class == "missing/uncertain"),
  classifiable_fraction = mean(postevent_class != "missing/uncertain")
), by = .(park_side, governance_profile_at_event, landscape_group,
          event_year, corridor_domain)]
fwrite(summary, file.path(out, "agriculture_persistence_summary.csv"))

sensitivity <- CJ(
  rule_id = c("year_plus1_at_or_above_25pct",
              "two_consecutive_postevent_years_at_or_above_25pct",
              "two_of_three_including_plus1_or_plus2_tau010",
              "two_of_three_including_plus1_or_plus2_tau025",
              "two_of_three_including_plus1_or_plus2_tau050"),
  corridor_domain = c("5km", "10km", "20km", "full")
)
sensitivity[, `:=`(
  status = "not_estimable",
  numerator = NA_integer_, denominator = NA_integer_,
  proportion = NA_real_,
  reason = "annual cropland fractions are unavailable"
)]
fwrite(sensitivity,
       file.path(out, "agriculture_persistence_sensitivity.csv"))

model <- data.table(
  outcome = "agriculture_persistent_first_establishment",
  governance_profile = FINAL_SPEC$profile_levels,
  estimate = NA_real_, standard_error = NA_real_,
  conf_low = NA_real_, conf_high = NA_real_,
  odds_ratio = NA_real_, fit_status = "not_estimable"
)
fwrite(model, file.path(out, "agriculture_persistent_event_model.csv"))
diagnostics <- data.table(
  model = "persistent first establishment; 25%; 10 km; weighted HC3",
  fit_status = "not_estimable",
  eligible_event_cells = nrow(events),
  classifiable_event_cells = 0L,
  persistent_event_cells = NA_integer_,
  warning_messages =
    "annual AFCD cropland-fraction stack unavailable; no persistent-event model fitted"
)
fwrite(diagnostics,
       file.path(out, "agriculture_persistent_event_diagnostics.csv"))

p <- ggplot(data.table(x = 0, y = 0), aes(x, y)) +
  annotate("text", x = 0, y = 0,
    label = paste(
      "Agricultural persistence not estimable",
      "Annual AFCD cropland fractions are unavailable;",
      "first-crossing event cells are retained as missing/uncertain.",
      sep = "\n"), size = 4) +
  xlim(-1, 1) + ylim(-1, 1) + theme_void()
ggsave(file.path(out, "fig_agriculture_persistence.pdf"), p,
       width = 8, height = 4.5)
ggsave(file.path(out, "fig_agriculture_persistence.png"), p,
       width = 8, height = 4.5, dpi = 300)

message("Post-event feasibility audit complete.")

