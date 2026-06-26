# ===========================================================
# ===========================================================
# SCRIPT 3 : REMOTE SENSING DATA PREPARATION
# ===========================================================
# ===========================================================

library(terra)
library(data.table)

# ============================================================
# USER SETTINGS
# ============================================================
root_dir <- Sys.getenv("UPEMBA_DATA_ROOT", unset = getwd())
run_dir <- NULL

fire_season_doy_min <- 100
fire_season_doy_max <- 300

target_sesus <- c(1L, 3L) ### HARD CODE
YEAR_MIN <- 2001L
YEAR_MAX <- 2022L

# ============================================================
# PIXEL SELECTION MODE (for inside/outside comparison)
# ============================================================
PIXEL_SELECTION_MODE <- "all"
# choices: "all", "covmatch", "closest_border"

PIXEL_MATCH_RATIO <- 1.0  # outside pixels kept = ceiling(PIXEL_MATCH_RATIO * n_inside) per SESU×pa_var

# ============================================================
# GOVERNANCE DISTANCE BANDS
# ============================================================
gov_keep <- c(
  "dist_parc_national_signed_m")#, "dist_zone_annexe_signed_m", "dist_domaine_chasse_signed_m")

gov_labels <- list(
  "dist_parc_national_signed_m"   = "National Park",
  #"dist_domaine_chasse_signed_m"  = "Hunting Reserve",
  #"dist_zone_annexe_signed_m"     = "Zone Annexe",
  "fire"                          = "Fire",
  "year_agri"                     = "Agricultural expansion",
  "year_deforest_masked"          = "Deforestation"
)

# ============================================================
# PLACEBO BOUNDARY SETTINGS
# ============================================================
RUN_PLACEBO_BOUNDARY <- TRUE
PLACEBO_SHIFT_KM     <- 10
PLACEBO_PA_VAR       <- "dist_parc_national_placebo_plus10km_signed_m"
N_PLACEBO <- 10L
PLACEBO_SEED_BASE <- 12345

if (RUN_PLACEBO_BOUNDARY) {
  gov_keep <- c(gov_keep, PLACEBO_PA_VAR)
  gov_labels[[PLACEBO_PA_VAR]] <- "National Park placebo (random side)"
}

# ============================================================
# HELPERS
# ============================================================
find_latest_run <- function(root_dir) {
  dd <- list.dirs(root_dir, recursive = FALSE, full.names = TRUE)
  dd <- dd[grepl("run_[0-9]{4}_[0-9]{2}_[0-9]{2}$", basename(dd))]
  if (length(dd) == 0) stop("No run_YYYY_MM_DD directories found under: ", root_dir)
  dates <- as.Date(sub("^run_", "", basename(dd)), format = "%Y_%m_%d")
  dd[which.max(dates)]
}

stop_missing <- function(path) if (!file.exists(path)) stop("Missing: ", path)

label_or_name <- function(x) {
  x <- as.character(x)
  labs <- unlist(gov_labels)
  out <- x
  hit <- x %in% names(labs)
  out[hit] <- unname(labs[out[hit]])
  out
}

write_provenance <- function(out_dir, paths) {
  prov_dir <- file.path(out_dir, "provenance")
  dir.create(prov_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- unique(paths[file.exists(paths)])
  md5 <- unname(tools::md5sum(paths))
  fwrite(data.table(path = paths, md5 = md5), file.path(prov_dir, "input_md5_Script2.csv"))
  writeLines(capture.output(sessionInfo()), file.path(prov_dir, "sessionInfo_Script2.txt"))
}

extract_cells_vec <- function(x, cells) {
  ex <- terra::extract(x, cells)

  if (is.null(ex)) stop("terra::extract() returned NULL.")

  if (is.vector(ex) && !is.list(ex)) {
    return(as.vector(ex))
  }

  if (is.data.frame(ex) || is.matrix(ex)) {
    return(as.vector(ex[, ncol(ex)]))
  }
    as.vector(ex)
}


# ============================================================
# LOCATE RUN DIRECTORY + INPUTS
# ============================================================
if (is.null(run_dir)) run_dir <- find_latest_run(root_dir)
message("Using run_dir: ", run_dir)

cov_path  <- file.path(run_dir, "SESU_covariates_500m.tif")
sesu_path <- file.path(run_dir, "SESU_ID_500m.tif")
stop_missing(cov_path); stop_missing(sesu_path)

out_dir <- run_dir

prov_dir <- file.path(out_dir, "provenance")
dir.create(prov_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- file.path(out_dir, "SESU_manifest.rds")
if (file.exists(manifest_path)) {
  file.copy(manifest_path, file.path(prov_dir, "SESU_manifest.rds"), overwrite = TRUE)
}

# ============================================================
# LOAD RASTERS
# ============================================================
r_cov  <- rast(cov_path)
r_sesu <- rast(sesu_path)

if (!compareGeom(r_cov[[1]], r_sesu, stopOnError = FALSE)) {
  r_sesu <- resample(r_sesu, r_cov[[1]], method = "near")
}

r <- r_cov
names(r) <- make.unique(names(r))

fire_bands <- grep("^fireDOY_", names(r), value = TRUE)
fire_years <- suppressWarnings(as.integer(sub("^fireDOY_([0-9]{4}).*$", "\\1", fire_bands)))

ok <- is.finite(fire_years)
fire_bands <- fire_bands[ok]
fire_years <- fire_years[ok]
ok2 <- fire_years >= YEAR_MIN & fire_years <= YEAR_MAX
fire_bands <- fire_bands[ok2]
fire_years <- fire_years[ok2]
o <- order(fire_years)
fire_bands <- fire_bands[o]
fire_years <- fire_years[o]

message("Fire years found: ", paste(fire_years, collapse = ", "))

if (length(fire_bands) > 0) {
  ok_year <- is.finite(fire_years) & fire_years >= YEAR_MIN & fire_years <= YEAR_MAX
  fire_bands <- fire_bands[ok_year]
  fire_years <- fire_years[ok_year]

  # chronological order
  o <- order(fire_years)
  fire_bands <- fire_bands[o]
  fire_years <- fire_years[o]
}

gov_names <- intersect(gov_keep, names(r))
if (length(gov_names) == 0) stop("None of gov_keep found in cov stack. Check names(r).")

# ============================================================
# COVARIATE BANDS USED FOR MATCHING
# ============================================================

match_bands_exact <- c(
  "elevation_m", "dist_perm_water_m"
)
names(r)
pick_one <- function(pattern, pool) {
  hit <- grep(pattern, pool, ignore.case = TRUE, value = TRUE)
  if (length(hit) == 1) return(hit)
  if (length(hit) == 0) return(NA_character_)
  # ambiguous: multiple candidates -> fail loudly
  stop("Ambiguous match for pattern '", pattern, "': ",
       paste(hit, collapse = ", "),
       "\nSet match_bands_exact explicitly to the correct band name.")
}

all_names <- names(r)

match_bands <- match_bands_exact[match_bands_exact %in% all_names]

exclude_match <- unique(c(
  gov_keep,
  "year_agri",
  "year_deforest_masked",
  grep("^fireDOY_", all_names, value = TRUE)
))
if (any(match_bands %in% exclude_match)) {
  stop("One of match_bands resolves to an excluded layer (governance/disturbance). match_bands = ",
       paste(match_bands, collapse = ", "))
}

message("Matching covariates used (STRICT): ", paste(match_bands, collapse = ", "))

# SESU values and valid pixel index
SESU_v    <- values(r_sesu)[, 1]
valid_idx <- which(!is.na(SESU_v))
n_valid   <- length(valid_idx)
if (n_valid == 0) stop("No non-NA SESU pixels found.")
SESU_valid <- SESU_v[valid_idx]

# governance matrix for valid pixels
gov_mat <- matrix(
  NA_real_,
  nrow = n_valid,
  ncol = length(gov_names),
  dimnames = list(NULL, gov_names)
)
for (i in seq_along(gov_names)) {
  nm <- gov_names[i]
  gov_mat[, i] <- values(r[[nm]])[valid_idx]
}

dist_mat <- gov_mat

# ============================================================
# MATCHING COVARIATE MATRIX FOR VALID PIXELS
# ============================================================
cov_mat <- matrix(
  NA_real_,
  nrow = n_valid,
  ncol = length(match_bands),
  dimnames = list(NULL, match_bands)
)

for (j in seq_along(match_bands)) {
  nm <- match_bands[j]
  cov_mat[, j] <- values(r[[nm]])[valid_idx]
}

cov_complete <- stats::complete.cases(cov_mat)
if (PIXEL_SELECTION_MODE == "covmatch" && !any(cov_complete)) {
  stop("covmatch mode requires complete matching covariates, but all valid pixels have missing values in matching covariates.")
}

has_pa <- apply(dist_mat, 1, function(v) any(is.finite(v)))
inside_any <- apply(dist_mat, 1, function(v) any(is.finite(v) & v < 0))

chosen_col <- rep(NA_integer_, n_valid)

idx_in <- which(has_pa & inside_any)
if (length(idx_in)) {
  chosen_col[idx_in] <- apply(dist_mat[idx_in, , drop = FALSE], 1, function(v) {
    v2 <- v; v2[!is.finite(v2)] <- Inf
    neg <- which(v2 < 0)
    neg[which.min(v2[neg])]
  })
}

idx_out <- which(has_pa & !inside_any)
if (length(idx_out)) {
  chosen_col[idx_out] <- apply(dist_mat[idx_out, , drop = FALSE], 1, function(v) {
    v2 <- v; v2[!is.finite(v2)] <- Inf
    pos <- which(v2 >= 0)
    pos[which.min(v2[pos])]
  })
}

pa_var_valid <- rep(NA_character_, n_valid)
pa_dist_km_valid <- rep(NA_real_, n_valid)

ok <- which(!is.na(chosen_col))
pa_var_valid[ok] <- gov_names[chosen_col[ok]]
pa_dist_km_valid[ok] <- dist_mat[cbind(ok, chosen_col[ok])] / 1000

# ============================================================
# PIXEL GEOMETRY TABLE
# ============================================================
pix_geom <- data.table(
  cell       = valid_idx,
  SESU_ID    = SESU_valid,
  pa_var     = pa_var_valid,
  pa_dist_km = pa_dist_km_valid
)[!is.na(pa_var) & is.finite(pa_dist_km)]

# ============================================================
# PIXEL GEOMETRY TABLE (NO DISTANCE TRUNCATION)
# ============================================================

pix_geom_all <- data.table(
  cell       = valid_idx,
  SESU_ID    = SESU_valid,
  pa_var     = pa_var_valid,
  pa_dist_km = pa_dist_km_valid
)[!is.na(pa_var) & is.finite(pa_dist_km)]

pix_geom_all[, pos_valid := match(cell, valid_idx)]

pix_geom_all[, side := fifelse(pa_dist_km < 0, "inside", "outside")]

build_covariate_similarity_corridor <- function(pix_dt, cov_mat, match_ratio = 1.0) {
  stopifnot(is.data.table(pix_dt))
  out_list <- vector("list", length = 0L)

  key_dt <- unique(pix_dt[, .(SESU_ID, pa_var)])
  for (k in seq_len(nrow(key_dt))) {
    sid <- key_dt$SESU_ID[k]
    pav <- key_dt$pa_var[k]

    dt_str <- pix_dt[SESU_ID == sid & pa_var == pav]
    dt_in  <- dt_str[side == "inside"]
    dt_out <- dt_str[side == "outside"]

    if (nrow(dt_in) == 0) next

    if (nrow(dt_out) == 0) {
      out_list[[length(out_list) + 1L]] <- dt_in
      next
    }

    n_in <- nrow(dt_in)
    n_target_out <- min(nrow(dt_out), as.integer(ceiling(match_ratio * n_in)))
    if (n_target_out <= 0) {
      out_list[[length(out_list) + 1L]] <- dt_in
      next
    }

    X_in  <- cov_mat[dt_in$pos_valid, , drop = FALSE]
    X_out <- cov_mat[dt_out$pos_valid, , drop = FALSE]

    # Center/scale using inside moments (robustness: avoid div by 0)
    mu <- colMeans(X_in)
    sdv <- apply(X_in, 2, stats::sd)
    sdv[!is.finite(sdv) | sdv == 0] <- 1

    Z_in  <- sweep(sweep(X_in,  2, mu, "-"), 2, sdv, "/")
    Z_out <- sweep(sweep(X_out, 2, mu, "-"), 2, sdv, "/")

    # Covariance from inside; regularize if ill-conditioned
    S <- stats::cov(Z_in)
    if (any(!is.finite(S))) {
      # fall back to diagonal covariance (independent z-scores)
      S <- diag(ncol(Z_in))
    } else {
      # mild ridge to ensure invertibility
      S <- S + diag(1e-6, ncol(S))
    }

    # Mahalanobis distance to inside mean (which is ~0 after z-scoring)
    d2 <- stats::mahalanobis(Z_out, center = rep(0, ncol(Z_out)), cov = S, inverted = FALSE)

    dt_out[, d2 := d2]
    dt_out <- dt_out[order(d2)][seq_len(n_target_out)]
    dt_out[, d2 := NULL]

    out_list[[length(out_list) + 1L]] <- rbind(dt_in, dt_out, use.names = TRUE)
  }

  if (length(out_list) == 0) {
    return(pix_dt[0])
  }
  rbindlist(out_list, use.names = TRUE, fill = TRUE)
}

build_closest_border_corridor <- function(pix_dt, match_ratio = 1.0) {
  stopifnot(is.data.table(pix_dt))
  out_list <- vector("list", length = 0L)

  key_dt <- unique(pix_dt[, .(SESU_ID, pa_var)])
  for (k in seq_len(nrow(key_dt))) {
    sid <- key_dt$SESU_ID[k]
    pav <- key_dt$pa_var[k]

    dt_str <- pix_dt[SESU_ID == sid & pa_var == pav]
    dt_in  <- dt_str[side == "inside"]
    dt_out <- dt_str[side == "outside"]

    # Always keep all inside; if no inside, skip (no target count)
    if (nrow(dt_in) == 0) next

    # If no outside, inside-only
    if (nrow(dt_out) == 0) {
      out_list[[length(out_list) + 1L]] <- dt_in
      next
    }

    n_in <- nrow(dt_in)
    n_target_out <- min(nrow(dt_out), as.integer(ceiling(match_ratio * n_in)))
    if (n_target_out <= 0) {
      out_list[[length(out_list) + 1L]] <- dt_in
      next
    }

    # closest to border = smallest absolute signed distance
    dt_out[, abs_dist := abs(pa_dist_km)]
    setorder(dt_out, abs_dist)
    dt_out <- dt_out[seq_len(n_target_out)]
    dt_out[, abs_dist := NULL]

    out_list[[length(out_list) + 1L]] <- rbind(dt_in, dt_out, use.names = TRUE)
  }

  if (length(out_list) == 0) return(pix_dt[0])
  rbindlist(out_list, use.names = TRUE, fill = TRUE)
}
# ============================================================
# PIXEL SELECTION
# ============================================================

if (PIXEL_SELECTION_MODE == "all") {
  pix_geom <- copy(pix_geom_all)

} else if (PIXEL_SELECTION_MODE == "closest_border") {
  pix_geom <- build_closest_border_corridor(pix_geom_all, match_ratio = PIXEL_MATCH_RATIO)

} else if (PIXEL_SELECTION_MODE == "covmatch") {
  pix_geom_cc <- copy(pix_geom_all)
  pix_geom_cc <- pix_geom_cc[cov_complete[pos_valid] == TRUE]
  if (nrow(pix_geom_cc) == 0) stop("No pixels remain after enforcing complete matching covariates (covmatch mode).")
  pix_geom <- build_covariate_similarity_corridor(pix_geom_cc, cov_mat, match_ratio = PIXEL_MATCH_RATIO)

} else {
  stop("Unknown PIXEL_SELECTION_MODE: ", PIXEL_SELECTION_MODE,
       " (use 'all', 'closest_border', or 'covmatch').")
}

if (nrow(pix_geom) == 0) stop("Pixel selection produced 0 pixels. Mode=", PIXEL_SELECTION_MODE)
pix_geom[, side := fifelse(pa_dist_km < 0, "inside", "outside")]

# ============================================================
# REDUCED PIXEL SET FOR DT BUILDERS (CORRIDOR × TARGET SESUs)
# ============================================================
pix_keep <- pix_geom[SESU_ID %in% target_sesus]
cells_keep <- unique(pix_keep$cell)
pos_keep <- match(cells_keep, valid_idx)
pos_keep <- pos_keep[!is.na(pos_keep)]
n_keep <- length(pos_keep)
SESU_keep <- SESU_valid[pos_keep]
pa_var_keep <- pa_var_valid[pos_keep]
pa_dist_keep <- pa_dist_km_valid[pos_keep]
if (n_keep == 0) stop("No corridor pixels found for target_sesus after truncation.")


# ============================================================
# CORRIDOR PIXEL COUNTS
# ============================================================
pix_geom_diag <- copy(pix_geom)
counts_side_sesu <- unique(pix_geom_diag[, .(cell, SESU_ID, side)])[
  , .(n_pixels = .N), by = .(SESU_ID, side)
]
setorder(counts_side_sesu, SESU_ID, side)
counts_side_pa <- unique(pix_geom_diag[, .(cell, SESU_ID, pa_var, side)])[
  , .(n_pixels = .N), by = .(SESU_ID, pa_var, side)
]
setorder(counts_side_pa, SESU_ID, pa_var, side)
fwrite(counts_side_sesu, file.path(out_dir, "corridor_pixel_counts_by_SESU_side.csv"))
fwrite(counts_side_pa,   file.path(out_dir, "corridor_pixel_counts_by_SESU_PA_side.csv"))

# ============================================================
# PLACEBO APPENDER (RANDOM SIDE)
# ============================================================
append_placebo_np <- function(dt) {
  if (!RUN_PLACEBO_BOUNDARY) return(dt)
  if (is.null(dt) || nrow(dt) == 0) return(dt)

  base_var <- "dist_parc_national_signed_m"
  dt_np <- dt[pa_var == base_var & is.finite(pa_dist_km)]
  if (nrow(dt_np) == 0) return(dt)

  pix <- unique(dt_np[, .(SESU_ID, cell, d = pa_dist_km)])
  pix[, orig_inside := (d < 0)]
  cnt <- pix[, .(n_total = .N, n_in = sum(orig_inside)), by = .(SESU_ID)]

  pix <- merge(pix, cnt, by = "SESU_ID", all.x = TRUE)

  placebo_list <- vector("list", N_PLACEBO)

  for (r_id in seq_len(N_PLACEBO)) {
    set.seed(PLACEBO_SEED_BASE + r_id)

    pix_r <- copy(pix)
    pix_r[, u := runif(.N), by = .(SESU_ID)]
    setorder(pix_r, SESU_ID, u)
    pix_r[, placebo_inside := (seq_len(.N) <= n_in), by = .(SESU_ID)]

    lut <- pix_r[, .(SESU_ID, cell, placebo_inside)]

    dt_pl <- merge(dt_np, lut, by = c("SESU_ID", "cell"), all.x = TRUE)
    dt_pl[, pa_var := PLACEBO_PA_VAR]
    dt_pl[, pa_label_rep := sprintf("placebo_r%03d", r_id)]  # NEW: replicate id

    dt_pl[, pa_dist_km := abs(pa_dist_km)]
    dt_pl[placebo_inside == TRUE & pa_dist_km == 0, pa_dist_km := 1e-6]
    dt_pl[placebo_inside == TRUE, pa_dist_km := -pa_dist_km]
    dt_pl[, placebo_inside := NULL]

    placebo_list[[r_id]] <- dt_pl
  }

  rbindlist(c(list(dt), placebo_list), use.names = TRUE, fill = TRUE)
}

# ============================================================
# PIXEL-YEAR TABLE BUILDERS
# ============================================================
build_dt_for_yearband <- function(band_name) {
  if (!(band_name %in% names(r))) return(NULL)
    band_vals <- extract_cells_vec(r[[band_name]], cells_keep)

  yrs_present_all <- sort(unique(na.omit(as.integer(band_vals[band_vals > 0]))))
  if (length(yrs_present_all) == 0) return(NULL)

  yrs_present_all <- seq.int(min(yrs_present_all), max(yrs_present_all))
  yrs_present_all <- yrs_present_all[yrs_present_all >= YEAR_MIN & yrs_present_all <= YEAR_MAX]
  if (length(yrs_present_all) == 0) return(NULL)

  if (band_name == "year_agri") {
    yrs_present <- yrs_present_all[yrs_present_all != 2000L]
  } else {
    yrs_present <- yrs_present_all
  }
  if (length(yrs_present) == 0) return(NULL)

  ny <- length(yrs_present)
  year_vec  <- rep(yrs_present, each = n_keep)
  local_idx <- rep.int(seq_len(n_keep), times = ny)

  event_rep <- as.integer(band_vals[local_idx])

  # 0 encodes "never crosses tau": keep in risk set for all years
  event_rep[event_rep <= 0] <- NA_integer_

  disturbed_vec <- as.integer(!is.na(event_rep) & (year_vec == event_rep))
  at_risk <- ifelse(is.na(event_rep), 1L, as.integer(year_vec <= event_rep))

  keep <- which(at_risk == 1L)
  if (length(keep) == 0) return(NULL)

  dt <- data.table(
    disturbance_type = band_name,
    year      = as.integer(year_vec[keep]),
    cell      = rep.int(cells_keep, times = ny)[keep],
    SESU_ID   = SESU_keep[local_idx[keep]],
    disturbed = disturbed_vec[keep]
  )

  dt[, pa_var := pa_var_keep[local_idx[keep]]]
  dt[, pa_dist_km := pa_dist_keep[local_idx[keep]]]
  dt[]
}


build_dt_fire_all <- function() {
  if (length(fire_bands) == 0) return(NULL)

  n_fire <- length(fire_bands)
  year_vec  <- rep(fire_years, each = n_keep)
  local_idx <- rep.int(seq_len(n_keep), times = n_fire)

  disturbed_vec <- integer(length = n_keep * n_fire)

  for (i in seq_along(fire_bands)) {
    vals <- extract_cells_vec(r[[fire_bands[i]]], cells_keep)

    start <- (i - 1) * n_keep + 1
    end   <- i * n_keep
    disturbed_vec[start:end] <- as.integer(
      is.finite(vals) & vals >= fire_season_doy_min & vals <= fire_season_doy_max
    )
  }

  dt <- data.table(
    disturbance_type = "fire",
    year      = as.integer(year_vec),
    cell      = rep.int(cells_keep, times = n_fire),
    SESU_ID   = SESU_keep[local_idx],
    disturbed = disturbed_vec
  )

  dt[, pa_var := pa_var_keep[local_idx]]
  dt[, pa_dist_km := pa_dist_keep[local_idx]]
  dt[]
}

# ============================================================
# SURFACE SUMMARY (MODEL-READY): counts by SESU × year × PA × side
# ============================================================
compute_surface_summary_simple <- function(dt) {
  dt_sub <- dt[!is.na(pa_var) & is.finite(pa_dist_km)]
  if (nrow(dt_sub) == 0) return(NULL)

  # Side is purely determined by signed distance
  dt_sub[, side := fifelse(pa_dist_km < 0, "inside", "outside")]
  dt_sub[, pa_label := label_or_name(pa_var)]

  # HARD ASSERTIONS: forbid side mixing due to any upstream bug
  if (any(dt_sub[side == "inside", pa_dist_km >= 0])) {
    stop("Integrity error: some rows labeled 'inside' have pa_dist_km >= 0. Check corridor construction / pa_dist_km propagation.")
  }
  if (any(dt_sub[side == "outside", pa_dist_km < 0])) {
    stop("Integrity error: some rows labeled 'outside' have pa_dist_km < 0. Check corridor construction / pa_dist_km propagation.")
  }

  surf <- dt_sub[, .(
    n = .N,
    y = sum(disturbed, na.rm = TRUE)
  ), by = .(SESU_ID, year, pa_label, side)]

  surf[, p_hat := y / n]
  surf[]
}

make_surfaces_for_dt <- function(dt, disturbance_name, target_sesus = NULL) {
  if (is.null(dt)) return(dt)
  if (!data.table::is.data.table(dt)) dt <- as.data.table(dt)
  if (nrow(dt) == 0) return(dt)

  dt2 <- dt
  if (!is.null(target_sesus)) {
    dt2 <- dt2[SESU_ID %in% target_sesus]
    if (nrow(dt2) == 0) return(NULL)
  }

  surf <- compute_surface_summary_simple(dt2)
  if (is.null(surf) || nrow(surf) == 0) return(NULL)

  surf[, disturbance := as.character(disturbance_name)]
  setcolorder(surf, c("SESU_ID","year","disturbance","pa_label","side","n","y","p_hat"))
  surf[]
}

# ============================================================
# BUILD DTs + APPEND PLACEBO
# ============================================================
dt_fire <- append_placebo_np(build_dt_fire_all())
dt_agri <- append_placebo_np(build_dt_for_yearband("year_agri"))
dt_def  <- append_placebo_np(build_dt_for_yearband("year_deforest_masked"))

assert_dt_matches_raster <- function(dt, r, r_sesu, base_np="dist_parc_national_signed_m", band=NULL, n_check=2000) {
  if (is.null(dt) || nrow(dt) == 0) return(invisible(TRUE))
  dt0 <- dt[pa_var == base_np]
  if (nrow(dt0) == 0) return(invisible(TRUE))

  # sample rows
  set.seed(1)
  dt0 <- dt0[sample(.N, min(.N, n_check))]

  # raster truth
  dist_km_r <- extract_cells_vec(r[[base_np]], dt0$cell) / 1000
  sesu_r    <- extract_cells_vec(r_sesu, dt0$cell)
  if (!is.null(band)) {
    band_r  <- extract_cells_vec(r[[band]], dt0$cell)
  } else band_r <- NULL

  # checks
  if (any(is.finite(dt0$pa_dist_km) & is.finite(dist_km_r) & abs(dt0$pa_dist_km - dist_km_r) > 1e-6, na.rm=TRUE)) {
    stop("DT pa_dist_km does not match raster distances for base NP. Alignment/indexing bug.")
  }
  if (any(!is.na(dt0$SESU_ID) & !is.na(sesu_r) & dt0$SESU_ID != sesu_r, na.rm=TRUE)) {
    stop("DT SESU_ID does not match raster SESU for base NP rows. Alignment/indexing bug.")
  }
  invisible(TRUE)
}

assert_dt_matches_raster(dt_agri, r, r_sesu, band="year_agri")
assert_dt_matches_raster(dt_def,  r, r_sesu, band="year_deforest_masked")


# ============================================================
# BUILD MODEL-READY SURFACES + EXPORT SINGLE LONG TABLE
# ============================================================
surf_fire <- make_surfaces_for_dt(dt_fire, "fire", target_sesus = NULL)
surf_agri <- make_surfaces_for_dt(dt_agri, "year_agri", target_sesus = NULL)
surf_def  <- make_surfaces_for_dt(dt_def,  "year_deforest_masked", target_sesus = NULL)

rs_surfaces_long <- rbindlist(list(surf_fire, surf_agri, surf_def), fill = TRUE)

if (is.null(rs_surfaces_long) || nrow(rs_surfaces_long) == 0) {
  stop("No RS surfaces produced. Diagnose: dt_fire/dt_agri/dt_def empty or corridor truncation removed all rows.")
}

rs_surfaces_long[, `:=`(
  SESU_ID = as.integer(SESU_ID),
  year = as.integer(year),
  side = as.character(side),
  pa_label = as.character(pa_label),
  disturbance = as.character(disturbance),
  n = as.integer(n),
  y = as.integer(y)
)]

setorder(rs_surfaces_long, disturbance, pa_label, SESU_ID, side, year)

out_path <- file.path(out_dir, "rs_surfaces_long.csv")
fwrite(rs_surfaces_long, out_path)

writeLines(
  c(
    paste0("PIXEL_SELECTION_MODE=", PIXEL_SELECTION_MODE),
    paste0("PIXEL_MATCH_RATIO=", PIXEL_MATCH_RATIO)
  ),
  file.path(out_dir, "provenance", "pixel_selection_mode.txt")
)

message("Wrote: ", out_path, " | nrow=", nrow(rs_surfaces_long),
        " | SESUs=", length(unique(rs_surfaces_long$SESU_ID)),
        " | PAs=", length(unique(rs_surfaces_long$pa_label)),
        " | disturbances=", paste(sort(unique(rs_surfaces_long$disturbance)), collapse=", "))
input_paths <- c(cov_path, sesu_path)
write_provenance(out_dir, input_paths)

# ============================================================
# DIAGNOSTIC RASTER: corridor classes by SESU × side
# 11=SESU1 inside, 12=SESU1 outside, 31=SESU3 inside, 32=SESU3 outside
# ============================================================

template_r <- r_cov[[1]]

# initialize with NA
r_corridor_class <- terra::setValues(template_r, rep(NA_integer_, ncell(template_r)))

# only keep the SESUs you care about (here: 1 and 3)
class_dt <- unique(pix_geom[SESU_ID %in% c(1L, 3L), .(cell, SESU_ID, side)])

# sanity: enforce uniqueness (one cell should map to one SESU×side)
if (any(duplicated(class_dt$cell))) {
  dup_cells <- class_dt[duplicated(cell), unique(cell)]
  stop("Some selected corridor cells have multiple SESU×side assignments. Example cells: ",
       paste(head(dup_cells, 20), collapse = ", "),
       "\nThis indicates a geometry/indexing bug upstream.")
}

# encode classes
class_dt[, class_code := fifelse(SESU_ID == 1L & side == "inside", 11L,
                                 fifelse(SESU_ID == 1L & side == "outside", 12L,
                                         fifelse(SESU_ID == 3L & side == "inside", 31L,
                                                 fifelse(SESU_ID == 3L & side == "outside", 32L, NA_integer_))))]

r_corridor_class[class_dt$cell] <- class_dt$class_code

class_path <- file.path(out_dir, "corridor_selected_SESU_side_classes.tif")
terra::writeRaster(r_corridor_class, class_path, overwrite = TRUE)
message("Wrote: ", class_path)

legend_dt <- data.table(
  class_code = c(11L, 12L, 31L, 32L),
  SESU_ID    = c(1L,  1L,  3L,  3L),
  side       = c("inside","outside","inside","outside"),
  label      = c("SESU1 inside","SESU1 outside","SESU3 inside","SESU3 outside")
)
fwrite(legend_dt, file.path(out_dir, "corridor_selected_SESU_side_classes_legend.csv"))
