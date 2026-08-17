#!/usr/bin/env Rscript

# Download the four public Hansen GFC v1.12 tiles used by the 2000-2012
# loss-gain overlap diagnostic. Files are cached under data/external/, which is
# git-ignored; authoritative repository data are never overwritten.

source("config/analysis_config.R")
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package 'digest' is required for SHA-256 validation.", call. = FALSE)
}

dest <- file.path(CH1_PROJECT_ROOT, "data", "external",
                  "hansen_gfc_2024_v1_12")
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

base <- paste0(
  "https://storage.googleapis.com/earthenginepartners-hansen/",
  "GFC-2024-v1.12/"
)
files <- c(
  "Hansen_GFC-2024-v1.12_gain_00N_020E.tif",
  "Hansen_GFC-2024-v1.12_gain_10S_020E.tif",
  "Hansen_GFC-2024-v1.12_lossyear_00N_020E.tif",
  "Hansen_GFC-2024-v1.12_lossyear_10S_020E.tif"
)
expected_sha256 <- c(
  "ADB03704E2E25494FC1C54E3B3302533D4D5BD802545182A8F51765FDDD88BD0",
  "BCC756D854092B6C6B4A45F09F0E65FB1AC894A5C701ACF4FC726E17D2B31D2E",
  "8C08A089F18BE2117DE0BD227A5CE7BE218A9193E5FE8F6E5DF6B152B11E00E0",
  "B19033C6089A943D089F68D060EF06D46ED2B38829DE6AD971B23428955C22C9"
)

for (i in seq_along(files)) {
  target <- file.path(dest, files[i])
  if (!file.exists(target)) {
    message("Downloading ", files[i])
    download.file(paste0(base, files[i]), target, mode = "wb", quiet = FALSE)
  }
  observed <- digest::digest(target, algo = "sha256", file = TRUE)
  if (!identical(toupper(observed), expected_sha256[i])) {
    stop("SHA-256 mismatch for ", files[i], call. = FALSE)
  }
  message("Verified ", files[i])
}

message("Hansen diagnostic tiles are present and checksum-verified in ", dest)
