# Replace stale 10 km fire sensitivity rows with the retained optimizer fits.
# The frozen analytical snapshots are not rewritten.
publication_refined_fire <- function(x, pairwise = FALSE, root = CH1_PROJECT_ROOT) {
  x <- data.table::copy(x)
  p <- file.path(root, "analysis_fire_optimizer_refinement_dev/tables",
    if (pairwise) "fire_10km_optimizer_pairwise_differences.csv" else "fire_10km_optimizer_profile_contrasts.csv")
  z <- data.table::fread(p)[optimizer_config == "D_BFGS_diagnostic"]
  key <- if (pairwise) "profile_comparison" else "governance_profile"
  for (j in seq_len(nrow(z))) {
    hit <- which(x$outcome == "fire" & x$spatial_design == "buffer_10km" &
      x$threshold_tag == z$threshold_tag[j] & x[[key]] == z[[key]][j])
    for (nm in intersect(c("estimate", "lower_95_ci", "upper_95_ci", "standard_error"), intersect(names(z), names(x))))
      data.table::set(x, i = hit, j = nm, value = z[[nm]][j])
  }
  x
}
