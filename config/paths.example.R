# Copy to config/paths.local.R and edit for your machine. Do not commit paths.local.R.
Sys.setenv(UPEMBA_PROJECT_ROOT = normalizePath(".", winslash = "/", mustWork = FALSE))
Sys.setenv(UPEMBA_DATA_ROOT = "/path/to/local/nonredistributable/chapter1-inputs")
Sys.setenv(UPEMBA_OUTPUT_ROOT = file.path(Sys.getenv("UPEMBA_PROJECT_ROOT"), "outputs"))