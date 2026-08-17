#!/usr/bin/env Rscript

# Hansen 2000-2012 loss-gain overlap and AFCD agricultural persistence.
#
# The Hansen diagnostic is deliberately described as loss-gain overlap rather
# than regrowth: the static gain band has no event year, so temporal ordering
# relative to loss cannot be established. Agriculture uses the annual AFCD
# binary stack that generated the manuscript's first-crossing outcome.

suppressPackageStartupMessages({
  library(data.table)
  library(terra)
  library(ggplot2)
})

source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")

out <- FINAL_SPEC$output_dir
dir.create(out, recursive = TRUE, showWarnings = FALSE)
cache_dir <- file.path(out, "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

spatial <- fr_load_spatial()
timeline <- fr_timeline()
template <- spatial$cov[[1]]

stop_with <- function(...) stop(..., call. = FALSE)

same_geometry <- function(x, y) {
  isTRUE(compareGeom(x, y, stopOnError = FALSE,
                     crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE))
}

# -------------------------------------------------------------------------
# Hansen GFC v1.12: native 30 m loss-gain overlap, 2000-2012
# -------------------------------------------------------------------------

hansen_dir <- file.path(CH1_PROJECT_ROOT, "data", "external",
                        "hansen_gfc_2024_v1_12")
tile_ids <- c("00N_020E", "10S_020E")
gain_files <- file.path(
  hansen_dir,
  paste0("Hansen_GFC-2024-v1.12_gain_", tile_ids, ".tif")
)
loss_files <- file.path(
  hansen_dir,
  paste0("Hansen_GFC-2024-v1.12_lossyear_", tile_ids, ".tif")
)
aoi_path <- file.path(CH1_DATA_ROOT, "data", "studyarea_chapter1.geojson")

missing_hansen <- c(gain_files, loss_files, aoi_path)[
  !file.exists(c(gain_files, loss_files, aoi_path))
]
if (length(missing_hansen)) {
  stop_with("Missing Hansen diagnostic input(s): ",
            paste(missing_hansen, collapse = ", "))
}

aoi <- vect(aoi_path)

crop_tile <- function(path) {
  r <- rast(path)
  av <- project(aoi, crs(r))
  crop(r, ext(av), snap = "out")
}

gain_parts <- lapply(gain_files, crop_tile)
loss_parts <- lapply(loss_files, crop_tile)
if (!all(mapply(same_geometry, gain_parts, loss_parts))) {
  stop_with("Hansen gain and loss-year tiles are not aligned.")
}

gain_native <- do.call(merge, gain_parts)
loss_native <- do.call(merge, loss_parts)
if (!same_geometry(gain_native, loss_native)) {
  stop_with("Merged Hansen gain and loss-year rasters are not aligned.")
}
aoi_native <- project(aoi, crs(gain_native))
gain_native <- mask(crop(gain_native, aoi_native), aoi_native)
loss_native <- mask(crop(loss_native, aoi_native), aoi_native)
names(gain_native) <- "gain_2000_2012"
names(loss_native) <- "lossyear"

loss_0012 <- loss_native >= 1 & loss_native <= 12
gain_0012 <- gain_native == 1
overlap_0012 <- loss_0012 & gain_0012
names(loss_0012) <- "loss_2001_2012"
names(gain_0012) <- "gain_2000_2012"
names(overlap_0012) <- "loss_gain_overlap"

native_global <- global(c(loss_0012, gain_0012, overlap_0012), "sum",
                        na.rm = TRUE)
native_sums <- setNames(native_global[[1]], rownames(native_global))
native_summary <- data.table(
  spatial_unit = "native Hansen pixel",
  domain = "study area",
  period = "gain 2000-2012; loss 2001-2012",
  loss_pixels = as.integer(native_sums[["loss_2001_2012"]]),
  gain_pixels = as.integer(native_sums[["gain_2000_2012"]]),
  overlap_pixels = as.integer(native_sums[["loss_gain_overlap"]])
)
native_summary[, `:=`(
  proportion_loss_pixels_also_gain = overlap_pixels / loss_pixels,
  proportion_gain_pixels_also_loss = overlap_pixels / gain_pixels
)]

# Aggregate exact native-grid binary fractions to the canonical 500 m grid.
hansen_500_path <- file.path(cache_dir,
                             "hansen_loss_gain_fractions_500m.tif")
if (file.exists(hansen_500_path)) {
  hansen_500 <- rast(hansen_500_path)
  if (!same_geometry(hansen_500[[1]], template)) {
    stop_with("Cached Hansen 500 m fractions do not match canonical grid.")
  }
} else {
  hansen_500 <- project(c(loss_0012, gain_0012, overlap_0012), template,
                        method = "average")
  names(hansen_500) <- c("loss_fraction_2001_2012",
                         "gain_fraction_2000_2012",
                         "overlap_fraction_2000_2012")
  writeRaster(hansen_500, hansen_500_path, overwrite = TRUE,
              wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2")))
}

hansen_cells <- copy(spatial$geom)
hvals <- terra::extract(hansen_500, hansen_cells$cell)
hansen_cells[, `:=`(
  loss_fraction_2001_2012 = hvals[["loss_fraction_2001_2012"]],
  gain_fraction_2000_2012 = hvals[["gain_fraction_2000_2012"]],
  overlap_fraction_2000_2012 = hvals[["overlap_fraction_2000_2012"]]
)]
canonical_loss_raw <- fr_extract(
  spatial$cov[["year_deforest_masked"]], hansen_cells$cell
)
hansen_cells[, `:=`(
  forest_eligible_2000 = is.finite(canonical_loss_raw),
  canonical_loss_event_year = fifelse(
    is.finite(canonical_loss_raw) & canonical_loss_raw > 0,
    as.integer(canonical_loss_raw), NA_integer_
  ),
  landscape_group = fifelse(SESU_ID == 1L, "Depression", "Plateau"),
  park_side = side,
  in_5km = abs(signed_distance_km) <= 5,
  in_10km = abs(signed_distance_km) <= 10,
  in_20km = abs(signed_distance_km) <= 20
)]
hansen_cells[, canonical_loss_crossed_25pct_by_2012 :=
               !is.na(canonical_loss_event_year) &
               canonical_loss_event_year <= 2012]
hansen_cells[, any_native_gain := gain_fraction_2000_2012 > 0]
hansen_cells[, any_native_overlap := overlap_fraction_2000_2012 > 0]
hansen_cells[, gain_fraction_ge_10pct := gain_fraction_2000_2012 >= 0.10]
hansen_cells[, gain_fraction_ge_25pct := gain_fraction_2000_2012 >= 0.25]
hansen_cells[, gain_fraction_ge_50pct := gain_fraction_2000_2012 >= 0.50]
hansen_cells <- merge(
  hansen_cells,
  timeline[, .(SESU_ID, canonical_loss_event_year = year,
               governance_profile_at_loss = governance_profile)],
  by = c("SESU_ID", "canonical_loss_event_year"), all.x = TRUE
)

fwrite(hansen_cells[
         forest_eligible_2000 == TRUE &
           canonical_loss_crossed_25pct_by_2012 == TRUE
       ],
       file.path(out, "hansen_loss_gain_overlap_cell_metrics.csv"))

domain_rows <- rbindlist(list(
  hansen_cells[in_5km == TRUE][, corridor_domain := "5km"],
  hansen_cells[in_10km == TRUE][, corridor_domain := "10km"],
  hansen_cells[in_20km == TRUE][, corridor_domain := "20km"],
  hansen_cells[, corridor_domain := "full"]
), fill = TRUE)

cell_summary <- domain_rows[forest_eligible_2000 == TRUE, .(
  eligible_500m_cells = .N,
  loss_crossing_cells_by_2012 = sum(canonical_loss_crossed_25pct_by_2012),
  loss_crossing_cells_with_any_gain =
    sum(canonical_loss_crossed_25pct_by_2012 & any_native_gain,
        na.rm = TRUE),
  loss_crossing_cells_with_any_overlap =
    sum(canonical_loss_crossed_25pct_by_2012 & any_native_overlap,
        na.rm = TRUE),
  median_gain_fraction_among_loss_crossing_cells = {
    z <- gain_fraction_2000_2012[canonical_loss_crossed_25pct_by_2012]
    if (length(z)) median(z, na.rm = TRUE) else NA_real_
  },
  q25_gain_fraction_among_loss_crossing_cells = {
    z <- gain_fraction_2000_2012[canonical_loss_crossed_25pct_by_2012]
    if (length(z)) as.numeric(quantile(z, 0.25, na.rm = TRUE)) else NA_real_
  },
  q75_gain_fraction_among_loss_crossing_cells = {
    z <- gain_fraction_2000_2012[canonical_loss_crossed_25pct_by_2012]
    if (length(z)) as.numeric(quantile(z, 0.75, na.rm = TRUE)) else NA_real_
  },
  gain_ge_10pct_cells = sum(canonical_loss_crossed_25pct_by_2012 &
                              gain_fraction_ge_10pct, na.rm = TRUE),
  gain_ge_25pct_cells = sum(canonical_loss_crossed_25pct_by_2012 &
                              gain_fraction_ge_25pct, na.rm = TRUE),
  gain_ge_50pct_cells = sum(canonical_loss_crossed_25pct_by_2012 &
                              gain_fraction_ge_50pct, na.rm = TRUE)
), by = .(corridor_domain, park_side, landscape_group,
          governance_profile_at_loss)]
cell_summary[, `:=`(
  proportion_loss_crossing_cells_with_any_gain =
    loss_crossing_cells_with_any_gain / loss_crossing_cells_by_2012,
  proportion_loss_crossing_cells_with_any_overlap =
    loss_crossing_cells_with_any_overlap / loss_crossing_cells_by_2012
)]

cell_overall <- domain_rows[
  forest_eligible_2000 == TRUE & canonical_loss_crossed_25pct_by_2012 == TRUE,
  .(
    loss_crossing_cells_by_2012 = .N,
    loss_crossing_cells_with_any_gain = sum(any_native_gain, na.rm = TRUE),
    loss_crossing_cells_with_any_overlap = sum(any_native_overlap, na.rm = TRUE),
    median_gain_fraction = median(gain_fraction_2000_2012, na.rm = TRUE),
    mean_gain_fraction = mean(gain_fraction_2000_2012, na.rm = TRUE),
    gain_ge_10pct_cells = sum(gain_fraction_ge_10pct, na.rm = TRUE),
    gain_ge_25pct_cells = sum(gain_fraction_ge_25pct, na.rm = TRUE),
    gain_ge_50pct_cells = sum(gain_fraction_ge_50pct, na.rm = TRUE)
  ),
  by = corridor_domain
]
cell_overall[, `:=`(
  proportion_with_any_gain =
    loss_crossing_cells_with_any_gain / loss_crossing_cells_by_2012,
  proportion_with_any_overlap =
    loss_crossing_cells_with_any_overlap / loss_crossing_cells_by_2012
)]

native_summary[, `:=`(
  corridor_domain = "native_AOI",
  park_side = "all",
  landscape_group = "all",
  governance_profile_at_loss = "not assigned"
)]
fwrite(native_summary,
       file.path(out, "hansen_native_loss_gain_overlap_summary.csv"))
fwrite(cell_summary,
       file.path(out, "hansen_loss_gain_overlap_summary.csv"))
fwrite(cell_overall,
       file.path(out, "hansen_loss_gain_overlap_overall.csv"))

hansen_diag <- data.table(
  diagnostic = c(
    "gain_loss_native_geometry_identical",
    "hansen_500m_geometry_matches_canonical",
    "gain_period_start", "gain_period_end",
    "loss_overlap_period_start", "loss_overlap_period_end",
    "temporal_order_identifiable"
  ),
  value = c(
    as.character(same_geometry(gain_native, loss_native)),
    as.character(same_geometry(hansen_500[[1]], template)),
    "2000", "2012", "2001", "2012", "FALSE"
  )
)
fwrite(hansen_diag,
       file.path(out, "hansen_loss_gain_overlap_diagnostics.csv"))

plot_hansen <- cell_summary[
  corridor_domain == "10km" & !is.na(governance_profile_at_loss) &
    loss_crossing_cells_by_2012 > 0
]
plot_hansen[, profile_label := factor(
  FINAL_SPEC$profile_public_labels[governance_profile_at_loss],
  levels = unname(FINAL_SPEC$profile_public_labels)
)]
p_hansen <- ggplot(
  plot_hansen,
  aes(profile_label,
      proportion_loss_crossing_cells_with_any_overlap,
      fill = park_side)
) +
  geom_col(position = position_dodge(width = 0.75), width = 0.66) +
  facet_wrap(~landscape_group) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                     limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  scale_fill_manual(values = c(inside = "#4C6A92", outside = "#B3B3B3"),
                    labels = c(inside = "Inside", outside = "Outside"),
                    name = "Park side") +
  labs(
    x = "Territorial-control profile at loss crossing",
    y = "Cells containing native loss-gain overlap",
    subtitle = "Among 500 m cells crossing 25% cumulative loss by 2012; 10 km corridor"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")
ggsave(file.path(out, "fig_hansen_loss_gain_overlap.pdf"), p_hansen,
       width = 8.5, height = 5.2)
ggsave(file.path(out, "fig_hansen_loss_gain_overlap.png"), p_hansen,
       width = 8.5, height = 5.2, dpi = 300)

hansen_methods <- c(
  "# Hansen loss-gain overlap diagnostic",
  "",
  "## Scope",
  "",
  "This is a measurement diagnostic, not an estimate of post-loss regrowth. Hansen Global Forest Change v1.12 supplies a static gain flag for 2000-2012 and annual loss-year coding. The gain flag has no year, so pixels carrying both flags cannot be temporally ordered.",
  "",
  "## Implementation",
  "",
  "- Matching v1.12 gain and loss-year tiles were used on their common native grid.",
  "- Native overlap is `gain == 1` and `lossyear` in 1-12 (loss in 2001-2012).",
  "- Native binary loss, gain, and overlap indicators were averaged onto the canonical 500 m grid.",
  "- Cell summaries are restricted to the manuscript's baseline-forest eligibility mask and separately identify cells whose cumulative loss crossed 25% by 2012.",
  "- Any overlap means at least one native Hansen pixel in the 500 m cell carried both flags; threshold summaries at 10%, 25%, and 50% are also retained.",
  "",
  "## Interpretation constraint",
  "",
  "A loss-gain overlap pixel may represent gain before loss, loss before gain, classification discordance, or multiple changes within the period. It must not be described as confirmed regrowth or recovery, and it does not alter the manuscript estimand of first cumulative mapped-loss threshold crossing."
)
writeLines(hansen_methods,
           file.path(out, "hansen_loss_gain_methods.md"))

tree_feasibility <- c(
  "# Tree-cover post-loss/regrowth feasibility",
  "",
  "## Decision",
  "",
  "Confirmed post-loss regrowth remains unidentifiable from Hansen Global Forest Change because the gain flag has no year. A limited, reproducible 2000-2012 loss-gain overlap diagnostic has nevertheless been completed.",
  "",
  "## Available diagnostic",
  "",
  "Matching Hansen GFC v1.12 native gain and loss-year tiles were intersected over the study area. Results are reported in `hansen_native_loss_gain_overlap_summary.csv`, `hansen_loss_gain_overlap_overall.csv`, and the stratified cell summary. Temporal order is not inferred.",
  "",
  "## Remaining data need",
  "",
  "A defensible recovery analysis still requires an annual, consistently processed canopy or woody-cover product spanning the relevant pre/post-event years, with quality flags and a recovery rule declared before analysis.",
  "",
  "The manuscript estimand remains the first year cumulative mapped Hansen loss crosses 25% among cells with at least 30% tree cover in 2000. The overlap diagnostic does not reverse or redefine that event."
)
writeLines(tree_feasibility,
           file.path(out, "tree_regrowth_feasibility.md"))

# -------------------------------------------------------------------------
# AFCD annual agricultural persistence and persistent first establishment
# -------------------------------------------------------------------------

afcd_path <- file.path(CH1_DATA_ROOT, "data", "AFCD_stack.tif")
if (!file.exists(afcd_path)) stop_with("Annual AFCD stack is missing: ", afcd_path)
afcd <- rast(afcd_path)
afcd_years <- suppressWarnings(as.integer(names(afcd)))
if (anyNA(afcd_years)) {
  afcd_years <- suppressWarnings(as.integer(
    sub(".*?([12][0-9]{3}).*", "\\1", names(afcd))
  ))
}
required_afcd_years <- 2000L:2022L
if (!identical(sort(afcd_years), required_afcd_years)) {
  stop_with("AFCD must contain exactly annual layers 2000-2022; found: ",
            paste(afcd_years, collapse = ", "))
}
afcd <- afcd[[match(required_afcd_years, afcd_years)]]
names(afcd) <- as.character(required_afcd_years)

afcd_fraction_path <- file.path(cache_dir,
                                "afcd_cropland_fraction_500m_2000_2022.tif")
if (file.exists(afcd_fraction_path)) {
  afcd_fraction <- rast(afcd_fraction_path)
  if (!same_geometry(afcd_fraction[[1]], template) ||
      nlyr(afcd_fraction) != length(required_afcd_years)) {
    stop_with("Cached AFCD fraction stack does not match canonical grid/years.")
  }
} else {
  aoi_afcd <- project(aoi, crs(afcd))
  afcd_crop <- mask(crop(afcd, ext(aoi_afcd), snap = "out"), aoi_afcd)
  afcd_binary <- ifel(afcd_crop == 1, 1, 0)
  afcd_fraction <- project(afcd_binary, template, method = "average")
  names(afcd_fraction) <- as.character(required_afcd_years)
  writeRaster(afcd_fraction, afcd_fraction_path, overwrite = TRUE,
              wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2")))
}
names(afcd_fraction) <- as.character(required_afcd_years)

frac_mat <- as.matrix(terra::extract(afcd_fraction, spatial$geom$cell))
colnames(frac_mat) <- as.character(required_afcd_years)
if (nrow(frac_mat) != nrow(spatial$geom)) stop_with("AFCD extraction row mismatch.")

first_transition <- function(x, tau, persistent = FALSE) {
  above <- is.finite(x) & x >= tau
  crossing <- above[-1L] & !above[-length(above)]
  candidate <- which(crossing) + 1L
  if (!persistent) {
    return(if (length(candidate)) required_afcd_years[candidate[1L]] else NA_integer_)
  }
  qualifies <- vapply(candidate, function(k) {
    # At least years +1 and +2 must exist. Persistence is >=tau in two of the
    # next three observed years, including at least one of +1 or +2.
    if (k + 2L > length(x)) return(FALSE)
    post_idx <- seq.int(k + 1L, min(k + 3L, length(x)))
    post <- x[post_idx]
    if (any(!is.finite(post))) return(FALSE)
    sum(post >= tau) >= 2L && any(x[k + c(1L, 2L)] >= tau)
  }, logical(1))
  candidate <- candidate[qualifies]
  if (length(candidate)) required_afcd_years[candidate[1L]] else NA_integer_
}

computed_first_025 <- apply(frac_mat, 1, first_transition, tau = 0.25,
                            persistent = FALSE)
canonical_agri_raw <- fr_extract(spatial$cov[["year_agri"]], spatial$geom$cell)
canonical_first_025 <- fifelse(
  is.finite(canonical_agri_raw) & canonical_agri_raw > 0,
  as.integer(canonical_agri_raw), NA_integer_
)
comparison_ok <- (is.na(computed_first_025) & is.na(canonical_first_025)) |
  computed_first_025 == canonical_first_025
comparison_ok[is.na(comparison_ok)] <- FALSE
if (!all(comparison_ok)) {
  mismatch <- sum(!comparison_ok)
  stop_with("AFCD annual fractions fail canonical first-crossing validation: ",
            mismatch, " cell(s) differ.")
}

event_idx <- which(!is.na(canonical_first_025))
events <- copy(spatial$geom[event_idx])
events[, event_year := canonical_first_025[event_idx]]
events[, `:=`(
  landscape_group = fifelse(SESU_ID == 1L, "Depression", "Plateau"),
  park_side = side,
  in_5km = abs(signed_distance_km) <= 5,
  in_10km = abs(signed_distance_km) <= 10,
  in_20km = abs(signed_distance_km) <= 20
)]

value_at <- function(row_index, year) {
  out_value <- rep(NA_real_, length(row_index))
  good <- year %in% required_afcd_years
  if (any(good)) {
    out_value[good] <- frac_mat[cbind(row_index[good],
                                     match(year[good], required_afcd_years))]
  }
  out_value
}

events[, source_row := event_idx]
events[, `:=`(
  cropland_fraction_year_minus1 = value_at(source_row, event_year - 1L),
  cropland_fraction_year0 = value_at(source_row, event_year),
  cropland_fraction_year_plus1 = value_at(source_row, event_year + 1L),
  cropland_fraction_year_plus2 = value_at(source_row, event_year + 2L),
  cropland_fraction_year_plus3 = value_at(source_row, event_year + 3L)
)]

classify_postevent <- function(event_year, p1, p2, p3, tau = 0.25) {
  n <- length(event_year)
  ans <- rep("missing/uncertain", n)
  reason <- rep("annual source observation unavailable or invalid", n)
  for (i in seq_len(n)) {
    if (event_year[i] > 2020L) {
      ans[i] <- "right-censored"
      reason[i] <- "fewer than two post-event years available by 2022"
      next
    }
    if (!is.finite(p1[i]) || !is.finite(p2[i]) ||
        (event_year[i] <= 2019L && !is.finite(p3[i]))) next
    post <- c(p1[i], p2[i], p3[i])
    post <- post[is.finite(post)]
    if (sum(post >= tau) >= 2L && (p1[i] >= tau || p2[i] >= tau)) {
      ans[i] <- "persistent"
      reason[i] <- "at or above threshold in at least two post-event years, including +1 or +2"
    } else if (p1[i] < tau && p2[i] < tau) {
      ans[i] <- "transient/reversed"
      reason[i] <- "below threshold in both years +1 and +2"
    } else {
      ans[i] <- "intermittent"
      reason[i] <- "crosses the threshold post-event but meets neither persistence nor reversal rule"
    }
  }
  list(class = ans, reason = reason)
}

cls <- classify_postevent(
  events$event_year,
  events$cropland_fraction_year_plus1,
  events$cropland_fraction_year_plus2,
  events$cropland_fraction_year_plus3,
  tau = 0.25
)
events[, `:=`(postevent_class = cls$class,
              classification_reason = cls$reason)]
events <- merge(
  events,
  timeline[, .(SESU_ID, event_year = year,
               governance_profile_at_event = governance_profile)],
  by = c("SESU_ID", "event_year"), all.x = TRUE
)
events[, source_row := NULL]
setcolorder(events, c("cell", "event_year", "SESU_ID", "landscape_group",
                      "park_side", "signed_distance_km",
                      "governance_profile_at_event", "postevent_class",
                      "classification_reason"))
fwrite(events, file.path(out, "agriculture_postevent_classification.csv"))

expanded_events <- rbindlist(list(
  events[in_5km == TRUE][, corridor_domain := "5km"],
  events[in_10km == TRUE][, corridor_domain := "10km"],
  events[in_20km == TRUE][, corridor_domain := "20km"],
  events[, corridor_domain := "full"]
), fill = TRUE)

agri_summary <- expanded_events[, .(
  event_cells = .N,
  persistent = sum(postevent_class == "persistent"),
  transient_reversed = sum(postevent_class == "transient/reversed"),
  intermittent = sum(postevent_class == "intermittent"),
  right_censored = sum(postevent_class == "right-censored"),
  missing_uncertain = sum(postevent_class == "missing/uncertain"),
  classifiable_fraction = mean(!postevent_class %in%
                                 c("missing/uncertain", "right-censored")),
  persistent_fraction_among_classifiable = {
    den <- sum(!postevent_class %in% c("missing/uncertain", "right-censored"))
    if (den) sum(postevent_class == "persistent") / den else NA_real_
  }
), by = .(park_side, governance_profile_at_event, landscape_group,
          event_year, corridor_domain)]
fwrite(agri_summary, file.path(out, "agriculture_persistence_summary.csv"))

sens_rules <- data.table(
  rule_id = c(
    "year_plus1_at_or_above_25pct",
    "two_consecutive_postevent_years_at_or_above_25pct",
    "two_of_three_including_plus1_or_plus2_tau010",
    "two_of_three_including_plus1_or_plus2_tau025",
    "two_of_three_including_plus1_or_plus2_tau050"
  ),
  tau = c(0.25, 0.25, 0.10, 0.25, 0.50)
)

eval_rule <- function(d, rule_id, tau) {
  p1 <- d$cropland_fraction_year_plus1
  p2 <- d$cropland_fraction_year_plus2
  p3 <- d$cropland_fraction_year_plus3
  if (rule_id == "year_plus1_at_or_above_25pct") {
    eligible <- is.finite(p1)
    hit <- p1 >= tau
  } else if (rule_id ==
             "two_consecutive_postevent_years_at_or_above_25pct") {
    eligible <- is.finite(p1) & is.finite(p2)
    hit <- (p1 >= tau & p2 >= tau) |
      (is.finite(p2) & is.finite(p3) & p2 >= tau & p3 >= tau)
  } else {
    eligible <- is.finite(p1) & is.finite(p2)
    hit <- rowSums(cbind(p1, p2, p3) >= tau, na.rm = TRUE) >= 2L &
      (p1 >= tau | p2 >= tau)
  }
  data.table(
    status = if (sum(eligible)) "estimated" else "not_estimable",
    numerator = sum(hit & eligible, na.rm = TRUE),
    denominator = sum(eligible),
    proportion = if (sum(eligible)) sum(hit & eligible, na.rm = TRUE) /
      sum(eligible) else NA_real_,
    reason = if (sum(eligible)) "" else "no cells with required post-event follow-up"
  )
}

agri_sensitivity <- rbindlist(lapply(
  c("5km", "10km", "20km", "full"), function(domain) {
    d <- expanded_events[corridor_domain == domain]
    rbindlist(lapply(seq_len(nrow(sens_rules)), function(i) {
      cbind(
        data.table(rule_id = sens_rules$rule_id[i],
                   corridor_domain = domain),
        eval_rule(d, sens_rules$rule_id[i], sens_rules$tau[i])
      )
    }))
  }
))

# Threshold-consistent persistence starts from first transitions at each tau.
threshold_sens <- rbindlist(lapply(c(0.10, 0.25, 0.50), function(tau) {
  ev <- apply(frac_mat, 1, first_transition, tau = tau, persistent = FALSE)
  idx <- which(!is.na(ev))
  if (!length(idx)) return(NULL)
  tmp <- data.table(
    source_row = idx,
    event_year = ev[idx],
    signed_distance_km = spatial$geom$signed_distance_km[idx]
  )
  tmp[, `:=`(
    p1 = value_at(source_row, event_year + 1L),
    p2 = value_at(source_row, event_year + 2L),
    p3 = value_at(source_row, event_year + 3L)
  )]
  tmp[, corridor_domain := "full"]
  all_domains <- rbindlist(list(
    tmp[abs(signed_distance_km) <= 5][, corridor_domain := "5km"],
    tmp[abs(signed_distance_km) <= 10][, corridor_domain := "10km"],
    tmp[abs(signed_distance_km) <= 20][, corridor_domain := "20km"],
    tmp
  ))
  all_domains[, {
    eligible <- is.finite(p1) & is.finite(p2)
    hit <- rowSums(cbind(p1, p2, p3) >= tau, na.rm = TRUE) >= 2L &
      (p1 >= tau | p2 >= tau)
    .(rule_id = sprintf("threshold_consistent_persistence_tau%03d",
                        as.integer(tau * 100)),
      status = if (sum(eligible)) "estimated" else "not_estimable",
      numerator = sum(hit & eligible, na.rm = TRUE),
      denominator = sum(eligible),
      proportion = if (sum(eligible)) sum(hit & eligible, na.rm = TRUE) /
        sum(eligible) else NA_real_,
      reason = if (sum(eligible)) "" else
        "no cells with required post-event follow-up")
  }, by = corridor_domain]
}))
agri_sensitivity <- rbindlist(list(agri_sensitivity, threshold_sens),
                              fill = TRUE)
fwrite(agri_sensitivity,
       file.path(out, "agriculture_persistence_sensitivity.csv"))

persistent_first_025 <- apply(frac_mat, 1, first_transition, tau = 0.25,
                              persistent = TRUE)
geom10 <- fr_design_cells(spatial, FINAL_SPEC$primary_corridor_km)
match10 <- match(geom10$cell, spatial$geom$cell)
persistent_ev10 <- persistent_first_025[match10]

surface_from_event_vector <- function(geom, event_year, timeline) {
  z <- vector("list", length(FINAL_SPEC$years))
  for (i in seq_along(FINAL_SPEC$years)) {
    yr <- FINAL_SPEC$years[i]
    keep <- is.na(event_year) | yr <= event_year
    d <- geom[keep]
    d[, `:=`(
      year = yr,
      y_cell = as.integer(!is.na(event_year[keep]) & event_year[keep] == yr)
    )]
    z[[i]] <- d[, .(n = .N, y = sum(y_cell)),
                  by = .(SESU_ID, year, side)]
  }
  ans <- rbindlist(z)
  ans[, outcome := "agriculture_persistent_first_establishment"]
  merge(ans, timeline[, .(SESU_ID, year, governance_profile)],
        by = c("SESU_ID", "year"), all.x = TRUE)
}

persistent_surface <- surface_from_event_vector(
  geom10, persistent_ev10, timeline
)
event_profile_support <- persistent_surface[, .(events = sum(y)),
                                            by = governance_profile]
adequate_support <- sum(persistent_surface$y) >= 30L &&
  nrow(event_profile_support) == length(FINAL_SPEC$profile_levels) &&
  all(event_profile_support$events >= 5L)

if (adequate_support) {
  persistent_fit <- fr_fit_sparse(
    persistent_surface, weighted = TRUE,
    run_id = "agriculture_persistent_first_establishment_tau025_10km"
  )
  model_profile <- copy(persistent_fit$profile)
  model_profile[, `:=`(
    contrast_type = "profile",
    profile_or_comparison = governance_profile
  )]
  model_pair <- copy(persistent_fit$pair)
  model_pair[, `:=`(
    contrast_type = "pairwise",
    profile_or_comparison = profile_comparison
  )]
  model_out <- rbindlist(list(model_profile, model_pair), fill = TRUE)
  model_out[, `:=`(
    threshold = 0.25,
    corridor_domain = "10km",
    weighting = "inverse_variance",
    covariance = "HC3"
  )]
  fit_diag <- copy(persistent_fit$diagnostics)
} else {
  model_out <- data.table(
    run_id = "agriculture_persistent_first_establishment_tau025_10km",
    outcome = "agriculture_persistent_first_establishment",
    contrast_type = "profile",
    profile_or_comparison = FINAL_SPEC$profile_levels,
    estimate = NA_real_, standard_error = NA_real_,
    conf_low = NA_real_, conf_high = NA_real_, odds_ratio = NA_real_,
    threshold = 0.25, corridor_domain = "10km",
    weighting = "inverse_variance", covariance = "HC3"
  )
  fit_diag <- data.table(
    run_id = "agriculture_persistent_first_establishment_tau025_10km",
    outcome = "agriculture_persistent_first_establishment",
    model = "inverse_variance_weighted_lm_hc3",
    fit_status = "insufficient_event_support",
    warning_messages = paste0(
      "Predeclared support rule not met: require >=30 events overall and ",
      ">=5 in every governance profile."
    )
  )
}
fwrite(model_out, file.path(out, "agriculture_persistent_event_model.csv"))

fit_diag[, `:=`(
  canonical_first_crossing_cells_full = sum(!is.na(canonical_first_025)),
  canonical_first_crossing_cells_10km =
    sum(!is.na(canonical_first_025) &
          abs(spatial$geom$signed_distance_km) <= 10),
  persistent_first_establishment_cells_full =
    sum(!is.na(persistent_first_025)),
  persistent_first_establishment_cells_10km =
    sum(!is.na(persistent_ev10)),
  minimum_total_events_rule = 30L,
  minimum_events_per_profile_rule = 5L,
  support_rule_passed = adequate_support,
  annual_fraction_validation_mismatches = sum(!comparison_ok)
)]
fwrite(fit_diag,
       file.path(out, "agriculture_persistent_event_diagnostics.csv"))

plot_agri <- expanded_events[
  corridor_domain == "10km" &
    !postevent_class %in% c("missing/uncertain", "right-censored"),
  .N,
  by = .(governance_profile_at_event, park_side, postevent_class)
]
plot_agri[, proportion := N / sum(N),
          by = .(governance_profile_at_event, park_side)]
plot_agri[, profile_label := factor(
  FINAL_SPEC$profile_public_labels[governance_profile_at_event],
  levels = unname(FINAL_SPEC$profile_public_labels)
)]
plot_agri[, postevent_class := factor(
  postevent_class,
  levels = c("persistent", "intermittent", "transient/reversed")
)]
p_agri <- ggplot(plot_agri,
                 aes(profile_label, proportion, fill = postevent_class)) +
  geom_col(width = 0.72) +
  facet_wrap(~park_side) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(
    values = c("persistent" = "#4C6A92", "intermittent" = "#D1B36A",
               "transient/reversed" = "#B8B8B8"),
    labels = c("Persistent", "Intermittent", "Transient/reversed"),
    name = "Post-event class"
  ) +
  labs(
    x = "Territorial-control profile at first crossing",
    y = "Share of classifiable first-crossing cells",
    subtitle = "Primary 25% threshold and 10 km corridor"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")
ggsave(file.path(out, "fig_agriculture_persistence.pdf"), p_agri,
       width = 8.5, height = 5.2)
ggsave(file.path(out, "fig_agriculture_persistence.png"), p_agri,
       width = 8.5, height = 5.2, dpi = 300)

agri_methods <- c(
  "# Agricultural persistence methods",
  "",
  "The annual AFCD binary stack for 2000-2022 was aggregated to the canonical 500 m grid by averaging native binary cropland presence. The reconstructed first transition from below 25% to at least 25% was required to reproduce the canonical event-year raster exactly before any persistence result was accepted.",
  "",
  "The primary post-event classification uses the predeclared rule: persistent means at least 25% cropland in at least two of the next three observed years, including at least one of years +1 or +2. Transient/reversed means below 25% in both +1 and +2. Other threshold alternation is intermittent. Events after 2020 are right-censored because fewer than two post-event years remain.",
  "",
  "Persistent first establishment is the first below-to-at-least-25% transition satisfying that same future-persistence rule. Its boundary model uses the final primary 10 km risk set, Haldane-Anscombe correction, inverse-variance weighting, and HC3 covariance. The model is fitted only if there are at least 30 events overall and at least five events under every governance profile.",
  "",
  "A decline below the mapped cropland threshold is a classification reversal, not proof of agricultural abandonment, ecological recovery, or forest regrowth."
)
writeLines(agri_methods,
           file.path(out, "agriculture_persistence_methods.md"))

message("Hansen loss-gain and agricultural persistence diagnostics complete.")
