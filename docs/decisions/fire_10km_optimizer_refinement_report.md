# Fire 10 km Optimizer Refinement Report

Generated on 2026-06-24 by `scripts/10_fire_10km_optimizer_refinement.R`.

## Scope

This phase refit only the harmonized 10 km fire beta-binomial models for `harmonized_tau010`, `harmonized_tau025`, and `harmonized_tau050`. The analytical data, 10 km sample definition, governance profiles, SESU assignments, side coding, study period, threshold definitions, beta-binomial family, logit link, and fixed-effect formula were unchanged:

```r
cbind(y, n - y) ~ 0 + sesu_year + side +
  inside_profile_militia + inside_profile_park
```

No all-cell models, tree-cover-loss models, agriculture models, bootstrap analyses, placebo analyses, or disturbance preprocessing were rerun.

## Baseline Reproduction

The baseline 10 km harmonized fits exactly reproduce the Phase 5 fire-harmonization diagnostics for all three thresholds. Convergence code, positive-definite Hessian status, model-matrix rank, dispersion, maximum framework gradient, profile contrasts, and pairwise differences match within numerical tolerance.

## Optimizer Configurations

The predeclared configurations were:

- `A_baseline`: the current `nlminb` controls used in `scripts/09_fire_2021_2022_harmonization.R`.
- `B_strict_nlminb`: `nlminb` with tighter tolerances, initialized from the baseline fit.
- `C_strict_nlminb_polish`: a second strict `nlminb` pass initialized from Configuration B.
- `D_BFGS_diagnostic`: BFGS initialized from Configuration B.

The strict validity rule was not changed: finite coefficients and standard errors, optimizer convergence code 0, no optimizer failure message, positive-definite Hessian, full model-matrix rank, maximum framework and independent numerical gradients below 0.001, finite profile contrasts and variances, and no extreme standard errors.

## Results

Strict `nlminb` reduced framework gradients below 0.001 for all thresholds, but returned `false convergence (8)` for every threshold. The second strict `nlminb` polishing pass did not resolve the false-convergence code. It improved the tau025 gradient further but left tau010 and tau050 effectively unchanged relative to the first strict pass.

BFGS converged with positive-definite Hessians and nearly identical likelihoods and estimates. It produced strict-valid fits for tau010 and tau025. Tau050 had a framework gradient below 0.001 but an independent numerical gradient of 0.00196, so it remains numerically stable but not strict-valid.

| threshold | baseline framework gradient | retained optimizer | retained framework gradient | retained numerical gradient | retained status |
|---|---:|---|---:|---:|---|
| tau010 | 0.001523 | BFGS diagnostic | 0.000844 | 0.000841 | strict-valid |
| tau025 | 0.001429 | BFGS diagnostic | 0.000954 | 0.000947 | strict-valid |
| tau050 | 0.001318 | BFGS diagnostic | 0.000829 | 0.001957 | numerically stable but not strict-valid |

The largest retained framework-gradient component is the dispersion intercept for all three thresholds. The largest retained independent numerical-gradient component is the dispersion intercept for tau010 and tau025, and `sesu_year3.2021` for tau050. No governance-profile interaction is the largest residual-gradient component.

## Stability

Optimizer refinement changed log-likelihoods and estimates negligibly:

- Tau010 retained delta log-likelihood: 0.000000029; maximum coefficient difference: 0.0000173; maximum profile-contrast difference: 0.000000673.
- Tau025 retained delta log-likelihood: 0.000000001; maximum coefficient difference: 0.000000314; maximum profile-contrast difference: 0.000000422.
- Tau050 retained delta log-likelihood: 0.000000001; maximum coefficient difference: 0.000000069; maximum profile-contrast difference: 0.000000126.

Profile-specific and pairwise fire estimates are stable across optimizer configurations. Optimizer refinement does not change the substantive fire interpretation.

## Inferential Role

The harmonized 10 km tau025 fire model is strict-valid under the BFGS diagnostic configuration and can remain the leading primary spatial estimand for fire, with the all-cell fire model retained as the landscape-scale strict-valid sensitivity. Tau010 also becomes strict-valid under BFGS. Tau050 remains a sensitivity result that is numerically stable but not strict-valid under the independent-gradient rule.

No further optimizer work is scientifically justified at this stage. The remaining tau050 issue is marginal and does not produce coefficient or contrast instability. Additional optimizer searches would risk turning a diagnostic exercise into model selection.

The subsequent stopped spatial pseudo-boundary screen did not alter this optimizer conclusion. The researcher-approved revised pseudo-boundary analysis then reproduced the actual 10 km tau025 fire fit exactly and retained the BFGS-refined label for the actual-boundary model.

The revised falsification results affect interpretation rather than numerical validity: fire profile-specific contrasts are stable measured 10 km associations but are not distinct from the spaced outer or dense outer pseudo-boundary patterns. The 10 km actual-boundary fire model remains the correct optimized fit, but manuscript fire claims should not overstate boundary-location specificity.
