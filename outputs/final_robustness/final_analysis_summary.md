# Final robustness analysis summary

## 1. Analyses completed

The authoritative primary workflow was reproduced; a centralized specification and shared risk-set/model library were added; lag 0-2, transition exclusions, thresholds, spatial domains, weights, transition-year alternatives, leave-one-episode-out, landscape-specific, and pseudo-boundary analyses were run. Every run records support, warnings, and validity.

## 2. Deviations from the requested plan and why

- No episode bootstrap was used. Eleven contiguous episodes are too few for routine asymptotic cluster-robust inference, and no prevalidated small-cluster bootstrap implementation was available in the repository. Leave-one-episode-out influence and episode-specific descriptive contrasts are reported instead.
- Tree regrowth was not analysed because no annual regrowth-sensitive canopy/vegetation series exists.
- Agricultural persistence and persistent-event refits were not estimated because the annual AFCD fraction stack is absent. All observable first-crossing cells are retained as missing/uncertain.
- Multi-factor combinations were not expanded indiscriminately. The registry contains one-dimension-at-a-time directly matched runs; unsupported fits remain explicit.

## 3. Reproducibility status

The primary estimates from the shared pipeline equal the recorded authoritative baseline exactly. Primary support is 42,554 eligible cells; 936,188 fire cell-years and 508,320 burned cell-years; 930,969 tree-loss risk-set cell-years and 519 events; and 931,657 agricultural risk-set cell-years and 518 events. The public repository still requires restricted manifest-listed inputs.

## 4. Temporal-lag findings

Lag-0 fire contrasts: Neither actor dominant 0.170 [0.112, 0.229]; Militia dominant 0.011 [-0.054, 0.075]; Park dominant 0.068 [0.008, 0.128].
Lag-0 tree-loss contrasts: Neither actor dominant -0.846 [-1.293, -0.399]; Militia dominant -0.898 [-1.509, -0.287]; Park dominant -1.430 [-1.941, -0.919].
Lag-0 agricultural contrasts: Neither actor dominant 0.286 [-0.164, 0.737]; Militia dominant 0.222 [-0.048, 0.492]; Park dominant -0.347 [-0.657, -0.037].
Tree-loss point estimates remain negative across lags 1 and 2 for every profile. Fire magnitude and interval exclusion change with lag. Agricultural estimates remain support-sensitive. These are matched temporal associations, not identified causal delays.

## 5. Matched robustness findings

Tree-loss direction is stable across the 5, 10, and 20 km corridors and full domain, and at 10% and 25%; the 50% measurement threshold is weak and its intervals include zero. Fire is directionally positive for the fragmented profile across the directly matched core, while other profile intervals and strict-validity vary. Agriculture changes direction across thresholds, domains, and weights and is not a stable headline result.

## 6. Episode and landscape influence

All leave-one-episode-out tree-loss profile estimates remain negative. Fragmented-profile fire remains positive, whereas militia-centred and park-centred fire estimates can change sign after episode omission. Park-centred agriculture remains negative in leave-one-episode-out estimates, but other agricultural profiles change sign. Episode-specific rows are descriptive and are flagged when event support is near zero. Landscape-only fits are reported only when estimable.

## 7. Tree-cover post-loss/regrowth feasibility

Not testable with available data. Hansen loss remains a first cumulative mapped-loss threshold-crossing measure; it is not reversed to infer regrowth.

## 8. Agricultural persistence findings

The full eligible domain contains 2685 recorded 25% first-crossing cells, including 518 in the primary 10 km corridor. None can be classified for persistence from the retained event-year raster alone.

## 9. Pseudo-boundary design recommendation

The +5 km design crosses the legal boundary and should be excluded. Retain +15 to +60 km by 5 km as the complete descriptive series; emphasize +15, +25, +35, +45, and +55 km as a parsimonious subset; report +10 km only as boundary-adjacent; optionally retain +20/+40/+60 for historical continuity. Across all audited designs, legal tree-loss profile estimates are below all offsets, legal fire estimates fall within offset ranges, and agriculture remains inconclusive. Overlap means offsets are not independent replicates.

## 10. Manuscript claims

- Supported with qualification: negative park-side tree-loss first-crossing contrasts at the legal boundary, including lag and episode sensitivities.
- Supported with qualification: profile-specific fire contrasts as conditional burned-cell-year patterns, without a unique legal-boundary claim.
- Move to supplement: profile-specific agricultural contrasts because support and specification sensitivity are substantial.
- Unsupported: causal claims about conservation effectiveness, legal designation, or actor-specific effects.
- Not testable: tree regrowth and agricultural persistence/reversal with currently retained data.

## 11. Recommended manuscript and supplement changes

State the 10 km, 25% primary estimands exactly; report fire as burned cell-years; add the lag figure/table, matched robustness matrix, episode influence table, and pseudo-boundary geometry/design table to the supplement; qualify the 50% tree-loss sensitivity; move agricultural profile interpretation out of the headline conclusions; describe the post-event diagnostics as infeasible due to missing annual metrics; and retain explicit non-causal language throughout.
