# Clustering Reproduction Validation

Authoritative script: `scripts/Script 2_SESU clustering.R`.
Frozen reference raster: `run_2026_05_27/SESU_ID_500m.tif`.
Adjusted Rand index: 0.997235754284.
Raw agreement before label matching: 0.999074204520.
Label-matched agreement: 0.999074204520.
Differing cells after label matching: 230.
Cells changed by de-speckling rule: 140 (0.0564%).

The reproduction reruns the frozen covariate-stack k-means specification with seed 123, k = 3, nstart = 25, and the eight-neighbour de-speckling rule, then performs label matching before comparison.
