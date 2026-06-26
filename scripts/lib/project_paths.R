project_root <- function() {
  env <- Sys.getenv("UPEMBA_PROJECT_ROOT", unset = "")
  if (nzchar(env)) return(normalizePath(env, winslash = "/", mustWork = FALSE))
  cur <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(cur, ".here"))) return(cur)
    parent <- dirname(cur)
    if (identical(parent, cur)) break
    cur <- parent
  }
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

data_root <- function(project = project_root()) {
  env <- Sys.getenv("UPEMBA_DATA_ROOT", unset = "")
  if (nzchar(env)) normalizePath(env, winslash = "/", mustWork = FALSE) else file.path(project, "data")
}

output_root <- function(project = project_root()) {
  env <- Sys.getenv("UPEMBA_OUTPUT_ROOT", unset = "")
  if (nzchar(env)) normalizePath(env, winslash = "/", mustWork = FALSE) else file.path(project, "outputs")
}