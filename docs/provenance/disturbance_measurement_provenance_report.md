# Disturbance Measurement Provenance Report

Generated in the measurement-harmonization phase on 2026-06-24.

## Verified Facts

- The current branch started from `def9462 Add spatial and threshold sensitivity analyses`; Phase 3 is tagged as `post-spatial-threshold-phase3-2026-06-24`.
- The canonical analytical tau025 outcomes reproduce exactly when read from `run_2026_05_27/SESU_covariates_500m.tif`.
- Canonical embedded objects are `fireDOY_2001` through `fireDOY_2022`, `year_deforest_masked`, and `year_agri`.
- Standalone threshold products for tau010, tau025, and tau050 match the canonical 500 m grid.
- Agriculture tau025 remains identical between the canonical embedded layer and standalone product after AOI masking, grid alignment, event-year coding, and risk-set construction.
- Script 0 exports unmasked GFC threshold-crossing years by default: `MASK_DEFOREST_TO_FOREST2000 = false`.
- Script 2 creates the canonical `year_deforest_masked` by applying `treecover2000_mean_pct_500m >= 30`.
- The harmonized standalone tree-cover-loss threshold series applies the canonical `forest2000_ge_30pct` mask to tau010, tau025, and tau050.

## Local Pipeline Differences

### Fire

The standalone tau025 fire product matches the canonical embedded fire classification for 2001-2020. The full 28,196 additional standalone fire events come from 2021 and 2022:

- 2021: 14,352 standalone-only events.
- 2022: 13,844 standalone-only events.

The local 2021-2022 standalone binary rasters do not classify identically to the corresponding local `fireDOY_max` rasters when fire is defined as DOY 100-300. This points to a 2021-2022 processing-version difference, not a 2001-2020 FireCCI stack difference.

### Tree-Cover Loss

The canonical embedded layer has 6,268 nonzero tree-cover-loss event cells in the comparison cells. The raw standalone tau025 product has 5,533 event cells, 735 fewer than canonical. After applying the fixed canonical forest mask, harmonized standalone tau025 has 5,460 event cells. Within the 2001-2022 analytical risk set, the harmonized standalone tau025 summaries match the canonical model-ready event count because the extra canonical nonzero years do not contribute additional study-period events.

Mask diagnostics:

- Tau010 raw events: 20,490; removed outside canonical forest mask: 754; harmonized events: 19,736.
- Tau025 raw events: 5,533; removed outside canonical forest mask: 73; harmonized events: 5,460.
- Tau050 raw events: 753; removed outside canonical forest mask: 0; harmonized events: 753.

### Agriculture

Canonical and standalone tau025 agriculture are identical:

- Canonical events: 2,685.
- Standalone events: 2,685.
- Event cells with different years: 0.

## Inferred Provenance

- The canonical fire pipeline combines a GEE-derived 2001-2020 FireCCI seasonal DOY stack with local 2021-2022 fire preprocessing.
- The 2021-2022 discrepancy is most plausibly due to a difference between binary burned rasters and the canonical embedded DOY-based seasonal event definition.
- The tree-cover-loss discrepancy reflects a processing-version difference plus the need to apply the canonical baseline forest mask consistently after export.
- The standalone threshold series is internally more suitable for threshold sensitivity because tau010, tau025, and tau050 are handled through one local harmonization script.

## Unresolved Provenance

Complete canonical provenance is not recoverable from local files alone. The researcher should retrieve:

- GEE Code Editor script revision for the canonical exports.
- GEE task/export history and export date.
- Source collection version and asset or Drive task ID.
- Original exported file checksums for the canonical fire and GFC products.
- Confirmation of the 2021-2022 fire binary versus DOY event definition.

## Model Consequences

Pipeline-version sensitivity at tau025 is negligible for model estimates in the final harmonized workflow:

- Fire all-cell profile differences from canonical are near zero; the largest all-cell profile shift is Park dominant, -0.0067 log-odds units, about -0.12 canonical standard errors.
- Tree-cover-loss tau025 model-ready estimates are unchanged after harmonization because the study-period event support matches the canonical analytical summaries.
- Agriculture tau025 estimates are unchanged because the products are identical.

Within the standalone threshold pipeline, fire profile signs are stable for all cells. Tree-cover-loss remains negative for Militia and Park profiles, while the Neither profile is threshold-sensitive around zero. Agriculture remains threshold-sensitive and support-sensitive.

## Scientific Measurement Implications

The canonical embedded tau025 version was the safest primary implementation before the 2021-2022 fire rebuild because it was exactly reproducible locally and matched the existing analytical run. This statement is now superseded for fire by `docs/fire_2021_2022_harmonization_report.md`: the rebuilt harmonized 2001-2022 fire series better matches the stated seasonal burned-fraction definition and is the recommended primary fire measurement candidate. The canonical embedded fire series should remain as a pipeline-version sensitivity.

For tree-cover loss, the canonical-versus-standalone measurement decision remains conditional because exact GFC export provenance is unresolved. Agriculture remains identical across canonical and standalone tau025.

This recommendation is conditional on provenance and measurement validity, not on model significance or preferred effect sizes.
