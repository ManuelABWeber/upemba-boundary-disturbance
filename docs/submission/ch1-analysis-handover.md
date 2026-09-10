# Chapter 1 analysis handover

The later analytical work is present, and the agricultural persistent-first-establishment refit **ran successfully and reproduces numerically**. It is not ready for unqualified manuscript use: the fitted risk set includes 2021â€“2022 as zero-event years although the persistence definition cannot identify events in those years. The primary estimates remain unchanged. This branch prepares reconciliation; it does not certify a reconciled manuscript or submit it to the journal.

## Authority and provenance

The repository is [ManuelABWeber/upemba-boundary-disturbance](https://github.com/ManuelABWeber/upemba-boundary-disturbance); handover branch: `codex/ch1-submission-audit-cleanup`.

| Evidence | Resolution |
| --- | --- |
| Remote `main` | Fetched and verified at `10d119ee3de06cdeedcb76f1691eab7fb66cf12f`; its only change after `43e09c1` is the README title. Merged into this branch, without changing remote main. |
| Local analytical branch | `analysis/final-robustness-suite` at `d91730f48ec07de52717f56553a34fecbb2ff822`, adding post-event diagnostics after `a84e48890d8201d964658c03078b304f00d3e73d`. Its source, input checksums, classifications and fitted tables agree under reproduction. |
| Earlier robustness snapshot | `a84e488` and the untracked `outputs/final_robustness.zip` contain missing-input/not-estimable persistence placeholders. Every CSV/Markdown archive entry matches that commit after newline normalization. They are superseded by the completed `d91730f` analysis. |
| Original local Chapter 1 checkout | `C:/0_Documents/Chapter_1`, active `publication/finalize-supplement` at `26b19e4`. Its data and `run_2026_05_27` supply indispensable upstream inputs. All 18 pruned branches were ancestors of its retained active branch and supported no active worktree. This checkout is not redundant. |
| Uncommitted revisions | Existing manuscript, editable figure PPTX, two timeline images, alternative main figures and publication script 09 were checkpointed and retained. The existing supplementary-script wording edits were retained and regenerated. These are editorial revisions, not evidence of a newer analytical model. |

Both repositories had a single registered worktree. Applicable `AGENTS.md` searches at the repository, parent directories and Chapter 1 project trees found none. Searches also covered relevant manuscript folders, the nested historical project, Downloads leads and local Codex document directories; unrelated fire-regime and Chapter 2 projects were left alone. Historical identifiers were used as leads, not authority inferred from dates.

The four top-level `analysis_*_dev/` directories supply publication scripts and frozen tests. Their dependencies are described in [ANALYTICAL_OUTPUTS.md](../../reports/repository/ANALYTICAL_OUTPUTS.md) and the regenerated [publication input registry](../../reports/publication_outputs/publication_input_registry.csv). Preserve them. The final robustness suite supplements those frozen outputs; it does not automatically supersede the primary model.

## Persistence evidence and exact implementation

The generating code is [analysis script 09](../../scripts/analysis/09_hansen_gain_and_agriculture_persistence.R), using [the shared functions](../../scripts/lib/final_robustness_functions.R) and [final specification](../../config/final_robustness_config.R). The raw annual input is `<UPEMBA_DATA_ROOT>/data/AFCD_stack.tif`, 31,896,288 bytes, SHA-256 `2fea7f5f1ef56f76688de00da036862924cac7580d201a028a21fd3444d2d4e0`. It contains 2000â€“2022 layers. The source is masked to the study area, converted with `AFCD == 1`, and averaged onto the canonical 500 m grid. The annual cache is ignored, not committed.

The raw-input audit reconstructed the fractions using a fresh isolated cache and exactly reproduced all 2,685 canonical first-crossing event dates across the retained full domain. All 23 years have finite fractions for all 204,411 full-domain cells and all 42,554 corridor cells. These are processed-grid coverage checks, not independent classification-accuracy or native-observation-quality validation. [Input hashes](validation/reproduction_input_checksums.csv), [annual coverage](validation/annual_afcd_coverage.csv), and [ten exact output comparisons](validation/postevent_reproduction.csv) are retained.

The historical script saved [model estimates](../../outputs/final_robustness/agriculture_persistent_event_model.csv), [diagnostics](../../outputs/final_robustness/agriculture_persistent_event_diagnostics.csv), [cell classifications](../../outputs/final_robustness/agriculture_postevent_classification.csv), persistence summaries, rule sensitivities and figures. It **did not save its fitted `lm` object**: `fr_fit_sparse()` returned estimates, contrasts and diagnostics, discarding `mod`. No historical persistence model RDS or dedicated execution log was located. The older `session_info.txt` records the July primary workflow, not proof of the August post-event execution.

The audit now supplies a [newly reproduced model and HC3 covariance](validation/agriculture_persistent_refit_audit.rds), [88 side-specific surface rows](validation/persistent_model_surface.csv), [44 modelling contrasts](validation/persistent_model_contrasts.csv), [year/profile support](validation/persistent_year_profile_support.csv), a repeatable [audit script](../../tests/scripts/audit_submission_reproduction.R), and [execution environment](validation/reproduction_session.txt). The RDS is explicitly an audit reconstruction, not an original historical object. Exact agreement with retained numerical outputs supplies evidence beyond methods prose.

### Response, risk set and event dating

- Response: each landscape-group/year's inside-minus-outside log odds of **first qualifying persistent establishment**, modelled by weighted linear regression on territorial-control profile and landscape-group fixed effect. Haldaneâ€“Anscombe adds 0.5 to all four event/non-event counts; inverse approximate sampling variance supplies weights. HC3 covariance and normal 95% intervals are used. Profile predictions average the two landscape-group model vectors equally.
- Domain: absolute signed park-boundary distance at most 10 km, inside when distance is negative. Retained groups are SESU 1 (Depression) and SESU 3 (Plateau); SESU 2 is excluded. There are 42,554 starting cells, 931,978 fitted risk-set cell-years, 44 group-years, model rank 4, 25 group-years flagged for a zero count, and no recorded fit warnings.
- Event dating: identify each below-25% to at-least-25% annual transition, then take the **first transition that meets the future persistence rule**. The date is the crossing year, not the later confirmation year. A transient earlier crossing can be followed by a qualifying later crossing. The cell remains at risk through its qualifying event year, then exits; cells without a qualifying event remain at risk throughout the fitted period.
- Baseline: 2000 supplies the preceding-year state. The implementation does not remove all cells above threshold at baseline (378 corridor cells); a later fall and recrossing can qualify. It is first detected qualifying establishment within this observation window, not necessarily first-ever cultivation.
- Follow-up rule: for events through 2019, all three following annual fractions must be finite. For 2020, only +1 and +2 exist and both must be at least 25% to qualify. Persistence requires at least two post-event values at/above 25%, including +1 or +2. Reversal requires both +1 and +2 below 25%. Other observed patterns are intermittent. Events in 2021â€“2022 are descriptively right-censored; missing earlier required fractions are missing/uncertain.

There are 431 persistent establishments in the corridor: 428 in Depression and 3 in Plateau; 223 inside and 208 outside. Profile totals are 124 fragmented, 192 militia-centred and 115 park-centred, passing the implemented support rule (30 overall, at least five in each profile). Of these, 424 qualify at the canonical first crossing and seven qualify at a later transition; [dating counts](validation/persistent_event_dating_counts.csv) retain those distinctions. Full-domain qualifying establishments total 2,106, versus 2,007 cells persistent immediately after their canonical first crossing.

### Estimates and comparison with the primary model

All entries below are conditional inside-minus-outside log-odds contrasts, with 95% confidence intervals. Primary estimates are the unchanged 518-event model; persistence estimates are the reproduced 431-event historical specification.

| Profile | Primary estimate [95% CI] | Persistent estimate [95% CI] | Change |
| --- | --- | --- | --- |
| Fragmented | 0.286486 [âˆ’0.164300, 0.737272] | 0.295366 [âˆ’0.137160, 0.727892] | +0.008880 |
| Militia-centred | 0.221756 [âˆ’0.048300, 0.491812] | 0.179019 [âˆ’0.150199, 0.508237] | âˆ’0.042738 |
| Park-centred | âˆ’0.346961 [âˆ’0.656864, âˆ’0.037058] | âˆ’0.236743 [âˆ’0.641880, 0.168395] | +0.110219 |

Persistent pairwise contrasts are fragmented minus militia 0.116347 [âˆ’0.464403, 0.697097], fragmented minus park 0.532108 [âˆ’0.136127, 1.200343], and militia minus park 0.415761 [âˆ’0.162052, 0.993574]. Every persistence profile and pairwise interval includes zero. The negative park-centred point estimate attenuates and its interval no longer excludes zero. This is specification sensitivity, not proof of no agricultural association.

**Unresolved scientific limitation:** possible qualifying event years end in 2020, but `surface_from_event_vector()` loops through 2022. It includes 42,123 at-risk cells and zero events in each of 2021 and 2022, under park-centred profiles. Descriptive right-censoring does not censor the fitted risk set. Missing future follow-up prevents an event from qualifying and otherwise leaves a cell in the no-event risk set; processed AFCD had no internal missing fractions in this run. An explicit scientific decision on eligible model years and censoring is needed before treating the refit as a resolved sensitivity. No corrected fit or new outcome was run here; the numerical `valid` flag is not a scientific approval of this treatment.

## Domains and the manuscript/S7 discrepancy

The supplied S7 reversal numerators are reproducible, but their denominators describe the **full retained study domain**, including cells with insufficient follow-up. [Domain/class counts](validation/agriculture_domain_class_counts.csv) show:

| Domain and side | First crossings | Persistent at first crossing | Reversed | Intermittent | Right-censored |
| --- | ---: | ---: | ---: | ---: | ---: |
| Full, inside | 255 | 219 | 10 | 8 | 18 |
| Full, outside | 2,430 | 1,788 | 193 | 111 | 338 |
| 10 km, inside | 252 | 218 | 10 | 8 | 18 |
| 10 km, outside | 266 | 206 | 13 | 8 | 37 |

Thus full-domain reversal is 10/255 and 193/2,430 when expressed against *all* events; classifiable-event denominators are 237 and 2,092. Corridor reversal is 10/252 and 13/266 against all events, or 10/234 and 13/229 against classifiable events. The corridor has 55 late events without sufficient follow-up. Persistence among classifiable first crossings is 2,007/2,329 (86.2%) full-domain and 424/463 (91.6%) corridor. Do not silently interpret all-event proportions as reversal risk conditional on adequate follow-up.

The full-period tree-loss counts are 5,460 full-domain versus 519 corridor in the retained spatial-domain outputs. However, the **completed Hansen overlap diagnostic does not use 5,460 as its loss-crossing denominator**: it restricts crossings to 2012 and reports 2,801 full-domain cells (599 with overlap) and 364 corridor cells (46 with overlap). The separate 20 km diagnostic also happens to have 519 crossings through 2012; this is not the primary 10 km total. See [Hansen overall results](../../outputs/final_robustness/hansen_loss_gain_overlap_overall.csv) and [spatial-domain support](../../analysis_spatial_threshold_sensitivity_dev/tables/event_support_summary.csv).

The native Hansen check counts 7,603 overlapping pixels among 1,445,406 pixels lost in 2001â€“2012, using a static 2000â€“2012 gain flag. Its temporal order is unknown: gain can precede or follow loss. Neither native overlap nor the 500 m summaries establish post-loss recovery, forest regrowth, or net forest change.

Annual agricultural **presence** would instead classify each year's cropland state and retain repeated observations after crossings. **Net change** would compare states/fractions between dates, balancing increases and decreases. Neither is the first persistent-establishment response. The available complete annual processed AFCD fractions support constructing an annual-presence sensitivity, subject to an explicitly chosen response, domain and observation-quality policy. No such new sensitivity or net-change model was initiated.

The exact current manuscript and S7 combination quoted in the request was not located among the inspected DOCX files. The repository supplement contains S1â€“S4; the separately stored Biological Conservation documents contain editorial revisions but not the supplied S7 passage. Their hashes and relevant-content flags are in [the manuscript inventory](validation/manuscript-inventory.csv). None was overwritten with a repository copy. Reconciliation should replace the blanket annual-AFCD-unavailable statement, identify the descriptive and fitted domains separately, disclose the unresolved model follow-up issue, and avoid regrowth claims. The exact S7 source remains needed to reconcile its wording and citations line by line.

## Cleanup, recovery and validation

The [cleanup manifest](cleanup-manifest.csv) records 249 removed files (475,577,858 bytes): 57 files in a byte-identical extracted historical project, the stale robustness ZIP, an obsolete placeholder analysis, superseded repository inventories/status documents, empty R histories and previous scratch validation outputs. Historical scientific decisions, indispensable external inputs, authoritative `_dev` outputs and unique editorial assets remain. No internal archive was created. Nineteen inactive ancestor branches were pruned after bundling: eighteen in the old checkout and the superseded local robustness branch in this repository. Their histories remain reachable from the retained active branches; see [the branch manifest](validation/local-branch-cleanup.csv). Remote branches were preserved.

The external recovery checkpoint is `C:/0_Documents/ch1-submission-recovery-20260910`. It contains both repositories' all-ref Git bundles, the current tracked/untracked working files, a binary working-tree patch, extra validation scratch, the original historical project ZIP, starting statuses/refs and the pruned-branch list. [Checkpoint hashes](validation/recovery-checksums.csv) verify the packages. Restore individual files from the named archive in the cleanup manifest; use a separate clone of a bundle to inspect historical states without overwriting current work.

Validation completed:

- All ten post-event CSVs reproduced exactly from matched raw inputs and fresh projection; subsequent verification reused the isolated cache. Primary sparse models refitted from retained legal-boundary surfaces agree within 4.5eâˆ’15, including confidence intervals.
- Frozen checks passed: 23 scalar results, 18 classifications and all three primary totals. These reference checks use their existing tolerances; they are not a full raw-data fire-model rerun.
- Downstream scripts 06/08/07 and frozen checks passed; required publication files and static script-path checks passed. Existing manuscript and supplementary DOCX hashes were preserved. Regenerated S16/S17 wording reflects the pre-existing supplementary-script edits; analytical numbers were retained.
- Nested sourcing exposed a configuration-path bug (`sys.frame(1)$ofile` resolved to the caller). The configuration now locates its own source frame; numerical reproduction passed after the fix. The post-event output override enables isolated verification, and downstream stage logs are retained locally instead of discarded.

Raw acquisition, frozen clustering, every historical/robustness optimizer and a complete fire refit were not rerun. The successful checks above identify exactly what was reproduced. A clean clone can regenerate publication exports from tracked tables but needs authorized external inputs for the post-event audit. No required post-event input was missing locally.

## Remaining reconciliation work

1. Decide the persistent-establishment model's eligible years/censoring scientifically, then authorize any separately labelled corrected analysis. The existing result remains preserved for comparison.
2. Supply/identify the exact current manuscript and S7 file; reconcile domains, follow-up denominators, the loss/gain time window and claims using this report. Retained repository DOCX files are not declared the newest editorial versions.
3. Choose between the canonical and preserved alternative figure designs, then reconcile embedded figures, captions, tables and supplement DOCX against the selected manuscript. The alternative chronology-only Figure 2 omits annual trajectories and is not interchangeable with the canonical figure.
4. Confirm final title/authors, contributions, declarations, funding, data/code availability and reuse terms. No licence was invented. Elsevier permits a data statement explaining access restrictions ([official guidance](https://www.elsevier.com/en-in/researcher/author/tools-and-resources/research-data/data-statement)). The live [Biological Conservation author guide](https://www.sciencedirect.com/journal/biological-conservation/publish/guide-for-authors) returned HTTP 403 during this audit, so journal-specific formatting requirements were not certified.

The old input-bearing checkout, its other historical ZIPs/backups, unique drafts/evidence, and the preserved figure variants remain intentionally unresolved rather than deleted on naming or date evidence alone. This handover does not merge into main, change repository visibility, publish private inputs, or submit a manuscript.

### Publication-export defects resolved during final review

Before changing the generated exports, the staged diff showed that script 06 wrote Unicode symbols as literal `<U+...>` tokens under the available C locale. Script 07 joined raw profile names to public display names, leaving nine legal-boundary profile estimates missing in Table S16; its pairwise classification join likewise mixed short and long display labels. Table S17 also referenced a moved decision report and two unretained measurement tables. The fixes use UTF-8 byte output, consistent display keys and retained provenance-report paths. These are export/dependency repairs using existing estimates and classifications, not refits or scientific reclassification. Existing supplementary DOCX files remain unchanged and require later manuscript reconciliation. Downstream checks now reject these missing values and encoding artifacts.

The final staged repository was additionally exported to an isolated clean tree and passed publication regeneration, frozen tests, post-event checks and shared-function checks without external rasters or local path configuration. [Clean-tree results](validation/clean-tree-validation.csv) and [the tested Git tree identifier](validation/clean-tree-execution.txt) are retained. The temporary exported copies and their ZIPs were removed after validation.
