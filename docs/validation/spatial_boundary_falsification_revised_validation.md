# Revised Spatial Boundary Falsification Validation

Branch: publication-revision/spatial-falsification-revised
Starting commit: 4dcdcd5 Add spatial pseudo-boundary falsification analysis

## Design Revision

The original symmetric inner/outer design stopped before outcome fitting. The revised fixed boundary sets were written before any outcome model fitting in this script.

## Fixed Boundary Sets

Actual boundary: 0 km.
Primary spaced outer set: 20, 40, 60 km.
Dense outer set: 15, 20, 25, 30, 35, 40, 45, 50, 55, 60 km.
Limited inner checks: -15, -20 km.

## Actual-Boundary Reproduction

                     component max_abs_difference reproduces
                        <char>              <num>     <lgcl>
1:      fire_profile_contrasts       2.775558e-17       TRUE
2:   fire_pairwise_differences       4.163336e-16       TRUE
3:   fire_retained_diagnostics       3.410605e-13       TRUE
4:    sparse_profile_estimates       4.440892e-16       TRUE
5: sparse_pairwise_differences       4.440892e-16       TRUE

## Models Attempted

Fire boundaries fitted: 13.
Strict-valid retained fire fits: 6.
Sparse SESU-year contrast rows: 2288.

## Warnings and Failed Fits

Fire retained failed or unstable fits: 0.

## Output Files

actual_boundary_reproduction_check.csv
actual_vs_all_outer_summary.csv
actual_vs_spaced_outer_pairwise_comparison.csv
actual_vs_spaced_outer_profile_comparison.csv
boundary_specificity_classification.csv
boundary_surface_summary.csv
fire_boundary_fit_diagnostics.csv
fire_boundary_pairwise_differences.csv
fire_boundary_profile_contrasts.csv
fire_boundary_retained_fits.csv
inner_check_pairwise_results.csv
inner_check_profile_results.csv
outer_gradient_pairwise_results.csv
outer_gradient_profile_results.csv
revised_boundary_balance_summary.csv
revised_boundary_covariate_balance.csv
revised_boundary_registry.csv
sparse_boundary_pairwise_differences.csv
sparse_boundary_profile_estimates.csv
sparse_boundary_sesu_year_contrasts.csv
sparse_boundary_support.csv

## Remaining Limitations

The two inner checks overlap substantially and are descriptive only. Overlapping outer corridors are not independent replicates.
