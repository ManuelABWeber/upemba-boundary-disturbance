# Tree-cover post-loss/regrowth feasibility

## Decision

A post-loss regrowth trajectory is not estimable from the available repository data. No trajectory or recovery percentage has been fabricated.

## Search and suitability audit

- The prepared 500 m stack contains `forest2000_ge_30pct` and `year_deforest_masked` but no annual canopy, woody-cover, vegetation-fraction, NDVI, EVI, or annual land-cover series.
- The restricted data root contains `gfc_treecover2000_meanpct_500m_epsg32735.tif` and cumulative Hansen first-crossing products. These establish baseline eligibility and event timing, not regrowth.
- Repository inventories and scripts contain no validated annual regrowth-sensitive product with 2001-2022 coverage aligned to the 500 m analytical grid.
- Hansen Global Forest Change loss is cumulative; reversing or subtracting cumulative loss would not measure regrowth and was not attempted.

## Data needed

A defensible analysis would require an annual, consistently processed canopy/woody-cover or vegetation-fraction product spanning at least 1998-2022 (to cover event time -3 to +5 where possible), aligned to the 500 m grid, with documented sensor harmonisation, observation quality/missingness flags, and an ecologically justified recovery rule declared before analysis. A reproducible acquisition and validation workflow would also be required.

The manuscript estimand therefore remains the first year cumulative mapped Hansen loss crosses 25% among cells with at least 30% tree cover in 2000. This is not an annual forest-condition or recovery estimand.
