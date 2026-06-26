# Governance Profile Model Stability Report

Phase 2 was needed because the Phase 1 beta-binomial fits produced corrected profile-specific contrasts, but deforestation and agriculture had convergence code 1, non-positive-definite Hessians, and extreme standard errors. Phase 2 therefore evaluated optimizer stability, strict fit diagnostics, bootstrap quality, transition timing, episode influence, SESU heterogeneity, and a transparent SESU-year two-stage analysis.

## Primary Fit Stability

The canonical Phase 1 point estimates reproduced exactly from the Phase 2 analytical dataset. Differences from Phase 1 were at floating-point precision only.

Fire remains the strongest beta-binomial fit: `nlminb_default` and `nlminb_strict` were both strict-valid, with positive-definite Hessians and maximum absolute gradient approximately 0.0008316. `optim_bfgs` was not retained as a strict-valid candidate.

Deforestation was not resolved by the controlled optimizer set. The finite-output `nlminb_default` and `nlminb_strict` fits retained non-positive-definite Hessians, convergence code 1, and maximum absolute gradient approximately 0.1101.

Agriculture was not resolved by the controlled optimizer set. The finite-output `nlminb_default` and `nlminb_strict` fits retained non-positive-definite Hessians, convergence code 1, and maximum absolute gradient approximately 0.0471.

## Bootstrap Diagnostics

The Phase 2 bootstrap records replicate-level support, rank, convergence, Hessian, gradient, finite-output status, and strict-valid status. Strict-valid fractions were below the 80% diagnostic threshold for every outcome:

- Fire: 103/499 strict-valid replicates, strict-valid fraction 0.206.
- Deforestation: 5/499 strict-valid replicates, strict-valid fraction 0.010.
- Agriculture: no strict-valid interval was available.

Finite-output bootstrap intervals remain useful for descriptive stability, but strict-valid bootstrap inference is unstable under the Phase 2 criteria.

## Two-Stage Transparency Analysis

The SESU-year contrast dataset uses a documented Haldane-Anscombe 0.5 correction for approximate log-odds calculations. Weighted and unweighted two-stage models broadly preserve the main directions for deforestation and Park-dominant agriculture. Fire estimates remain small and sensitive around zero for some profiles. HC3 covariance was used and documented as not fully accounting for calendar-year clustering.

## Historical Sensitivity

The largest transition-timing deviation was for deforestation under Militia dominant in scenario `T3_earlier`, changing the estimate from -2.073 to -1.053. Transition timing therefore matters most for the militia-deforestation contrast, but the direction remained negative in the scenario range.

The largest leave-one-episode-out influence was agriculture under Park dominant when omitting `SESU1_Park dominant_2017_2022`, producing an extreme estimate of -16.275. Agriculture under Militia dominant and Neither actor dominant changed qualitative sign in some leave-one-episode-out scenarios.

## SESU Heterogeneity

The heterogeneity model indicates materially different SESU-specific estimates. Fire contrasts are higher in SESU3 than SESU1. Deforestation differences are large, especially for Militia dominant, but the militia between-SESU estimate has very large uncertainty. Agriculture SESU differences are numerically large but unstable, consistent with the unresolved agriculture beta-binomial diagnostics.

## Manuscript Readiness

Fire: direction and magnitude are comparatively stable in the canonical beta-binomial fit, but strict bootstrap support is below the diagnostic threshold. Fire can be described as the most numerically stable outcome, with bootstrap-quality caveats.

Deforestation: the direction is largely negative across diagnostics, but the beta-binomial fit remains unresolved. Do not rely on non-strict-valid Wald inference as final manuscript evidence.

Agriculture: the beta-binomial fit remains unresolved, and episode influence is substantial. Treat agriculture profile contrasts as sensitivity results until further robustness work is complete.

Recommended primary specification remains Script 05's categorical governance-profile beta-binomial model. Recommended sensitivity specification is Script 06's controlled optimizer diagnostics, finite-output and strict bootstrap comparison, SESU-year two-stage model, transition timing checks, leave-one-episode-out checks, and SESU heterogeneity model. No model should be selected based on p-values or preferred substantive direction.

The next phase should construct symmetric 5, 10, and 20 km boundary-local samples and compare them with the current all-cell analysis.
