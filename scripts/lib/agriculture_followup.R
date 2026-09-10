# Calendar-year rules shared by the corrected analysis and synthetic tests.
ag_first_crossing <- function(x, years = 2000:2022, tau = .25,
                              persistent = FALSE, historical = FALSE) {
  stopifnot(length(x) == length(years), all(diff(years) == 1))
  k <- which(is.finite(x[-1]) & is.finite(x[-length(x)]) &
               x[-1] >= tau & x[-length(x)] < tau) + 1L
  if (persistent) k <- k[vapply(k, function(j) {
    last <- if (historical) min(j + 3L, length(x)) else j + 3L
    if (j + 2L > length(x) || last > length(x)) return(FALSE)
    post <- x[seq.int(j + 1L, last)]
    all(is.finite(post)) && sum(post >= tau) >= 2L &&
      any(x[j + c(1L, 2L)] >= tau)
  }, logical(1))]
  if (length(k)) as.integer(years[k[1]]) else NA_integer_
}

ag_reversal <- function(event, p1, p2, last_year = 2022L, tau = .25) {
  data.table::fcase(event + 2L > last_year, "insufficient_followup",
    !is.finite(p1) | !is.finite(p2), "missing_followup",
    p1 < tau & p2 < tau, "reversed", default = "not_reversed")
}

# An unobserved candidate/history cannot be classified as event-free. Censor
# prospectively at the first year whose status cannot be ascertained. The
# supplied stack has no missing fractions; this guard prevents silent absence.
ag_observation_end <- function(x, years = 2000:2022, persistent = FALSE) {
  candidates <- years[years >= 2001 & years <= if (persistent) 2019 else 2022]
  if (!is.finite(x[1])) return(2000L)
  for (y in candidates) {
    j <- match(y, years)
    ix <- if (persistent) (j - 1L):(j + 3L) else (j - 1L):j
    if (any(!is.finite(x[ix]))) return(y - 1L)
  }
  max(candidates)
}
