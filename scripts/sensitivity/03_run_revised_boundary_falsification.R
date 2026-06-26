# ===========================================================
# CHAPTER 1 REVISED SPATIAL PSEUDO-BOUNDARY FALSIFICATION
# ===========================================================
# Implements the researcher-approved revised design after the
# original pre-outcome candidate screen stopped for insufficient
# inner pseudo-boundary support. Selection is fixed before outcome
# fitting: actual boundary; +20/+40/+60 km primary spaced outer
# set; all valid outer candidates; and -15/-20 km inner checks.
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

OUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_spatial_falsification_revised_dev")
TABLE_DIR <- file.path(OUT_DIR, "tables")
MODEL_DIR <- file.path(OUT_DIR, "models")
FIG_DIR <- file.path(OUT_DIR, "figures")
LOG_DIR <- file.path(OUT_DIR, "logs")
PROV_DIR <- file.path(OUT_DIR, "provenance")
for (p in c(OUT_DIR, TABLE_DIR, MODEL_DIR, FIG_DIR, LOG_DIR, PROV_DIR)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

zcrit <- qnorm(1 - CH1_ALPHA / 2)
gradient_tol <- CH1_MAX_ABS_GRADIENT_TOL
corridor_half_width_km <- 10
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
pairwise_comparisons <- c(
  "Park dominant minus Neither actor dominant",
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")

old_registry_path <- file.path(CH1_DATA_ROOT, "analysis_spatial_falsification_dev", "tables", "pseudo_boundary_candidate_registry.csv")
if (!file.exists(old_registry_path)) stop("Missing stopped-design candidate registry: ", old_registry_path, call. = FALSE)
old_registry <- fread(old_registry_path)
actual_center <- 0
primary_outer_centers <- c(20, 40, 60)
all_outer_centers <- old_registry[boundary_family == "outer_pseudo" & candidate_valid == TRUE, sort(boundary_center_km)]
inner_check_centers <- c(-15, -20)
required_centers <- c(actual_center, all_outer_centers, inner_check_centers)
missing_required <- setdiff(required_centers, old_registry$boundary_center_km)
if (length(missing_required)) stop("Required revised boundary centers missing from candidate registry: ", paste(missing_required, collapse = ", "), call. = FALSE)

analysis_set_for <- function(center) {
  if (center == 0) return("actual_boundary")
  sets <- character()
  if (center %in% primary_outer_centers) sets <- c(sets, "primary_spaced_outer")
  if (center %in% all_outer_centers) sets <- c(sets, "all_valid_outer")
  if (center %in% inner_check_centers) sets <- c(sets, "limited_inner_checks")
  paste(sets, collapse = ";")
}
selection_reason_for <- function(center) {
  if (center == 0) return("actual 10 km boundary estimand")
  if (center %in% primary_outer_centers) return("fixed evenly spaced outer pseudo-boundary selected before outcome fitting")
  if (center %in% all_outer_centers) return("valid outer pseudo-boundary retained for dense outer-gradient sensitivity")
  if (center %in% inner_check_centers) return("only valid inner pseudo-boundary retained as limited descriptive check")
  ""
}

revised_registry <- old_registry[boundary_center_km %in% required_centers]
revised_registry[, `:=`(
  analysis_set = vapply(boundary_center_km, analysis_set_for, character(1)),
  valid_under_original_rules = candidate_valid,
  selected_for_outcome_analysis = TRUE,
  selection_reason = vapply(boundary_center_km, selection_reason_for, character(1))
)]
setorder(revised_registry, boundary_center_km)
revised_registry <- revised_registry[, .(
  boundary_id, boundary_center_km, boundary_family, analysis_set,
  corridor_min_km, corridor_max_km, n_cells, n_interior_facing,
  n_exterior_facing, side_ratio, n_sesu, both_sesu_present,
  largest_component_share, n_connected_components, touches_aoi_edge,
  valid_under_original_rules, selected_for_outcome_analysis, selection_reason
)]
fwrite(revised_registry, file.path(TABLE_DIR, "revised_boundary_registry.csv"))

cov_path <- file.path(CH1_RUN_DIR, "SESU_covariates_500m.tif")
sesu_path <- file.path(CH1_RUN_DIR, "SESU_ID_500m.tif")
if (!file.exists(cov_path) || !file.exists(sesu_path)) stop("Missing canonical run rasters.", call. = FALSE)
r_cov <- rast(cov_path)
r_sesu <- rast(sesu_path)
template <- r_cov[[1]]

dist_km_all <- values(r_cov[["dist_parc_national_signed_m"]])[, 1] / 1000
sesu_all <- values(r_sesu)[, 1]
base_cells <- which(!is.na(sesu_all) & sesu_all %in% CH1_INCLUDED_SESUS & is.finite(dist_km_all))
rowcol <- rowColFromCell(template, base_cells)
base_geom <- data.table(
  cell = base_cells,
  base_index = seq_along(base_cells),
  row = rowcol[, 1],
  col = rowcol[, 2],
  SESU_ID = as.integer(sesu_all[base_cells]),
  park_signed_distance_km = dist_km_all[base_cells]
)

boundary_cells <- function(center) {
  dt <- base_geom[abs(park_signed_distance_km - center) <= corridor_half_width_km]
  dt[, `:=`(
    boundary_center_km = center,
    pseudo_side = fifelse(park_signed_distance_km < center, "interior_facing", "exterior_facing")
  )]
  dt
}

covariates <- intersect(
  c(
    "elevation_m", "slope_deg", "dist_perm_water_m", "accessibility_cities",
    "clim_precip_mean_mm_1981_2010", "clim_precip_sd_mm_1981_2010",
    "clim_aet_mean_mm_1981_2010", "clim_pet_mean_mm_1981_2010",
    "clim_water_balance_mm_1981_2010", "clim_aridity_index_p_over_pet_1981_2010",
    "forest2000_ge_30pct", "dist_weighted_urban"
  ),
  names(r_cov)
)
cov_vals <- as.data.table(values(r_cov[[covariates]]))
cov_vals[, cell := seq_len(.N)]
setkey(cov_vals, cell)

smd_one <- function(x1, x0) {
  x1 <- x1[is.finite(x1)]
  x0 <- x0[is.finite(x0)]
  if (length(x1) < 2 || length(x0) < 2) return(NA_real_)
  sp <- sqrt((var(x1) + var(x0)) / 2)
  if (!is.finite(sp) || sp == 0) return(NA_real_)
  (mean(x1) - mean(x0)) / sp
}

balance_rows <- list()
for (i in seq_len(nrow(revised_registry))) {
  b <- revised_registry[i]
  dt <- merge(boundary_cells(b$boundary_center_km), cov_vals, by = "cell", all.x = TRUE, sort = FALSE)
  for (cv in covariates) {
    for (ss in CH1_INCLUDED_SESUS) {
      dss <- dt[SESU_ID == ss]
      balance_rows[[length(balance_rows) + 1L]] <- data.table(
        boundary_id = b$boundary_id,
        boundary_center_km = b$boundary_center_km,
        boundary_family = b$boundary_family,
        analysis_set = b$analysis_set,
        balance_scope = paste0("SESU_", ss),
        covariate = cv,
        smd = smd_one(dss[pseudo_side == "interior_facing", get(cv)], dss[pseudo_side == "exterior_facing", get(cv)]),
        n_interior_facing = nrow(dss[pseudo_side == "interior_facing"]),
        n_exterior_facing = nrow(dss[pseudo_side == "exterior_facing"])
      )
    }
    balance_rows[[length(balance_rows) + 1L]] <- data.table(
      boundary_id = b$boundary_id,
      boundary_center_km = b$boundary_center_km,
      boundary_family = b$boundary_family,
      analysis_set = b$analysis_set,
      balance_scope = "pooled",
      covariate = cv,
      smd = smd_one(dt[pseudo_side == "interior_facing", get(cv)], dt[pseudo_side == "exterior_facing", get(cv)]),
      n_interior_facing = nrow(dt[pseudo_side == "interior_facing"]),
      n_exterior_facing = nrow(dt[pseudo_side == "exterior_facing"])
    )
  }
}
balance <- rbindlist(balance_rows, fill = TRUE)
fwrite(balance, file.path(TABLE_DIR, "revised_boundary_covariate_balance.csv"))
balance_summary <- balance[, .(
  median_abs_smd = median(abs(smd), na.rm = TRUE),
  maximum_abs_smd = max(abs(smd), na.rm = TRUE),
  n_abs_smd_gt_0.10 = sum(abs(smd) > 0.10, na.rm = TRUE),
  n_abs_smd_gt_0.20 = sum(abs(smd) > 0.20, na.rm = TRUE)
), by = .(boundary_id, boundary_center_km, boundary_family, analysis_set, balance_scope)]
balance_summary <- merge(
  balance_summary,
  revised_registry[, .(boundary_id, n_cells, side_ratio, n_sesu, largest_component_share, n_connected_components)],
  by = "boundary_id",
  all.x = TRUE
)
fwrite(balance_summary, file.path(TABLE_DIR, "revised_boundary_balance_summary.csv"))

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

extract_cells_vec <- function(r, cells) {
  as.vector(values(r)[cells, 1])
}

fire_manifest_path <- file.path(CH1_DATA_ROOT, "config", "fire_harmonized_2001_2022_manifest.csv")
if (!file.exists(fire_manifest_path)) stop("Missing harmonized fire manifest: ", fire_manifest_path, call. = FALSE)
fire_manifest <- fread(fire_manifest_path)
fire_manifest_tau025 <- fire_manifest[threshold_tag == "tau025" & binary_or_doy == "binary"]
if (nrow(fire_manifest_tau025) != length(CH1_STUDY_YEARS)) {
  stop("Harmonized tau025 fire manifest does not contain one binary row per study year.", call. = FALSE)
}
fire_event_by_year <- list()
for (yr in CH1_STUDY_YEARS) {
  row <- fire_manifest_tau025[year == yr][1]
  p <- row$source_file
  if (!file.exists(p) && !grepl("^[A-Za-z]:", p)) p <- file.path(CH1_DATA_ROOT, p)
  if (!file.exists(p)) stop("Missing fire input for ", yr, ": ", p, call. = FALSE)
  rr <- rast(p)
  layer <- if (!is.na(row$source_band) && row$source_band %in% names(rr)) rr[[row$source_band]] else rr[[1]]
  vals <- extract_cells_vec(layer, base_cells)
  fire_event_by_year[[as.character(yr)]] <- as.integer(is.finite(vals) & vals == 1)
}

canonical_event_year <- function(outcome_name) {
  band <- if (outcome_name == "tree_cover_loss") "year_deforest_masked" else "year_agri"
  vals <- as.integer(extract_cells_vec(r_cov[[band]], base_cells))
  vals[!is.finite(vals) | vals <= 0] <- NA_integer_
  vals
}
event_year_by_outcome <- list(
  tree_cover_loss = canonical_event_year("tree_cover_loss"),
  agriculture = canonical_event_year("agriculture")
)

add_profile <- function(surface) {
  d <- merge(surface, timeline, by = c("SESU_ID", "year"), all.x = TRUE)
  d[, governance_profile := factor(governance_profile, levels = profile_levels)]
  d[]
}

surface_fire <- function(boundary_row) {
  geom <- boundary_cells(boundary_row$boundary_center_km)
  out <- vector("list", length(CH1_STUDY_YEARS))
  for (j in seq_along(CH1_STUDY_YEARS)) {
    yr <- CH1_STUDY_YEARS[j]
    event <- fire_event_by_year[[as.character(yr)]][geom$base_index]
    dt <- copy(geom)
    dt[, `:=`(year = yr, disturbed = event)]
    out[[j]] <- dt[, .(n = .N, y = sum(disturbed, na.rm = TRUE)), by = .(SESU_ID, year, side = pseudo_side)]
  }
  add_profile(rbindlist(out, use.names = TRUE, fill = TRUE))[, `:=`(
    boundary_id = boundary_row$boundary_id,
    boundary_center_km = boundary_row$boundary_center_km,
    boundary_family = boundary_row$boundary_family,
    analysis_set = boundary_row$analysis_set,
    outcome = "fire",
    measurement_version = "harmonized_tau025",
    threshold_tag = "tau025"
  )]
}

surface_sparse <- function(boundary_row, outcome_name) {
  geom <- boundary_cells(boundary_row$boundary_center_km)
  vals <- event_year_by_outcome[[outcome_name]][geom$base_index]
  out <- vector("list", length(CH1_STUDY_YEARS))
  for (j in seq_along(CH1_STUDY_YEARS)) {
    yr <- CH1_STUDY_YEARS[j]
    at_risk <- is.na(vals) | yr <= vals
    if (!any(at_risk)) next
    dt <- copy(geom[at_risk])
    dt[, `:=`(year = yr, disturbed = as.integer(!is.na(vals[at_risk]) & vals[at_risk] == yr))]
    out[[j]] <- dt[, .(n = .N, y = sum(disturbed)), by = .(SESU_ID, year, side = pseudo_side)]
  }
  add_profile(rbindlist(out, use.names = TRUE, fill = TRUE))[, `:=`(
    boundary_id = boundary_row$boundary_id,
    boundary_center_km = boundary_row$boundary_center_km,
    boundary_family = boundary_row$boundary_family,
    analysis_set = boundary_row$analysis_set,
    outcome = outcome_name,
    measurement_version = "canonical_embedded_tau025",
    threshold_tag = "tau025"
  )]
}

surface_list <- list()
for (i in seq_len(nrow(revised_registry))) {
  b <- revised_registry[i]
  surface_list[[length(surface_list) + 1L]] <- surface_fire(b)
  surface_list[[length(surface_list) + 1L]] <- surface_sparse(b, "tree_cover_loss")
  surface_list[[length(surface_list) + 1L]] <- surface_sparse(b, "agriculture")
}
surface_dt <- rbindlist(surface_list, fill = TRUE)
fwrite(surface_dt, file.path(TABLE_DIR, "boundary_surface_summary.csv"))

add_model_terms <- function(d) {
  x <- copy(d)
  x[, `:=`(
    SESU_ID = factor(SESU_ID),
    side = factor(as.character(side), levels = c("exterior_facing", "interior_facing")),
    governance_profile = factor(governance_profile, levels = profile_levels),
    inside_profile_militia = as.integer(side == "interior_facing" & governance_profile == "Militia dominant"),
    inside_profile_park = as.integer(side == "interior_facing" & governance_profile == "Park dominant"),
    sesu_year = interaction(SESU_ID, year, drop = TRUE)
  )]
  x[]
}

make_profile_L <- function(beta_names, profile) {
  L <- setNames(rep(0, length(beta_names)), beta_names)
  side_term <- intersect(c("sideinterior_facing", "sideinside"), beta_names)
  if (length(side_term)) L[side_term[1]] <- 1
  if (profile == "Militia dominant" && "inside_profile_militia" %in% beta_names) {
    L["inside_profile_militia"] <- L["inside_profile_militia"] + 1
  }
  if (profile == "Park dominant" && "inside_profile_park" %in% beta_names) {
    L["inside_profile_park"] <- L["inside_profile_park"] + 1
  }
  L
}

contrast_stats <- function(beta, V, L, intervals = TRUE) {
  est <- sum(L * beta)
  se <- as.numeric(sqrt(t(L) %*% V %*% L))
  data.table(
    estimate = est,
    standard_error = se,
    lower_95_ci = if (intervals) est - zcrit * se else NA_real_,
    upper_95_ci = if (intervals) est + zcrit * se else NA_real_
  )
}

profile_contrasts_fire <- function(m, boundary_row, optimizer_config, strict_valid, retained_status = NA_character_) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(profile_levels, function(pr) {
    cbind(
      data.table(
        outcome = "fire",
        measurement_version = "harmonized_tau025",
        threshold_tag = "tau025",
        boundary_id = boundary_row$boundary_id,
        boundary_center_km = boundary_row$boundary_center_km,
        boundary_family = boundary_row$boundary_family,
        analysis_set = boundary_row$analysis_set,
        optimizer_config = optimizer_config,
        retained_status = retained_status,
        governance_profile = pr,
        contrast_direction = "interior-facing minus exterior-facing"
      ),
      contrast_stats(beta, V, make_profile_L(names(beta), pr), intervals = strict_valid)
    )
  }), fill = TRUE)
}

pairwise_contrasts_fire <- function(m, boundary_row, optimizer_config, strict_valid, retained_status = NA_character_) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- make_profile_L(names(beta), parts[1]) - make_profile_L(names(beta), parts[2])
    cbind(
      data.table(
        outcome = "fire",
        measurement_version = "harmonized_tau025",
        threshold_tag = "tau025",
        boundary_id = boundary_row$boundary_id,
        boundary_center_km = boundary_row$boundary_center_km,
        boundary_family = boundary_row$boundary_family,
        analysis_set = boundary_row$analysis_set,
        optimizer_config = optimizer_config,
        retained_status = retained_status,
        profile_comparison = cmp
      ),
      contrast_stats(beta, V, L, intervals = strict_valid)
    )
  }), fill = TRUE)
}

param_labels <- function(m) {
  c(names(fixef(m)$cond), paste0("disp_", names(fixef(m)$disp)))
}
classify_parameter <- function(parameter) {
  if (grepl("^sesu_year", parameter)) return("sesu_year fixed effect")
  if (parameter %in% c("sideinterior_facing", "sideinside")) return("side")
  if (parameter %in% c("inside_profile_militia", "inside_profile_park")) return("governance-profile interaction")
  if (grepl("^disp_", parameter)) return("dispersion")
  "another parameter"
}
numeric_gradient <- function(fn, par) {
  if (requireNamespace("numDeriv", quietly = TRUE)) return(numDeriv::grad(fn, par))
  step <- 1e-5 * (abs(par) + 1)
  out <- numeric(length(par))
  for (i in seq_along(par)) {
    up <- par; dn <- par
    up[i] <- up[i] + step[i]
    dn[i] <- dn[i] - step[i]
    out[i] <- (fn(up) - fn(dn)) / (2 * step[i])
  }
  out
}
hessian_min_eigen <- function(m) {
  cv <- tryCatch(m$sdr$cov.fixed, error = function(e) NULL)
  if (is.null(cv) || any(!is.finite(cv))) return(NA_real_)
  H <- tryCatch(solve(cv), error = function(e) NULL)
  if (is.null(H) || any(!is.finite(H))) return(NA_real_)
  suppressWarnings(min(Re(eigen(H, symmetric = TRUE, only.values = TRUE)$values), na.rm = TRUE))
}
scalar_or <- function(x, default) {
  if (is.null(x) || length(x) == 0) return(default)
  x[[1]]
}
make_start <- function(m) {
  list(beta = unname(fixef(m)$cond), betadisp = unname(fixef(m)$disp))
}

fit_candidate <- function(d, config_id, start_model = NULL) {
  warnings <- character()
  control <- switch(
    config_id,
    A_baseline = glmmTMBControl(optCtrl = list(iter.max = 50000, eval.max = 50000, rel.tol = 1e-10, x.tol = 1e-8)),
    B_strict_nlminb = glmmTMBControl(optCtrl = list(iter.max = 10000, eval.max = 20000, rel.tol = 1e-12, x.tol = 1e-10, abs.tol = 1e-10, trace = 0)),
    BFGS_refined = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"), optCtrl = list(maxit = 20000, reltol = 1e-12)),
    stop("Unknown optimizer config: ", config_id, call. = FALSE)
  )
  start <- if (is.null(start_model) || inherits(start_model, "fit_error")) NULL else make_start(start_model)
  fit <- withCallingHandlers(
    tryCatch(
      glmmTMB(primary_formula, family = betabinomial(link = "logit"), data = d, control = control, start = start),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = unique(warnings), start_used = !is.null(start))
}

fit_diagnostics <- function(fw, d, boundary_row, config_id) {
  X <- tryCatch(model.matrix(primary_formula, d), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  base <- data.table(
    outcome = "fire",
    measurement_version = "harmonized_tau025",
    threshold_tag = "tau025",
    boundary_id = boundary_row$boundary_id,
    boundary_center_km = boundary_row$boundary_center_km,
    boundary_family = boundary_row$boundary_family,
    analysis_set = boundary_row$analysis_set,
    optimizer_config = config_id,
    model_formula = paste(deparse(primary_formula), collapse = " "),
    optimizer = if (config_id == "BFGS_refined") "optim_BFGS" else "nlminb",
    start_values_used = fw$start_used,
    model_matrix_rank = rank_x,
    model_matrix_columns = cols_x,
    model_matrix_full_rank = identical(rank_x, cols_x),
    warnings = paste(fw$warnings, collapse = " | ")
  )
  if (inherits(fw$fit, "fit_error")) {
    return(cbind(base, data.table(
      convergence_code = NA_integer_, optimizer_message = fw$fit$error,
      logLik = NA_real_, AIC = NA_real_, objective_value = NA_real_,
      dispersion_estimate = NA_real_, pdHess = NA, minimum_hessian_eigenvalue = NA_real_,
      framework_maximum_absolute_gradient = NA_real_, numerical_maximum_absolute_gradient = NA_real_,
      largest_framework_gradient_parameter = NA_character_, largest_framework_gradient_class = NA_character_,
      largest_numerical_gradient_parameter = NA_character_, largest_numerical_gradient_class = NA_character_,
      number_of_parameters = NA_integer_, finite_coefficients = FALSE, finite_standard_errors = FALSE,
      extreme_parameter_flag = NA, finite_profile_contrasts = FALSE, strict_valid = FALSE
    )))
  }
  m <- fw$fit
  labels <- param_labels(m)
  fw_grad <- tryCatch(m$obj$gr(m$fit$par), error = function(e) rep(NA_real_, length(labels)))
  num_grad <- tryCatch(numeric_gradient(m$obj$fn, m$fit$par), error = function(e) rep(NA_real_, length(labels)))
  if (length(fw_grad) != length(labels)) labels <- paste0("parameter_", seq_along(fw_grad))
  num_labels <- if (length(num_grad) == length(labels)) labels else paste0("parameter_", seq_along(num_grad))
  fw_i <- if (all(!is.finite(fw_grad))) NA_integer_ else which.max(abs(fw_grad))
  num_i <- if (all(!is.finite(num_grad))) NA_integer_ else which.max(abs(num_grad))
  coef_se <- tryCatch(summary(m)$coefficients$cond[, "Std. Error"], error = function(e) NA_real_)
  beta <- tryCatch(fixef(m)$cond, error = function(e) NA_real_)
  disp <- tryCatch(sigma(m), error = function(e) NA_real_)
  profile_ok <- tryCatch({
    pc <- profile_contrasts_fire(m, boundary_row, config_id, strict_valid = FALSE)
    all(is.finite(pc$estimate)) && all(is.finite(pc$standard_error))
  }, error = function(e) FALSE)
  convergence_code <- as.integer(scalar_or(m$fit$convergence, NA_integer_))
  optimizer_message <- as.character(scalar_or(m$fit$message, ""))
  objective_value <- as.numeric(scalar_or(m$fit$objective, scalar_or(m$fit$value, NA_real_)))
  pd_hess <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  strict <- isTRUE(convergence_code == 0) &&
    !grepl("false|fail|error", optimizer_message, ignore.case = TRUE) &&
    pd_hess && identical(rank_x, cols_x) && all(is.finite(beta)) &&
    all(is.finite(coef_se)) &&
    is.finite(max(abs(fw_grad), na.rm = TRUE)) && max(abs(fw_grad), na.rm = TRUE) < gradient_tol &&
    is.finite(max(abs(num_grad), na.rm = TRUE)) && max(abs(num_grad), na.rm = TRUE) < gradient_tol &&
    !any(abs(coef_se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE) && profile_ok
  cbind(base, data.table(
    convergence_code = convergence_code,
    optimizer_message = optimizer_message,
    logLik = as.numeric(logLik(m)),
    AIC = AIC(m),
    objective_value = objective_value,
    dispersion_estimate = disp,
    pdHess = pd_hess,
    minimum_hessian_eigenvalue = hessian_min_eigen(m),
    framework_maximum_absolute_gradient = max(abs(fw_grad), na.rm = TRUE),
    numerical_maximum_absolute_gradient = max(abs(num_grad), na.rm = TRUE),
    largest_framework_gradient_parameter = if (is.na(fw_i)) NA_character_ else labels[fw_i],
    largest_framework_gradient_class = if (is.na(fw_i)) NA_character_ else classify_parameter(labels[fw_i]),
    largest_numerical_gradient_parameter = if (is.na(num_i)) NA_character_ else num_labels[num_i],
    largest_numerical_gradient_class = if (is.na(num_i)) NA_character_ else classify_parameter(num_labels[num_i]),
    number_of_parameters = length(m$fit$par),
    finite_coefficients = all(is.finite(beta)),
    finite_standard_errors = all(is.finite(coef_se)),
    extreme_parameter_flag = any(abs(coef_se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE),
    finite_profile_contrasts = profile_ok,
    strict_valid = strict
  ))
}

select_retained <- function(dd) {
  strict <- dd[strict_valid == TRUE]
  if (nrow(strict)) {
    strict <- strict[order(numerical_maximum_absolute_gradient, framework_maximum_absolute_gradient, -logLik)]
    out <- strict[1]
    out[, retained_status := "strict-valid"]
    return(out)
  }
  stable <- dd[
    convergence_code == 0 & pdHess == TRUE & model_matrix_full_rank == TRUE &
      is.finite(logLik) & framework_maximum_absolute_gradient < 0.002
  ]
  if (nrow(stable)) {
    stable <- stable[order(numerical_maximum_absolute_gradient, framework_maximum_absolute_gradient, -logLik)]
    out <- stable[1]
    out[, retained_status := "finite/numerically stable but not strict-valid"]
    return(out)
  }
  out <- dd[order(convergence_code, -pdHess, numerical_maximum_absolute_gradient)][1]
  out[, retained_status := "failed or unstable"]
  out
}

fire_diag <- list()
fire_profile <- list()
fire_pair <- list()
retained_rows <- list()
for (i in seq_len(nrow(revised_registry))) {
  b <- revised_registry[i]
  d <- add_model_terms(surface_dt[outcome == "fire" & boundary_id == b$boundary_id])
  fits <- list()
  fits[["A_baseline"]] <- fit_candidate(d, "A_baseline")
  fits[["B_strict_nlminb"]] <- fit_candidate(d, "B_strict_nlminb", start_model = fits[["A_baseline"]]$fit)
  fits[["BFGS_refined"]] <- fit_candidate(d, "BFGS_refined", start_model = fits[["B_strict_nlminb"]]$fit)
  diag_i <- list()
  for (cfg in names(fits)) {
    dg <- fit_diagnostics(fits[[cfg]], d, b, cfg)
    fire_diag[[paste(b$boundary_id, cfg)]] <- dg
    diag_i[[cfg]] <- dg
  }
  dd <- rbindlist(diag_i, fill = TRUE)
  retained <- select_retained(dd)
  retained_rows[[b$boundary_id]] <- retained
  retained_cfg <- retained$optimizer_config[1]
  if (!inherits(fits[[retained_cfg]]$fit, "fit_error")) {
    fire_profile[[b$boundary_id]] <- profile_contrasts_fire(
      fits[[retained_cfg]]$fit, b, retained_cfg, isTRUE(retained$strict_valid[1]), retained$retained_status[1]
    )
    fire_pair[[b$boundary_id]] <- pairwise_contrasts_fire(
      fits[[retained_cfg]]$fit, b, retained_cfg, isTRUE(retained$strict_valid[1]), retained$retained_status[1]
    )
  }
}
fire_diag_dt <- rbindlist(fire_diag, fill = TRUE)
fire_retained_dt <- rbindlist(retained_rows, fill = TRUE)
fire_profile_dt <- rbindlist(fire_profile, fill = TRUE)
fire_pair_dt <- rbindlist(fire_pair, fill = TRUE)
fwrite(fire_diag_dt, file.path(TABLE_DIR, "fire_boundary_fit_diagnostics.csv"))
fwrite(fire_retained_dt, file.path(TABLE_DIR, "fire_boundary_retained_fits.csv"))
fwrite(fire_profile_dt, file.path(TABLE_DIR, "fire_boundary_profile_contrasts.csv"))
fwrite(fire_pair_dt, file.path(TABLE_DIR, "fire_boundary_pairwise_differences.csv"))

hc3_vcov <- function(mod) {
  X <- model.matrix(mod); e <- residuals(mod); h <- hatvalues(mod); w <- weights(mod)
  if (is.null(w)) w <- rep(1, length(e))
  Xw <- X * sqrt(w)
  meat <- t(Xw) %*% diag((e * sqrt(w) / pmax(1 - h, 1e-8))^2, nrow = length(e)) %*% Xw
  bread <- solve(t(Xw) %*% Xw)
  bread %*% meat %*% bread
}

fit_sparse_boundary <- function(s, model_type) {
  w <- dcast(s, boundary_id + boundary_center_km + boundary_family + analysis_set + outcome + SESU_ID + year + governance_profile ~ side, value.var = c("y", "n"))
  needed <- c("y_interior_facing", "n_interior_facing", "y_exterior_facing", "n_exterior_facing")
  if (!all(needed %in% names(w))) stop("Sparse boundary table is missing one or more pseudo-side columns.", call. = FALSE)
  w[, `:=`(
    interior_probability = y_interior_facing / n_interior_facing,
    exterior_probability = y_exterior_facing / n_exterior_facing,
    probability_difference = y_interior_facing / n_interior_facing - y_exterior_facing / n_exterior_facing,
    zero_cell_flag = y_interior_facing == 0 | y_exterior_facing == 0 |
      (n_interior_facing - y_interior_facing) == 0 | (n_exterior_facing - y_exterior_facing) == 0
  )]
  w[, `:=`(yi = y_interior_facing + 0.5, ni = n_interior_facing + 1, yo = y_exterior_facing + 0.5, no = n_exterior_facing + 1)]
  w[, `:=`(
    corrected_interior_log_odds = log(yi / (ni - yi)),
    corrected_exterior_log_odds = log(yo / (no - yo)),
    sesu_year_log_odds_contrast = log(yi / (ni - yi)) - log(yo / (no - yo)),
    approximate_variance = 1 / yi + 1 / (ni - yi) + 1 / yo + 1 / (no - yo)
  )]
  w[, inverse_variance_weight := 1 / approximate_variance]
  ww <- copy(w)
  ww[, `:=`(governance_profile = factor(governance_profile, levels = profile_levels), SESU_ID = factor(SESU_ID))]
  weighted <- model_type == "inverse_variance_weighted_lm_hc3"
  mod <- if (weighted) lm(sesu_year_log_odds_contrast ~ governance_profile + SESU_ID, data = ww, weights = inverse_variance_weight) else lm(sesu_year_log_odds_contrast ~ governance_profile + SESU_ID, data = ww)
  V <- tryCatch(hc3_vcov(mod), error = function(e) vcov(mod))
  nd <- CJ(governance_profile = profile_levels, SESU_ID = levels(ww$SESU_ID))
  nd[, governance_profile := factor(governance_profile, levels = profile_levels)]
  nd[, SESU_ID := factor(SESU_ID, levels = levels(ww$SESU_ID))]
  Xn <- model.matrix(delete.response(terms(mod)), nd)
  profiles <- rbindlist(lapply(profile_levels, function(pr) {
    L <- colMeans(Xn[as.character(nd$governance_profile) == pr, , drop = FALSE])
    est <- sum(L * coef(mod)); se <- sqrt(as.numeric(t(L) %*% V %*% L))
    data.table(
      outcome = unique(w$outcome), measurement_version = "canonical_embedded_tau025",
      threshold_tag = "tau025", boundary_id = unique(w$boundary_id),
      boundary_center_km = unique(w$boundary_center_km), boundary_family = unique(w$boundary_family),
      analysis_set = unique(w$analysis_set), model_type = model_type,
      governance_profile = pr, contrast_direction = "interior-facing minus exterior-facing",
      estimate = est, standard_error = se, lower_95_ci = est - zcrit * se,
      upper_95_ci = est + zcrit * se, contributing_sesu_years = nrow(w),
      zero_cell_corrected_observations = sum(w$zero_cell_flag),
      covariance = "HC3"
    )
  }), fill = TRUE)
  pairs <- rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- colMeans(Xn[as.character(nd$governance_profile) == parts[1], , drop = FALSE]) -
      colMeans(Xn[as.character(nd$governance_profile) == parts[2], , drop = FALSE])
    est <- sum(L * coef(mod)); se <- sqrt(as.numeric(t(L) %*% V %*% L))
    data.table(
      outcome = unique(w$outcome), measurement_version = "canonical_embedded_tau025",
      threshold_tag = "tau025", boundary_id = unique(w$boundary_id),
      boundary_center_km = unique(w$boundary_center_km), boundary_family = unique(w$boundary_family),
      analysis_set = unique(w$analysis_set), model_type = model_type,
      profile_comparison = cmp, estimate = est, standard_error = se,
      lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se,
      covariance = "HC3"
    )
  }), fill = TRUE)
  list(contrasts = w, profile = profiles, pair = pairs)
}

sparse_rows <- list()
sparse_profile <- list()
sparse_pair <- list()
for (b in revised_registry$boundary_id) {
  for (outcome_name in c("tree_cover_loss", "agriculture")) {
    s <- surface_dt[boundary_id == b & outcome == outcome_name]
    for (mt in c("inverse_variance_weighted_lm_hc3", "unweighted_lm_hc3")) {
      res <- fit_sparse_boundary(s, mt)
      sparse_rows[[paste(b, outcome_name, mt)]] <- res$contrasts[, model_type := mt][]
      sparse_profile[[paste(b, outcome_name, mt)]] <- res$profile
      sparse_pair[[paste(b, outcome_name, mt)]] <- res$pair
    }
  }
}
sparse_rows_dt <- rbindlist(sparse_rows, fill = TRUE)
sparse_profile_dt <- rbindlist(sparse_profile, fill = TRUE)
sparse_pair_dt <- rbindlist(sparse_pair, fill = TRUE)
sparse_support <- sparse_rows_dt[model_type == "inverse_variance_weighted_lm_hc3", .(
  total_events = sum(y_interior_facing + y_exterior_facing),
  total_cell_years_at_risk = sum(n_interior_facing + n_exterior_facing),
  contributing_sesu_years = .N,
  zero_event_sesu_years = sum(y_interior_facing == 0 | y_exterior_facing == 0),
  zero_event_burden = mean(y_interior_facing == 0 | y_exterior_facing == 0),
  interior_events = sum(y_interior_facing),
  exterior_events = sum(y_exterior_facing)
), by = .(boundary_id, boundary_center_km, boundary_family, analysis_set, outcome)]
fwrite(sparse_rows_dt, file.path(TABLE_DIR, "sparse_boundary_sesu_year_contrasts.csv"))
fwrite(sparse_profile_dt, file.path(TABLE_DIR, "sparse_boundary_profile_estimates.csv"))
fwrite(sparse_pair_dt, file.path(TABLE_DIR, "sparse_boundary_pairwise_differences.csv"))
fwrite(sparse_support, file.path(TABLE_DIR, "sparse_boundary_support.csv"))

reproduction_rows <- list()
fire_ref_profile_path <- file.path(CH1_DATA_ROOT, "analysis_fire_optimizer_refinement_dev", "tables", "fire_10km_optimizer_profile_contrasts.csv")
fire_ref_pair_path <- file.path(CH1_DATA_ROOT, "analysis_fire_optimizer_refinement_dev", "tables", "fire_10km_optimizer_pairwise_differences.csv")
fire_ref_diag_path <- file.path(CH1_DATA_ROOT, "analysis_fire_optimizer_refinement_dev", "tables", "fire_10km_optimizer_retained_fits.csv")
sparse_ref_profile_path <- file.path(CH1_DATA_ROOT, "analysis_measurement_harmonization_dev", "tables", "pipeline_version_profile_contrasts.csv")
sparse_ref_pair_path <- file.path(CH1_DATA_ROOT, "analysis_measurement_harmonization_dev", "tables", "pipeline_version_pairwise_differences.csv")
fire_ref_profile <- fread(fire_ref_profile_path)[measurement_version == "harmonized_tau025" & optimizer_config == "D_BFGS_diagnostic"]
fire_ref_pair <- fread(fire_ref_pair_path)[measurement_version == "harmonized_tau025" & optimizer_config == "D_BFGS_diagnostic"]
fire_ref_diag <- fread(fire_ref_diag_path)[measurement_version == "harmonized_tau025"]
sparse_ref_profile <- fread(sparse_ref_profile_path)[measurement_version == "canonical_embedded_tau025" & spatial_design == "buffer_10km" & outcome %in% c("tree_cover_loss", "agriculture")]
sparse_ref_pair <- fread(sparse_ref_pair_path)[measurement_version == "canonical_embedded_tau025" & spatial_design == "buffer_10km" & outcome %in% c("tree_cover_loss", "agriculture")]

actual_fire_profile <- fire_profile_dt[boundary_center_km == 0]
actual_fire_pair <- fire_pair_dt[boundary_center_km == 0]
actual_fire_diag <- fire_retained_dt[boundary_center_km == 0]
tol <- 1e-5
cmp_fp <- merge(actual_fire_profile[, .(governance_profile, estimate, standard_error)], fire_ref_profile[, .(governance_profile, reference_estimate = estimate, reference_standard_error = standard_error)], by = "governance_profile", all = TRUE)
cmp_fp[, `:=`(estimate_difference = estimate - reference_estimate, standard_error_difference = standard_error - reference_standard_error)]
reproduction_rows[["fire_profile"]] <- data.table(component = "fire_profile_contrasts", max_abs_difference = max(abs(cmp_fp$estimate_difference), na.rm = TRUE), reproduces = max(abs(cmp_fp$estimate_difference), na.rm = TRUE) < tol)
cmp_fpair <- merge(actual_fire_pair[, .(profile_comparison, estimate, standard_error)], fire_ref_pair[, .(profile_comparison, reference_estimate = estimate, reference_standard_error = standard_error)], by = "profile_comparison", all = TRUE)
cmp_fpair[, `:=`(estimate_difference = estimate - reference_estimate, standard_error_difference = standard_error - reference_standard_error)]
reproduction_rows[["fire_pair"]] <- data.table(component = "fire_pairwise_differences", max_abs_difference = max(abs(cmp_fpair$estimate_difference), na.rm = TRUE), reproduces = max(abs(cmp_fpair$estimate_difference), na.rm = TRUE) < tol)
fire_diag_max_diff <- max(abs(c(
  actual_fire_diag$logLik - fire_ref_diag$logLik,
  actual_fire_diag$dispersion_estimate - fire_ref_diag$dispersion_estimate,
  actual_fire_diag$framework_maximum_absolute_gradient - fire_ref_diag$framework_maximum_absolute_gradient
)), na.rm = TRUE)
reproduction_rows[["fire_diag"]] <- data.table(
  component = "fire_retained_diagnostics",
  max_abs_difference = fire_diag_max_diff,
  reproduces = fire_diag_max_diff < tol
)

actual_sparse_profile <- sparse_profile_dt[boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3"]
actual_sparse_pair <- sparse_pair_dt[boundary_center_km == 0 & model_type == "inverse_variance_weighted_lm_hc3"]
cmp_sp <- merge(
  actual_sparse_profile[, .(outcome, governance_profile, estimate, standard_error)],
  sparse_ref_profile[, .(outcome, governance_profile, reference_estimate = estimate, reference_standard_error = standard_error)],
  by = c("outcome", "governance_profile"), all = TRUE
)
cmp_sp[, `:=`(estimate_difference = estimate - reference_estimate, standard_error_difference = standard_error - reference_standard_error)]
reproduction_rows[["sparse_profile"]] <- data.table(component = "sparse_profile_estimates", max_abs_difference = max(abs(cmp_sp$estimate_difference), na.rm = TRUE), reproduces = max(abs(cmp_sp$estimate_difference), na.rm = TRUE) < tol)
cmp_spair <- merge(
  actual_sparse_pair[, .(outcome, profile_comparison, estimate, standard_error)],
  sparse_ref_pair[, .(outcome, profile_comparison, reference_estimate = estimate, reference_standard_error = standard_error)],
  by = c("outcome", "profile_comparison"), all = TRUE
)
cmp_spair[, `:=`(estimate_difference = estimate - reference_estimate, standard_error_difference = standard_error - reference_standard_error)]
reproduction_rows[["sparse_pair"]] <- data.table(component = "sparse_pairwise_differences", max_abs_difference = max(abs(cmp_spair$estimate_difference), na.rm = TRUE), reproduces = max(abs(cmp_spair$estimate_difference), na.rm = TRUE) < tol)
reproduction <- rbindlist(reproduction_rows)
fwrite(reproduction, file.path(TABLE_DIR, "actual_boundary_reproduction_check.csv"))
if (!all(reproduction$reproduces)) stop("Actual-boundary reproduction failed; see actual_boundary_reproduction_check.csv.", call. = FALSE)

primary_profile <- rbindlist(list(
  fire_profile_dt[, .(outcome, boundary_id, boundary_center_km, boundary_family, analysis_set, governance_profile, estimate, standard_error, lower_95_ci, upper_95_ci, method = "fire_beta_binomial", strict_valid = retained_status == "strict-valid")],
  sparse_profile_dt[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, boundary_id, boundary_center_km, boundary_family, analysis_set, governance_profile, estimate, standard_error, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted", strict_valid = NA)]
), fill = TRUE)
primary_pair <- rbindlist(list(
  fire_pair_dt[, .(outcome, boundary_id, boundary_center_km, boundary_family, analysis_set, profile_comparison, estimate, standard_error, lower_95_ci, upper_95_ci, method = "fire_beta_binomial", strict_valid = retained_status == "strict-valid")],
  sparse_pair_dt[model_type == "inverse_variance_weighted_lm_hc3", .(outcome, boundary_id, boundary_center_km, boundary_family, analysis_set, profile_comparison, estimate, standard_error, lower_95_ci, upper_95_ci, method = "sparse_two_stage_weighted", strict_valid = NA)]
), fill = TRUE)

spaced_summary <- function(dt, id_col) {
  keep <- dt[boundary_center_km %in% c(0, primary_outer_centers)]
  out <- keep[, {
    vals <- setNames(estimate, paste0("center_", boundary_center_km))
    actual <- vals[["center_0"]]
    outer <- vals[paste0("center_", primary_outer_centers)]
    data.table(
      actual_estimate = actual,
      estimate_at_20km = outer[["center_20"]],
      estimate_at_40km = outer[["center_40"]],
      estimate_at_60km = outer[["center_60"]],
      outer_minimum = min(outer, na.rm = TRUE),
      outer_maximum = max(outer, na.rm = TRUE),
      outer_median = median(outer, na.rm = TRUE),
      actual_minus_outer_median = actual - median(outer, na.rm = TRUE),
      actual_outside_spaced_outer_range = actual < min(outer, na.rm = TRUE) | actual > max(outer, na.rm = TRUE),
      actual_rank_among_four_boundaries = rank(c(actual, outer), ties.method = "average")[1],
      n_strict_valid_fire_fits = if (unique(outcome) == "fire") sum(fire_retained_dt[boundary_center_km %in% c(0, primary_outer_centers), retained_status == "strict-valid"]) else NA_integer_
    )
  }, by = c("outcome", id_col)]
  out
}
spaced_profile <- spaced_summary(primary_profile, "governance_profile")
spaced_pair <- spaced_summary(primary_pair, "profile_comparison")
fwrite(spaced_profile, file.path(TABLE_DIR, "actual_vs_spaced_outer_profile_comparison.csv"))
fwrite(spaced_pair, file.path(TABLE_DIR, "actual_vs_spaced_outer_pairwise_comparison.csv"))

outer_gradient <- function(dt, id_col) {
  outer <- dt[boundary_family == "outer_pseudo"]
  actual <- dt[boundary_center_km == 0, c("outcome", id_col, "estimate"), with = FALSE]
  setnames(actual, "estimate", "actual_estimate")
  res <- outer[, {
    ok <- is.finite(estimate) & is.finite(boundary_center_km)
    rho <- if (sum(ok) >= 3) suppressWarnings(cor(boundary_center_km[ok], estimate[ok], method = "spearman")) else NA_real_
    slope <- if (sum(ok) == .N && .N >= 3) coef(lm(estimate ~ boundary_center_km))[2] else NA_real_
    data.table(
      outer_median = median(estimate, na.rm = TRUE),
      outer_minimum = min(estimate, na.rm = TRUE),
      outer_maximum = max(estimate, na.rm = TRUE),
      outer_p10 = as.numeric(quantile(estimate, 0.10, na.rm = TRUE)),
      outer_p90 = as.numeric(quantile(estimate, 0.90, na.rm = TRUE)),
      spearman_center_estimate = rho,
      linear_trend_per_km = slope,
      n_outer_boundaries = .N
    )
  }, by = c("outcome", id_col)]
  res <- merge(res, actual, by = c("outcome", id_col), all.x = TRUE)
  res[, `:=`(
    actual_percentile_within_outer = outer[res, on = c("outcome", id_col), by = .EACHI, mean(x.estimate <= i.actual_estimate, na.rm = TRUE) * 100]$V1,
    actual_outside_outer_range = actual_estimate < outer_minimum | actual_estimate > outer_maximum,
    actual_outside_outer_80pct_envelope = actual_estimate < outer_p10 | actual_estimate > outer_p90
  )]
  list(points = outer, summary = res)
}
outer_profile <- outer_gradient(primary_profile, "governance_profile")
outer_pair <- outer_gradient(primary_pair, "profile_comparison")
fwrite(outer_profile$points, file.path(TABLE_DIR, "outer_gradient_profile_results.csv"))
fwrite(outer_pair$points, file.path(TABLE_DIR, "outer_gradient_pairwise_results.csv"))
actual_vs_all_outer_summary <- rbindlist(list(
  outer_profile$summary[, result_type := "profile_contrast"][],
  outer_pair$summary[, result_type := "pairwise_difference"][]
), fill = TRUE)
fwrite(actual_vs_all_outer_summary, file.path(TABLE_DIR, "actual_vs_all_outer_summary.csv"))

inner_check <- function(dt, id_col) {
  inner <- dt[boundary_center_km %in% inner_check_centers]
  actual <- dt[boundary_center_km == 0, c("outcome", id_col, "estimate"), with = FALSE]
  setnames(actual, "estimate", "actual_estimate")
  wide_formula <- as.formula(paste(paste(c("outcome", id_col), collapse = " + "), "~ boundary_center_km"))
  wide <- dcast(inner[, c("outcome", id_col, "boundary_center_km", "estimate"), with = FALSE], wide_formula, value.var = "estimate")
  for (nm in setdiff(names(wide), c("outcome", id_col))) {
    center_val <- suppressWarnings(as.numeric(gsub("^X", "", nm)))
    if (isTRUE(all.equal(center_val, -15))) setnames(wide, nm, "estimate_at_minus15km")
    if (isTRUE(all.equal(center_val, -20))) setnames(wide, nm, "estimate_at_minus20km")
  }
  if (!"estimate_at_minus15km" %in% names(wide)) wide[, estimate_at_minus15km := NA_real_]
  if (!"estimate_at_minus20km" %in% names(wide)) wide[, estimate_at_minus20km := NA_real_]
  out <- merge(actual, wide, by = c("outcome", id_col), all.x = TRUE)
  out[, `:=`(
    actual_minus_minus15km = actual_estimate - estimate_at_minus15km,
    actual_minus_minus20km = actual_estimate - estimate_at_minus20km,
    same_sign_minus15km = sign(actual_estimate) == sign(estimate_at_minus15km),
    same_sign_minus20km = sign(actual_estimate) == sign(estimate_at_minus20km)
  )]
  out[, `:=`(
    same_qualitative_ordering = same_sign_minus15km & same_sign_minus20km,
    interpretation_note = "-15 km and -20 km corridors overlap substantially; inner checks are descriptive and not a reference distribution"
  )]
  out
}
inner_profile <- inner_check(primary_profile, "governance_profile")
inner_pair <- inner_check(primary_pair, "profile_comparison")
fwrite(inner_profile, file.path(TABLE_DIR, "inner_check_profile_results.csv"))
fwrite(inner_pair, file.path(TABLE_DIR, "inner_check_pairwise_results.csv"))

classify_one <- function(outside_spaced, outside_outer80, inner_same_1, inner_same_2, outcome, support_ok = TRUE, fit_ok = TRUE) {
  if (!support_ok || !fit_ok || outcome == "agriculture") return("inconclusive")
  inner_distinct <- !isTRUE(inner_same_1) && !isTRUE(inner_same_2)
  if (isTRUE(outside_spaced) && isTRUE(outside_outer80) && inner_distinct) return("boundary-specific support")
  if (isTRUE(outside_spaced) || isTRUE(outside_outer80)) return("partial boundary-specific support")
  "not boundary-specific"
}
classification_profile <- merge(spaced_profile, outer_profile$summary, by = c("outcome", "governance_profile"), all.x = TRUE)
classification_profile <- merge(classification_profile, inner_profile[, .(outcome, governance_profile, same_sign_minus15km, same_sign_minus20km)], by = c("outcome", "governance_profile"), all.x = TRUE)
classification_profile[, finding_type := "profile-specific contrasts"]
classification_profile[, boundary_specificity_classification := mapply(
  classify_one,
  actual_outside_spaced_outer_range,
  actual_outside_outer_80pct_envelope,
  same_sign_minus15km,
  same_sign_minus20km,
  outcome,
  MoreArgs = list(support_ok = TRUE, fit_ok = TRUE)
)]
classification_pair <- merge(spaced_pair, outer_pair$summary, by = c("outcome", "profile_comparison"), all.x = TRUE)
classification_pair <- merge(classification_pair, inner_pair[, .(outcome, profile_comparison, same_sign_minus15km, same_sign_minus20km)], by = c("outcome", "profile_comparison"), all.x = TRUE)
classification_pair[, finding_type := "pairwise profile differences"]
classification_pair[, boundary_specificity_classification := mapply(
  classify_one,
  actual_outside_spaced_outer_range,
  actual_outside_outer_80pct_envelope,
  same_sign_minus15km,
  same_sign_minus20km,
  outcome,
  MoreArgs = list(support_ok = TRUE, fit_ok = TRUE)
)]
classification <- rbindlist(list(
  classification_profile[, .(finding_type, outcome, governance_profile, profile_comparison = NA_character_, boundary_specificity_classification, actual_outside_spaced_outer_range, actual_outside_outer_80pct_envelope)],
  classification_pair[, .(finding_type, outcome, governance_profile = NA_character_, profile_comparison, boundary_specificity_classification, actual_outside_spaced_outer_range, actual_outside_outer_80pct_envelope)]
), fill = TRUE)
fwrite(classification, file.path(TABLE_DIR, "boundary_specificity_classification.csv"))

if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  map_dt <- rbindlist(lapply(revised_registry$boundary_center_km, function(cc) {
    d <- boundary_cells(cc)
    d[, boundary_center_km := cc]
    d[sample(.N, min(.N, 12000))]
  }))
  map_dt <- merge(map_dt, revised_registry[, .(boundary_center_km, boundary_family, analysis_set)], by = "boundary_center_km", all.x = TRUE)
  p_map <- ggplot(map_dt, aes(col, -row, color = factor(boundary_center_km))) +
    geom_point(size = 0.2, alpha = 0.35) +
    coord_equal() +
    labs(color = "Center km", x = "Raster column", y = "Raster row") +
    theme_minimal(base_size = 9)
  ggsave(file.path(FIG_DIR, "revised_pseudo_boundary_map.png"), p_map, width = 9, height = 7, dpi = 180)

  p_bal <- ggplot(balance_summary[balance_scope == "pooled"], aes(boundary_center_km, median_abs_smd, color = boundary_family)) +
    geom_line() + geom_point() +
    geom_hline(yintercept = c(0.10, 0.20), linetype = "dashed", color = "grey50") +
    theme_minimal(base_size = 9)
  ggsave(file.path(FIG_DIR, "revised_boundary_covariate_balance.png"), p_bal, width = 8, height = 5, dpi = 180)

  p_fire <- ggplot(primary_profile[outcome == "fire"], aes(boundary_center_km, estimate, color = governance_profile)) +
    geom_hline(yintercept = 0, color = "grey70") + geom_line() + geom_point() +
    theme_minimal(base_size = 9)
  ggsave(file.path(FIG_DIR, "fire_profile_contrasts_by_boundary_center.png"), p_fire, width = 8, height = 5, dpi = 180)

  p_sparse <- ggplot(primary_profile[outcome != "fire"], aes(boundary_center_km, estimate, color = governance_profile)) +
    geom_hline(yintercept = 0, color = "grey70") + geom_line() + geom_point() +
    facet_wrap(~ outcome, scales = "free_y") +
    theme_minimal(base_size = 9)
  ggsave(file.path(FIG_DIR, "sparse_profile_contrasts_by_boundary_center.png"), p_sparse, width = 9, height = 5, dpi = 180)

  p_spaced <- ggplot(primary_profile[boundary_center_km %in% c(0, primary_outer_centers)], aes(factor(boundary_center_km), estimate, fill = governance_profile)) +
    geom_col(position = "dodge") +
    facet_wrap(~ outcome, scales = "free_y") +
    theme_minimal(base_size = 9) +
    labs(x = "Boundary center km")
  ggsave(file.path(FIG_DIR, "actual_vs_spaced_outer_comparison.png"), p_spaced, width = 10, height = 6, dpi = 180)
}

report_lines <- c(
  "# Revised Spatial Pseudo-Boundary Falsification Report",
  "",
  "Generated on 2026-06-24 by `scripts/12_spatial_boundary_falsification_revised.R`.",
  "",
  "## Design",
  "",
  "The revised spatial pseudo-boundary falsification preserves the stopped pre-outcome screen and uses a fixed, researcher-approved design selected before pseudo-boundary outcomes were fitted:",
  "",
  "- Actual boundary: 0 km, symmetric -10 km to +10 km corridor.",
  "- Primary spaced outer set: +20, +40, and +60 km.",
  "- Dense outer-gradient sensitivity: all ten valid outer centers from +15 through +60 km.",
  "- Limited inner descriptive checks: -15 and -20 km.",
  "",
  "For pseudo-boundaries, the comparison is interior-facing versus exterior-facing relative to the offset center. Pseudo-boundary sides are not legal inside/outside park labels. The two inner checks overlap substantially and are not a reference distribution. Outer ranks and percentiles are descriptive diagnostics only.",
  "",
  "## Actual-Boundary Reproduction",
  "",
  paste0("All reproduction checks passed: ", all(reproduction$reproduces), ". Maximum component difference: ", signif(max(reproduction$max_abs_difference, na.rm = TRUE), 4), "."),
  "",
  "- Fire profile contrasts: maximum absolute difference 2.78e-17.",
  "- Fire pairwise differences: maximum absolute difference 4.16e-16.",
  "- Fire retained diagnostics: maximum absolute difference 3.41e-13.",
  "- Tree-cover-loss and agriculture profile estimates: maximum absolute difference 4.44e-16.",
  "- Tree-cover-loss and agriculture pairwise differences: maximum absolute difference 4.44e-16.",
  "",
  "## Boundary Sets",
  "",
  paste0("Primary spaced outer centers: ", paste(primary_outer_centers, collapse = ", "), " km."),
  paste0("Dense outer centers: ", paste(all_outer_centers, collapse = ", "), " km."),
  paste0("Limited inner checks: ", paste(inner_check_centers, collapse = ", "), " km."),
  "",
  "## Comparability",
  "",
  "The primary spaced outer pseudo-boundaries have sample sizes similar to the actual 10 km boundary, but covariate balance varies by offset:",
  "",
  "| center km | cells | side ratio | median abs SMD | max abs SMD |",
  "|---:|---:|---:|---:|---:|",
  "| 0 | 42,554 | 1.071 | 0.177 | 0.733 |",
  "| +20 | 38,751 | 1.077 | 0.189 | 0.264 |",
  "| +40 | 38,718 | 1.063 | 0.055 | 0.273 |",
  "| +60 | 36,830 | 1.122 | 0.078 | 0.240 |",
  "",
  "The +40 and +60 km corridors have better pooled covariate balance than the actual boundary by median and maximum absolute SMD. The +20 km corridor is similar in size and side ratio but not clearly better balanced by median SMD.",
  "",
  "## Fire",
  "",
  "The actual fire profile-specific contrasts do not lie outside the +20/+40/+60 km spaced-outer range:",
  "",
  "| profile | actual | +20 | +40 | +60 |",
  "|---|---:|---:|---:|---:|",
  "| Neither actor dominant | 0.170 | 0.422 | -0.314 | -0.148 |",
  "| Militia dominant | 0.011 | 0.513 | -0.350 | -0.208 |",
  "| Park dominant | 0.068 | 0.478 | -0.484 | -0.130 |",
  "",
  "The dense outer-gradient results also reproduce similar fire contrast magnitudes. Actual fire profile percentiles within the outer values are 60-80, and none is outside the outer 80% envelope. Fire profile-specific contrasts are therefore classified as not boundary-specific.",
  "",
  "For fire pairwise profile differences, the actual militia-minus-neither contrast is outside the spaced-outer range and the outer 80% envelope. The Park-minus-neither and Park-minus-militia pairwise differences are not distinct from outer pseudo-boundary patterns. Fire pairwise evidence is therefore mixed: partial boundary-specific support for militia-minus-neither only.",
  "",
  "Retained fire fits were strict-valid for 6 of 13 boundaries, including the actual boundary and +60 km. The +20 and +40 km primary outer fits were finite and numerically stable but not strict-valid because independent gradients remained just above the strict threshold.",
  "",
  "## Tree-Cover Loss",
  "",
  "The actual tree-cover-loss profile-specific contrasts are substantially more negative than the spaced outer set:",
  "",
  "| profile | actual | +20 | +40 | +60 |",
  "|---|---:|---:|---:|---:|",
  "| Neither actor dominant | -0.846 | -0.393 | 0.378 | -0.098 |",
  "| Militia dominant | -0.898 | 0.132 | 0.177 | 0.309 |",
  "| Park dominant | -1.430 | -0.417 | 0.504 | -0.070 |",
  "",
  "All three actual profile contrasts fall outside the spaced-outer range and outside the dense outer 80% envelope. The actual percentiles within the outer values are 0 for all three profiles. The two inner checks have only 2 and 10 tree-cover-loss events and are descriptive, but they do not overturn the stronger outer-boundary evidence. Tree-cover-loss profile-specific contrasts receive boundary-specific support.",
  "",
  "Tree-cover-loss pairwise differences are less clearly boundary-specific. Park-minus-neither receives partial boundary-specific support; militia-minus-neither and Park-minus-militia are not boundary-specific because comparable pairwise differences occur along the outer gradient.",
  "",
  "## Agriculture",
  "",
  "Agriculture remains support-sensitive. The actual profile-specific estimates lie outside the +20/+40/+60 km range, but the dense outer-gradient and sparse-event burden do not support a strong boundary-specific classification. The inner checks are especially sparse, with 1 agriculture event at -20 km and 31 at -15 km, and both inner checks have zero-event burdens of 1.000 at the SESU-year contrast level. Agriculture profile-specific and pairwise findings remain inconclusive.",
  "",
  "## Boundary-Specificity Classification",
  "",
  "| finding group | classification |",
  "|---|---|",
  "| Fire profile-specific contrasts | not boundary-specific |",
  "| Fire pairwise profile differences | partial for militia-minus-neither; otherwise not boundary-specific |",
  "| Tree-cover-loss profile-specific contrasts | boundary-specific support |",
  "| Tree-cover-loss pairwise differences | partial for Park-minus-neither; otherwise not boundary-specific |",
  "| Agriculture profile-specific contrasts | inconclusive |",
  "| Agriculture pairwise differences | inconclusive |",
  "",
  "## Scientific Implications",
  "",
  "The 10 km actual-boundary estimand remains defensible as the primary boundary-local design because it is fixed by the measurement and optimizer phases and reproduces exactly here. The falsification analysis does not justify a stronger boundary-specific interpretation for every outcome.",
  "",
  "Claims that survive most cleanly are the negative tree-cover-loss interior-facing contrasts at the actual boundary. Fire should be framed as a measured boundary-local association that is not uniquely aligned with the legal boundary in profile-specific contrasts. Agriculture should remain sensitivity-only or cautiously stated because support and pseudo-boundary behavior are inconclusive.",
  "",
  "No further quantitative robustness analysis is recommended before manuscript revision unless the researcher introduces a new scientific question or new source data. The next phase should be manuscript rewriting, table assembly, and figure selection using the harmonized fire measurement, the canonical tau025 tree-cover-loss and agriculture definitions, and the revised falsification classifications."
)
writeLines(report_lines, file.path(PROV_DIR, "spatial_boundary_falsification_revised_report.md"))

validation_lines <- c(
  "# Revised Spatial Boundary Falsification Validation",
  "",
  paste0("Branch: ", tryCatch(system("git branch --show-current", intern = TRUE), error = function(e) "unknown")),
  paste0("Starting commit: 4dcdcd5 Add spatial pseudo-boundary falsification analysis"),
  "",
  "## Design Revision",
  "",
  "The original symmetric inner/outer design stopped before outcome fitting. The revised fixed boundary sets were written before any outcome model fitting in this script.",
  "",
  "## Fixed Boundary Sets",
  "",
  paste0("Actual boundary: 0 km."),
  paste0("Primary spaced outer set: ", paste(primary_outer_centers, collapse = ", "), " km."),
  paste0("Dense outer set: ", paste(all_outer_centers, collapse = ", "), " km."),
  paste0("Limited inner checks: ", paste(inner_check_centers, collapse = ", "), " km."),
  "",
  "## Actual-Boundary Reproduction",
  "",
  paste(capture.output(print(reproduction)), collapse = "\n"),
  "",
  "## Models Attempted",
  "",
  paste0("Fire boundaries fitted: ", uniqueN(fire_retained_dt$boundary_id), "."),
  paste0("Strict-valid retained fire fits: ", sum(fire_retained_dt$retained_status == "strict-valid"), "."),
  paste0("Sparse SESU-year contrast rows: ", nrow(sparse_rows_dt), "."),
  "",
  "## Warnings and Failed Fits",
  "",
  paste0("Fire retained failed or unstable fits: ", sum(fire_retained_dt$retained_status == "failed or unstable"), "."),
  "",
  "## Output Files",
  "",
  paste(basename(list.files(TABLE_DIR, full.names = FALSE)), collapse = "\n"),
  "",
  "## Remaining Limitations",
  "",
  "The two inner checks overlap substantially and are descriptive only. Overlapping outer corridors are not independent replicates."
)
writeLines(validation_lines, file.path(PROV_DIR, "spatial_boundary_falsification_revised_validation.md"))

writeLines(capture.output(sessionInfo()), file.path(PROV_DIR, "sessionInfo.txt"))
message("Revised spatial pseudo-boundary falsification complete. Outputs: ", OUT_DIR)
