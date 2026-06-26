# Revised Spatial Pseudo-Boundary Falsification Report

Generated on 2026-06-24 by `scripts/12_spatial_boundary_falsification_revised.R`.

## Design

The revised spatial pseudo-boundary falsification preserves the stopped pre-outcome screen and uses a fixed, researcher-approved design selected before pseudo-boundary outcomes were fitted:

- Actual boundary: 0 km, symmetric -10 km to +10 km corridor.
- Primary spaced outer set: +20, +40, and +60 km.
- Dense outer-gradient sensitivity: all ten valid outer centers from +15 through +60 km.
- Limited inner descriptive checks: -15 and -20 km.

For pseudo-boundaries, the comparison is interior-facing versus exterior-facing relative to the offset center. Pseudo-boundary sides are not legal inside/outside park labels. The two inner checks overlap substantially and are not a reference distribution. Outer ranks and percentiles are descriptive diagnostics only.

## Actual-Boundary Reproduction

All reproduction checks passed: TRUE. Maximum component difference: 3.411e-13.

- Fire profile contrasts: maximum absolute difference 2.78e-17.
- Fire pairwise differences: maximum absolute difference 4.16e-16.
- Fire retained diagnostics: maximum absolute difference 3.41e-13.
- Tree-cover-loss and agriculture profile estimates: maximum absolute difference 4.44e-16.
- Tree-cover-loss and agriculture pairwise differences: maximum absolute difference 4.44e-16.

## Boundary Sets

Primary spaced outer centers: 20, 40, 60 km.
Dense outer centers: 15, 20, 25, 30, 35, 40, 45, 50, 55, 60 km.
Limited inner checks: -15, -20 km.

## Comparability

The primary spaced outer pseudo-boundaries have sample sizes similar to the actual 10 km boundary, but covariate balance varies by offset:

| center km | cells | side ratio | median abs SMD | max abs SMD |
|---:|---:|---:|---:|---:|
| 0 | 42,554 | 1.071 | 0.177 | 0.733 |
| +20 | 38,751 | 1.077 | 0.189 | 0.264 |
| +40 | 38,718 | 1.063 | 0.055 | 0.273 |
| +60 | 36,830 | 1.122 | 0.078 | 0.240 |

The +40 and +60 km corridors have better pooled covariate balance than the actual boundary by median and maximum absolute SMD. The +20 km corridor is similar in size and side ratio but not clearly better balanced by median SMD.

## Fire

The actual fire profile-specific contrasts do not lie outside the +20/+40/+60 km spaced-outer range:

| profile | actual | +20 | +40 | +60 |
|---|---:|---:|---:|---:|
| Neither actor dominant | 0.170 | 0.422 | -0.314 | -0.148 |
| Militia dominant | 0.011 | 0.513 | -0.350 | -0.208 |
| Park dominant | 0.068 | 0.478 | -0.484 | -0.130 |

The dense outer-gradient results also reproduce similar fire contrast magnitudes. Actual fire profile percentiles within the outer values are 60-80, and none is outside the outer 80% envelope. Fire profile-specific contrasts are therefore classified as not boundary-specific.

For fire pairwise profile differences, the actual militia-minus-neither contrast is outside the spaced-outer range and the outer 80% envelope. The Park-minus-neither and Park-minus-militia pairwise differences are not distinct from outer pseudo-boundary patterns. Fire pairwise evidence is therefore mixed: partial boundary-specific support for militia-minus-neither only.

Retained fire fits were strict-valid for 6 of 13 boundaries, including the actual boundary and +60 km. The +20 and +40 km primary outer fits were finite and numerically stable but not strict-valid because independent gradients remained just above the strict threshold.

## Tree-Cover Loss

The actual tree-cover-loss profile-specific contrasts are substantially more negative than the spaced outer set:

| profile | actual | +20 | +40 | +60 |
|---|---:|---:|---:|---:|
| Neither actor dominant | -0.846 | -0.393 | 0.378 | -0.098 |
| Militia dominant | -0.898 | 0.132 | 0.177 | 0.309 |
| Park dominant | -1.430 | -0.417 | 0.504 | -0.070 |

All three actual profile contrasts fall outside the spaced-outer range and outside the dense outer 80% envelope. The actual percentiles within the outer values are 0 for all three profiles. The two inner checks have only 2 and 10 tree-cover-loss events and are descriptive, but they do not overturn the stronger outer-boundary evidence. Tree-cover-loss profile-specific contrasts receive boundary-specific support.

Tree-cover-loss pairwise differences are less clearly boundary-specific. Park-minus-neither receives partial boundary-specific support; militia-minus-neither and Park-minus-militia are not boundary-specific because comparable pairwise differences occur along the outer gradient.

## Agriculture

Agriculture remains support-sensitive. The actual profile-specific estimates lie outside the +20/+40/+60 km range, but the dense outer-gradient and sparse-event burden do not support a strong boundary-specific classification. The inner checks are especially sparse, with 1 agriculture event at -20 km and 31 at -15 km, and both inner checks have zero-event burdens of 1.000 at the SESU-year contrast level. Agriculture profile-specific and pairwise findings remain inconclusive.

## Boundary-Specificity Classification

| finding group | classification |
|---|---|
| Fire profile-specific contrasts | not boundary-specific |
| Fire pairwise profile differences | partial for militia-minus-neither; otherwise not boundary-specific |
| Tree-cover-loss profile-specific contrasts | boundary-specific support |
| Tree-cover-loss pairwise differences | partial for Park-minus-neither; otherwise not boundary-specific |
| Agriculture profile-specific contrasts | inconclusive |
| Agriculture pairwise differences | inconclusive |

## Scientific Implications

The 10 km actual-boundary estimand remains defensible as the primary boundary-local design because it is fixed by the measurement and optimizer phases and reproduces exactly here. The falsification analysis does not justify a stronger boundary-specific interpretation for every outcome.

Claims that survive most cleanly are the negative tree-cover-loss interior-facing contrasts at the actual boundary. Fire should be framed as a measured boundary-local association that is not uniquely aligned with the legal boundary in profile-specific contrasts. Agriculture should remain sensitivity-only or cautiously stated because support and pseudo-boundary behavior are inconclusive.

No further quantitative robustness analysis is recommended before manuscript revision unless the researcher introduces a new scientific question or new source data. The next phase should be manuscript rewriting, table assembly, and figure selection using the harmonized fire measurement, the canonical tau025 tree-cover-loss and agriculture definitions, and the revised falsification classifications.
