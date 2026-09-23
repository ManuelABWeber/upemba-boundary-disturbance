#!/usr/bin/env Rscript
# Rebuilds main Figures 2-4 with a single territorial-control palette taken from
# the manuscript Figure 2 timeline, and with per-outcome effect scales.
#
# Reads the frozen exports in outputs/publication/figure_source_data so the
# rebuilt figures carry the same numbers as the published set.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
  library(grid)
})

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
FSD <- file.path(ROOT, "outputs", "publication", "figure_source_data")
OUT_FIG <- file.path(ROOT, "outputs", "publication", "main_figures_revised")
dir.create(OUT_FIG, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------- palette ----
# Sampled from outputs/publication/figure_sources/timeline fig.png (Figure 2).
profile_fill <- c(
  "Fragmented control"      = "#D7D7D7",
  "Militia-centred control" = "#B9A16B",
  "Park-centred control"    = "#6F86A6"
)

darken <- function(hex, factor) {
  rgb_mat <- col2rgb(hex)
  apply(rgb_mat, 2, function(z) {
    do.call(rgb, as.list(c(pmax(0, z * factor) / 255)))
  })
}

# Fills stay identical to Figure 2; strokes and intervals are the same hue
# darkened so thin marks stay legible against white.
profile_stroke <- setNames(
  c(darken(profile_fill[["Fragmented control"]], 0.56),
    darken(profile_fill[["Militia-centred control"]], 0.70),
    darken(profile_fill[["Park-centred control"]], 0.72)),
  names(profile_fill)
)

profile_shape <- c(
  "Fragmented control"      = 21,
  "Militia-centred control" = 24,
  "Park-centred control"    = 22
)

profile_order <- names(profile_fill)
outcome_order <- c("Tree-cover loss", "Fire", "Agricultural expansion")

profile_map <- c(
  "Neither actor dominant" = "Fragmented control",
  "Militia dominant"       = "Militia-centred control",
  "Park dominant"          = "Park-centred control"
)
outcome_map <- c(
  tree_cover_loss = "Tree-cover loss",
  fire            = "Fire",
  agriculture     = "Agricultural expansion"
)
pair_map <- c(
  "Militia dominant minus Neither actor dominant" = "Militia-centred − Fragmented",
  "Park dominant minus Neither actor dominant"    = "Park-centred − Fragmented",
  "Park dominant minus Militia dominant"          = "Park-centred − Militia-centred"
)
pair_order <- unname(pair_map)

# ------------------------------------------------------------------ theme ----
base_theme <- function(base_size = 7.6) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.background   = element_rect(fill = "white", colour = NA),
      panel.background  = element_rect(fill = "white", colour = NA),
      panel.grid.minor  = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.22),
      axis.title        = element_text(size = rel(1.0), colour = "grey15"),
      axis.text         = element_text(size = rel(0.95), colour = "grey25"),
      axis.text.y       = element_text(hjust = 0, colour = "grey15"),
      plot.title        = element_text(face = "bold", size = rel(1.05),
                                       colour = "grey10", margin = margin(b = 3)),
      plot.title.position = "plot",
      legend.position   = "none",
      plot.margin       = margin(3, 4, 3, 3)
    )
}

save_pub <- function(g, stem, width_mm, height_mm) {
  ggsave(file.path(OUT_FIG, paste0(stem, ".pdf")), g,
         width = width_mm / 25.4, height = height_mm / 25.4,
         device = cairo_pdf, bg = "white")
  ggsave(file.path(OUT_FIG, paste0(stem, ".png")), g,
         width = width_mm / 25.4, height = height_mm / 25.4,
         dpi = 600, bg = "white")
  invisible(g)
}

# ================================================================ FIGURE 3 ====
prof3 <- fread(file.path(FSD, "Figure_3_profile_contrasts.csv"))
pair3 <- fread(file.path(FSD, "Figure_3_pairwise_differences.csv"))

prof3[, `:=`(
  outcome_label = factor(unname(outcome_map[outcome]), levels = outcome_order),
  profile_label = factor(unname(profile_map[profile_or_comparison]),
                         levels = rev(profile_order))
)]
pair3[, `:=`(
  outcome_label = factor(unname(outcome_map[outcome]), levels = outcome_order),
  comparison_label = factor(unname(pair_map[profile_or_comparison]),
                            levels = rev(pair_order))
)]

# Forest panel: one facet row per outcome, each with its own effect scale so a
# 0.06 fire contrast is not flattened by a 1.4 tree-cover-loss contrast.
forest_core <- function(d, yvar, colour_rows, x_title) {
  d <- copy(d)
  # Use explicit numeric row positions. With free-y facets, independent
  # discrete-scale training can otherwise reorder rows according to encounter
  # order, which misaligns the forest panel and the adjacent value column.
  y_levels <- levels(d[[yvar]])
  d[, `:=`(
    row_group = get(yvar),
    yrow = match(as.character(get(yvar)), y_levels)
  )]
  y_key <- unique(d[, .(yrow, row_label = as.character(row_group))])
  setorder(y_key, yrow)

  # Zero is the reference for every contrast, so keep it inside each facet's
  # range even when all intervals sit on one side of it.
  # yrow is carried through so the blank rows reuse an existing category rather
  # than adding an empty one, which would shift the rows out of alignment with
  # the value column.
  pad <- d[, {
    rng <- range(c(0, lower_95, upper_95))
    span <- diff(rng)
    .(x = c(rng[1] - 0.10 * span, rng[2] + 0.10 * span), yrow = yrow[1])
  }, by = outcome_label]

  p <- ggplot(d, aes(estimate, yrow)) +
    geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.34) +
    geom_blank(data = pad, aes(x = x, y = yrow), inherit.aes = FALSE)

  if (colour_rows) {
    p <- p +
      geom_errorbar(aes(xmin = lower_95, xmax = upper_95,
                        colour = row_group),
                    orientation = "y", width = 0, linewidth = 0.62) +
      geom_point(aes(fill = row_group, shape = row_group,
                     colour = row_group),
                 size = 2.3, stroke = 0.62) +
      scale_colour_manual(values = profile_stroke, drop = FALSE) +
      scale_fill_manual(values = profile_fill, drop = FALSE) +
      scale_shape_manual(values = profile_shape, drop = FALSE)
  } else {
    p <- p +
      geom_errorbar(aes(xmin = lower_95, xmax = upper_95),
                    orientation = "y", width = 0, linewidth = 0.62,
                    colour = "grey35") +
      geom_point(size = 2.15, shape = 21, fill = "grey40", colour = "grey20",
                 stroke = 0.62)
  }

  p +
    facet_wrap(~outcome_label, ncol = 1, scales = "free", strip.position = "top") +
    scale_y_continuous(
      breaks = y_key$yrow, labels = y_key$row_label,
      expand = expansion(mult = 0.12)
    ) +
    scale_x_continuous(n.breaks = 5, expand = expansion(mult = 0.02)) +
    labs(x = x_title, y = NULL) +
    base_theme() +
    theme(
      strip.text = element_text(face = "bold", size = rel(1.05), hjust = 0,
                                colour = "grey10", margin = margin(b = 2, t = 3)),
      axis.title.x = element_text(size = rel(1.0), margin = margin(t = 3)),
      panel.spacing.y = unit(3.5, "mm")
    )
}

build_figure3 <- function() {
  panel <- function(d, yvar, colour_rows, x_title, tag) {
    d <- copy(d)
    forest_core(d, yvar, colour_rows, x_title) +
      plot_annotation(
        title = tag,
        theme = theme(plot.title = element_text(
          face = "bold", size = 8.6, family = "sans", colour = "grey10",
          margin = margin(b = 1)
        ))
      )
  }

  a <- panel(prof3, "profile_label", TRUE,
             "Inside − outside log-odds contrast",
             "A")
  b <- panel(pair3, "comparison_label", FALSE,
             "Difference between profile contrasts",
             "B")

  wrap_elements(a) / wrap_elements(b)
}

# ================================================================ FIGURE 4 ====
prof4 <- fread(file.path(FSD, "Figure_4_profile_boundary_estimates.csv"))

# The exported `accepted` flag is TRUE everywhere because the upstream regex
# matched the substring "strict" inside "not strict-valid". Recompute it.
prof4[, strict := fit_validity %in% c("strict-valid", "accepted two-stage estimate")]

# The manuscript caption describes the legal boundary and the ten outward
# offsets (+15 to +60 km); the inner checks live in supplementary Table S15.
prof4 <- prof4[boundary_center_km >= 0]
prof4[, `:=`(
  outcome_label = factor(unname(outcome_map[outcome]), levels = outcome_order),
  profile_label = factor(unname(profile_map[profile]), levels = profile_order),
  is_legal = boundary_center_km == 0
)]

prof4[, estimate_status := factor(
  fifelse(is_legal,
          "Legal boundary",
          fifelse(strict,
                  "Pseudo-boundary: valid interval",
                  "Pseudo-boundary: interval unavailable")),
  levels = c("Legal boundary",
             "Pseudo-boundary: valid interval",
             "Pseudo-boundary: interval unavailable")
)]

build_figure4 <- function() {
  ggplot(prof4, aes(boundary_center_km, estimate)) +
    geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.3) +
    geom_line(data = prof4[is_legal == FALSE],
              aes(group = profile_label),
              colour = "grey55", linewidth = 0.3, alpha = 0.75) +
    geom_errorbar(data = prof4[strict == TRUE],
                  aes(ymin = lower_interval, ymax = upper_interval),
                  colour = "grey35",
                  width = 0, linewidth = 0.34) +
    geom_point(aes(fill = profile_label, colour = profile_label,
                   shape = estimate_status, size = estimate_status),
               stroke = 0.65) +
    facet_grid(outcome_label ~ profile_label, scales = "free_y", switch = "y") +
    scale_colour_manual(values = profile_stroke, drop = FALSE, guide = "none") +
    scale_fill_manual(values = profile_fill, drop = FALSE, guide = "none") +
    scale_shape_manual(
      values = c(
        "Legal boundary" = 23,
        "Pseudo-boundary: valid interval" = 21,
        "Pseudo-boundary: interval unavailable" = 1
      ),
      name = "Estimate status",
      drop = FALSE
    ) +
    scale_size_manual(
      values = c(
        "Legal boundary" = 1.35,
        "Pseudo-boundary: valid interval" = 1.35,
        "Pseudo-boundary: interval unavailable" = 1.25
      ),
      guide = "none",
      drop = FALSE
    ) +
    scale_x_continuous(breaks = c(0, 20, 40, 60),
                       labels = c("Legal\nboundary", "20", "40", "60"),
                       expand = expansion(mult = c(0.07, 0.05))) +
    scale_y_continuous(expand = expansion(mult = c(0.10, 0.10))) +
    labs(
      x = "Boundary centre relative to the legal boundary (km)",
      y = "Log-odds difference (park-facing − outward-facing)"
    ) +
    guides(shape = guide_legend(
      override.aes = list(
        colour = "grey30",
        fill = "grey75",
        size = c(1.8, 1.8, 1.8)
      )
    )) +
    base_theme() +
    theme(
      panel.grid.major.y = element_line(colour = "grey93", linewidth = 0.22),
      panel.grid.major.x = element_blank(),
      strip.text.x = element_text(face = "bold", size = rel(1.0),
                                  colour = "grey10", margin = margin(b = 3)),
      strip.text.y.left = element_text(face = "bold", size = rel(1.0),
                                       angle = 90, colour = "grey10",
                                       margin = margin(r = 3)),
      strip.placement = "outside",
      panel.spacing.x = unit(3.2, "mm"),
      panel.spacing.y = unit(3.0, "mm"),
      axis.text.y = element_text(hjust = 1),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = rel(0.90)),
      legend.text = element_text(size = rel(0.85)),
      legend.key.width = unit(4.5, "mm"),
      legend.spacing.x = unit(1.5, "mm")
    )
}

# ================================================================ FIGURE 2 ====
chron <- fread(file.path(FSD, "Figure_2_profile_chronology.csv"))
chron[, profile_label := factor(profile_label, levels = profile_order)]
chron[, landscape_label := factor(landscape_label, levels = c("Depression", "Plateau"))]

episodes <- chron[order(landscape_label, year)][
  , rleid := rleid(profile_label), by = landscape_label
][, .(
  start = min(year), end = max(year), profile_label = profile_label[1]
), by = .(landscape_label, rleid)]
episodes[, `:=`(ymin = start - 0.5, ymax = end + 0.5)]
episodes[, mid := (ymin + ymax) / 2]

build_figure2 <- function() {
  ggplot(episodes) +
    geom_rect(aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax,
                  fill = profile_label),
              colour = "grey20", linewidth = 0.28) +
    geom_text(aes(x = 0.5, y = mid, label = profile_label),
              size = 2.3, colour = "grey10", family = "sans") +
    facet_wrap(~landscape_label, nrow = 1) +
    scale_fill_manual(values = profile_fill, drop = FALSE,
                      name = "Territorial-control profile") +
    scale_y_reverse(breaks = seq(2001, 2022, 1), expand = expansion(mult = 0.01)) +
    scale_x_continuous(expand = c(0, 0)) +
    labs(x = NULL, y = NULL) +
    base_theme() +
    theme(
      panel.grid.major.x = element_blank(),
      axis.text.x = element_blank(),
      strip.text = element_text(face = "bold", size = rel(1.2), colour = "grey10"),
      legend.position = "bottom",
      legend.title = element_text(size = rel(1.0)),
      legend.key.height = unit(0.5, "lines"),
      legend.key.width = unit(1.2, "lines")
    )
}

# ------------------------------------------------------------------- run -----
save_pub(build_figure3(), "Figure_3_primary_contrasts", 175, 195)
save_pub(build_figure4(), "Figure_4_boundary_location_diagnostic", 180, 150)
save_pub(build_figure2(), "Figure_2_chronology_blocks", 130, 150)

cat("Rebuilt Figures 2-4 in", OUT_FIG, "\n")
