# ===========================================================
# CHAPTER 1 SPATIAL AND THRESHOLD SENSITIVITY WORKFLOW
# ===========================================================
# Phase 3 workflow. Reconstructs threshold-specific outcomes and
# symmetric boundary samples without changing governance assignments,
# thresholds, SESU clustering, or Phase 1/2 outputs.
# ===========================================================

suppressPackageStartupMessages({
  library(data.table)
  library(terra)
  library(glmmTMB)
  library(ggplot2)
})

script_path <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/"), error = function(e) NA_character_)
if (is.na(script_path)) {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) script_path <- normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/")
}
script_dir <- if (!is.na(script_path)) dirname(script_path) else getwd()
config_path <- normalizePath(file.path(script_dir, "..", "..", "config", "analysis_config.R"), winslash = "/", mustWork = TRUE)
source(config_path)

zcrit <- qnorm(1 - CH1_ALPHA / 2)
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")
pairwise_comparisons <- c(
  "Park dominant minus Neither actor dominant",
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)

ensure_dir <- function(path) dir.create(path, recursive = TRUE, showWarnings = FALSE)
stop_missing <- function(path) if (!file.exists(path)) stop("Missing required file or directory: ", path, call. = FALSE)
extract_cells_vec <- function(x, cells) {
  ex <- terra::extract(x, cells)
  if (is.data.frame(ex)) return(as.vector(ex[, ncol(ex)]))
  as.vector(ex)
}
safe_tag <- function(x) gsub("[^A-Za-z0-9_.-]+", "_", x)

invisible(lapply(c(
  CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, CH1_SPATIAL_THRESHOLD_TABLES_DIR,
  CH1_SPATIAL_THRESHOLD_MODELS_DIR, CH1_SPATIAL_THRESHOLD_FIGURES_DIR,
  CH1_SPATIAL_THRESHOLD_LOGS_DIR, CH1_SPATIAL_THRESHOLD_PROVENANCE_DIR
), ensure_dir))

manifest_path <- file.path(CH1_ROOT, "config", "disturbance_threshold_manifest.csv")
stop_missing(manifest_path)
manifest <- fread(manifest_path)
manifest[, abs_path := normalizePath(file.path(CH1_ROOT, file_path), winslash = "/", mustWork = FALSE)]

cov_path <- file.path(CH1_RUN_DIR, "SESU_covariates_500m.tif")
sesu_path <- file.path(CH1_RUN_DIR, "SESU_ID_500m.tif")
stop_missing(cov_path)
stop_missing(sesu_path)
r_cov <- rast(cov_path)
r_sesu <- rast(sesu_path)
template <- r_cov[[1]]

raster_meta <- function(path) {
  if (!file.exists(path)) {
    return(data.table(
      exists = FALSE, crs = NA_character_, resolution_x = NA_real_, resolution_y = NA_real_,
      nrow = NA_integer_, ncol = NA_integer_, extent = NA_character_, origin_x = NA_real_,
      origin_y = NA_real_, nlyr = NA_integer_, band_names = NA_character_
    ))
  }
  r <- rast(path)
  rs <- res(r)
  org <- origin(r)
  data.table(
    exists = TRUE,
    crs = crs(r, describe = TRUE)$code,
    resolution_x = rs[1],
    resolution_y = rs[2],
    nrow = nrow(r),
    ncol = ncol(r),
    extent = paste(as.vector(ext(r)), collapse = ","),
    origin_x = org[1],
    origin_y = org[2],
    nlyr = nlyr(r),
    band_names = paste(names(r), collapse = ";")
  )
}

resolved <- rbindlist(lapply(seq_len(nrow(manifest)), function(i) cbind(manifest[i], raster_meta(manifest$abs_path[i]))), fill = TRUE)
fwrite(resolved, file.path(CH1_SPATIAL_THRESHOLD_PROVENANCE_DIR, "disturbance_threshold_manifest_resolved.csv"))

template_meta <- raster_meta(cov_path)
validation <- copy(resolved)
validation[, `:=`(
  crs_matches_template = gsub("^EPSG:", "", as.character(crs)) == gsub("^EPSG:", "", as.character(template_meta$crs)),
  resolution_matches_template = resolution_x == template_meta$resolution_x & resolution_y == template_meta$resolution_y,
  extent_matches_template = extent == template_meta$extent,
  origin_matches_template = origin_x == template_meta$origin_x & origin_y == template_meta$origin_y,
  dimensions_match_template = nrow == template_meta$nrow & ncol == template_meta$ncol,
  band_coverage_complete = TRUE,
  value_domain_ok = TRUE,
  identical_to_other_threshold_flag = FALSE
)]

for (i in seq_len(nrow(validation))) {
  if (!isTRUE(validation$exists[i])) next
  r <- rast(validation$abs_path[i])
  if (validation$file_type[i] == "fire_stack") {
    nms <- names(r)
    yrs <- CH1_STUDY_YEARS[CH1_STUDY_YEARS <= 2020L]
    validation$band_coverage_complete[i] <- all(vapply(yrs, function(y) any(grepl(paste0("^", y, "_fire_season_", y, "$"), nms)), logical(1)))
    vals <- unique(na.omit(values(r[[grep("_fire_season_", nms)[1]]])))
    validation$value_domain_ok[i] <- all(vals %in% c(0, 1))
  } else if (validation$file_type[i] == "fire_annual_binary") {
    vals <- unique(na.omit(values(r)))
    validation$value_domain_ok[i] <- all(vals %in% c(0, 1))
  } else if (validation$file_type[i] == "event_year") {
    vals <- unique(na.omit(values(r)))
    validation$value_domain_ok[i] <- all(vals == 0 | (vals >= min(CH1_STUDY_YEARS) & vals <= max(CH1_STUDY_YEARS)))
  }
}

for (out in unique(validation$outcome)) {
  for (ft in unique(validation[outcome == out, file_type])) {
    idx <- validation[outcome == out & file_type == ft, which = TRUE]
    if (length(idx) > 1) {
      sums <- vapply(validation$abs_path[idx], function(p) if (file.exists(p)) as.character(tools::md5sum(p)) else NA_character_, character(1))
      validation$identical_to_other_threshold_flag[idx] <- duplicated(sums) | duplicated(sums, fromLast = TRUE)
    }
  }
}

fwrite(validation, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "input_raster_validation.csv"))
bad_grid <- validation[exists == TRUE & (!crs_matches_template | !resolution_matches_template | !extent_matches_template | !origin_matches_template | !dimensions_match_template)]
if (nrow(bad_grid)) stop("Grid alignment failed for: ", paste(bad_grid$file_path, collapse = "; "), call. = FALSE)

load_governance_timeline <- function() {
  gov_wide <- fread(CH1_GOVERNANCE_PROFILE_PATH)
  gov_long <- melt(
    gov_wide,
    id.vars = "year",
    measure.vars = paste0("SESU", CH1_INCLUDED_SESUS, "_regime"),
    variable.name = "SESU_col",
    value.name = "original_profile_code"
  )
  gov_long[, `:=`(
    year = as.integer(year),
    SESU_ID = as.integer(gsub("^SESU([0-9]+)_regime$", "\\1", SESU_col))
  )]
  gov_long[, governance_profile := unname(CH1_PROFILE_CODE_MAP[original_profile_code])]
  gov_long[, .(SESU_ID, year, original_profile_code, governance_profile)]
}
timeline <- load_governance_timeline()

SESU_v <- values(r_sesu)[, 1]
dist_m <- values(r_cov[["dist_parc_national_signed_m"]])[, 1]
valid_idx <- which(!is.na(SESU_v) & SESU_v %in% CH1_INCLUDED_SESUS & is.finite(dist_m))
pix_geom <- data.table(
  cell = valid_idx,
  SESU_ID = as.integer(SESU_v[valid_idx]),
  park_signed_distance_km = dist_m[valid_idx] / 1000
)
pix_geom[, side := fifelse(park_signed_distance_km < 0, "inside", "outside")]

design_cells <- function(design) {
  d <- copy(pix_geom)
  if (design != "all_cells") {
    lim <- CH1_BUFFER_KM[[design]]
    d <- d[abs(park_signed_distance_km) <= lim]
  }
  zero_excluded <- d[park_signed_distance_km == 0 & is.na(side), .N]
  d[!is.na(side)][, zero_distance_excluded := zero_excluded][]
}

fire_stack_path <- function(tag) manifest[outcome == "fire" & threshold_tag == tag & file_type == "fire_stack", abs_path][1]
fire_annual_path <- function(tag, year) manifest[outcome == "fire" & threshold_tag == tag & file_type == "fire_annual_binary" & year_start == year, abs_path][1]
event_path <- function(outcome_name, tag) {
  manifest[get("outcome") == outcome_name & threshold_tag == tag & file_type == "event_year", abs_path][1]
}
canonical_tau025_path <- normalizePath(cov_path, winslash = "/", mustWork = TRUE)

audit_tau025_inputs <- function() {
  rows <- list()
  disc <- list()
  g <- design_cells("all_cells")

  add_input_row <- function(outcome, year_start, year_end, canonical_object, phase3_path, phase3_object, note) {
    phase3_r <- rast(phase3_path)
    rows[[length(rows) + 1L]] <<- data.table(
      outcome = outcome,
      threshold_tag = "tau025",
      year_start = year_start,
      year_end = year_end,
      canonical_file_path = canonical_tau025_path,
      canonical_object = canonical_object,
      canonical_md5 = as.character(tools::md5sum(canonical_tau025_path)),
      phase3_threshold_file_path = normalizePath(phase3_path, winslash = "/", mustWork = TRUE),
      phase3_threshold_object = phase3_object,
      phase3_threshold_md5 = as.character(tools::md5sum(phase3_path)),
      canonical_geometry = paste(nrow(r_cov), ncol(r_cov), paste(res(r_cov), collapse = "x"), paste(as.vector(ext(r_cov)), collapse = ","), sep = "|"),
      phase3_threshold_geometry = paste(nrow(phase3_r), ncol(phase3_r), paste(res(phase3_r), collapse = "x"), paste(as.vector(ext(phase3_r)), collapse = ","), sep = "|"),
      comparison_note = note
    )
  }

  for (yr in CH1_STUDY_YEARS) {
    canonical_band <- paste0("fireDOY_", yr)
    phase_path <- if (yr <= 2020L) fire_stack_path("tau025") else fire_annual_path("tau025", yr)
    phase_object <- if (yr <= 2020L) paste0(yr, "_fire_season_", yr) else "fireDOY_max_native"
    add_input_row("fire", yr, yr, canonical_band, phase_path, phase_object, "canonical uses embedded seasonal DOY; threshold product stores binary fire")
    cv <- extract_cells_vec(r_cov[[canonical_band]], g$cell)
    if (yr <= 2020L) {
      pr <- rast(phase_path)
      pv <- extract_cells_vec(pr[[phase_object]], g$cell)
      phase_event <- is.finite(pv) & pv == 1
    } else {
      pv <- extract_cells_vec(rast(phase_path), g$cell)
      phase_event <- is.finite(pv) & pv == 1
    }
    canonical_event <- is.finite(cv) & cv >= 100 & cv <= 300
    dd <- copy(g)[, `:=`(year = yr, canonical_event = canonical_event, phase3_threshold_event = phase_event)]
    dd[, outcome := "fire"]
    disc[[paste0("fire_", yr)]] <- dd[, .(
      n_cells = .N,
      differing_cells = sum(canonical_event != phase3_threshold_event),
      percent_differing_cells = 100 * mean(canonical_event != phase3_threshold_event),
      canonical_events = sum(canonical_event),
      phase3_threshold_events = sum(phase3_threshold_event),
      event_count_difference = sum(phase3_threshold_event) - sum(canonical_event),
      differing_event_years = ifelse(sum(canonical_event != phase3_threshold_event) > 0, as.character(yr), "")
    ), by = .(outcome, year, SESU_ID, side)]
  }

  for (outcome_name in c("tree_cover_loss", "agriculture")) {
    canonical_band <- if (outcome_name == "tree_cover_loss") "year_deforest_masked" else "year_agri"
    phase_path <- event_path(outcome_name, "tau025")
    phase_object <- names(rast(phase_path))[1]
    add_input_row(outcome_name, min(CH1_STUDY_YEARS), max(CH1_STUDY_YEARS), canonical_band, phase_path, phase_object, "canonical uses embedded event-year layer; threshold product stores event-year layer")
    cv <- as.integer(extract_cells_vec(r_cov[[canonical_band]], g$cell))
    pv <- as.integer(extract_cells_vec(rast(phase_path), g$cell))
    cv[!is.finite(cv) | cv <= 0] <- NA_integer_
    pv[!is.finite(pv) | pv <= 0] <- NA_integer_
    dd <- copy(g)[, `:=`(canonical_event_year = cv, phase3_threshold_event_year = pv)]
    dd[, `:=`(outcome = outcome_name, year = NA_integer_)]
    dd[, differs := fifelse(
      is.na(canonical_event_year) & is.na(phase3_threshold_event_year),
      FALSE,
      canonical_event_year != phase3_threshold_event_year | is.na(canonical_event_year) != is.na(phase3_threshold_event_year)
    )]
    disc[[outcome_name]] <- dd[, .(
      n_cells = .N,
      differing_cells = sum(differs),
      percent_differing_cells = 100 * mean(differs),
      canonical_events = sum(!is.na(canonical_event_year)),
      phase3_threshold_events = sum(!is.na(phase3_threshold_event_year)),
      event_count_difference = sum(!is.na(phase3_threshold_event_year)) - sum(!is.na(canonical_event_year)),
      differing_event_years = paste(sort(unique(na.omit(c(canonical_event_year[differs], phase3_threshold_event_year[differs])))), collapse = ";")
    ), by = .(outcome, year, SESU_ID, side)]
  }

  list(inputs = rbindlist(rows, use.names = TRUE, fill = TRUE), discrepancies = rbindlist(disc, use.names = TRUE, fill = TRUE))
}

tau025_audit <- audit_tau025_inputs()
fwrite(tau025_audit$inputs, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "tau025_input_comparison.csv"))
fwrite(tau025_audit$discrepancies, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "tau025_cell_value_discrepancies_summary.csv"))
audit_summary <- tau025_audit$discrepancies[, .(
  differing_cells = sum(differing_cells),
  n_cells_compared = sum(n_cells),
  percent_differing_cells = 100 * sum(differing_cells) / sum(n_cells),
  canonical_events = sum(canonical_events),
  phase3_threshold_events = sum(phase3_threshold_events),
  event_count_difference = sum(event_count_difference)
), by = outcome]
audit_lines <- c(
  "# Tau025 Reproduction Audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Resolution",
  "",
  "The final Phase 3 tau025 reference analysis uses the exact canonical embedded layers in `run_2026_05_27/SESU_covariates_500m.tif`: `fireDOY_2001` through `fireDOY_2022`, `year_deforest_masked`, and `year_agri`.",
  "",
  "The threshold-specific tau025 products remain inventoried and audited, but are treated as revised tau025 products rather than the canonical reference when they differ from the embedded run stack.",
  "",
  "## Canonical Versus Threshold-Product Summary",
  "",
  paste(capture.output(print(audit_summary)), collapse = "\n"),
  "",
  "## Files",
  "",
  paste(capture.output(print(tau025_audit$inputs[, .(outcome, year_start, year_end, canonical_file_path, canonical_object, phase3_threshold_file_path, phase3_threshold_object)])), collapse = "\n"),
  "",
  "See `tau025_input_comparison.csv`, `tau025_cell_value_discrepancies_summary.csv`, and `tau025_allcell_reproduction_check.csv` for machine-readable details."
)
writeLines(audit_lines, file.path(CH1_SPATIAL_THRESHOLD_PROVENANCE_DIR, "tau025_reproduction_audit.md"))

surface_fire <- function(tag, geom) {
  out <- list()
  if (tag == "tau025") {
    for (yr in CH1_STUDY_YEARS) {
      band <- paste0("fireDOY_", yr)
      vals <- extract_cells_vec(r_cov[[band]], geom$cell)
      dt <- copy(geom)[, `:=`(year = yr, disturbed = as.integer(is.finite(vals) & vals >= 100 & vals <= 300))]
      out[[as.character(yr)]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
    }
    return(rbindlist(out)[, outcome := "fire"][])
  }
  rs <- rast(fire_stack_path(tag))
  for (yr in 2001:2020) {
    band <- grep(paste0("^", yr, "_fire_season_", yr, "$"), names(rs), value = TRUE)
    if (length(band) != 1) stop("Missing fire binary band for ", tag, " ", yr, call. = FALSE)
    vals <- extract_cells_vec(rs[[band]], geom$cell)
    dt <- copy(geom)[, `:=`(year = yr, disturbed = as.integer(is.finite(vals) & vals == 1))]
    out[[as.character(yr)]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  for (yr in 2021:2022) {
    vals <- extract_cells_vec(rast(fire_annual_path(tag, yr)), geom$cell)
    dt <- copy(geom)[, `:=`(year = yr, disturbed = as.integer(is.finite(vals) & vals == 1))]
    out[[as.character(yr)]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  rbindlist(out)[, outcome := "fire"][]
}

surface_event_year <- function(outcome, tag, geom) {
  if (tag == "tau025") {
    band <- if (outcome == "tree_cover_loss") "year_deforest_masked" else "year_agri"
    vals <- as.integer(extract_cells_vec(r_cov[[band]], geom$cell))
  } else {
    vals <- as.integer(extract_cells_vec(rast(event_path(outcome, tag)), geom$cell))
  }
  vals[!is.finite(vals) | vals <= 0] <- NA_integer_
  out <- vector("list", length(CH1_STUDY_YEARS))
  for (j in seq_along(CH1_STUDY_YEARS)) {
    yr <- CH1_STUDY_YEARS[j]
    at_risk <- is.na(vals) | yr <= vals
    if (!any(at_risk)) next
    dt <- copy(geom[at_risk])
    dt[, `:=`(year = yr, disturbed = as.integer(!is.na(vals[at_risk]) & vals[at_risk] == yr))]
    out[[j]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  rbindlist(out, use.names = TRUE, fill = TRUE)[, outcome := outcome][]
}

add_profile <- function(surface) {
  d <- merge(surface, timeline, by = c("SESU_ID", "year"), all.x = TRUE)
  d[, `:=`(
    governance_profile = factor(governance_profile, levels = profile_levels),
    side = factor(side, levels = c("outside", "inside"))
  )]
  d[]
}

all_surfaces <- list()
for (tag in names(CH1_THRESHOLD_VALUES)) {
  for (design in CH1_SPATIAL_DESIGNS) {
    geom <- design_cells(design)
    all_surfaces[[paste(tag, design, "fire")]] <- add_profile(surface_fire(tag, geom))[, `:=`(threshold_tag = tag, threshold = CH1_THRESHOLD_VALUES[[tag]], spatial_design = design)]
    all_surfaces[[paste(tag, design, "tree")]] <- add_profile(surface_event_year("tree_cover_loss", tag, geom))[, `:=`(threshold_tag = tag, threshold = CH1_THRESHOLD_VALUES[[tag]], spatial_design = design)]
    all_surfaces[[paste(tag, design, "agri")]] <- add_profile(surface_event_year("agriculture", tag, geom))[, `:=`(threshold_tag = tag, threshold = CH1_THRESHOLD_VALUES[[tag]], spatial_design = design)]
  }
}
surface_dt <- rbindlist(all_surfaces, use.names = TRUE, fill = TRUE)
surface_dt[, `:=`(p_hat = y / n, zero_event_flag = y == 0, all_event_flag = y == n)]

detail <- surface_dt[, .(
  cells_at_risk = sum(n),
  disturbed_cells = sum(y),
  undisturbed_cells = sum(n - y),
  disturbance_probability = sum(y) / sum(n),
  zero_event_flag = sum(y) == 0,
  all_event_flag = sum(y) == sum(n),
  number_unique_cells = sum(n),
  number_unique_sesu_years = uniqueN(paste(SESU_ID, year))
), by = .(outcome, threshold, threshold_tag, spatial_design, SESU_ID, year, governance_profile, side)]
fwrite(detail, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "event_support_detailed.csv"))

episode_table <- function(dt) {
  e <- unique(dt[, .(SESU_ID, year, governance_profile)])
  setorder(e, SESU_ID, year)
  e[, new_ep := is.na(data.table::shift(governance_profile)) |
      governance_profile != data.table::shift(governance_profile) |
      year != data.table::shift(year, fill = first(year) - 1L) + 1L,
    by = SESU_ID]
  e[, ep := cumsum(new_ep), by = SESU_ID]
  e[, .(start_year = min(year), end_year = max(year), n_years = .N), by = .(SESU_ID, governance_profile, ep)]
}
eps <- episode_table(timeline)
support_summary <- detail[, .(
  total_events = sum(disturbed_cells),
  total_cell_years_at_risk = sum(cells_at_risk),
  years_with_at_least_one_event = sum(disturbed_cells > 0),
  zero_event_years = sum(disturbed_cells == 0),
  both_sides_represented = uniqueN(side) == 2,
  both_sesus_represented = uniqueN(SESU_ID) == length(CH1_INCLUDED_SESUS)
), by = .(outcome, threshold, threshold_tag, spatial_design, governance_profile, SESU_ID, side)]
ep_sum <- eps[, .(number_represented_episodes = .N, largest_episode_share = max(n_years) / sum(n_years)), by = .(governance_profile, SESU_ID)]
support_summary <- merge(support_summary, ep_sum, by = c("governance_profile", "SESU_ID"), all.x = TRUE)
fwrite(support_summary, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "event_support_summary.csv"))
sparse_flags <- detail[, .(
  zero_event_strata = sum(zero_event_flag),
  all_event_strata = sum(all_event_flag),
  total_strata = .N,
  total_events = sum(disturbed_cells),
  total_at_risk = sum(cells_at_risk),
  zero_event_burden = mean(zero_event_flag)
), by = .(outcome, threshold, threshold_tag, spatial_design, governance_profile)]
fwrite(sparse_flags, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "sparse_strata_flags.csv"))

canon <- fread(file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"))[pa_label == "National Park"]
canon[, outcome := fifelse(disturbance == "year_deforest_masked", "tree_cover_loss", fifelse(disturbance == "year_agri", "agriculture", disturbance))]
rep <- merge(
  surface_dt[threshold_tag == "tau025" & spatial_design == "all_cells", .(SESU_ID, year, outcome, side = as.character(side), n_phase3 = n, y_phase3 = y)],
  canon[, .(SESU_ID, year, outcome, side, n_canonical = n, y_canonical = y)],
  by = c("SESU_ID", "year", "outcome", "side"),
  all = TRUE
)
rep[, `:=`(
  n_difference = n_phase3 - n_canonical,
  y_difference = y_phase3 - y_canonical,
  exact_agreement = n_phase3 == n_canonical & y_phase3 == y_canonical
)]
fwrite(rep, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "tau025_allcell_reproduction_check.csv"))

covariates <- readLines(file.path(CH1_RUN_DIR, "SESU_features_used.txt"))
covariates <- covariates[covariates %in% names(r_cov)]
balance_rows <- list()
for (design in CH1_SPATIAL_DESIGNS) {
  geom <- design_cells(design)
  vals <- as.data.table(extract(r_cov[[covariates]], geom$cell))
  if ("ID" %in% names(vals)) vals[, ID := NULL]
  cd <- cbind(geom[, .(cell, SESU_ID, side)], vals)
  for (sid in c(CH1_INCLUDED_SESUS, NA_integer_)) {
    d <- if (is.na(sid)) cd else cd[SESU_ID == sid]
    for (cv in covariates) {
      ins <- d[side == "inside", get(cv)]
      out <- d[side == "outside", get(cv)]
      sd_pool <- sqrt((stats::var(ins, na.rm = TRUE) + stats::var(out, na.rm = TRUE)) / 2)
      smd <- if (is.finite(sd_pool) && sd_pool > 0) (mean(ins, na.rm = TRUE) - mean(out, na.rm = TRUE)) / sd_pool else NA_real_
      balance_rows[[length(balance_rows) + 1L]] <- data.table(
        spatial_design = design, SESU_ID = ifelse(is.na(sid), "pooled", paste0("SESU", sid)),
        covariate = cv, inside_n = sum(is.finite(ins)), outside_n = sum(is.finite(out)),
        inside_mean = mean(ins, na.rm = TRUE), outside_mean = mean(out, na.rm = TRUE),
        standardized_mean_difference = smd
      )
    }
  }
}
balance <- rbindlist(balance_rows)
fwrite(balance, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "covariate_balance_by_sesu.csv"))
balance_summary <- balance[, .(
  median_abs_smd = median(abs(standardized_mean_difference), na.rm = TRUE),
  max_abs_smd = max(abs(standardized_mean_difference), na.rm = TRUE),
  n_covariates_abs_smd_gt_0_10 = sum(abs(standardized_mean_difference) > 0.10, na.rm = TRUE),
  n_covariates_abs_smd_gt_0_20 = sum(abs(standardized_mean_difference) > 0.20, na.rm = TRUE),
  inside_cell_count = max(inside_n, na.rm = TRUE),
  outside_cell_count = max(outside_n, na.rm = TRUE)
), by = .(spatial_design, SESU_ID)]
fwrite(balance_summary, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "covariate_balance_summary.csv"))

add_model_terms <- function(d) {
  x <- copy(d)
  x[, `:=`(
    SESU_ID = factor(SESU_ID),
    side = factor(as.character(side), levels = c("outside", "inside")),
    governance_profile = factor(governance_profile, levels = profile_levels),
    inside_profile_militia = as.integer(side == "inside" & governance_profile == "Militia dominant"),
    inside_profile_park = as.integer(side == "inside" & governance_profile == "Park dominant"),
    sesu_year = interaction(SESU_ID, year, drop = TRUE)
  )]
  x[]
}
fit_model <- function(d) {
  warns <- character()
  fit <- withCallingHandlers(
    tryCatch(glmmTMB(primary_formula, family = betabinomial(link = "logit"), data = d,
      control = glmmTMBControl(optCtrl = list(iter.max = 50000, eval.max = 50000, rel.tol = 1e-10, x.tol = 1e-8))),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")),
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  list(fit = fit, warnings = unique(warns))
}
max_abs_gradient <- function(model) tryCatch(max(abs(model$obj$gr(model$fit$par)), na.rm = TRUE), error = function(e) NA_real_)
make_profile_L <- function(beta_names, profile) {
  L <- setNames(rep(0, length(beta_names)), beta_names)
  if ("sideinside" %in% beta_names) L["sideinside"] <- 1
  if (profile == "Militia dominant" && "inside_profile_militia" %in% beta_names) L["inside_profile_militia"] <- L["inside_profile_militia"] + 1
  if (profile == "Park dominant" && "inside_profile_park" %in% beta_names) L["inside_profile_park"] <- L["inside_profile_park"] + 1
  L
}
contrast_stats <- function(beta, V, L, intervals = TRUE) {
  est <- sum(L * beta)
  se <- as.numeric(sqrt(t(L) %*% V %*% L))
  data.table(estimate = est, standard_error = se, lower_95_ci = if (intervals) est - zcrit * se else NA_real_, upper_95_ci = if (intervals) est + zcrit * se else NA_real_)
}
fit_diag <- function(fw, d, outcome, tag, design) {
  X <- tryCatch(model.matrix(primary_formula, d), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  if (inherits(fw$fit, "fit_error")) return(data.table(outcome = outcome, threshold_tag = tag, spatial_design = design, convergence_code = NA_integer_, optimizer_message = fw$fit$error, pdHess = NA, maximum_absolute_gradient = NA_real_, model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = FALSE, warnings = paste(fw$warnings, collapse = " | ")))
  m <- fw$fit
  se <- tryCatch(summary(m)$coefficients$cond[, "Std. Error"], error = function(e) NA_real_)
  pd <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  grad <- max_abs_gradient(m)
  strict <- identical(m$fit$convergence, 0L) && pd && identical(rank_x, cols_x) && is.finite(grad) && grad < CH1_MAX_ABS_GRADIENT_TOL && !any(abs(se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE)
  data.table(outcome = outcome, threshold_tag = tag, spatial_design = design, convergence_code = m$fit$convergence, optimizer_message = as.character(m$fit$message), pdHess = pd, maximum_absolute_gradient = grad, dispersion_estimate = tryCatch(sigma(m), error = function(e) NA_real_), model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = strict, warnings = paste(fw$warnings, collapse = " | "), coefficient_estimates = paste(paste0(names(fixef(m)$cond), "=", signif(fixef(m)$cond, 8)), collapse = "; "))
}
profile_contrasts <- function(m, outcome, tag, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(profile_levels, function(pr) cbind(data.table(outcome = outcome, threshold_tag = tag, spatial_design = design, governance_profile = pr), contrast_stats(beta, V, make_profile_L(names(beta), pr), intervals = strict_valid))), fill = TRUE)
}
pairwise_contrasts <- function(m, outcome, tag, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- make_profile_L(names(beta), parts[1]) - make_profile_L(names(beta), parts[2])
    cbind(data.table(outcome = outcome, threshold_tag = tag, spatial_design = design, profile_comparison = cmp), contrast_stats(beta, V, L, intervals = strict_valid))
  }), fill = TRUE)
}

fire_diag <- list(); fire_con <- list(); fire_pair <- list()
rare_diag <- list(); rare_con <- list()
for (tag in names(CH1_THRESHOLD_VALUES)) {
  for (design in CH1_SPATIAL_DESIGNS) {
    fd <- add_model_terms(surface_dt[outcome == "fire" & threshold_tag == tag & spatial_design == design])
    fw <- fit_model(fd)
    dg <- fit_diag(fw, fd, "fire", tag, design)
    fire_diag[[paste(tag, design)]] <- dg
    if (!inherits(fw$fit, "fit_error")) {
      fire_con[[paste(tag, design)]] <- profile_contrasts(fw$fit, "fire", tag, design, dg$strict_valid)
      fire_pair[[paste(tag, design)]] <- pairwise_contrasts(fw$fit, "fire", tag, design, dg$strict_valid)
    }
    for (out in c("tree_cover_loss", "agriculture")) {
      rd <- add_model_terms(surface_dt[outcome == out & threshold_tag == tag & spatial_design == design])
      rw <- fit_model(rd)
      rg <- fit_diag(rw, rd, out, tag, design)
      rare_diag[[paste(out, tag, design)]] <- rg
      if (!inherits(rw$fit, "fit_error")) rare_con[[paste(out, tag, design)]] <- profile_contrasts(rw$fit, out, tag, design, rg$strict_valid)
    }
  }
}
fire_diag_dt <- rbindlist(fire_diag, fill = TRUE)
fire_con_dt <- rbindlist(fire_con, fill = TRUE)
fire_pair_dt <- rbindlist(fire_pair, fill = TRUE)
rare_diag_dt <- rbindlist(rare_diag, fill = TRUE)
rare_con_dt <- rbindlist(rare_con, fill = TRUE)
fwrite(fire_diag_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "fire_fit_diagnostics.csv"))
fwrite(fire_con_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "fire_profile_contrasts.csv"))
fwrite(fire_pair_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "fire_pairwise_differences.csv"))
fwrite(rare_diag_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "rare_outcome_beta_binomial_diagnostics.csv"))
fwrite(rare_con_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "rare_outcome_beta_binomial_profile_contrasts.csv"))

hc3_vcov <- function(mod) {
  X <- model.matrix(mod); e <- residuals(mod); h <- hatvalues(mod); w <- weights(mod)
  if (is.null(w)) w <- rep(1, length(e))
  Xw <- X * sqrt(w)
  meat <- t(Xw) %*% diag((e * sqrt(w) / pmax(1 - h, 1e-8))^2, nrow = length(e)) %*% Xw
  bread <- solve(t(Xw) %*% Xw)
  bread %*% meat %*% bread
}
two_stage_est <- list(); two_stage_pair <- list(); two_stage_diag <- list(); sy_rows <- list()
for (tag in names(CH1_THRESHOLD_VALUES)) for (design in CH1_SPATIAL_DESIGNS) for (out in c("tree_cover_loss", "agriculture")) {
  s <- surface_dt[outcome == out & threshold_tag == tag & spatial_design == design]
  w <- dcast(s, threshold + threshold_tag + spatial_design + outcome + SESU_ID + year + governance_profile ~ side, value.var = c("y", "n"))
  w[, `:=`(
    inside_probability = y_inside / n_inside,
    outside_probability = y_outside / n_outside,
    probability_difference = y_inside / n_inside - y_outside / n_outside,
    zero_cell_flag = y_inside == 0 | y_outside == 0 | (n_inside - y_inside) == 0 | (n_outside - y_outside) == 0
  )]
  w[, `:=`(yi = y_inside + 0.5, ni = n_inside + 1, yo = y_outside + 0.5, no = n_outside + 1)]
  w[, `:=`(
    corrected_inside_log_odds = log(yi / (ni - yi)),
    corrected_outside_log_odds = log(yo / (no - yo)),
    sesu_year_log_odds_contrast = log(yi / (ni - yi)) - log(yo / (no - yo)),
    approximate_variance = 1 / yi + 1 / (ni - yi) + 1 / yo + 1 / (no - yo)
  )]
  w[, inverse_variance_weight := 1 / approximate_variance]
  sy_rows[[paste(tag, design, out)]] <- w
  w[, `:=`(governance_profile = factor(governance_profile, levels = profile_levels), SESU_ID = factor(SESU_ID))]
  for (weighted in c(TRUE, FALSE)) {
    mt <- if (weighted) "inverse_variance_weighted_lm_hc3" else "unweighted_lm_hc3"
    mod <- if (weighted) lm(sesu_year_log_odds_contrast ~ governance_profile + SESU_ID, data = w, weights = inverse_variance_weight) else lm(sesu_year_log_odds_contrast ~ governance_profile + SESU_ID, data = w)
    V <- tryCatch(hc3_vcov(mod), error = function(e) vcov(mod))
    nd <- CJ(governance_profile = profile_levels, SESU_ID = levels(w$SESU_ID))
    nd[, governance_profile := factor(governance_profile, levels = profile_levels)]
    nd[, SESU_ID := factor(SESU_ID, levels = levels(w$SESU_ID))]
    Xn <- model.matrix(delete.response(terms(mod)), nd)
    for (pr in profile_levels) {
      L <- colMeans(Xn[as.character(nd$governance_profile) == pr, , drop = FALSE])
      est <- sum(L * coef(mod)); se <- sqrt(as.numeric(t(L) %*% V %*% L))
      two_stage_est[[paste(tag, design, out, mt, pr)]] <- data.table(outcome = out, threshold_tag = tag, spatial_design = design, model_type = mt, governance_profile = pr, estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se, contributing_sesu_years = nrow(w), zero_cell_corrected_observations = sum(w$zero_cell_flag), covariance = "HC3; calendar-year clustering not implemented")
    }
    for (cmp in pairwise_comparisons) {
      parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
      L <- colMeans(Xn[as.character(nd$governance_profile) == parts[1], , drop = FALSE]) - colMeans(Xn[as.character(nd$governance_profile) == parts[2], , drop = FALSE])
      est <- sum(L * coef(mod)); se <- sqrt(as.numeric(t(L) %*% V %*% L))
      two_stage_pair[[paste(tag, design, out, mt, cmp)]] <- data.table(outcome = out, threshold_tag = tag, spatial_design = design, model_type = mt, profile_comparison = cmp, estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se, covariance = "HC3; calendar-year clustering not implemented")
    }
    two_stage_diag[[paste(tag, design, out, mt)]] <- data.table(outcome = out, threshold_tag = tag, spatial_design = design, model_type = mt, n_obs = nrow(w), residual_df = df.residual(mod), r_squared = summary(mod)$r.squared, covariance = "HC3")
  }
}
sy_dt <- rbindlist(sy_rows, fill = TRUE)
fwrite(sy_dt, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "sparse_outcome_sesu_year_contrasts.csv"))
fwrite(rbindlist(two_stage_est, fill = TRUE), file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "sparse_outcome_profile_estimates.csv"))
fwrite(rbindlist(two_stage_pair, fill = TRUE), file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "sparse_outcome_pairwise_differences.csv"))
fwrite(rbindlist(two_stage_diag, fill = TRUE), file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "sparse_outcome_model_diagnostics.csv"))

primary_est <- rbindlist(list(
  fire_con_dt[, .(outcome, threshold_tag, spatial_design, governance_profile, estimate, lower_95_ci, upper_95_ci, method = "fire_beta_binomial")],
  rbindlist(two_stage_est, fill = TRUE)[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, threshold_tag, spatial_design, governance_profile, estimate, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted")]
), fill = TRUE)
ref <- primary_est[threshold_tag == CH1_PHASE3_REFERENCE_THRESHOLD & spatial_design == CH1_PHASE3_REFERENCE_SPATIAL_DESIGN, .(outcome, governance_profile, reference_estimate = estimate)]
comp <- merge(primary_est, ref, by = c("outcome", "governance_profile"), all.x = TRUE)
comp[, `:=`(
  absolute_deviation_from_reference = abs(estimate - reference_estimate),
  ci_crosses_zero = lower_95_ci <= 0 & upper_95_ci >= 0
)]
fwrite(comp, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "spatial_threshold_contrast_comparison.csv"))
pair_primary <- rbindlist(list(
  fire_pair_dt[, .(outcome, threshold_tag, spatial_design, profile_comparison, estimate, lower_95_ci, upper_95_ci, method = "fire_beta_binomial")],
  rbindlist(two_stage_pair, fill = TRUE)[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, threshold_tag, spatial_design, profile_comparison, estimate, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted")]
), fill = TRUE)
pair_ref <- pair_primary[threshold_tag == CH1_PHASE3_REFERENCE_THRESHOLD & spatial_design == CH1_PHASE3_REFERENCE_SPATIAL_DESIGN, .(outcome, profile_comparison, reference_estimate = estimate)]
pair_comp <- merge(pair_primary, pair_ref, by = c("outcome", "profile_comparison"), all.x = TRUE)
pair_comp[, absolute_deviation_from_reference := abs(estimate - reference_estimate)]
fwrite(pair_comp, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "spatial_threshold_pairwise_comparison.csv"))
stability <- comp[, .(
  reference_estimate = reference_estimate[1],
  minimum_estimate = min(estimate, na.rm = TRUE),
  maximum_estimate = max(estimate, na.rm = TRUE),
  maximum_absolute_deviation_from_reference = max(absolute_deviation_from_reference, na.rm = TRUE),
  sign_consistency = uniqueN(sign(estimate)) == 1,
  any_ci_crosses_zero = any(ci_crosses_zero, na.rm = TRUE),
  contributing_sesu_years = sum(support_summary[outcome == .BY$outcome & threshold_tag == CH1_PHASE3_REFERENCE_THRESHOLD & spatial_design == CH1_PHASE3_REFERENCE_SPATIAL_DESIGN, uniqueN(paste(SESU_ID, governance_profile))]),
  event_count_reference = sum(detail[outcome == .BY$outcome & threshold_tag == CH1_PHASE3_REFERENCE_THRESHOLD & spatial_design == CH1_PHASE3_REFERENCE_SPATIAL_DESIGN, disturbed_cells]),
  zero_event_burden_reference = mean(detail[outcome == .BY$outcome & threshold_tag == CH1_PHASE3_REFERENCE_THRESHOLD & spatial_design == CH1_PHASE3_REFERENCE_SPATIAL_DESIGN, zero_event_flag])
), by = .(outcome, governance_profile)]
fwrite(stability, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "spatial_threshold_stability_summary.csv"))

decision <- balance_summary[SESU_ID == "pooled", .(spatial_design, median_abs_smd, max_abs_smd, n_covariates_abs_smd_gt_0_10, n_covariates_abs_smd_gt_0_20, inside_cell_count, outside_cell_count)]
support_design <- detail[, .(events = sum(disturbed_cells), at_risk = sum(cells_at_risk)), by = .(spatial_design, outcome)]
support_wide <- dcast(support_design, spatial_design ~ outcome, value.var = c("events", "at_risk"))
decision <- merge(decision, support_wide, by = "spatial_design", all.x = TRUE)
decision <- merge(decision, fire_diag_dt[, .(strict_valid_fire_fits = sum(strict_valid, na.rm = TRUE)), by = spatial_design], by = "spatial_design", all.x = TRUE)
decision <- merge(decision, rare_diag_dt[, .(strict_valid_rare_outcome_beta_binomial_fits = sum(strict_valid, na.rm = TRUE)), by = spatial_design], by = "spatial_design", all.x = TRUE)
decision[, `:=`(
  directional_agreement_with_all_cells = "see spatial_threshold_stability_summary.csv",
  principal_strengths = fifelse(spatial_design == "all_cells", "maximizes event and episode support", "improves territorial-control estimand locality"),
  principal_weaknesses = fifelse(spatial_design == "buffer_05km", "largest event-support loss", fifelse(spatial_design == "all_cells", "least boundary-local comparability", "intermediate support-comparability tradeoff")),
  decision_hierarchy = "territorial-control estimand; comparability; event and episode support; adjacent-buffer stability; parsimony"
)]
fwrite(decision, file.path(CH1_SPATIAL_THRESHOLD_TABLES_DIR, "spatial_design_decision_matrix.csv"))

ggsave(file.path(CH1_SPATIAL_THRESHOLD_FIGURES_DIR, "covariate_balance_by_buffer.png"),
  ggplot(balance_summary[SESU_ID == "pooled"], aes(spatial_design, median_abs_smd)) + geom_col() + coord_flip() + theme_minimal(),
  width = 7, height = 4, dpi = 150)
ggsave(file.path(CH1_SPATIAL_THRESHOLD_FIGURES_DIR, "event_support_by_threshold_and_buffer.png"),
  ggplot(detail[, .(events = sum(disturbed_cells)), by = .(outcome, threshold_tag, spatial_design)], aes(spatial_design, events, fill = threshold_tag)) + geom_col(position = "dodge") + facet_wrap(~ outcome, scales = "free_y") + coord_flip() + theme_minimal(),
  width = 9, height = 5, dpi = 150)
ggsave(file.path(CH1_SPATIAL_THRESHOLD_FIGURES_DIR, "profile_contrasts_by_threshold_and_buffer.png"),
  ggplot(comp, aes(spatial_design, estimate, color = threshold_tag)) + geom_point(position = position_dodge(width = 0.4)) + facet_grid(outcome ~ governance_profile, scales = "free_y") + coord_flip() + theme_minimal(),
  width = 11, height = 7, dpi = 150)

writeLines(capture.output(sessionInfo()), file.path(CH1_SPATIAL_THRESHOLD_PROVENANCE_DIR, "sessionInfo.txt"))
message("Spatial-threshold sensitivity workflow complete. Outputs: ", CH1_SPATIAL_THRESHOLD_OUTPUT_DIR)
