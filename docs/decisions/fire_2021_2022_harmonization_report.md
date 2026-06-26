# Fire 2021-2022 Harmonization Report

Generated on 2026-06-24 by `scripts/09_fire_2021_2022_harmonization.R`.

## Verified Source Structure

The local source directory `data/fire/` contains monthly FireCCI-style rasters for April through October in both 2021 and 2022. For each year there are seven burn-date DOY rasters (`JD`), seven confidence or quality rasters (`CL`), and seven land-cover rasters (`LC`). The harmonized workflow uses the JD rasters only for event construction.

The JD rasters are WGS84 rasters at approximately 0.002245733 degree native resolution. Sampled values include negative non-burn or missing codes, zero, and positive burn DOYs. The local files therefore support a native-resolution seasonal burned-status calculation for DOY 100-300.

## Harmonized Algorithm

For 2021 and 2022 separately, the script:

1. reads the monthly JD rasters from `data/fire/`;
2. retains positive burn dates only when DOY is between 100 and 300;
3. computes the earliest positive seasonal DOY across April-October months at native resolution;
4. converts native seasonal burn presence to 1 and all non-seasonal or non-burned native pixels to 0;
5. aggregates native burn presence to the canonical 500 m EPSG:32735 template with `terra::project(..., method = "average")`;
6. aggregates the descriptive DOY to the 500 m template with the minimum seasonal DOY;
7. thresholds the 500 m burned fraction at tau010, tau025, and tau050;
8. writes binary threshold rasters and threshold-masked minimum-DOY rasters separately under `data/fire_harmonized_500m/`.

The canonical 500 m template is the first layer of `run_2026_05_27/SESU_covariates_500m.tif`; no threshold-dependent raster is used as a template.

## Validation

All harmonized products passed validation:

- grid identity with the canonical template;
- binary values restricted to 0, 1, or NA;
- DOY values restricted to 0 or DOY 100-300;
- every binary 1 has DOY greater than 0;
- every binary 0 has DOY 0;
- event counts decrease monotonically from tau010 to tau025 to tau050;
- year and threshold labels resolve to distinct files.

Event counts across the full canonical template:

| year | tau010 | tau025 | tau050 |
|---:|---:|---:|---:|
| 2021 | 157,317 | 145,677 | 129,035 |
| 2022 | 153,233 | 141,606 | 125,247 |

## Previous Workflow Audit

The previous local 2021-2022 workflow used monthly JD rasters but combined annual native DOY with the maximum positive DOY. It then constructed a native burned binary from nonmissing annual DOY, aggregated that binary to 500 m using an average burned fraction, and produced a descriptive 500 m DOY with nearest-neighbour projection. This created a binary product and a DOY-derived classification that were not guaranteed to agree.

The canonical embedded 2021-2022 tau025 layers match the previous `fireDOY_max`-derived classification exactly:

| year | canonical events | previous DOY-max events | disagreements |
|---:|---:|---:|---:|
| 2021 | 95,856 | 95,856 | 0 |
| 2022 | 92,664 | 92,664 | 0 |

This confirms that the embedded canonical 2021-2022 fire layers used the max-DOY/nearest-neighbour classification rather than the fraction-burned binary rule that matches the stated 2001-2020 measurement specification.

## Canonical Versus Harmonized Tau025

The new harmonized tau025 product does not reproduce the canonical embedded 2021-2022 layers, and exact reproduction is not expected because the canonical layers reflect the older max-DOY-derived rule.

| year | canonical events | harmonized events | canonical-only | harmonized-only | disagreement percent | Cohen kappa |
|---:|---:|---:|---:|---:|---:|---:|
| 2021 | 95,856 | 110,145 | 2 | 14,291 | 6.99 | 0.861 |
| 2022 | 92,664 | 106,503 | 0 | 13,839 | 6.77 | 0.865 |

Disagreements are mostly harmonized-only events and are spatially diffuse rather than isolated to one side or SESU. SESU 1 outside contains the largest absolute number because it has the largest cell count. Percentage disagreements are similar inside and outside, with SESU 3 outside slightly higher. By distance class, disagreement percentages are broadly similar from 0-5 km through >20 km.

## Model Consequences

The fire beta-binomial model was refit for the canonical embedded tau025 comparator and the harmonized tau010, tau025, and tau050 series for `all_cells` and `buffer_10km`.

Strict-valid fits:

- `canonical_embedded_tau025`, all cells;
- `canonical_embedded_tau025`, 10 km buffer;
- `harmonized_tau010`, all cells;
- `harmonized_tau025`, all cells;
- `harmonized_tau050`, all cells.

The 10 km harmonized fits converged with positive-definite Hessians but exceeded the strict maximum-gradient threshold, so their Wald intervals are not reported as strict-valid.

For all cells, profile-specific fire conclusions are stable in sign across canonical and harmonized tau025. The largest canonical-versus-harmonized tau025 shift is Park dominant, -0.0067 log-odds units, about -0.12 canonical standard errors. Neither actor dominant and Militia dominant change by less than 0.001 canonical standard errors. Pairwise profile comparisons preserve the same qualitative ordering; changes are small relative to their uncertainty.

Within the harmonized threshold series, all-cell profile signs remain positive for all three governance profiles at tau010, tau025, and tau050. Park dominant is lowest at tau010 and highest at tau050, while Neither actor dominant remains the largest positive profile contrast across thresholds.

## Scientific Decision

The local 2021-2022 source data support the same seasonal burned-fraction definition used as the 2001-2020 fire specification. The harmonized 2021-2022 products use burn-date information, DOY 100-300, a native seasonal binary with non-seasonal native pixels contributing zero, mean burned fraction at 500 m, and earliest positive seasonal DOY for descriptive timing.

The new harmonized 2001-2022 fire series should replace the canonical embedded fire series as the primary fire measurement candidate because it is more internally coherent, reproducible from local source files, and aligned with the stated burned-fraction algorithm. The canonical embedded tau025 fire series should be retained as a pipeline-version sensitivity, not as the primary fire implementation solely because it reproduces the previous analysis.

This decision is based on measurement coherence and reproducibility, not statistical significance. Fire remains a remote-sensing disturbance outcome and should not be interpreted directly as poaching.

The follow-up optimizer-refinement phase in `docs/fire_10km_optimizer_refinement_report.md` resolves the marginal 10 km tau025 fire optimizer diagnostic. The harmonized 10 km tau025 model is strict-valid under the BFGS diagnostic fit and materially identical to baseline, so the 10 km design can remain the leading primary spatial estimand for fire.

## Deprecated Inputs

For primary fire measurement, deprecate the previous 2021-2022 max-DOY-derived classification and the old tau025 2021-2022 products in `data/fire_precomputed_500m/`. Keep them for audit and pipeline-version sensitivity only.

Tree-cover loss and agriculture were not reprocessed in this phase.
