#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
  library(grid)
  library(ragg)
})

ROOT <- Sys.getenv("CH1_ROOT", unset = getwd())
ROOT <- normalizePath(ROOT, winslash = "/", mustWork = TRUE)

YEAR_MIN <- 2001L
YEAR_MAX <- 2022L
YEAR_BREAKS <- c(2001L, 2005L, 2010L, 2015L, 2022L)

SHOW_UNCERTAINTY <- TRUE
SHOW_DIFFERENCE_FILL <- TRUE
DISPLAY_AS_PERCENT <- TRUE

# Muted palette aligned to the old figure style
PROFILE_COLOURS <- c(
  "Fragmented control" = "#8F8F8F",
  "Militia-centred control" = "#B7A164",
  "Park-centred control" = "#748CB4"
)

DIFFERENCE_COLOURS <- c(
  "Inside higher" = "#E7C9C9",
  "Outside higher" = "#D5E4D1"
)

OUT_FIG <- file.path(ROOT, "outputs", "publication", "main_figures")
OUT_FSD <- file.path(ROOT, "outputs", "publication", "figure_source_data")
OUT_REP <- file.path(ROOT, "reports", "publication_outputs")

dir.create(OUT_FIG, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_FSD, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_REP, recursive = TRUE, showWarnings = FALSE)

FIGURE_STEM <- "Figure_2_chronology_time_series_old_style_candidate_pubqual"

SOURCE_TRAJ <- file.path(
  ROOT,
  "outputs", "publication", "figure_source_data",
  "Figure_2_annual_trajectories.csv"
)

SOURCE_CHRONOLOGY <- file.path(
  ROOT,
  "outputs", "publication", "figure_source_data",
  "Figure_2_profile_chronology.csv"
)

SOURCE_BOUNDARY <- file.path(
  ROOT,
  "analysis_spatial_falsification_revised_dev",
  "tables",
  "boundary_surface_summary.csv"
)

PROFILE_MAP <- c(
  "Neither actor dominant" = "Fragmented control",
  "Militia dominant" = "Militia-centred control",
  "Park dominant" = "Park-centred control"
)

OUTCOME_MAP <- c(
  "tree_cover_loss" = "Tree-cover loss",
  "fire" = "Fire",
  "agriculture" = "Agricultural expansion"
)

LANDSCAPE_MAP <- c(
  "1" = "Depression",
  "3" = "Plateau"
)

PROFILE_LEVELS <- c(
  "Fragmented control",
  "Militia-centred control",
  "Park-centred control"
)

OUTCOME_LEVELS <- c(
  "Fire",
  "Tree-cover loss",
  "Agricultural expansion"
)

OUTCOME_STRIP_LABELS <- c(
  "Fire" = "Fire",
  "Tree-cover loss" = "Tree-cover loss",
  "Agricultural expansion" = "Agricultural\nexpansion"
)

LANDSCAPE_LEVELS <- c("Depression", "Plateau")
SIDE_LEVELS <- c("Outside", "Inside")

stop_missing <- function(path) {
  if (!file.exists(path)) stop("Missing required file: ", path, call. = FALSE)
}

read_authoritative_figure2_data <- function() {
  if (file.exists(SOURCE_TRAJ)) {
    message("Reading final Figure 2 source data: ", SOURCE_TRAJ)
    x <- fread(SOURCE_TRAJ)
    
    required <- c(
      "SESU_ID", "year", "outcome", "side", "n", "y",
      "governance_profile"
    )
    missing <- setdiff(required, names(x))
    if (length(missing) > 0L) {
      stop(
        "Figure_2_annual_trajectories.csv is missing: ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
    
    if (!"landscape_label" %in% names(x)) {
      x[, landscape_label := unname(LANDSCAPE_MAP[as.character(SESU_ID)])]
    }
    if (!"outcome_label" %in% names(x)) {
      x[, outcome_label := unname(OUTCOME_MAP[outcome])]
    }
    if (!"side_label" %in% names(x)) {
      x[, side_label := fifelse(
        side == "interior_facing", "Inside",
        fifelse(side == "exterior_facing", "Outside", NA_character_)
      )]
    }
    if (!"profile_label" %in% names(x)) {
      x[, profile_label := unname(PROFILE_MAP[governance_profile])]
    }
    
    chronology <- if (file.exists(SOURCE_CHRONOLOGY)) {
      fread(SOURCE_CHRONOLOGY)
    } else {
      unique(x[, .(
        SESU_ID,
        landscape_label,
        year,
        governance_profile,
        profile_label
      )])
    }
    
    return(list(
      trajectories = x,
      chronology = chronology,
      input_path = SOURCE_TRAJ,
      chronology_path = if (file.exists(SOURCE_CHRONOLOGY)) {
        SOURCE_CHRONOLOGY
      } else {
        SOURCE_TRAJ
      }
    ))
  }
  
  message(
    "Final Figure 2 source CSV was not found; reconstructing from: ",
    SOURCE_BOUNDARY
  )
  stop_missing(SOURCE_BOUNDARY)
  
  x <- fread(SOURCE_BOUNDARY)
  
  required <- c(
    "boundary_id", "threshold_tag", "outcome", "measurement_version",
    "SESU_ID", "year", "side", "n", "y", "governance_profile"
  )
  missing <- setdiff(required, names(x))
  if (length(missing) > 0L) {
    stop(
      "boundary_surface_summary.csv is missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  
  x <- x[
    boundary_id == "actual_c000" &
      threshold_tag == "tau025" &
      (
        (outcome == "fire" & measurement_version == "harmonized_tau025") |
          outcome %in% c("tree_cover_loss", "agriculture")
      )
  ]
  
  x[, `:=`(
    landscape_label = unname(LANDSCAPE_MAP[as.character(SESU_ID)]),
    outcome_label = unname(OUTCOME_MAP[outcome]),
    side_label = fifelse(
      side == "interior_facing", "Inside",
      fifelse(side == "exterior_facing", "Outside", NA_character_)
    ),
    profile_label = unname(PROFILE_MAP[governance_profile])
  )]
  
  chronology <- unique(x[, .(
    SESU_ID,
    landscape_label,
    year,
    governance_profile,
    profile_label
  )])
  
  list(
    trajectories = x,
    chronology = chronology,
    input_path = SOURCE_BOUNDARY,
    chronology_path = SOURCE_BOUNDARY
  )
}

dat <- read_authoritative_figure2_data()
traj <- as.data.table(dat$trajectories)
chronology <- as.data.table(dat$chronology)

traj[, `:=`(
  SESU_ID = as.integer(SESU_ID),
  year = as.integer(year),
  n = as.numeric(n),
  y = as.numeric(y),
  landscape_label = as.character(landscape_label),
  outcome_label = as.character(outcome_label),
  side_label = as.character(side_label),
  profile_label = as.character(profile_label)
)]

chronology[, `:=`(
  SESU_ID = as.integer(SESU_ID),
  year = as.integer(year),
  landscape_label = as.character(landscape_label),
  profile_label = as.character(profile_label)
)]

traj <- traj[
  SESU_ID %in% c(1L, 3L) &
    year >= YEAR_MIN & year <= YEAR_MAX &
    outcome_label %in% OUTCOME_LEVELS &
    side_label %in% SIDE_LEVELS
]

chronology <- chronology[
  SESU_ID %in% c(1L, 3L) &
    year >= YEAR_MIN & year <= YEAR_MAX
]

if (nrow(traj) == 0L) stop("No Figure 2 rows remain after filtering.", call. = FALSE)

dup <- traj[, .N, by = .(landscape_label, outcome_label, year, side_label)][N != 1L]
if (nrow(dup) > 0L) {
  print(dup)
  stop("Duplicate or missing trajectory strata detected.", call. = FALSE)
}

profile_conflicts <- chronology[
  ,
  .(n_profiles = uniqueN(profile_label)),
  by = .(landscape_label, year)
][n_profiles != 1L]

if (nrow(profile_conflicts) > 0L) {
  print(profile_conflicts)
  stop("Conflicting territorial-control profiles detected.", call. = FALSE)
}

event_totals <- traj[, .(events = sum(y, na.rm = TRUE)), by = outcome]
expected_totals <- data.table(
  outcome = c("fire", "tree_cover_loss", "agriculture"),
  expected_events = c(508320, 519, 518)
)
event_check <- merge(expected_totals, event_totals, by = "outcome", all = TRUE)
event_check[, ok := expected_events == events]

if (!all(event_check$ok)) {
  print(event_check)
  stop(
    "Locked event-total validation failed. The input is not the final authoritative Figure 2 data.",
    call. = FALSE
  )
}

traj[, proportion := y / n]
alpha <- 0.05
traj[, `:=`(
  proportion_lo = qbeta(alpha / 2, y + 0.5, (n - y) + 0.5),
  proportion_hi = qbeta(1 - alpha / 2, y + 0.5, (n - y) + 0.5)
)]

MULTIPLIER <- if (DISPLAY_AS_PERCENT) 100 else 1
traj[, `:=`(
  display_value = MULTIPLIER * proportion,
  display_lo = MULTIPLIER * proportion_lo,
  display_hi = MULTIPLIER * proportion_hi
)]

traj[, landscape_label := factor(landscape_label, levels = LANDSCAPE_LEVELS)]
traj[, outcome_label := factor(outcome_label, levels = OUTCOME_LEVELS)]
traj[, side_label := factor(side_label, levels = SIDE_LEVELS)]
traj[, profile_label := factor(profile_label, levels = PROFILE_LEVELS)]

chronology[, landscape_label := factor(landscape_label, levels = LANDSCAPE_LEVELS)]
chronology[, profile_label := factor(profile_label, levels = PROFILE_LEVELS)]

setorder(traj, landscape_label, outcome_label, side_label, year)
setorder(chronology, landscape_label, year)

candidate_source <- traj[, .(
  SESU_ID,
  landscape_label,
  year,
  outcome,
  outcome_label,
  side,
  side_label,
  n,
  y,
  proportion,
  display_value,
  governance_profile,
  profile_label,
  authoritative_input = normalizePath(
    dat$input_path,
    winslash = "/",
    mustWork = FALSE
  )
)]

fwrite(candidate_source, file.path(OUT_FSD, paste0(FIGURE_STEM, "_source_data.csv")))
fwrite(event_check, file.path(OUT_REP, paste0(FIGURE_STEM, "_event_total_validation.csv")))

wide <- dcast(
  traj,
  landscape_label + outcome_label + year ~ side_label,
  value.var = "display_value"
)
wide <- wide[is.finite(Inside) & is.finite(Outside)]

fill_dense <- wide[
  ,
  {
    dense_year <- seq(min(year), max(year), by = 0.02)
    inside_dense <- approx(x = year, y = Inside, xout = dense_year, method = "linear", ties = mean)$y
    outside_dense <- approx(x = year, y = Outside, xout = dense_year, method = "linear", ties = mean)$y
    data.table(year = dense_year, Inside = inside_dense, Outside = outside_dense)
  },
  by = .(landscape_label, outcome_label)
]

fill_dense[, `:=`(
  ymin = pmin(Inside, Outside),
  ymax = pmax(Inside, Outside),
  difference_direction = fifelse(Inside > Outside, "Inside higher", "Outside higher")
)]
fill_dense[, run_id := rleid(difference_direction), by = .(landscape_label, outcome_label)]

transitions <- chronology[
  order(year),
  {
    change <- profile_label != shift(profile_label)
    .(transition_x = year[which(change)] - 0.5)
  },
  by = landscape_label
]
transitions <- transitions[is.finite(transition_x)]

smart_axis_labels <- function(x) {
  finite_x <- x[is.finite(x)]
  if (length(finite_x) == 0L) return(as.character(x))
  max_abs <- max(abs(finite_x), na.rm = TRUE)
  digits <- if (max_abs >= 10) 0 else if (max_abs >= 1) 1 else if (max_abs >= 0.1) 2 else 3
  formatC(x, format = "f", digits = digits)
}

theme_ch1 <- function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.25),
      panel.border = element_blank(),
      strip.background = element_blank(),
      strip.text.x = element_text(face = "bold", size = 13, margin = margin(b = 4)),
      strip.text.y.left = element_text(
        face = "bold", angle = 90, size = 10.5,
        lineheight = 0.95, margin = margin(r = 8)
      ),
      axis.title = element_text(size = 12, colour = "black"),
      axis.text = element_text(size = 9.0, colour = "grey20"),
      axis.ticks = element_blank(),
      legend.position = "bottom",
      legend.title = element_text(size = 10.5, colour = "black"),
      legend.text = element_text(size = 9.2, colour = "grey15"),
      legend.key.height = unit(0.8, "lines"),
      legend.key.width = unit(1.55, "lines"),
      legend.box = "vertical",
      panel.spacing.x = unit(1.25, "lines"),
      panel.spacing.y = unit(0.35, "lines"),
      plot.margin = margin(5.5, 8, 2, 16)
    )
}

p_traj <- ggplot()

if (SHOW_DIFFERENCE_FILL) {
  p_traj <- p_traj +
    geom_ribbon(
      data = fill_dense,
      aes(
        x = year,
        ymin = ymin,
        ymax = ymax,
        fill = difference_direction,
        group = interaction(landscape_label, outcome_label, run_id)
      ),
      alpha = 0.45,
      colour = NA
    )
}

if (SHOW_UNCERTAINTY) {
  p_traj <- p_traj +
    geom_ribbon(
      data = traj,
      aes(
        x = year,
        ymin = display_lo,
        ymax = display_hi,
        group = interaction(landscape_label, outcome_label, side_label)
      ),
      fill = "grey55",
      alpha = 0.08,
      colour = NA
    )
}

p_traj <- p_traj +
  geom_vline(
    data = transitions,
    aes(xintercept = transition_x),
    colour = "grey55",
    linewidth = 0.28,
    linetype = "22"
  ) +
  geom_line(
    data = traj,
    aes(
      x = year,
      y = display_value,
      linetype = side_label,
      group = interaction(landscape_label, outcome_label, side_label)
    ),
    colour = "black",
    linewidth = 0.60,
    lineend = "round"
  ) +
  facet_grid(
    rows = vars(outcome_label),
    cols = vars(landscape_label),
    scales = "free_y",
    switch = "y",
    labeller = labeller(
      outcome_label = as_labeller(OUTCOME_STRIP_LABELS)
    )
  ) +
  scale_linetype_manual(
    values = c("Outside" = "solid", "Inside" = "22"),
    breaks = c("Outside", "Inside"),
    name = "Park side"
  ) +
  scale_fill_manual(
    values = DIFFERENCE_COLOURS,
    breaks = c("Inside higher", "Outside higher"),
    name = "Annual contrast"
  ) +
  scale_x_continuous(
    limits = c(YEAR_MIN - 0.5, YEAR_MAX + 0.5),
    breaks = YEAR_BREAKS,
    labels = NULL,
    expand = c(0, 0)
  ) +
  scale_y_continuous(labels = smart_axis_labels) +
  labs(
    x = NULL,
    y = if (DISPLAY_AS_PERCENT) "Eligible cells disturbed (%)" else "Annual event proportion"
  ) +
  guides(
    linetype = guide_legend(order = 1, nrow = 1, title.position = "left"),
    fill = guide_legend(order = 2, nrow = 1, title.position = "left")
  ) +
  theme_ch1() +
  theme(
    strip.placement = "outside",
    axis.title.x = element_blank(),
    legend.margin = margin(0, 0, 0, 0),
    legend.box.margin = margin(0, 0, 0, 0)
  )

profile_strip <- chronology[, .(
  xmin = year - 0.5,
  xmax = year + 0.5,
  ymin = 0,
  ymax = 1,
  landscape_label,
  profile_label
)]

p_strip <- ggplot(
  profile_strip,
  aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = profile_label)
) +
  geom_rect(colour = NA) +
  geom_vline(
    data = transitions,
    aes(xintercept = transition_x),
    inherit.aes = FALSE,
    colour = "white",
    linewidth = 0.30
  ) +
  facet_grid(. ~ landscape_label) +
  scale_fill_manual(
    values = PROFILE_COLOURS,
    breaks = PROFILE_LEVELS,
    drop = FALSE,
    name = "Territorial-control profile"
  ) +
  scale_x_continuous(
    limits = c(YEAR_MIN - 0.5, YEAR_MAX + 0.5),
    breaks = YEAR_BREAKS,
    expand = c(0, 0)
  ) +
  scale_y_continuous(limits = c(0, 1), breaks = NULL, expand = c(0, 0)) +
  labs(x = "Year", y = "Territorial-control profile") +
  theme_ch1() +
  theme(
    panel.grid = element_blank(),
    strip.text = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_text(face = "bold", size = 12, angle = 90, margin = margin(r = 10)),
    axis.title.x = element_text(face = "bold", size = 12, margin = margin(t = 6)),
    legend.margin = margin(0, 0, 0, 0),
    legend.box.margin = margin(0, 0, 0, 0)
  ) +
  guides(fill = guide_legend(order = 3, nrow = 1, title.position = "left"))

figure_2_candidate <- p_traj / p_strip +
  plot_layout(heights = c(5.3, 0.78), guides = "collect") &
  theme(legend.position = "bottom", legend.box = "vertical")

png_path <- file.path(OUT_FIG, paste0(FIGURE_STEM, ".png"))
pdf_path <- file.path(OUT_FIG, paste0(FIGURE_STEM, ".pdf"))

ggsave(
  filename = png_path,
  plot = figure_2_candidate,
  width = 195 / 25.4,
  height = 202 / 25.4,
  dpi = 600,
  device = ragg::agg_png,
  scaling = 1,
  bg = "white"
)

pdf_device <- if (capabilities("cairo")) grDevices::cairo_pdf else grDevices::pdf

ggsave(
  filename = pdf_path,
  plot = figure_2_candidate,
  width = 195 / 25.4,
  height = 202 / 25.4,
  device = pdf_device,
  bg = "white"
)

validation_report <- c(
  paste0("Figure candidate: ", FIGURE_STEM),
  paste0("Repository root: ", ROOT),
  paste0("Trajectory input: ", normalizePath(dat$input_path, winslash = "/", mustWork = FALSE)),
  paste0("Chronology input: ", normalizePath(dat$chronology_path, winslash = "/", mustWork = FALSE)),
  "",
  "Locked event totals:",
  paste0("  Fire: ", event_check[outcome == "fire", events], " / 508320"),
  paste0("  Tree-cover loss: ", event_check[outcome == "tree_cover_loss", events], " / 519"),
  paste0("  Agricultural expansion: ", event_check[outcome == "agriculture", events], " / 518"),
  "",
  paste0("PNG: ", png_path),
  paste0("PDF: ", pdf_path),
  paste0("Source data: ", file.path(OUT_FSD, paste0(FIGURE_STEM, "_source_data.csv"))),
  "",
  "Status: candidate only; the current publication Figure 2 was not overwritten."
)

writeLines(validation_report, file.path(OUT_REP, paste0(FIGURE_STEM, "_validation.txt")))
message(paste(validation_report, collapse = "\n"))
