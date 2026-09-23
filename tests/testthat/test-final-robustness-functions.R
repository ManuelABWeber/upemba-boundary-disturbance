suppressPackageStartupMessages(library(data.table))
source("config/final_robustness_config.R")
source("scripts/lib/final_robustness_functions.R")

# Synthetic cell histories verify estimand-level risk-set rules independently
# of restricted geospatial inputs.
yrs <- 2001:2005
fire <- CJ(cell = 1:2, year = yrs)
stopifnot(all(fire[, .N, by = cell]$N == length(yrs)))

event_risk <- function(event_year) data.table(
  year = yrs[yrs <= event_year], event = as.integer(yrs[yrs <= event_year] == event_year))
tree <- event_risk(2003)
agri <- event_risk(2004)
stopifnot(max(tree$year) == 2003, sum(tree$event) == 1)
stopifnot(max(agri$year) == 2004, sum(agri$event) == 1)
stopifnot(!any(tree$event[tree$year < 2003] == 1))

signed <- data.table(d = c(-1, 0, 1))
signed[, side := fifelse(d < 0, "inside", "outside")]
stopifnot(identical(signed$side, c("inside", "outside", "outside")))

tl <- data.table(SESU_ID = 1L, year = yrs,
                 governance_profile = FINAL_SPEC$profile_levels[1])
s <- data.table(SESU_ID = 1L, year = yrs, side = "inside",
                outcome = "fire", n = 1L, y = 0L,
                governance_profile = "wrong")
assigned <- fr_assign_profiles(s, tl)
stopifnot(all(assigned$governance_profile == FINAL_SPEC$profile_levels[1]))

ha <- fr_haldane_anscombe(rbind(
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "inside", y = 0L, n = 10L),
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "outside", y = 2L, n = 10L)))
stopifnot(ha$yi == .5, ha$ni == 11, ha$yo == 2.5, ha$no == 11)

# Identical legal and pseudo comparison bands must yield identical corrected
# sparse contrasts when passed to the same shared function.
stopifnot(identical(fr_haldane_anscombe(rbindlist(list(
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "inside", y = 1L, n = 10L),
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "outside", y = 2L, n = 10L))))$inside_outside_log_odds_contrast,
  fr_haldane_anscombe(rbindlist(list(
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "inside", y = 1L, n = 10L),
  data.table(outcome = "x", SESU_ID = 1L, year = 2001L,
             governance_profile = FINAL_SPEC$profile_levels[1],
             side = "outside", y = 2L, n = 10L))))$inside_outside_log_odds_contrast))

# When restricted prepared inputs have been restored, the final primary suite
# must reproduce the locked manuscript support totals.
registry_path <- file.path(FINAL_SPEC$output_dir,
                           "robustness_run_registry.csv")
if (file.exists(registry_path)) {
  observed <- fread(registry_path)[robustness_run_id == "primary",
    .(outcome, eligible_cells, cell_years, events)]
  expected <- data.table(
    outcome = c("fire", "tree_cover_loss", "agriculture"),
    eligible_cells = c(42554L, 42554L, 42554L),
    cell_years = c(936188L, 930969L, 931657L),
    events = c(508320L, 519L, 518L)
  )
  checked <- merge(observed, expected, by = "outcome",
                   suffixes = c("_observed", "_expected"))
  stopifnot(nrow(checked) == 3L)
  stopifnot(all(checked$eligible_cells_observed ==
                  checked$eligible_cells_expected))
  stopifnot(all(checked$cell_years_observed == checked$cell_years_expected))
  stopifnot(all(checked$events_observed == checked$events_expected))
}
