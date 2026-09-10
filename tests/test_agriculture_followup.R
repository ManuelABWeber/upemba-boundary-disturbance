library(data.table)
source("scripts/lib/agriculture_followup.R")
years <- 2000:2022
v <- rep(0, 23)
v[years %in% c(2019,2020,2022)] <- .25
stopifnot(ag_first_crossing(v, persistent=TRUE) == 2019L)
v[years == 2021] <- NA_real_
stopifnot(is.na(ag_first_crossing(v, persistent=TRUE)))
stopifnot(ag_observation_end(v, persistent=TRUE) == 2017L)
v <- rep(0,23); v[years >= 2020] <- .25
stopifnot(ag_first_crossing(v) == 2020L,
          is.na(ag_first_crossing(v,persistent=TRUE)),
          ag_first_crossing(v,persistent=TRUE,historical=TRUE) == 2020L)
v <- rep(0,23); v[years == 2001 | years >= 2005] <- .25
stopifnot(ag_first_crossing(v) == 2001L,
          ag_first_crossing(v,persistent=TRUE) == 2005L)
v[1] <- .5
stopifnot(ag_first_crossing(v) == 2005L) # baseline cultivation retained
v <- rep(0,23); v[years == 2018] <- NA; v[years >= 2019] <- .5
stopifnot(is.na(ag_first_crossing(v))) # missing predecessor is not below
stopifnot(identical(ag_reversal(c(2019L,2020L,2021L,2019L),
                              c(0,0,0,NA),c(0,.25,0,0)),
  c("reversed","not_reversed","insufficient_followup","missing_followup")))
cat("Calendar follow-up, later crossing, baseline and missing-data checks passed.\n")
