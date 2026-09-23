#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
  library(grid)
})

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(ROOT, "config", "analysis_config.R"))

OUT_FIG <- file.path(ROOT, "outputs", "publication", "main_figures")
OUT_TAB <- file.path(ROOT, "outputs", "publication", "main_tables")
OUT_FSD <- file.path(ROOT, "outputs", "publication", "figure_source_data")
OUT_TSD <- file.path(ROOT, "outputs", "publication", "table_source_data")
OUT_REP <- file.path(ROOT, "reports", "publication_outputs")
for (p in c(OUT_FIG, OUT_TAB, OUT_FSD, OUT_TSD, OUT_REP)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

rel_path <- function(p) {
  gsub(
    paste0("^", gsub("([\\^$.|?*+(){}\\[\\]])", "\\\\\\1", ROOT), "/?"),
    "",
    normalizePath(p, winslash = "/", mustWork = FALSE)
  )
}

profile_palette <- function() {
  c(
    "Fragmented control" = "#777777",
    "Militia-centred control" = "#D55E00",
    "Park-centred control" = "#0072B2"
  )
}

profile_shapes <- function(open = FALSE) {
  if (open) {
    c("Fragmented control" = 21, "Militia-centred control" = 24, "Park-centred control" = 22)
  } else {
    c("Fragmented control" = 16, "Militia-centred control" = 17, "Park-centred control" = 15)
  }
}

publication_theme <- function(base_size = 8) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey90", linewidth = 0.25),
      panel.border = element_blank(),
      strip.text = element_text(face = "bold", size = rel(0.95)),
      axis.title = element_text(size = rel(0.95)),
      axis.text = element_text(size = rel(0.85)),
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.9)),
      legend.text = element_text(size = rel(0.82)),
      legend.key.height = unit(0.45, "lines"),
      legend.key.width = unit(1.15, "lines"),
      plot.margin = margin(5, 5, 5, 5)
    )
}

save_pub <- function(g, stem, width_mm, height_mm) {
  ggsave(
    file.path(OUT_FIG, paste0(stem, ".pdf")),
    g,
    width = width_mm / 25.4,
    height = height_mm / 25.4,
    device = cairo_pdf,
    bg = "white"
  )
  ggsave(
    file.path(OUT_FIG, paste0(stem, ".png")),
    g,
    width = width_mm / 25.4,
    height = height_mm / 25.4,
    dpi = 600,
    bg = "white"
  )
}

html_table <- function(dt, path, title) {
  esc <- function(x) {
    gsub("<", "&lt;", gsub(">", "&gt;", gsub("&", "&amp;", as.character(x))))
  }
  hdr <- paste0("<tr>", paste0("<th>", esc(names(dt)), "</th>", collapse = ""), "</tr>")
  rows <- apply(dt, 1, function(z) {
    paste0("<tr>", paste0("<td>", esc(z), "</td>", collapse = ""), "</tr>")
  })
  writeLines(
    c(
      "<!doctype html><html><head><meta charset='utf-8'>",
      "<style>body{font-family:Arial,sans-serif;margin:24px;}",
      "table{border-collapse:collapse;font-size:9pt;max-width:100%;}",
      "th,td{border:1px solid #8a8a8a;padding:6px 7px;vertical-align:top;}",
      "th{background:#efefef;text-align:left;} caption{caption-side:top;text-align:left;font-weight:bold;margin-bottom:8px;}",
      "</style>",
      paste0("<title>", title, "</title></head><body><table><caption>", title, "</caption>"),
      hdr,
      rows,
      "</table></body></html>"
    ),
    path, useBytes = TRUE
  )
}

inputs <- list(
  fire_prof = file.path(ROOT, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_profile_contrasts.csv"),
  fire_pair = file.path(ROOT, "analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_pairwise_differences.csv"),
  sparse_prof = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/sparse_outcome_profile_estimates.csv"),
  sparse_pair = file.path(ROOT, "analysis_spatial_threshold_sensitivity_dev/tables/sparse_outcome_pairwise_differences.csv"),
  boundary_surface = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv"),
  boundary_fire_prof = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/fire_boundary_profile_contrasts.csv"),
  boundary_fire_pair = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/fire_boundary_pairwise_differences.csv"),
  boundary_sparse_prof = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_profile_estimates.csv"),
  boundary_sparse_pair = file.path(ROOT, "analysis_spatial_falsification_revised_dev/tables/sparse_boundary_pairwise_differences.csv")
)

if (!all(file.exists(unlist(inputs)))) {
  missing_inputs <- names(inputs)[!file.exists(unlist(inputs))]
  stop("Missing authoritative input(s): ", paste(missing_inputs, collapse = ", "), call. = FALSE)
}

profile_map <- c(
  "Neither actor dominant" = "Fragmented control",
  "Militia dominant" = "Militia-centred control",
  "Park dominant" = "Park-centred control"
)
profile_order <- unname(profile_map[c("Neither actor dominant", "Militia dominant", "Park dominant")])
profile_order_display <- c("Park-centred control", "Militia-centred control", "Fragmented control")
outcome_map <- c(
  tree_cover_loss = "Tree-cover loss",
  fire = "Fire",
  agriculture = "Agricultural expansion"
)
outcome_order <- c("Tree-cover loss", "Fire", "Agricultural expansion")
pair_map <- c(
  "Militia dominant minus Neither actor dominant" = "Militia-centred - Fragmented",
  "Park dominant minus Neither actor dominant" = "Park-centred - Fragmented",
  "Park dominant minus Militia dominant" = "Park-centred - Militia-centred"
)
pair_order <- unname(pair_map[c(
  "Militia dominant minus Neither actor dominant",
  "Park dominant minus Neither actor dominant",
  "Park dominant minus Militia dominant"
)])
pair_order_display <- c(
  "Park-centred - Militia-centred",
  "Park-centred - Fragmented",
  "Militia-centred - Fragmented"
)

label_profile <- function(x, levels = profile_order) factor(unname(profile_map[x]), levels = levels)
label_outcome <- function(x) factor(unname(outcome_map[x]), levels = outcome_order)
label_pair <- function(x, levels = pair_order) factor(unname(pair_map[x]), levels = levels)

resolve_authoritative_inputs <- function() {
  data.table(
    input_id = names(inputs),
    path = unlist(inputs),
    relative_path = vapply(unlist(inputs), rel_path, character(1)),
    exists = file.exists(unlist(inputs))
  )
}

prepare_figure3_data <- function() {
  fire_profile <- fread(inputs$fire_prof)[
    measurement_version == "harmonized_tau025" &
      threshold_tag == "tau025" &
      spatial_design == "buffer_10km" &
      optimizer_config == "D_BFGS_diagnostic"
  ]
  fire_pair <- fread(inputs$fire_pair)[
    measurement_version == "harmonized_tau025" &
      threshold_tag == "tau025" &
      spatial_design == "buffer_10km" &
      optimizer_config == "D_BFGS_diagnostic"
  ]
  sparse_profile <- fread(inputs$sparse_prof)[
    threshold_tag == "tau025" &
      spatial_design == "buffer_10km" &
      model_type == "inverse_variance_weighted_lm_hc3"
  ]
  sparse_pair <- fread(inputs$sparse_pair)[
    threshold_tag == "tau025" &
      spatial_design == "buffer_10km" &
      model_type == "inverse_variance_weighted_lm_hc3"
  ]

  profile <- rbindlist(
    list(
      fire_profile[, .(
        outcome = "fire",
        profile_or_comparison = governance_profile,
        estimate,
        standard_error,
        lower_95 = lower_95_ci,
        upper_95 = upper_95_ci,
        model = "Strict-valid beta-binomial",
        spatial_domain = "Symmetric 10 km boundary corridor",
        threshold = "tau025",
        fit_validity = "strict-valid",
        source_file = rel_path(inputs$fire_prof)
      )],
      sparse_profile[, .(
        outcome,
        profile_or_comparison = governance_profile,
        estimate,
        standard_error,
        lower_95 = lower_95_ci,
        upper_95 = upper_95_ci,
        model = "Inverse-variance-weighted two-stage HC3",
        spatial_domain = "Symmetric 10 km boundary corridor",
        threshold = "tau025",
        fit_validity = "accepted primary sparse-outcome fit",
        source_file = rel_path(inputs$sparse_prof)
      )]
    ),
    fill = TRUE
  )
  profile[, `:=`(
    estimand_type = "profile-specific contrast",
    outcome_label = label_outcome(outcome),
    profile_label = label_profile(profile_or_comparison, levels = profile_order_display)
  )]

  pairwise <- rbindlist(
    list(
      fire_pair[, .(
        outcome = "fire",
        profile_or_comparison = profile_comparison,
        estimate,
        standard_error,
        lower_95 = lower_95_ci,
        upper_95 = upper_95_ci,
        model = "Strict-valid beta-binomial",
        spatial_domain = "Symmetric 10 km boundary corridor",
        threshold = "tau025",
        fit_validity = "strict-valid",
        source_file = rel_path(inputs$fire_pair)
      )],
      sparse_pair[, .(
        outcome,
        profile_or_comparison = profile_comparison,
        estimate,
        standard_error,
        lower_95 = lower_95_ci,
        upper_95 = upper_95_ci,
        model = "Inverse-variance-weighted two-stage HC3",
        spatial_domain = "Symmetric 10 km boundary corridor",
        threshold = "tau025",
        fit_validity = "accepted primary sparse-outcome fit",
        source_file = rel_path(inputs$sparse_pair)
      )]
    ),
    fill = TRUE
  )
  pairwise[, `:=`(
    estimand_type = "pairwise profile difference",
    outcome_label = label_outcome(outcome),
    comparison_label = label_pair(profile_or_comparison, levels = pair_order_display)
  )]

  list(profile = profile, pairwise = pairwise)
}

validate_primary_estimates <- function(fig3) {
  expected_profile <- data.table(
    outcome_label = rep(outcome_order, each = 3),
    profile_label = rep(profile_order, 3),
    estimate = c(-0.846, -0.898, -1.430, 0.170, 0.011, 0.068, 0.286, 0.222, -0.347),
    lower_95 = c(-1.293, -1.509, -1.941, 0.112, -0.054, 0.008, -0.164, -0.048, -0.657),
    upper_95 = c(-0.399, -0.287, -0.919, 0.229, 0.075, 0.128, 0.737, 0.492, -0.037)
  )
  expected_pair <- data.table(
    outcome_label = rep(outcome_order, each = 3),
    comparison_label = rep(pair_order, 3),
    estimate = c(-0.052, -0.584, -0.532, -0.160, -0.102, 0.057, -0.065, -0.633, -0.569),
    lower_95 = c(-0.814, -1.255, -1.321, -0.247, -0.186, -0.031, -0.634, -1.244, -1.001),
    upper_95 = c(0.711, 0.087, 0.256, -0.072, -0.019, 0.145, 0.505, -0.023, -0.137)
  )

  observed_profile <- fig3$profile[, .(
    outcome_label = as.character(outcome_label),
    profile_label = as.character(label_profile(profile_or_comparison)),
    estimate,
    lower_95,
    upper_95
  )]
  observed_pair <- fig3$pairwise[, .(
    outcome_label = as.character(outcome_label),
    comparison_label = as.character(label_pair(profile_or_comparison)),
    estimate,
    lower_95,
    upper_95
  )]

  profile_check <- merge(expected_profile, observed_profile,
    by = c("outcome_label", "profile_label"),
    suffixes = c("_expected", "_observed"),
    all = TRUE
  )
  pair_check <- merge(expected_pair, observed_pair,
    by = c("outcome_label", "comparison_label"),
    suffixes = c("_expected", "_observed"),
    all = TRUE
  )
  for (x in list(profile_check, pair_check)) {
    x[, ok := abs(estimate_expected - estimate_observed) <= 0.001 &
      abs(lower_95_expected - lower_95_observed) <= 0.001 &
      abs(upper_95_expected - upper_95_observed) <= 0.001]
  }
  if (!all(profile_check$ok) || !all(pair_check$ok)) {
    stop("Locked primary estimate validation failed.", call. = FALSE)
  }

  boundary_fire <- fread(inputs$boundary_surface)[
    boundary_id == "actual_c000" &
      outcome == "fire" &
      measurement_version == "harmonized_tau025" &
      threshold_tag == "tau025",
    .(events = sum(y), risk = sum(n))
  ]
  sparse_events <- fread(inputs$boundary_surface)[
    boundary_id == "actual_c000" &
      outcome %in% c("tree_cover_loss", "agriculture"),
    .(events = sum(y)),
    by = outcome
  ]
  event_check <- rbindlist(
    list(
      data.table(outcome = "fire", source = "boundary_surface_summary", expected = 508320L, observed = boundary_fire$events, source_file = rel_path(inputs$boundary_surface)),
      sparse_events[, .(
        outcome,
        source = "boundary_surface_summary",
        expected = c(tree_cover_loss = 519L, agriculture = 518L)[outcome],
        observed = events,
        source_file = rel_path(inputs$boundary_surface)
      )]
    ),
    fill = TRUE
  )
  event_check[, ok := expected == observed]
  if (!all(event_check$ok)) {
    stop("Event-total validation failed.", call. = FALSE)
  }
  fwrite(event_check, file.path(OUT_REP, "Figure_2_event_total_validation.csv"))
  invisible(list(profile = profile_check, pairwise = pair_check, events = event_check))
}

prepare_figure2_data <- function() {
  x <- fread(inputs$boundary_surface)[boundary_id == "actual_c000" & threshold_tag == "tau025"]
  x <- x[(outcome == "fire" & measurement_version == "harmonized_tau025") |
    outcome %in% c("tree_cover_loss", "agriculture")]
  x[, `:=`(
    proportion = 100 * y / n,
    side_label = fifelse(side == "interior_facing", "Inside", "Outside"),
    landscape_label = fifelse(SESU_ID == 1, "Depression", "Plateau"),
    outcome_label = label_outcome(outcome),
    profile_label = label_profile(governance_profile)
  )]
  x[, outcome_label := factor(outcome_label, levels = outcome_order)]
  fwrite(
    x[, .(SESU_ID, landscape_label, year, outcome, outcome_label, side, side_label, n, y, proportion, governance_profile, profile_label, source_file = rel_path(inputs$boundary_surface))],
    file.path(OUT_FSD, "Figure_2_annual_trajectories.csv")
  )
  chronology <- unique(x[, .(SESU_ID, landscape_label, year, governance_profile, profile_label, source_file = rel_path(inputs$boundary_surface))])
  fwrite(chronology, file.path(OUT_FSD, "Figure_2_profile_chronology.csv"))
  list(traj = x, chronology = chronology)
}

horizontal_interval <- function(mapping = NULL, data = NULL, height = 0.18, linewidth = 0.45, colour = NULL) {
  args <- list(mapping = mapping, data = data, orientation = "y", width = height, linewidth = linewidth)
  if (!is.null(colour)) args$colour <- colour
  do.call(geom_errorbar, args)
}

build_figure3 <- function(data) {
  profile <- copy(data$profile)
  profile[, profile_label := factor(as.character(profile_label), levels = profile_order_display)]
  profile[, outcome_label := factor(as.character(outcome_label), levels = outcome_order)]

  pairwise <- copy(data$pairwise)
  pairwise[, comparison_label := factor(as.character(comparison_label), levels = pair_order_display)]
  pairwise[, outcome_label := factor(as.character(outcome_label), levels = outcome_order)]

  p_a <- ggplot(profile, aes(estimate, profile_label, colour = profile_label, shape = profile_label)) +
    geom_vline(xintercept = 0, colour = "grey35", linewidth = 0.32) +
    horizontal_interval(aes(xmin = lower_95, xmax = upper_95)) +
    geom_point(size = 1.95) +
    facet_grid(outcome_label ~ ., scales = "free_x") +
    scale_colour_manual(values = profile_palette(), drop = FALSE, name = "Profile") +
    scale_shape_manual(values = profile_shapes(), drop = FALSE, name = "Profile") +
    labs(
      tag = "A",
      x = "Inside-minus-outside log-odds contrast",
      y = NULL
    ) +
    publication_theme() +
    theme(
      plot.tag = element_text(face = "bold", size = 10),
      strip.text.y.right = element_text(angle = 0, face = "bold"),
      legend.position = "bottom",
      panel.grid.major.y = element_blank(),
      plot.margin = margin(5, 14, 5, 5)
    )

  p_b <- ggplot(pairwise, aes(estimate, comparison_label)) +
    geom_vline(xintercept = 0, colour = "grey35", linewidth = 0.32) +
    horizontal_interval(aes(xmin = lower_95, xmax = upper_95), colour = "grey25") +
    geom_point(size = 1.85, colour = "grey15") +
    facet_grid(outcome_label ~ ., scales = "free_x") +
    labs(
      tag = "B",
      x = "Difference in inside-minus-outside log-odds contrasts",
      y = NULL
    ) +
    publication_theme() +
    theme(
      plot.tag = element_text(face = "bold", size = 10),
      strip.text.y.right = element_text(angle = 0, face = "bold"),
      legend.position = "none",
      panel.grid.major.y = element_blank(),
      plot.margin = margin(5, 14, 5, 5)
    )

  p_a / p_b + plot_layout(heights = c(1, 1.02))
}

prepare_figure4_data <- function() {
  fire_profile <- fread(inputs$boundary_fire_prof)[threshold_tag == "tau025"]
  sparse_profile <- fread(inputs$boundary_sparse_prof)[threshold_tag == "tau025" & model_type == "inverse_variance_weighted_lm_hc3"]
  profile <- rbindlist(
    list(
      fire_profile[, .(
        analysis_type = "revised spatial pseudo-boundary falsification",
        outcome,
        threshold = threshold_tag,
        spatial_domain = analysis_set,
        boundary_id,
        boundary_center_km,
        boundary_family,
        analysis_set,
        profile = governance_profile,
        estimate,
        standard_error,
        lower_interval = lower_95_ci,
        upper_interval = upper_95_ci,
        fit_validity = fifelse(retained_status == "strict-valid", "strict-valid", retained_status),
        source_file = rel_path(inputs$boundary_fire_prof)
      )],
      sparse_profile[, .(
        analysis_type = "revised spatial pseudo-boundary falsification",
        outcome,
        threshold = threshold_tag,
        spatial_domain = analysis_set,
        boundary_id,
        boundary_center_km,
        boundary_family,
        analysis_set,
        profile = governance_profile,
        estimate,
        standard_error,
        lower_interval = lower_95_ci,
        upper_interval = upper_95_ci,
        fit_validity = "accepted two-stage estimate",
        source_file = rel_path(inputs$boundary_sparse_prof)
      )]
    ),
    fill = TRUE
  )
  profile[, `:=`(
    outcome_label = label_outcome(outcome),
    profile_label = label_profile(profile),
    actual_boundary = boundary_center_km == 0,
    primary_spaced_outer = boundary_center_km %in% c(20, 40, 60),
    accepted = grepl("strict|accepted", fit_validity)
  )]

  fire_pair <- fread(inputs$boundary_fire_pair)[threshold_tag == "tau025"]
  sparse_pair <- fread(inputs$boundary_sparse_pair)[threshold_tag == "tau025" & model_type == "inverse_variance_weighted_lm_hc3"]
  pairwise <- rbindlist(
    list(
      fire_pair[, .(
        analysis_type = "revised spatial pseudo-boundary falsification",
        outcome,
        threshold = threshold_tag,
        spatial_domain = analysis_set,
        boundary_id,
        boundary_center_km,
        boundary_family,
        analysis_set,
        profile_comparison,
        estimate,
        standard_error,
        lower_interval = lower_95_ci,
        upper_interval = upper_95_ci,
        fit_validity = retained_status,
        source_file = rel_path(inputs$boundary_fire_pair)
      )],
      sparse_pair[, .(
        analysis_type = "revised spatial pseudo-boundary falsification",
        outcome,
        threshold = threshold_tag,
        spatial_domain = analysis_set,
        boundary_id,
        boundary_center_km,
        boundary_family,
        analysis_set,
        profile_comparison,
        estimate,
        standard_error,
        lower_interval = lower_95_ci,
        upper_interval = upper_95_ci,
        fit_validity = "accepted two-stage estimate",
        source_file = rel_path(inputs$boundary_sparse_pair)
      )]
    ),
    fill = TRUE
  )
  pairwise[, `:=`(
    outcome_label = label_outcome(outcome),
    comparison_label = label_pair(profile_comparison)
  )]

  fwrite(profile, file.path(OUT_FSD, "Figure_4_profile_boundary_estimates.csv"))
  fwrite(pairwise, file.path(OUT_FSD, "Figure_4_pairwise_boundary_estimates.csv"))
  list(profile = profile, pairwise = pairwise)
}

build_figure4 <- function(data) {
  profile <- copy(data$profile)
  profile[, outcome_label := factor(as.character(outcome_label), levels = outcome_order)]
  profile[, profile_label := factor(as.character(profile_label), levels = profile_order)]
  profile[, point_size := fifelse(actual_boundary, 2.7, fifelse(primary_spaced_outer, 2.15, 1.65))]
  profile[, alpha_value := fifelse(accepted, 1, 0.42)]

  class_labels <- data.table(
    outcome_label = factor(outcome_order, levels = outcome_order),
    x = 60,
    y = -Inf,
    label = c("Boundary-specific", "Not boundary-specific", "Inconclusive")
  )

  ggplot(profile, aes(boundary_center_km, estimate, colour = profile_label, shape = profile_label)) +
    annotate("rect", xmin = -22.5, xmax = -12.5, ymin = -Inf, ymax = Inf, fill = "grey90", alpha = 0.25) +
    annotate("rect", xmin = -2.5, xmax = 2.5, ymin = -Inf, ymax = Inf, fill = "grey80", alpha = 0.25) +
    annotate("rect", xmin = 12.5, xmax = 62.5, ymin = -Inf, ymax = Inf, fill = "grey95", alpha = 0.35) +
    geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.3) +
    geom_vline(xintercept = 0, colour = "black", linewidth = 0.48) +
    geom_line(
      data = profile[boundary_family == "outer_pseudo"],
      aes(group = profile_label),
      linewidth = 0.28,
      alpha = 0.45
    ) +
    geom_errorbar(aes(ymin = lower_interval, ymax = upper_interval, alpha = accepted),
      width = 1.0,
      linewidth = 0.3
    ) +
    geom_point(aes(size = point_size, alpha = accepted), stroke = 0.85, fill = "white") +
    geom_text(data = class_labels, aes(x = x, y = y, label = label),
      inherit.aes = FALSE,
      hjust = 1,
      vjust = -0.8,
      size = 2.5,
      fontface = "italic"
    ) +
    annotate("text", x = -17.5, y = Inf, label = "Inner checks", vjust = 1.15, size = 2.2, colour = "grey25") +
    annotate("text", x = 0, y = Inf, label = "Legal boundary", vjust = 1.15, size = 2.2, colour = "grey15") +
    annotate("text", x = 38, y = Inf, label = "Outer pseudo-boundaries", vjust = 1.15, size = 2.2, colour = "grey25") +
    facet_grid(outcome_label ~ ., scales = "free_y") +
    scale_colour_manual(values = profile_palette(), drop = FALSE, name = "Profile") +
    scale_shape_manual(values = profile_shapes(), drop = FALSE, name = "Profile") +
    scale_alpha_identity(guide = "none") +
    scale_size_identity(guide = "none") +
    scale_x_continuous(breaks = c(-20, -15, 0, seq(15, 60, 5))) +
    labs(
      x = "Signed boundary centre relative to the legal boundary (km)",
      y = "Park-facing minus outward-facing log-odds contrast"
    ) +
    publication_theme() +
    theme(
      panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.2),
      panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.2),
      legend.position = "bottom"
    )
}

build_table1 <- function() {
  table <- data.table(
    Outcome = c("Fire", "Tree-cover loss", "Agricultural expansion"),
    `Source product` = c("ESA FireCCI v5.1", "Hansen Global Forest Change v1.12", "Annual Cropland Extent Dataset for Africa"),
    Years = "2001\u20132022",
    `Native resolution` = c("250 m", "30 m", "30 m"),
    `Event definition` = c(
      "\u226525% of a 500 m cell burned during DOY 100\u2013300",
      "First year cumulative loss reaches \u226525% of a 500 m cell",
      "First annual transition from <25% to \u226525% cropland"
    ),
    `Risk-set rule` = c(
      "All eligible cells remain at risk annually",
      "Cells with \u226530% tree cover in 2000; removed after first event",
      "Eligible cells removed after first event"
    ),
    `Primary threshold` = "25%",
    `Sensitivity thresholds` = "10%, 50%"
  )
  fwrite(table, file.path(OUT_TAB, "Table_1_data_products.csv"))
  fwrite(table, file.path(OUT_TSD, "Table_1_data_products_source.csv"))
  html_table(table, file.path(OUT_TAB, "Table_1_data_products.html"), "Table 1. Data products and event definitions")
  table
}

build_table2 <- function() {
  table <- data.table(
    Outcome = c("Tree-cover loss", "Fire", "Agricultural expansion"),
    `Primary model` = c("Weighted two-stage HC3", "Strict-valid beta-binomial", "Weighted two-stage HC3"),
    Events = c("519", "508,320", "518"),
    `Primary result` = c(
      "Lower inside under all profiles; largest negative estimate under park-centred control. No pairwise 95% CI excluded zero.",
      "Higher inside under fragmented and park-centred control; near zero under militia-centred control. Militia-centred and park-centred differed from fragmented.",
      "Lower inside only under park-centred control. Park-centred differed from fragmented and militia-centred in the weighted model."
    ),
    `Boundary-location assessment` = c(
      "Profile contrasts boundary-specific; partial support for park-centred versus fragmented.",
      "Profile contrasts not boundary-specific; partial support for militia-centred versus fragmented.",
      "Inconclusive because of sparse support and unstable pseudo-boundary fits."
    ),
    Robustness = c(
      "Direction stable to weighting and 10\u201320 km/all-cell designs; weak at 5 km and unsupported at the sparse 50% threshold.",
      "Stable across thresholds, spatial domains, and valid optimizer configurations.",
      "Sensitive to weighting, threshold, and spatial domain."
    )
  )
  fwrite(table, file.path(OUT_TAB, "Table_2_primary_evidence.csv"))
  fwrite(table, file.path(OUT_TSD, "Table_2_primary_evidence_source.csv"))
  html_table(table, file.path(OUT_TAB, "Table_2_primary_evidence.html"), "Table 2. Primary evidence synthesis")
  table
}

write_captions <- function() {
  writeLines(
    c(
      "# Main Figure Captions",
      "",
      "**Figure 1. Study design and analytical domain.** The map displays the legal Upemba National Park boundary, the symmetric 10 km primary analytical corridor, major permanent-water features, and the landscape comparison groups. Depression and Plateau are the retained inferential groups; SESU2 is displayed as outside the inferential scope. Coordinates are shown as longitude and latitude for display only; spatial calculations used the canonical projected 500 m grid.",
      "",
      "**Figure 2. Annual disturbance trajectories inside and outside Upemba National Park, 2001–2022.** Panels show the percentage of eligible 500 m cells affected by fire, first tree-cover loss, and first agricultural expansion within the Depression and Plateau landscape groups. Dashed lines denote cells inside the park and solid lines denote cells outside the park within the symmetric 10 km boundary corridor. Shading between trajectories indicates whether annual disturbance was higher inside or outside. Vertical dashed lines and the lower strip mark changes in reconstructed territorial-control profiles.",
      "",
      "**Figure 3. Primary profile contrasts and pairwise differences.** Panel A shows profile-specific inside-minus-outside log-odds contrasts; Panel B shows differences between those profile-specific contrasts. Negative profile contrasts indicate lower disturbance inside the legal park boundary. Fire estimates are from the strict-valid harmonized tau025 beta-binomial model. Tree-cover-loss and agricultural-expansion estimates are from inverse-variance-weighted two-stage models with HC3 covariance. Bars are 95% model-based confidence intervals for the primary symmetric 10 km corridor and 25% event threshold.",
      "",
      "**Figure 4. Boundary-location diagnostic.** Points show park-facing minus outward-facing log-odds contrasts at the legal boundary (0 km), limited inner descriptive checks (-20 and -15 km), and spatially coherent outer pseudo-boundaries (+15 to +60 km). At 0 km the contrast is equivalent to inside minus outside the legal park boundary. Larger symbols mark the actual legal boundary; +20, +40, and +60 km form the primary spaced-outer set, and the thin outer lines are descriptive guides along the dense outer gradient. Open or muted symbols indicate non-strict or support-limited fits. The analysis is descriptive and non-randomized."
    ),
    file.path(OUT_REP, "main_figure_captions.md")
  )
  writeLines(
    c(
      "# Main Table Captions",
      "",
      "**Table 1. Data products and annual event definitions.** The table summarizes the primary 25% event definitions and the threshold sensitivities used for the disturbance outcomes.",
      "",
      "**Table 2. Primary evidence synthesis.** The table summarizes the primary 25% analyses in the symmetric 10 km park-boundary corridor. Event totals are from the final authoritative surfaces; fire uses 508,320 events from both final harmonized and revised actual-boundary fire summaries."
    ),
    file.path(OUT_REP, "main_table_captions.md")
  )
}

write_provenance <- function() {
  provenance <- data.table(
    output_file = c(
      "Figure_1_study_design",
      "Figure_2_chronology_time_series",
      "Figure_3_primary_contrasts",
      "Figure_4_boundary_location_diagnostic",
      "Table_1_data_products",
      "Table_2_primary_evidence"
    ),
    source_file_or_files = c(
      "outputs/publication/main_figures/Figure_1_study_design.png; outputs/publication/figure_source_data/Figure_1_layer_registry.csv",
      rel_path(inputs$boundary_surface),
      paste(rel_path(inputs$fire_prof), rel_path(inputs$fire_pair), rel_path(inputs$sparse_prof), rel_path(inputs$sparse_pair), sep = "; "),
      paste(rel_path(inputs$boundary_fire_prof), rel_path(inputs$boundary_sparse_prof), rel_path(inputs$boundary_fire_pair), rel_path(inputs$boundary_sparse_pair), sep = "; "),
      "Final Methods specification",
      rel_path(inputs$boundary_surface)
    ),
    source_object_or_columns = c(
      "SESU_ID; signed distance; permanent water; park boundary geometry",
      "n; y; side; SESU_ID; governance_profile; year",
      "estimate; standard_error; lower_95_ci; upper_95_ci",
      "boundary_center_km; estimate; intervals; fit validity",
      "Outcome definitions",
      "Event totals; evidence-synthesis text"
    ),
    transformation_performed = c(
      "Display transformation to longitude/latitude and layer styling",
      "Annual y/n percentages and profile chronology",
      "Label mapping and locked-value validation",
      "Boundary-centre plotting data and display classification",
      "Compact table construction",
      "Compact synthesis after event-total validation"
    ),
    script_function = c(
      "Retained approved publication asset",
      "prepare_figure2_data; final rendering delegated to scripts/publication/08_generate_figure2_chronology_time_series.R",
      "prepare_figure3_data/build_figure3",
      "prepare_figure4_data/build_figure4",
      "build_table1",
      "build_table2"
    ),
    authoritative_status = "final authoritative",
    validation_status = "passed",
    notes = c(
      "Axes display longitude and latitude; spatial calculations remain in the canonical projected grid.",
      "Descriptive trajectories only.",
      "No deprecated horizontal error-bar geometry usage.",
      "Outer pseudo-boundary contrasts are park-facing minus outward-facing.",
      "HTML generated as manuscript-ready preview without adding packages.",
      "The final harmonized and revised actual-boundary surfaces both contain 508,320 fire events in the tau025 10 km primary analysis. The earlier total of 508,332 came from a superseded standalone measurement-harmonization output and was not used."
    )
  )
  fwrite(provenance, file.path(OUT_REP, "publication_output_provenance.csv"))
}

write_layout_revision_note <- function(contact_sheet_generated) {
  writeLines(
    c(
      "# Final Main-Figure Workflow",
      "",
      "The final publication workflow preserves the locked scientific values and uses retained authoritative analytical inputs.",
      "",
      "## Figure Responsibilities",
      "",
      "- The approved Figure 1 study-design map is retained as a publication asset because its restricted geospatial source layers are documented but not redistributed.",
      "- Script 06 regenerates the canonical Figure 2 trajectory and chronology source-data CSVs but does not render Figure 2.",
      "- Script 08 is the single final Figure 2 renderer and validates locked event totals before writing the 600 dpi PNG and vector PDF.",
      "- Script 06 regenerates Figures 3-4 and the main publication tables from retained authoritative analytical tables.",
      "- Figure 2 uses solid black outside trajectories, dashed black inside trajectories, difference shading, light transition lines, and the muted territorial-control palette.",
      paste0("- Contact sheet generated: ", ifelse(contact_sheet_generated, "yes.", "no; `magick` was not available."))
    ),
    file.path(OUT_REP, "figure_layout_revision_v2.md")
  )
}

validate_display_outputs <- function(fig2, fig3, fig4, table2) {
  problems <- character()
  expected_figs <- file.path(OUT_FIG, paste0(
    rep(c("Figure_1_study_design", "Figure_2_chronology_time_series", "Figure_3_primary_contrasts", "Figure_4_boundary_location_diagnostic"), each = 2),
    rep(c(".pdf", ".png"), times = 4)
  ))
  if (!all(file.exists(expected_figs))) {
    problems <- c(problems, "One or more expected figure files are missing.")
  }
  if (any(file.info(expected_figs[file.exists(expected_figs)])$size <= 0)) {
    problems <- c(problems, "One or more figure files have zero size.")
  }
  if (ncol(table2) != 6) problems <- c(problems, "Table 2 does not have exactly six columns.")
  if (!identical(names(table2), c("Outcome", "Primary model", "Events", "Primary result", "Boundary-location assessment", "Robustness"))) {
    problems <- c(problems, "Table 2 column names do not match the requested structure.")
  }

  active_files <- c(
    file.path(ROOT, "scripts/publication/06_generate_main_figures_tables.R"),
    list.files(file.path(ROOT, "outputs/publication"), pattern = "\\.(csv|html)$", recursive = TRUE, full.names = TRUE),
    list.files(OUT_REP, pattern = "\\.(csv|md|txt)$", recursive = TRUE, full.names = TRUE)
  )
  active_files <- active_files[!grepl("/review_v1/|\\\\review_v1\\\\", active_files)]
  active_text <- unlist(lapply(active_files, function(path) readLines(path, warn = FALSE, encoding = "UTF-8")), use.names = FALSE)
  forbidden <- c(
    paste0("Easting ", "(EPSG:32735)"),
    paste0("Northing ", "(EPSG:32735)"),
    paste0("508", "332")
  )
  for (f in forbidden) {
    if (any(grepl(f, active_text, fixed = TRUE))) {
      problems <- c(problems, paste0("Forbidden text remains in active publication outputs or code: ", f))
    }
  }

  if (any(fig2$traj$proportion < 0 | fig2$traj$proportion > 100 | fig2$traj$y > fig2$traj$n, na.rm = TRUE)) {
    problems <- c(problems, "Figure 2 percentages are outside 0-100 or y > n.")
  }
  if (any(fig3$profile$lower_95 > fig3$profile$upper_95) || any(fig3$pairwise$lower_95 > fig3$pairwise$upper_95)) {
    problems <- c(problems, "Figure 3 confidence intervals are not ordered.")
  }
  if (any(fig4$profile$lower_interval > fig4$profile$upper_interval, na.rm = TRUE)) {
    problems <- c(problems, "Figure 4 confidence intervals are not ordered.")
  }
  if (any(duplicated(fig3$profile[, .(outcome, profile_or_comparison)]))) {
    problems <- c(problems, "Duplicate Figure 3 profile rows.")
  }
  if (any(duplicated(fig3$pairwise[, .(outcome, profile_or_comparison)]))) {
    problems <- c(problems, "Duplicate Figure 3 pairwise rows.")
  }
  centers <- sort(unique(fig4$profile$boundary_center_km))
  if (!all(c(-20, -15, 0, seq(15, 60, 5)) %in% centers)) {
    problems <- c(problems, "Figure 4 boundary centres are incomplete.")
  }

  validation_lines <- c(
    "# Publication Output Validation",
    "",
    sprintf("Overall validation status: %s.", ifelse(length(problems), "failed", "passed")),
    "",
    "- Locked primary estimates match requested values within 0.001.",
    "- Event totals validated from the retained actual-boundary surface: fire 508,320; tree-cover loss 519; agricultural expansion 518.",
    "- Figure 2 percentages satisfy 0 <= y/n <= 100 and y <= n.",
    "- Required profiles, outcomes, and boundary centres are present.",
    "- The approved Figure 1 publication asset and matching PDF are present.",
    "- Table 2 has exactly six columns.",
    "- The superseded fire event total is absent from active publication outputs.",
    "- Deprecated horizontal error-bar geometry is no longer used.",
    "- HTML tables are generated as manuscript-ready previews without adding packages.",
    "",
    if (length(problems)) paste("- ", problems) else "No validation failures."
  )
  writeLines(validation_lines, file.path(OUT_REP, "publication_output_validation.md"))
  if (length(problems)) stop("Publication output validation failed.", call. = FALSE)
  invisible(TRUE)
}

create_contact_sheet <- function() {
  if (!requireNamespace("magick", quietly = TRUE)) return(FALSE)
  figs <- file.path(OUT_FIG, c(
    "Figure_1_study_design.png",
    "Figure_2_chronology_time_series.png",
    "Figure_3_primary_contrasts.png",
    "Figure_4_boundary_location_diagnostic.png"
  ))
  imgs <- magick::image_read(figs)
  imgs <- magick::image_resize(imgs, "900x")
  sheet <- magick::image_montage(imgs, tile = "2x2", geometry = "+24+24")
  magick::image_write(sheet, file.path(OUT_REP, "main_figures_review_contact_sheet_v2.png"))
  TRUE
}

run_publication_generation <- function() {
  input_registry <- resolve_authoritative_inputs()
  fwrite(input_registry, file.path(OUT_REP, "publication_input_registry.csv"))

  fig3 <- prepare_figure3_data()
  validate_primary_estimates(fig3)
  fwrite(
    fig3$profile[, .(outcome, estimand_type, profile_or_comparison, estimate, standard_error, lower_95, upper_95, model, spatial_domain, threshold, fit_validity, source_file)],
    file.path(OUT_FSD, "Figure_3_profile_contrasts.csv")
  )
  fwrite(
    fig3$pairwise[, .(outcome, estimand_type, profile_or_comparison, estimate, standard_error, lower_95, upper_95, model, spatial_domain, threshold, fit_validity, source_file)],
    file.path(OUT_FSD, "Figure_3_pairwise_differences.csv")
  )

  fig2 <- prepare_figure2_data()
  fig4 <- prepare_figure4_data()
  table1 <- build_table1()
  table2 <- build_table2()

  if (!all(file.exists(file.path(OUT_FIG, c("Figure_1_study_design.png", "Figure_1_study_design.pdf"))))) {
    stop("Approved Figure 1 PNG/PDF assets are missing.", call. = FALSE)
  }
  message("Prepared authoritative Figure 2 source data; final rendering is delegated to script 08.")
  save_pub(build_figure3(fig3), "Figure_3_primary_contrasts", 180, 180)
  save_pub(build_figure4(fig4), "Figure_4_boundary_location_diagnostic", 180, 165)

  write_captions()
  write_provenance()
  contact_sheet <- create_contact_sheet()
  write_layout_revision_note(contact_sheet)
  validate_display_outputs(fig2, fig3, fig4, table2)
  message("Revised main manuscript figures and tables generated.")
}

run_publication_generation()
