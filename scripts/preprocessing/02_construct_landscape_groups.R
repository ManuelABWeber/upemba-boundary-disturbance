# ===========================================================
# ===========================================================
# SCRIPT 1: SESU CLUSTERING, COVARIATE STACK ASSEMBLY
# ===========================================================
# ===========================================================

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(dplyr)
  library(factoextra)
  library(ggplot2)
  library(tidyr)
  library(mclust)
  library(data.table)
  library(cluster)
})

# ===========================================================
# PARAMETERS
# ===========================================================
root_dir <- Sys.getenv("UPEMBA_DATA_ROOT", unset = getwd())
data_dir <- file.path(root_dir, "data")
aoi_path <- file.path(data_dir, "studyarea_chapter1.geojson")

today_str <- format(Sys.Date(), "%Y_%m_%d")
out_dir <- file.path(root_dir, paste0("run_", today_str))
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

target_crs <- "EPSG:32735"
target_res_m <- 500
min_patch_size <- 4
treecover_threshold <- 30
sample_size <- 20000
k_max_elbow <- 15
k_final <- 3
baseline_years <- list(year_urban = 2000)

# Fire season already applied in GEE exports
fire_season_doy_min <- 100
fire_season_doy_max <- 300

YEAR_MIN <- 2001L
YEAR_MAX <- 2022L

tau <- 0.25


# ===========================================================
# INPUTS
# ===========================================================.
template_anchor_path<- file.path(data_dir, "gfc_year_deforest_majority_tau_500m_epsg32735.tif")
landmask500_path    <- file.path(data_dir, "land_mask_nonwater_500m_epsg32735.tif")
tree2000mean500_path<- file.path(data_dir, "gfc_treecover2000_meanpct_500m_epsg32735.tif")
deforest500_path    <- file.path(data_dir, "gfc_year_deforest_majority_tau_500m_epsg32735.tif")
built_year500_path  <- file.path(data_dir, "ghsl_year_urban_majority_tau_500m_epsg32735.tif")
access500_path      <- file.path(data_dir, "accessibility_cities_2015_500m_epsg32735.tif")
fire500_stack_path  <- file.path(data_dir, "FireCCI51_season_DOYmin_tau_and_binary_2001_2020_500m_epsg32735.tif")
dist_water500_path  <- file.path(data_dir, "dist_perm_water_m_500m_epsg32735.tif")
climate500_path     <- file.path(data_dir, "climate_summaries_1981_2010_500m_epsg32735.tif")
soil500_path        <- file.path(data_dir, "soilgrids_0_30cm_mean_500m_epsg32735.tif")
dist_parc500_path   <- file.path(data_dir, "dist_parc_national_signed_m_500m_epsg32735.tif")
dist_zone500_path   <- file.path(data_dir, "dist_zone_annexe_signed_m_500m_epsg32735.tif")
dist_dom500_path    <- file.path(data_dir, "dist_domaine_chasse_signed_m_500m_epsg32735.tif")
dem_path            <- file.path(data_dir, "dem_copernicus_glo30_mean_500m_epsg32735.tif")
fire_2021_path      <- file.path(data_dir, "fireDOY_season_2021_500m_tau0.25.tif")
fire_2022_path      <- file.path(data_dir, "fireDOY_season_2022_500m_tau0.25.tif")
agri_year_path      <- file.path(data_dir, "year_agri_500m_tau0.25_2001_2022.tif")



# ===========================================================
# LOAD TEMPLATE + AOI MASK
# ===========================================================
template <- rast(template_anchor_path)
if (!same.crs(template, target_crs)) stop("Template CRS not EPSG:32735: ", crs(template))

aoi_v <- terra::vect(aoi_path)
aoi_v <- terra::project(aoi_v, target_crs)

aoi_mask <- terra::rasterize(aoi_v, template, field = 1, background = NA)
aoi_mask[aoi_mask > 0] <- 1

land_mask <- rast(landmask500_path)
land_mask <- project(land_mask, template, method = "near")
land_mask[land_mask == 0] <- NA
mask_keep <- aoi_mask * land_mask

# ===========================================================
# MANIFEST
# ===========================================================
manifest <- list(
  run_date = today_str,
  target_crs = target_crs,
  target_res_m = target_res_m,
  min_patch_size = min_patch_size,
  treecover_threshold = treecover_threshold,
  sample_size = sample_size,
  k_max_elbow = k_max_elbow,
  k_final = k_final,
  fire_season_doy_min = fire_season_doy_min,
  fire_season_doy_max = fire_season_doy_max,
  baseline_years = baseline_years,
  inputs = list(
    template_anchor_path = template_anchor_path,
    landmask500_path = landmask500_path,
    tree2000mean500_path = tree2000mean500_path,
    deforest500_path = deforest500_path,
    built_year500_path = built_year500_path,
    access500_path = access500_path,
    fire500_stack_path = fire500_stack_path,
    fire_2021_path = fire_2021_path,
    fire_2022_path = fire_2022_path,
    agri_year_path = agri_year_path,
    dist_water500_path = dist_water500_path,
    climate500_path = climate500_path,
    soil500_path = soil500_path,
    dist_parc500_path = dist_parc500_path,
    dist_zone500_path = dist_zone500_path,
    dist_dom500_path = dist_dom500_path,
    dem_path = dem_path,
    aoi_path = aoi_path
  )
)

saveRDS(manifest, file.path(out_dir, "SESU_manifest.rds"))
writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))

# ===========================================================
# LOAD STATIC COVARIATES
# ===========================================================
# Deforestation year (500 m): earliest year when cumulative loss fraction ≥ τ within 500 m cell
deforest_year <- rast(deforest500_path)
names(deforest_year) <- "year_deforest"

# Forest mask from 500 m mean treecover
tree2000mean <- rast(tree2000mean500_path)
names(tree2000mean) <- "treecover2000_mean_pct_500m"
forestmask <- ifel(tree2000mean >= treecover_threshold, 1, 0)

deforest_year_masked <- mask(deforest_year, forestmask, maskvalues = 0, inverse = FALSE)
names(deforest_year_masked) <- "year_deforest_masked"

# Built-year (500 m): earliest GHSL epoch when cumulative built fraction ≥ τ within 500 m cell
built_year <- rast(built_year500_path)
names(built_year) <- "year_urban"

# Accessibility (500m)
accessibility <- rast(access500_path)
names(accessibility) <- "accessibility_cities"

# Distance to permanent water (500m)
dist_to_water <- rast(dist_water500_path)
names(dist_to_water) <- "dist_perm_water_m"

# Climate summaries (500m)
clim <- rast(climate500_path)

# Soil 0–30 cm means (500m)
soil <- rast(soil500_path)

# PA signed distances (500m)
dist_parc <- rast(dist_parc500_path); names(dist_parc) <- "dist_parc_national_signed_m"
dist_zone <- rast(dist_zone500_path); names(dist_zone) <- "dist_zone_annexe_signed_m"
dist_dom  <- rast(dist_dom500_path);  names(dist_dom)  <- "dist_domaine_chasse_signed_m"
gov_stack <- c(dist_parc, dist_zone, dist_dom)

# -----------------------------------------------------------
# Fire (DOY) 2001–2020 from GEE stack + append 2021–2022 cached
# -----------------------------------------------------------
fire_stack <- rast(fire500_stack_path)

# Prefer DOY-like layers; exclude obvious burned/binary layers if present
nm_fire <- names(fire_stack)

fire_doy_names <- nm_fire[
  grepl("doy", nm_fire, ignore.case = TRUE) &
    !grepl("burn|bin|frac|mask", nm_fire, ignore.case = TRUE)
]
stopifnot(length(fire_doy_names) > 0)

fire_doy <- fire_stack[[fire_doy_names]]

# Parse year from each band name (first 4-digit year in name)
fire_years_gee <- suppressWarnings(as.integer(sub("^.*?([0-9]{4}).*$", "\\1", names(fire_doy))))
if (any(!is.finite(fire_years_gee))) {
  stop("Could not parse 4-digit years from some fire DOY band names in fire_stack. Names were: ",
       paste(names(fire_doy)[!is.finite(fire_years_gee)], collapse = ", "))
}

# Canonical names expected by Script 3
names(fire_doy) <- paste0("fireDOY_", fire_years_gee)

# Append cached 2021–2022
stopifnot(file.exists(fire_2021_path), file.exists(fire_2022_path))
fire_2021 <- rast(fire_2021_path); names(fire_2021) <- "fireDOY_2021"
fire_2022 <- rast(fire_2022_path); names(fire_2022) <- "fireDOY_2022"
fire_doy <- c(fire_doy, fire_2021, fire_2022)

# Keep only study-period fire layers and sort by year
fire_years_all <- suppressWarnings(as.integer(sub("^fireDOY_([0-9]{4}).*$", "\\1", names(fire_doy))))
keep_fire <- is.finite(fire_years_all) & fire_years_all >= YEAR_MIN & fire_years_all <= YEAR_MAX
fire_doy <- fire_doy[[which(keep_fire)]]

fire_years_all <- fire_years_all[keep_fire]
o <- order(fire_years_all)
fire_doy <- fire_doy[[o]]

message("Fire years in fire_doy being written to cov stack: ",
        paste(fire_years_all[o], collapse = ", "))



# Agriculture
stopifnot(file.exists(agri_year_path))
agri_year <- rast(agri_year_path)
names(agri_year) <- "year_agri"

# DEM + slope
dem <- rast(dem_path)
dem_proj <- project(dem, template, method = "bilinear")
names(dem_proj) <- "elevation_m"
slope_proj <- terrain(dem_proj, v = "slope", unit = "degrees")
names(slope_proj) <- "slope_deg"

# ===========================================================
# MASK EVERYTHING TO AOI AND LAND
# ===========================================================
base_stack <- c(
  dem_proj,
  built_year,
  deforest_year_masked,
  agri_year,
  fire_doy
)

base_stack <- base_stack * mask_keep
accessibility <- accessibility * mask_keep
slope_masked <- slope_proj * mask_keep
dist_to_water <- dist_to_water * mask_keep
clim <- clim * mask_keep
soil <- soil * mask_keep
gov_stack <- gov_stack * mask_keep

# Forest2000 threshold raster for outputs
forest2000_30pct <- ifel(tree2000mean >= treecover_threshold, 1, 0) * mask_keep
names(forest2000_30pct) <- paste0("forest2000_ge_", treecover_threshold, "pct")

# ===========================================================
# DISTANCE-WEIGHTED METRICS
# ===========================================================
compute_weighted_dist <- function(binary_rast, prefix, min_patch_pixels = min_patch_size) {
  bin1 <- classify(binary_rast, rcl = matrix(c(-Inf, 0.5, NA, 0.5, Inf, 1), ncol=3, byrow=TRUE))
  patches_r <- patches(bin1, directions = 8)

  pf <- as.data.frame(freq(patches_r))
  pf <- pf[!is.na(pf$value), ]
  pf <- pf[pf$count >= min_patch_pixels, ]

  res_r <- rast(bin1)
  values(res_r) <- NA
  names(res_r) <- paste0("dist_weighted_", prefix)

  if (nrow(pf) == 0) {
    e <- ext(bin1)
    diag_m <- sqrt((e$xmax - e$xmin)^2 + (e$ymax - e$ymin)^2)
    values(res_r) <- diag_m
    return(res_r)
  }

  pf$area_m2 <- pf$count * prod(res(bin1))
  pf$sqrt_area <- sqrt(pf$area_m2)

  res_vals <- values(res_r)

  for (pid in pf$value) {
    patch_mask <- patches_r == pid
    patch_mask[values(patch_mask) == 0] <- NA

    d_pid <- distance(patch_mask)
    wd_pid <- d_pid / pf$sqrt_area[pf$value == pid]
    pid_vals <- values(wd_pid)

    idx_new  <- is.na(res_vals) & !is.na(pid_vals)
    res_vals[idx_new] <- pid_vals[idx_new]

    idx_both <- !is.na(res_vals) & !is.na(pid_vals)
    res_vals[idx_both] <- pmin(res_vals[idx_both], pid_vals[idx_both])
  }

  values(res_r) <- res_vals
  return(res_r)
}

# Baseline-only presence: built year <= 2000
yr_urban <- base_stack[["year_urban"]]
binary_urban0 <- ifel(!is.na(yr_urban) & (yr_urban <= baseline_years$year_urban), 1, 0)
dist_weighted_urban <- compute_weighted_dist(binary_urban0, "urban")
names(dist_weighted_urban) <- "dist_weighted_urban"
dist_weighted_urban <- dist_weighted_urban * mask_keep

metrics_stack <- dist_weighted_urban

# ===========================================================
# SESU CLUSTERING FEATURE SET
# ===========================================================
context_stack <- c(
  dem_proj * mask_keep,
  slope_proj * mask_keep,
  forest2000_30pct,
  metrics_stack,
  accessibility,
  dist_to_water,
  clim,
  soil
)

# Ensure unique names
names(context_stack)[names(context_stack) == "elevation_m"] <- "elevation_m"
names(context_stack)[names(context_stack) == "slope_deg"] <- "slope_deg"

context_df <- as.data.frame(context_stack, xy = TRUE, na.rm = FALSE)
context_df_complete <- context_df %>% filter(!is.na(elevation_m), !is.na(slope_deg))

# Imputation
impute_max <- c("dist_weighted_urban", "accessibility_cities", "dist_perm_water_m")
impute_median <- setdiff(names(context_stack), c("x","y","elevation_m","slope_deg","forest2000_ge_30pct"))

impute_log <- list()

for (v in impute_max) {
  if (v %in% names(context_df_complete)) {
    mx <- suppressWarnings(max(context_df_complete[[v]], na.rm = TRUE))
    if (!is.finite(mx)) mx <- 0
    context_df_complete[[v]][is.na(context_df_complete[[v]])] <- mx
    impute_log[[paste0(v, "_fill")]] <- mx
  }
}
for (v in impute_median) {
  if (v %in% names(context_df_complete)) {
    md <- suppressWarnings(median(context_df_complete[[v]], na.rm = TRUE))
    if (!is.finite(md)) md <- 0
    context_df_complete[[v]][is.na(context_df_complete[[v]])] <- md
    impute_log[[paste0(v, "_fill")]] <- md
  }
}
saveRDS(impute_log, file.path(out_dir, "SESU_imputation_values.rds"))

# Log transforms
log_vars <- c("dist_weighted_urban", "accessibility_cities", "dist_perm_water_m")
writeLines(names(context_stack), file.path(out_dir, "SESU_features_used.txt"))
writeLines(log_vars, file.path(out_dir, "SESU_log1p_features.txt"))

context_df_trans <- context_df_complete
context_df_trans[log_vars] <- lapply(context_df_trans[log_vars], function(x) log1p(x))

X_full <- as.matrix(context_df_trans[, setdiff(names(context_df_trans), c("x","y"))])
X_full_scaled <- scale(X_full)

sc_params <- list(center = attr(X_full_scaled, "scaled:center"),
                  scale  = attr(X_full_scaled, "scaled:scale"),
                  features = colnames(X_full_scaled))
saveRDS(sc_params, file.path(out_dir, "SESU_scaling_params.rds"))

# feature summary
feature_names <- setdiff(names(context_df_trans), c("x","y"))
feat_summary <- data.frame(
  feature = feature_names,
  n_na = sapply(context_df_trans[feature_names], function(z) sum(!is.finite(z))),
  min = sapply(context_df_trans[feature_names], function(z) suppressWarnings(min(z, na.rm=TRUE))),
  max = sapply(context_df_trans[feature_names], function(z) suppressWarnings(max(z, na.rm=TRUE)))
)
data.table::fwrite(data.table::as.data.table(feat_summary),
                   file.path(out_dir, "SESU_feature_summary.csv"))

# Elbow plot
set.seed(42)
sample_idx <- sample.int(nrow(X_full_scaled), size = min(sample_size, nrow(X_full_scaled)))
X_sample_scaled <- X_full_scaled[sample_idx, , drop = FALSE]

# -----------------------------------------------------------
# Silhouette-by-k table
# -----------------------------------------------------------
k_seq <- 2:k_max_elbow
d_sample <- dist(X_sample_scaled)

sil_df <- data.frame(
  k = k_seq,
  silhouette_mean = NA_real_
)

set.seed(42)
for (kk in k_seq) {
  km <- kmeans(X_sample_scaled, centers = kk, nstart = 25)
  sil <- silhouette(km$cluster, d_sample)
  sil_df$silhouette_mean[sil_df$k == kk] <- mean(sil[, "sil_width"])
}

write.csv(sil_df, file.path(out_dir, "kmeans_silhouette_by_k.csv"), row.names = FALSE)

best_k <- sil_df$k[which.max(sil_df$silhouette_mean)]
writeLines(
  paste0("Best k by mean silhouette (max): ", best_k),
  con = file.path(out_dir, "kmeans_best_k_silhouette.txt")
)

elbow_plot <- fviz_nbclust(as.data.frame(X_sample_scaled), kmeans, method = "wss", k.max = k_max_elbow)
ggsave(file.path(out_dir, "elbow_plot.png"), plot = elbow_plot, width = 7, height = 5, dpi = 300)

# Seed stability (ARI)
seeds <- c(11, 22, 33, 44, 55)
clust_mat <- sapply(seeds, function(sd){
  set.seed(sd)
  kmeans(X_full_scaled, centers = k_final, nstart = 25)$cluster
})
ari <- outer(1:length(seeds), 1:length(seeds), Vectorize(function(i,j){
  adjustedRandIndex(clust_mat[,i], clust_mat[,j])
}))
colnames(ari) <- rownames(ari) <- paste0("seed_", seeds)
write.csv(ari, file.path(out_dir, "kmeans_seed_stability_ARI.csv"), row.names = TRUE)

# Fit final k-means
set.seed(123)
final_kmeans <- kmeans(X_full_scaled, centers = k_final, nstart = 25)
context_df_complete$SESU_ID <- final_kmeans$cluster

# Rasterize SESU_ID back to grid
r_sesu <- rast(template)
values(r_sesu) <- NA
names(r_sesu) <- "SESU_ID"
xy <- as.matrix(context_df_complete[, c("x","y")])
cells <- cellFromXY(r_sesu, xy)
r_sesu[cells] <- context_df_complete$SESU_ID

# cleaning
mode_fun <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
w <- matrix(1, 3, 3); w[2,2] <- 0
neigh_mode <- focal(r_sesu, w = w, fun = mode_fun, na.policy = "omit", fillvalue = NA)

same_count_fun <- function(x) {
  center <- x[5]
  nb <- x[-5]
  if (!is.finite(center)) return(NA_real_)
  nb <- nb[is.finite(nb)]
  if (length(nb) == 0) return(NA_real_)
  sum(nb == center)
}
same_count <- focal(r_sesu, w = matrix(1,3,3), fun = same_count_fun, na.policy = "omit", fillvalue = NA)
outlier <- !is.na(r_sesu) & !is.na(same_count) & (same_count <= 1) & !is.na(neigh_mode)

r_sesu_clean <- ifel(outlier, neigh_mode, r_sesu)
names(r_sesu_clean) <- "SESU_ID"

# Area diagnostics
tab_before <- as.data.frame(terra::freq(r_sesu)); tab_before <- tab_before[!is.na(tab_before$value),]
tab_after  <- as.data.frame(terra::freq(r_sesu_clean)); tab_after <- tab_after[!is.na(tab_after$value),]
tab_before$area_km2 <- tab_before$count * (target_res_m^2) / 1e6
tab_after$area_km2  <- tab_after$count  * (target_res_m^2) / 1e6
write.csv(tab_before, file.path(out_dir, "SESU_area_before_cleaning.csv"), row.names = FALSE)
write.csv(tab_after,  file.path(out_dir, "SESU_area_after_cleaning.csv"),  row.names = FALSE)

# Write SESU raster
writeRaster(
  r_sesu_clean,
  file.path(out_dir, paste0("SESU_ID_", target_res_m, "m.tif")),
  overwrite = TRUE,
  datatype = "INT2U"
)

# ===========================================================
# WRITE COVARIATE STACK
# ===========================================================
cov_stack <- c(
  base_stack,
  forest2000_30pct,
  accessibility,
  slope_masked,
  dist_to_water,
  metrics_stack,
  clim,
  soil,
  gov_stack
)

writeRaster(
  cov_stack,
  file.path(out_dir, paste0("SESU_covariates_", target_res_m, "m.tif")),
  overwrite = TRUE,
  datatype = "FLT4S"
)
