# ===========================================================
# CHAPTER 1 GOVERNANCE-PROFILE ROBUSTNESS WORKFLOW
# ===========================================================
# Phase 2 diagnostic workflow for the authoritative categorical
# governance-profile model. This script does not alter canonical
# governance assignments, disturbance thresholds, spatial sampling, or
# Phase 1 outputs.
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
config_path <- normalizePath(file.path(script_dir, "..", "..", "config", "analysis_config.R"), winslash = "/", mustWork = TRUE)
source(config_path)

zcrit <- qnorm(1 - CH1_ALPHA / 2)
profile_levels <- unname(CH1_PROFILE_CODE_MAP)
profile_levels <- c(CH1_REFERENCE_PROFILE, setdiff(profile_levels, CH1_REFERENCE_PROFILE))
pairwise_comparisons <- c(
  "Park dominant minus Neither actor dominant",
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")
heterogeneity_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + inside_sesu1 + inside_sesu3 + militia_sesu1 + militia_sesu3 + park_sesu1 + park_sesu3")

ensure_dir <- function(path) dir.create(path, recursive = TRUE, showWarnings = FALSE)
stop_missing <- function(path) if (!file.exists(path)) stop("Missing required file or directory: ", path, call. = FALSE)
safe_tag <- function(x) gsub("[^A-Za-z0-9_.-]+", "_", x)
dist_key <- function(x) {
  nm <- names(CH1_DISTURBANCE_NAMES)[match(x, CH1_DISTURBANCE_NAMES)]
  ifelse(is.na(nm), as.character(x), nm)
}

invisible(lapply(c(
  CH1_ROBUSTNESS_OUTPUT_DIR, CH1_ROBUSTNESS_TABLES_DIR, CH1_ROBUSTNESS_FIGURES_DIR,
  CH1_ROBUSTNESS_MODELS_DIR, CH1_ROBUSTNESS_PROVENANCE_DIR, CH1_ROBUSTNESS_LOGS_DIR
), ensure_dir))

load_governance_timeline <- function(path = CH1_GOVERNANCE_PROFILE_PATH) {
  gov_wide <- fread(path)
  required_gov_cols <- c("year", paste0("SESU", CH1_INCLUDED_SESUS, "_regime"))
  if (!all(required_gov_cols %in% names(gov_wide))) {
    stop("Governance profile file missing required columns: ", paste(setdiff(required_gov_cols, names(gov_wide)), collapse = ", "), call. = FALSE)
  }
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
    source_governance_file = normalizePath(path, winslash = "/")
  )]
  gov_long[, governance_profile := unname(CH1_PROFILE_CODE_MAP[original_profile_code])]
  gov_long[, .(SESU_ID, year, original_profile_code, governance_profile, source_governance_file)]
}

episode_table <- function(dt, profile_col = "governance_profile") {
  d <- unique(copy(dt)[, .(SESU_ID, year, governance_profile = get(profile_col))])
  setorderv(d, c("SESU_ID", "year"))
  d[, prev_profile := shift(governance_profile), by = SESU_ID]
  d[, new_episode := is.na(prev_profile) | governance_profile != prev_profile | year != shift(year, fill = first(year) - 1L) + 1L, by = SESU_ID]
  d[, episode_index := cumsum(new_episode), by = SESU_ID]
  out <- d[, .(
    start_year = min(year),
    end_year = max(year),
    n_years = .N
  ), by = .(SESU_ID, governance_profile, episode_index)]
  out[, episode_id := paste0("SESU", SESU_ID, "_", governance_profile, "_", start_year, "_", end_year)]
  out[]
}

build_analysis_data <- function(timeline) {
  stop_missing(CH1_RUN_DIR)
  stop_missing(file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"))
  surf_all <- fread(file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"))
  if (!("pa_label_rep" %in% names(surf_all))) surf_all[, pa_label_rep := "true"]
  surf_all[, pa_label_full := ifelse(pa_label == "National Park placebo (random side)", paste(pa_label, pa_label_rep, sep = " / "), pa_label)]
  surf_all[, dist_short := dist_key(disturbance)]
  surf <- surf_all[
    dist_short %in% names(CH1_DISTURBANCE_NAMES) &
      pa_label_full %in% CH1_KEEP_PA_LABELS &
      side %in% c("inside", "outside") &
      year %in% CH1_STUDY_YEARS &
      SESU_ID %in% CH1_INCLUDED_SESUS
  ]
  surf <- surf[is.finite(y) & is.finite(n) & n > 0 & y >= 0 & y <= n]
  dat <- surf[, .(n = sum(as.integer(n), na.rm = TRUE), y = sum(as.integer(y), na.rm = TRUE)),
    by = .(SESU_ID, disturbance, dist_short, pa_label = pa_label_full, side, year)]
  dat <- merge(dat, timeline[, .(SESU_ID, year, original_profile_code, governance_profile)], by = c("SESU_ID", "year"), all.x = TRUE)
  dat[!is.na(governance_profile)]
}

add_primary_terms <- function(dat) {
  d <- copy(dat)
  d[, `:=`(
    SESU_ID = factor(SESU_ID),
    side = factor(side, levels = c("outside", "inside")),
    governance_profile = factor(governance_profile, levels = profile_levels),
    inside_profile_militia = as.integer(side == "inside" & governance_profile == "Militia dominant"),
    inside_profile_park = as.integer(side == "inside" & governance_profile == "Park dominant"),
    sesu_year = interaction(SESU_ID, year, drop = TRUE)
  )]
  d[]
}

add_heterogeneity_terms <- function(dat) {
  d <- add_primary_terms(dat)
  sid <- as.integer(as.character(d$SESU_ID))
  d[, `:=`(
    inside_sesu1 = as.integer(side == "inside" & sid == 1L),
    inside_sesu3 = as.integer(side == "inside" & sid == 3L),
    militia_sesu1 = as.integer(side == "inside" & governance_profile == "Militia dominant" & sid == 1L),
    militia_sesu3 = as.integer(side == "inside" & governance_profile == "Militia dominant" & sid == 3L),
    park_sesu1 = as.integer(side == "inside" & governance_profile == "Park dominant" & sid == 1L),
    park_sesu3 = as.integer(side == "inside" & governance_profile == "Park dominant" & sid == 3L)
  )]
  d[]
}

fit_config <- function(name) {
  if (name == "nlminb_default") {
    return(list(
      optimizer = "nlminb",
      optimizer_controls = "iter.max=10000; eval.max=10000",
      starting_value_strategy = "none",
      control = glmmTMBControl(optCtrl = list(iter.max = 10000, eval.max = 10000))
    ))
  }
  if (name == "nlminb_strict") {
    return(list(
      optimizer = "nlminb",
      optimizer_controls = "iter.max=50000; eval.max=50000; rel.tol=1e-10; x.tol=1e-8",
      starting_value_strategy = "none",
      control = glmmTMBControl(optCtrl = list(iter.max = 50000, eval.max = 50000, rel.tol = 1e-10, x.tol = 1e-8))
    ))
  }
  if (name == "optim_bfgs") {
    return(list(
      optimizer = "optim",
      optimizer_controls = "method=BFGS; maxit=10000",
      starting_value_strategy = "none",
      control = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"), optCtrl = list(maxit = 10000))
    ))
  }
  stop("Unknown optimizer config: ", name, call. = FALSE)
}

fit_model <- function(formula, dat, optimizer_config = "nlminb_default") {
  cfg <- fit_config(optimizer_config)
  warns <- character()
  fit <- withCallingHandlers(
    tryCatch(
      glmmTMB(formula = formula, family = betabinomial(link = "logit"), data = dat, control = cfg$control),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")
    ),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = unique(warns), config = cfg, optimizer_config = optimizer_config)
}

max_abs_gradient <- function(model) {
  val <- tryCatch({
    gr <- model$obj$gr(model$fit$par)
    max(abs(gr), na.rm = TRUE)
  }, error = function(e) NA_real_)
  if (!is.finite(val)) NA_real_ else val
}

dispersion_estimate <- function(model) {
  sig <- tryCatch(sigma(model), error = function(e) NA_real_)
  if (length(sig) != 1L || !is.finite(sig)) NA_real_ else as.numeric(sig)
}

make_profile_L <- function(beta_names, profile) {
  L <- setNames(rep(0, length(beta_names)), beta_names)
  if ("sideinside" %in% beta_names) L["sideinside"] <- 1
  if (profile == "Militia dominant" && "inside_profile_militia" %in% beta_names) L["inside_profile_militia"] <- L["inside_profile_militia"] + 1
  if (profile == "Park dominant" && "inside_profile_park" %in% beta_names) L["inside_profile_park"] <- L["inside_profile_park"] + 1
  L
}

make_pairwise_L <- function(beta_names, comparison) {
  parts <- strsplit(comparison, " minus ", fixed = TRUE)[[1]]
  make_profile_L(beta_names, parts[1]) - make_profile_L(beta_names, parts[2])
}

contrast_stats <- function(beta, V, L) {
  est <- sum(L * beta)
  se <- as.numeric(sqrt(t(L) %*% V %*% L))
  z <- est / se
  p <- 2 * pnorm(abs(z), lower.tail = FALSE)
  lo <- est - zcrit * se
  hi <- est + zcrit * se
  list(estimate = est, standard_error = se, z = z, p = p, lower_95_ci = lo, upper_95_ci = hi)
}

profile_contrasts <- function(model, disturbance, optimizer_config = NA_character_, scenario_id = "canonical", model_id = NA_character_) {
  beta <- tryCatch(fixef(model)$cond, error = function(e) NULL)
  V <- tryCatch(as.matrix(vcov(model)$cond), error = function(e) NULL)
  if (is.null(beta) || is.null(V)) return(data.table())
  rbindlist(lapply(profile_levels, function(pr) {
    cs <- contrast_stats(beta, V, make_profile_L(names(beta), pr))
    data.table(
      disturbance = disturbance,
      scenario_id = scenario_id,
      optimizer_config = optimizer_config,
      governance_profile = pr,
      estimate = cs$estimate,
      standard_error = cs$standard_error,
      z = cs$z,
      p = cs$p,
      lower_95_ci = cs$lower_95_ci,
      upper_95_ci = cs$upper_95_ci,
      odds_ratio = exp(cs$estimate),
      lower_odds_ratio_ci = exp(cs$lower_95_ci),
      upper_odds_ratio_ci = exp(cs$upper_95_ci),
      model_identifier = model_id,
      reference_profile = CH1_REFERENCE_PROFILE
    )
  }), use.names = TRUE, fill = TRUE)
}

pairwise_contrasts <- function(model, disturbance, optimizer_config = NA_character_, scenario_id = "canonical") {
  beta <- tryCatch(fixef(model)$cond, error = function(e) NULL)
  V <- tryCatch(as.matrix(vcov(model)$cond), error = function(e) NULL)
  if (is.null(beta) || is.null(V)) return(data.table())
  rbindlist(lapply(pairwise_comparisons, function(cmp) {
    cs <- contrast_stats(beta, V, make_pairwise_L(names(beta), cmp))
    data.table(
      disturbance = disturbance,
      scenario_id = scenario_id,
      optimizer_config = optimizer_config,
      profile_comparison = cmp,
      estimate = cs$estimate,
      standard_error = cs$standard_error,
      z = cs$z,
      p = cs$p,
      lower_95_ci = cs$lower_95_ci,
      upper_95_ci = cs$upper_95_ci,
      p_adjustment = "unadjusted"
    )
  }), use.names = TRUE, fill = TRUE)
}

fit_diagnostics <- function(fw, dat, formula, disturbance, optimizer_config, scenario_id = "canonical") {
  cfg <- fw$config
  X <- tryCatch(model.matrix(formula, dat), error = function(e) NULL)
  rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
  cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
  if (inherits(fw$fit, "fit_error")) {
    return(data.table(
      disturbance = disturbance, scenario_id = scenario_id, optimizer_config = optimizer_config,
      optimizer = cfg$optimizer, optimizer_controls = cfg$optimizer_controls,
      starting_value_strategy = cfg$starting_value_strategy,
      n_obs = nrow(dat), n_sesu_years = uniqueN(dat[, .(SESU_ID, year)]),
      n_parameters = cols_x, model_matrix_rank = rank_x, model_matrix_columns = cols_x,
      model_matrix_full_rank = identical(rank_x, cols_x), convergence_code = NA_integer_,
      optimizer_message = fw$fit$error, warnings = paste(fw$warnings, collapse = " | "),
      pdHess = NA, maximum_absolute_gradient = NA_real_, dispersion_estimate = NA_real_,
      dispersion_standard_error = NA_real_, fixed_effect_estimates = NA_character_,
      fixed_effect_standard_errors = NA_character_, logLik = NA_real_, AIC = NA_real_, BIC = NA_real_,
      finite_coefficients = FALSE, finite_profile_contrasts = FALSE,
      extreme_standard_error = NA, strict_valid = FALSE, finite_output = FALSE,
      diagnostic_status = "fit_error"
    ))
  }
  m <- fw$fit
  summ <- tryCatch(summary(m)$coefficients$cond, error = function(e) NULL)
  beta <- tryCatch(fixef(m)$cond, error = function(e) numeric())
  se <- if (is.null(summ)) rep(NA_real_, length(beta)) else summ[, "Std. Error"]
  pc <- profile_contrasts(m, disturbance, optimizer_config, scenario_id)
  grad <- max_abs_gradient(m)
  finite_coef <- length(beta) > 0 && all(is.finite(beta))
  finite_contrast <- nrow(pc) == length(profile_levels) && all(is.finite(pc$estimate)) && all(is.finite(pc$standard_error))
  extreme_se <- any(!is.na(se) & abs(se) > CH1_EXTREME_SE_THRESHOLD)
  pd <- isTRUE(tryCatch(m$sdr$pdHess, error = function(e) FALSE))
  conv <- tryCatch(m$fit$convergence, error = function(e) NA_integer_)
  grad_ok <- is.na(grad) || grad < CH1_MAX_ABS_GRADIENT_TOL
  strict <- identical(conv, 0L) && pd && finite_coef && finite_contrast && identical(rank_x, cols_x) && !extreme_se && !is.na(grad) && grad_ok
  status <- if (strict) "strict_valid" else if (finite_coef && finite_contrast) {
    if (is.na(grad)) "diagnostically_incomplete" else "finite_output"
  } else {
    "failed_output"
  }
  data.table(
    disturbance = disturbance,
    scenario_id = scenario_id,
    optimizer_config = optimizer_config,
    optimizer = cfg$optimizer,
    optimizer_controls = cfg$optimizer_controls,
    starting_value_strategy = cfg$starting_value_strategy,
    n_obs = nrow(dat),
    n_sesu_years = uniqueN(dat[, .(SESU_ID, year)]),
    n_parameters = cols_x,
    model_matrix_rank = rank_x,
    model_matrix_columns = cols_x,
    model_matrix_full_rank = identical(rank_x, cols_x),
    convergence_code = conv,
    optimizer_message = tryCatch(as.character(m$fit$message), error = function(e) NA_character_),
    warnings = paste(fw$warnings, collapse = " | "),
    pdHess = pd,
    maximum_absolute_gradient = grad,
    dispersion_estimate = dispersion_estimate(m),
    dispersion_standard_error = NA_real_,
    fixed_effect_estimates = paste(paste0(names(beta), "=", signif(beta, 8)), collapse = "; "),
    fixed_effect_standard_errors = paste(paste0(names(se), "=", signif(se, 8)), collapse = "; "),
    logLik = tryCatch(as.numeric(logLik(m)), error = function(e) NA_real_),
    AIC = tryCatch(AIC(m), error = function(e) NA_real_),
    BIC = tryCatch(BIC(m), error = function(e) NA_real_),
    finite_coefficients = finite_coef,
    finite_profile_contrasts = finite_contrast,
    extreme_standard_error = extreme_se,
    strict_valid = strict,
    finite_output = finite_coef && finite_contrast,
    diagnostic_status = status
  )
}

write_diagnose_log <- function(model, disturbance, optimizer_config, scenario_id = "canonical") {
  out <- tryCatch(capture.output(glmmTMB::diagnose(model)), error = function(e) paste("diagnose unavailable or failed:", conditionMessage(e)))
  writeLines(out, file.path(CH1_ROBUSTNESS_LOGS_DIR, paste0("diagnose_", safe_tag(disturbance), "_", safe_tag(scenario_id), "_", safe_tag(optimizer_config), ".txt")))
}

support_tables <- function(dat, timeline) {
  ep <- episode_table(timeline)
  support <- dat[, .(
    n_sesus = uniqueN(SESU_ID),
    n_sesu_years = uniqueN(paste(SESU_ID, year)),
    n_calendar_years = uniqueN(year),
    n_inside_rows = sum(side == "inside"),
    n_outside_rows = sum(side == "outside"),
    total_at_risk = sum(n),
    total_disturbed = sum(y),
    sesu1_unique_sesu_years = uniqueN(paste(SESU_ID, year)[SESU_ID == 1]),
    sesu3_unique_sesu_years = uniqueN(paste(SESU_ID, year)[SESU_ID == 3]),
    sesu_distribution = paste(
      paste0("SESU", CH1_INCLUDED_SESUS, "=", vapply(CH1_INCLUDED_SESUS, function(s) uniqueN(paste(SESU_ID, year)[SESU_ID == s]), integer(1))),
      collapse = "; "
    ),
    first_contributing_year = min(year),
    last_contributing_year = max(year)
  ), by = .(disturbance = dist_short, governance_profile)]
  ep_support <- ep[, .(
    n_episodes = .N,
    episode_ranges = paste(paste0("SESU", SESU_ID, ":", start_year, "-", end_year), collapse = "; "),
    episode_lengths = paste(paste0("SESU", SESU_ID, ":", start_year, "-", end_year, "=", n_years), collapse = "; "),
    largest_episode_length = max(n_years),
    largest_episode_id = episode_id[which.max(n_years)],
    profile_occurs_one_sesu = uniqueN(SESU_ID) == 1,
    profile_occurs_one_contiguous_period = .N == 1
  ), by = governance_profile]
  support <- merge(support, ep_support, by = "governance_profile", all.x = TRUE)
  support[, represented_in_both_sesus := n_sesus == length(CH1_INCLUDED_SESUS)]
  support[, largest_episode_share := largest_episode_length / n_sesu_years]
  support[, one_episode_dominates_support := largest_episode_share > CH1_ONE_EPISODE_DOMINANCE_THRESHOLD]
  support[, one_episode_dominance_threshold := CH1_ONE_EPISODE_DOMINANCE_THRESHOLD]
  list(support = support, episodes = ep)
}

stop_missing(CH1_GOVERNANCE_PROFILE_PATH)
timeline <- load_governance_timeline()
dat_all <- build_analysis_data(timeline)
st <- support_tables(dat_all, timeline)
fwrite(st$support, file.path(CH1_ROBUSTNESS_TABLES_DIR, "profile_model_support_corrected.csv"))
fwrite(st$episodes, file.path(CH1_ROBUSTNESS_TABLES_DIR, "profile_episode_support_corrected.csv"))

phase1_contrasts <- fread(file.path(CH1_TABLES_DIR, "profile_specific_inside_outside_contrasts.csv"))
phase1_pairwise <- fread(file.path(CH1_TABLES_DIR, "profile_pairwise_contrast_differences.csv"))

# Optimizer diagnostics and Phase 1 reproduction.
optimizer_configs <- c("nlminb_default", "nlminb_strict", "optim_bfgs")
opt_diag <- list()
opt_contrasts <- list()
opt_pairwise <- list()
coef_comp <- list()
canonical_models <- list()

for (dist in names(CH1_DISTURBANCE_NAMES)) {
  d <- add_primary_terms(dat_all[dist_short == dist])
  for (oc in optimizer_configs) {
    fw <- fit_model(primary_formula, d, oc)
    dg <- fit_diagnostics(fw, d, primary_formula, dist, oc)
    opt_diag[[paste(dist, oc)]] <- dg
    if (!inherits(fw$fit, "fit_error")) {
      write_diagnose_log(fw$fit, dist, oc)
      pc <- profile_contrasts(fw$fit, dist, oc, "canonical", paste0("robustness|", dist, "|", oc))
      pw <- pairwise_contrasts(fw$fit, dist, oc, "canonical")
      opt_contrasts[[paste(dist, oc)]] <- pc
      opt_pairwise[[paste(dist, oc)]] <- pw
      beta <- fixef(fw$fit)$cond
      se <- summary(fw$fit)$coefficients$cond[, "Std. Error"]
      coef_comp[[paste(dist, oc)]] <- data.table(disturbance = dist, optimizer_config = oc, term = names(beta), estimate = as.numeric(beta), standard_error = as.numeric(se))
      if (oc == "nlminb_default") canonical_models[[dist]] <- fw$fit
    }
  }
}

opt_diag_dt <- rbindlist(opt_diag, use.names = TRUE, fill = TRUE)
opt_contrast_dt <- rbindlist(opt_contrasts, use.names = TRUE, fill = TRUE)
opt_pairwise_dt <- rbindlist(opt_pairwise, use.names = TRUE, fill = TRUE)
coef_comp_dt <- rbindlist(coef_comp, use.names = TRUE, fill = TRUE)

fwrite(opt_diag_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "optimizer_fit_diagnostics.csv"))
fwrite(coef_comp_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "optimizer_coefficient_comparison.csv"))
fwrite(opt_contrast_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "optimizer_profile_contrast_comparison.csv"))

best_optimizer <- opt_diag_dt[order(
  disturbance,
  -as.integer(strict_valid),
  -as.integer(pdHess),
  convergence_code,
  fifelse(is.na(maximum_absolute_gradient), Inf, maximum_absolute_gradient)
), .SD[1], by = disturbance]
fwrite(best_optimizer, file.path(CH1_ROBUSTNESS_TABLES_DIR, "best_diagnostic_candidate_optimizer.csv"))

stability <- merge(
  opt_contrast_dt,
  phase1_contrasts[, .(disturbance, governance_profile, phase1_estimate = log_odds_contrast)],
  by = c("disturbance", "governance_profile"),
  all.x = TRUE
)
strict_ranges <- stability[strict <- opt_diag_dt[stability, on = .(disturbance, optimizer_config), x.strict_valid]]
stability_summary <- stability[, .(
  estimate_min = min(estimate, na.rm = TRUE),
  estimate_max = max(estimate, na.rm = TRUE),
  estimate_range_all_finite = diff(range(estimate, na.rm = TRUE)),
  maximum_absolute_deviation_from_phase1 = max(abs(estimate - phase1_estimate), na.rm = TRUE),
  sign_consistency = uniqueN(sign(estimate)) == 1,
  any_ci_crosses_zero = any(lower_95_ci <= 0 & upper_95_ci >= 0),
  substantive_interpretation_changes = max(abs(estimate - phase1_estimate), na.rm = TRUE) > CH1_MATERIAL_CONTRAST_DELTA
), by = .(disturbance, governance_profile)]
fwrite(stability_summary, file.path(CH1_ROBUSTNESS_TABLES_DIR, "optimizer_stability_summary.csv"))

# Enhanced bootstrap.
bootstrap_one <- function(dist, dat, B = CH1_BOOTSTRAP_REPLICATES) {
  set.seed(CH1_BOOTSTRAP_SEED)
  yrs <- sort(unique(dat$year))
  K <- length(yrs)
  diag_rows <- vector("list", B)
  draw_rows <- vector("list", B)
  for (b in seq_len(B)) {
    sampled <- sample(yrs, size = K, replace = TRUE)
    db <- rbindlist(lapply(sampled, function(yr) dat[year == yr]), use.names = TRUE, fill = TRUE)
    prof_support <- db[, uniqueN(paste(SESU_ID, year)), by = governance_profile]
    missing_profiles <- setdiff(profile_levels, as.character(prof_support$governance_profile))
    dprep <- add_primary_terms(db)
    X <- tryCatch(model.matrix(primary_formula, dprep), error = function(e) NULL)
    rank_x <- if (is.null(X)) NA_integer_ else qr(X)$rank
    cols_x <- if (is.null(X)) NA_integer_ else ncol(X)
    base <- data.table(
      disturbance = dist,
      replicate = b,
      sampled_calendar_years = paste(sampled, collapse = ";"),
      n_unique_sampled_years = uniqueN(sampled),
      n_represented_sesus = uniqueN(db$SESU_ID),
      n_represented_sesu_years = uniqueN(db[, .(SESU_ID, year)]),
      n_observations = nrow(db),
      support_neither = prof_support[governance_profile == "Neither actor dominant", V1],
      support_militia = prof_support[governance_profile == "Militia dominant", V1],
      support_park = prof_support[governance_profile == "Park dominant", V1],
      model_matrix_rank = rank_x,
      model_matrix_columns = cols_x
    )
    if (length(missing_profiles)) {
      diag_rows[[b]] <- cbind(base, data.table(
        convergence_code = NA_integer_, optimizer_message = NA_character_, warnings = NA_character_, pdHess = NA,
        maximum_absolute_gradient = NA_real_, extreme_standard_error = NA, finite_coefficient_flag = FALSE,
        finite_contrast_flag = FALSE, strict_valid_flag = FALSE, failure_reason = paste("missing_profiles", paste(missing_profiles, collapse = ";"), sep = ":")
      ))
      next
    }
    fw <- fit_model(primary_formula, dprep, "nlminb_default")
    dg <- fit_diagnostics(fw, dprep, primary_formula, dist, "nlminb_default", paste0("bootstrap_", b))
    diag_rows[[b]] <- cbind(base, data.table(
      convergence_code = dg$convergence_code, optimizer_message = dg$optimizer_message, warnings = dg$warnings, pdHess = dg$pdHess,
      maximum_absolute_gradient = dg$maximum_absolute_gradient, extreme_standard_error = dg$extreme_standard_error,
      finite_coefficient_flag = dg$finite_coefficients, finite_contrast_flag = dg$finite_profile_contrasts,
      strict_valid_flag = dg$strict_valid,
      failure_reason = fifelse(dg$strict_valid, NA_character_, dg$diagnostic_status)
    ))
    if (!inherits(fw$fit, "fit_error")) {
      pc <- profile_contrasts(fw$fit, dist, "nlminb_default", paste0("bootstrap_", b))
      if (nrow(pc)) {
        pc[, `:=`(replicate = b, strict_valid_flag = dg$strict_valid, finite_contrast_flag = dg$finite_profile_contrasts)]
        draw_rows[[b]] <- pc
      }
    }
  }
  list(diagnostics = rbindlist(diag_rows, use.names = TRUE, fill = TRUE), draws = rbindlist(draw_rows, use.names = TRUE, fill = TRUE))
}

boot_diag <- list()
boot_draws <- list()
for (dist in names(CH1_DISTURBANCE_NAMES)) {
  b <- bootstrap_one(dist, dat_all[dist_short == dist])
  boot_diag[[dist]] <- b$diagnostics
  boot_draws[[dist]] <- b$draws
}
boot_diag_dt <- rbindlist(boot_diag, use.names = TRUE, fill = TRUE)
boot_draws_dt <- rbindlist(boot_draws, use.names = TRUE, fill = TRUE)
fwrite(boot_diag_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "bootstrap_replicate_diagnostics.csv"))

summ_boot <- function(draws, strict_only = FALSE) {
  d <- if (strict_only) draws[strict_valid_flag == TRUE] else draws[finite_contrast_flag == TRUE]
  d[, .(
    requested_replicates = CH1_BOOTSTRAP_REPLICATES,
    attempted_replicates = CH1_BOOTSTRAP_REPLICATES,
    interval_replicates = .N,
    percentile_lower_95_ci = as.numeric(quantile(estimate, CH1_ALPHA / 2, na.rm = TRUE, names = FALSE)),
    percentile_upper_95_ci = as.numeric(quantile(estimate, 1 - CH1_ALPHA / 2, na.rm = TRUE, names = FALSE))
  ), by = .(disturbance, governance_profile)]
}
boot_finite <- summ_boot(boot_draws_dt, FALSE)
boot_strict <- summ_boot(boot_draws_dt, TRUE)
strict_frac <- boot_diag_dt[, .(
  finite_output_replicates = sum(finite_contrast_flag, na.rm = TRUE),
  strict_valid_replicates = sum(strict_valid_flag, na.rm = TRUE),
  rejected_replicates = sum(!strict_valid_flag, na.rm = TRUE),
  strict_valid_fraction = mean(strict_valid_flag, na.rm = TRUE),
  bootstrap_inference_unstable = mean(strict_valid_flag, na.rm = TRUE) < 0.80
), by = disturbance]
boot_finite <- merge(boot_finite, strict_frac, by = "disturbance", all.x = TRUE)
boot_strict <- merge(boot_strict, strict_frac, by = "disturbance", all.x = TRUE)
fwrite(boot_finite, file.path(CH1_ROBUSTNESS_TABLES_DIR, "bootstrap_profile_contrasts_finite.csv"))
fwrite(boot_strict, file.path(CH1_ROBUSTNESS_TABLES_DIR, "bootstrap_profile_contrasts_strict.csv"))
fwrite(boot_diag_dt[, .N, by = .(disturbance, failure_reason)][order(disturbance, failure_reason)], file.path(CH1_ROBUSTNESS_TABLES_DIR, "bootstrap_failure_reasons.csv"))

# SESU-year transparency contrasts and two-stage models.
wide <- dcast(dat_all, dist_short + SESU_ID + year + governance_profile ~ side, value.var = c("y", "n"))
wide[, `:=`(
  inside_probability = y_inside / n_inside,
  outside_probability = y_outside / n_outside,
  probability_difference = y_inside / n_inside - y_outside / n_outside,
  zero_cell_flag = y_inside == 0 | y_outside == 0 | (n_inside - y_inside) == 0 | (n_outside - y_outside) == 0
)]
wide[, `:=`(
  yi = y_inside + 0.5,
  ni = n_inside + 1,
  yo = y_outside + 0.5,
  no = n_outside + 1
)]
wide[, `:=`(
  corrected_inside_log_odds = log(yi / (ni - yi)),
  corrected_outside_log_odds = log(yo / (no - yo)),
  inside_outside_log_odds_contrast = log(yi / (ni - yi)) - log(yo / (no - yo)),
  approximate_sampling_variance = 1 / yi + 1 / (ni - yi) + 1 / yo + 1 / (no - yo)
)]
wide[, approximate_inverse_variance_weight := 1 / approximate_sampling_variance]
sesu_year_contrasts <- wide[, .(
  disturbance = dist_short, SESU_ID, year, governance_profile,
  inside_disturbed_count = y_inside, inside_at_risk_count = n_inside,
  outside_disturbed_count = y_outside, outside_at_risk_count = n_outside,
  inside_probability, outside_probability, probability_difference,
  corrected_inside_log_odds, corrected_outside_log_odds,
  inside_outside_log_odds_contrast, approximate_sampling_variance,
  approximate_inverse_variance_weight, zero_cell_flag,
  correction = "Haldane-Anscombe 0.5 added to all four cells before approximate log-odds calculations"
)]
fwrite(sesu_year_contrasts, file.path(CH1_ROBUSTNESS_TABLES_DIR, "sesu_year_inside_outside_contrasts.csv"))

hc3_vcov <- function(mod) {
  X <- model.matrix(mod)
  e <- residuals(mod)
  h <- hatvalues(mod)
  w <- weights(mod)
  if (is.null(w)) w <- rep(1, length(e))
  Xw <- X * sqrt(w)
  meat <- t(Xw) %*% diag((e * sqrt(w) / pmax(1 - h, 1e-8))^2, nrow = length(e)) %*% Xw
  bread <- solve(t(Xw) %*% Xw)
  bread %*% meat %*% bread
}

two_stage_rows <- list()
two_stage_pair_rows <- list()
two_stage_diag_rows <- list()
for (dist in names(CH1_DISTURBANCE_NAMES)) {
  td <- copy(sesu_year_contrasts[disturbance == dist])
  td[, `:=`(governance_profile = factor(governance_profile, levels = profile_levels), SESU_ID = factor(SESU_ID))]
  for (weighted in c(TRUE, FALSE)) {
    model_type <- if (weighted) "inverse_variance_weighted_lm_hc3" else "unweighted_lm_hc3"
    mod <- if (weighted) {
      lm(inside_outside_log_odds_contrast ~ governance_profile + SESU_ID, data = td, weights = approximate_inverse_variance_weight)
    } else {
      lm(inside_outside_log_odds_contrast ~ governance_profile + SESU_ID, data = td)
    }
    V <- tryCatch(hc3_vcov(mod), error = function(e) vcov(mod))
    nd <- CJ(governance_profile = profile_levels, SESU_ID = levels(td$SESU_ID))
    nd[, governance_profile := factor(governance_profile, levels = profile_levels)]
    nd[, SESU_ID := factor(SESU_ID, levels = levels(td$SESU_ID))]
    Xn <- model.matrix(delete.response(terms(mod)), nd)
    mu <- as.numeric(Xn %*% coef(mod))
    nd[, estimate_component := mu]
    for (pr in profile_levels) {
      rows <- which(as.character(nd$governance_profile) == pr)
      L <- colMeans(Xn[rows, , drop = FALSE])
      est <- sum(L * coef(mod))
      se <- sqrt(as.numeric(t(L) %*% V %*% L))
      two_stage_rows[[paste(dist, model_type, pr)]] <- data.table(
        disturbance = dist, model_type = model_type, governance_profile = pr,
        estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se,
        covariance = "HC3; not calendar-year clustered"
      )
    }
    for (cmp in pairwise_comparisons) {
      parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
      L1 <- colMeans(Xn[as.character(nd$governance_profile) == parts[1], , drop = FALSE])
      L2 <- colMeans(Xn[as.character(nd$governance_profile) == parts[2], , drop = FALSE])
      L <- L1 - L2
      est <- sum(L * coef(mod))
      se <- sqrt(as.numeric(t(L) %*% V %*% L))
      two_stage_pair_rows[[paste(dist, model_type, cmp)]] <- data.table(
        disturbance = dist, model_type = model_type, profile_comparison = cmp,
        estimate = est, standard_error = se, lower_95_ci = est - zcrit * se, upper_95_ci = est + zcrit * se,
        covariance = "HC3; not calendar-year clustered"
      )
    }
    two_stage_diag_rows[[paste(dist, model_type)]] <- data.table(
      disturbance = dist, model_type = model_type, n_obs = nrow(td), residual_df = df.residual(mod),
      r_squared = summary(mod)$r.squared, covariance = "HC3; CR2 calendar-year clustering not implemented in this environment"
    )
  }
}
two_stage_est <- rbindlist(two_stage_rows, use.names = TRUE, fill = TRUE)
two_stage_pair <- rbindlist(two_stage_pair_rows, use.names = TRUE, fill = TRUE)
two_stage_diag <- rbindlist(two_stage_diag_rows, use.names = TRUE, fill = TRUE)
fwrite(two_stage_est, file.path(CH1_ROBUSTNESS_TABLES_DIR, "two_stage_profile_estimates.csv"))
fwrite(two_stage_pair, file.path(CH1_ROBUSTNESS_TABLES_DIR, "two_stage_pairwise_differences.csv"))
fwrite(two_stage_diag, file.path(CH1_ROBUSTNESS_TABLES_DIR, "two_stage_model_diagnostics.csv"))

# Transition table and scenarios.
ep <- st$episodes
transitions <- list()
for (s in CH1_INCLUDED_SESUS) {
  es <- ep[SESU_ID == s][order(start_year)]
  if (nrow(es) > 1) {
    for (i in seq_len(nrow(es) - 1L)) {
      transitions[[length(transitions) + 1L]] <- data.table(
        transition_id = paste0("T", length(transitions) + 1L),
        SESU_ID = s,
        last_year_previous_profile = es$end_year[i],
        first_year_new_profile = es$start_year[i + 1L],
        previous_profile = es$governance_profile[i],
        new_profile = es$governance_profile[i + 1L],
        previous_episode_length = es$n_years[i],
        new_episode_length = es$n_years[i + 1L]
      )
    }
  }
}
transitions <- rbindlist(transitions, use.names = TRUE, fill = TRUE)
fwrite(transitions, file.path(CH1_ROBUSTNESS_TABLES_DIR, "governance_transitions.csv"))
review_sheet <- copy(transitions)
review_sheet[, `:=`(
  evidence_reviewed = "", transition_confidence = "", plausible_earlier_transition = "",
  plausible_later_transition = "", researcher_decision = "", notes = ""
)]
fwrite(review_sheet, file.path(CH1_ROBUSTNESS_TABLES_DIR, "governance_transition_review_sheet.csv"))

scenario_timelines <- function(timeline, transitions) {
  rows <- list()
  scen <- list()
  for (i in seq_len(nrow(transitions))) {
    tr <- transitions[i]
    for (typ in c("earlier", "later", "omit_first_new_year")) {
      sid <- paste(tr$transition_id, typ, sep = "_")
      tl <- copy(timeline)
      reason <- NA_character_
      if (typ == "earlier") {
        target_year <- tr$last_year_previous_profile
        tl[SESU_ID == tr$SESU_ID & year == target_year, governance_profile := tr$new_profile]
      } else if (typ == "later") {
        target_year <- tr$first_year_new_profile
        tl[SESU_ID == tr$SESU_ID & year == target_year, governance_profile := tr$previous_profile]
      } else {
        target_year <- tr$first_year_new_profile
      }
      ept <- episode_table(tl)
      if (any(table(tl$governance_profile) == 0) || !all(profile_levels %in% tl$governance_profile)) reason <- "required_profile_absent"
      rows[[length(rows) + 1L]] <- data.table(
        scenario_id = sid, transition_id = tr$transition_id, SESU_ID = tr$SESU_ID,
        scenario_type = typ, target_year = target_year, skipped = !is.na(reason), skip_reason = reason
      )
      if (is.na(reason)) scen[[sid]] <- list(timeline = tl, omit = if (typ == "omit_first_new_year") data.table(SESU_ID = tr$SESU_ID, year = target_year) else NULL)
    }
  }
  list(index = rbindlist(rows, use.names = TRUE, fill = TRUE), scenarios = scen)
}

sc <- scenario_timelines(timeline, transitions)
scenario_index <- sc$index
transition_diag <- list()
transition_contrasts <- list()
transition_pairwise <- list()
for (sid in names(sc$scenarios)) {
  tl <- sc$scenarios[[sid]]$timeline
  dd <- build_analysis_data(tl)
  omit <- sc$scenarios[[sid]]$omit
  if (!is.null(omit)) dd <- dd[!(SESU_ID == omit$SESU_ID & year == omit$year)]
  for (dist in names(CH1_DISTURBANCE_NAMES)) {
    d <- add_primary_terms(dd[dist_short == dist])
    if (!all(profile_levels %in% d$governance_profile)) {
      transition_diag[[paste(sid, dist)]] <- data.table(disturbance = dist, scenario_id = sid, diagnostic_status = "not_estimable_missing_profile")
      next
    }
    X <- model.matrix(primary_formula, d)
    if (qr(X)$rank < ncol(X)) {
      transition_diag[[paste(sid, dist)]] <- data.table(disturbance = dist, scenario_id = sid, diagnostic_status = "not_estimable_rank_deficient")
      next
    }
    oc <- best_optimizer[disturbance == dist, optimizer_config][1]
    fw <- fit_model(primary_formula, d, oc)
    dg <- fit_diagnostics(fw, d, primary_formula, dist, oc, sid)
    transition_diag[[paste(sid, dist)]] <- dg
    if (!inherits(fw$fit, "fit_error")) {
      transition_contrasts[[paste(sid, dist)]] <- profile_contrasts(fw$fit, dist, oc, sid)
      transition_pairwise[[paste(sid, dist)]] <- pairwise_contrasts(fw$fit, dist, oc, sid)
    }
  }
}
transition_diag_dt <- rbindlist(transition_diag, use.names = TRUE, fill = TRUE)
transition_contrast_dt <- rbindlist(transition_contrasts, use.names = TRUE, fill = TRUE)
transition_pairwise_dt <- rbindlist(transition_pairwise, use.names = TRUE, fill = TRUE)
fwrite(scenario_index, file.path(CH1_ROBUSTNESS_TABLES_DIR, "transition_sensitivity_scenarios.csv"))
fwrite(transition_diag_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "transition_sensitivity_fit_diagnostics.csv"))
fwrite(transition_contrast_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "transition_sensitivity_profile_contrasts.csv"))
fwrite(transition_pairwise_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "transition_sensitivity_pairwise_differences.csv"))

# Leave-one-episode-out.
loo_diag <- list()
loo_contrasts <- list()
loo_pairwise <- list()
for (i in seq_len(nrow(ep))) {
  e <- ep[i]
  sid <- paste0("omit_", e$episode_id)
  dd <- dat_all[!(SESU_ID == e$SESU_ID & year >= e$start_year & year <= e$end_year)]
  for (dist in names(CH1_DISTURBANCE_NAMES)) {
    d <- add_primary_terms(dd[dist_short == dist])
    if (!all(profile_levels %in% d$governance_profile)) {
      loo_diag[[paste(sid, dist)]] <- data.table(disturbance = dist, scenario_id = sid, omitted_episode_id = e$episode_id, diagnostic_status = "not_estimable_missing_profile")
      next
    }
    X <- model.matrix(primary_formula, d)
    if (qr(X)$rank < ncol(X)) {
      loo_diag[[paste(sid, dist)]] <- data.table(disturbance = dist, scenario_id = sid, omitted_episode_id = e$episode_id, diagnostic_status = "not_estimable_rank_deficient")
      next
    }
    oc <- best_optimizer[disturbance == dist, optimizer_config][1]
    fw <- fit_model(primary_formula, d, oc)
    dg <- fit_diagnostics(fw, d, primary_formula, dist, oc, sid)
    dg[, omitted_episode_id := e$episode_id]
    loo_diag[[paste(sid, dist)]] <- dg
    if (!inherits(fw$fit, "fit_error")) {
      pc <- profile_contrasts(fw$fit, dist, oc, sid)
      pc[, omitted_episode_id := e$episode_id]
      loo_contrasts[[paste(sid, dist)]] <- pc
      pw <- pairwise_contrasts(fw$fit, dist, oc, sid)
      pw[, omitted_episode_id := e$episode_id]
      loo_pairwise[[paste(sid, dist)]] <- pw
    }
  }
}
loo_diag_dt <- rbindlist(loo_diag, use.names = TRUE, fill = TRUE)
loo_contrast_dt <- rbindlist(loo_contrasts, use.names = TRUE, fill = TRUE)
loo_pairwise_dt <- rbindlist(loo_pairwise, use.names = TRUE, fill = TRUE)
fwrite(loo_diag_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "leave_one_episode_out_fit_diagnostics.csv"))
fwrite(loo_contrast_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "leave_one_episode_out_profile_contrasts.csv"))
fwrite(loo_pairwise_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "leave_one_episode_out_pairwise_differences.csv"))
episode_influence <- merge(loo_contrast_dt, phase1_contrasts[, .(disturbance, governance_profile, canonical_estimate = log_odds_contrast)], by = c("disturbance", "governance_profile"), all.x = TRUE)
episode_influence_summary <- episode_influence[, .(
  minimum_leave_one_episode_out_estimate = min(estimate, na.rm = TRUE),
  maximum_leave_one_episode_out_estimate = max(estimate, na.rm = TRUE),
  maximum_absolute_change_from_canonical = max(abs(estimate - canonical_estimate), na.rm = TRUE),
  sign_stability = uniqueN(sign(estimate)) == 1,
  most_influential_omitted_episode = omitted_episode_id[which.max(abs(estimate - canonical_estimate))],
  one_episode_determines_qualitative_interpretation = uniqueN(sign(c(canonical_estimate[1], estimate))) > 1
), by = .(disturbance, governance_profile)]
fwrite(episode_influence_summary, file.path(CH1_ROBUSTNESS_TABLES_DIR, "episode_influence_summary.csv"))

# SESU heterogeneity.
het_diag <- list()
het_contrasts <- list()
het_between <- list()
for (dist in names(CH1_DISTURBANCE_NAMES)) {
  d <- add_heterogeneity_terms(dat_all[dist_short == dist])
  fw <- fit_model(heterogeneity_formula, d, best_optimizer[disturbance == dist, optimizer_config][1])
  het_diag[[dist]] <- fit_diagnostics(fw, d, heterogeneity_formula, dist, best_optimizer[disturbance == dist, optimizer_config][1], "sesu_heterogeneity")
  if (!inherits(fw$fit, "fit_error")) {
    beta <- fixef(fw$fit)$cond
    V <- as.matrix(vcov(fw$fit)$cond)
    L_profile_sesu <- function(profile, sesu) {
      L <- setNames(rep(0, length(beta)), names(beta))
      L[paste0("inside_sesu", sesu)] <- 1
      if (profile == "Militia dominant") L[paste0("militia_sesu", sesu)] <- L[paste0("militia_sesu", sesu)] + 1
      if (profile == "Park dominant") L[paste0("park_sesu", sesu)] <- L[paste0("park_sesu", sesu)] + 1
      L
    }
    for (s in CH1_INCLUDED_SESUS) {
      for (pr in profile_levels) {
        L <- L_profile_sesu(pr, s)
        cs <- contrast_stats(beta, V, L)
        het_contrasts[[paste(dist, s, pr)]] <- data.table(disturbance = dist, SESU_ID = s, governance_profile = pr, estimate = cs$estimate, standard_error = cs$standard_error, lower_95_ci = cs$lower_95_ci, upper_95_ci = cs$upper_95_ci)
      }
      for (cmp in pairwise_comparisons) {
        parts <- strsplit(cmp, " minus ", fixed = TRUE)[[1]]
        L <- L_profile_sesu(parts[1], s) - L_profile_sesu(parts[2], s)
        cs <- contrast_stats(beta, V, L)
        het_contrasts[[paste(dist, s, cmp)]] <- data.table(disturbance = dist, SESU_ID = s, governance_profile = cmp, estimate = cs$estimate, standard_error = cs$standard_error, lower_95_ci = cs$lower_95_ci, upper_95_ci = cs$upper_95_ci, contrast_type = "within_sesu_pairwise")
      }
    }
    for (pr in profile_levels) {
      L <- L_profile_sesu(pr, 1) - L_profile_sesu(pr, 3)
      cs <- contrast_stats(beta, V, L)
      het_between[[paste(dist, pr)]] <- data.table(disturbance = dist, governance_profile = pr, estimate_sesu1_minus_sesu3 = cs$estimate, standard_error = cs$standard_error, lower_95_ci = cs$lower_95_ci, upper_95_ci = cs$upper_95_ci)
    }
  }
}
het_diag_dt <- rbindlist(het_diag, use.names = TRUE, fill = TRUE)
het_contrast_dt <- rbindlist(het_contrasts, use.names = TRUE, fill = TRUE)
het_between_dt <- rbindlist(het_between, use.names = TRUE, fill = TRUE)
fwrite(het_diag_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "sesu_heterogeneity_fit_diagnostics.csv"))
fwrite(het_contrast_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "sesu_specific_profile_contrasts.csv"))
fwrite(het_between_dt, file.path(CH1_ROBUSTNESS_TABLES_DIR, "sesu_between_landscape_differences.csv"))

# Consolidated summary.
transition_contrast_annotated <- merge(
  transition_contrast_dt,
  transition_diag_dt[, .(disturbance, scenario_id, strict_valid, finite_output)],
  by = c("disturbance", "scenario_id"),
  all.x = TRUE
)
trans_sum <- merge(transition_contrast_annotated, phase1_contrasts[, .(disturbance, governance_profile, canonical_estimate = log_odds_contrast)], by = c("disturbance", "governance_profile"), all.x = TRUE)
trans_sum <- trans_sum[, .(
  transition_scenario_min = min(estimate, na.rm = TRUE),
  transition_scenario_max = max(estimate, na.rm = TRUE),
  transition_sign_consistency = uniqueN(sign(estimate)) == 1,
  transition_strict_valid_scenarios = sum(strict_valid, na.rm = TRUE),
  transition_failed_scenarios = sum(!finite_output, na.rm = TRUE),
  transition_largest_deviation_scenario = scenario_id[which.max(abs(estimate - canonical_estimate))]
), by = .(disturbance, governance_profile)]

summary_dt <- merge(phase1_contrasts[, .(disturbance, governance_profile, canonical_phase1_estimate = log_odds_contrast)], stability_summary, by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, boot_finite[, .(disturbance, governance_profile, finite_bootstrap_lower = percentile_lower_95_ci, finite_bootstrap_upper = percentile_upper_95_ci)], by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, boot_strict[, .(disturbance, governance_profile, strict_bootstrap_lower = percentile_lower_95_ci, strict_bootstrap_upper = percentile_upper_95_ci, strict_valid_fraction)], by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, two_stage_est[model_type == "inverse_variance_weighted_lm_hc3", .(disturbance, governance_profile, two_stage_weighted_estimate = estimate)], by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, two_stage_est[model_type == "unweighted_lm_hc3", .(disturbance, governance_profile, two_stage_unweighted_estimate = estimate)], by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, trans_sum, by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, episode_influence_summary[, .(disturbance, governance_profile, leave_one_episode_min = minimum_leave_one_episode_out_estimate, leave_one_episode_max = maximum_leave_one_episode_out_estimate, most_influential_omitted_episode)], by = c("disturbance", "governance_profile"), all.x = TRUE)
summary_dt <- merge(summary_dt, het_contrast_dt[is.na(contrast_type), .(disturbance, governance_profile, SESU_ID, estimate)], by = c("disturbance", "governance_profile"), all.x = TRUE, allow.cartesian = TRUE)
summary_wide <- dcast(summary_dt, disturbance + governance_profile + canonical_phase1_estimate + estimate_range_all_finite + finite_bootstrap_lower + finite_bootstrap_upper + strict_bootstrap_lower + strict_bootstrap_upper + strict_valid_fraction + two_stage_weighted_estimate + two_stage_unweighted_estimate + transition_scenario_min + transition_scenario_max + leave_one_episode_min + leave_one_episode_max + most_influential_omitted_episode ~ SESU_ID, value.var = "estimate")
setnames(summary_wide, old = c("1", "3"), new = c("SESU1_estimate", "SESU3_estimate"), skip_absent = TRUE)
summary_wide <- merge(
  summary_wide,
  best_optimizer[, .(disturbance, convergence_status = diagnostic_status, best_optimizer_strict_valid = strict_valid)],
  by = "disturbance",
  all.x = TRUE
)
summary_wide[, sign_consistency_across_analyses := uniqueN(sign(c(
  canonical_phase1_estimate, two_stage_weighted_estimate, two_stage_unweighted_estimate,
  transition_scenario_min, transition_scenario_max, leave_one_episode_min, leave_one_episode_max
)), na.rm = TRUE) == 1, by = .(disturbance, governance_profile)]
summary_wide[, inferential_status := fifelse(
  best_optimizer_strict_valid == TRUE & strict_valid_fraction >= 0.80 & sign_consistency_across_analyses == TRUE,
  "stable",
  fifelse(strict_valid_fraction < 0.80 | best_optimizer_strict_valid != TRUE, "beta-binomial unresolved",
    fifelse(!sign_consistency_across_analyses, "directionally stable but uncertainty sensitive", "directionally stable but uncertainty sensitive"))
)]
summary_wide[, inferential_status_definition := "stable=strict primary diagnostics and broadly consistent sensitivity estimates; directionally stable but uncertainty sensitive=sign mostly stable with uncertainty changes; episode dependent=leave-one-episode-out changes sign; transition sensitive=transition scenarios change sign; optimizer sensitive=optimizer range changes interpretation; beta-binomial unresolved=no strict-valid primary beta-binomial fit or strict bootstrap fraction below 0.80; insufficient support=required profile absent"]
fwrite(summary_wide, file.path(CH1_ROBUSTNESS_TABLES_DIR, "governance_profile_robustness_summary.csv"))

# Phase 1 reproduction.
repro <- merge(
  opt_contrast_dt[optimizer_config == "nlminb_default", .(disturbance, governance_profile, reproduced_estimate = estimate)],
  phase1_contrasts[, .(disturbance, governance_profile, phase1_estimate = log_odds_contrast)],
  by = c("disturbance", "governance_profile")
)
repro[, `:=`(absolute_difference = abs(reproduced_estimate - phase1_estimate), reproduced = abs(reproduced_estimate - phase1_estimate) < 1e-8)]
fwrite(repro, file.path(CH1_ROBUSTNESS_TABLES_DIR, "phase1_point_estimate_reproduction.csv"))

prov_paths <- c(config_path, file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"), CH1_GOVERNANCE_PROFILE_PATH, script_path)
prov <- data.table(item = c("config", "rs_surfaces", "governance_profile_input", "script"), path = prov_paths, md5 = as.character(tools::md5sum(prov_paths)))
fwrite(prov, file.path(CH1_ROBUSTNESS_PROVENANCE_DIR, "input_provenance.csv"))
writeLines(capture.output(sessionInfo()), file.path(CH1_ROBUSTNESS_PROVENANCE_DIR, "sessionInfo.txt"))

message("Governance-profile robustness workflow complete. Outputs: ", CH1_ROBUSTNESS_OUTPUT_DIR)
