# Governance Profile Phase 2 Validation

## Scope

- Branch: `publication-revision/profile-robustness`.
- Starting commit: `38c6bc0 Refactor authoritative governance-profile pipeline`.
- Phase 1 tag: `post-governance-profile-phase1-2026-06-23`.
- Archived file: `data/upemba_sesu_year_regimes_reflected.csv` moved to `outdated/data/upemba_sesu_year_regimes_reflected.csv`.
- Active governance input: `data/upemba_sesu_year_regimes.csv`.
- Output directory: `analysis_governance_profiles_robustness_dev`.

## Parse and Execution

`scripts/05_models_governance_profiles.R` and `scripts/06_governance_profile_robustness.R` parsed successfully. Script 06 executed successfully and generated Phase 2 tables. Script 05 was not rerun because Phase 2 outputs were required to avoid overwriting Phase 1 outputs.

Phase 1 point estimates reproduced exactly from Script 06 using the canonical dataset and default optimizer; all reproduction flags are `TRUE`.

## Support Diagnostics

Script 05 support diagnostics were corrected so `sesu_distribution` counts unique SESU-year combinations rather than inside and outside rows. Phase 2 writes corrected support tables with unique SESU-years by SESU, episode lengths, largest episode length, largest episode share, largest episode ID, and a descriptive one-episode dominance flag using `CH1_ONE_EPISODE_DOMINANCE_THRESHOLD = 0.50`.

## Optimizer Diagnostics

Controlled optimizer configurations attempted: `nlminb_default`, `nlminb_strict`, and `optim_bfgs`.

- Fire: `nlminb_default` and `nlminb_strict` strict-valid; positive-definite Hessian; maximum absolute gradient about 0.0008316.
- Deforestation: no strict-valid optimizer; finite-output `nlminb_default` and `nlminb_strict`; Hessian not positive definite; maximum absolute gradient about 0.1101.
- Agriculture: no strict-valid optimizer; finite-output `nlminb_default` and `nlminb_strict`; Hessian not positive definite; maximum absolute gradient about 0.0471.

Dispersion estimates are recorded in `optimizer_fit_diagnostics.csv`; deforestation and agriculture dispersion estimates are extremely large and accompany the failed Hessian diagnostics.

## Bootstrap Diagnostics

Strict-valid bootstrap fractions:

- Fire: 103/499 = 0.206.
- Deforestation: 5/499 = 0.010.
- Agriculture: 0 strict-valid interval available.

Finite-output bootstrap intervals were generated. Strict-valid bootstrap inference is flagged unstable because all strict-valid fractions are below 0.80.

## Sensitivity Status

Two-stage SESU-year models ran with weighted and unweighted specifications using HC3 covariance. The report documents that HC3 does not fully account for calendar-year clustering.

Transition scenarios were generated one transition at a time, with skipped or failed scenarios retained in diagnostics. The largest transition deviation was deforestation under Militia dominant in `T3_earlier`.

Leave-one-episode-out models were attempted for canonical episodes. The largest influence was agriculture under Park dominant after omitting `SESU1_Park dominant_2017_2022`.

SESU heterogeneity models ran and produced SESU-specific profile contrasts and between-SESU differences. The heterogeneity results are sensitivity outputs and are not replacements for the primary model.

## Warnings and Errors

Script 06 produced repeated `sqrt(diag(vcovs)) : NaNs produced` warnings during problematic beta-binomial fits. These are retained in diagnostics and are consistent with unresolved Hessian/standard-error problems for deforestation and agriculture.

## Remaining Scientific Decisions

- Boundary-local versus all-cell estimand remains unresolved.
- Spatial placebo redesign remains unresolved.
- Transition-year historical evidence audit remains required.
- Episode-level sensitivity should be interpreted with researcher review.
- Deforestation and agriculture beta-binomial Wald inference remains unresolved.
