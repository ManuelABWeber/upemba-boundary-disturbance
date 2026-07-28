# Central specification for the submission-ready final robustness suite.
# Scientific definitions are inherited from config/analysis_config.R.

source("config/analysis_config.R")

FINAL_SPEC <- list(
  pipeline_version = "final_robustness_v1",
  years = 2001L:2022L,
  grid_resolution_m = 500,
  primary_corridor_km = 10,
  corridor_km = c(5, 10, 20, Inf),
  thresholds = c(tau010 = 0.10, tau025 = 0.25, tau050 = 0.50),
  primary_threshold_tag = "tau025",
  tree_cover_eligibility_2000 = 0.30,
  fire_doy = c(100L, 300L),
  profile_levels = c("Neither actor dominant", "Militia dominant", "Park dominant"),
  profile_public_labels = c(
    "Neither actor dominant" = "fragmented",
    "Militia dominant" = "militia-centred",
    "Park dominant" = "park-centred"
  ),
  legal_boundary_signed_distance_km = 0,
  pseudo_centres_km = c(5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60),
  pseudo_designs = list(
    dense = seq(15, 60, 5),
    non_adjacent = c(15, 25, 35, 45, 55),
    round_number = c(10, 20, 30, 40, 50),
    historical = c(20, 40, 60)
  ),
  fire_formula = cbind(y, n - y) ~ 0 + sesu_year + side +
    inside_profile_militia + inside_profile_park,
  sparse_formula = inside_outside_log_odds_contrast ~ governance_profile + SESU_ID,
  correction = "Haldane-Anscombe: add 0.5 to all four cells",
  weighting = c("inverse_variance", "unweighted"),
  covariance = "HC3",
  alpha = 0.05,
  strict_gradient_tolerance = 1e-3,
  extreme_standard_error = 10,
  seeds = list(main = 20260728L, episode_bootstrap = 20260729L),
  output_dir = file.path(CH1_PROJECT_ROOT, "outputs", "final_robustness")
)

