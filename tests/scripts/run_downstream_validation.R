#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_file <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("tests/scripts/run_downstream_validation.R", winslash = "/", mustWork = TRUE)
}
ROOT <- normalizePath(file.path(dirname(script_file), "..", ".."), winslash = "/", mustWork = TRUE)
OUT <- file.path(ROOT, "reports", "repository")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

run_stage <- function(order, script) {
  log_path <- tempfile(sprintf("downstream_stage_%02d_", order), fileext = ".log")
  start <- Sys.time()
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", file.path(ROOT, script)),
    stdout = log_path,
    stderr = log_path
  )
  end <- Sys.time()
  result <- data.frame(
    stage_order = order,
    script = script,
    exit_status = status,
    elapsed_seconds = as.numeric(difftime(end, start, units = "secs")),
    log = "temporary validation log removed after stage completion",
    pass = identical(status, 0L),
    stringsAsFactors = FALSE
  )
  unlink(log_path)
  result
}

stages <- c(
  "scripts/publication/06_generate_main_figures_tables.R",
  "scripts/publication/08_generate_figure2_chronology_time_series.R",
  "scripts/publication/07_generate_supplementary_material.R",
  "tests/scripts/compare_frozen_results.R"
)
stage_results <- data.frame()
for (i in seq_along(stages)) {
  result <- run_stage(i, stages[i])
  stage_results <- rbind(stage_results, result)
  if (!result$pass) break
}
write.csv(
  stage_results,
  file.path(OUT, "downstream_stage_validation.csv"),
  row.names = FALSE
)

required <- c(
  "outputs/publication/manuscript/Chapter1_manuscript_final.docx",
  "outputs/publication/supplement/Chapter1_Supplementary_Material_final.docx",
  "outputs/publication/main_figures/Figure_1_study_design.png",
  "outputs/publication/main_figures/Figure_1_study_design.pdf",
  "outputs/publication/main_figures/Figure_2_chronology_time_series.png",
  "outputs/publication/main_figures/Figure_2_chronology_time_series.pdf",
  "outputs/publication/main_figures/Figure_3_primary_contrasts.png",
  "outputs/publication/main_figures/Figure_3_primary_contrasts.pdf",
  "outputs/publication/main_figures/Figure_4_boundary_location_diagnostic.png",
  "outputs/publication/main_figures/Figure_4_boundary_location_diagnostic.pdf",
  "outputs/publication/figure_source_data/Figure_2_annual_trajectories.csv",
  "outputs/publication/figure_source_data/Figure_2_profile_chronology.csv",
  "reports/publication_outputs/Figure_2_event_total_validation.csv",
  "outputs/publication/supplement/figures/Figure_S1_clustering_diagnostics.png",
  "outputs/publication/supplement/figures/Figure_S2_threshold_spatial_sensitivities.png",
  "outputs/publication/supplement/figures/Figure_S3_pairwise_pseudo_boundary_diagnostic.png"
)
required_validation <- data.frame(
  path = required,
  exists = file.exists(file.path(ROOT, required)),
  nonempty = file.exists(file.path(ROOT, required)) &
    file.info(file.path(ROOT, required))$size > 0,
  stringsAsFactors = FALSE
)
required_validation$pass <- required_validation$exists & required_validation$nonempty
write.csv(
  required_validation,
  file.path(OUT, "downstream_required_file_validation.csv"),
  row.names = FALSE
)

all_files <- list.files(ROOT, recursive = TRUE, all.files = TRUE, no.. = TRUE)
active_obsolete <- grepl(
  "old_style_candidate|candidate_pubqual|(^|/)fig [12]\\.png$|outputs/publication/(Manuscript|Supplementary_Material)\\.docx$",
  gsub("\\\\", "/", all_files)
)
obsolete_validation <- data.frame(
  path = gsub("\\\\", "/", all_files[active_obsolete]),
  pass = rep(FALSE, sum(active_obsolete)),
  stringsAsFactors = FALSE
)
write.csv(
  obsolete_validation,
  file.path(OUT, "downstream_obsolete_file_validation.csv"),
  row.names = FALSE
)

script_files <- list.files(
  file.path(ROOT, "scripts"),
  pattern = "\\.(R|py|js)$",
  recursive = TRUE,
  full.names = TRUE
)
static_rows <- lapply(script_files, function(path) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  data.frame(
    path = substring(path, nchar(ROOT) + 2),
    contains_absolute_workstation_path = grepl(
      "[A-Za-z]:[/\\\\](Users|0_Documents)",
      text
    ),
    references_obsolete_figure2 = grepl(
      "old_style_candidate|candidate_pubqual|fig 2\\.png",
      text
    ),
    stringsAsFactors = FALSE
  )
})
static_validation <- do.call(rbind, static_rows)
static_validation$pass <- !static_validation$contains_absolute_workstation_path &
  !static_validation$references_obsolete_figure2
write.csv(
  static_validation,
  file.path(OUT, "downstream_static_validation.csv"),
  row.names = FALSE
)

failed <- any(!stage_results$pass) ||
  any(!required_validation$pass) ||
  nrow(obsolete_validation) > 0 ||
  any(!static_validation$pass)
if (failed) quit(status = 1)
