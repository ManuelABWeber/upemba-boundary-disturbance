suppressPackageStartupMessages({
  library(data.table)
})

fr_extract <- function(r, cells) {
  x <- terra::extract(r, cells)
  if (ncol(x) == 2L) x[[2L]] else x[[1L]]
}

fr_timeline <- function(spec = FINAL_SPEC) {
  x <- fread(CH1_GOVERNANCE_PROFILE_PATH)
  x <- melt(x, id.vars = "year", variable.name = "SESU_col",
            value.name = "profile_code")
  x[, SESU_ID := as.integer(sub("^SESU([0-9]+)_regime$", "\\1", SESU_col))]
  x[, governance_profile := unname(CH1_PROFILE_CODE_MAP[profile_code])]
  x[, .(SESU_ID, year = as.integer(year), profile_code, governance_profile)]
}

fr_episode_table <- function(timeline) {
  x <- unique(copy(timeline)[order(SESU_ID, year)])
  x[, new_episode := is.na(shift(governance_profile)) |
      governance_profile != shift(governance_profile) |
      year != shift(year, fill = first(year) - 1L) + 1L, by = SESU_ID]
  x[, episode_index := cumsum(new_episode), by = SESU_ID]
  x[, episode_id := paste0("SESU", SESU_ID, "_", start <- min(year), "_",
                           max(year)), by = .(SESU_ID, episode_index)]
  x[, .(SESU_ID, year, governance_profile, episode_index, episode_id)]
}

fr_load_spatial <- function(spec = FINAL_SPEC) {
  stopifnot(requireNamespace("terra", quietly = TRUE))
  cov_path <- file.path(CH1_RUN_DIR, "SESU_covariates_500m.tif")
  sesu_path <- file.path(CH1_RUN_DIR, "SESU_ID_500m.tif")
  if (!file.exists(cov_path) || !file.exists(sesu_path)) {
    stop("Prepared 500 m rasters are unavailable.", call. = FALSE)
  }
  cov <- terra::rast(cov_path)
  sesu <- terra::rast(sesu_path)
  sv <- terra::values(sesu)[, 1]
  dv <- terra::values(cov[["dist_parc_national_signed_m"]])[, 1] / 1000
  cells <- which(is.finite(sv) & sv %in% CH1_INCLUDED_SESUS & is.finite(dv))
  geom <- data.table(
    cell = cells, SESU_ID = as.integer(sv[cells]),
    signed_distance_km = dv[cells]
  )
  # The authoritative implementation codes signed distance < 0 as inside.
  geom[, side := fifelse(signed_distance_km < 0, "inside", "outside")]
  list(cov = cov, sesu = sesu, geom = geom, cov_path = cov_path,
       sesu_path = sesu_path)
}

fr_manifest <- function() {
  x <- fread(file.path(CH1_PROJECT_ROOT, "config",
                       "disturbance_threshold_manifest.csv"))
  x[, abs_path := file.path(CH1_DATA_ROOT, file_path)]
  x
}

fr_design_cells <- function(spatial, corridor_km) {
  x <- copy(spatial$geom)
  if (is.finite(corridor_km)) x <- x[abs(signed_distance_km) <= corridor_km]
  x
}

fr_event_year_values <- function(outcome, tag, cells, spatial, manifest) {
  if (tag == "tau025") {
    band <- if (outcome == "tree_cover_loss") "year_deforest_masked" else "year_agri"
    v <- as.integer(fr_extract(spatial$cov[[band]], cells))
  } else {
    p <- manifest[outcome == ..outcome & threshold_tag == tag &
                    file_type == "event_year", abs_path][1]
    if (!length(p) || !file.exists(p)) stop("Missing event-year raster: ", p)
    v <- as.integer(fr_extract(terra::rast(p), cells))
  }
  v[!is.finite(v) | v <= 0] <- NA_integer_
  v
}

fr_surface_event <- function(outcome, tag, geom, spatial, manifest, timeline) {
  ev <- fr_event_year_values(outcome, tag, geom$cell, spatial, manifest)
  z <- vector("list", length(FINAL_SPEC$years))
  for (i in seq_along(FINAL_SPEC$years)) {
    yr <- FINAL_SPEC$years[i]
    keep <- is.na(ev) | yr <= ev
    d <- geom[keep]
    d[, `:=`(year = yr, y_cell = as.integer(!is.na(ev[keep]) & ev[keep] == yr))]
    z[[i]] <- d[, .(n = .N, y = sum(y_cell)), by = .(SESU_ID, year, side)]
  }
  ans <- rbindlist(z)
  ans[, outcome := outcome]
  merge(ans, timeline[, .(SESU_ID, year, governance_profile)],
        by = c("SESU_ID", "year"), all.x = TRUE)
}

fr_surface_fire <- function(tag, geom, spatial, manifest, timeline) {
  z <- vector("list", length(FINAL_SPEC$years))
  if (tag != "tau025") {
    stack_path <- manifest[outcome == "fire" & threshold_tag == tag &
                             file_type == "fire_stack", abs_path][1]
    rs <- terra::rast(stack_path)
  }
  for (i in seq_along(FINAL_SPEC$years)) {
    yr <- FINAL_SPEC$years[i]
    if (tag == "tau025") {
      v <- fr_extract(spatial$cov[[paste0("fireDOY_", yr)]], geom$cell)
      event <- is.finite(v) & v >= FINAL_SPEC$fire_doy[1] &
        v <= FINAL_SPEC$fire_doy[2]
    } else if (yr <= 2020L) {
      band <- paste0(yr, "_fire_season_", yr)
      v <- fr_extract(rs[[band]], geom$cell)
      event <- is.finite(v) & v == 1
    } else {
      p <- manifest[outcome == "fire" & threshold_tag == tag &
                      file_type == "fire_annual_binary" & year_start == yr,
                    abs_path][1]
      v <- fr_extract(terra::rast(p), geom$cell)
      event <- is.finite(v) & v == 1
    }
    d <- copy(geom)
    d[, `:=`(year = yr, y_cell = as.integer(event))]
    z[[i]] <- d[, .(n = .N, y = sum(y_cell)), by = .(SESU_ID, year, side)]
  }
  ans <- rbindlist(z)
  ans[, outcome := "fire"]
  merge(ans, timeline[, .(SESU_ID, year, governance_profile)],
        by = c("SESU_ID", "year"), all.x = TRUE)
}

fr_build_surface <- function(outcome, tag, corridor_km, spatial, manifest,
                             timeline) {
  geom <- fr_design_cells(spatial, corridor_km)
  ans <- if (outcome == "fire") {
    fr_surface_fire(tag, geom, spatial, manifest, timeline)
  } else {
    fr_surface_event(outcome, tag, geom, spatial, manifest, timeline)
  }
  ans[, `:=`(
    threshold_tag = tag,
    threshold = FINAL_SPEC$thresholds[[tag]],
    corridor_km = corridor_km,
    domain = ifelse(is.finite(corridor_km), paste0(corridor_km, "km"),
                    "full")
  )]
  ans[]
}

fr_assign_profiles <- function(surface, timeline, lag = 0L,
                               exclude_after_transition = 0L) {
  x <- copy(surface)
  tl <- copy(timeline)
  setorder(tl, SESU_ID, year)
  tl[, profile_year := year]
  tl[, outcome_year := year + lag]
  tl[, transition := !is.na(shift(governance_profile)) &
       governance_profile != shift(governance_profile), by = SESU_ID]
  tl[, years_since_transition := {
    idx <- which(transition)
    vapply(seq_len(.N), function(i) {
      prior <- idx[idx <= i]
      if (!length(prior)) Inf else i - max(prior)
    }, numeric(1))
  }, by = SESU_ID]
  x[, governance_profile := NULL]
  x <- merge(x, tl[, .(SESU_ID, year = outcome_year, profile_year,
                       governance_profile, transition, years_since_transition)],
             by = c("SESU_ID", "year"), all.x = TRUE)
  x <- x[!is.na(governance_profile)]
  if (exclude_after_transition > 0L) {
    x <- x[years_since_transition >= exclude_after_transition]
  }
  x[]
}

fr_haldane_anscombe <- function(surface) {
  w <- dcast(surface,
             outcome + SESU_ID + year + governance_profile ~ side,
             value.var = c("y", "n"))
  needed <- c("y_inside", "n_inside", "y_outside", "n_outside")
  if (!all(needed %in% names(w))) return(data.table())
  w[, zero_cell_flag := y_inside == 0 | y_outside == 0 |
      (n_inside - y_inside) == 0 | (n_outside - y_outside) == 0]
  w[, `:=`(
    yi = y_inside + 0.5, ni = n_inside + 1,
    yo = y_outside + 0.5, no = n_outside + 1
  )]
  w[, `:=`(
    inside_outside_log_odds_contrast =
      log(yi / (ni - yi)) - log(yo / (no - yo)),
    approximate_sampling_variance =
      1 / yi + 1 / (ni - yi) + 1 / yo + 1 / (no - yo)
  )]
  w[, inverse_variance_weight := 1 / approximate_sampling_variance]
  w[]
}

fr_hc3 <- function(mod) {
  X <- model.matrix(mod)
  e <- residuals(mod)
  h <- hatvalues(mod)
  w <- weights(mod)
  if (is.null(w)) w <- rep(1, length(e))
  Xw <- X * sqrt(w)
  meat <- crossprod(Xw, Xw * (e / pmax(1 - h, 1e-8))^2)
  bread <- solve(crossprod(Xw))
  bread %*% meat %*% bread
}

fr_profile_vectors <- function(mod, levels) {
  nd <- CJ(governance_profile = levels,
           SESU_ID = levels(model.frame(mod)$SESU_ID))
  nd[, governance_profile := factor(governance_profile, levels = levels)]
  nd[, SESU_ID := factor(SESU_ID, levels = levels(model.frame(mod)$SESU_ID))]
  X <- model.matrix(delete.response(terms(mod)), nd)
  setNames(lapply(levels, function(p) colMeans(
    X[as.character(nd$governance_profile) == p, , drop = FALSE])), levels)
}

fr_fit_sparse <- function(surface, weighted = TRUE, run_id = NA_character_) {
  w <- fr_haldane_anscombe(surface)
  base_diag <- data.table(run_id = run_id, outcome = unique(surface$outcome),
                          model = if (weighted) "inverse_variance_weighted_lm_hc3" else "unweighted_lm_hc3")
  if (nrow(w) < 6L || uniqueN(w$governance_profile) < 3L) {
    return(list(profile = data.table(), pair = data.table(), contrasts = w,
                diagnostics = base_diag[, `:=`(fit_status = "insufficient_support",
                                                warning_messages = "")]))
  }
  w[, `:=`(governance_profile = factor(governance_profile,
                                        levels = FINAL_SPEC$profile_levels),
            SESU_ID = factor(SESU_ID))]
  warns <- character()
  mod <- withCallingHandlers(
    if (weighted) lm(FINAL_SPEC$sparse_formula, data = w,
                     weights = inverse_variance_weight) else
      lm(FINAL_SPEC$sparse_formula, data = w),
    warning = function(z) { warns <<- c(warns, conditionMessage(z));
      invokeRestart("muffleWarning") })
  V <- tryCatch(fr_hc3(mod), error = function(e) NULL)
  if (is.null(V) || any(!is.finite(V))) {
    return(list(profile = data.table(), pair = data.table(), contrasts = w,
                diagnostics = base_diag[, `:=`(fit_status = "invalid_fit",
                  warning_messages = paste(c(warns, "HC3 covariance unavailable"),
                                           collapse = " | "))]))
  }
  vec <- fr_profile_vectors(mod, FINAL_SPEC$profile_levels)
  stat <- function(L) {
    est <- sum(L * coef(mod)); se <- sqrt(drop(t(L) %*% V %*% L))
    data.table(estimate = est, standard_error = se,
               conf_low = est - qnorm(.975) * se,
               conf_high = est + qnorm(.975) * se,
               odds_ratio = exp(est))
  }
  profile <- rbindlist(lapply(names(vec), function(p)
    cbind(data.table(run_id = run_id, outcome = unique(surface$outcome),
                     governance_profile = p), stat(vec[[p]]))))
  comps <- combn(FINAL_SPEC$profile_levels, 2, simplify = FALSE)
  pair <- rbindlist(lapply(comps, function(p)
    cbind(data.table(run_id = run_id, outcome = unique(surface$outcome),
                     profile_comparison = paste(p[1], "minus", p[2])),
          stat(vec[[p[1]]] - vec[[p[2]]]))))
  list(profile = profile, pair = pair, contrasts = w,
       diagnostics = base_diag[, `:=`(
         fit_status = "valid",
         warning_messages = paste(unique(warns), collapse = " | "),
         n_observations = nobs(mod), rank = mod$rank,
         zero_corrected = sum(w$zero_cell_flag))])
}

fr_fire_L <- function(beta_names, profile) {
  L <- setNames(rep(0, length(beta_names)), beta_names)
  side_name <- intersect(c("sideinside", "sideinterior_facing"), beta_names)
  if (length(side_name)) L[side_name[1]] <- 1
  if (profile == "Militia dominant") L["inside_profile_militia"] <- 1
  if (profile == "Park dominant") L["inside_profile_park"] <- 1
  L
}

fr_fit_fire <- function(surface, run_id = NA_character_) {
  if (!requireNamespace("glmmTMB", quietly = TRUE)) stop("glmmTMB unavailable")
  d <- copy(surface)
  d[, `:=`(
    side = factor(side, levels = c("outside", "inside")),
    governance_profile = factor(governance_profile,
                                levels = FINAL_SPEC$profile_levels),
    inside_profile_militia = as.integer(side == "inside" &
      governance_profile == "Militia dominant"),
    inside_profile_park = as.integer(side == "inside" &
      governance_profile == "Park dominant"),
    sesu_year = interaction(SESU_ID, year, drop = TRUE)
  )]
  warns <- character()
  fit <- withCallingHandlers(tryCatch(
    glmmTMB::glmmTMB(FINAL_SPEC$fire_formula,
      family = glmmTMB::betabinomial(link = "logit"), data = d,
      control = glmmTMB::glmmTMBControl(
        optimizer = optim, optArgs = list(method = "BFGS"),
        optCtrl = list(maxit = 20000, reltol = 1e-12))),
    error = function(e) structure(list(error = conditionMessage(e)),
                                  class = "fit_error")),
    warning = function(w) { warns <<- c(warns, conditionMessage(w));
      invokeRestart("muffleWarning") })
  diag <- data.table(run_id = run_id, outcome = "fire",
                     model = "beta_binomial_logit")
  if (inherits(fit, "fit_error")) {
    return(list(profile = data.table(), pair = data.table(),
                diagnostics = diag[, `:=`(fit_status = "invalid_fit",
                  warning_messages = paste(c(warns, fit$error), collapse = " | "))]))
  }
  b <- glmmTMB::fixef(fit)$cond
  V <- as.matrix(vcov(fit)$cond)
  X <- model.matrix(FINAL_SPEC$fire_formula, d)
  grad <- tryCatch(max(abs(fit$obj$gr(fit$fit$par))), error = function(e) NA_real_)
  se_all <- tryCatch(summary(fit)$coefficients$cond[, "Std. Error"],
                     error = function(e) NA_real_)
  strict <- isTRUE(fit$fit$convergence == 0) &&
    isTRUE(fit$sdr$pdHess) && qr(X)$rank == ncol(X) &&
    is.finite(grad) && grad < FINAL_SPEC$strict_gradient_tolerance &&
    all(is.finite(b)) && all(is.finite(se_all)) &&
    !any(se_all > FINAL_SPEC$extreme_standard_error)
  stat <- function(L) {
    est <- sum(L * b); se <- sqrt(drop(t(L) %*% V %*% L))
    data.table(estimate = est, standard_error = se,
               conf_low = if (strict) est - qnorm(.975) * se else NA_real_,
               conf_high = if (strict) est + qnorm(.975) * se else NA_real_,
               odds_ratio = exp(est))
  }
  profile <- rbindlist(lapply(FINAL_SPEC$profile_levels, function(p)
    cbind(data.table(run_id = run_id, outcome = "fire",
                     governance_profile = p),
          stat(fr_fire_L(names(b), p)))))
  comps <- combn(FINAL_SPEC$profile_levels, 2, simplify = FALSE)
  pair <- rbindlist(lapply(comps, function(p)
    cbind(data.table(run_id = run_id, outcome = "fire",
                     profile_comparison = paste(p[1], "minus", p[2])),
          stat(fr_fire_L(names(b), p[1]) - fr_fire_L(names(b), p[2])))))
  list(profile = profile, pair = pair,
       diagnostics = diag[, `:=`(
         fit_status = ifelse(strict, "strict_valid",
                             "finite_not_strict_valid"),
         warning_messages = paste(unique(warns), collapse = " | "),
         convergence_code = fit$fit$convergence,
         pdHess = fit$sdr$pdHess, maximum_absolute_gradient = grad,
         model_matrix_rank = qr(X)$rank, model_matrix_columns = ncol(X))])
}

fr_support <- function(surface, run_id) {
  data.table(
    run_id = run_id, outcome = unique(surface$outcome),
    eligible_cells = unique(surface[, sum(n), by = year]$V1)[1],
    cell_years = sum(surface$n), events = sum(surface$y),
    group_years = uniqueN(surface[, .(SESU_ID, year)]),
    historical_episodes = nrow(unique(fr_episode_table(
      surface[, .(SESU_ID, year, governance_profile)]),
      by = "episode_id"))
  )
}

