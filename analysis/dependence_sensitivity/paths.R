# Run R drivers from the repository root. No packages are installed implicitly.
if (nzchar(Sys.getenv("UPEMBA_R_LIBRARY"))) {
  .libPaths(c(normalizePath(Sys.getenv("UPEMBA_R_LIBRARY")), .libPaths()))
}
dependence_output <- function() {
  p <- Sys.getenv("UPEMBA_DEPENDENCE_OUTPUT_DIR", "outputs/_validation/dependence_sensitivity")
  dir.create(p, recursive=TRUE, showWarnings=FALSE)
  p <- normalizePath(p, winslash="/", mustWork=TRUE)
  frozen <- normalizePath(c("data/dependence_sensitivity", "outputs/dependence_sensitivity"), winslash="/", mustWork=TRUE)
  if (any(p == frozen | startsWith(p, paste0(frozen,"/")))) stop("Choose an output directory outside the committed inputs and results")
  p
}
