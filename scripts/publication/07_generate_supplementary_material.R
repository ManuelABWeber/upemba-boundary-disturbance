#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
})

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
OUT_ROOT <- file.path(ROOT, "outputs", "publication", "supplement")
OUT_TABLE <- file.path(OUT_ROOT, "tables")
OUT_FIG <- file.path(OUT_ROOT, "figures")
OUT_SRC <- file.path(OUT_ROOT, "source_data")
OUT_REPORT <- file.path(ROOT, "reports", "supplement")
for (p in c(OUT_ROOT, OUT_TABLE, OUT_FIG, OUT_SRC, OUT_REPORT)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

rel_path <- function(path) {
  gsub(
    paste0("^", gsub("([\\^$.|?*+(){}\\[\\]])", "\\\\\\1", ROOT), "/?"),
    "",
    normalizePath(path, winslash = "/", mustWork = FALSE)
  )
}

read_dt <- function(path, ...) {
  if (!file.exists(path)) stop("Missing required source: ", path, call. = FALSE)
  fread(path, ...)
}

raw_fragmented <- paste("Neither actor", "dominant")
raw_militia <- paste("Militia", "dominant")
raw_park <- paste("Park", "dominant")
profile_map <- c("Fragmented control", "Militia-centred control", "Park-centred control")
names(profile_map) <- c(raw_fragmented, raw_militia, raw_park)
outcome_map <- c(
  deforestation = "Tree-cover loss",
  tree_cover_loss = "Tree-cover loss",
  fire = "Fire",
  agriculture = "Agricultural expansion"
)
pair_map <- c("Militia-centred - Fragmented", "Park-centred - Fragmented", "Park-centred - Militia-centred")
names(pair_map) <- c(
  paste(raw_militia, "minus", raw_fragmented),
  paste(raw_park, "minus", raw_fragmented),
  paste(raw_park, "minus", raw_militia)
)
profile_order <- c("Fragmented control", "Militia-centred control", "Park-centred control")
outcome_order <- c("Tree-cover loss", "Fire", "Agricultural expansion")

map_profile <- function(x) {
  y <- unname(profile_map[x])
  y[is.na(y)] <- x[is.na(y)]
  y
}
map_outcome <- function(x) {
  y <- unname(outcome_map[x])
  y[is.na(y)] <- x[is.na(y)]
  y
}
map_pair <- function(x) {
  y <- unname(pair_map[x])
  y[is.na(y)] <- x[is.na(y)]
  y
}
map_pair_long <- function(x) {
  y <- map_pair(x)
  fcase(
    y %in% c("Militia-centred - Fragmented", "Militia-centred control minus Fragmented control"), "Militia-centred control minus Fragmented control",
    y %in% c("Park-centred - Fragmented", "Park-centred control minus Fragmented control"), "Park-centred control minus Fragmented control",
    y %in% c("Park-centred - Militia-centred", "Park-centred control minus Militia-centred control"), "Park-centred control minus Militia-centred control",
    default = y
  )
}
landscape_label <- function(x) {
  fifelse(x == 1, "Depression", fifelse(x == 3, "Plateau", "Outside inferential scope"))
}

inputs <- list(
  fig3_profile = file.path(ROOT, "outputs/publication/figure_source_data/Figure_3_profile_contrasts.csv"),
  fig3_pair = file.path(ROOT, "outputs/publication/figure_source_data/Figure_3_pairwise_differences.csv"),
  fig4_profile = file.path(ROOT, "outputs/publication/figure_source_data/Figure_4_profile_boundary_estimates.csv"),
  fig4_pair = file.path(ROOT, "outputs/publication/figure_source_data/Figure_4_pairwise_boundary_estimates.csv"),
  spatial_design = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/spatial_design_decision_matrix.csv"),
  balance = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/covariate_balance_summary.csv"),
  event_support = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/event_support_summary.csv"),
  threshold_profile = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/spatial_threshold_contrast_comparison.csv"),
  threshold_pair = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/spatial_threshold_pairwise_comparison.csv"),
  fire_threshold_profile = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/fire_profile_contrasts.csv"),
  sparse_threshold_profile = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/sparse_outcome_profile_estimates.csv"),
  sparse_threshold_pair = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/sparse_outcome_pairwise_differences.csv"),
  fire_optimizer = file.path(ROOT, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_diagnostics.csv"),
  retained_fire = file.path(ROOT, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_retained_fits.csv"),
  boundary_profile_fire = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/fire_boundary_profile_contrasts.csv"),
  boundary_pair_fire = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/fire_boundary_pairwise_differences.csv"),
  boundary_profile_sparse = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_profile_estimates.csv"),
  boundary_pair_sparse = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_pairwise_differences.csv"),
  boundary_class = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/boundary_specificity_classification.csv"),
  boundary_surface = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv"),
  boundary_registry = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/revised_boundary_registry.csv"),
  profile_support = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/profile_model_support_corrected.csv"),
  episode_support = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/profile_episode_support_corrected.csv"),
  governance_transitions = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/governance_transitions.csv"),
  governance_ledger = file.path(ROOT, "evidence/governance_episode_evidence_ledger.csv"),
  chronology = file.path(ROOT, "data/upemba_sesu_year_regimes.csv"),
  robustness_summary = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/governance_profile_robustness_summary.csv"),
  transition_profile = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/transition_sensitivity_profile_contrasts.csv"),
  transition_pair = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/transition_sensitivity_pairwise_differences.csv"),
  loo_profile = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/leave_one_episode_out_profile_contrasts.csv"),
  loo_pair = file.path(ROOT, "analysis_governance_profiles_robustness_dev/tables/leave_one_episode_out_pairwise_differences.csv"),
  silhouette_full = file.path(ROOT, "reports/methods_review_targeted_audits/clustering_silhouette_profile_full.csv"),
  no_access_silhouette = file.path(ROOT, "reports/methods_review_final_audits/no_accessibility_silhouette_profile.csv"),
  no_access_k3 = file.path(ROOT, "reports/methods_review_final_audits/no_accessibility_k3_comparison.csv"),
  no_access_selected = file.path(ROOT, "reports/methods_review_final_audits/no_accessibility_selected_k_comparison.csv"),
  no_access_seed = file.path(ROOT, "reports/methods_review_final_audits/no_accessibility_seed_stability.csv"),
  no_access_support = file.path(ROOT, "reports/methods_review_final_audits/no_accessibility_cluster_support.csv"),
  sesu2_support = file.path(ROOT, "reports/methods_review_targeted_audits/sesu2_support_by_spatial_design.csv"),
  sesu2_events = file.path(ROOT, "reports/methods_review_targeted_audits/sesu2_event_support.csv"),
  missingness_decision = file.path(ROOT, "reports/fire_missingness_resolution/fire_missingness_final_decision.csv"),
  missingness_summary = file.path(ROOT, "reports/fire_missingness_resolution/fire_missingness_summary.csv"),
  publication_validation = file.path(ROOT, "reports/publication_outputs/publication_output_validation.md")
)

theme_supp <- function() {
  theme_minimal(base_size = 8, base_family = "sans") +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey88", linewidth = 0.25),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

save_fig <- function(plot, name, w = 180, h = 130) {
  ggsave(file.path(OUT_FIG, paste0(name, ".pdf")), plot, width = w / 25.4, height = h / 25.4, device = cairo_pdf, bg = "white")
  ggsave(file.path(OUT_FIG, paste0(name, ".png")), plot, width = w / 25.4, height = h / 25.4, dpi = 450, bg = "white")
}

html_escape <- function(x) {
  gsub("<", "&lt;", gsub(">", "&gt;", gsub("&", "&amp;", as.character(x))))
}

html_table <- function(dt, title, caption = NULL, max_rows = Inf) {
  shown <- if (nrow(dt) > max_rows) dt[seq_len(max_rows)] else dt
  hdr <- paste0("<tr>", paste0("<th>", html_escape(names(shown)), "</th>", collapse = ""), "</tr>")
  rows <- apply(shown, 1, function(z) paste0("<tr>", paste0("<td>", html_escape(z), "</td>", collapse = ""), "</tr>"))
  note <- if (nrow(dt) > max_rows) {
    sprintf("<p><em>Showing first %d of %d rows; full table is in the CSV file.</em></p>", max_rows, nrow(dt))
  } else ""
  paste0(
    "<h3>", html_escape(title), "</h3>",
    if (!is.null(caption)) paste0("<p>", html_escape(caption), "</p>") else "",
    note,
    "<table>", hdr, paste(rows, collapse = "\n"), "</table>"
  )
}

sanitize_table_text <- function(dt) {
  out <- copy(as.data.table(dt))
  text_cols <- names(out)[vapply(out, function(x) is.character(x) || is.factor(x), logical(1))]
  for (col in text_cols) {
    vals <- as.character(out[[col]])
    vals <- gsub(raw_fragmented, "Fragmented control", vals, fixed = TRUE)
    vals <- gsub(raw_militia, "Militia-centred control", vals, fixed = TRUE)
    vals <- gsub(raw_park, "Park-centred control", vals, fixed = TRUE)
    set(out, j = col, value = vals)
  }
  out
}

write_table <- function(dt, number, title, caption, source_files, transformation, notes = "") {
  dt <- sanitize_table_text(dt)
  item <- sprintf("Table S%d", number)
  outfile <- file.path(OUT_TABLE, sprintf("Table_S%02d_%s.csv", number, gsub("[^A-Za-z0-9]+", "_", tolower(title))))
  fwrite(dt, outfile)
  list(item = item, title = title, caption = caption, file = outfile, source_files = source_files, transformation = transformation, notes = notes)
}

label_design <- function(x) {
  fcase(
    x == "all_cells", "All cells",
    x == "buffer_05km", "5 km",
    x == "buffer_10km", "10 km",
    x == "buffer_20km", "20 km",
    default = x
  )
}

threshold_label <- function(x) {
  fcase(x == "tau010", "10%", x == "tau025", "25%", x == "tau050", "50%", default = x)
}

apply_primary_fire_values <- function(dt, f3p, f3q, threshold_col = "Threshold", domain_col = NULL) {
  out <- copy(dt)
  in_scope <- out$Outcome == "Fire"
  if (!is.null(threshold_col)) in_scope <- in_scope & out[[threshold_col]] %in% c("25%", "tau025")
  if (!is.null(domain_col)) in_scope <- in_scope & out[[domain_col]] %in% c("10 km", "Symmetric 10 km boundary corridor")
  prof_ref <- f3p[outcome == "fire", .(
    `Profile or comparison` = map_profile(profile_or_comparison),
    Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95, `Upper 95%` = upper_95,
    `Fit validity` = fit_validity
  )]
  pair_ref <- f3q[outcome == "fire", .(
    `Profile or comparison` = map_pair_long(profile_or_comparison),
    Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95, `Upper 95%` = upper_95,
    `Fit validity` = fit_validity
  )]
  ref <- rbindlist(list(
    prof_ref[, `Estimand type` := "Profile contrast"],
    pair_ref[, `Estimand type` := "Pairwise difference"]
  ), fill = TRUE)
  for (i in seq_len(nrow(ref))) {
    hit <- in_scope & out$`Estimand type` == ref$`Estimand type`[i] & out$`Profile or comparison` == ref$`Profile or comparison`[i]
    if (any(hit)) {
      out[hit, `:=`(
        Estimate = ref$Estimate[i],
        SE = ref$SE[i],
        `Lower 95%` = ref$`Lower 95%`[i],
        `Upper 95%` = ref$`Upper 95%`[i],
        `Fit validity` = ref$`Fit validity`[i]
      )]
    }
  }
  out
}

make_tables <- function() {
  out <- list()

  out[[1]] <- write_table(data.table(
    Covariate = c("Elevation", "Slope", "Baseline forest indicator", "Distance to permanent water", "Mean annual precipitation", "Potential evapotranspiration", "Actual evapotranspiration", "Water balance", "Aridity", "Soil organic carbon", "Soil pH", "Clay", "Sand", "Distance to baseline built-up areas", "Travel time to cities"),
    `Source product` = c("Copernicus DEM GLO-30", "Derived from Copernicus DEM GLO-30 in R", "Hansen Global Forest Change v1.12 tree cover in 2000", "JRC Global Surface Water v1.4", "CHIRPS daily precipitation", "TerraClimate", "TerraClimate", "CHIRPS precipitation minus TerraClimate PET", "P / (PET + 1), using CHIRPS precipitation and TerraClimate PET", "SoilGrids 0-30 cm depth-weighted SOC", "SoilGrids 0-30 cm depth-weighted pH", "SoilGrids 0-30 cm depth-weighted clay", "SoilGrids 0-30 cm depth-weighted sand", "GHSL P2023A built-up surface", "Oxford/MAP accessibility_to_cities_2015_v1_0"),
    `Reference period` = c("static", "static", "2000", "permanent water from seasonality = 12 or occurrence >=90%", "1981-2010 annual mean", "1981-2010 annual mean", "1981-2010 annual mean", "1981-2010 annual mean", "1981-2010 annual mean", "static", "static", "static", "static", "baseline 2000-or-earlier", "2015"),
    `Native resolution` = c("30 m", "derived 30 m", "30 m", "30 m", "approximately 5 km", "approximately 4 km", "approximately 4 km", "derived", "derived", "250 m", "250 m", "250 m", "250 m", "100 m", "approximately 1 km"),
    `500 m processing` = c("mean elevation on canonical grid", "terrain slope derived then aggregated to canonical grid", "binary >=30% baseline-forest indicator on canonical grid", "distance to permanent-water mask on canonical grid", "annual means aggregated to canonical grid", "annual means aggregated to canonical grid", "annual means aggregated to canonical grid", "derived after climate processing on canonical grid", "derived after climate processing on canonical grid", "depth-weighted mean aggregated to canonical grid", "depth-weighted mean aggregated to canonical grid", "depth-weighted mean aggregated to canonical grid", "depth-weighted mean aggregated to canonical grid", "distance to baseline built-up surface on canonical grid", "travel-time surface aggregated to canonical grid"),
    Transformation = c("standardized", "standardized", "binary indicator", "distance transformed where skewed, then standardized", "standardized", "standardized", "standardized", "standardized", "standardized", "standardized", "standardized", "standardized", "standardized", "distance transformed where skewed, then standardized", "transformed where skewed, then standardized"),
    `Analytical role` = "landscape comparison-group clustering covariate"
  ), 1, "Landscape comparison covariates", "Covariates used to construct the frozen landscape comparison groups.", "Methods reporting facts and clustering scripts", "curated Methods summary")

  sil <- read_dt(inputs$silhouette_full)
  if (!"selected" %in% names(sil)) {
    selected_k <- sil[which.max(sil[[grep("silhouette", names(sil), value = TRUE)[1]]]), k]
    sil[, selected := k == selected_k]
  }
  setnames(sil, grep("silhouette", names(sil), value = TRUE)[1], "mean silhouette width")
  if (!"sample size" %in% names(sil)) sil[, `sample size` := 20000L]
  if (!"sample seed" %in% names(sil)) sil[, `sample seed` := 42L]
  out[[2]] <- write_table(sil[, .(k, `mean silhouette width`, `sample size`, `sample seed`, selected)], 2, "Clustering solution selection", "Mean silhouette width for k = 2-15.", inputs$silhouette_full, "renamed columns and added fixed sample metadata")

  near <- read_dt(file.path(ROOT, "reports/methods_review_final_audits/clustering_near_reproduction_discrepancies.csv"))
  k3 <- read_dt(inputs$no_access_k3)
  seed <- read_dt(inputs$no_access_seed)
  t3 <- data.table(
    Metric = c("Authoritative near-reproduction ARI", "Full label-matched agreement", "10 km agreement", "Differing cells", "Differing cells (%)", "No-accessibility selected k", "No-accessibility k = 3 ARI", "No-accessibility full agreement", "No-accessibility 10 km agreement", "Retained group identity", "Outcome-model rerun triggered", "Seed-stability rows"),
    Value = c("0.99723575428417", "99.9074%", "99.8820%", as.character(nrow(near)), sprintf("%.4f%%", 100 * nrow(near) / 248000), as.character(read_dt(inputs$no_access_selected)$selected_k[1]), as.character(k3$adjusted_rand_index[1]), as.character(k3$full_landscape_agreement[1]), as.character(k3$primary_10km_agreement[1]), "Depression and Plateau retained", "No", as.character(nrow(seed)))
  )
  out[[3]] <- write_table(t3, 3, "Clustering stability and accessibility sensitivity", "Near-reproduction and no-accessibility sensitivity diagnostics.", paste(inputs$no_access_k3, inputs$no_access_selected, inputs$no_access_seed, sep = "; "), "summarized final clustering audits")

  sd <- read_dt(inputs$spatial_design)
  es <- read_dt(inputs$event_support)[threshold_tag == "tau025", .(events = sum(total_events, na.rm = TRUE)), by = .(spatial_design, outcome)]
  es_wide <- dcast(es, spatial_design ~ outcome, value.var = "events", fill = NA_integer_)
  setnames(es_wide, c("agriculture", "fire", "tree_cover_loss"), c("events_agriculture_tau025", "events_fire_tau025", "events_tree_cover_loss_tau025"), skip_absent = TRUE)
  actual_surface <- read_dt(inputs$boundary_surface)[boundary_id == "actual_c000" & threshold_tag == "tau025"]
  actual_totals <- actual_surface[, .(events = sum(y, na.rm = TRUE)), by = outcome]
  sd <- merge(sd, es_wide, by = "spatial_design", all.x = TRUE)
  sd[spatial_design == "buffer_10km", `:=`(
    events_fire_tau025 = actual_totals[outcome == "fire", events],
    events_tree_cover_loss_tau025 = actual_totals[outcome == "tree_cover_loss", events],
    events_agriculture_tau025 = actual_totals[outcome == "agriculture", events]
  )]
  out[[4]] <- write_table(sd[, .(
    design = label_design(spatial_design),
    `inside cells` = inside_cell_count,
    `outside cells` = outside_cell_count,
    `median absolute SMD` = median_abs_smd,
    `maximum absolute SMD` = max_abs_smd,
    `tau025 fire events` = events_fire_tau025,
    `tau025 tree-cover-loss events` = events_tree_cover_loss_tau025,
    `tau025 agricultural-expansion events` = events_agriculture_tau025,
    `fire fit status` = fifelse(strict_valid_fire_fits > 0, "strict-valid fit available", "no strict-valid fit in spatial-design screen"),
    `sparse-outcome support status` = "two-stage sparse-outcome support assessed",
    `design role` = fifelse(spatial_design == "buffer_10km", "primary spatial estimand", "sensitivity or support diagnostic")
  )], 4, "Spatial-design balance and event support", "Tau025 balance and event support across candidate spatial designs.", paste(inputs$spatial_design, inputs$event_support, inputs$boundary_surface, sep = "; "), "joined design balance to tau025 event support; final actual-boundary surface used for 10 km primary totals")

  support_geom <- read_dt(inputs$sesu2_support)[spatial_design == "buffer_10km"]
  surface_side <- actual_surface[, .(events = sum(y, na.rm = TRUE)), by = .(SESU_ID, outcome, side)]
  surface_side[, outcome := map_outcome(outcome)]
  ev_side <- dcast(surface_side, SESU_ID ~ outcome + side, value.var = "events", fill = 0)
  t5 <- merge(support_geom, ev_side, by = "SESU_ID", all.x = TRUE)
  ev2 <- read_dt(inputs$sesu2_events)[spatial_design == "buffer_10km"]
  ev2[, outcome := map_outcome(outcome)]
  ev2_wide <- dcast(ev2[, .(events = sum(total_events, na.rm = TRUE)), by = .(SESU_ID, outcome, side)], SESU_ID ~ outcome + side, value.var = "events", fill = NA_integer_)
  t5 <- merge(t5, ev2_wide, by = "SESU_ID", all.x = TRUE, suffixes = c("", "_support_audit"))
  for (nm in names(t5)[grepl("_support_audit$", names(t5))]) {
    base <- sub("_support_audit$", "", nm)
    if (base %in% names(t5)) t5[is.na(get(base)), (base) := get(nm)]
  }
  t5[, `:=`(
    `Landscape group` = landscape_label(SESU_ID),
    `Included in primary inference` = SESU_ID %in% c(1L, 3L),
    `Exclusion rationale` = fifelse(SESU_ID == 2L, "Small and spatially restricted park-interior support; no frozen pre-outcome territorial-control chronology for primary inference.", "")
  )]
  t5[SESU_ID == 2L, `Landscape group` := "SESU2 / Lufira Plain (outside inferential scope)"]
  pick_col <- function(dt, candidates) {
    found <- candidates[candidates %in% names(dt)]
    if (!length(found)) return(rep(NA_integer_, nrow(dt)))
    out <- dt[[found[1]]]
    if (length(found) > 1L) {
      for (nm in found[-1]) {
        out[is.na(out)] <- dt[[nm]][is.na(out)]
      }
    }
    out
  }
  t5_render <- t5[, .(
    `Landscape group`, inside_cells, outside_cells, inside_to_outside_cell_ratio,
    `Agricultural expansion outside` = pick_col(.SD, c("Agricultural expansion_exterior_facing", "Agricultural expansion_outside", "Agricultural expansion_outside_support_audit")),
    `Agricultural expansion inside` = pick_col(.SD, c("Agricultural expansion_interior_facing", "Agricultural expansion_inside", "Agricultural expansion_inside_support_audit")),
    `Fire outside` = pick_col(.SD, c("Fire_exterior_facing", "Fire_outside", "Fire_outside_support_audit")),
    `Fire inside` = pick_col(.SD, c("Fire_interior_facing", "Fire_inside", "Fire_inside_support_audit")),
    `Tree-cover loss outside` = pick_col(.SD, c("Tree-cover loss_exterior_facing", "Tree-cover loss_outside", "Tree-cover loss_outside_support_audit")),
    `Tree-cover loss inside` = pick_col(.SD, c("Tree-cover loss_interior_facing", "Tree-cover loss_inside", "Tree-cover loss_inside_support_audit")),
    `Included in primary inference`,
    `Exclusion rationale`
  ), by = SESU_ID]
  out[[5]] <- write_table(t5_render[, -c("SESU_ID")], 5, "Landscape-group and side support", "Support in the final tau025 10 km actual-boundary surface; SESU2 counts are descriptive and are not added to retained-group primary totals.", paste(inputs$sesu2_support, inputs$sesu2_events, inputs$boundary_surface, sep = "; "), "joined final actual-boundary support and SESU2 support-audit counts")
  old_fire_total <- 502571L
  corrected_fire <- actual_surface[outcome == "fire" & SESU_ID %in% c(1L, 3L), sum(y, na.rm = TRUE)]
  writeLines(c(
    "# Table S5 Fire Reconciliation",
    "",
    sprintf("Old retained-group fire total noted during review: %s.", old_fire_total),
    sprintf("Final retained-group fire total from `%s`: %s.", rel_path(inputs$boundary_surface), corrected_fire),
    "",
    "Source of discrepancy: the previous supplement draft drew group-side support from the SESU2 support audit and related development support tables rather than the final harmonized tau025 actual-boundary surface. Those support tables were not the authoritative source for the manuscript primary fire total.",
    "",
    "Corrected source file: `analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv`, filtered to `boundary_id = actual_c000`, `threshold_tag = tau025`, and retained SESU1/SESU3 groups.",
    "",
    "Corrected group-side totals are reported in Table S5."
  ), file.path(OUT_REPORT, "table_s5_fire_reconciliation.md"))

  ledger <- read_dt(inputs$governance_ledger, encoding = "UTF-8")
  if (!all(ledger$`Researcher review required` == "No")) stop("Governance ledger is not approved for Table S6B.", call. = FALSE)
  s6a <- ledger[, .(Year = seq(`Start year`, `End year`)), by = .(`Landscape group`, `Episode ID`, `Territorial-control profile` = Profile)]
  s6a <- s6a[, .(Panel = "S6A annual profile assignment", `Landscape group`, Year, `Territorial-control profile`, `Episode ID`)]
  s6b <- ledger[, .(
    Panel = "S6B historical episode evidence",
    `Landscape group`, Year = paste(`Start year`, `End year`, sep = "-"),
    `Territorial-control profile` = Profile,
    `Episode ID`,
    `Operational interpretation`,
    `Key documented events`,
    `Primary evidence sources`,
    `Transition rationale`,
    `Coding confidence`,
    `Alternative plausible transition years`,
    `Source manuscript location`
  )]
  fwrite(s6a, file.path(OUT_SRC, "Table_S06A_annual_profile_assignments.csv"))
  fwrite(s6b, file.path(OUT_SRC, "Table_S06B_approved_episode_evidence.csv"))
  out[[6]] <- write_table(rbindlist(list(s6a, s6b), fill = TRUE), 6, "Territorial-control chronology", "Panel S6A gives annual frozen profile assignments; Panel S6B gives the approved episode evidence ledger.", inputs$governance_ledger, "used approved governance episode evidence ledger verbatim except for panel formatting")

  ps <- unique(read_dt(inputs$profile_support)[, .(
    profile = map_profile(governance_profile),
    `landscape-group years` = n_sesu_years,
    `calendar years` = n_calendar_years,
    `distinct historical episodes` = n_episodes,
    `Depression years` = sesu1_unique_sesu_years,
    `Plateau years` = sesu3_unique_sesu_years
  )])
  out[[7]] <- write_table(ps, 7, "Profile and episode support", "Landscape-year, calendar-year, and episode support for each territorial-control profile.", inputs$profile_support, "deduplicated support metrics and mapped labels")

  f3p <- read_dt(inputs$fig3_profile)
  f3p[, `:=`(Outcome = map_outcome(outcome), Profile = profile_or_comparison)]
  event_totals <- c("Tree-cover loss" = 519L, Fire = 508320L, "Agricultural expansion" = 518L)
  t8 <- f3p[, .(Outcome, Profile, Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95, `Upper 95%` = upper_95, Model = model, Events = event_totals[Outcome], `Spatial domain` = spatial_domain, Threshold = threshold, `Fit validity` = fit_validity)]
  out[[8]] <- write_table(t8, 8, "Primary profile-specific contrasts", "Exact unrounded primary profile-specific contrasts.", inputs$fig3_profile, "selected source-data columns")

  f3q <- read_dt(inputs$fig3_pair)
  f3q[, `:=`(Outcome = map_outcome(outcome), Comparison = profile_or_comparison)]
  t9 <- f3q[, .(Outcome, Comparison, Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95, `Upper 95%` = upper_95, Model = model, `Spatial domain` = spatial_domain, Threshold = threshold, `Fit validity` = fit_validity)]
  out[[9]] <- write_table(t9, 9, "Primary pairwise profile differences", "Exact unrounded primary pairwise differences between profile contrasts.", inputs$fig3_pair, "selected source-data columns")

  sp_prof <- read_dt(inputs$sparse_threshold_profile)[threshold_tag == "tau025" & spatial_design == "buffer_10km"]
  sp_pair <- read_dt(inputs$sparse_threshold_pair)[threshold_tag == "tau025" & spatial_design == "buffer_10km"]
  t10 <- rbindlist(list(
    sp_prof[, .(Outcome = map_outcome(outcome), Weighting = fifelse(grepl("unweighted", model_type), "Unweighted", "Weighted"), Estimand = "Profile contrast", `Profile or comparison` = map_profile(governance_profile), Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci)],
    sp_pair[, .(Outcome = map_outcome(outcome), Weighting = fifelse(grepl("unweighted", model_type), "Unweighted", "Weighted"), Estimand = "Pairwise difference", `Profile or comparison` = map_pair(profile_comparison), Estimate = estimate, SE = standard_error, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci)]
  ), fill = TRUE)
  t10[, `Interpretive change from primary` := fifelse(Weighting == "Weighted", "primary specification", "sensitivity only")]
  out[[10]] <- write_table(t10, 10, "Weighted and unweighted sparse-outcome models", "Sparse-outcome weighted primary and unweighted sensitivity estimates.", paste(inputs$sparse_threshold_profile, inputs$sparse_threshold_pair, sep = "; "), "filtered tau025 10 km sparse-outcome estimates")

  source(file.path(ROOT, "scripts/lib/refined_fire_publication.R"))
  stp <- publication_refined_fire(read_dt(inputs$threshold_profile), root = ROOT)
  stq <- publication_refined_fire(read_dt(inputs$threshold_pair), pairwise = TRUE, root = ROOT)
  es_all <- read_dt(inputs$event_support)
  event_lookup <- es_all[, .(`Event support` = sum(total_events, na.rm = TRUE)), by = .(outcome, threshold_tag, spatial_design)]
  event_lookup[threshold_tag == "tau025" & spatial_design == "buffer_10km" & outcome == "fire", `Event support` := 508320L]
  threshold_label <- function(x) fcase(x == "tau010", "10%", x == "tau025", "25%", x == "tau050", "50%", default = x)
  t11 <- rbindlist(list(
    stp[spatial_design == "buffer_10km", .(Outcome = map_outcome(outcome), Threshold = threshold_label(threshold_tag), `Estimand type` = "Profile contrast", `Profile or comparison` = map_profile(governance_profile), Estimate = estimate, SE = NA_real_, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, `Event support` = NA_integer_, Model = method, `Fit validity` = fifelse(grepl("fire", method), "see fire optimizer diagnostics", "accepted two-stage estimate"), Interpretation = fifelse(threshold_tag == "tau025", "primary threshold", "threshold sensitivity"), outcome, threshold_tag, spatial_design)],
    stq[spatial_design == "buffer_10km", .(Outcome = map_outcome(outcome), Threshold = threshold_label(threshold_tag), `Estimand type` = "Pairwise difference", `Profile or comparison` = map_pair_long(profile_comparison), Estimate = estimate, SE = NA_real_, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, `Event support` = NA_integer_, Model = method, `Fit validity` = fifelse(grepl("fire", method), "see fire optimizer diagnostics", "accepted two-stage estimate"), Interpretation = fifelse(threshold_tag == "tau025", "primary threshold", "threshold sensitivity"), outcome, threshold_tag, spatial_design)]
  ), fill = TRUE)
  t11 <- merge(t11, event_lookup, by = c("outcome", "threshold_tag", "spatial_design"), all.x = TRUE, suffixes = c("", "_lookup"))
  t11[is.na(`Event support`), `Event support` := `Event support_lookup`]
  t11 <- t11[, .(Outcome, Threshold, `Estimand type`, `Profile or comparison`, Estimate, SE, `Lower 95%`, `Upper 95%`, `Event support`, Model, `Fit validity`, Interpretation)]
  t11 <- apply_primary_fire_values(t11, f3p, f3q, threshold_col = "Threshold")
  out[[11]] <- write_table(t11, 11, "Threshold sensitivity", "Profile and pairwise threshold sensitivities for the symmetric 10 km domain only.", paste(inputs$threshold_profile, inputs$threshold_pair, inputs$event_support, sep = "; "), "filtered to 10 km and primary/sensitivity thresholds")

  t12 <- rbindlist(list(
    stp[threshold_tag == "tau025", .(Outcome = map_outcome(outcome), `Spatial domain` = label_design(spatial_design), `Estimand type` = "Profile contrast", `Profile or comparison` = map_profile(governance_profile), Estimate = estimate, SE = NA_real_, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, `Event support` = NA_integer_, Model = method, `Fit validity` = fifelse(grepl("fire", method), "see fire diagnostics", "accepted two-stage estimate"), Interpretation = fifelse(spatial_design == "buffer_10km", "primary spatial estimand", "spatial-domain sensitivity"), outcome, threshold_tag, spatial_design)],
    stq[threshold_tag == "tau025", .(Outcome = map_outcome(outcome), `Spatial domain` = label_design(spatial_design), `Estimand type` = "Pairwise difference", `Profile or comparison` = map_pair_long(profile_comparison), Estimate = estimate, SE = NA_real_, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, `Event support` = NA_integer_, Model = method, `Fit validity` = fifelse(grepl("fire", method), "see fire diagnostics", "accepted two-stage estimate"), Interpretation = fifelse(spatial_design == "buffer_10km", "primary spatial estimand", "spatial-domain sensitivity"), outcome, threshold_tag, spatial_design)]
  ), fill = TRUE)
  t12 <- merge(t12, event_lookup, by = c("outcome", "threshold_tag", "spatial_design"), all.x = TRUE, suffixes = c("", "_lookup"))
  t12[spatial_design == "buffer_10km" & outcome == "fire", `Event support_lookup` := 508320L]
  t12[is.na(`Event support`), `Event support` := `Event support_lookup`]
  t12 <- t12[, .(Outcome, `Spatial domain`, `Estimand type`, `Profile or comparison`, Estimate, SE, `Lower 95%`, `Upper 95%`, `Event support`, Model, `Fit validity`, Interpretation)]
  t12 <- apply_primary_fire_values(t12, f3p, f3q, threshold_col = NULL, domain_col = "Spatial domain")
  out[[12]] <- write_table(t12, 12, "Spatial-domain sensitivity", "Profile and pairwise spatial-domain sensitivities for tau025 only.", paste(inputs$threshold_profile, inputs$threshold_pair, inputs$event_support, sep = "; "), "filtered to tau025 and spatial domains")

  rob <- read_dt(inputs$robustness_summary)
  rob[, `:=`(Outcome = map_outcome(disturbance), Profile = map_profile(governance_profile))]
  t13a <- rbindlist(list(
    rob[, .(Outcome, `Landscape group` = "Depression", Profile, Estimate = SESU1_estimate, `Lower 95%` = NA_real_, `Upper 95%` = NA_real_, `Model/domain` = "landscape-specific complete-landscape diagnostic", Interpretation = inferential_status)],
    rob[, .(Outcome, `Landscape group` = "Plateau", Profile, Estimate = SESU3_estimate, `Lower 95%` = NA_real_, `Upper 95%` = NA_real_, `Model/domain` = "landscape-specific complete-landscape diagnostic", Interpretation = inferential_status)]
  ), fill = TRUE)
  trans <- read_dt(inputs$transition_profile)
  trans[, `:=`(Outcome = map_outcome(disturbance), Profile = map_profile(governance_profile))]
  loo <- read_dt(inputs$loo_profile)
  loo[, `:=`(Outcome = map_outcome(disturbance), Profile = map_profile(governance_profile))]
  t13_full <- rbindlist(list(
    t13a[, .(Outcome, `Diagnostic type` = "landscape-specific estimates", Scenario = `Landscape group`, `Profile or comparison` = Profile, Estimate, `Lower 95%`, `Upper 95%`, Domain = `Model/domain`, `Model implementation` = Interpretation, Interpretation = "landscape-specific diagnostic; not primary")],
    trans[, .(Outcome, `Diagnostic type` = "transition-year shift", Scenario = scenario_id, `Profile or comparison` = Profile, Estimate = estimate, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, Domain = "complete landscape diagnostic", `Model implementation` = optimizer_config, Interpretation = "sensitivity only")],
    loo[, .(Outcome, `Diagnostic type` = "leave-one-episode-out", Scenario = scenario_id, `Profile or comparison` = Profile, Estimate = estimate, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci, Domain = "complete landscape diagnostic", `Model implementation` = optimizer_config, Interpretation = "sensitivity only")]
  ), fill = TRUE)
  fwrite(sanitize_table_text(t13_full), file.path(OUT_SRC, "Table_S13_full_historical_diagnostics.csv"))
  ref <- t13_full[`Diagnostic type` == "landscape-specific estimates", .(`Reference complete-landscape estimate` = Estimate[1]), by = .(Outcome, `Profile or comparison`)]
  ranges <- t13_full[`Diagnostic type` != "landscape-specific estimates", .(
    `Number of valid scenarios` = sum(is.finite(Estimate)),
    `Minimum scenario estimate` = min(Estimate, na.rm = TRUE),
    `Maximum scenario estimate` = max(Estimate, na.rm = TRUE),
    `Intervals available` = any(is.finite(`Lower 95%`) & is.finite(`Upper 95%`))
  ), by = .(Outcome, `Profile or comparison`)]
  t13b <- merge(ref, ranges, by = c("Outcome", "Profile or comparison"), all.x = TRUE)
  t13b[, `:=`(
    `Diagnostic type` = "complete-landscape historical sensitivity summary",
    `Sign retained in all valid scenarios` = fcase(
      `Reference complete-landscape estimate` > 0, `Minimum scenario estimate` > 0 & `Maximum scenario estimate` > 0,
      `Reference complete-landscape estimate` < 0, `Minimum scenario estimate` < 0 & `Maximum scenario estimate` < 0,
      default = NA
    ),
    Interpretation = "diagnostic only; not a primary estimate"
  )]
  t13 <- t13b[, .(
    Outcome,
    Profile = `Profile or comparison`,
    `Valid scenarios` = `Number of valid scenarios`,
    `Reference estimate` = `Reference complete-landscape estimate`,
    Minimum = `Minimum scenario estimate`,
    Maximum = `Maximum scenario estimate`,
    `Sign retained` = fifelse(`Sign retained in all valid scenarios` == TRUE, "Yes", fifelse(`Sign retained in all valid scenarios` == FALSE, "No", NA_character_))
  )]
  setorder(t13, Outcome, Profile)
  out[[13]] <- write_table(t13, 13, "Landscape transition and episode diagnostics", "Transition-year and episode-omission diagnostics. These complete-landscape diagnostics use an earlier sparse-outcome implementation and are not direct replications of the primary 10 km models. The table reports the reference estimate and the full range across all valid transition-year and episode-omission scenarios. Sign retention indicates whether all valid scenario estimates retained the non-zero sign of the reference estimate.", paste(inputs$robustness_summary, inputs$transition_profile, inputs$loo_profile, sep = "; "), "summarized profile-level complete-landscape transition and episode diagnostics")

  opt <- read_dt(inputs$fire_optimizer)
  retained <- read_dt(inputs$retained_fire)
  t14 <- opt[, .(
    Threshold = threshold_tag,
    `Spatial domain` = label_design(spatial_design),
    Optimizer = fifelse(optimizer_config == "D_BFGS_diagnostic", "BFGS_refined", optimizer_config),
    `Convergence code` = convergence_code,
    `Positive-definite Hessian` = pdHess,
    `Model rank` = model_matrix_rank,
    `Maximum framework gradient` = framework_maximum_absolute_gradient,
    `Maximum independent gradient` = numerical_maximum_absolute_gradient,
    `Strict-valid` = strict_valid
  )]
  t14[, Selected := Threshold == "tau025" & `Spatial domain` == "10 km" & Optimizer == "BFGS_refined" & `Strict-valid`]
  out[[14]] <- write_table(t14, 14, "Fire optimizer diagnostics", "Final optimizer-refinement diagnostics for the harmonized 10 km fire models.", paste(inputs$fire_optimizer, inputs$retained_fire, sep = "; "), "selected optimizer diagnostic columns")

  bp <- read_dt(inputs$fig4_profile)
  surf <- read_dt(inputs$boundary_surface)
  support <- surf[, .(`Event support` = sum(y, na.rm = TRUE)), by = .(outcome, boundary_id)]
  bp <- merge(bp, support, by.x = c("outcome", "boundary_id"), by.y = c("outcome", "boundary_id"), all.x = TRUE)
  bp[, `:=`(Outcome = map_outcome(outcome), Profile = profile, `Boundary role` = fcase(boundary_center_km %in% c(-20, -15), "inner descriptive check", boundary_center_km == 0, "legal boundary", boundary_center_km %in% c(20, 40, 60), "primary spaced outer boundary", default = "dense outer gradient"))]
  bp_full <- bp[, .(Outcome, `Boundary centre` = boundary_center_km, `Boundary role`, Profile, Estimate = estimate, `Lower 95%` = lower_interval, `Upper 95%` = upper_interval, `Fit validity` = fit_validity, `Event support`)]
  fwrite(sanitize_table_text(bp_full), file.path(OUT_SRC, "Table_S15_complete_actual_and_pseudo_boundary_profile_contrasts.csv"))
  bp_render <- bp_full[`Boundary centre` %in% c(-20, -15, 0, 20, 40, 60)]
  out[[15]] <- write_table(bp_render, 15, "Actual and pseudo-boundary profile contrasts", "Concise rendered actual-boundary, inner-check, and primary spaced-outer profile contrasts. The dense outer gradient is retained in source data.", inputs$fig4_profile, "joined event support to profile boundary estimates and rendered selected centres")

  bq <- read_dt(inputs$fig4_pair)
  class <- read_dt(inputs$boundary_class)
  class[, `:=`(Outcome = map_outcome(outcome), Comparison = map_pair_long(profile_comparison))]
  bq[, `:=`(Outcome = map_outcome(outcome), Comparison = map_pair_long(profile_comparison), `Boundary role` = fcase(boundary_center_km %in% c(-20, -15), "inner descriptive check", boundary_center_km == 0, "legal boundary", boundary_center_km %in% c(20, 40, 60), "primary spaced outer boundary", default = "dense outer gradient"))]
  bq <- merge(bq, unique(class[finding_type == "pairwise profile differences", .(Outcome, Comparison, boundary_specificity_classification)]), by = c("Outcome", "Comparison"), all.x = TRUE)
  bq_full <- bq[, .(Outcome, `Boundary centre` = boundary_center_km, `Boundary role`, Comparison, Estimate = estimate, `Lower 95%` = lower_interval, `Upper 95%` = upper_interval, `Fit validity` = fit_validity, `Boundary-specificity classification` = boundary_specificity_classification)]
  fwrite(sanitize_table_text(bq_full), file.path(OUT_SRC, "Table_S16_complete_pseudo_boundary_pairwise_differences.csv"))
  class_profile <- class[finding_type == "profile-specific contrasts", .(
    Outcome = map_outcome(outcome),
    Estimand = map_profile(governance_profile),
    `Estimand type` = "Profile-specific contrast",
    `spaced outer flag` = actual_outside_spaced_outer_range,
    `dense outer flag` = actual_outside_outer_80pct_envelope,
    `final boundary-specificity classification` = boundary_specificity_classification
  )]
  class_pair <- class[finding_type == "pairwise profile differences", .(
    Outcome = map_outcome(outcome),
    Estimand = map_pair_long(profile_comparison),
    `Estimand type` = "Pairwise profile difference",
    `spaced outer flag` = actual_outside_spaced_outer_range,
    `dense outer flag` = actual_outside_outer_80pct_envelope,
    `final boundary-specificity classification` = boundary_specificity_classification
  )]
  class_panel <- rbindlist(list(class_profile, class_pair), fill = TRUE)
  legal_profile <- bp_full[`Boundary centre` == 0, .(Outcome, Estimand = map_profile(Profile), `legal-boundary estimate` = Estimate)]
  legal_pair <- bq_full[`Boundary centre` == 0, .(Outcome, Estimand = Comparison, `legal-boundary estimate` = Estimate)]
  class_panel <- merge(class_panel, rbindlist(list(legal_profile, legal_pair), fill = TRUE), by = c("Outcome", "Estimand"), all.x = TRUE)
  class_panel[, `:=`(
    `spaced-outer comparison result` = fifelse(`spaced outer flag`, "actual outside +20/+40/+60 range", "actual within +20/+40/+60 range"),
    `dense outer 10th–90th percentile result` = fifelse(
      `dense outer flag`,
      "legal estimate outside dense outer 10th–90th percentile interval",
      "legal estimate within dense outer 10th–90th percentile interval"
    ),    `inner-check support` = fcase(
      Outcome == "Tree-cover loss", "limited inner checks only; 2 and 10 events",
      Outcome == "Agricultural expansion", "limited inner checks only; 1 and 31 events",
      default = "inner checks reported descriptively"
    ),
    reason = fcase(
      `final boundary-specificity classification` == "boundary-specific support", "legal estimate lies outside both the +20/+40/+60 range and the dense outer 10th–90th percentile interval, and neither inner check shares its sign",
      `final boundary-specificity classification` == "partial boundary-specific support", "legal estimate lies outside either the +20/+40/+60 range or the dense outer 10th–90th percentile interval, but does not meet every criterion for full support",
      `final boundary-specificity classification` == "not boundary-specific", "legal estimate lies within both the +20/+40/+60 range and the dense outer 10th–90th percentile interval",
      default = "sparse support or model-validity limits prevent boundary-specific interpretation"
    )
  )]
  class_panel <- class_panel[, .(Outcome, `Estimand type`, Estimand, `legal-boundary estimate`, `spaced-outer comparison result`, `dense outer 10th–90th percentile result`, `inner-check support`, `final boundary-specificity classification`, reason)]
  out[[16]] <- write_table(class_panel, 16, "Boundary-specificity classifications", "Legal-boundary classification panel. Complete boundary-level pairwise rows are retained in source data.", paste(inputs$boundary_class, inputs$fig4_profile, inputs$fig4_pair, sep = "; "), "combined implemented classification output with legal-boundary estimates")

  miss <- read_dt(inputs$missingness_decision)
  na_k3 <- read_dt(inputs$no_access_k3)
  t17 <- data.table(
    `Validation topic` = c("FireCCI harmonization", "FireCCI missingness", "tree-cover-loss baseline mask", "agricultural-product reproduction", "clustering reproduction", "accessibility-removal sensitivity", "spatial-design selection", "SESU2 support"),
    Question = c("Does the 2021-2022 fire series match the intended FireCCI measurement?", "Could fully unobserved native pixels alter the primary 25% fire classification?", "Was a fixed baseline forest mask used?", "Did agriculture reproduce across canonical and standalone products?", "Was the frozen clustering reproducible?", "Does removing travel time to cities alter groups?", "Which spatial design is primary?", "Can the third group support primary inference?"),
    Result = c("Harmonized 2001-2022 fire series retained", miss$final_classification, "fixed 30% tree-cover mask retained", "exact identity confirmed in measurement audit", "near reproduction accepted; frozen raster remains authoritative", sprintf("ARI %.3f; retained groups unchanged", na_k3$adjusted_rand_index[1]), "symmetric 10 km corridor selected", "outside inferential scope"),
    Decision = c("use harmonized fire", "no correction required", "retain primary definition", "retain primary product", "retain frozen k = 3 partition", "no model rerun", "10 km primary, all cells sensitivity", "exclude from primary models"),
    `Primary pipeline changed` = c("yes, earlier fire products deprecated", "no", "no", "no", "no", "no", "yes, spatial estimand selected", "no new chronology constructed"),
    `Manuscript implication` = c("Methods report harmonized FireCCI series", "Methods can report missingness bound audit", "Methods report baseline forest eligibility", "Methods report product reproduction", "Methods report frozen clustering", "Supplementary sensitivity only", "Main analyses use 10 km corridor", "Scope statement required"),
    `Final report` = c("docs/decisions/fire_2021_2022_harmonization_report.md", "reports/fire_missingness_resolution/fire_missingness_final_decision.md", "docs/provenance/disturbance_measurement_provenance_report.md", "docs/provenance/disturbance_measurement_provenance_report.md", "reports/methods_review_final_audits/clustering_near_reproduction_acceptance.md", "reports/methods_review_final_audits/no_accessibility_clustering_audit.md", "analysis_spatial_threshold_sensitivity_dev/tables/spatial_design_decision_matrix.csv", "reports/methods_review_targeted_audits/sesu2_support_audit.md")
  )
  out[[17]] <- write_table(t17, 17, "Measurement and validation decisions", "Final validation decisions supporting the frozen analysis.", "final validation reports", "curated validation-decision registry")

  sess <- sub("[[:space:]]+$", "", capture.output(sessionInfo()))
  pkg_version <- function(pkg) if (requireNamespace(pkg, quietly = TRUE)) as.character(utils::packageVersion(pkg)) else "not installed"
  analysis_scripts <- paste(c(
    "scripts/preprocessing/04_harmonize_fire_2021_2022.R",
    "scripts/analysis/01_fit_governance_profile_models.R",
    "scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R",
    "scripts/analysis/03_refine_fire_10km_optimizer.R",
    "scripts/sensitivity/01_run_spatial_threshold_sensitivity.R",
    "scripts/sensitivity/02_audit_measurement_harmonization.R",
    "scripts/sensitivity/03_run_revised_boundary_falsification.R"
  ), collapse = "; ")
  publication_scripts <- paste(c(
    "scripts/publication/06_generate_main_figures_tables.R",
    "scripts/publication/08_generate_figure2_chronology_time_series.R",
    "scripts/publication/07_generate_supplementary_material.R"
  ), collapse = "; ")
  result_tables <- paste(c(
    "outputs/publication/figure_source_data/Figure_2_annual_trajectories.csv",
    "outputs/publication/figure_source_data/Figure_2_profile_chronology.csv",
    "outputs/publication/figure_source_data/Figure_3_profile_contrasts.csv",
    "outputs/publication/figure_source_data/Figure_3_pairwise_differences.csv",
    "outputs/publication/figure_source_data/Figure_4_profile_boundary_estimates.csv",
    "analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv"
  ), collapse = "; ")
  t18 <- data.table(
    Component = c("R", "data.table", "ggplot2", "patchwork", "ragg", "analysis configuration", "active analysis scripts", "publication scripts", "final result tables"),
    `Software or file` = c("R", "data.table", "ggplot2", "patchwork", "ragg", "config/analysis_config.R", analysis_scripts, publication_scripts, result_tables),
    Version = c(R.version.string, pkg_version("data.table"), pkg_version("ggplot2"), pkg_version("patchwork"), pkg_version("ragg"), "frozen repository version", "frozen repository version", "final publication workflow", "frozen authoritative outputs"),
    Role = c("execution environment", "tabular processing", "statistical graphics", "figure composition", "600 dpi PNG rendering", "configuration", "upstream analysis execution", "publication output generation", "authoritative inputs"),
    `Authoritative path` = c("system R", "installed package", "installed package", "installed package", "installed package", "config/analysis_config.R", analysis_scripts, publication_scripts, result_tables),
    `Checksum if available` = rep(NA_character_, 9)
  )
  writeLines(sess, file.path(OUT_REPORT, "sessionInfo.txt"))
  out[[18]] <- write_table(t18, 18, "Reproducibility environment and authoritative inputs", "Software environment and core authoritative inputs.", "sessionInfo and repository files", "captured installed package versions")
  out
}

make_figures <- function() {
  # S1
  sil <- read_dt(inputs$silhouette_full)
  setnames(sil, grep("silhouette", names(sil), value = TRUE)[1], "silhouette")
  no <- read_dt(inputs$no_access_silhouette)
  setnames(no, grep("silhouette", names(no), value = TRUE)[1], "silhouette")
  pa <- ggplot(sil, aes(k, silhouette)) + geom_line() + geom_point() + labs(tag = "A", x = "k", y = "Mean silhouette width") + theme_supp()
  pb <- ggplot(no, aes(k, silhouette)) + geom_line(colour = "#0072B2") + geom_point(colour = "#0072B2") + labs(tag = "B", x = "k without accessibility", y = "Mean silhouette width") + theme_supp()
  k3 <- read_dt(inputs$no_access_k3)
  agreement_values <- as.numeric(unlist(k3[, .(full_landscape_agreement, primary_10km_agreement, inside_agreement, outside_agreement)], use.names = FALSE))
  pc <- ggplot(data.table(metric = c("Full landscape", "10 km corridor", "Inside", "Outside"), agreement = agreement_values), aes(metric, agreement)) + geom_col(fill = "#777777") + coord_flip() + labs(tag = "C", x = NULL, y = "Label-matched agreement") + theme_supp()
  pd <- ggplot(k3, aes(x = "No-accessibility k = 3", y = adjusted_rand_index)) + geom_col(fill = "#D55E00") + ylim(0, 1) + labs(tag = "D", x = NULL, y = "Adjusted Rand index") + theme_supp()
  s1 <- (pa | pb) / (pc | pd)
  save_fig(s1, "Figure_S1_clustering_diagnostics", 180, 130)
  fwrite(rbindlist(list(sil[, .(specification = "full covariate", k, silhouette)], no[, .(specification = "without accessibility", k, silhouette)])), file.path(OUT_SRC, "Figure_S1_source_data.csv"))

  # S2
  source(file.path(ROOT, "scripts/lib/refined_fire_publication.R"))
  st <- publication_refined_fire(read_dt(inputs$threshold_profile), root = ROOT)
  st[, `:=`(Outcome = factor(map_outcome(outcome), levels = outcome_order), Profile = factor(map_profile(governance_profile), levels = profile_order), Domain = label_design(spatial_design))]
  st[, `:=`(
    Threshold = threshold_label(threshold_tag),
    Scenario = paste(threshold_label(threshold_tag), Domain),
    `Estimand type` = "Profile contrast",
    `Profile or comparison` = as.character(Profile),
    primary_row = threshold_tag == "tau025" & spatial_design == "buffer_10km",
    fit_display = fifelse(outcome == "fire" & threshold_tag == "tau050", "non-strict fire fit", "accepted or diagnostic fit")
  )]
  fig3_fire <- read_dt(inputs$fig3_profile)[outcome == "fire", .(
    Profile = map_profile(profile_or_comparison),
    estimate = estimate,
    lower_95_ci = lower_95,
    upper_95_ci = upper_95
  )]
  for (i in seq_len(nrow(fig3_fire))) {
    st[outcome == "fire" & threshold_tag == "tau025" & spatial_design == "buffer_10km" & as.character(Profile) == fig3_fire$Profile[i],
       `:=`(estimate = fig3_fire$estimate[i], lower_95_ci = fig3_fire$lower_95_ci[i], upper_95_ci = fig3_fire$upper_95_ci[i])]
  }
  s2 <- ggplot(st, aes(estimate, Scenario, colour = Profile, shape = Profile, alpha = fit_display)) +
    geom_vline(xintercept = 0, colour = "grey40") +
    geom_errorbar(aes(xmin = lower_95_ci, xmax = upper_95_ci), orientation = "y", width = 0.15) +
    geom_point(aes(size = primary_row), stroke = 0.7) +
    facet_wrap(~Outcome, scales = "free_y", ncol = 1) +
    scale_colour_manual(values = c("Fragmented control" = "#777777", "Militia-centred control" = "#D55E00", "Park-centred control" = "#0072B2")) +
    scale_alpha_manual(values = c("accepted or diagnostic fit" = 1, "non-strict fire fit" = 0.45), name = "Fit display") +
    scale_size_manual(values = c("TRUE" = 1.9, "FALSE" = 1.2), guide = "none") +
    labs(x = "Inside-minus-outside log-odds contrast", y = "Threshold and spatial domain") +
    theme_supp()
  save_fig(s2, "Figure_S2_threshold_spatial_sensitivities", 180, 170)
  fwrite(sanitize_table_text(st), file.path(OUT_SRC, "Figure_S2_source_data.csv"))

  # S3
  bq <- read_dt(inputs$fig4_pair)
  bq[, `:=`(
    Outcome = factor(map_outcome(outcome), levels = outcome_order),
    Comparison = map_pair_long(profile_comparison),
    accepted = fit_validity %in% c("strict-valid", "accepted two-stage estimate"),
    valid_interval = fit_validity %in% c("strict-valid", "accepted two-stage estimate") & is.finite(lower_interval) & is.finite(upper_interval)
  )]
  bq[, fit_display_category := fcase(
    outcome == "fire" & !accepted, "finite non-strict fire fit",
    outcome %in% c("tree_cover_loss", "agriculture") & boundary_center_km %in% c(-20, -15), "limited-support descriptive check",
    default = "accepted/strict-valid fit"
  )]
  s3 <- ggplot(bq, aes(boundary_center_km, estimate, shape = fit_display_category)) +
    geom_hline(yintercept = 0, colour = "grey45") +
    geom_vline(xintercept = 0, colour = "black") +
    geom_errorbar(data = bq[valid_interval == TRUE], aes(ymin = lower_interval, ymax = upper_interval), width = 1.0, colour = "grey40") +
    geom_point(size = 1.3) +
    facet_grid(Outcome ~ Comparison, scales = "free_y") +
    scale_shape_manual(values = c("accepted/strict-valid fit" = 16, "finite non-strict fire fit" = 1, "limited-support descriptive check" = 4), name = "Fit validity") +
    labs(x = "Signed boundary centre (km)", y = "Pairwise difference in log-odds contrasts") +
    theme_supp()
  save_fig(s3, "Figure_S3_pairwise_pseudo_boundary_diagnostic", 180, 150)
  fwrite(sanitize_table_text(bq), file.path(OUT_SRC, "Figure_S3_pairwise_pseudo_boundary_diagnostic_source_data.csv"))

  data.table(
    `Supplementary item` = paste0("Figure S", 1:3),
    `Output file` = file.path("outputs/publication/supplement/figures", c("Figure_S1_clustering_diagnostics.png", "Figure_S2_threshold_spatial_sensitivities.png", "Figure_S3_pairwise_pseudo_boundary_diagnostic.png")),
    `Authoritative source file or files` = c(inputs$silhouette_full, inputs$threshold_profile, inputs$fig4_pair),
    Transformation = c("silhouette and agreement plotting", "forest plot", "pairwise boundary diagnostic plot"),
    `Scientific status` = "supplementary diagnostic",
    `Validation status` = "pending",
    Notes = ""
  )
}

methods_sections <- function() {
  c(
    "<h1>Supplementary Material</h1>",
    "<h2>Supplementary Methods S1. Spatial design and landscape comparison groups</h2>",
    "<p>All analyses used the canonical 500 m grid and land mask. Park side was assigned from signed distance to the legal park boundary, with negative values inside the park and positive values outside. Environmental, hydrological, soil, vegetation, settlement, and accessibility covariates were processed to the common grid, transformed where needed, and standardized before k-means clustering. Candidate k values from 2 to 15 were evaluated on the fixed 20,000-cell silhouette sample with seed 42, 25 random starts, final-fit seed 123, and an eight-neighbour de-speckling rule for isolated labels. The frozen k = 3 partition remains authoritative. The accessibility-removal audit retained the Depression and Plateau groups and did not trigger outcome-model reruns. The symmetric 10 km corridor is the primary spatial design; all cells and 5, 20 km corridors are sensitivity domains. The groups are landscape comparison strata, not bounded socio-ecological entities. SESU2 is outside the primary inferential scope.</p>",
    "<h2>Supplementary Methods S2. Territorial-control reconstruction</h2>",
    "<p>Territorial-control profiles were reconstructed by a single expert before inspecting disturbance outcomes. The source hierarchy prioritized dated, spatially interpretable historical evidence and reconciled conflicting evidence by assigning the profile best supported for each landscape group-year. Fragmented control indicates no actor-centred territorial control; militia-centred control indicates practical territorial control centred on armed-group presence; park-centred control indicates practical territorial control centred on park authority. These labels describe practical control and are distinct from legitimacy or exclusive sovereignty. Transition-year and episode-omission diagnostics evaluate sensitivity to chronology uncertainty.</p>",
    "<h2>Supplementary Methods S3. Disturbance measurement and validation</h2>",
    "<p>Fire used ESA FireCCI v5.1 products for 2001-2020 and official monthly files for 2021-2022. Seasonal fire used inclusive DOY 100-300, whole-cell area averaging, and thresholds 0.10, 0.25, and 0.50. The final missingness-bound audit reproduced the authoritative tau025 classifications exactly and found no fully unobserved April-October native pixels that could alter the primary fire analysis. Tree-cover loss used the first year cumulative loss reached the threshold under the fixed 30% baseline-forest mask. Agricultural expansion used the first annual transition to threshold cropland. Tree-cover loss and agricultural expansion used post-event risk-set exclusion.</p>",
    "<h2>Supplementary Methods S4. Statistical estimation and diagnostics</h2>",
    "<p>Fire used the beta-binomial profile model with complete profile-specific contrasts and pairwise differences. Strict-valid optimizer criteria required finite coefficients and standard errors, convergence code 0, positive-definite Hessian, full model rank, and maximum framework and numerical gradients below 0.001. Sparse tree-cover-loss and agricultural-expansion analyses used SESU-year two-stage contrasts with Haldane-Anscombe correction, inverse-variance weights, HC3 covariance, and unweighted sensitivity. Boundary-location diagnostics used the legal boundary, spaced outer pseudo-boundaries, dense outer-gradient sensitivity, and limited inner checks. They are deterministic spatial diagnostics and not a randomized null distribution.</p>",
    "<p>The implemented boundary-specificity classifier first returned <em>inconclusive</em> when event support or fit diagnostics were inadequate, and agriculture was classified as inconclusive because of sparse support and unstable pseudo-boundary fits. Otherwise, a finding was classified as <em>boundary-specific support</em> when the actual estimate was outside the +20/+40/+60 km spaced-outer range, outside the dense outer 80% envelope, and the inner checks were qualitatively distinct. A finding was classified as <em>partial boundary-specific support</em> when the actual estimate was outside either the spaced-outer range or the dense outer 80% envelope but did not satisfy all boundary-specific criteria. Findings were classified as <em>not boundary-specific</em> when the actual estimate was not distinct from the pseudo-boundary diagnostics.</p>"
  )
}

supplementary_references <- function() {
  c(
    "Aerden, P. 2012. Upemba National Park technical-assistance and conservation notes. Internal project documentation.",
    "Asmani, H. 2015. Reporting on displacement and insecurity in northern Katanga. Humanitarian reporting.",
    "Brugiere, D. 2020. Upemba-Kundelungu conservation and management reporting. Project report.",
    "Chief Kayumba. 2010. [Declaration recognizing the 1975 boundaries of Upemba National Park]. Unpublished correspondence.",
    "d'Huart, C. 2017. Upemba-Kundelungu public-private partnership and conservation-management documentation. Project report.",
    "ESA FireCCI project. 2022. FireCCI v5.1 burned-area products. European Space Agency Climate Change Initiative.",
    "FZS. 2009. Upemba National Park reconnaissance and conservation-support report. Frankfurt Zoological Society report.",
    "GHSL. 2023. Global Human Settlement Layer P2023A built-up surface. European Commission Joint Research Centre.",
    "Hance, J. 2012a. Reporting on renewed conservation activity and insecurity in Upemba National Park. Mongabay web article.",
    "Hance, J. 2012b. Reporting on raids and threats to Upemba National Park. Mongabay web article.",
    "Hansen, M. C., et al. 2013. High-resolution global maps of 21st-century forest cover change. Science 342:850-853.",
    "Hasson, A. 2003. Upemba National Park conservation status and emergency support documentation. Project report.",
    "Hasson, A. 2015. Historical and conservation documentation for Upemba National Park. Project manuscript/report.",
    "Hecht, G. 2006. Humanitarian and security reporting on the Katanga conflict. Report.",
    "Human Rights Watch. 2006. The Curse of Gold? Democratic Republic of Congo conflict and human rights reporting. Human Rights Watch report.",
    "Huisman, T. 2017. Upemba National Park security and conservation chronology. Project documentation.",
    "IUCN NL. 2021. Upemba-Kundelungu conservation programme reporting. IUCN National Committee of the Netherlands report.",
    "JRC. 2021. Global Surface Water v1.4. European Commission Joint Research Centre.",
    "Katembo, R. 2016. Rapport technique sur l'operation de gardiennage et protection des derniers elephants du Katanga. Internal ICCN report.",
    "Katembo, R. 2017. Rapport d'operation et suivi de protection des elephants dans le complexe Upemba-Kundelungu. Internal ICCN report.",
    "MONUSCO. 2013. Reporting on Mai-Mai child separation and Katanga insecurity. United Nations mission report.",
    "MONUSCO. 2022a. Reporting on insecurity affecting the Upemba-Kundelungu landscape. United Nations mission report.",
    "MONUSCO. 2022b. Reporting on attacks and security incidents in Haut-Katanga. United Nations mission report.",
    "Ngoy, M. 2015. Reporting on displacement and insecurity around Upemba National Park. Humanitarian or news report.",
    "Nouvelles Approches. 2002-2004. Upemba National Park emergency conservation assistance records. Project documentation.",
    "OCHA. 2013. Humanitarian reporting on Katanga displacement and insecurity. United Nations Office for the Coordination of Humanitarian Affairs.",
    "OKA Kanyundu. 2018. Documentation on customary-authority engagement and Upemba boundary recognition. Project documentation.",
    "Radio Okapi. 2012b. Report on the killing of the Upemba park manager. Radio Okapi web article.",
    "Radio Okapi. 2013a. Report on armed activity and territorial control around Mbwe and Upemba National Park. Radio Okapi web article.",
    "Radio Okapi. 2014a. Report on attacks around Upemba National Park positions. Radio Okapi web article.",
    "Radio Okapi. 2014b. Report on hostage-taking and weapons theft around Upemba National Park. Radio Okapi web article.",
    "Radio Okapi. 2014c. Report on guard-post destruction in Upemba National Park. Radio Okapi web article.",
    "Radio Okapi. 2014d. Report on FARDC deployment and park-guard displacement around Upemba National Park. Radio Okapi web article.",
    "SoilGrids. 2020. SoilGrids 250 m global soil information layers. ISRIC - World Soil Information.",
    "TerraClimate. 2023. Monthly climate and climatic water balance data for global terrestrial surfaces. University of Idaho.",
    "UCSB CHG. 2023. CHIRPS daily precipitation data. Climate Hazards Center, University of California Santa Barbara.",
    "Van Leeuwe, H., et al. 2009. Upemba National Park and Kundelungu National Park reconnaissance and conservation assessment. Wildlife Conservation Society and partner report.",
    "Villaespesa, M. 2020. Ranger training and professionalization reporting for Upemba-Kundelungu. Project report.",
    "Weiss, D. J., et al. 2018. A global map of travel time to cities to assess inequalities in accessibility in 2015. Nature 553:333-336."
  )
}

write_supplement_documents <- function(tables, fig_manifest) {
  table_html <- Map(function(x) {
    if (x$item == "Table S6") {
      paste0(
        html_table(read_dt(file.path(OUT_SRC, "Table_S06A_annual_profile_assignments.csv")), "Table S6A. Annual profile assignment", "Frozen annual territorial-control profile assignments.", max_rows = Inf),
        html_table(read_dt(file.path(OUT_SRC, "Table_S06B_approved_episode_evidence.csv")), "Table S6B. Historical episode evidence", "Approved episode evidence supporting the frozen chronology.", max_rows = Inf)
      )
    } else {
      html_table(read_dt(x$file), paste(x$item, x$title), x$caption, max_rows = Inf)
    }
  }, tables)
  fig_html <- c(
    "<h2>Supplementary Figures S1-S3</h2>",
    "<h3>Figure S1. Clustering diagnostics.</h3><p>Mean silhouette profiles, no-accessibility comparison, and agreement metrics.</p><img src='figures/Figure_S1_clustering_diagnostics.png' style='max-width:100%;'>",
    "<h3>Figure S2. Threshold and spatial-domain sensitivities.</h3><p>Profile-specific contrasts across thresholds and spatial domains; the 25% / 10 km row is the primary specification and muted points indicate non-strict fire fits.</p><img src='figures/Figure_S2_threshold_spatial_sensitivities.png' style='max-width:100%;'>",
    "<h3>Figure S3. Pairwise pseudo-boundary diagnostic.</h3><p>Pairwise differences are shown at the legal boundary, supported inner checks, and outer pseudo-boundaries. Filled symbols denote accepted or strict-valid estimates; open symbols denote finite non-strict fire fits or sparse estimates with limited support.</p><img src='figures/Figure_S3_pairwise_pseudo_boundary_diagnostic.png' style='max-width:100%;'>"
  )
  html <- c(
    "<!doctype html><html><head><meta charset='utf-8'><style>body{font-family:Arial,sans-serif;margin:32px;line-height:1.35;} table{border-collapse:collapse;font-size:8.5pt;margin-bottom:24px;} th,td{border:1px solid #888;padding:4px 6px;vertical-align:top;} th{background:#eee;} h1,h2{page-break-after:avoid;} img{margin:8px 0 24px 0;}</style></head><body>",
    methods_sections(),
    "<h2>Supplementary Tables S1-S18</h2>",
    unlist(table_html),
    fig_html,
    "<h2>Supplementary References</h2>",
    "<p>The episode coding ledger and complete source metadata are provided in Table S6B and the Supplementary References; sensitive operational details were excluded.</p>",
    paste0("<p>", html_escape(supplementary_references()), "</p>"),
    "</body></html>"
  )
  writeLines(html, file.path(OUT_ROOT, "Chapter1_Supplementary_Material.html"), useBytes = TRUE)

  final_docx <- file.path(OUT_ROOT, "Chapter1_Supplementary_Material_final.docx")
  if (!file.exists(final_docx)) {
    stop("Missing authoritative final supplement: ", final_docx, call. = FALSE)
  }
  character()
}

cross_reference_map <- function() {
  data.table(
    `Main-text placeholder` = c("clustering covariates", "clustering diagnostics", "spatial-design decision", "territorial-control chronology", "profile support", "primary numerical estimates", "weighting sensitivity", "threshold sensitivity", "spatial sensitivity", "historical diagnostics", "optimizer diagnostics", "boundary diagnostic", "measurement audits", "software and reproducibility"),
    `Manuscript section` = c("Methods", "Methods", "Methods", "Methods", "Methods", "Results", "Results", "Robustness", "Robustness", "Robustness", "Methods/Results", "Robustness", "Methods", "Data and code availability"),
    Replacement = c("Table S1", "Tables S2-S3; Figure S1", "Tables S4-S5", "Table S6", "Table S7", "Tables S8-S9", "Table S10", "Table S11; Figure S2", "Table S12; Figure S2", "Table S13", "Table S14", "Tables S15-S16; Figure S3", "Table S17", "Table S18"),
    `Supporting item` = c("Table S1", "Tables S2-S3; Figure S1", "Tables S4-S5", "Table S6", "Table S7", "Tables S8-S9", "Table S10", "Table S11; Figure S2", "Table S12; Figure S2", "Table S13", "Table S14", "Tables S15-S16; Figure S3", "Table S17", "Table S18")
  )
}

write_supplementary_data_delivery <- function() {
  csv_files <- file.path(OUT_TABLE, sprintf(
    "Table_S%02d_%s.csv",
    11:16,
    c(
      "threshold_sensitivity",
      "spatial_domain_sensitivity",
      "landscape_transition_and_episode_diagnostics",
      "fire_optimizer_diagnostics",
      "actual_and_pseudo_boundary_profile_contrasts",
      "pseudo_boundary_pairwise_differences"
    )
  ))
  extra <- file.path(OUT_SRC, c(
    "Table_S13_full_historical_diagnostics.csv",
    "Table_S15_complete_actual_and_pseudo_boundary_profile_contrasts.csv",
    "Table_S16_boundary_specificity_classifications.csv",
    "Table_S16_complete_pseudo_boundary_pairwise_differences.csv"
  ))
  csv_files <- c(csv_files[file.exists(csv_files)], extra[file.exists(extra)])
  xlsx_path <- file.path(OUT_ROOT, "Chapter1_Supplementary_Data.xlsx")
  if (requireNamespace("openxlsx", quietly = TRUE)) {
    wb <- openxlsx::createWorkbook()
    for (f in csv_files) {
      sheet <- substr(tools::file_path_sans_ext(basename(f)), 1, 31)
      openxlsx::addWorksheet(wb, sheet)
      openxlsx::writeData(wb, sheet, read_dt(f))
    }
    openxlsx::saveWorkbook(wb, xlsx_path, overwrite = TRUE)
    return("xlsx_openxlsx")
  }
  if (requireNamespace("writexl", quietly = TRUE)) {
    sheets <- setNames(lapply(csv_files, read_dt), substr(tools::file_path_sans_ext(basename(csv_files)), 1, 31))
    writexl::write_xlsx(sheets, xlsx_path)
    return("xlsx_writexl")
  }
  writeLines(c(
    "# Supplementary Data CSV Index",
    "",
    "No installed XLSX writer (`openxlsx` or `writexl`) was available. Complete supplementary data are provided as CSV files:",
    "",
    paste0("- `", rel_path(csv_files), "`")
  ), file.path(OUT_ROOT, "README_supplementary_data.md"))
  "csv_index"
}

validate_supplement <- function(table_meta, fig_manifest, missing_pkg) {
  problems <- character()
  table_files <- file.path(OUT_TABLE, sprintf("Table_S%02d_%s.csv", seq_len(18), gsub("[^A-Za-z0-9]+", "_", tolower(vapply(table_meta, `[[`, character(1), "title")))))
  if (!all(file.exists(table_files))) problems <- c(problems, "Not all Tables S1-S18 exist.")
  fig_files <- file.path(OUT_FIG, paste0(c("Figure_S1_clustering_diagnostics", "Figure_S2_threshold_spatial_sensitivities", "Figure_S3_pairwise_pseudo_boundary_diagnostic"), ".png"))
  if (!all(file.exists(fig_files))) problems <- c(problems, "Not all Figures S1-S3 exist.")
  primary <- read_dt(file.path(OUT_TABLE, "Table_S08_primary_profile_specific_contrasts.csv"))
  if (!all(c("Tree-cover loss", "Fire", "Agricultural expansion") %in% primary$Outcome)) problems <- c(problems, "Primary estimates do not include all outcomes.")
  if (!all(profile_order %in% primary$Profile)) problems <- c(problems, "Primary estimates do not include all profiles.")
  if (primary[Outcome == "Fire", unique(Events)][1] != 508320L) problems <- c(problems, "Primary fire total is not 508320.")
  if (primary[Outcome == "Tree-cover loss", unique(Events)][1] != 519L) problems <- c(problems, "Tree-cover-loss total is not 519.")
  if (primary[Outcome == "Agricultural expansion", unique(Events)][1] != 518L) problems <- c(problems, "Agricultural-expansion total is not 518.")
  s1 <- read_dt(file.path(OUT_TABLE, "Table_S01_landscape_comparison_covariates.csv"))
  required_products <- c("Copernicus DEM GLO-30", "JRC Global Surface Water v1.4", "CHIRPS daily precipitation", "TerraClimate", "SoilGrids 0-30 cm depth-weighted SOC", "GHSL P2023A built-up surface", "Oxford/MAP accessibility_to_cities_2015_v1_0")
  if (!all(required_products %in% s1$`Source product`)) problems <- c(problems, "Table S1 does not contain exact authoritative product names.")
  s4 <- read_dt(file.path(OUT_TABLE, "Table_S04_spatial_design_balance_and_event_support.csv"))
  s4_10 <- s4[design == "10 km"]
  if (nrow(s4_10) != 1 || s4_10$`tau025 fire events` != 508320L || s4_10$`tau025 tree-cover-loss events` != 519L || s4_10$`tau025 agricultural-expansion events` != 518L) {
    problems <- c(problems, "Table S4 10 km event totals do not equal 508320, 519, and 518.")
  }
  s5 <- read_dt(file.path(OUT_TABLE, "Table_S05_landscape_group_and_side_support.csv"))
  s5_retained <- s5[`Included in primary inference` == TRUE]
  fire_cols <- grep("^Fire (outside|inside)$", names(s5_retained), value = TRUE)
  tcl_cols <- grep("^Tree-cover loss (outside|inside)$", names(s5_retained), value = TRUE)
  ag_cols <- grep("^Agricultural expansion (outside|inside)$", names(s5_retained), value = TRUE)
  if (sum(unlist(s5_retained[, ..fire_cols]), na.rm = TRUE) != 508320L ||
      sum(unlist(s5_retained[, ..tcl_cols]), na.rm = TRUE) != 519L ||
      sum(unlist(s5_retained[, ..ag_cols]), na.rm = TRUE) != 518L) {
    problems <- c(problems, "Table S5 retained-group totals do not equal 508320, 519, and 518.")
  }
  s5_sesu2 <- s5[grepl("SESU2", `Landscape group`)]
  if (nrow(s5_sesu2) != 1L || as.integer(s5_sesu2$`Tree-cover loss inside`) != 0L || as.integer(s5_sesu2$`Agricultural expansion inside`) != 2L) {
    problems <- c(problems, "SESU2 event-support cells are not populated as expected.")
  }
  s6 <- read_dt(file.path(OUT_TABLE, "Table_S06_territorial_control_chronology.csv"))
  s6a <- s6[Panel == "S6A annual profile assignment"]
  s6b <- s6[Panel == "S6B historical episode evidence"]
  if (nrow(unique(s6a[, .(`Landscape group`, Year)])) != 44L) problems <- c(problems, "Table S6A does not have 44 unique landscape-group by year rows.")
  if (nrow(s6b) != 11L || any(grepl("detailed evidence ledger|profile assigned from frozen chronology|curated source hierarchy", apply(s6b, 1, paste, collapse = " "), ignore.case = TRUE))) {
    problems <- c(problems, "Table S6B is incomplete or contains boilerplate placeholders.")
  }
  required_refs <- c("Hasson, A. 2003", "Hasson, A. 2015", "Nouvelles Approches. 2002-2004", "OKA Kanyundu. 2018", "Van Leeuwe, H., et al. 2009", "Hecht, G. 2006", "Human Rights Watch. 2006", "FZS. 2009", "Chief Kayumba. 2010", "OCHA. 2013", "MONUSCO. 2013", "MONUSCO. 2022a", "MONUSCO. 2022b", "Radio Okapi. 2012b", "Radio Okapi. 2013a", "Radio Okapi. 2014a", "Radio Okapi. 2014b", "Radio Okapi. 2014c", "Radio Okapi. 2014d", "Aerden, P. 2012", "Hance, J. 2012a", "Hance, J. 2012b", "Asmani, H. 2015", "Ngoy, M. 2015", "Huisman, T. 2017", "Katembo, R. 2016", "Katembo, R. 2017", "d'Huart, C. 2017", "Brugiere, D. 2020", "Villaespesa, M. 2020", "IUCN NL. 2021")
  ref_text <- paste(supplementary_references(), collapse = "\n")
  missing_refs <- required_refs[!vapply(required_refs, function(z) grepl(z, ref_text, fixed = TRUE), logical(1))]
  if (length(missing_refs)) problems <- c(problems, paste("Supplementary references missing entries for:", paste(missing_refs, collapse = ", ")))
  s11 <- read_dt(file.path(OUT_TABLE, "Table_S11_threshold_sensitivity.csv"))
  if (any(duplicated(s11[, .(Outcome, Threshold, `Estimand type`, `Profile or comparison`)]))) problems <- c(problems, "Table S11 has duplicate threshold-estimand keys.")
  if (!setequal(unique(s11$Threshold), c("10%", "25%", "50%"))) problems <- c(problems, "Table S11 does not contain only 10%, 25%, and 50% thresholds.")
  s12 <- read_dt(file.path(OUT_TABLE, "Table_S12_spatial_domain_sensitivity.csv"))
  if (any(duplicated(s12[, .(Outcome, `Spatial domain`, `Estimand type`, `Profile or comparison`)]))) problems <- c(problems, "Table S12 has duplicate spatial-domain-estimand keys.")
  if (!setequal(unique(s12$`Spatial domain`), c("All cells", "5 km", "10 km", "20 km"))) problems <- c(problems, "Table S12 does not contain only the intended tau025 spatial domains.")
  fire_ref_prof <- primary[Outcome == "Fire", .(key = paste("Profile contrast", Profile), Estimate, `Lower 95%`, `Upper 95%`)]
  pair_primary <- read_dt(file.path(OUT_TABLE, "Table_S09_primary_pairwise_profile_differences.csv"))
  fire_ref_pair <- pair_primary[Outcome == "Fire", .(key = paste("Pairwise difference", map_pair_long(Comparison)), Estimate, `Lower 95%`, `Upper 95%`)]
  fire_ref <- rbindlist(list(fire_ref_prof, fire_ref_pair), fill = TRUE)
  check_fire_block <- function(dt, source_name, expected = fire_ref) {
    vals <- dt[Outcome == "Fire", .(key = paste(`Estimand type`, `Profile or comparison`), Estimate, `Lower 95%`, `Upper 95%`)]
    vals <- vals[key %in% expected$key]
    cmp <- merge(expected, vals, by = "key", suffixes = c("_ref", "_candidate"), all.x = TRUE)
    bad <- cmp[!is.finite(Estimate_candidate) | abs(Estimate_ref - Estimate_candidate) > 1e-12 | abs(`Lower 95%_ref` - `Lower 95%_candidate`) > 1e-12 | abs(`Upper 95%_ref` - `Upper 95%_candidate`) > 1e-12]
    if (nrow(bad)) paste("Primary fire values mismatch in", source_name) else character()
  }
  problems <- c(problems, check_fire_block(s11[Threshold == "25%"], "Table S11"))
  problems <- c(problems, check_fire_block(s12[`Spatial domain` == "10 km"], "Table S12"))
  fig_s2 <- read_dt(file.path(OUT_SRC, "Figure_S2_source_data.csv"))
  fig_s2_check <- fig_s2[outcome == "fire" & threshold_tag == "tau025" & spatial_design == "buffer_10km", .(Outcome = "Fire", `Estimand type` = "Profile contrast", `Profile or comparison` = as.character(Profile), Estimate = estimate, `Lower 95%` = lower_95_ci, `Upper 95%` = upper_95_ci)]
  problems <- c(problems, check_fire_block(fig_s2_check, "Figure S2 source data", fire_ref_prof))
  s14 <- read_dt(file.path(OUT_TABLE, "Table_S14_fire_optimizer_diagnostics.csv"))
  if (s14[Selected == TRUE, .N] != 1L || s14[Selected == TRUE, Threshold] != "tau025" || s14[Selected == TRUE, `Spatial domain`] != "10 km" || s14[Selected == TRUE, Optimizer] != "BFGS_refined" || !s14[Selected == TRUE, `Strict-valid`]) {
    problems <- c(problems, "Table S14 does not have exactly one primary selected strict-valid tau025 10 km BFGS_refined fit.")
  }
  centers <- sort(unique(read_dt(file.path(OUT_TABLE, "Table_S15_actual_and_pseudo_boundary_profile_contrasts.csv"))$`Boundary centre`))
  if (!all(c(-20, -15, 0, 20, 40, 60) %in% centers)) problems <- c(problems, "Rendered pseudo-boundary centres are incomplete.")
  s16 <- read_dt(file.path(OUT_TABLE, "Table_S16_boundary_specificity_classifications.csv"))
  if (any(is.na(s16$`final boundary-specificity classification`) | s16$`final boundary-specificity classification` == "")) problems <- c(problems, "Boundary-specificity classification is NA or blank in Table S16.")
  full_centers <- sort(unique(read_dt(file.path(OUT_SRC, "Table_S15_complete_actual_and_pseudo_boundary_profile_contrasts.csv"))$`Boundary centre`))
  if (!all(c(-20, -15, 0, seq(15, 60, 5)) %in% full_centers)) problems <- c(problems, "Complete pseudo-boundary source-data centres are incomplete.")
  html_text <- readLines(file.path(OUT_ROOT, "Chapter1_Supplementary_Material.html"), warn = FALSE, encoding = "UTF-8")
  if (any(grepl("Showing first", html_text, fixed = TRUE))) problems <- c(problems, "Rendered supplement silently truncates a table.")
  if (any(grepl("primary estimates are shown", html_text, ignore.case = TRUE))) problems <- c(problems, "Figure S3 caption claims complete-landscape diagnostics are primary.")
  if (!any(grepl("Table S6A. Annual profile assignment", html_text, fixed = TRUE)) || !any(grepl("Table S6B. Historical episode evidence", html_text, fixed = TRUE))) problems <- c(problems, "S6A and S6B are not rendered as separate panels.")
  s13 <- read_dt(file.path(OUT_TABLE, "Table_S13_landscape_transition_and_episode_diagnostics.csv"))
  expected_s13 <- c("Outcome", "Profile", "Valid scenarios", "Reference estimate", "Minimum", "Maximum", "Sign retained")
  if (!identical(names(s13), expected_s13)) problems <- c(problems, "Table S13 columns do not match the locked final specification.")
  if (s13[Outcome == "Fire" & Profile == "Fragmented control", `Sign retained`][1] != "No") problems <- c(problems, "Fragmented-control fire sign retention is not No.")
  fig_s4 <- read_dt(file.path(OUT_SRC, "Figure_S3_pairwise_pseudo_boundary_diagnostic_source_data.csv"))
  required_fit_cats <- c("accepted/strict-valid fit", "finite non-strict fire fit", "limited-support descriptive check")
  if (!all(required_fit_cats %in% fig_s4$fit_display_category)) problems <- c(problems, "Figure S3 source data do not contain every fit-validity category used in the caption.")
  active_files <- c(list.files(OUT_ROOT, pattern = "\\.(csv|html|md)$", recursive = TRUE, full.names = TRUE), list.files(OUT_REPORT, pattern = "\\.(csv|md)$", recursive = TRUE, full.names = TRUE), file.path(ROOT, "scripts/publication/07_generate_supplementary_material.R"))
  active_files <- active_files[basename(active_files) != "supplement_validation.md"]
  text <- unlist(lapply(active_files, readLines, warn = FALSE, encoding = "UTF-8"), use.names = FALSE)
  forbidden <- c(
    paste0("508", "332"),
    raw_park,
    raw_militia,
    paste("governance", "intensity"),
    paste("random", "side", sep = "-"),
    paste("year-block bootstrap", "primary inference"),
    paste("pixel-centre", "valid-denominator", sep = " ")
  )
  hits <- forbidden[vapply(forbidden, function(pattern) any(grepl(pattern, text, fixed = TRUE)), logical(1))]
  if (length(hits)) problems <- c(problems, paste("Deprecated string(s) found:", paste(hits, collapse = ", ")))
  if (!file.exists(file.path(OUT_ROOT, "Chapter1_Supplementary_Material.html"))) problems <- c(problems, "HTML supplement missing.")
  if (!file.exists(file.path(OUT_ROOT, "Chapter1_Supplementary_Material_final.docx"))) problems <- c(problems, "Authoritative final DOCX supplement is missing.")
  validation <- c(
    "# Supplement Validation",
    "",
    sprintf("Overall validation status: %s.", ifelse(length(problems), "failed", "passed")),
    "",
    "- Tables S1-S18 exist.",
    "- Figures S1-S3 exist.",
    "- Primary estimates match the main manuscript source data.",
    "- Event totals validated: fire 508,320; tree-cover loss 519; agricultural expansion 518.",
    "- Deprecated outputs and terminology checks completed.",
    sprintf("- Missing Word-output packages: %s.", ifelse(length(missing_pkg), paste(missing_pkg, collapse = ", "), "none")),
    "",
    if (length(problems)) paste("- ", problems) else "No validation failures."
  )
  writeLines(validation, file.path(OUT_REPORT, "supplement_validation.md"))
  if (length(problems)) stop("Supplement validation failed.", call. = FALSE)
}

run <- function() {
  tables <- make_tables()
  fig_manifest <- make_figures()
  missing_pkg <- write_supplement_documents(tables, fig_manifest)
  data_delivery <- write_supplementary_data_delivery()
  xref <- cross_reference_map()
  fwrite(xref, file.path(OUT_REPORT, "main_text_cross_reference_map.csv"))
  table_manifest <- rbindlist(lapply(tables, function(x) data.table(
    `Supplementary item` = x$item,
    `Output file` = rel_path(x$file),
    `Authoritative source file or files` = x$source_files,
    Transformation = x$transformation,
    `Scientific status` = "curated supplementary evidence",
    `Validation status` = "passed",
    Notes = x$notes
  )), fill = TRUE)
  fig_manifest[, `Output file` := rel_path(file.path(ROOT, `Output file`))]
  manifest <- rbindlist(list(table_manifest, fig_manifest), fill = TRUE)
  manifest[, `Authoritative source file or files` := vapply(
    `Authoritative source file or files`,
    function(value) {
      parts <- trimws(strsplit(value, ";", fixed = TRUE)[[1]])
      paste(vapply(parts, function(path) {
        if (file.exists(path)) rel_path(path) else path
      }, character(1)), collapse = "; ")
    },
    character(1)
  )]
  fwrite(manifest, file.path(OUT_REPORT, "supplement_manifest.csv"))
  validate_supplement(tables, fig_manifest, missing_pkg)
  writeLines(c(
    "# Supplement Generation Log",
    "",
    sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    sprintf("Tables generated: %d", length(tables)),
    "Figures generated: 3",
    sprintf("HTML supplement generated: %s", file.exists(file.path(OUT_ROOT, "Chapter1_Supplementary_Material.html"))),
    sprintf("Authoritative final Word supplement retained: %s", file.exists(file.path(OUT_ROOT, "Chapter1_Supplementary_Material_final.docx"))),
    sprintf("Missing Word-output packages: %s", ifelse(length(missing_pkg), paste(missing_pkg, collapse = ", "), "none")),
    sprintf("Large-table delivery method: %s", data_delivery),
    "No models were refit and no events were reconstructed."
  ), file.path(OUT_REPORT, "supplement_generation_log.md"))
  message("Supplementary material package generated.")
}

run()
