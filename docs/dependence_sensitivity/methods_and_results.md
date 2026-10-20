# Supplementary dependence assessment

The spatial bootstrap resamples complete 2001–2022 histories in geographic blocks, jointly across landscape groups and boundary sides. It evaluates 5, 10, 20 and 40 km blocks at two origins. Tree loss uses 4,999 draws per smaller-scale configuration and 19,999 at 40 km; fire uses 999. Joint legal-versus-outer comparisons use the same geographic resamples at all eleven boundaries, with 9,999 tree-loss draws and 999 fire draws. All planned scales are retained. Large blocks contain few independent spatial units and are long-range sensitivity checks (Lahiri, 2003).

Temporal checks aggregate estimating-function contributions within calendar year, retaining covariance across landscapes and sides. Bartlett HAC bandwidths zero to four allow contemporaneous and short serial covariance, with a 22/21 adjustment and a t critical value with 21 degrees of freedom. Tree loss uses HC3-adjusted scores; fire uses independently checked likelihood scores and the full Hessian. Leave-one-year-out estimates and a fire delete-year jackknife assess influence. Tree-loss CR2 intervals with Satterthwaite degrees of freedom use individual years and consecutive two- and three-year clusters at every origin (Pustejovsky and Tipton, 2018). The short record limits inference; these complementary sensitivities do not fit a single spatiotemporal process.

Paired profile contrasts are computed within each common resample. Legal-minus-outer differences retain their joint covariance. Approximate simultaneous bands use the 95th percentile of the maximum absolute standardized, bootstrap-centred deviation across the thirty profile-by-outer-boundary comparisons. An extreme point estimate does not establish a difference from every other location. The forest-only population is reported separately and does not replace the primary all-cell denominator.

The primary point estimates remain unchanged. Lower tree loss is supported most consistently under fragmented and park-centred control; some small-sample temporal configurations leave the militia-centred reduction uncertain. Fire intervals include zero in every 10 km and larger spatial configuration. The militia-minus-fragmented fire boundary contrast stays negative across the eight spatial and five temporal configurations, although earlier chronology/episode checks still limit broader claims. The legal boundary retains the largest estimated tree-loss reduction, but simultaneous comparisons do not distinguish it from every outer contrast. These results do not rank conservation effectiveness or establish disturbance mechanisms.

The original conditional estimates and intervals remain in their existing repository locations. New numerical files are under ../../outputs/dependence_sensitivity/. Table numbers below refer to the additional submission supplement and do not change the historical numbering elsewhere in this repository.

| Supplement item | Numerical source in outputs/dependence_sensitivity/ |
|---|---|
| S12 spatial tree loss | tree_spatial_intervals.csv, reported_all_cells/main rows |
| S13 spatial fire | combined_spatial_intervals.csv, fire rows; individual fire_*_intervals.csv |
| S14 temporal HAC and fire jackknife | tree_temporal_hac.csv; fire_temporal_intervals.csv |
| S15 small-sample temporal tree loss | tree_small_sample_temporal.csv, reported_all_cells rows |
| S16 paired profile comparisons | profile_pairwise_spatial_intervals.csv; fire_pairwise_temporal_intervals.csv |
| S17 joint tree legal-minus-outer comparisons | joint_boundary_intervals.csv, tree_cover_loss/reported_all_cells rows |
| S18 joint fire legal-minus-outer comparisons | joint_boundary_intervals.csv, fire rows |
| S19 forest-only spatial tree loss | tree_spatial_intervals.csv, baseline_forest_only/main rows |
| S20 forest-only temporal tree loss | tree_small_sample_temporal.csv, baseline_forest_only rows |
| Figure S5 | dependence_intervals.png; render_figures.py |

The audit verifies all 18,981 accepted fire bootstrap fits, including replicate identities, gradient checks, positive Hessian curvature and recomputed percentile intervals. Independent R calculations reproduce tree-loss estimates and HC3 standard errors at all eleven boundaries, and polished fire contrasts differ from the retained primary values by less than 0.000001 log-odds units. Ten bounded-optimizer cross-checks reproduce bootstrap contrasts to within 0.000002. The final tree audit covers 359,962 model calculations, including the forest-only sensitivity. Computational bookkeeping and unsuccessful alternative optimizer diagnostics are described in computational_notes.md.

Lahiri, S.N., 2003. Resampling Methods for Dependent Data. Springer, New York. https://doi.org/10.1007/978-1-4757-3803-2

Pustejovsky, J.E., Tipton, E., 2018. Small-sample methods for cluster-robust variance estimation and hypothesis testing in fixed effects models. Journal of Business & Economic Statistics 36, 672–683. https://doi.org/10.1080/07350015.2016.1247004
