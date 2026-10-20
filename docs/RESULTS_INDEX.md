# Current analytical results

The primary inside–outside comparison uses 10 km bands on both sides of the legal boundary and the 25% event definition. Primary point estimates and conditional intervals remain unchanged. Supplementary dependence intervals describe additional uncertainty and do not replace those point estimates. Negative log-odds contrasts indicate lower occurrence on the park-facing side.

| Analysis | Canonical location |
|---|---|
| Primary estimates and original numerical checks | outputs/final_robustness/baseline_primary_results.csv; tests/reference/ |
| Fire primary optimizer diagnostics and contrasts | analysis_fire_optimizer_refinement_dev/tables/ |
| Legal and ten outer-boundary counts, model estimates and pairwise differences | analysis_spatial_falsification_revised_dev/tables/ |
| Threshold and comparison-domain sensitivities | analysis_spatial_threshold_sensitivity_dev/tables/ |
| Documentary chronology and source coding | data/governance_profiles/; evidence/ |
| Matched chronology lags and episode/landscape influence | outputs/final_robustness/temporal_lag_*.csv, episode_*.csv, landscape_specific_estimates.csv |
| Retained transition and model-stability diagnostics | analysis_governance_profiles_robustness_dev/tables/ |
| Corrected agricultural counts, models, covariance, spatial bootstrap and annual presence | outputs/final_reconciliation/ |
| Corrected agricultural post-event classification and static Hansen overlap | outputs/final_reconciliation/postevent/ |
| Monthly rainfall/fire illustration and observation-coverage audits | outputs/final_reconciliation/rainfall_fire/ |
| Additional dependence inputs, code, draws and summaries | data/dependence_sensitivity/; analysis/dependence_sensitivity/; outputs/dependence_sensitivity/ |

The new supplementary Methods S8, Tables S12–S20 and Figure S5 have a dedicated [file map](dependence_sensitivity/methods_and_results.md). Historical document layouts and their former table/figure numbers are excluded from the current tree. Use the source paths above to identify an analysis, rather than inferring authority from an older filename.

The implemented primary tree-loss response applies the baseline-forest mask when defining events and retains the original all-cell denominator. The forest-only denominator is explicitly labelled baseline_forest_only in the additional sensitivity files. The corrected agricultural persistence result uses candidate years 2001–2019 and contains 414 corridor events. The earlier persistence output is retired; the primary first-crossing count remains 518.

The unique measurement and model audits in reports/ and docs/validation/ record source-product selection, coverage, numerical acceptance and reconstruction checks. They supply scientific provenance, not alternative manuscript versions. The code-release records under docs/validation/releases/ describe the checks performed at their dates.
