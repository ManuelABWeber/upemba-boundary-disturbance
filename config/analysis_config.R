# Sanitized Chapter 1 analysis configuration.

.config_sources <- vapply(sys.frames(), function(frame) {
  if (is.null(frame$ofile)) "" else as.character(frame$ofile)[1L]
}, character(1))
.config_sources <- .config_sources[grepl("(^|[/\\\\])analysis_config\\.R$", .config_sources)]
.config_file <- if (length(.config_sources)) {
  normalizePath(tail(.config_sources, 1L), winslash = "/", mustWork = TRUE)
} else NA_character_
if (is.na(.config_file)) {
  .config_file <- normalizePath("config/analysis_config.R", winslash = "/", mustWork = TRUE)
}
.config_dir <- dirname(.config_file)
if (!nzchar(Sys.getenv("UPEMBA_PROJECT_ROOT", unset = ""))) {
  Sys.setenv(UPEMBA_PROJECT_ROOT = normalizePath(file.path(.config_dir, ".."), winslash = "/", mustWork = TRUE))
}

source(file.path(.config_dir, "..", "scripts", "lib", "project_paths.R"))

CH1_PROJECT_ROOT <- project_root()
CH1_DATA_ROOT <- data_root(CH1_PROJECT_ROOT)
CH1_OUTPUT_ROOT <- output_root(CH1_PROJECT_ROOT)

if (file.exists(file.path(CH1_PROJECT_ROOT, "config", "paths.local.R"))) {
  source(file.path(CH1_PROJECT_ROOT, "config", "paths.local.R"))
  CH1_PROJECT_ROOT <- project_root()
  CH1_DATA_ROOT <- data_root(CH1_PROJECT_ROOT)
  CH1_OUTPUT_ROOT <- output_root(CH1_PROJECT_ROOT)
}

CH1_ROOT <- CH1_DATA_ROOT
CH1_RUN_ID <- Sys.getenv("CH1_RUN_ID", unset = "run_2026_05_27")
CH1_RUN_DIR <- file.path(CH1_DATA_ROOT, CH1_RUN_ID)

CH1_OUTPUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_governance_profiles_dev")
CH1_TABLES_DIR <- file.path(CH1_OUTPUT_DIR, "tables")
CH1_FIGURES_DIR <- file.path(CH1_OUTPUT_DIR, "figures")
CH1_MODELS_DIR <- file.path(CH1_OUTPUT_DIR, "models")
CH1_PROVENANCE_DIR <- file.path(CH1_OUTPUT_DIR, "provenance")

CH1_ROBUSTNESS_OUTPUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_governance_profiles_robustness_dev")
CH1_ROBUSTNESS_TABLES_DIR <- file.path(CH1_ROBUSTNESS_OUTPUT_DIR, "tables")
CH1_ROBUSTNESS_FIGURES_DIR <- file.path(CH1_ROBUSTNESS_OUTPUT_DIR, "figures")
CH1_ROBUSTNESS_MODELS_DIR <- file.path(CH1_ROBUSTNESS_OUTPUT_DIR, "models")
CH1_ROBUSTNESS_PROVENANCE_DIR <- file.path(CH1_ROBUSTNESS_OUTPUT_DIR, "provenance")
CH1_ROBUSTNESS_LOGS_DIR <- file.path(CH1_ROBUSTNESS_OUTPUT_DIR, "logs")

CH1_SPATIAL_THRESHOLD_OUTPUT_DIR <- file.path(CH1_OUTPUT_ROOT, "analysis_spatial_threshold_sensitivity_dev")
CH1_SPATIAL_THRESHOLD_TABLES_DIR <- file.path(CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, "tables")
CH1_SPATIAL_THRESHOLD_FIGURES_DIR <- file.path(CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, "figures")
CH1_SPATIAL_THRESHOLD_MODELS_DIR <- file.path(CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, "models")
CH1_SPATIAL_THRESHOLD_PROVENANCE_DIR <- file.path(CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, "provenance")
CH1_SPATIAL_THRESHOLD_LOGS_DIR <- file.path(CH1_SPATIAL_THRESHOLD_OUTPUT_DIR, "logs")

CH1_THRESHOLD_VALUES <- c(tau010 = 0.10, tau025 = 0.25, tau050 = 0.50)
CH1_SPATIAL_DESIGNS <- c("all_cells", "buffer_05km", "buffer_10km", "buffer_20km")
CH1_BUFFER_KM <- c(buffer_05km = 5, buffer_10km = 10, buffer_20km = 20)
CH1_PHASE3_REFERENCE_THRESHOLD <- "tau025"
CH1_PHASE3_REFERENCE_SPATIAL_DESIGN <- "all_cells"
CH1_STUDY_YEARS <- 2001L:2022L
CH1_INCLUDED_SESUS <- c(1L, 3L)
CH1_DISTURBANCE_NAMES <- c(fire = "fire", deforestation = "year_deforest_masked", agriculture = "year_agri")
CH1_KEEP_PA_LABELS <- c("National Park")
CH1_BOOTSTRAP_ENABLED <- FALSE
CH1_BOOTSTRAP_REPLICATES <- 499L
CH1_BOOTSTRAP_SEED <- 1L
CH1_BOOTSTRAP_MIN_UNIQUE_YEARS <- 6L
CH1_BOOTSTRAP_MAX_RESAMPLE_TRIES <- 400L
CH1_ALPHA <- 0.05
CH1_ONE_EPISODE_DOMINANCE_THRESHOLD <- 0.50
CH1_MAX_ABS_GRADIENT_TOL <- 1e-3
CH1_EXTREME_SE_THRESHOLD <- 10
CH1_MATERIAL_CONTRAST_DELTA <- 0.10
CH1_GOVERNANCE_PROFILE_PATH <- file.path(CH1_PROJECT_ROOT, "data", "governance_profiles", "upemba_sesu_year_profiles.csv")
CH1_PROFILE_CODE_MAP <- c(A = "Neither actor dominant", B = "Militia dominant", C = "Park dominant")
CH1_PROFILE_DEFINITIONS <- c(
  "Neither actor dominant" = "Neither park authority nor militia actors are dominant; access control is fragmented, weak, or negotiated.",
  "Militia dominant" = "Militia dominance is associated with park collapse or sharply reduced lawful enforcement.",
  "Park dominant" = "Park authority is the dominant practical governance actor through expanded operational reach, while insecurity may persist."
)
CH1_REFERENCE_PROFILE <- "Neither actor dominant"
