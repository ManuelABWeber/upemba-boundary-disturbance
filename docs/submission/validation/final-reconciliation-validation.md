# Final reconciliation validation — 10 September 2026

| Check | Result |
|---|---|
| Corrected script 09/10 execution with external annual AFCD and Hansen inputs | Completed; 414 corridor persistent events, 1,994 full-domain events; saved model objects and HC3 covariance. |
| Canonical first-crossing reconstruction | All 2,685 full-domain event dates reproduced; cell IDs, sides, signed distances and domain flags agree. |
| Exact primary agriculture input | All 88 side/group/year event and at-risk rows agree; 518 events, 254 inside and 264 outside. |
| Full/restricted/persistent support | 931,657 / 805,391 / 805,592 at-risk cell-years; 518 / 442 / 414 events. |
| Annual agricultural presence | 936,188 observed cell-years; 12,031 positive cell-years, 4,482 inside and 7,549 outside. |
| Follow-up unit checks | Passed: complete +1/+2/+3, 2019 cutoff, missing predecessor/future values, later qualifying recrossing, baseline retention, separate reversal eligibility. |
| Whole-trajectory uncertainty check | 499 successful spatial-bootstrap replicates per model; four models, three profiles; paired period/definition changes retained. |
| Historical reproduction | Ten CSV comparisons pass with maximum numerical difference 0; original 431-event fit and all Hansen outputs remain reproducible. Explicit historical mode prevents corrected-year censoring from entering this comparison. |
| Existing downstream suite | Four stages pass: publication scripts 06, 08, 07 and frozen comparison. 23 scalar expectations, 18 classifications and all three primary totals pass unchanged. |
| Targeted reconciliation check | `tests/scripts/check_final_reconciliation.R` passes model rank, support, exact sample, reversal denominators, Hansen totals, bootstrap completeness and monthly area accounting. |
| New figure | 24 landscape-month rows for 2021; all twelve monthly products; rainfall observed fraction 1; observed, non-burnable and missing fire areas sum to domain area. Initial 95% fire gate failed and is disclosed, not counted as a successful coverage check. |
| Review document check | `tests/scripts/check_submission_review.py` passes corrected numerical text, table/figure linkage, six restored 10% fire intervals, unchanged source hashes, nonempty PDF pages and no text outside page bounds. |
| Word/PDF rendering | LibreOffice 26.8.0 via the documents skill renderer with Poppler. Main manuscript 13 pages, supplement 20, highlights 1, cover letter 1. PDF previews retained alongside Word review files. |
| Visual QA | All-page render overview inspected, with full-page checks of equations, Figure 3, corrected tables, S7, seasonal figure/caption and reference pages. Figures and captions kept together; table vertical rules/shading removed; repeated headers retained; no observed clipping. Seasonal vector PDF and 600 dpi PNG inspected; Windows superscript-unit encoding corrected. |

Raw-raster reconstruction was feasible using the original Chapter 1 checkout and existing ignored caches. Historical raw-cache reconstruction was already validated in the starting handover; this turn reused that cache for the historical rerun and recomputed corrected classifications/models. This is distinguished from a fresh download/reconstruction of every original primary input. Frozen downstream checks consume retained authoritative outputs, not a complete raw-data rerun of all primary models.

Execution logs are ignored local files in `outputs/_validation/final-reconciliation/`: `corrected_execution.log`, `historical_reproduction.log`, `downstream.log`, `rainfall_final.log`, `render_final.log` and `render_supp_final.log`. Compact execution/session metadata, source hashes and check summaries are committed. Public product versions and acquisition/processing hashes accompany the seasonal figure. Raw imagery, MSI/rendering runtime and restricted source documents are not committed.

Open scientific limits: spatial dependence beyond 5 km tiles, common chronological uncertainty, conditional fire/tree-loss intervals, sparse Plateau agricultural support, native classification accuracy and the January Plateau fire observation gap. Open submission gates: unavailable current S7/commented documents and author-approved declarations/access details. No failed scientific check was resolved by changing a frozen expectation or recoding missing observations as zero.
