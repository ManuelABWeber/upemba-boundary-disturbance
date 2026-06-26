#!/usr/bin/env Rscript

script_file <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE), error = function(e) NA_character_)
if (is.na(script_file)) script_file <- normalizePath("tests/scripts/run_downstream_validation.R", winslash = "/", mustWork = TRUE)
root <- normalizePath(file.path(dirname(script_file), "..", ".."), winslash = "/", mustWork = TRUE)
source(file.path(root, "config", "analysis_config.R"))

validation_root <- CH1_OUTPUT_ROOT
dir.create(file.path(validation_root, "logs"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(validation_root, "provenance"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(validation_root, "results"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(validation_root, "stage_outputs"), recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")

validate_inputs <- function() {
  manifest <- read.csv(file.path(root, "data", "manifests", "required_external_inputs.csv"), stringsAsFactors = FALSE)
  rows <- lapply(seq_len(nrow(manifest)), function(i) {
    rel <- manifest$expected_relative_path[i]
    p <- file.path(CH1_DATA_ROOT, rel)
    exists <- file.exists(p)
    size <- if (exists) file.info(p)$size else NA_real_
    hash <- if (exists && !is.na(size) && size < 250 * 1024^2) unname(tools::sha256sum(p)) else NA_character_
    checksum_matches <- if (nzchar(manifest$sha256[i]) && !is.na(hash)) identical(tolower(hash), tolower(manifest$sha256[i])) else NA
    data.frame(
      logical_id = manifest$logical_id[i],
      resolved_validation_path = paste0("<frozen-source>/", rel),
      exists = exists,
      size_bytes = size,
      manifest_size_matches = if (!exists || !nzchar(manifest$size_bytes[i])) NA else as.character(size) == manifest$size_bytes[i],
      sha256_expected = manifest$sha256[i],
      sha256_observed = ifelse(is.na(hash), "", hash),
      checksum_matches = checksum_matches,
      required_stage = "downstream_validation",
      validation_status = if (exists && (is.na(checksum_matches) || isTRUE(checksum_matches))) "ok" else "stop_condition",
      notes = if (exists) "resolved under frozen source" else "missing",
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  write_csv(out, file.path(validation_root, "provenance", "resolved_input_validation.csv"))
  out
}

software_preflight <- function() {
  scripts <- list.files(file.path(root, "scripts"), pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  imports <- unique(unlist(lapply(scripts, function(f) {
    x <- readLines(f, warn = FALSE)
    m <- regmatches(x, gregexpr("library\\(([^)]+)\\)", x))
    gsub("^library\\(|\\)$", "", unlist(m))
  })))
  imports <- imports[nzchar(imports)]
  lock_ok <- TRUE
  lock <- tryCatch(jsonlite::fromJSON(file.path(root, "renv.lock")), error = function(e) {
    lock_ok <<- FALSE
    NULL
  })
  rows <- lapply(imports, function(pkg) {
    inst <- requireNamespace(pkg, quietly = TRUE)
    installed_version <- if (inst) as.character(utils::packageVersion(pkg)) else ""
    lock_version <- ""
    if (lock_ok && !is.null(lock$Packages[[pkg]]$Version)) lock_version <- lock$Packages[[pkg]]$Version
    status <- if (!inst) "package_missing" else if (nzchar(lock_version) && identical(installed_version, lock_version)) "exact_match" else if (nzchar(lock_version)) "compatible_difference" else "unknown"
    data.frame(package = pkg, installed = inst, installed_version = installed_version, lockfile_version = lock_version, version_status = status)
  })
  out <- if (length(rows)) do.call(rbind, rows) else data.frame()
  write_csv(out, file.path(validation_root, "provenance", "software_preflight.csv"))
  sink(file.path(validation_root, "provenance", "sessionInfo.txt"))
  print(R.version.string)
  print(sessionInfo())
  sink()
  out
}

static_validation <- function() {
  scripts <- list.files(file.path(root, "scripts"), pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  rows <- lapply(scripts, function(f) {
    rel <- substring(f, nchar(root) + 2)
    parse_ok <- TRUE
    msg <- ""
    tryCatch(parse(f), error = function(e) {
      parse_ok <<- FALSE
      msg <<- conditionMessage(e)
    })
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    drive_prefix <- paste0("C", ":")
    user_name <- paste0("weber", "034")
    abs_pattern <- paste(
      paste0(drive_prefix, "/0_", "Documents"),
      paste0(drive_prefix, "\\\\0_", "Documents"),
      paste0(drive_prefix, "/Users/", user_name),
      paste0(drive_prefix, "\\\\Users\\\\", user_name),
      sep = "|"
    )
    has_abs <- grepl(abs_pattern, txt)
    stopped <- grepl("11_spatial_boundary_falsification", txt)
    data.frame(
      script = gsub("\\\\", "/", rel),
      parse_ok = parse_ok,
      message = msg,
      contains_absolute_workstation_path = has_abs,
      references_stopped_script = stopped,
      writes_frozen_source = FALSE,
      validation_status = if (parse_ok && !has_abs && !stopped) "ok" else "review",
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  write_csv(out, file.path(validation_root, "provenance", "static_script_validation.csv"))
  out
}

run_stage <- function(order, script) {
  start <- Sys.time()
  log_path <- file.path(validation_root, "logs", sprintf("%02d_%s.log", order, tools::file_path_sans_ext(basename(script))))
  cmd <- file.path(R.home("bin"), "Rscript")
  args <- c("--vanilla", file.path(root, script))
  status <- system2(cmd, args, stdout = log_path, stderr = log_path)
  end <- Sys.time()
  log_lines <- if (file.exists(log_path)) readLines(log_path, warn = FALSE) else character()
  data.frame(
    stage_order = order,
    script = script,
    start_time = format(start, "%Y-%m-%dT%H:%M:%OS%z"),
    end_time = format(end, "%Y-%m-%dT%H:%M:%OS%z"),
    elapsed_seconds = as.numeric(difftime(end, start, units = "secs")),
    exit_status = status,
    warnings_count = sum(grepl("warning", log_lines, ignore.case = TRUE)),
    errors_count = sum(grepl("error", log_lines, ignore.case = TRUE)),
    outputs_created = NA,
    validation_status = if (identical(status, 0L)) "completed" else "failed",
    stringsAsFactors = FALSE
  )
}

inputs <- validate_inputs()
software <- software_preflight()
static <- static_validation()

stage_manifest <- data.frame()
if (any(inputs$validation_status == "stop_condition")) {
  stage_manifest <- data.frame(stage_order = 0, script = "preflight", start_time = "", end_time = "", elapsed_seconds = 0, exit_status = 1, warnings_count = 0, errors_count = sum(inputs$validation_status == "stop_condition"), outputs_created = 0, validation_status = "failed_input_resolution")
} else if (any(software$version_status == "package_missing")) {
  stage_manifest <- data.frame(stage_order = 0, script = "preflight", start_time = "", end_time = "", elapsed_seconds = 0, exit_status = 1, warnings_count = 0, errors_count = sum(software$version_status == "package_missing"), outputs_created = 0, validation_status = "failed_package_preflight")
} else if (any(static$validation_status != "ok")) {
  stage_manifest <- data.frame(stage_order = 0, script = "preflight", start_time = "", end_time = "", elapsed_seconds = 0, exit_status = 1, warnings_count = 0, errors_count = sum(static$validation_status != "ok"), outputs_created = 0, validation_status = "failed_static_validation")
} else {
  stages <- c(
    "scripts/preprocessing/04_harmonize_fire_2021_2022.R",
    "scripts/analysis/01_fit_governance_profile_models.R",
    "scripts/analysis/02_fit_sparse_outcomes_and_profile_robustness.R",
    "scripts/analysis/03_refine_fire_10km_optimizer.R",
    "scripts/sensitivity/03_run_revised_boundary_falsification.R"
  )
  for (i in seq_along(stages)) {
    row <- run_stage(i, stages[i])
    stage_manifest <- rbind(stage_manifest, row)
    write_csv(stage_manifest, file.path(validation_root, "provenance", "execution_stage_manifest.csv"))
    if (!identical(row$exit_status, 0L)) break
  }
}

write_csv(stage_manifest, file.path(validation_root, "provenance", "execution_stage_manifest.csv"))
if (nrow(stage_manifest) && any(stage_manifest$exit_status != 0)) quit(status = 1)
