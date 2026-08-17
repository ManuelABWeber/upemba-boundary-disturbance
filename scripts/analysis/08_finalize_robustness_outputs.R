suppressPackageStartupMessages(library(data.table))
source("config/final_robustness_config.R")
out <- FINAL_SPEC$output_dir

primary <- fread(file.path(out, "robustness_profile_estimates.csv"))[
  robustness_run_id == "primary"]
lags <- fread(file.path(out, "temporal_lag_profile_estimates.csv"))[
  specification %in% paste0("lag", 0:2)]
registry <- fread(file.path(out, "robustness_run_registry.csv"))
episode <- fread(file.path(out, "episode_influence.csv"))
pseudo <- fread(file.path(out, "pseudoboundary_design_classification.csv"))
agri <- fread(file.path(out, "agriculture_postevent_classification.csv"))
agri_sens <- fread(file.path(out, "agriculture_persistence_sensitivity.csv"))
agri_model <- fread(file.path(out, "agriculture_persistent_event_model.csv"))
agri_diag <- fread(file.path(out, "agriculture_persistent_event_diagnostics.csv"))
hansen_native <- fread(file.path(out,
                                 "hansen_native_loss_gain_overlap_summary.csv"))
hansen_overall <- fread(file.path(out,
                                  "hansen_loss_gain_overlap_overall.csv"))

fmt <- function(x) formatC(x, digits = 3, format = "f")
pct <- function(x) paste0(formatC(100 * x, digits = 1, format = "f"), "%")
pval <- function(o, p) primary[outcome == o & governance_profile == p]
tree_vals <- primary[outcome == "tree_cover_loss",
  paste0(governance_profile, " ", fmt(estimate), " [", fmt(conf_low),
         ", ", fmt(conf_high), "]")]
fire_vals <- primary[outcome == "fire",
  paste0(governance_profile, " ", fmt(estimate), " [", fmt(conf_low),
         ", ", fmt(conf_high), "]")]
agri_vals <- primary[outcome == "agriculture",
  paste0(governance_profile, " ", fmt(estimate), " [", fmt(conf_low),
         ", ", fmt(conf_high), "]")]
agri_persist_full <- agri_sens[
  rule_id == "two_of_three_including_plus1_or_plus2_tau025" &
    corridor_domain == "full", proportion][1]
agri_persist_10 <- agri_sens[
  rule_id == "two_of_three_including_plus1_or_plus2_tau025" &
    corridor_domain == "10km", proportion][1]
agri_tau_persist <- agri_sens[
  grepl("^threshold_consistent_persistence", rule_id) &
    corridor_domain == "full",
  paste0(sub("threshold_consistent_persistence_", "", rule_id), " ",
         pct(proportion))]
persistent_park <- agri_model[
  contrast_type == "profile" & profile_or_comparison == "Park dominant"][1]
hansen_native_overlap <- hansen_native$proportion_loss_pixels_also_gain[1]
hansen_10_overlap <- hansen_overall[
  corridor_domain == "10km", proportion_with_any_overlap][1]

claims <- data.table(
  claim_id = c("C01", "C02", "C03", "C04", "C05", "C06"),
  proposed_claim = c(
    "At the legal boundary, tree-cover-loss first-crossing odds were lower on the park side across all three territorial-control profiles.",
    "Fire boundary contrasts were positive for fragmented and park-centred profile years at lag 0, while the militia-centred interval included zero.",
    "The negative park-centred agricultural first-crossing contrast is support- and specification-sensitive.",
    "The territorial-control categories identify actor-specific causal effects.",
    "Post-loss forest recovery can be quantified from the retained Hansen products.",
    "Most classifiable 25% agricultural first-crossing cells remain above the mapped threshold under the predeclared persistence rule."
  ),
  outcome = c("tree_cover_loss", "fire", "agriculture",
              "all", "tree_cover_loss", "agriculture"),
  primary_support = c("all three estimates negative; all three conditional intervals exclude zero",
                      "fragmented and park-centred intervals exclude zero; militia-centred includes zero",
                      "park-centred negative interval excludes zero; other profiles include zero",
                      "none; design is observational and conditional",
                      paste0("native 2001-2012 loss pixels also flagged as 2000-2012 gain: ",
                             pct(hansen_native_overlap),
                             "; temporal order unknown"),
                      paste0(pct(agri_persist_full),
                             " persistent among classifiable full-domain first crossings; ",
                             pct(agri_persist_10), " in the 10 km corridor")),
  lag_support = c("negative at lags 1 and 2 for all profiles",
                  "positive point estimates at lags 1 and 2, but some intervals include zero",
                  "park-centred is negative; lag-1 interval includes zero and lag-2 excludes zero",
                  "not applicable", "not testable", "not applicable"),
  threshold_support = c("negative at 10%; 50% estimates are weak and intervals include zero",
                        "fragmented positive; militia-centred and park-centred vary in interval exclusion",
                        "directions change across 10%, 25%, and 50%",
                        "not applicable", "not testable",
                        paste(agri_tau_persist, collapse = "; ")),
  spatial_domain_support = c("negative direction across 5, 10, 20 km and full domain; 5 km support is weaker",
                             "positive point estimates across domains; some fits/intervals are non-strict",
                             "profile-specific patterns vary by domain",
                             "not applicable", "not testable",
                             paste0("10 km persistence ", pct(agri_persist_10),
                                    "; full-domain persistence ",
                                    pct(agri_persist_full))),
  chronology_support = c("negative under lags and transition-year alternatives overall",
                         "chronology changes magnitude and interval exclusion",
                         "chronology sensitivity does not resolve sparse support",
                         "not applicable", "not testable", "not applicable"),
  episode_support = c("negative direction in all leave-one-episode-out fits",
                      "fragmented remains positive; militia- and park-centred signs can change",
                      "park-centred remains negative; other profiles change sign",
                      "not applicable", "not testable", "not applicable"),
  pseudoboundary_support = c("legal estimates are below all offsets in every audited design",
                             "legal estimates lie within the offset range in every audited design",
                             "inconclusive; design-dependent ranges and sparse support",
                             "none", "not testable", "not applicable"),
  caveat = c(
    "Conditional spatial association; 50% measurement sensitivity is imprecise and the products are first-crossing measures.",
    "The quantity is burned cell-years rather than discrete fire-event counts; offset results do not show a unique legal-boundary pattern.",
    paste0("The persistent-establishment park-centred estimate is ",
           fmt(persistent_park$estimate), " [", fmt(persistent_park$conf_low),
           ", ", fmt(persistent_park$conf_high),
           "]; unlike the primary first-crossing interval, it includes zero."),
    "No causal identification of legal designation or individual actors.",
    paste0("The static gain flag is limited to 2000-2012 and has no year. ",
           "Loss-gain overlap (", pct(hansen_10_overlap),
           " of 10 km loss-crossing cells) does not identify regrowth order."),
    "Persistence is a mapped-cropland classification diagnostic, not proof of continuous cultivation, abandonment, or ecological recovery."
  ),
  recommended_status = c("retain_with_qualification",
                         "retain_with_qualification",
                         "move_to_supplement", "remove",
                         "not_testable", "retain_with_qualification")
)
fwrite(claims, file.path(out, "claims_audit.csv"))

summary_lines <- c(
  "# Final robustness analysis summary",
  "",
  "## 1. Analyses completed",
  "",
  "The authoritative primary workflow was reproduced; a centralized specification and shared risk-set/model library were added; lag 0-2, transition exclusions, thresholds, spatial domains, weights, transition-year alternatives, leave-one-episode-out, landscape-specific, and pseudo-boundary analyses were run. Every run records support, warnings, and validity.",
  "",
  "## 2. Deviations from the requested plan and why",
  "",
  "- No episode bootstrap was used. Eleven contiguous episodes are too few for routine asymptotic cluster-robust inference, and no prevalidated small-cluster bootstrap implementation was available in the repository. Leave-one-episode-out influence and episode-specific descriptive contrasts are reported instead.",
  paste0("- Confirmed tree regrowth remains unidentifiable because Hansen gain is a static 2000-2012 flag without timing. A native-grid loss-gain overlap diagnostic was completed instead; ", pct(hansen_native_overlap), " of 2001-2012 loss pixels also carry the gain flag."),
  paste0("- Annual AFCD fractions were recovered and validated against the canonical event raster. Agricultural persistence and persistent-first-establishment models were completed; the reconstruction had ", agri_diag$annual_fraction_validation_mismatches[1], " first-crossing mismatches."),
  "- Multi-factor combinations were not expanded indiscriminately. The registry contains one-dimension-at-a-time directly matched runs; unsupported fits remain explicit.",
  "",
  "## 3. Reproducibility status",
  "",
  "The primary estimates from the shared pipeline equal the recorded authoritative baseline exactly. Primary support is 42,554 eligible cells; 936,188 fire cell-years and 508,320 burned cell-years; 930,969 tree-loss risk-set cell-years and 519 events; and 931,657 agricultural risk-set cell-years and 518 events. The public repository still requires restricted manifest-listed inputs.",
  "",
  "## 4. Temporal-lag findings",
  "",
  paste0("Lag-0 fire contrasts: ", paste(fire_vals, collapse = "; "), "."),
  paste0("Lag-0 tree-loss contrasts: ", paste(tree_vals, collapse = "; "), "."),
  paste0("Lag-0 agricultural contrasts: ", paste(agri_vals, collapse = "; "), "."),
  "Tree-loss point estimates remain negative across lags 1 and 2 for every profile. Fire magnitude and interval exclusion change with lag. Agricultural estimates remain support-sensitive. These are matched temporal associations, not identified causal delays.",
  "",
  "## 5. Matched robustness findings",
  "",
  "Tree-loss direction is stable across the 5, 10, and 20 km corridors and full domain, and at 10% and 25%; the 50% measurement threshold is weak and its intervals include zero. Fire is directionally positive for the fragmented profile across the directly matched core, while other profile intervals and strict-validity vary. Agriculture changes direction across thresholds, domains, and weights and is not a stable headline result.",
  "",
  "## 6. Episode and landscape influence",
  "",
  "All leave-one-episode-out tree-loss profile estimates remain negative. Fragmented-profile fire remains positive, whereas militia-centred and park-centred fire estimates can change sign after episode omission. Park-centred agriculture remains negative in leave-one-episode-out estimates, but other agricultural profiles change sign. Episode-specific rows are descriptive and are flagged when event support is near zero. Landscape-only fits are reported only when estimable.",
  "",
  "## 7. Tree-cover post-loss/regrowth feasibility",
  "",
  paste0("Confirmed post-loss regrowth is still not testable from Hansen GFC because the 2000-2012 gain flag has no year. On the native grid, ", hansen_native$overlap_pixels[1], " of ", hansen_native$loss_pixels[1], " loss pixels from 2001-2012 (", pct(hansen_native_overlap), ") also carry the gain flag. Among 500 m cells crossing 25% cumulative loss by 2012 in the primary 10 km corridor, ", pct(hansen_10_overlap), " contain at least one native loss-gain overlap pixel. These are overlap diagnostics only: gain may precede loss, follow loss, or reflect classification discordance."),
  "",
  "## 8. Agricultural persistence findings",
  "",
  paste0("The annual AFCD reconstruction exactly reproduced the canonical 25% first-crossing raster. Of ", nrow(agri), " full-domain first crossings, ", sum(agri$postevent_class == "persistent"), " were persistent, ", sum(agri$postevent_class == "transient/reversed"), " transient/reversed, ", sum(agri$postevent_class == "intermittent"), " intermittent, and ", sum(agri$postevent_class == "right-censored"), " right-censored. Persistence among classifiable cells was ", pct(agri_persist_full), " in the full domain and ", pct(agri_persist_10), " in the primary corridor."),
  paste0("Persistent first establishment retained ", agri_diag$persistent_first_establishment_cells_10km[1], " of ", agri_diag$canonical_first_crossing_cells_10km[1], " primary-corridor events. The park-centred conditional contrast changed from the primary first-crossing estimate to ", fmt(persistent_park$estimate), " [", fmt(persistent_park$conf_low), ", ", fmt(persistent_park$conf_high), "]; its interval includes zero. This supports treating the agricultural boundary result as specification-sensitive."),
  "",
  "## 9. Pseudo-boundary design recommendation",
  "",
  "The +5 km design crosses the legal boundary and should be excluded. Retain +15 to +60 km by 5 km as the complete descriptive series; emphasize +15, +25, +35, +45, and +55 km as a parsimonious subset; report +10 km only as boundary-adjacent; optionally retain +20/+40/+60 for historical continuity. Across all audited designs, legal tree-loss profile estimates are below all offsets, legal fire estimates fall within offset ranges, and agriculture remains inconclusive. Overlap means offsets are not independent replicates.",
  "",
  "## 10. Manuscript claims",
  "",
  "- Supported with qualification: negative park-side tree-loss first-crossing contrasts at the legal boundary, including lag and episode sensitivities.",
  "- Supported with qualification: profile-specific fire contrasts as conditional burned-cell-year patterns, without a unique legal-boundary claim.",
  "- Move to supplement: profile-specific agricultural contrasts because support and specification sensitivity are substantial.",
  "- Unsupported: causal claims about conservation effectiveness, legal designation, or actor-specific effects.",
  "- Not testable: confirmed temporal ordering of Hansen loss and gain, or ecological forest recovery, from the static gain band.",
  "- Supported with qualification: most classifiable agricultural first crossings persist under the predeclared mapped-threshold rule; this is not proof of continuous cultivation or ecological condition.",
  "",
  "## 11. Recommended manuscript and supplement changes",
  "",
  "State the 10 km, 25% primary estimands exactly; report fire as burned cell-years; add the lag figure/table, matched robustness matrix, episode influence table, and pseudo-boundary geometry/design table to the supplement; qualify the 50% tree-loss sensitivity; report Hansen loss-gain overlap only as a temporally unordered measurement diagnostic; report AFCD persistence descriptively and the persistent-establishment refit as a sensitivity; move agricultural profile interpretation out of the headline conclusions; and retain explicit non-causal language throughout."
)
writeLines(summary_lines, file.path(out, "final_analysis_summary.md"))

required <- c(
  "baseline_primary_results.csv", "session_info.txt",
  "temporal_lag_profile_estimates.csv",
  "robustness_run_registry.csv", "episode_influence.csv",
  "tree_regrowth_feasibility.md",
  "hansen_native_loss_gain_overlap_summary.csv",
  "hansen_loss_gain_overlap_overall.csv",
  "agriculture_postevent_classification.csv",
  "agriculture_persistent_event_model.csv",
  "pseudoboundary_geometry.csv", "claims_audit.csv")
validation <- data.table(
  file = required,
  exists = file.exists(file.path(out, required)),
  bytes = file.info(file.path(out, required))$size
)
fwrite(validation, file.path(out, "final_output_validation.csv"))
stopifnot(all(validation$exists), all(validation$bytes > 0))
message("Integrated summary and claims audit complete.")
