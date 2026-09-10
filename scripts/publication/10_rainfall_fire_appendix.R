#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(terra); library(data.table); library(ggplot2)})
source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")
s <- fr_load_spatial()
out <- file.path(CH1_PROJECT_ROOT, "outputs/final_reconciliation/rainfall_fire")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
external <- file.path(CH1_DATA_ROOT, paste0("data/rainfall_fire_", Sys.getenv("UPEMBA_ILLUSTRATION_YEAR", "2021")))
year <- as.integer(Sys.getenv("UPEMBA_ILLUSTRATION_YEAR", "2021"))
stopifnot(year %in% c(2021L, 2022L))
# Earliest year with existing official monthly FireCCI JD+CL April-October
# inputs (2021, 2022). Complete that year with five public monthly products;
# The initial >=95% gate failed for both years. The documented amendment keeps
# better-covered 2021 with explicit missing-area bounds; no further acquisition.
domain <- s$sesu
v <- rep(NA_integer_, ncell(domain)); g <- fr_design_cells(s, 10)
v[g$cell] <- g$SESU_ID
values(domain) <- v
names(domain) <- "SESU_ID"
pol <- project(as.polygons(domain, dissolve = TRUE, na.rm = TRUE), "EPSG:4326")
resolve_fire <- function(month, layer) {
  stem <- sprintf("%d%02d01-ESACCI-L3S_FIRE-BA-MODIS-AREA_5-fv5.1", year, month)
  candidates <- c(file.path(external, paste0(stem, "-", layer, ".tif")),
    file.path(CH1_DATA_ROOT, "data/fire", stem, paste0(stem, "-", layer, ".tif")))
  p <- candidates[file.exists(candidates)][1]
  if (is.na(p)) stop("Missing complete-cycle input: ", stem, "-", layer)
  p
}
fire_files <- vapply(1:12, resolve_fire, character(1), layer = "JD")
confidence_files <- vapply(1:12, resolve_fire, character(1), layer = "CL")
rain_files <- file.path(external, sprintf("chirps-v2.0.%d.%02d.tif", year, 1:12))
stopifnot(all(file.exists(rain_files)))
crop_domain <- function(p) crop(rast(p), ext(pol), snap = "out")
fire_grid <- crop_domain(fire_files[1]); rain_grid <- crop_domain(rain_files[1])
weights_for <- function(grid) {
  area <- cellSize(grid, unit = "km", transform = TRUE)
  names(area) <- "area_km2"
  w <- as.data.table(extract(area, pol, cells = TRUE, exact = TRUE))
  w[, SESU_ID := values(pol)$SESU_ID[ID]]
  w[, weight_km2 := area_km2 * fraction]
  w
}
fw <- weights_for(fire_grid); rw <- weights_for(rain_grid)
rows <- vector("list", 12)
for (m in 1:12) {
  jd <- crop_domain(fire_files[m]); cl <- crop_domain(confidence_files[m]); rain <- crop_domain(rain_files[m])
  stopifnot(compareGeom(jd, fire_grid), compareGeom(cl, fire_grid), compareGeom(rain, rain_grid))
  f <- copy(fw); r <- copy(rw)
  f[, `:=`(jd = values(jd)[cell,1], confidence = values(cl)[cell,1])]
  r[, rain_mm := values(rain)[cell,1]]
  lo <- as.integer(format(as.Date(sprintf("%d-%02d-01", year, m)), "%j"))
  hi <- if (m == 12) 365L else as.integer(format(as.Date(sprintf("%d-%02d-01", year, m+1)), "%j")) - 1L
  # Each monthly pixel contributes at most once. Separate months may contain
  # distinct burns at the same pixel; no annual earliest-date collapse is used.
  stopifnot(!any(f$jd > 0 & (f$jd < lo | f$jd > hi), na.rm = TRUE))
  f[, observed := is.finite(jd) & jd >= 0 & jd <= 365 & is.finite(confidence) & confidence >= 1 & confidence <= 100]
  fs <- f[, .(domain_area_km2 = sum(weight_km2),
    observed_area_km2 = sum(weight_km2[observed]),
    not_burnable_area_km2 = sum(weight_km2[is.finite(jd) & jd == -2]),
    missing_area_km2 = sum(weight_km2[!observed & !(is.finite(jd) & jd == -2)]),
    burned_area_km2 = if (any(observed)) sum(weight_km2[observed & jd > 0]) else NA_real_), by = SESU_ID]
  fs[, `:=`(observed_fraction_of_burnable = observed_area_km2 / (domain_area_km2 - not_burnable_area_km2),
    burned_fraction_of_domain = burned_area_km2 / domain_area_km2)]
  rs <- r[, .(rainfall_mm = if (any(is.finite(rain_mm) & rain_mm >= 0)) weighted.mean(rain_mm[is.finite(rain_mm) & rain_mm >= 0], weight_km2[is.finite(rain_mm) & rain_mm >= 0]) else NA_real_,
    rain_observed_fraction = sum(weight_km2[is.finite(rain_mm) & rain_mm >= 0]) / sum(weight_km2)), by = SESU_ID]
  rows[[m]] <- merge(fs, rs, by = "SESU_ID")[, `:=`(year = year, month = m)]
}
tidy <- rbindlist(rows)
tidy[, landscape_group := fifelse(SESU_ID == 1L, "Depression", "Plateau")]
fwrite(tidy, file.path(out, sprintf("rainfall_fire_monthly_%d.csv", year)))
stopifnot(nrow(tidy) == 24L, all(is.finite(tidy$observed_fraction_of_burnable)), all(tidy$rain_observed_fraction >= .95))
# Neither available candidate met the initial 95% every-month target. Retain
# 2021 (minimum 93.99%, versus 71.92% in 2022), disclose missing area and show
# identification bounds rather than silently calling missing pixels unburned.
candidates <- rbindlist(lapply(c(2021, 2022), function(yy) fread(file.path(out, sprintf("rainfall_fire_monthly_%d.csv", yy)))[, .(year = yy, minimum_fire_coverage = min(observed_fraction_of_burnable), minimum_rain_coverage = min(rain_observed_fraction))]))
fwrite(candidates, file.path(out, "year_selection_coverage.csv"))
if (year == 2022L) {
  message("Second-year coverage audit complete; publication illustration remains 2021.")
  quit(save = "no", status = 0)
}
long <- melt(tidy, id.vars = c("year", "month", "landscape_group"), measure.vars = c("rainfall_mm", "burned_area_km2"), variable.name = "measure")
long[, measure := factor(measure, levels = c("rainfall_mm", "burned_area_km2"), labels = c("A   Rainfall (mm/month)", "B   Mapped burned area (km\u00b2/month)"))]
p <- ggplot(long, aes(month, value, fill = landscape_group)) +
  geom_col(width = .68, show.legend = FALSE) +
  geom_linerange(data = tidy[missing_area_km2 > 0][, measure := factor("B   Mapped burned area (km\u00b2/month)", levels = levels(long$measure))], aes(x = month, ymin = burned_area_km2, ymax = burned_area_km2 + missing_area_km2), inherit.aes = FALSE, colour = "grey35", linewidth = .5) +
  facet_grid(measure ~ landscape_group, scales = "free_y", switch = "y") +
  scale_fill_manual(values = c(Depression = "#416C8F", Plateau = "#B67B3F")) +
  scale_x_continuous(breaks = 1:12, labels = month.abb, expand = expansion(mult = c(.03,.03))) +
  scale_y_continuous(expand = expansion(mult = c(0,.08))) +
  labs(x = as.character(year), y = NULL) + theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    strip.background = element_blank(), strip.placement = "outside",
    axis.text.x = element_text(angle = 45, hjust = 1), plot.margin = margin(8,8,8,8))
ggsave(file.path(out, sprintf("Figure_S3_rainfall_fire_%d.pdf", year)), p, width = 7.1, height = 5.1, device = cairo_pdf)
ggsave(file.path(out, sprintf("Figure_S3_rainfall_fire_%d.png", year)), p, width = 7.1, height = 5.1, dpi = 600)
files <- c(fire_files, confidence_files, rain_files, s$cov_path, s$sesu_path)
fwrite(data.table(file = basename(files), bytes = file.info(files)$size,
  sha256 = vapply(files, function(p) digest::digest(file = p, algo = "sha256"), character(1))), file.path(out, "processing_input_checksums.csv"))
writeLines(c("# Figure S3. Seasonal rainfall and mapped burning in 2021",
  "Monthly rainfall and mapped burned area in the Depression and Plateau portions of the primary 10 km corridor on both sides of Upemba National Park's legal boundary (retained landscape groups 1 and 3). Panel A shows the area-weighted mean of CHIRPS v2.0 final monthly accumulated precipitation (mm); rainfall values are not summed across pixels. Panel B shows the area of native FireCCI51 pixels with a positive monthly detection date, weighted by their exact intersection with the same corridor (km²). WGS84 pixel areas and polygon-intersection fractions provide spatial weights. The area denominator for supplementary burned fractions is the entire group-specific corridor footprint. JD=-1 or invalid observations are missing; JD=-2 is non-burnable and is reported separately. Valid burnable pixels require JD=0 or a date in that month and confidence in 1–100; no additional confidence cutoff is imposed. A pixel contributes at most once per monthly composite; burns detected in different months can contribute repeatedly. Multiple burns within one monthly composite cannot be recovered. Detection dates may lag actual burning. All twelve months are unfiltered by seasonal DOY. The year was selected using monthly coverage among the two years with reusable official monthly inputs (2021–2022). Neither met the initial 95% every-group-month target; 2021 had higher minimum coverage (93.99% versus 71.92%) and is retained with explicit missing-area bounds. Rainfall coverage was complete; fire coverage exceeded 99.5% in every Depression month and 99.6% in Plateau months other than January (93.99%). Grey vertical ranges extend from mapped burned area to mapped burned plus missing area, bounding classification of unobserved pixels; they are not confidence intervals. Zero mapped area means no detected burning in observed pixels, not demonstrated absence in missing pixels. This single year illustrates seasonal co-occurrence, not causation, a long-term association or representative climatology. See rainfall_fire_monthly_2021.csv for monthly areas and coverage.",
  "", "Products: FireCCI51 (MODIS C6; monthly pixel JD and CL, Area 5); CHIRPS v2.0 final global monthly 0.05-degree precipitation. Calendar interval: 1 January–31 December 2021. Domain derives from the canonical 500 m SESU and signed-distance rasters, EPSG:32735; polygon intersections use EPSG:4326 with geodesic pixel areas.",
  "", "Sources: https://data.ceda.ac.uk/neodc/esacci/fire/data/burned_area/MODIS/pixel/v5.1/ ; https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_monthly/tifs/ ; https://www.chc.ucsb.edu/data/chirps ; FireCCI Product User Guide MODIS v1.1, 9 December 2021, sections 2.1 and 2.4.",
  "", "Reproduce: python scripts/acquisition/02_acquire_rainfall_fire_2021.py; Rscript --vanilla scripts/publication/10_rainfall_fire_appendix.R. Raw downloads remain under <UPEMBA_DATA_ROOT>/data/rainfall_fire_2021; April–October FireCCI inputs are reused from data/fire. Acquisition and processing manifests record versions and SHA-256 hashes.",
  "", capture.output(sessionInfo())), file.path(out, "figure_caption_and_provenance.md"))
