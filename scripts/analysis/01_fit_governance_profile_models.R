# ===========================================================
# AUTHORITATIVE CHAPTER 1 MODEL SCRIPT
# ===========================================================
# This is the authoritative Chapter 1 model script.
# It fits categorical, temporally delimited governance profiles.
# Intended profiles: Park dominant, Militia dominant, Neither actor dominant.
# Ordinal Park and Mai-Mai score models are deprecated.
# SESU x year profile assignments come from the historical governance dataset.
# Generated outputs must not overwrite legacy or deprecated model outputs.
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
shift_profiles <- setdiff(profile_levels, CH1_REFERENCE_PROFILE)

stop_missing <- function(path) {
  if (!file.exists(path)) stop("Missing required file or directory: ", path, call. = FALSE)
}
ensure_dir <- function(path) dir.create(path, recursive = TRUE, showWarnings = FALSE)
safe_tag <- function(x) gsub("[^A-Za-z0-9_.-]+", "_", x)

dist_key <- function(x) {
  nm <- names(CH1_DISTURBANCE_NAMES)[match(x, CH1_DISTURBANCE_NAMES)]
  ifelse(is.na(nm), as.character(x), nm)
}

episode_table <- function(dt, profile_col = "governance_profile") {
  d <- copy(dt)
  setorderv(d, c("SESU_ID", "year"))
  d[, prev_profile := shift(get(profile_col)), by = SESU_ID]
  d[, new_episode := is.na(prev_profile) | get(profile_col) != prev_profile | year != shift(year, fill = first(year) - 1L) + 1L, by = SESU_ID]
  d[, episode_id := cumsum(new_episode), by = SESU_ID]
  out <- d[, .(
    start_year = min(year),
    end_year = max(year),
    n_years = .N
  ), by = .(SESU_ID, governance_profile = get(profile_col), episode_id)]
  out[]
}

contrast_stats <- function(beta, V, L, alpha = CH1_ALPHA) {
  est <- sum(L * beta)
  se <- as.numeric(sqrt(t(L) %*% V %*% L))
  z <- est / se
  p <- 2 * pnorm(abs(z), lower.tail = FALSE)
  lo <- est - qnorm(1 - alpha / 2) * se
  hi <- est + qnorm(1 - alpha / 2) * se
  list(estimate = est, std_error = se, z = z, p = p, conf_low = lo, conf_high = hi)
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

fit_with_warnings <- function(formula, dat) {
  warns <- character()
  fit <- withCallingHandlers(
    tryCatch(
      glmmTMB(
        formula = formula,
        family = betabinomial(link = "logit"),
        data = dat,
        control = glmmTMBControl(optCtrl = list(iter.max = 1e4, eval.max = 1e4))
      ),
      error = function(e) structure(list(error = conditionMessage(e)), class = "fit_error")
    ),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = warns)
}

bootstrap_year_resampling <- function(formula, dat, profiles, B, seed, min_unique_years, max_tries) {
  set.seed(seed)
  yrs <- sort(unique(dat$year))
  K <- length(yrs)
  rows <- vector("list", B)
  diag <- data.table(
    replicate = seq_len(B),
    model_fit_success = FALSE,
    contrast_success = FALSE,
    failure_reason = NA_character_
  )

  for (b in seq_len(B)) {
    sampled <- NULL
    for (i in seq_len(max_tries)) {
      candidate <- sample(yrs, size = K, replace = TRUE)
      if (length(unique(candidate)) >= min_unique_years) {
        sampled <- candidate
        break
      }
    }
    if (is.null(sampled)) {
      diag[b, failure_reason := "could_not_sample_min_unique_years"]
      next
    }
    db <- rbindlist(lapply(sampled, function(yr_sample) dat[year == yr_sample]), use.names = TRUE, fill = TRUE)
    fw <- fit_with_warnings(formula, db)
    if (inherits(fw$fit, "fit_error")) {
      diag[b, failure_reason := fw$fit$error]
      next
    }
    beta <- tryCatch(fixef(fw$fit)$cond, error = function(e) NULL)
    V <- tryCatch(as.matrix(vcov(fw$fit)$cond), error = function(e) NULL)
    if (is.null(beta) || is.null(V)) {
      diag[b, `:=`(model_fit_success = TRUE, failure_reason = "missing_coefficients_or_vcov")]
      next
    }
    diag[b, model_fit_success := TRUE]
    vals <- lapply(profiles, function(pr) {
      L <- make_profile_L(names(beta), pr)
      if (!any(L != 0)) return(NULL)
      data.table(replicate = b, governance_profile = pr, estimate = sum(L * beta))
    })
    vals <- rbindlist(vals, use.names = TRUE, fill = TRUE)
    if (nrow(vals) == length(profiles) && all(is.finite(vals$estimate))) {
      diag[b, contrast_success := TRUE]
      rows[[b]] <- vals
    } else {
      diag[b, failure_reason := "contrast_calculation_failed"]
    }
  }
  list(draws = rbindlist(rows, use.names = TRUE, fill = TRUE), diagnostics = diag)
}

stop_missing(CH1_RUN_DIR)
stop_missing(CH1_GOVERNANCE_PROFILE_PATH)
stop_missing(file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"))

invisible(lapply(c(CH1_OUTPUT_DIR, CH1_TABLES_DIR, CH1_FIGURES_DIR, CH1_MODELS_DIR, CH1_PROVENANCE_DIR), ensure_dir))

# Governance profile validation.
gov_wide <- fread(CH1_GOVERNANCE_PROFILE_PATH)
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
  source_governance_file = normalizePath(CH1_GOVERNANCE_PROFILE_PATH, winslash = "/")
)]
gov_long[, governance_profile := unname(CH1_PROFILE_CODE_MAP[original_profile_code])]

grid <- CJ(SESU_ID = CH1_INCLUDED_SESUS, year = CH1_STUDY_YEARS)
diag_dt <- merge(grid, gov_long, by = c("SESU_ID", "year"), all.x = TRUE, allow.cartesian = TRUE)
diag_dt[, duplicate_flag := duplicated(paste(SESU_ID, year)) | duplicated(paste(SESU_ID, year), fromLast = TRUE)]
diag_dt[, missing_flag := is.na(original_profile_code)]
diag_dt[, unexpected_code_flag := !missing_flag & !(original_profile_code %in% names(CH1_PROFILE_CODE_MAP))]
diag_dt[, included_in_analysis := SESU_ID %in% CH1_INCLUDED_SESUS & year %in% CH1_STUDY_YEARS]
setorderv(diag_dt, c("SESU_ID", "year"))
diag_dt[, prev_profile := shift(governance_profile), by = SESU_ID]
diag_dt[, next_profile := shift(governance_profile, type = "lead"), by = SESU_ID]
diag_dt[, isolated_one_year_change_flag := !is.na(prev_profile) & !is.na(next_profile) & governance_profile != prev_profile & prev_profile == next_profile, by = SESU_ID]
diag_dt[, `:=`(prev_profile = NULL, next_profile = NULL, SESU_col = NULL)]

if (any(diag_dt$missing_flag)) stop("Governance profile validation failed: missing SESU-year records.", call. = FALSE)
if (any(diag_dt$duplicate_flag)) stop("Governance profile validation failed: duplicate SESU-year records.", call. = FALSE)
if (any(diag_dt$unexpected_code_flag)) stop("Governance profile validation failed: unknown profile codes.", call. = FALSE)
if (!all(profile_levels %in% diag_dt$governance_profile)) stop("Governance profile validation failed: not all canonical labels are represented.", call. = FALSE)

timeline <- diag_dt[, .(SESU_ID, year, original_profile_code, governance_profile, source_governance_file)]
fwrite(diag_dt[, .(SESU = SESU_ID, year, original_profile_code, canonical_profile = governance_profile, duplicate_flag, missing_flag, unexpected_code_flag, isolated_one_year_change_flag, included_in_analysis, source_governance_file)], file.path(CH1_TABLES_DIR, "governance_profile_diagnostics.csv"))
fwrite(timeline, file.path(CH1_TABLES_DIR, "governance_profile_timeline.csv"))

# Read and prepare model data.
surf_all <- fread(file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"))
rows_before <- nrow(surf_all)
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
rows_after_basic <- nrow(surf)

invalid_yn <- surf[!(is.finite(y) & is.finite(n) & n > 0 & y >= 0 & y <= n), .N]
surf <- surf[is.finite(y) & is.finite(n) & n > 0 & y >= 0 & y <= n]

dat_all <- surf[, .(n = sum(as.integer(n), na.rm = TRUE), y = sum(as.integer(y), na.rm = TRUE)), by = .(SESU_ID, disturbance, dist_short, pa_label = pa_label_full, side, year)]
rows_before_gov_merge <- nrow(dat_all)
dat_all <- merge(dat_all, timeline[, .(SESU_ID, year, original_profile_code, governance_profile)], by = c("SESU_ID", "year"), all.x = TRUE)
rows_missing_profile <- dat_all[is.na(governance_profile), .N]
dat_all <- dat_all[!is.na(governance_profile)]
rows_after_gov_merge <- nrow(dat_all)

attrition <- data.table(
  rows_raw_rs_surfaces = rows_before,
  rows_after_basic_filter = rows_after_basic,
  rows_before_governance_merge = rows_before_gov_merge,
  rows_after_governance_merge = rows_after_gov_merge,
  rows_removed_for_missing_profile = rows_missing_profile,
  rows_removed_for_invalid_y_or_n = invalid_yn,
  retained_sesu_years = uniqueN(dat_all[, .(SESU_ID, year)]),
  retained_inside_observations = dat_all[side == "inside", .N],
  retained_outside_observations = dat_all[side == "outside", .N],
  retained_governance_episodes = nrow(episode_table(unique(dat_all[, .(SESU_ID, year, governance_profile)])))
)
fwrite(attrition, file.path(CH1_TABLES_DIR, "model_sample_attrition.csv"))

# Support diagnostics.
ep <- episode_table(unique(timeline[, .(SESU_ID, year, governance_profile)]))
fwrite(ep, file.path(CH1_TABLES_DIR, "profile_episode_support.csv"))

support_rows <- dat_all[, .(
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
    paste0(
      "SESU",
      CH1_INCLUDED_SESUS,
      "=",
      vapply(CH1_INCLUDED_SESUS, function(s) uniqueN(paste(SESU_ID, year)[SESU_ID == s]), integer(1))
    ),
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
  largest_episode_id = paste0("SESU", SESU_ID[which.max(n_years)], ":", start_year[which.max(n_years)], "-", end_year[which.max(n_years)]),
  profile_occurs_one_sesu = uniqueN(SESU_ID) == 1,
  profile_occurs_one_contiguous_period = .N == 1
), by = governance_profile]
support_rows <- merge(support_rows, ep_support, by = "governance_profile", all.x = TRUE)
support_rows[, represented_in_both_sesus := n_sesus == length(CH1_INCLUDED_SESUS)]
support_rows[, largest_episode_share := largest_episode_length / n_sesu_years]
support_rows[, one_episode_dominates_support := largest_episode_share > CH1_ONE_EPISODE_DOMINANCE_THRESHOLD]
support_rows[, one_episode_dominance_threshold := CH1_ONE_EPISODE_DOMINANCE_THRESHOLD]
fwrite(support_rows, file.path(CH1_TABLES_DIR, "profile_model_support.csv"))

# Fit models and calculate contrasts.
primary_formula <- as.formula("cbind(y, n - y) ~ 0 + sesu_year + side + inside_profile_militia + inside_profile_park")
model_formula_rows <- list()
fit_rows <- list()
coef_rows <- list()
contrast_rows <- list()
pairwise_rows <- list()
bootstrap_contrast_rows <- list()
bootstrap_diag_rows <- list()
validation_rows <- list()

for (dist in names(CH1_DISTURBANCE_NAMES)) {
  dat <- copy(dat_all[dist_short == dist])
  if (nrow(dat) == 0) next
  dat[, `:=`(
    SESU_ID = factor(SESU_ID),
    side = factor(side, levels = c("outside", "inside")),
    governance_profile = factor(governance_profile, levels = profile_levels),
    inside_profile_militia = as.integer(side == "inside" & governance_profile == "Militia dominant"),
    inside_profile_park = as.integer(side == "inside" & governance_profile == "Park dominant"),
    sesu_year = interaction(SESU_ID, year, drop = TRUE)
  )]
  model_id <- paste0("PRIMARY_BB_GOVERNANCE_PROFILES|pa=National Park|dist=", dist)
  X <- model.matrix(primary_formula, dat)
  rank_x <- qr(X)$rank
  full_rank <- rank_x == ncol(X)
  fw <- fit_with_warnings(primary_formula, dat)
  if (inherits(fw$fit, "fit_error")) {
    validation_rows[[dist]] <- data.table(disturbance = dist, model_id = model_id, model_fit_success = FALSE, fit_error = fw$fit$error)
    next
  }
  m <- fw$fit
  model_path <- file.path(CH1_MODELS_DIR, paste0("PRIMARY_betaBinomial_governance_profiles_", safe_tag(dist), ".rds"))
  saveRDS(m, model_path)
  summ <- summary(m)$coefficients$cond
  beta <- fixef(m)$cond
  V <- as.matrix(vcov(m)$cond)
  beta_names <- names(beta)
  hessian_warning <- !isTRUE(sdr <- tryCatch(m$sdr$pdHess, error = function(e) NA))
  extreme_se <- any(summ[, "Std. Error"] > 10, na.rm = TRUE)

  fit_rows[[dist]] <- data.table(
    model_id = model_id,
    disturbance = dist,
    formula = paste(deparse(primary_formula), collapse = " "),
    reference_profile = CH1_REFERENCE_PROFILE,
    reference_side = "outside",
    n_obs = nrow(dat),
    n_sesu_year = uniqueN(dat$sesu_year),
    n_years = uniqueN(dat$year),
    n_sesus = uniqueN(dat$SESU_ID),
    model_matrix_rank = rank_x,
    model_matrix_columns = ncol(X),
    model_matrix_full_rank = full_rank,
    convergence_code = m$fit$convergence,
    warnings = paste(unique(fw$warnings), collapse = " | "),
    hessian_warning = hessian_warning,
    extreme_standard_error = extreme_se,
    AIC = AIC(m),
    BIC = BIC(m),
    logLik = as.numeric(logLik(m))
  )

  cr <- as.data.table(summ, keep.rownames = "term")
  setnames(cr, c("term", "estimate", "std_error", "z", "p"))
  cr[, `:=`(
    disturbance = dist,
    model_id = model_id,
    coefficient_type = fifelse(term == "sideinside", "reference_profile_inside_outside_contrast", fifelse(grepl("^inside_profile_", term), "profile_shift_relative_to_reference", "sesu_year_fixed_effect")),
    lower_95_ci = estimate - zcrit * std_error,
    upper_95_ci = estimate + zcrit * std_error,
    reference_profile = CH1_REFERENCE_PROFILE
  )]
  coef_rows[[dist]] <- cr[coefficient_type != "sesu_year_fixed_effect"]

  for (pr in profile_levels) {
    L <- make_profile_L(beta_names, pr)
    cs <- contrast_stats(beta, V, L)
    sup <- support_rows[disturbance == dist & governance_profile == pr]
    contrast_rows[[paste(dist, pr)]] <- data.table(
      disturbance = dist,
      governance_profile = pr,
      log_odds_contrast = cs$estimate,
      standard_error = cs$std_error,
      z = cs$z,
      p = cs$p,
      lower_95_ci = cs$conf_low,
      upper_95_ci = cs$conf_high,
      odds_ratio = exp(cs$estimate),
      lower_odds_ratio_ci = exp(cs$conf_low),
      upper_odds_ratio_ci = exp(cs$conf_high),
      number_contributing_sesu_years = sup$n_sesu_years,
      number_contributing_calendar_years = sup$n_calendar_years,
      number_contributing_episodes = sup$n_episodes,
      model_identifier = model_id,
      reference_profile = CH1_REFERENCE_PROFILE
    )
  }

  comparisons <- c(
    "Park dominant minus Neither actor dominant",
    "Militia dominant minus Neither actor dominant",
    "Park dominant minus Militia dominant"
  )
  for (cmp in comparisons) {
    L <- make_pairwise_L(beta_names, cmp)
    cs <- contrast_stats(beta, V, L)
    pairwise_rows[[paste(dist, cmp)]] <- data.table(
      disturbance = dist,
      profile_comparison = cmp,
      estimate = cs$estimate,
      standard_error = cs$std_error,
      z = cs$z,
      p = cs$p,
      lower_95_ci = cs$conf_low,
      upper_95_ci = cs$conf_high,
      p_adjustment = "unadjusted"
    )
  }

  if (isTRUE(CH1_BOOTSTRAP_ENABLED)) {
    boot <- bootstrap_year_resampling(
      primary_formula,
      dat,
      profile_levels,
      B = CH1_BOOTSTRAP_REPLICATES,
      seed = CH1_BOOTSTRAP_SEED,
      min_unique_years = CH1_BOOTSTRAP_MIN_UNIQUE_YEARS,
      max_tries = CH1_BOOTSTRAP_MAX_RESAMPLE_TRIES
    )
    bd <- boot$diagnostics[, .(
      requested_bootstrap_replicates = CH1_BOOTSTRAP_REPLICATES,
      successful_model_fits = sum(model_fit_success),
      failed_model_fits = sum(!model_fit_success),
      successful_contrast_replicates = sum(contrast_success),
      failed_contrast_calculations = sum(model_fit_success & !contrast_success),
      bootstrap_failure_rate = mean(!contrast_success)
    )]
    bd[, `:=`(disturbance = dist, model_identifier = model_id, bootstrap_type = "year-resampling bootstrap")]
    bootstrap_diag_rows[[dist]] <- bd
    if (nrow(boot$draws)) {
      bc <- boot$draws[, .(
        requested_bootstrap_replicates = CH1_BOOTSTRAP_REPLICATES,
        successful_model_fits = bd$successful_model_fits,
        successful_contrast_estimates = .N,
        failed_model_fits = bd$failed_model_fits,
        failed_contrast_calculations = bd$failed_contrast_calculations,
        percentile_lower_95_ci = as.numeric(quantile(estimate, CH1_ALPHA / 2, na.rm = TRUE, names = FALSE)),
        percentile_upper_95_ci = as.numeric(quantile(estimate, 1 - CH1_ALPHA / 2, na.rm = TRUE, names = FALSE)),
        bootstrap_failure_rate = bd$bootstrap_failure_rate
      ), by = governance_profile]
      bc[, `:=`(disturbance = dist, model_identifier = model_id, bootstrap_type = "year-resampling bootstrap")]
      bootstrap_contrast_rows[[dist]] <- bc
    }
  }
}

fit_dt <- rbindlist(fit_rows, use.names = TRUE, fill = TRUE)
coef_dt <- rbindlist(coef_rows, use.names = TRUE, fill = TRUE)
contrast_dt <- rbindlist(contrast_rows, use.names = TRUE, fill = TRUE)
pairwise_dt <- rbindlist(pairwise_rows, use.names = TRUE, fill = TRUE)
boot_contrast_dt <- rbindlist(bootstrap_contrast_rows, use.names = TRUE, fill = TRUE)
boot_diag_dt <- rbindlist(bootstrap_diag_rows, use.names = TRUE, fill = TRUE)

fwrite(fit_dt, file.path(CH1_TABLES_DIR, "model_fit_diagnostics.csv"))
fwrite(coef_dt, file.path(CH1_TABLES_DIR, "profile_shift_coefficients.csv"))
fwrite(contrast_dt, file.path(CH1_TABLES_DIR, "profile_specific_inside_outside_contrasts.csv"))
fwrite(pairwise_dt, file.path(CH1_TABLES_DIR, "profile_pairwise_contrast_differences.csv"))
fwrite(boot_contrast_dt, file.path(CH1_TABLES_DIR, "profile_specific_inside_outside_contrasts_bootstrap.csv"))
fwrite(boot_diag_dt, file.path(CH1_TABLES_DIR, "bootstrap_diagnostics.csv"))

prov_paths <- c(
  config_path,
  file.path(CH1_RUN_DIR, "rs_surfaces_long.csv"),
  CH1_GOVERNANCE_PROFILE_PATH,
  script_path
)
prov <- data.table(
  item = c("config", "rs_surfaces", "governance_profile_input", "script"),
  path = prov_paths,
  md5 = as.character(tools::md5sum(prov_paths))
)
fwrite(prov, file.path(CH1_PROVENANCE_DIR, "input_provenance.csv"))
writeLines(capture.output(sessionInfo()), file.path(CH1_PROVENANCE_DIR, "sessionInfo.txt"))

message("Governance-profile model workflow complete. Outputs: ", CH1_OUTPUT_DIR)
