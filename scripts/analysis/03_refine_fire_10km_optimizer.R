# ===========================================================
# CHAPTER 1 HARMONIZED 10 KM FIRE OPTIMIZER REFINEMENT
# ===========================================================
# Refines only the harmonized 10 km fire beta-binomial fits.
# The data, model formula, family, link, threshold definitions,
# SESU assignments, governance profiles, and side coding are held
# fixed relative to scripts/09_fire_2021_2022_harmonization.R.
# ===========================================================

suppressPackageStartupMessages({
  library(data.table)
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

OUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_fire_optimizer_refinement_dev")
TABLE_DIR <- file.path(OUT_DIR, "tables")
MODEL_DIR <- file.path(OUT_DIR, "models")
LOG_DIR <- file.path(OUT_DIR, "logs")
PROV_DIR <- file.path(OUT_DIR, "provenance")
for (p in c(OUT_DIR, TABLE_DIR, MODEL_DIR, LOG_DIR, PROV_DIR)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

zcrit <- qnorm(1 - CH1_ALPHA / 2)
gradient_tol <- CH1_MAX_ABS_GRADIENT_TOL
threshold_tags <- c("tau010", "tau025", "tau050")
measurement_versions <- paste0("harmonized_", threshold_tags)
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")
pairwise_comparisons <- c(
  "Park dominant minus Neither actor dominant",
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)

surface_path <- file.path(CH1_DATA_ROOT, "analysis_fire_harmonization_dev", "tables", "fire_harmonized_surface_summary.csv")
phase5_diag_path <- file.path(CH1_DATA_ROOT, "analysis_fire_harmonization_dev", "tables", "fire_harmonized_fit_diagnostics.csv")
phase5_profile_path <- file.path(CH1_DATA_ROOT, "analysis_fire_harmonization_dev", "tables", "fire_harmonized_profile_contrasts.csv")
phase5_pair_path <- file.path(CH1_DATA_ROOT, "analysis_fire_harmonization_dev", "tables", "fire_harmonized_pairwise_differences.csv")
for (p in c(surface_path, phase5_diag_path, phase5_profile_path, phase5_pair_path)) {
  if (!file.exists(p)) stop("Missing required Phase 5 output: ", p, call. = FALSE)
}

surfaces <- fread(surface_path)
phase5_diag <- fread(phase5_diag_path)
phase5_profile <- fread(phase5_profile_path)
phase5_pair <- fread(phase5_pair_path)

model_data <- surfaces[
  measurement_version %in% measurement_versions &
    spatial_design == "buffer_10km"
]
if (nrow(model_data) == 0) stop("No harmonized 10 km fire rows found.", call. = FALSE)

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

make_profile_L <- function(beta_names, profile) {
  L <- setNames(rep(0, length(beta_names)), beta_names)
  if ("sideinside" %in% beta_names) L["sideinside"] <- 1
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

profile_contrasts <- function(m, measurement_version, threshold_tag, optimizer_config, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(profile_levels, function(pr) {
    cbind(
      data.table(
        measurement_version = measurement_version,
        threshold_tag = threshold_tag,
        spatial_design = "buffer_10km",
        optimizer_config = optimizer_config,
        governance_profile = pr
      ),
      contrast_stats(beta, V, make_profile_L(names(beta), pr), intervals = strict_valid)
    )
  }), fill = TRUE)
}

pairwise_contrasts <- function(m, measurement_version, threshold_tag, optimizer_config, strict_valid) {
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
    L <- make_profile_L(names(beta), parts[1]) - make_profile_L(names(beta), parts[2])
    cbind(
      data.table(
        measurement_version = measurement_version,
        threshold_tag = threshold_tag,
        spatial_design = "buffer_10km",
        optimizer_config = optimizer_config,
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
  if (identical(parameter, "sideinside")) return("side")
  if (parameter %in% c("inside_profile_militia", "inside_profile_park")) return("governance-profile interaction")
  if (grepl("^disp_", parameter)) return("dispersion")
  "another parameter"
}

numeric_gradient <- function(fn, par) {
  if (requireNamespace("numDeriv", quietly = TRUE)) {
    return(numDeriv::grad(fn, par))
  }
  step <- 1e-5 * (abs(par) + 1)
  out <- numeric(length(par))
  for (i in seq_along(par)) {
    up <- par
    dn <- par
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
    C_strict_nlminb_polish = glmmTMBControl(optCtrl = list(iter.max = 10000, eval.max = 20000, rel.tol = 1e-12, x.tol = 1e-10, abs.tol = 1e-10, trace = 0)),
    BFGS_refined = glmmTMBControl(
      optimizer = optim,
      optArgs = list(method = "BFGS"),
      optCtrl = list(maxit = 20000, reltol = 1e-12)
    ),
    stop("Unknown optimizer config: ", config_id, call. = FALSE)
  )
  start <- if (is.null(start_model) || inherits(start_model, "fit_error")) NULL else make_start(start_model)
  fit <- withCallingHandlers(
    tryCatch(
      glmmTMB(
        primary_formula,
        family = betabinomial(link = "logit"),
        data = d,
        control = control,
        start = start
      ),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = unique(warnings), start_used = !is.null(start))
}

fit_diagnostics <- function(fw, d, measurement_version, threshold_tag, config_id) {
  X <- tryCatch(model.matrix(primary_formula, d), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  base <- data.table(
    measurement_version = measurement_version,
    threshold_tag = threshold_tag,
    spatial_design = "buffer_10km",
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
      convergence_code = NA_integer_,
      optimizer_message = fw$fit$error,
      logLik = NA_real_,
      AIC = NA_real_,
      objective_value = NA_real_,
      dispersion_estimate = NA_real_,
      pdHess = NA,
      minimum_hessian_eigenvalue = NA_real_,
      framework_maximum_absolute_gradient = NA_real_,
      numerical_maximum_absolute_gradient = NA_real_,
      largest_framework_gradient_parameter = NA_character_,
      largest_framework_gradient_class = NA_character_,
      largest_numerical_gradient_parameter = NA_character_,
      largest_numerical_gradient_class = NA_character_,
      number_of_parameters = NA_integer_,
      finite_coefficients = FALSE,
      finite_standard_errors = FALSE,
      extreme_parameter_flag = NA,
      finite_profile_contrasts = FALSE,
      strict_valid = FALSE
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
    pc <- profile_contrasts(m, measurement_version, threshold_tag, config_id, strict_valid = FALSE)
    all(is.finite(pc$estimate)) && all(is.finite(pc$standard_error))
  }, error = function(e) FALSE)
  convergence_code <- as.integer(scalar_or(m$fit$convergence, NA_integer_))
  optimizer_message <- as.character(scalar_or(m$fit$message, ""))
  objective_value <- as.numeric(scalar_or(m$fit$objective, scalar_or(m$fit$value, NA_real_)))
  pd_hess <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  strict <- isTRUE(convergence_code == 0) &&
    !grepl("false|fail|error", optimizer_message, ignore.case = TRUE) &&
    pd_hess &&
    identical(rank_x, cols_x) &&
    all(is.finite(beta)) &&
    all(is.finite(coef_se)) &&
    is.finite(max(abs(fw_grad), na.rm = TRUE)) &&
    max(abs(fw_grad), na.rm = TRUE) < gradient_tol &&
    is.finite(max(abs(num_grad), na.rm = TRUE)) &&
    max(abs(num_grad), na.rm = TRUE) < gradient_tol &&
    !any(abs(coef_se) > CH1_EXTREME_SE_THRESHOLD, na.rm = TRUE) &&
    profile_ok
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

parameter_table <- function(m, measurement_version, threshold_tag, config_id) {
  data.table(
    measurement_version = measurement_version,
    threshold_tag = threshold_tag,
    spatial_design = "buffer_10km",
    optimizer_config = config_id,
    parameter = param_labels(m),
    parameter_class = vapply(param_labels(m), classify_parameter, character(1)),
    estimate = c(unname(fixef(m)$cond), unname(fixef(m)$disp))
  )
}

all_diag <- list()
all_profile <- list()
all_pair <- list()
all_param <- list()
baseline_models <- list()
strict_b_models <- list()

for (version in measurement_versions) {
  tag <- sub("^harmonized_", "", version)
  d <- add_model_terms(model_data[measurement_version == version])
  fits <- list()
  fits[["A_baseline"]] <- fit_candidate(d, "A_baseline")
  baseline_models[[version]] <- fits[["A_baseline"]]$fit
  fits[["B_strict_nlminb"]] <- fit_candidate(d, "B_strict_nlminb", start_model = fits[["A_baseline"]]$fit)
  strict_b_models[[version]] <- fits[["B_strict_nlminb"]]$fit
  fits[["C_strict_nlminb_polish"]] <- fit_candidate(d, "C_strict_nlminb_polish", start_model = fits[["B_strict_nlminb"]]$fit)
  fits[["BFGS_refined"]] <- fit_candidate(d, "BFGS_refined", start_model = fits[["B_strict_nlminb"]]$fit)
  for (cfg in names(fits)) {
    dg <- fit_diagnostics(fits[[cfg]], d, version, tag, cfg)
    all_diag[[paste(version, cfg)]] <- dg
    if (!inherits(fits[[cfg]]$fit, "fit_error")) {
      strict_flag <- isTRUE(dg$strict_valid[[1]])
      all_profile[[paste(version, cfg)]] <- profile_contrasts(fits[[cfg]]$fit, version, tag, cfg, strict_flag)
      all_pair[[paste(version, cfg)]] <- pairwise_contrasts(fits[[cfg]]$fit, version, tag, cfg, strict_flag)
      all_param[[paste(version, cfg)]] <- parameter_table(fits[[cfg]]$fit, version, tag, cfg)
    }
  }
}

diag_dt <- rbindlist(all_diag, fill = TRUE)
profile_dt <- rbindlist(all_profile, fill = TRUE)
pair_dt <- rbindlist(all_pair, fill = TRUE)
param_dt <- rbindlist(all_param, fill = TRUE)

baseline_diag <- diag_dt[optimizer_config == "A_baseline"]
baseline_profile <- profile_dt[optimizer_config == "A_baseline"]
baseline_pair <- pair_dt[optimizer_config == "A_baseline"]

phase5_10km_diag <- phase5_diag[measurement_version %in% measurement_versions & spatial_design == "buffer_10km"]
phase5_10km_profile <- phase5_profile[measurement_version %in% measurement_versions & spatial_design == "buffer_10km"]
phase5_10km_pair <- phase5_pair[measurement_version %in% measurement_versions & spatial_design == "buffer_10km"]

baseline_check_diag <- merge(
  baseline_diag[, .(measurement_version, threshold_tag, convergence_code, logLik, AIC, dispersion_estimate, pdHess, framework_maximum_absolute_gradient, model_matrix_rank)],
  phase5_10km_diag[, .(measurement_version, phase5_convergence_code = convergence_code, phase5_dispersion_estimate = dispersion_estimate, phase5_pdHess = pdHess, phase5_maximum_absolute_gradient = maximum_absolute_gradient, phase5_model_matrix_rank = model_matrix_rank)],
  by = "measurement_version",
  all = TRUE
)
baseline_check_diag[, `:=`(
  convergence_code_matches = convergence_code == phase5_convergence_code,
  pdHess_matches = pdHess == phase5_pdHess,
  rank_matches = model_matrix_rank == phase5_model_matrix_rank,
  gradient_difference = framework_maximum_absolute_gradient - phase5_maximum_absolute_gradient,
  dispersion_difference = dispersion_estimate - phase5_dispersion_estimate
)]

baseline_check_profile <- merge(
  unique(baseline_profile[, .(measurement_version, governance_profile, estimate, standard_error)], by = c("measurement_version", "governance_profile")),
  unique(phase5_10km_profile[, .(measurement_version, governance_profile, phase5_estimate = estimate, phase5_standard_error = standard_error)], by = c("measurement_version", "governance_profile")),
  by = c("measurement_version", "governance_profile"),
  all = TRUE
)
baseline_check_profile[, `:=`(
  estimate_difference = estimate - phase5_estimate,
  standard_error_difference = standard_error - phase5_standard_error
)]

baseline_check_pair <- merge(
  unique(baseline_pair[, .(measurement_version, profile_comparison, estimate, standard_error)], by = c("measurement_version", "profile_comparison")),
  unique(phase5_10km_pair[, .(measurement_version, profile_comparison, phase5_estimate = estimate, phase5_standard_error = standard_error)], by = c("measurement_version", "profile_comparison")),
  by = c("measurement_version", "profile_comparison"),
  all = TRUE
)
baseline_check_pair[, `:=`(
  estimate_difference = estimate - phase5_estimate,
  standard_error_difference = standard_error - phase5_standard_error
)]

baseline_reproduces <- all(abs(baseline_check_diag$gradient_difference) < 1e-8, na.rm = TRUE) &&
  all(abs(baseline_check_diag$dispersion_difference) < 1e-8, na.rm = TRUE) &&
  all(abs(baseline_check_profile$estimate_difference) < 1e-8, na.rm = TRUE) &&
  all(abs(baseline_check_pair$estimate_difference) < 1e-8, na.rm = TRUE)
if (!baseline_reproduces) stop("Baseline 10 km fits do not reproduce Phase 5 outputs within tolerance.", call. = FALSE)

baseline_ref <- diag_dt[optimizer_config == "A_baseline",
  .(measurement_version, baseline_logLik = logLik, baseline_dispersion = dispersion_estimate)]
diag_dt <- merge(diag_dt, baseline_ref, by = "measurement_version", all.x = TRUE)
diag_dt[, `:=`(
  delta_logLik = logLik - baseline_logLik,
  dispersion_difference = dispersion_estimate - baseline_dispersion
)]

param_base <- unique(param_dt[optimizer_config == "A_baseline", .(measurement_version, parameter, baseline_parameter_estimate = estimate)], by = c("measurement_version", "parameter"))
param_dt <- merge(param_dt, param_base, by = c("measurement_version", "parameter"), all.x = TRUE)
param_dt[, parameter_difference_from_baseline := estimate - baseline_parameter_estimate]

profile_base <- unique(profile_dt[optimizer_config == "A_baseline", .(measurement_version, governance_profile, baseline_profile_estimate = estimate)], by = c("measurement_version", "governance_profile"))
profile_dt <- merge(profile_dt, profile_base, by = c("measurement_version", "governance_profile"), all.x = TRUE)
profile_dt[, profile_difference_from_baseline := estimate - baseline_profile_estimate]

pair_base <- unique(pair_dt[optimizer_config == "A_baseline", .(measurement_version, profile_comparison, baseline_pairwise_estimate = estimate)], by = c("measurement_version", "profile_comparison"))
pair_dt <- merge(pair_dt, pair_base, by = c("measurement_version", "profile_comparison"), all.x = TRUE)
pair_dt[, pairwise_difference_from_baseline := estimate - baseline_pairwise_estimate]

param_delta <- param_dt[, .(maximum_absolute_coefficient_difference = max(abs(parameter_difference_from_baseline), na.rm = TRUE)), by = .(measurement_version, optimizer_config)]
profile_delta <- profile_dt[, .(maximum_absolute_profile_contrast_difference = max(abs(profile_difference_from_baseline), na.rm = TRUE)), by = .(measurement_version, optimizer_config)]
pair_delta <- pair_dt[, .(maximum_absolute_pairwise_difference = max(abs(pairwise_difference_from_baseline), na.rm = TRUE)), by = .(measurement_version, optimizer_config)]
diag_dt <- Reduce(function(x, y) merge(x, y, by = c("measurement_version", "optimizer_config"), all.x = TRUE), list(diag_dt, param_delta, profile_delta, pair_delta))

select_retained <- function(dd) {
  strict <- dd[strict_valid == TRUE]
  if (nrow(strict)) {
    strict <- strict[order(numerical_maximum_absolute_gradient, framework_maximum_absolute_gradient, -logLik)]
    out <- strict[1]
    out[, retained_status := "strict-valid"]
    return(out)
  }
  stable <- dd[
    convergence_code == 0 &
      pdHess == TRUE &
      model_matrix_full_rank == TRUE &
      is.finite(logLik) &
      framework_maximum_absolute_gradient < 0.002 &
      abs(delta_logLik) < 1e-6 &
      maximum_absolute_coefficient_difference < 1e-4 &
      maximum_absolute_profile_contrast_difference < 1e-5 &
      maximum_absolute_pairwise_difference < 1e-5
  ]
  if (nrow(stable)) {
    stable <- stable[order(numerical_maximum_absolute_gradient, framework_maximum_absolute_gradient, -logLik)]
    out <- stable[1]
    out[, retained_status := "numerically stable but not strict-valid"]
    return(out)
  }
  out <- dd[order(convergence_code, -pdHess, numerical_maximum_absolute_gradient)][1]
  out[, retained_status := "not strict-valid and not numerically stable"]
  out
}

retained <- diag_dt[, select_retained(.SD), by = threshold_tag]

fwrite(baseline_diag, file.path(TABLE_DIR, "baseline_10km_fit_diagnostics.csv"))
fwrite(baseline_profile, file.path(TABLE_DIR, "baseline_10km_profile_contrasts.csv"))
fwrite(baseline_pair, file.path(TABLE_DIR, "baseline_10km_pairwise_differences.csv"))
fwrite(baseline_check_diag, file.path(TABLE_DIR, "baseline_10km_reproduction_check.csv"))
fwrite(diag_dt, file.path(TABLE_DIR, "fire_10km_optimizer_diagnostics.csv"))
fwrite(param_dt, file.path(TABLE_DIR, "fire_10km_optimizer_parameter_comparison.csv"))
fwrite(profile_dt, file.path(TABLE_DIR, "fire_10km_optimizer_profile_contrasts.csv"))
fwrite(pair_dt, file.path(TABLE_DIR, "fire_10km_optimizer_pairwise_differences.csv"))
fwrite(retained, file.path(TABLE_DIR, "fire_10km_optimizer_retained_fits.csv"))

writeLines(capture.output(sessionInfo()), file.path(PROV_DIR, "sessionInfo.txt"))
message("Fire 10 km optimizer refinement complete. Outputs: ", OUT_DIR)
