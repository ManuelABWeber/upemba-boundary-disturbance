# Fire 10 km Optimizer Refinement Validation

Generated on 2026-06-24.

## Repository State

- Branch: `publication-revision/fire-optimizer-refinement`.
- Starting commit: `5ed80d0 Harmonize 2021-2022 fire measurements`.
- Phase tag present: `post-fire-harmonization-2026-06-24`.
- Workflow script: `scripts/10_fire_10km_optimizer_refinement.R`.
- Output directory: `analysis_fire_optimizer_refinement_dev/`.

## Thresholds And Configurations

Thresholds fitted:

- `harmonized_tau010`
- `harmonized_tau025`
- `harmonized_tau050`

Configurations attempted:

- `A_baseline`
- `B_strict_nlminb`
- `C_strict_nlminb_polish`
- `D_BFGS_diagnostic`

## Validation Checks

- Baseline 10 km fits reproduced Phase 5 diagnostics and contrasts exactly within numerical tolerance.
- All configurations used the same 10 km analytical data and model formula.
- Start values were passed from baseline to strict `nlminb`, and from strict `nlminb` to BFGS using the supported `beta` and `betadisp` start components.
- Output tables refer only to harmonized 10 km fire thresholds.
- No raster preprocessing, tree-cover-loss fitting, agriculture fitting, bootstrap, placebo, SESU clustering, or governance recoding was run.
- `scripts/10_fire_10km_optimizer_refinement.R` parses successfully.

## Convergence Diagnostics

Baseline fits converged with positive-definite Hessians but exceeded the strict gradient threshold:

- Tau010 framework gradient 0.001523; independent numerical gradient 0.001751.
- Tau025 framework gradient 0.001429; independent numerical gradient 0.001462.
- Tau050 framework gradient 0.001318; independent numerical gradient 0.002853.

Strict `nlminb` reduced gradients, but returned convergence code 1 with `false convergence (8)` for all three thresholds. BFGS converged with code 0 and positive-definite Hessians for all three thresholds.

## Strict-Valid Fits

Strict-valid retained fits:

- Tau010: `D_BFGS_diagnostic`.
- Tau025: `D_BFGS_diagnostic`.

Numerically stable but not strict-valid:

- Tau050: `D_BFGS_diagnostic`; framework gradient 0.000829, independent numerical gradient 0.001957.

## Coefficient Stability

Maximum retained differences from baseline:

- Tau010: coefficient 0.0000173; profile contrast 0.000000673; pairwise difference 0.000000165.
- Tau025: coefficient 0.000000314; profile contrast 0.000000422; pairwise difference 0.000000185.
- Tau050: coefficient 0.000000069; profile contrast 0.000000126; pairwise difference 0.000000059.

Log-likelihood differences from baseline are below `3e-8` for all retained fits.

## Warnings And Errors

- `B_strict_nlminb` and `C_strict_nlminb_polish` returned `false convergence (8)` for all thresholds.
- BFGS emitted no model warnings in the final run.
- No workflow-stopping errors remain.

## Selected Fits

- Tau010: retain BFGS diagnostic fit as strict-valid.
- Tau025: retain BFGS diagnostic fit as strict-valid.
- Tau050: retain BFGS diagnostic fit as numerically stable but not strict-valid.

## Unresolved Issues

Tau050 remains slightly above the independent numerical-gradient criterion. Because likelihoods, coefficients, profile contrasts, and pairwise differences are stable across optimizers, no additional optimizer work is recommended before the placebo phase.
