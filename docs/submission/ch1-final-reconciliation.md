# Chapter 1 final reconciliation — review handover

This work starts from `01a5d338fde07caaeaec05a47e1c052449e250a9` on `codex/ch1-submission-audit-cleanup`. No intervening commits or uncommitted work were found before creating `codex/ch1-final-reconciliation`. The previous cleanup was retained; no further branch pruning was necessary. The original manuscript files and external inputs were preserved. The package is **for review, not certified submission-ready**.

## Scientific decisions and results

The corrected agricultural persistence model ran successfully, retaining **414 corridor events** and 1,994 events in the retained full domain. Candidate crossing years are 2001–2019, with all three calendar-year follow-ups available through 2022. The crossing must reach 25%; at least two of the next three years must reach 25%, including year +1 or +2. All three observations must be finite. The first crossing satisfying this complete rule defines the event, including seven corridor cells qualifying later than their original first crossing.

The 42,554-cell corridor, signed-distance side assignment, Depression/Plateau groups, original baseline eligibility and paired landscape-year model are retained. The original model includes 378 cells agricultural in 2000: an event can be a later recrossing after falling below threshold. Thus “first” means first detected qualifying crossing in the observation window, not first-ever cultivation. Finite baseline observations are required. Cells enter in 2001 and leave after the selected event; persistence retains cells after earlier transient crossings. Missing history/follow-up censors before the first unassessable candidate year. No internal missing annual fractions or baseline exclusions occurred. No 2020–2022 years enter the corrected persistence risk set.

| Model | Events | Park-centred inside-minus-outside log odds [HC3 95% CI] |
|---|---:|---|
| Original first crossing, 2001–2022 | 518 | −0.347 [−0.657, −0.037] |
| First crossing, 2001–2019 | 442 | −0.240 [−0.611, 0.131] |
| Corrected persistence, 2001–2019 | 414 | −0.235 [−0.753, 0.284] |
| Historical persistence, superseded | 431 | −0.237 [−0.642, 0.168] |

The period restriction accounts for most of the park-centred point-estimate change (+0.107); redefining the restricted-period event adds +0.005. Persistence has greater uncertainty (SE 0.265 versus 0.189 for restricted first crossing). Overlapping intervals do not establish equivalence. All models are full-rank weighted linear fits; restricted fits have 38 landscape-years, versus 44 in full-period fits. Coefficients, model objects, covariance matrices, profile/pairwise intervals, diagnostics and side/group/profile/year support are in [final_reconciliation](../../outputs/final_reconciliation/). Sparse Plateau support remains consequential: only three corrected persistent events occur there, and baseline annual presence has four outside agricultural cells and none inside.

The bounded annual-presence analysis uses all 936,188 observed corridor cell-years during 2001–2022, including baseline agricultural cells and observations after first establishment. Its binary response can change in either direction. We retain the paired landscape-year profile design, while resampling whole trajectories in 5 km spatial tiles for uncertainty (499 replicates, seed 20260910; 263 Depression and 355 Plateau tiles). This preserves within-cell serial and within-tile spatial dependence; it does not remove between-tile dependence or uncertainty in the common chronology. Annual-presence profile estimates are −1.549 (fragmented), −1.356 (militia-centred), and −1.175 (park-centred), with spatial-bootstrap intervals [−2.311, −0.098], [−2.074, 0.061], and [−1.900, 0.233]. HC3 intervals are substantially narrower. Annual presence estimates prevalence, first crossing estimates entry into the mapped class, and neither estimates net agricultural change.

The same bootstrap is supplied for all three first-event comparisons and paired changes. For example, the original full-period park-centred interval broadens to [−0.807, 0.102], and corrected persistence to [−0.683, 0.236]. The conclusion should remain cautious about agricultural associations, even where the original conditional HC3 interval excluded zero. Primary fire and tree-loss intervals remain conditional: beta-binomial dispersion and HC3 covariance do not establish independence.

## Cell reconciliation and descriptive diagnostics

The alleged 252-inside/266-outside split was an **arithmetic error in the prior handover narrative**. Its own category rows sum to 254/264. All 2,685 full-domain event IDs agree between canonical reconstruction and historical classifications, with identical event dates, sides, corridor flags and signed distances (tolerance 1e-9 km). Coordinates derive from those canonical grid IDs. All 88 corridor side/group/year event and at-risk counts exactly match the primary-model surface. No boundary assignment or primary estimate was altered. [Cell comparison](../../outputs/final_reconciliation/agriculture_cell_reconciliation.csv) and [primary surface comparison](../../outputs/final_reconciliation/agriculture_primary_surface_reconciliation.csv) retain the evidence.

Reversal requires valid +1 and +2 observations, both below 25%. Full-domain numerators remain 10 inside and 193 outside, but eligible denominators are **237 and 2,092**, rather than all-event denominators 255 and 2,430. There are 18 and 338 insufficient-follow-up cases. Corridor reversal is **10/236 (4.2%) inside and 13/227 (5.7%) outside**, with 18 and 37 insufficient-follow-up cases. There are no missing-data cases in either domain. These are classification reversals, not demonstrated ecological recovery.

Reproduced Hansen outputs confirm 2,801 full-domain cumulative-loss crossings through 2012: 754 cells with any gain, and 599 with native-pixel loss–gain overlap. Corridor values are 364, 58 and 46. These are distinct from all-period loss-event totals of 5,460 full-domain and 519 corridor cells. Static gain cannot establish gain after the dated loss; neither overlap definition demonstrates post-loss recovery.

## Fire model, figures and interpretation

The actual fire model is beta-binomial with fixed landscape-group/year intercepts, side, and inside-by-profile terms; it has no random effects. Figure 3B is retained. Its intervals use the covariance of the pairwise linear contrast, not subtraction of interval endpoints. Panel A signs describe inside versus outside; panel B signs describe the first named profile’s contrast minus the second. Unresolved pairwise differences do not imply equivalence.

The missing 10% fire interval came from a stale publication input. The retained D_BFGS optimizer fit has convergence code 0, positive-definite Hessian and independent maximum gradient 0.000841; the 25% value is 0.000947. The 50% independent gradient is 0.001957, above the 0.001 strict gate, and remains qualified. Publication script 07 now uses the retained refined rows for the 10 km fire sensitivity, without changing frozen analytical outputs. See [optimizer decision record](../decisions/fire_10km_optimizer_refinement_report.md). The +15 km pseudo-boundary's park-facing band is +5–15 km, overlapping the primary outside band; its purpose is an outward-offset location diagnostic, not an independent untreated comparison. Lag checks assess temporal alignment, not causal delays.

No recoverable earlier rainfall–fire script, image or self-contained caption was located in the searched repository/history and manuscript candidates. The additional **review-supplement Figure S3** uses the original products: CHIRPS v2.0 final monthly rainfall and FireCCI51 monthly JD/CL data. It depicts both retained landscape groups in the identical primary corridor for January–December 2021, with unfiltered monthly burns. Rainfall is an area-weighted mean of monthly accumulated mm; fire is mapped burned km² using native geodesic areas and exact polygon intersections. Repeated detections in distinct months contribute again; a monthly composite cannot recover multiple burns within that month. Coverage and missing values are explicit.

The initial selection rule was the earliest reusable complete-product year meeting 95% coverage in every landscape-month. Completing 2021 and then 2022 showed neither met that target (minimum 93.99% and 71.92%). Acquisition stopped after these two bounded years. We retained better-covered 2021, disclosed the amended rule, and plotted mapped-to-mapped-plus-missing-area bounds. Rainfall coverage was complete; January Plateau is the material fire gap. This illustrates seasonal co-occurrence and cannot independently validate an optimal DOY window, causation or representative climatology. Raw downloads remain outside Git. [Figure and provenance](../../outputs/final_reconciliation/rainfall_fire/) contain the vector PDF, 600 dpi PNG, tidy monthly values, both coverage audits, URLs and hashes. Figure S3 numbering applies to the new Word review supplement; the older HTML supplement has a separate existing S3 offset diagnostic.

## Documents and submission gates

The most developed available editorial sources were the anonymized manuscript and supplement in `C:/0_Documents/biological conservation manuscript/Biological_Conservation_submission_package`. Their contents, distinct text and source hashes are recorded in [document provenance](../../outputs/submission_review/source_document_provenance.json). Repository “final” copies are older editorial versions. Neither available supplement contains the S7 described in the request. The only located Chapter 1 document with Word comments is the older `C:/0_Documents/Chapter_1/chapter 1 manuscript.docx` (43 comments). Each is addressed in [the response log](comment-response-log.md); current unlocated comments cannot be certified resolved.

Separate annotated review copies, highlights and a draft cover letter are in [submission_review](../../outputs/submission_review/). Exact main-text replacements and new supplementary methods are committed. Existing sources were not overwritten. Methods, Results, Discussion, Figure 3 caption, sensitivity figure and Tables S11/S18–S21 were reconciled. The available manuscript has 5,982 words including references and four figures (approximately 7,182 against the journal's figure-adjusted limit); its abstract has 203 words. This is not a clean submission package while substantive document-version and declaration gates remain.

The [official journal requirements audit](journal-requirements.md) records the checked instructions. Author confirmation is still required for the current manuscript/supplement carrying S7 and unresolved comments; the de Maret and Weber “in press” entries absent from available candidates; verified author order, affiliations, correspondence, CRediT, funding, competing interests, ethics/permissions and submission declarations; and anonymized reviewer data access/persistent deposit. No author declaration or acceptance status was invented. The Asmani misattribution was corrected from the underlying report title page: Katanga Protection Cluster, May 2015; Asmani is a photograph credit.

## Reproduction and validation

Run from the repository root with `UPEMBA_DATA_ROOT` pointing to the original external Chapter 1 data root. `UPEMBA_POSTEVENT_CACHE_DIR` may point to an existing annual/Hansen cache. With no historical-rule override, script 09 now runs the corrected specification and script 10, writing to `outputs/final_reconciliation/`; it does not overwrite historical results. Historical reproduction explicitly sets `UPEMBA_POSTEVENT_RULE_VERSION=historical_2026_08` in its audit script.

```powershell
$env:UPEMBA_DATA_ROOT='C:/0_Documents/Chapter_1'
$env:UPEMBA_POSTEVENT_CACHE_DIR='C:/0_Documents/upemba-boundary-disturbance/outputs/final_robustness/cache'
Rscript --vanilla scripts/analysis/09_hansen_gain_and_agriculture_persistence.R
Rscript --vanilla tests/test_agriculture_followup.R
Rscript --vanilla tests/scripts/check_final_reconciliation.R
Rscript --vanilla tests/scripts/run_downstream_validation.R
python scripts/acquisition/02_acquire_rainfall_fire_2021.py
Rscript --vanilla scripts/publication/10_rainfall_fire_appendix.R
python scripts/publication/11_reconcile_submission_documents.py
```

The acquisition script defaults to 2021; `UPEMBA_ILLUSTRATION_YEAR=2022` reproduces the second coverage audit. Document generation requires the explicitly identified external editorial sources and `python-docx`, Pillow. Rendering additionally requires LibreOffice and Poppler. New synthetic follow-up tests and final-reconciliation checks pass. The existing four-stage downstream suite passes, including all frozen checks (23 scalar targets, 18 classifications and three primary totals). The primary 508,320 burned cell-years, 519 loss events and 518 agricultural events remain unchanged; no frozen expectations were relaxed. See [validation record](validation/final-reconciliation-validation.md) for execution and visual checks.

The recovery checkpoint from the preceding cleanup remains `C:/0_Documents/ch1-submission-recovery-20260910`; the starting Git commit additionally preserves this turn's source state. Only duplicate newly generated S19-named versions of the now S3 rainfall figure were removed in this turn. Raw imagery, downloaded rendering software and restricted evidence are ignored/external, never staged. No remote branch, source manuscript or unique evidence was removed.
