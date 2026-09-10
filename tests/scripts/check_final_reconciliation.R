library(data.table)
root <- "outputs/final_reconciliation"
d <- fread(file.path(root,"agriculture_counts_by_side_group_profile_year.csv"))
stopifnot(d[analysis=="first_crossing_full",sum(y)]==518,
 d[analysis=="persistence_corrected",sum(y)]==414,
 max(d[analysis=="persistence_corrected",year])==2019,
 max(d[analysis=="first_crossing_restricted",year])==2019,
 d[analysis=="annual_presence",sum(n)]==42554*22,
 d[analysis=="first_crossing_full" & side=="inside",sum(y)]==254,
 d[analysis=="first_crossing_full" & side=="outside",sum(y)]==264)
cc <- fread(file.path(root,"agriculture_cell_reconciliation.csv"))
stopifnot(nrow(cc)==2685,all(cc$matches),sum(cc$in_10km)==518)
surface <- fread(file.path(root,"agriculture_primary_surface_reconciliation.csv"))
stopifnot(all(surface$n_reconstructed==surface$n_primary),all(surface$y_reconstructed==surface$y_primary))
p <- fread(file.path(root,"agriculture_profile_estimates_hc3.csv"))
stopifnot(nrow(p)==12,all(is.finite(p$conf_low)),all(p$conf_low<p$conf_high))
m <- readRDS(file.path(root,"agriculture_models.rds"))
stopifnot(all(vapply(m$fits,function(f) f$model$rank==4,logical(1))))
rev <- fread(file.path(root,"agriculture_reversal_denominators.csv"))
stopifnot(all(rev$all_events==rev$eligible+rev$insufficient_followup+rev$missing_followup),
 rev[domain=="10km" & park_side=="inside",eligible]==236,
 rev[domain=="10km" & park_side=="outside",eligible]==227)
h <- fread(file.path(root,"postevent/hansen_loss_gain_overlap_overall.csv"))
stopifnot(h[corridor_domain=="full",loss_crossing_cells_by_2012]==2801,
 h[corridor_domain=="full",loss_crossing_cells_with_any_gain]==754,
 h[corridor_domain=="full",loss_crossing_cells_with_any_overlap]==599)
b <- fread(file.path(root,"agriculture_spatial_bootstrap_intervals.csv"))
stopifnot(nrow(b)==12,all(b$replicates==499))
r <- fread(file.path(root,"rainfall_fire/rainfall_fire_monthly_2021.csv"))
stopifnot(nrow(r)==24,uniqueN(r$month)==12,all(r$rain_observed_fraction==1),
 all(r$burned_area_km2<=r$observed_area_km2),
 all(abs(r$domain_area_km2-r$observed_area_km2-r$not_burnable_area_km2-r$missing_area_km2)<1e-6))
cat("Corrected results, unchanged primary sample, coverage and denominator checks passed.\n")
