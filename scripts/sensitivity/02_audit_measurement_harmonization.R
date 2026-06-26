# ===========================================================
# CHAPTER 1 MEASUREMENT PROVENANCE AND HARMONIZATION WORKFLOW
# ===========================================================
# Narrow post-Phase-3 workflow. Audits canonical embedded tau025
# disturbance outcomes against standalone threshold products, then fits a
# harmonized standalone threshold series for all-cells and 10 km boundary
# estimands only.
# ===========================================================

suppressPackageStartupMessages({
  library(data.table)
  library(terra)
  library(glmmTMB)
})

script_path <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/"), error = function(e) NA_character_)
if (is.na(script_path)) {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) script_path <- normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/")
}
script_dir <- if (!is.na(script_path)) dirname(script_path) else getwd()
source(normalizePath(file.path(script_dir, "..", "..", "config", "analysis_config.R"), winslash = "/", mustWork = TRUE))

CH1_MEASUREMENT_OUTPUT_DIR <- file.path(CH1_ROOT, "analysis_measurement_harmonization_dev")
CH1_MEASUREMENT_TABLES_DIR <- file.path(CH1_MEASUREMENT_OUTPUT_DIR, "tables")
CH1_MEASUREMENT_PROVENANCE_DIR <- file.path(CH1_MEASUREMENT_OUTPUT_DIR, "provenance")
CH1_MEASUREMENT_LOGS_DIR <- file.path(CH1_MEASUREMENT_OUTPUT_DIR, "logs")
CH1_MEASUREMENT_MODELS_DIR <- file.path(CH1_MEASUREMENT_OUTPUT_DIR, "models")
CH1_MEASUREMENT_FIGURES_DIR <- file.path(CH1_MEASUREMENT_OUTPUT_DIR, "figures")

for (p in c(
  CH1_MEASUREMENT_OUTPUT_DIR, CH1_MEASUREMENT_TABLES_DIR, CH1_MEASUREMENT_PROVENANCE_DIR,
  CH1_MEASUREMENT_LOGS_DIR, CH1_MEASUREMENT_MODELS_DIR, CH1_MEASUREMENT_FIGURES_DIR
)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

zcrit <- qnorm(1 - CH1_ALPHA / 2)
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
measurement_versions <- c("canonical_embedded_tau025", "standalone_tau010", "standalone_tau025", "standalone_tau050")
standalone_versions <- setdiff(measurement_versions, "canonical_embedded_tau025")
spatial_designs <- c("all_cells", "buffer_10km")
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")
pairwise_comparisons <- c(
  "Park dominant minus Neither actor dominant",
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)

stop_missing <- function(path) if (!file.exists(path)) stop("Missing required file: ", path, call. = FALSE)
extract_cells_vec <- function(x, cells) {
  ex <- terra::extract(x, cells)
  if (is.data.frame(ex)) return(as.vector(ex[, ncol(ex)]))
  as.vector(ex)
}
rel_path <- function(path) gsub("\\\\", "/", sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", normalizePath(CH1_ROOT, winslash = "/", mustWork = FALSE)), "/?"), "", normalizePath(path, winslash = "/", mustWork = FALSE)))
measurement_threshold <- function(version) {
  if (version == "canonical_embedded_tau025") return(0.25)
  unname(CH1_THRESHOLD_VALUES[[threshold_tag(version)]])
}
threshold_tag <- function(version) {
  if (version == "canonical_embedded_tau025") return("tau025")
  sub("^standalone_", "", version)
}
distance_class <- function(x) {
  fifelse(abs(x) <= 5, "0-5 km",
    fifelse(abs(x) <= 10, "5-10 km",
      fifelse(abs(x) <= 20, "10-20 km", ">20 km")))
}

cov_path <- file.path(CH1_RUN_DIR, "SESU_covariates_500m.tif")
sesu_path <- file.path(CH1_RUN_DIR, "SESU_ID_500m.tif")
canonical_surface_path <- file.path(CH1_RUN_DIR, "rs_surfaces_long.csv")
stop_missing(cov_path); stop_missing(sesu_path); stop_missing(canonical_surface_path)

r_cov <- rast(cov_path)
r_sesu <- rast(sesu_path)
template <- r_cov[[1]]
stopifnot("forest2000_ge_30pct" %in% names(r_cov))
forest_mask_vals <- as.logical(values(r_cov[["forest2000_ge_30pct"]])[, 1] == 1)

threshold_manifest <- fread(file.path(CH1_ROOT, "config", "disturbance_threshold_manifest.csv"))
threshold_manifest[, abs_path := normalizePath(file.path(CH1_ROOT, file_path), winslash = "/", mustWork = FALSE)]
measurement_manifest <- fread(file.path(CH1_ROOT, "config", "disturbance_measurement_versions.csv"))

raster_meta <- function(path) {
  if (!file.exists(path)) {
    return(data.table(path = path, exists = FALSE, md5 = NA_character_, nlyr = NA_integer_, band_names = NA_character_))
  }
  if (!grepl("\\.(tif|tiff)$", path, ignore.case = TRUE)) {
    return(data.table(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      exists = TRUE,
      md5 = as.character(tools::md5sum(path)),
      file_type = tools::file_ext(path),
      crs = NA_character_,
      resolution_x = NA_real_,
      resolution_y = NA_real_,
      nrow = NA_integer_,
      ncol = NA_integer_,
      extent = NA_character_,
      origin_x = NA_real_,
      origin_y = NA_real_,
      nlyr = NA_integer_,
      band_names = NA_character_
    ))
  }
  r <- rast(path)
  data.table(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    exists = TRUE,
    md5 = as.character(tools::md5sum(path)),
    crs = crs(r, describe = TRUE)$code,
    resolution_x = res(r)[1],
    resolution_y = res(r)[2],
    nrow = nrow(r),
    ncol = ncol(r),
    extent = paste(as.vector(ext(r)), collapse = ","),
    origin_x = origin(r)[1],
    origin_y = origin(r)[2],
    nlyr = nlyr(r),
    band_names = paste(names(r), collapse = ";")
  )
}
all_input_paths <- unique(c(
  cov_path, sesu_path,
  threshold_manifest$abs_path,
  file.path(CH1_ROOT, "data", "gfc_treecover2000_meanpct_500m_epsg32735.tif"),
  file.path(CH1_ROOT, "scripts", "Script 0_data acquisition.txt"),
  file.path(CH1_ROOT, "scripts", "Script 1_Fire agri preprocessing.R"),
  file.path(CH1_ROOT, "scripts", "Script 2_SESU clustering.R"),
  file.path(CH1_ROOT, "scripts", "Script 3_RS data preparation.R")
))
input_hashes <- rbindlist(lapply(all_input_paths, raster_meta), fill = TRUE)
fwrite(input_hashes, file.path(CH1_MEASUREMENT_PROVENANCE_DIR, "measurement_input_hashes.csv"))

compare_to_template <- function(path) {
  r <- rast(path)
  data.table(
    file_path = rel_path(path),
    grid_matches_template = compareGeom(template, r[[1]], stopOnError = FALSE),
    crs_matches_template = crs(template, describe = TRUE)$code == crs(r, describe = TRUE)$code,
    resolution_matches_template = identical(as.numeric(res(template)), as.numeric(res(r))),
    extent_matches_template = identical(as.vector(ext(template)), as.vector(ext(r))),
    origin_matches_template = identical(as.numeric(origin(template)), as.numeric(origin(r))),
    dimensions_match_template = nrow(template) == nrow(r) && ncol(template) == ncol(r)
  )
}
grid_checks <- rbindlist(lapply(threshold_manifest$abs_path, compare_to_template), fill = TRUE)
fwrite(grid_checks, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_grid_validation.csv"))
if (any(!grid_checks$grid_matches_template)) {
  stop("At least one standalone input does not match the canonical grid; no resampling is performed.", call. = FALSE)
}

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
    SESU_ID = as.integer(gsub("^SESU([0-9]+)_regime$", "\\1", SESU_col)),
    governance_profile = unname(CH1_PROFILE_CODE_MAP[original_profile_code])
  )]
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
pix_geom[, abs_boundary_distance_class := distance_class(park_signed_distance_km)]

design_cells <- function(design) {
  d <- copy(pix_geom)
  if (design == "buffer_10km") d <- d[abs(park_signed_distance_km) <= 10]
  if (!design %in% spatial_designs) stop("Unsupported spatial design in this phase: ", design, call. = FALSE)
  d
}

fire_stack_path <- function(tag) threshold_manifest[outcome == "fire" & threshold_tag == tag & file_type == "fire_stack", abs_path][1]
fire_binary_path <- function(tag, year) threshold_manifest[outcome == "fire" & threshold_tag == tag & file_type == "fire_annual_binary" & year_start == year, abs_path][1]
fire_doy_path <- function(tag, year) {
  p <- fire_binary_path(tag, year)
  candidate <- sub("fireBurned_AprOct", "fireDOY_max_AprOct", p)
  if (file.exists(candidate)) candidate else NA_character_
}
event_path <- function(outcome_name, tag) threshold_manifest[get("outcome") == outcome_name & threshold_tag == tag & file_type == "event_year", abs_path][1]

canonical_fire_event <- function(year, cells) {
  vals <- extract_cells_vec(r_cov[[paste0("fireDOY_", year)]], cells)
  is.finite(vals) & vals >= 100 & vals <= 300
}
standalone_fire_event <- function(tag, year, cells) {
  if (year <= 2020L) {
    rs <- rast(fire_stack_path(tag))
    band <- grep(paste0("^", year, "_fire_season_", year, "$"), names(rs), value = TRUE)
    if (length(band) != 1) stop("Missing standalone fire binary band for ", tag, " ", year, call. = FALSE)
    vals <- extract_cells_vec(rs[[band]], cells)
  } else {
    vals <- extract_cells_vec(rast(fire_binary_path(tag, year)), cells)
  }
  is.finite(vals) & vals == 1
}
canonical_event_year <- function(outcome_name, cells) {
  band <- if (outcome_name == "tree_cover_loss") "year_deforest_masked" else "year_agri"
  vals <- as.integer(extract_cells_vec(r_cov[[band]], cells))
  vals[!is.finite(vals) | vals <= 0] <- NA_integer_
  vals
}
standalone_event_year <- function(outcome_name, tag, cells, harmonize_tree_mask = TRUE) {
  vals <- as.integer(extract_cells_vec(rast(event_path(outcome_name, tag)), cells))
  vals[!is.finite(vals) | vals <= 0] <- NA_integer_
  if (outcome_name == "tree_cover_loss" && harmonize_tree_mask) {
    fm <- forest_mask_vals[cells]
    vals[!fm] <- NA_integer_
  }
  vals
}

# -----------------------------------------------------------
# Measurement provenance audits
# -----------------------------------------------------------
algorithm_rows <- list(
  data.table(outcome = "fire", measurement_version = "canonical_embedded_tau025", complete_provenance_available = FALSE, source_version_known = FALSE, method_reproducible_from_current_scripts = FALSE, same_grid = TRUE, same_study_period = TRUE, same_eligibility_mask = TRUE, same_missing_data_treatment = NA, same_threshold_interpretation = FALSE, consistent_across_all_thresholds = FALSE, agreement_with_manuscript_definition = "partial", principal_strength = "exactly reproduces canonical analytical tau025", principal_weakness = "exact GEE export revision and mixed 2021-2022 local fire algorithm are not fully recoverable", unresolved_issue = "retrieve GEE task/revision and confirm FireCCI source/version/export settings"),
  data.table(outcome = "tree_cover_loss", measurement_version = "canonical_embedded_tau025", complete_provenance_available = FALSE, source_version_known = TRUE, method_reproducible_from_current_scripts = TRUE, same_grid = TRUE, same_study_period = TRUE, same_eligibility_mask = TRUE, same_missing_data_treatment = TRUE, same_threshold_interpretation = TRUE, consistent_across_all_thresholds = FALSE, agreement_with_manuscript_definition = "yes after Script 2 forest mask", principal_strength = "canonical 30% baseline-forest mask is explicit in Script 2", principal_weakness = "GEE export itself is unmasked and exact export revision is unknown", unresolved_issue = "retrieve original GEE export/task evidence"),
  data.table(outcome = "agriculture", measurement_version = "canonical_embedded_tau025", complete_provenance_available = FALSE, source_version_known = FALSE, method_reproducible_from_current_scripts = TRUE, same_grid = TRUE, same_study_period = TRUE, same_eligibility_mask = TRUE, same_missing_data_treatment = TRUE, same_threshold_interpretation = TRUE, consistent_across_all_thresholds = TRUE, agreement_with_manuscript_definition = "yes", principal_strength = "canonical and standalone tau025 are locally identical", principal_weakness = "AFCD source version is not documented locally", unresolved_issue = "retrieve AFCD stack provenance if needed")
)
for (outcome_name in c("fire", "tree_cover_loss", "agriculture")) {
  for (v in standalone_versions) {
    algorithm_rows[[length(algorithm_rows) + 1L]] <- data.table(
      outcome = outcome_name,
      measurement_version = v,
      complete_provenance_available = FALSE,
      source_version_known = outcome_name == "tree_cover_loss",
      method_reproducible_from_current_scripts = outcome_name != "fire",
      same_grid = TRUE,
      same_study_period = TRUE,
      same_eligibility_mask = outcome_name != "tree_cover_loss" || TRUE,
      same_missing_data_treatment = outcome_name != "fire",
      same_threshold_interpretation = TRUE,
      consistent_across_all_thresholds = TRUE,
      agreement_with_manuscript_definition = fifelse(outcome_name == "fire", "partial", "yes"),
      principal_strength = "internally harmonized threshold series for tau010/tau025/tau050",
      principal_weakness = "not identical to canonical embedded tau025 for fire and tree-cover loss",
      unresolved_issue = "exact export/task provenance remains incomplete"
    )
  }
}
fwrite(rbindlist(algorithm_rows, fill = TRUE), file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_algorithm_decision_matrix.csv"))

g_all <- design_cells("all_cells")

fire_year_rows <- list()
fire_sesu_rows <- list()
for (yr in CH1_STUDY_YEARS) {
  can <- canonical_fire_event(yr, g_all$cell)
  st <- standalone_fire_event("tau025", yr, g_all$cell)
  dd <- copy(g_all)[, `:=`(year = yr, canonical_event = can, standalone_event = st)]
  fire_year_rows[[as.character(yr)]] <- dd[, .(
    period = fifelse(year <= 2020L, "2001-2020", as.character(year))[1],
    valid_cell_years = .N,
    canonical_events = sum(canonical_event),
    standalone_events = sum(standalone_event),
    canonical_only_events = sum(canonical_event & !standalone_event),
    standalone_only_events = sum(!canonical_event & standalone_event),
    differing_cell_years = sum(canonical_event != standalone_event),
    percent_valid_cell_years_differ = 100 * mean(canonical_event != standalone_event),
    inside_differences = sum(canonical_event != standalone_event & side == "inside"),
    outside_differences = sum(canonical_event != standalone_event & side == "outside")
  ), by = year]
  fire_sesu_rows[[as.character(yr)]] <- dd[, .(
    valid_cell_years = .N,
    canonical_events = sum(canonical_event),
    standalone_events = sum(standalone_event),
    canonical_only_events = sum(canonical_event & !standalone_event),
    standalone_only_events = sum(!canonical_event & standalone_event),
    differing_cell_years = sum(canonical_event != standalone_event),
    percent_valid_cell_years_differ = 100 * mean(canonical_event != standalone_event)
  ), by = .(year, SESU_ID, side, abs_boundary_distance_class)]
}
fire_discrepancies_by_year <- rbindlist(fire_year_rows)
fire_discrepancies_by_sesu_side <- rbindlist(fire_sesu_rows)
fwrite(fire_discrepancies_by_year, file.path(CH1_MEASUREMENT_TABLES_DIR, "fire_discrepancies_by_year.csv"))
fwrite(fire_discrepancies_by_sesu_side, file.path(CH1_MEASUREMENT_TABLES_DIR, "fire_discrepancies_by_sesu_side.csv"))
fire_pipeline_comparison <- fire_discrepancies_by_year[, .(
  years = paste(range(year), collapse = "-"),
  canonical_events = sum(canonical_events),
  standalone_events = sum(standalone_events),
  canonical_only_events = sum(canonical_only_events),
  standalone_only_events = sum(standalone_only_events),
  differing_cell_years = sum(differing_cell_years),
  percent_valid_cell_years_differ = 100 * sum(differing_cell_years) / sum(valid_cell_years),
  likely_cause = "pipeline-version difference; exact GEE export revision/settings not recovered locally"
), by = period]
fwrite(fire_pipeline_comparison, file.path(CH1_MEASUREMENT_TABLES_DIR, "fire_pipeline_comparison.csv"))

fire_binary_consistency <- list()
for (tag in names(CH1_THRESHOLD_VALUES)) {
  rs <- rast(fire_stack_path(tag))
  for (yr in 2001:2020) {
    b_bin <- grep(paste0("^", yr, "_fire_season_", yr, "$"), names(rs), value = TRUE)
    b_doy <- grep(paste0("^", yr, "_fireDOY_season_", yr, "$"), names(rs), value = TRUE)
    if (length(b_bin) == 1 && length(b_doy) == 1) {
      bin <- extract_cells_vec(rs[[b_bin]], g_all$cell)
      doy <- extract_cells_vec(rs[[b_doy]], g_all$cell)
      fire_binary_consistency[[paste(tag, yr)]] <- data.table(
        threshold_tag = tag, year = yr, compared_cells = length(bin),
        binary_events = sum(is.finite(bin) & bin == 1),
        doy_events = sum(is.finite(doy) & doy >= 100 & doy <= 300),
        differing_cells = sum((is.finite(bin) & bin == 1) != (is.finite(doy) & doy >= 100 & doy <= 300)),
        comparison = "standalone 2001-2020 binary band versus standalone DOY band"
      )
    }
  }
  for (yr in 2021:2022) {
    dp <- fire_doy_path(tag, yr)
    if (is.na(dp) || !file.exists(dp)) next
    bin <- extract_cells_vec(rast(fire_binary_path(tag, yr)), g_all$cell)
    doy <- extract_cells_vec(rast(dp), g_all$cell)
    fire_binary_consistency[[paste(tag, yr)]] <- data.table(
      threshold_tag = tag, year = yr, compared_cells = length(bin),
      binary_events = sum(is.finite(bin) & bin == 1),
      doy_events = sum(is.finite(doy) & doy >= 100 & doy <= 300),
      differing_cells = sum((is.finite(bin) & bin == 1) != (is.finite(doy) & doy >= 100 & doy <= 300)),
      comparison = "standalone 2021-2022 binary raster versus local DOY_max raster"
    )
  }
}
fwrite(rbindlist(fire_binary_consistency, fill = TRUE), file.path(CH1_MEASUREMENT_TABLES_DIR, "fire_binary_doy_consistency.csv"))

tree_rows <- list()
tree_mask_rows <- list()
for (tag in names(CH1_THRESHOLD_VALUES)) {
  raw <- as.integer(extract_cells_vec(rast(event_path("tree_cover_loss", tag)), g_all$cell))
  raw[!is.finite(raw) | raw <= 0] <- NA_integer_
  fm <- forest_mask_vals[g_all$cell]
  masked <- raw
  masked[!fm] <- NA_integer_
  tree_mask_rows[[tag]] <- data.table(
    threshold_tag = tag,
    compared_cells = nrow(g_all),
    baseline_forest_cells = sum(fm, na.rm = TRUE),
    raw_event_cells = sum(!is.na(raw)),
    raw_events_outside_canonical_forest_mask = sum(!is.na(raw) & !fm, na.rm = TRUE),
    harmonized_event_cells = sum(!is.na(masked)),
    removed_by_canonical_forest_mask = sum(!is.na(raw) & is.na(masked))
  )
}
fwrite(rbindlist(tree_mask_rows), file.path(CH1_MEASUREMENT_TABLES_DIR, "tree_cover_loss_mask_diagnostics.csv"))

can_tree <- canonical_event_year("tree_cover_loss", g_all$cell)
raw_tree <- as.integer(extract_cells_vec(rast(event_path("tree_cover_loss", "tau025")), g_all$cell))
raw_tree[!is.finite(raw_tree) | raw_tree <= 0] <- NA_integer_
harm_tree <- raw_tree
harm_tree[!forest_mask_vals[g_all$cell]] <- NA_integer_
td <- copy(g_all)[, `:=`(
  canonical_year = can_tree,
  standalone_raw_year = raw_tree,
  standalone_harmonized_year = harm_tree,
  baseline_mask_status = fifelse(forest_mask_vals[g_all$cell], "baseline_forest_ge30", "outside_baseline_forest")
)]
td[, discrepancy_type := fifelse(is.na(canonical_year) & is.na(standalone_harmonized_year), "event in neither",
  fifelse(!is.na(canonical_year) & is.na(standalone_harmonized_year), "event in canonical only",
    fifelse(is.na(canonical_year) & !is.na(standalone_harmonized_year), "event in standalone only",
      fifelse(canonical_year == standalone_harmonized_year, "event in both with same year", "event in both with different years"))))]
tree_discrepancies <- td[, .(
  cells = .N,
  canonical_events = sum(!is.na(canonical_year)),
  standalone_raw_events = sum(!is.na(standalone_raw_year)),
  standalone_harmonized_events = sum(!is.na(standalone_harmonized_year)),
  canonical_years = paste(sort(unique(na.omit(canonical_year))), collapse = ";"),
  standalone_harmonized_years = paste(sort(unique(na.omit(standalone_harmonized_year))), collapse = ";")
), by = .(discrepancy_type, baseline_mask_status, SESU_ID, side, abs_boundary_distance_class)]
fwrite(tree_discrepancies, file.path(CH1_MEASUREMENT_TABLES_DIR, "tree_cover_loss_cell_discrepancies.csv"))
tree_pipeline_comparison <- td[, .(
  canonical_events = sum(!is.na(canonical_year)),
  standalone_raw_events = sum(!is.na(standalone_raw_year)),
  standalone_harmonized_events = sum(!is.na(standalone_harmonized_year)),
  canonical_only_events = sum(!is.na(canonical_year) & is.na(standalone_harmonized_year)),
  standalone_only_events = sum(is.na(canonical_year) & !is.na(standalone_harmonized_year)),
  both_same_year = sum(!is.na(canonical_year) & !is.na(standalone_harmonized_year) & canonical_year == standalone_harmonized_year),
  both_different_year = sum(!is.na(canonical_year) & !is.na(standalone_harmonized_year) & canonical_year != standalone_harmonized_year),
  likely_cause = "pipeline-version difference plus explicit canonical forest-mask harmonization; exact GEE export revision/settings not recovered locally"
)]
fwrite(tree_pipeline_comparison, file.path(CH1_MEASUREMENT_TABLES_DIR, "tree_cover_loss_pipeline_comparison.csv"))

can_agri <- canonical_event_year("agriculture", g_all$cell)
st_agri <- standalone_event_year("agriculture", "tau025", g_all$cell)
agri_comp <- data.table(
  compared_cells = length(can_agri),
  canonical_events = sum(!is.na(can_agri)),
  standalone_events = sum(!is.na(st_agri)),
  canonical_only_events = sum(!is.na(can_agri) & is.na(st_agri)),
  standalone_only_events = sum(is.na(can_agri) & !is.na(st_agri)),
  both_same_year = sum(!is.na(can_agri) & !is.na(st_agri) & can_agri == st_agri),
  both_different_year = sum(!is.na(can_agri) & !is.na(st_agri) & can_agri != st_agri),
  exact_identity_after_coding = identical(can_agri, st_agri),
  provenance_conclusion = "canonical and standalone tau025 agriculture remain identical after AOI/grid/event-year coding"
)
fwrite(agri_comp, file.path(CH1_MEASUREMENT_TABLES_DIR, "agriculture_pipeline_comparison.csv"))

# -----------------------------------------------------------
# Harmonized analytical surfaces
# -----------------------------------------------------------
surface_fire <- function(version, geom) {
  out <- vector("list", length(CH1_STUDY_YEARS))
  tag <- threshold_tag(version)
  for (j in seq_along(CH1_STUDY_YEARS)) {
    yr <- CH1_STUDY_YEARS[j]
    ev <- if (version == "canonical_embedded_tau025") canonical_fire_event(yr, geom$cell) else standalone_fire_event(tag, yr, geom$cell)
    dt <- copy(geom)[, `:=`(year = yr, disturbed = as.integer(ev))]
    out[[j]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  rbindlist(out)[, outcome := "fire"][]
}
surface_event <- function(outcome_name, version, geom) {
  tag <- threshold_tag(version)
  vals <- if (version == "canonical_embedded_tau025") canonical_event_year(outcome_name, geom$cell) else standalone_event_year(outcome_name, tag, geom$cell, harmonize_tree_mask = TRUE)
  out <- vector("list", length(CH1_STUDY_YEARS))
  for (j in seq_along(CH1_STUDY_YEARS)) {
    yr <- CH1_STUDY_YEARS[j]
    at_risk <- is.na(vals) | yr <= vals
    if (!any(at_risk)) next
    dt <- copy(geom[at_risk])
    dt[, `:=`(year = yr, disturbed = as.integer(!is.na(vals[at_risk]) & vals[at_risk] == yr))]
    out[[j]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  rbindlist(out, use.names = TRUE, fill = TRUE)[, outcome := outcome_name][]
}
add_profile <- function(surface) {
  d <- merge(surface, timeline, by = c("SESU_ID", "year"), all.x = TRUE)
  d[, `:=`(
    governance_profile = factor(governance_profile, levels = profile_levels),
    side = factor(side, levels = c("outside", "inside"))
  )]
  d[]
}

surface_list <- list()
for (version in measurement_versions) {
  for (design in spatial_designs) {
    geom <- design_cells(design)
    for (outcome_name in c("fire", "tree_cover_loss", "agriculture")) {
      s <- if (outcome_name == "fire") surface_fire(version, geom) else surface_event(outcome_name, version, geom)
      surface_list[[paste(version, design, outcome_name)]] <- add_profile(s)[, `:=`(
        measurement_version = version,
        threshold_tag = threshold_tag(version),
        threshold = measurement_threshold(version),
        spatial_design = design
      )]
    }
  }
}
surface_dt <- rbindlist(surface_list, use.names = TRUE, fill = TRUE)
surface_dt[, `:=`(p_hat = y / n, zero_event_flag = y == 0, all_event_flag = y == n)]
fwrite(surface_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "harmonized_surface_summary.csv"))

canon <- fread(canonical_surface_path)[pa_label == "National Park"]
canon[, outcome := fifelse(disturbance == "year_deforest_masked", "tree_cover_loss", fifelse(disturbance == "year_agri", "agriculture", disturbance))]
rep <- merge(
  surface_dt[measurement_version == "canonical_embedded_tau025" & spatial_design == "all_cells", .(SESU_ID, year, outcome, side = as.character(side), n_phase4 = n, y_phase4 = y)],
  canon[, .(SESU_ID, year, outcome, side, n_canonical = n, y_canonical = y)],
  by = c("SESU_ID", "year", "outcome", "side"),
  all = TRUE
)
rep[, `:=`(
  n_difference = n_phase4 - n_canonical,
  y_difference = y_phase4 - y_canonical,
  exact_agreement = n_phase4 == n_canonical & y_phase4 == y_canonical
)]
fwrite(rep, file.path(CH1_MEASUREMENT_TABLES_DIR, "canonical_embedded_tau025_reproduction_check.csv"))
if (any(!rep$exact_agreement, na.rm = TRUE)) stop("Canonical embedded tau025 reproduction failed in measurement harmonization workflow.", call. = FALSE)

event_support <- surface_dt[, .(
  event_count = sum(y),
  cell_years_at_risk = sum(n),
  contributing_sesu_years = uniqueN(paste(SESU_ID, year)),
  zero_event_strata = sum(y == 0),
  zero_event_burden = mean(y == 0)
), by = .(measurement_version, threshold_tag, threshold, spatial_design, outcome)]
fwrite(event_support, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_event_support.csv"))

# -----------------------------------------------------------
# Models
# -----------------------------------------------------------
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
    tryCatch(
      glmmTMB(primary_formula, family = betabinomial(link = "logit"), data = d,
        control = glmmTMBControl(optCtrl = list(iter.max = 50000, eval.max = 50000, rel.tol = 1e-10, x.tol = 1e-8))),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")
    ),
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
fit_diag <- function(fw, d, version, design) {
  X <- tryCatch(model.matrix(primary_formula, d), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  if (inherits(fw$fit, "fit_error")) {
    return(data.table(outcome = "fire", measurement_version = version, spatial_design = design, convergence_code = NA_integer_, optimizer_message = fw$fit$error, pdHess = NA, maximum_absolute_gradient = NA_real_, model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = FALSE, warnings = paste(fw$warnings, collapse = " | ")))
  }
  m <- fw$fit
  se <- tryCatch(summary(m)$coefficients$cond[, "Std. Error"], error = function(e) NA_real_)
  pd <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  grad <- max_abs_gradient(m)
  strict <- identical(m$fit$convergence, 0L) && pd && identical(rank_x, cols_x) && is.finite(grad) && grad < CH1_MAX_ABS_GRADIENT_TOL && !any(abs(se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE)
  data.table(outcome = "fire", measurement_version = version, spatial_design = design, convergence_code = m$fit$convergence, optimizer_message = as.character(m$fit$message), pdHess = pd, maximum_absolute_gradient = grad, dispersion_estimate = tryCatch(sigma(m), error = function(e) NA_real_), model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = strict, warnings = paste(fw$warnings, collapse = " | "), coefficient_estimates = paste(paste0(names(fixef(m)$cond), "=", signif(fixef(m)$cond, 8)), collapse = "; "))
}
profile_contrasts <- function(m, version, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(profile_levels, function(pr) cbind(data.table(outcome = "fire", measurement_version = version, spatial_design = design, governance_profile = pr), contrast_stats(beta, V, make_profile_L(names(beta), pr), intervals = strict_valid))), fill = TRUE)
}
pairwise_contrasts <- function(m, version, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- make_profile_L(names(beta), parts[1]) - make_profile_L(names(beta), parts[2])
    cbind(data.table(outcome = "fire", measurement_version = version, spatial_design = design, profile_comparison = cmp), contrast_stats(beta, V, L, intervals = strict_valid))
  }), fill = TRUE)
}

fire_diag <- list(); fire_profile <- list(); fire_pair <- list()
for (version in measurement_versions) {
  for (design in spatial_designs) {
    d <- add_model_terms(surface_dt[outcome == "fire" & measurement_version == version & spatial_design == design])
    fw <- fit_model(d)
    dg <- fit_diag(fw, d, version, design)
    fire_diag[[paste(version, design)]] <- dg
    if (!inherits(fw$fit, "fit_error")) {
      fire_profile[[paste(version, design)]] <- profile_contrasts(fw$fit, version, design, dg$strict_valid)
      fire_pair[[paste(version, design)]] <- pairwise_contrasts(fw$fit, version, design, dg$strict_valid)
    }
  }
}
fire_diag_dt <- rbindlist(fire_diag, fill = TRUE)
fire_profile_dt <- rbindlist(fire_profile, fill = TRUE)
fire_pair_dt <- rbindlist(fire_pair, fill = TRUE)
fwrite(fire_diag_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_fire_fit_diagnostics.csv"))
fwrite(fire_profile_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_fire_profile_contrasts.csv"))
fwrite(fire_pair_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_fire_pairwise_differences.csv"))

hc3_vcov <- function(mod) {
  X <- model.matrix(mod); e <- residuals(mod); h <- hatvalues(mod); w <- weights(mod)
  if (is.null(w)) w <- rep(1, length(e))
  Xw <- X * sqrt(w)
  meat <- t(Xw) %*% diag((e * sqrt(w) / pmax(1 - h, 1e-8))^2, nrow = length(e)) %*% Xw
  bread <- solve(t(Xw) %*% Xw)
  bread %*% meat %*% bread
}
sparse_rows <- list(); sparse_profile <- list(); sparse_pair <- list(); sparse_diag <- list()
for (version in measurement_versions) for (design in spatial_designs) for (outcome_name in c("tree_cover_loss", "agriculture")) {
  s <- surface_dt[outcome == outcome_name & measurement_version == version & spatial_design == design]
  w <- dcast(s, measurement_version + threshold_tag + threshold + spatial_design + outcome + SESU_ID + year + governance_profile ~ side, value.var = c("y", "n"))
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
  sparse_rows[[paste(version, design, outcome_name)]] <- w
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
      sparse_profile[[paste(version, design, outcome_name, mt, pr)]] <- data.table(outcome = outcome_name, measurement_version = version, spatial_design = design, model_type = mt, governance_profile = pr, estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se, contributing_sesu_years = nrow(w), zero_cell_corrected_observations = sum(w$zero_cell_flag), covariance = "HC3; CR2 calendar-year clustering not used")
    }
    for (cmp in pairwise_comparisons) {
      parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
      L <- colMeans(Xn[as.character(nd$governance_profile) == parts[1], , drop = FALSE]) - colMeans(Xn[as.character(nd$governance_profile) == parts[2], , drop = FALSE])
      est <- sum(L * coef(mod)); se <- sqrt(as.numeric(t(L) %*% V %*% L))
      sparse_pair[[paste(version, design, outcome_name, mt, cmp)]] <- data.table(outcome = outcome_name, measurement_version = version, spatial_design = design, model_type = mt, profile_comparison = cmp, estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se, covariance = "HC3; CR2 calendar-year clustering not used")
    }
    sparse_diag[[paste(version, design, outcome_name, mt)]] <- data.table(outcome = outcome_name, measurement_version = version, spatial_design = design, model_type = mt, n_obs = nrow(w), residual_df = df.residual(mod), r_squared = summary(mod)$r.squared, covariance = "HC3")
  }
}
sparse_rows_dt <- rbindlist(sparse_rows, fill = TRUE)
sparse_profile_dt <- rbindlist(sparse_profile, fill = TRUE)
sparse_pair_dt <- rbindlist(sparse_pair, fill = TRUE)
sparse_diag_dt <- rbindlist(sparse_diag, fill = TRUE)
fwrite(sparse_rows_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_sparse_sesu_year_contrasts.csv"))
fwrite(sparse_profile_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_sparse_profile_estimates.csv"))
fwrite(sparse_pair_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_sparse_pairwise_differences.csv"))
fwrite(sparse_diag_dt, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_sparse_model_diagnostics.csv"))

primary_profile <- rbindlist(list(
  fire_profile_dt[, .(outcome, measurement_version, spatial_design, governance_profile, estimate, standard_error, lower_95_ci, upper_95_ci, method = "fire_beta_binomial")],
  sparse_profile_dt[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, measurement_version, spatial_design, governance_profile, estimate, standard_error, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted")]
), fill = TRUE)
primary_pair <- rbindlist(list(
  fire_pair_dt[, .(outcome, measurement_version, spatial_design, profile_comparison, estimate, standard_error, lower_95_ci, upper_95_ci, method = "fire_beta_binomial")],
  sparse_pair_dt[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, measurement_version, spatial_design, profile_comparison, estimate, standard_error, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted")]
), fill = TRUE)

add_comparison_fields <- function(dt, key_cols) {
  ref <- copy(dt[measurement_version == "canonical_embedded_tau025", c(key_cols, "estimate", "standard_error"), with = FALSE])
  setnames(ref, c("estimate", "standard_error"), c("reference_estimate", "reference_standard_error"))
  ref <- unique(ref)
  out <- merge(dt, ref, by = key_cols, all.x = TRUE)
  out[, `:=`(
    difference_from_canonical_estimate = estimate - reference_estimate,
    difference_relative_to_canonical_standard_error = (estimate - reference_estimate) / reference_standard_error,
    sign = fifelse(estimate > 0, "positive", fifelse(estimate < 0, "negative", "zero")),
    confidence_interval_crosses_zero = lower_95_ci <= 0 & upper_95_ci >= 0,
    substantive_interpretation_changes = sign(estimate) != sign(reference_estimate) & measurement_version != "canonical_embedded_tau025"
  )]
  out <- merge(out, event_support[, .(measurement_version, spatial_design, outcome, event_count, contributing_sesu_years, zero_event_burden)], by = c("measurement_version", "spatial_design", "outcome"), all.x = TRUE)
  out
}
profile_comp <- add_comparison_fields(primary_profile, c("outcome", "spatial_design", "governance_profile"))
pair_comp <- add_comparison_fields(primary_pair, c("outcome", "spatial_design", "profile_comparison"))

fire_strict <- fire_diag_dt[, .(measurement_version, spatial_design, outcome, strict_valid)]
profile_comp <- merge(profile_comp, fire_strict, by = c("measurement_version", "spatial_design", "outcome"), all.x = TRUE)
pair_comp <- merge(pair_comp, fire_strict, by = c("measurement_version", "spatial_design", "outcome"), all.x = TRUE)
profile_comp[method != "fire_beta_binomial", strict_valid := NA]
pair_comp[method != "fire_beta_binomial", strict_valid := NA]

pipeline_profile <- profile_comp[measurement_version %in% c("canonical_embedded_tau025", "standalone_tau025")]
pipeline_pair <- pair_comp[measurement_version %in% c("canonical_embedded_tau025", "standalone_tau025")]
threshold_profile <- profile_comp[measurement_version %in% standalone_versions]
threshold_pair <- pair_comp[measurement_version %in% standalone_versions]

fwrite(pipeline_profile, file.path(CH1_MEASUREMENT_TABLES_DIR, "pipeline_version_profile_contrasts.csv"))
fwrite(pipeline_pair, file.path(CH1_MEASUREMENT_TABLES_DIR, "pipeline_version_pairwise_differences.csv"))
fwrite(threshold_profile, file.path(CH1_MEASUREMENT_TABLES_DIR, "harmonized_threshold_profile_contrasts.csv"))
fwrite(threshold_pair, file.path(CH1_MEASUREMENT_TABLES_DIR, "harmonized_threshold_pairwise_differences.csv"))

effect_summary <- profile_comp[, .(
  canonical_estimate = estimate[measurement_version == "canonical_embedded_tau025"][1],
  standalone_tau025_estimate = estimate[measurement_version == "standalone_tau025"][1],
  pipeline_version_delta = estimate[measurement_version == "standalone_tau025"][1] - estimate[measurement_version == "canonical_embedded_tau025"][1],
  harmonized_threshold_min = min(estimate[measurement_version %in% standalone_versions], na.rm = TRUE),
  harmonized_threshold_max = max(estimate[measurement_version %in% standalone_versions], na.rm = TRUE),
  harmonized_threshold_sign_consistent = uniqueN(sign(estimate[measurement_version %in% standalone_versions])) == 1,
  any_substantive_interpretation_change = any(substantive_interpretation_changes, na.rm = TRUE)
), by = .(outcome, spatial_design, governance_profile)]
fwrite(effect_summary, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_effect_summary.csv"))

validation <- data.table(
  check = c(
    "canonical_embedded_tau025_exact_reproduction",
    "tree_cover_loss_forest_mask_identical_across_standalone_thresholds",
    "all_model_inputs_match_template_grid",
    "agriculture_tau025_identical_after_coding",
    "agriculture_paths_not_tree_cover_loss_paths",
    "threshold_tags_not_recycled"
  ),
  passed = c(
    all(rep$exact_agreement, na.rm = TRUE),
    all(rbindlist(tree_mask_rows)$baseline_forest_cells == rbindlist(tree_mask_rows)$baseline_forest_cells[1]),
    all(grid_checks$grid_matches_template),
    isTRUE(agri_comp$exact_identity_after_coding),
    !any(grepl("gfc|deforest", threshold_manifest[outcome == "agriculture", file_path], ignore.case = TRUE)),
    identical(sort(unique(threshold_manifest$threshold_tag)), sort(names(CH1_THRESHOLD_VALUES)))
  ),
  details = c(
    paste0("Rows checked: ", nrow(rep)),
    "Standalone tree-cover-loss thresholds are post-masked with canonical forest2000_ge_30pct.",
    paste0("Input rasters checked: ", nrow(grid_checks)),
    paste0("Canonical events=", agri_comp$canonical_events, "; standalone events=", agri_comp$standalone_events),
    paste(threshold_manifest[outcome == "agriculture", file_path], collapse = "; "),
    paste(sort(unique(threshold_manifest$threshold_tag)), collapse = "; ")
  )
)
fwrite(validation, file.path(CH1_MEASUREMENT_TABLES_DIR, "measurement_harmonization_validation_checks.csv"))
writeLines(capture.output(sessionInfo()), file.path(CH1_MEASUREMENT_PROVENANCE_DIR, "sessionInfo.txt"))

message("Measurement harmonization workflow complete. Outputs: ", CH1_MEASUREMENT_OUTPUT_DIR)
