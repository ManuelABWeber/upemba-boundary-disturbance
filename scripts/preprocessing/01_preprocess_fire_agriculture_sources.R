# ===========================================================
# Fire (2021–2022) + Agriculture (year_agri) preprocessing
# ===========================================================

suppressPackageStartupMessages({
  library(terra)
})

root_dir <- Sys.getenv("UPEMBA_DATA_ROOT", unset = getwd())
data_dir <- file.path(root_dir, "data")

template_anchor_path <- file.path(data_dir, "gfc_year_deforest_majority_tau_500m_epsg32735.tif")
template <- rast(template_anchor_path)

# Fire inputs
fire_local_dir <- file.path(data_dir, "fire")  # <frozen-development-repository>/data/fire

# Agri inputs
agri_stack_fallback <- file.path(data_dir, "AFCD_stack.tif")
landmask500_path    <- file.path(data_dir, "land_mask_nonwater_500m_epsg32735.tif")
aoi_path            <- file.path(data_dir, "studyarea_chapter1.geojson")

# Output dirs
out_dir_fire <- file.path(data_dir, "fire_precomputed_500m")
out_dir_agri <- file.path(data_dir, "agri_precomputed_500m")
dir.create(out_dir_fire, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir_agri, recursive = TRUE, showWarnings = FALSE)

# Parameters
tau <- 0.25
fire_season_doy_min <- 100
fire_season_doy_max <- 300

YEAR_MIN <- 2001L
YEAR_MAX <- 2022L

terraOptions(progress = 1)

# ===========================================================
# Fire (2021–2022): monthly merge -> per-cell MAX (native grid),
# ===========================================================

suppressPackageStartupMessages({
  library(terra)
})

root_dir <- Sys.getenv("UPEMBA_DATA_ROOT", unset = getwd())
data_dir <- file.path(root_dir, "data")

template_anchor_path <- file.path(data_dir, "gfc_year_deforest_majority_tau_500m_epsg32735.tif")
template <- rast(template_anchor_path)

fire_root <- file.path(data_dir, "fire")
out_dir   <- file.path(data_dir, "fire_precomputed_500m")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tau <- 0.25

terraOptions(progress = 1)

find_fire_monthly_jd <- function(year, fire_root) {
  dd_all <- list.dirs(fire_root, recursive = FALSE, full.names = TRUE)

  dd <- dd_all[
    grepl(sprintf("^%d(04|05|06|07|08|09|10)01", year), basename(dd_all))
  ]
  if (length(dd) == 0) {
    stop("No monthly fire folders matched for year ", year, " under: ", fire_root)
  }

  jf <- unlist(lapply(dd, function(d) {
    ff <- list.files(d, pattern = "\\.(tif|tiff)$", full.names = TRUE, ignore.case = TRUE)
    if (length(ff) == 0) return(character(0))

    ff_jd <- ff[grepl("JD", basename(ff), ignore.case = TRUE)]
    ff_jd <- ff_jd[!grepl("QC|QUAL|QUALITY|UNC|UNCT|ERROR", basename(ff_jd), ignore.case = TRUE)]
    if (length(ff_jd) == 0) return(character(0))

    ff_jd <- ff_jd[order(nchar(basename(ff_jd)))]
    ff_jd[1]
  }))

  jf <- jf[file.exists(jf)]
  if (length(jf) == 0) stop("No JD rasters found for year ", year, " after filtering.")

  sort(jf)
}

build_fire_native_max_then_tau500 <- function(year, template, fire_root, out_dir, tau = 0.5) {

  out_doy500 <- file.path(out_dir, sprintf("fireDOY_max_AprOct_%d_500m_tau%0.2f.tif", year, tau))
  out_bin500 <- file.path(out_dir, sprintf("fireBurned_AprOct_%d_500m_tau%0.2f.tif", year, tau))

  if (file.exists(out_doy500) && file.exists(out_bin500)) {
    message("Fire cached exists, skipping: ", basename(out_doy500))
    return(invisible(list(doy500 = rast(out_doy500), burned500 = rast(out_bin500))))
  }

  jf <- find_fire_monthly_jd(year, fire_root)
  message("Year ", year, " | monthly JD rasters (n=", length(jf), "):\n  ",
          paste(basename(jf), collapse = "\n  "))

  doy_native <- rast(jf[1])
  doy_native[doy_native <= 0] <- NA

  if (length(jf) > 1) {
    for (f in jf[-1]) {
      r <- rast(f)
      r[r <= 0] <- NA
      doy_native <- max(doy_native, r, na.rm = TRUE)  # per-cell max
    }
  }
  names(doy_native) <- "fireDOY_max_native"


  burned_native <- as.int(!is.na(doy_native))
  burned_frac_500 <- project(burned_native, template, method = "average")
  burned500       <- burned_frac_500 >= tau
  burned_out      <- as.int(burned500)

  doy500 <- project(doy_native, template, method = "near")
  doy500 <- mask(doy500, burned500, maskvalues = FALSE)
  doy500[is.na(doy500)] <- 0
  doy500 <- round(doy500)
  names(doy500) <- "fireDOY_max"

  writeRaster(
    doy500, out_doy500, overwrite = TRUE,
    wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
  )
  writeRaster(
    burned_out, out_bin500, overwrite = TRUE, datatype = "INT1U",
    wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
  )

  message("Wrote: ", basename(out_doy500), " and ", basename(out_bin500))
  invisible(list(doy500 = rast(out_doy500), burned500 = rast(out_bin500)))
}

build_fire_native_max_then_tau500(2021L, template, fire_root, out_dir, tau = tau)
build_fire_native_max_then_tau500(2022L, template, fire_root, out_dir, tau = tau)

# ===========================================================
# AGRICULTURE: cache year_agri at 500m (tau; 2001–2022)
# ===========================================================

out_path_agri <- file.path(
  out_dir_agri,
  sprintf("year_agri_500m_tau%0.2f_%d_%d.tif", tau, YEAR_MIN, YEAR_MAX)
)

if (file.exists(out_path_agri)) {
  message("Agri cached exists, skipping compute: ", out_path_agri)
} else {

  # ---- Masks on the 500m template ----
  aoi_v <- vect(aoi_path)
  aoi_v <- project(aoi_v, crs(template))

  aoi_mask <- rasterize(aoi_v, template, field = 1, background = NA)
  aoi_mask[aoi_mask > 0] <- 1

  land_mask <- rast(landmask500_path)
  land_mask <- project(land_mask, template, method = "near")
  land_mask[land_mask == 0] <- NA

  mask_keep <- aoi_mask * land_mask

  r <- rast(agri_stack_fallback)
  a_native <- project(aoi_v, crs(r))
  r <- mask(crop(r, ext(a_native), snap = "out"), a_native)

  yrs <- suppressWarnings(as.integer(gsub(".*?(\\d{4}).*", "\\1", names(r))))
  if (all(is.na(yrs))) yrs <- seq(2000L, by = 1L, length.out = nlyr(r))
  o <- order(yrs); r <- r[[o]]; yrs <- yrs[o]

  BASE_YEAR <- YEAR_MIN - 1L
  keep <- which(yrs >= BASE_YEAR & yrs <= YEAR_MAX)
  r <- r[[keep]]
  yrs <- yrs[keep]
  stopifnot(nlyr(r) == length(yrs), length(yrs) > 0)

  if (!any(yrs == BASE_YEAR)) {
    stop("Baseline year ", BASE_YEAR, " not found in AFCD stack; cannot compute ", BASE_YEAR, "→", YEAR_MIN, " transitions.")
  }

  b <- ifel(r == 1, 1, 0)

  frac500 <- project(b, template, method = "average")
  frac500 <- frac500 * mask_keep
  names(frac500) <- paste0("frac_", yrs)

  present <- frac500 >= tau  # logical multilayer

  zero0 <- present[[1]] * 0
  lag_present <- c(zero0, present[[1:(nlyr(present) - 1)]])
  names(lag_present) <- paste0("lag_", yrs)

  transition <- present & (lag_present == 0)

  idx_win <- which(yrs >= YEAR_MIN & yrs <= YEAR_MAX)
  transition_win <- transition[[idx_win]]
  yrs_win <- yrs[idx_win]

  year_agri <- app(transition_win, fun = function(...) {
    x <- c(...)
    k <- which(x == 1)[1]
    if (length(k) == 0) return(NA_real_)
    yrs_win[k]
  })

  names(year_agri) <- "year_agri"
  year_agri <- year_agri * mask_keep

  writeRaster(
    year_agri, out_path_agri, overwrite = TRUE,
    wopt = list(gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
  )
}


message("Done. Fire cache dir: ", out_dir_fire, " | Agri cache dir: ", out_dir_agri)
