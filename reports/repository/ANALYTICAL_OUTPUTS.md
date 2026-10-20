# Retained analytical snapshots

The four top-level analysis_*_dev/ directories contain frozen numerical inputs used by current verification and figure code. Their names are stable paths, not provisional scientific status. The cleanup preserves their model tables and unique diagnostics.

analysis_fire_optimizer_refinement_dev/ retains primary 10 km fire contrasts, pairwise comparisons, fit checks and optimizer provenance. analysis_governance_profiles_robustness_dev/ retains transition, episode, landscape and numerical-stability tables; repeated console logs were retired. analysis_spatial_falsification_revised_dev/ supplies legal/outer-boundary counts and estimates. analysis_spatial_threshold_sensitivity_dev/ supplies threshold and domain sensitivities and sparse-outcome support.

The identical spatial-analysis software records are consolidated in docs/provenance/sessionInfo_spatial.txt. Corrected agricultural and Hansen outputs have a single canonical location in outputs/final_reconciliation/. Additional dependence outputs are in outputs/dependence_sensitivity/. The [results index](../../docs/RESULTS_INDEX.md) identifies the current analysis sources; the cleanup manifest records retired duplicates and document artifacts.
