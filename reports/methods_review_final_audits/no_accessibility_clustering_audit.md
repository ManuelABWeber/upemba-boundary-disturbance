# No-Accessibility Clustering Audit

Selected no-accessibility k by silhouette: 3.
No-accessibility k=3 ARI versus frozen partition: 0.916027.
No-accessibility k=3 full-landscape agreement: 97.390464%.
No-accessibility k=3 primary 10 km agreement: 96.790431%.
Outcome-model sensitivity triggered: FALSE.

The only specification change is removal of `accessibility_cities`. The frozen `SESU_ID_500m.tif` remains the full-covariate reference. No outcome models were run by this script.

## Code-Derived Settings
- canonical_grid: 500 m EPSG:32735
- silhouette_sample_size: 20000
- silhouette_sample_seed: 42
- same_sample_all_k: yes
- k_range: 2 through 15
- kmeans_random_starts: 25
- final_fit_seed: 123
- despeckling_rule: eight-neighbour modal reassignment for isolated labels
- outcome_model_sensitivity_triggered: FALSE
