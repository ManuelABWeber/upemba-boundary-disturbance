# ===========================================================
# CHAPTER 1 FIRE 2021-2022 HARMONIZATION WORKFLOW
# ===========================================================
# Rebuilds local 2021-2022 FireCCI products to match the
# 2001-2020 seasonal burned-fraction definition as closely as the
# local monthly JD rasters permit.
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

OUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_fire_harmonization_dev")
TABLE_DIR <- file.path(OUT_DIR, "tables")
PROV_DIR <- file.path(OUT_DIR, "provenance")
LOG_DIR <- file.path(OUT_DIR, "logs")
MODEL_DIR <- file.path(OUT_DIR, "models")
FIG_DIR <- file.path(OUT_DIR, "figures")
FIRE_OUT_DIR <- file.path(CH1_OUTPUT_ROOT, "stage_outputs", "fire_harmonized_500m")
for (p in c(OUT_DIR, TABLE_DIR, PROV_DIR, LOG_DIR, MODEL_DIR, FIG_DIR, FIRE_OUT_DIR)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

FIRE_DOY_MIN <- 100L
FIRE_DOY_MAX <- 300L
YEARS_LOCAL <- 2021L:2022L
THRESHOLDS <- CH1_THRESHOLD_VALUES
zcrit <- qnorm(1 - CH1_ALPHA / 2)
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
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
rel_path <- function(path) {
  rp <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", normalizePath(CH1_ROOT, winslash = "/", mustWork = FALSE)), "/?"), "", rp)
}
threshold_from_tag <- function(tag) unname(CH1_THRESHOLD_VALUES[[tag]])
distance_class <- function(x) {
  fifelse(abs(x) <= 5, "0-5 km",
    fifelse(abs(x) <= 10, "5-10 km",
      fifelse(abs(x) <= 20, "10-20 km", ">20 km")))
}
kappa2 <- function(a, b) {
  tab <- table(factor(a, levels = c(FALSE, TRUE)), factor(b, levels = c(FALSE, TRUE)))
  n <- sum(tab)
  if (n == 0) return(NA_real_)
  po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (!is.finite(pe) || pe == 1) return(NA_real_)
  (po - pe) / (1 - pe)
}

cov_path <- file.path(CH1_RUN_DIR, "SESU_covariates_500m.tif")
sesu_path <- file.path(CH1_RUN_DIR, "SESU_ID_500m.tif")
stop_missing(cov_path); stop_missing(sesu_path)
r_cov <- rast(cov_path)
r_sesu <- rast(sesu_path)
template <- r_cov[[1]]

fire_root <- file.path(CH1_ROOT, "data", "fire")
stop_missing(fire_root)
threshold_manifest <- fread(file.path(CH1_ROOT, "config", "disturbance_threshold_manifest.csv"))
threshold_manifest[, abs_path := normalizePath(file.path(CH1_ROOT, file_path), winslash = "/", mustWork = FALSE)]

all_fire_files <- list.files(fire_root, recursive = TRUE, full.names = TRUE)
raster_files <- all_fire_files[grepl("\\.(tif|tiff)$", all_fire_files, ignore.case = TRUE)]

file_year <- function(path) as.integer(sub("^([0-9]{4}).*$", "\\1", basename(dirname(path))))
file_month <- function(path) as.integer(sub("^[0-9]{4}([0-9]{2}).*$", "\\1", basename(dirname(path))))
quantity_type <- function(path) {
  b <- basename(path)
  if (grepl("-JD\\.", b, ignore.case = TRUE)) return("burn_date_doy")
  if (grepl("-CL\\.", b, ignore.case = TRUE)) return("confidence_or_quality")
  if (grepl("-LC\\.", b, ignore.case = TRUE)) return("land_cover")
  "unknown"
}

inventory_one <- function(path) {
  r <- rast(path)
  vals <- tryCatch(spatSample(r, size = 10000, method = "regular", values = TRUE, na.rm = FALSE)[, 1], error = function(e) rep(NA_real_, 0))
  data.table(
    filename = basename(path),
    file_path = rel_path(path),
    year = file_year(path),
    month = file_month(path),
    acquisition_period = basename(dirname(path)),
    nrow = nrow(r),
    ncol = ncol(r),
    crs = crs(r, describe = TRUE)$name,
    resolution_x = res(r)[1],
    resolution_y = res(r)[2],
    extent = paste(as.vector(ext(r)), collapse = ","),
    origin_x = origin(r)[1],
    origin_y = origin(r)[2],
    band_names = paste(names(r), collapse = ";"),
    data_type = paste(datatype(r), collapse = ";"),
    no_data_value = paste(NAflag(r), collapse = ";"),
    sampled_min = suppressWarnings(min(vals, na.rm = TRUE)),
    sampled_max = suppressWarnings(max(vals, na.rm = TRUE)),
    quantity_type = quantity_type(path),
    multiple_observations_same_pixel_within_year = "monthly files can contain different positive JD values for the same annual pixel",
    md5 = as.character(tools::md5sum(path))
  )
}
source_inventory <- rbindlist(lapply(raster_files, inventory_one), fill = TRUE)
fwrite(source_inventory, file.path(TABLE_DIR, "fire_2021_2022_source_inventory.csv"))
if (!all(YEARS_LOCAL %in% source_inventory[quantity_type == "burn_date_doy", year])) {
  stop("Raw local fire source does not contain JD burn-date rasters for both 2021 and 2022.", call. = FALSE)
}

previous_workflow <- data.table(
  component = c("source selection", "annual native DOY", "native burned binary", "500 m burned fraction", "500 m descriptive DOY", "disagreement cause"),
  previous_workflow = c(
    "Script 1 selected monthly files with JD in the filename for April-October.",
    "Monthly positive JD rasters were merged with terra::max(..., na.rm=TRUE).",
    "The binary was !is.na(doy_native) after nonpositive JD values were set to NA.",
    "The binary was projected to the 500 m template with method='average' and thresholded by tau.",
    "The native maximum-DOY raster was projected to 500 m with method='near' and then masked to burned500.",
    "Binary and DOY-derived classifications disagreed because the binary fraction was area-based while DOY was nearest-neighbour and based on maximum annual DOY."
  ),
  harmonized_workflow = c(
    "Use the same local monthly JD rasters for April-October.",
    "Monthly positive seasonal JD rasters are merged with terra::min(..., na.rm=TRUE).",
    "The seasonal binary is JD within 100-300; all other native cells are set to 0.",
    "The seasonal binary is projected to the canonical 500 m template with method='average' and thresholded by tau.",
    "Earliest positive seasonal DOY is projected to the canonical 500 m template with method='min' and masked to cells meeting the threshold.",
    "The modeled outcome is the thresholded burned-fraction binary; DOY is descriptive only."
  ),
  evidence = c(
    "scripts/Script 1_Fire agri preprocessing.R find_fire_monthly_jd()",
    "scripts/Script 1_Fire agri preprocessing.R uses max(doy_native, r, na.rm=TRUE)",
    "scripts/Script 1_Fire agri preprocessing.R uses as.int(!is.na(doy_native))",
    "scripts/Script 1_Fire agri preprocessing.R uses project(..., method='average')",
    "scripts/Script 1_Fire agri preprocessing.R uses project(doy_native, template, method='near')",
    "analysis_measurement_harmonization_dev/tables/fire_binary_doy_consistency.csv"
  )
)
fwrite(previous_workflow, file.path(TABLE_DIR, "fire_previous_workflow_audit.csv"))

jd_files_for_year <- function(target_year) {
  rows <- source_inventory[
    quantity_type == "burn_date_doy" &
      source_inventory[["year"]] == target_year &
      month %in% 4:10
  ]
  ff <- file.path(CH1_ROOT, rows$file_path)
  ff[order(file_month(ff), ff)]
}
make_source_stack <- function(year) {
  jf <- jd_files_for_year(year)
  if (length(jf) == 0) stop("No JD source files found for ", year, call. = FALSE)
  r <- rast(jf)
  names(r) <- paste0("m", file_month(jf))
  # Crop to the template extent transformed to WGS84, with a small margin, before reprojection.
  template_ext_ll <- ext(project(template, crs(r)))
  e <- ext(xmin(template_ext_ll) - 0.25, xmax(template_ext_ll) + 0.25, ymin(template_ext_ll) - 0.25, ymax(template_ext_ll) + 0.25)
  crop(r, e, snap = "out")
}
annual_min_doy_native <- function(year) {
  r <- make_source_stack(year)
  seasonal <- ifel(r >= FIRE_DOY_MIN & r <= FIRE_DOY_MAX, r, NA)
  app(seasonal, fun = function(...) {
    x <- c(...)
    x <- x[is.finite(x) & x >= FIRE_DOY_MIN & x <= FIRE_DOY_MAX]
    if (!length(x)) return(NA_real_)
    min(x)
  })
}
build_harmonized_year <- function(year) {
  message("Building harmonized fire products for ", year)
  doy_min_native <- annual_min_doy_native(year)
  names(doy_min_native) <- "fireDOY_min_native"
  burned_native <- ifel(is.na(doy_min_native), 0, 1)
  names(burned_native) <- "fire_burned_season_native"
  burned_frac_500 <- project(burned_native, template, method = "average")
  names(burned_frac_500) <- "burned_fraction_500m"
  doy_500 <- project(doy_min_native, template, method = "min")
  doy_500[is.na(doy_500)] <- 0
  doy_500 <- round(doy_500)
  out <- list()
  for (tag in names(THRESHOLDS)) {
    tau <- THRESHOLDS[[tag]]
    burned <- as.int(burned_frac_500 >= tau)
    burned[is.na(burned)] <- 0
    names(burned) <- "fire_burned"
    doy_masked <- mask(doy_500, burned, maskvalues = 0)
    doy_masked[is.na(doy_masked)] <- 0
    names(doy_masked) <- "fireDOY_min"
    bin_path <- file.path(FIRE_OUT_DIR, sprintf("fireBurned_AprOct_%d_500m_%s_harmonized.tif", year, tag))
    doy_path <- file.path(FIRE_OUT_DIR, sprintf("fireDOY_min_AprOct_%d_500m_%s_harmonized.tif", year, tag))
    if (file.exists(bin_path) || file.exists(doy_path)) stop("Refusing to overwrite existing harmonized fire output for ", year, " ", tag, call. = FALSE)
    writeRaster(burned, bin_path, datatype = "INT1U", overwrite = FALSE, wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2")))
    writeRaster(doy_masked, doy_path, datatype = "INT2S", overwrite = FALSE, wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2")))
    out[[tag]] <- data.table(year = year, threshold = tau, threshold_tag = tag, binary_path = bin_path, doy_path = doy_path)
  }
  rbindlist(out)
}

expected_outputs <- CJ(year = YEARS_LOCAL, threshold_tag = names(THRESHOLDS))
expected_outputs[, `:=`(
  binary_path = file.path(FIRE_OUT_DIR, sprintf("fireBurned_AprOct_%d_500m_%s_harmonized.tif", year, threshold_tag)),
  doy_path = file.path(FIRE_OUT_DIR, sprintf("fireDOY_min_AprOct_%d_500m_%s_harmonized.tif", year, threshold_tag))
)]
if (!all(file.exists(expected_outputs$binary_path) & file.exists(expected_outputs$doy_path))) {
  built <- rbindlist(lapply(YEARS_LOCAL, build_harmonized_year))
} else {
  built <- copy(expected_outputs)
  built[, threshold := THRESHOLDS[threshold_tag]]
}

input_hashes <- source_inventory[quantity_type == "burn_date_doy" & year %in% YEARS_LOCAL & month %in% 4:10,
  .(year, month, source_file = file_path, file_hash = md5, quantity_type)]
fwrite(input_hashes, file.path(PROV_DIR, "fire_harmonized_input_hashes.csv"))

validate_one <- function(year, tag) {
  bin_path <- file.path(FIRE_OUT_DIR, sprintf("fireBurned_AprOct_%d_500m_%s_harmonized.tif", year, tag))
  doy_path <- file.path(FIRE_OUT_DIR, sprintf("fireDOY_min_AprOct_%d_500m_%s_harmonized.tif", year, tag))
  b <- rast(bin_path); d <- rast(doy_path)
  bv <- values(b)[, 1]; dv <- values(d)[, 1]
  data.table(
    year = year,
    threshold_tag = tag,
    threshold = threshold_from_tag(tag),
    binary_file = rel_path(bin_path),
    doy_file = rel_path(doy_path),
    grid_matches_template = compareGeom(template, b, stopOnError = FALSE) && compareGeom(template, d, stopOnError = FALSE),
    binary_domain_ok = all(na.omit(unique(bv)) %in% c(0, 1)),
    doy_domain_ok = all(na.omit(unique(dv)) == 0 | (na.omit(unique(dv)) >= FIRE_DOY_MIN & na.omit(unique(dv)) <= FIRE_DOY_MAX)),
    every_binary_one_has_doy = all(dv[bv == 1] > 0, na.rm = TRUE),
    every_binary_zero_has_zero_doy = all(dv[bv == 0] == 0, na.rm = TRUE),
    event_count = sum(bv == 1, na.rm = TRUE),
    source_files = paste(input_hashes[["source_file"]][input_hashes[["year"]] == year], collapse = ";"),
    validation_status = "pass"
  )
}
validation <- rbindlist(lapply(YEARS_LOCAL, function(y) rbindlist(lapply(names(THRESHOLDS), function(tg) validate_one(y, tg)))))
monotone <- validation[, .(monotone_events = event_count[threshold_tag == "tau010"] >= event_count[threshold_tag == "tau025"] & event_count[threshold_tag == "tau025"] >= event_count[threshold_tag == "tau050"]), by = year]
validation <- merge(validation, monotone, by = "year", all.x = TRUE)
validation[!(grid_matches_template & binary_domain_ok & doy_domain_ok & every_binary_one_has_doy & every_binary_zero_has_zero_doy & monotone_events), validation_status := "fail"]
fwrite(validation, file.path(TABLE_DIR, "fire_harmonized_validation.csv"))
if (any(validation$validation_status != "pass")) stop("Harmonized fire validation failed.", call. = FALSE)
event_counts <- validation[, .(year, threshold, threshold_tag, event_count)]
fwrite(event_counts, file.path(TABLE_DIR, "fire_harmonized_event_counts.csv"))

SESU_v <- values(r_sesu)[, 1]
dist_m <- values(r_cov[["dist_parc_national_signed_m"]])[, 1]
valid_idx <- which(!is.na(SESU_v) & SESU_v %in% CH1_INCLUDED_SESUS & is.finite(dist_m))
pix_geom <- data.table(cell = valid_idx, SESU_ID = as.integer(SESU_v[valid_idx]), park_signed_distance_km = dist_m[valid_idx] / 1000)
pix_geom[, `:=`(side = fifelse(park_signed_distance_km < 0, "inside", "outside"), abs_boundary_distance_class = distance_class(park_signed_distance_km))]
design_cells <- function(design) {
  d <- copy(pix_geom)
  if (design == "buffer_10km") d <- d[abs(park_signed_distance_km) <= 10]
  d
}
canonical_fire_event <- function(year, cells) {
  vals <- extract_cells_vec(r_cov[[paste0("fireDOY_", year)]], cells)
  is.finite(vals) & vals >= FIRE_DOY_MIN & vals <= FIRE_DOY_MAX
}
previous_binary_event <- function(year, cells) {
  vals <- extract_cells_vec(rast(file.path(CH1_ROOT, "data", "fire_precomputed_500m", sprintf("fireBurned_AprOct_%d_500m_tau025.tif", year))), cells)
  is.finite(vals) & vals == 1
}
previous_doymax_event <- function(year, cells) {
  vals <- extract_cells_vec(rast(file.path(CH1_ROOT, "data", "fire_precomputed_500m", sprintf("fireDOY_max_AprOct_%d_500m_tau025.tif", year))), cells)
  is.finite(vals) & vals >= FIRE_DOY_MIN & vals <= FIRE_DOY_MAX
}
harmonized_event <- function(year, tag, cells) {
  vals <- extract_cells_vec(rast(file.path(FIRE_OUT_DIR, sprintf("fireBurned_AprOct_%d_500m_%s_harmonized.tif", year, tag))), cells)
  is.finite(vals) & vals == 1
}
compare_events <- function(year, label, comp_event, geom) {
  canon <- canonical_fire_event(year, geom$cell)
  comp <- comp_event
  data.table(
    year = year,
    comparison = label,
    compared_cells = length(canon),
    canonical_events = sum(canon),
    comparison_events = sum(comp),
    canonical_only_events = sum(canon & !comp),
    comparison_only_events = sum(!canon & comp),
    agreement_count = sum(canon == comp),
    disagreement_count = sum(canon != comp),
    disagreement_percentage = 100 * mean(canon != comp),
    cohen_kappa = kappa2(canon, comp)
  )
}
g_all <- design_cells("all_cells")
comparison_rows <- list()
disagree_sesu <- list()
disagree_dist <- list()
for (yr in YEARS_LOCAL) {
  comps <- list(
    previous_standalone_binary_tau025 = previous_binary_event(yr, g_all$cell),
    previous_doymax_derived_tau025 = previous_doymax_event(yr, g_all$cell),
    harmonized_binary_tau025 = harmonized_event(yr, "tau025", g_all$cell)
  )
  canon <- canonical_fire_event(yr, g_all$cell)
  for (nm in names(comps)) {
    comparison_rows[[paste(yr, nm)]] <- compare_events(yr, nm, comps[[nm]], g_all)
    dd <- copy(g_all)[, `:=`(canonical_event = canon, comparison_event = comps[[nm]], comparison = nm, year = yr)]
    disagree_sesu[[paste(yr, nm)]] <- dd[, .(
      cells = .N,
      canonical_events = sum(canonical_event),
      comparison_events = sum(comparison_event),
      disagreements = sum(canonical_event != comparison_event),
      canonical_only_events = sum(canonical_event & !comparison_event),
      comparison_only_events = sum(!canonical_event & comparison_event),
      disagreement_percentage = 100 * mean(canonical_event != comparison_event)
    ), by = .(year, comparison, SESU_ID, side)]
    disagree_dist[[paste(yr, nm)]] <- dd[, .(
      cells = .N,
      disagreements = sum(canonical_event != comparison_event),
      canonical_only_events = sum(canonical_event & !comparison_event),
      comparison_only_events = sum(!canonical_event & comparison_event),
      disagreement_percentage = 100 * mean(canonical_event != comparison_event)
    ), by = .(year, comparison, abs_boundary_distance_class)]
  }
}
fwrite(rbindlist(comparison_rows), file.path(TABLE_DIR, "fire_2021_2022_product_comparison.csv"))
fwrite(rbindlist(disagree_sesu), file.path(TABLE_DIR, "fire_2021_2022_disagreement_by_sesu_side.csv"))
fwrite(rbindlist(disagree_dist), file.path(TABLE_DIR, "fire_2021_2022_disagreement_by_distance.csv"))

fire_stack_path <- function(tag) threshold_manifest[outcome == "fire" & threshold_tag == tag & file_type == "fire_stack", abs_path][1]
fire_stack_event <- function(tag, year, cells) {
  rs <- rast(fire_stack_path(tag))
  band <- grep(paste0("^", year, "_fire_season_", year, "$"), names(rs), value = TRUE)
  if (length(band) != 1) stop("Missing 2001-2020 fire band: ", tag, " ", year, call. = FALSE)
  vals <- extract_cells_vec(rs[[band]], cells)
  is.finite(vals) & vals == 1
}
surface_fire <- function(version, design) {
  geom <- design_cells(design)
  out <- list()
  for (yr in CH1_STUDY_YEARS) {
    ev <- if (version == "canonical_embedded_tau025") {
      canonical_fire_event(yr, geom$cell)
    } else {
      tag <- sub("^harmonized_", "", version)
      if (yr <= 2020L) fire_stack_event(tag, yr, geom$cell) else harmonized_event(yr, tag, geom$cell)
    }
    dt <- copy(geom)[, `:=`(year = yr, disturbed = as.integer(ev))]
    out[[as.character(yr)]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side)]
  }
  rbindlist(out)[, `:=`(outcome = "fire", measurement_version = version, spatial_design = design)][]
}
load_governance_timeline <- function() {
  gov_wide <- fread(CH1_GOVERNANCE_PROFILE_PATH)
  gov_long <- melt(gov_wide, id.vars = "year", measure.vars = paste0("SESU", CH1_INCLUDED_SESUS, "_regime"), variable.name = "SESU_col", value.name = "original_profile_code")
  gov_long[, `:=`(year = as.integer(year), SESU_ID = as.integer(gsub("^SESU([0-9]+)_regime$", "\\1", SESU_col)), governance_profile = unname(CH1_PROFILE_CODE_MAP[original_profile_code]))]
  gov_long[, .(SESU_ID, year, original_profile_code, governance_profile)]
}
timeline <- load_governance_timeline()
add_profile <- function(surface) {
  d <- merge(surface, timeline, by = c("SESU_ID", "year"), all.x = TRUE)
  d[, `:=`(governance_profile = factor(governance_profile, levels = profile_levels), side = factor(side, levels = c("outside", "inside")))]
  d[]
}
versions <- c("canonical_embedded_tau025", paste0("harmonized_", names(THRESHOLDS)))
surfaces <- rbindlist(lapply(versions, function(v) rbindlist(lapply(c("all_cells", "buffer_10km"), function(d) add_profile(surface_fire(v, d))))), fill = TRUE)
surfaces[, threshold_tag := fifelse(measurement_version == "canonical_embedded_tau025", "tau025", sub("^harmonized_", "", measurement_version))]
surfaces[, threshold := THRESHOLDS[threshold_tag]]
fwrite(surfaces, file.path(TABLE_DIR, "fire_harmonized_surface_summary.csv"))

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
fit_diag <- function(fw, d, version, design) {
  X <- tryCatch(model.matrix(primary_formula, d), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  if (inherits(fw$fit, "fit_error")) return(data.table(measurement_version = version, spatial_design = design, convergence_code = NA_integer_, optimizer_message = fw$fit$error, pdHess = NA, maximum_absolute_gradient = NA_real_, model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = FALSE, warnings = paste(fw$warnings, collapse = " | ")))
  m <- fw$fit
  se <- tryCatch(summary(m)$coefficients$cond[, "Std. Error"], error = function(e) NA_real_)
  pd <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  grad <- max_abs_gradient(m)
  strict <- identical(m$fit$convergence, 0L) && pd && identical(rank_x, cols_x) && is.finite(grad) && grad < CH1_MAX_ABS_GRADIENT_TOL && !any(abs(se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE)
  data.table(measurement_version = version, spatial_design = design, convergence_code = m$fit$convergence, optimizer_message = as.character(m$fit$message), pdHess = pd, maximum_absolute_gradient = grad, dispersion_estimate = tryCatch(sigma(m), error = function(e) NA_real_), model_matrix_rank = rank_x, model_matrix_columns = cols_x, model_matrix_full_rank = identical(rank_x, cols_x), strict_valid = strict, warnings = paste(fw$warnings, collapse = " | "), coefficient_estimates = paste(paste0(names(fixef(m)$cond), "=", signif(fixef(m)$cond, 8)), collapse = "; "))
}
profile_contrasts <- function(m, version, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(profile_levels, function(pr) cbind(data.table(measurement_version = version, spatial_design = design, governance_profile = pr), contrast_stats(beta, V, make_profile_L(names(beta), pr), intervals = strict_valid))), fill = TRUE)
}
pairwise_contrasts <- function(m, version, design, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- make_profile_L(names(beta), parts[1]) - make_profile_L(names(beta), parts[2])
    cbind(data.table(measurement_version = version, spatial_design = design, profile_comparison = cmp), contrast_stats(beta, V, L, intervals = strict_valid))
  }), fill = TRUE)
}

diag_rows <- list(); profile_rows <- list(); pair_rows <- list()
for (v in versions) for (dsgn in c("all_cells", "buffer_10km")) {
  d <- add_model_terms(surfaces[measurement_version == v & spatial_design == dsgn])
  fw <- fit_model(d)
  dg <- fit_diag(fw, d, v, dsgn)
  diag_rows[[paste(v, dsgn)]] <- dg
  if (!inherits(fw$fit, "fit_error")) {
    profile_rows[[paste(v, dsgn)]] <- profile_contrasts(fw$fit, v, dsgn, dg$strict_valid)
    pair_rows[[paste(v, dsgn)]] <- pairwise_contrasts(fw$fit, v, dsgn, dg$strict_valid)
  }
}
diag_dt <- rbindlist(diag_rows, fill = TRUE)
profile_dt <- rbindlist(profile_rows, fill = TRUE)
pair_dt <- rbindlist(pair_rows, fill = TRUE)
fwrite(diag_dt, file.path(TABLE_DIR, "fire_harmonized_fit_diagnostics.csv"))
fwrite(profile_dt, file.path(TABLE_DIR, "fire_harmonized_profile_contrasts.csv"))
fwrite(pair_dt, file.path(TABLE_DIR, "fire_harmonized_pairwise_differences.csv"))

canon_vs <- merge(
  profile_dt[measurement_version == "canonical_embedded_tau025", .(spatial_design, governance_profile, canonical_estimate = estimate, canonical_se = standard_error)],
  profile_dt[measurement_version == "harmonized_tau025", .(spatial_design, governance_profile, harmonized_estimate = estimate, harmonized_se = standard_error)],
  by = c("spatial_design", "governance_profile"),
  all = TRUE
)
canon_vs[, `:=`(
  estimate_difference = harmonized_estimate - canonical_estimate,
  difference_relative_to_canonical_se = (harmonized_estimate - canonical_estimate) / canonical_se,
  sign_changes = sign(harmonized_estimate) != sign(canonical_estimate)
)]
fwrite(canon_vs, file.path(TABLE_DIR, "fire_canonical_vs_harmonized_tau025.csv"))

manifest_rows <- list()
for (tag in names(THRESHOLDS)) {
  rs <- rast(fire_stack_path(tag))
  for (yr in 2001:2020) {
    b <- grep(paste0("^", yr, "_fire_season_", yr, "$"), names(rs), value = TRUE)
    d <- grep(paste0("^", yr, "_fireDOY_season_", yr, "$"), names(rs), value = TRUE)
    manifest_rows[[paste(tag, yr, "binary")]] <- data.table(year = yr, threshold = THRESHOLDS[[tag]], threshold_tag = tag, source_file = rel_path(fire_stack_path(tag)), source_band = b, source_dataset = "ESA/CCI/FireCCI/5_1", processing_script = "scripts/Script 0_data acquisition.txt", binary_or_doy = "binary", crs = crs(rs, describe = TRUE)$code, resolution = paste(res(rs), collapse = "x"), file_hash = as.character(tools::md5sum(fire_stack_path(tag))), validation_status = "existing_2001_2020_product")
    manifest_rows[[paste(tag, yr, "doy")]] <- data.table(year = yr, threshold = THRESHOLDS[[tag]], threshold_tag = tag, source_file = rel_path(fire_stack_path(tag)), source_band = d, source_dataset = "ESA/CCI/FireCCI/5_1", processing_script = "scripts/Script 0_data acquisition.txt", binary_or_doy = "doy", crs = crs(rs, describe = TRUE)$code, resolution = paste(res(rs), collapse = "x"), file_hash = as.character(tools::md5sum(fire_stack_path(tag))), validation_status = "existing_2001_2020_product")
  }
  for (yr in YEARS_LOCAL) {
    bp <- file.path(FIRE_OUT_DIR, sprintf("fireBurned_AprOct_%d_500m_%s_harmonized.tif", yr, tag))
    dp <- file.path(FIRE_OUT_DIR, sprintf("fireDOY_min_AprOct_%d_500m_%s_harmonized.tif", yr, tag))
    rb <- rast(bp); rd <- rast(dp)
    manifest_rows[[paste(tag, yr, "binary")]] <- data.table(year = yr, threshold = THRESHOLDS[[tag]], threshold_tag = tag, source_file = rel_path(bp), source_band = names(rb)[1], source_dataset = "local FireCCI monthly JD rasters", processing_script = "scripts/09_fire_2021_2022_harmonization.R", binary_or_doy = "binary", crs = crs(rb, describe = TRUE)$code, resolution = paste(res(rb), collapse = "x"), file_hash = as.character(tools::md5sum(bp)), validation_status = "pass")
    manifest_rows[[paste(tag, yr, "doy")]] <- data.table(year = yr, threshold = THRESHOLDS[[tag]], threshold_tag = tag, source_file = rel_path(dp), source_band = names(rd)[1], source_dataset = "local FireCCI monthly JD rasters", processing_script = "scripts/09_fire_2021_2022_harmonization.R", binary_or_doy = "doy", crs = crs(rd, describe = TRUE)$code, resolution = paste(res(rd), collapse = "x"), file_hash = as.character(tools::md5sum(dp)), validation_status = "pass")
  }
}
fwrite(rbindlist(manifest_rows, fill = TRUE), file.path(PROV_DIR, "fire_harmonized_2001_2022_manifest.csv"))

writeLines(capture.output(sessionInfo()), file.path(PROV_DIR, "sessionInfo.txt"))
message("Fire 2021-2022 harmonization complete. Outputs: ", OUT_DIR)
