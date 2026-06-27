# Final Repository Validation

Validation date: 2026-06-27

Starting review commit: `35f9aa2186f2ef777a773b96b7dd6248ef67e96e`
Clean-clone validation commit: `00c85d46c24451b45577b55d842a12da88a5a6d7`

## Recovery and repository state

- PASS — Starting working tree was clean.
- PASS — Starting branch was `review/local-repository-cleanup`.
- PASS — Review history descended from `main` at `73233e5115210813fe3a4d5d976490e46b3cadb9`.
- PASS — GitHub authentication was active for `ManuelABWeber`.
- PASS — GitHub repository visibility was `PRIVATE`.
- PASS — GitHub default branch was `main`.
- PASS — All refs were preserved in `C:\0_Documents\upemba-boundary-disturbance_prepublication_20260627_093356.bundle`; `git bundle verify` reported complete history.

## Restored analytical dependencies

- PASS — Required fire-optimizer, governance-robustness, spatial-falsification, and spatial-threshold analytical outputs were restored.
- PASS — Frozen-result tests, citation and sanitization status files, reproducibility status, and submission-metadata status were restored.
- PASS — Final Figure 3 and Figure 4 vector PDFs were restored.
- PASS — Active publication scripts read only retained repository paths; previously broken Figure 1 and fire-surface paths were removed from script 06.
- PASS — The protected analytical files named in the cleanup specification are present and retained.

## Manuscript and supplement

- PASS — Manuscript title is “A protected-area boundary separates tree-cover loss but not fire across changing territorial control”.
- PASS — Manuscript contains the symmetric 10 km corridor, legal/pseudo-boundary analysis, locked tree-cover-loss estimates, locked fire estimates, and outcome-specific modelling framework.
- PASS — Manuscript does not present random-side placebo tests, year-block bootstrap, all-outcome beta-binomial modelling, or consistently boundary-specific fire as the active analysis.
- PASS — Manuscript contains exactly one Figure 2 and four main figure drawings.
- PASS — Embedded Figure 2 is byte-identical to `outputs/publication/main_figures/Figure_2_chronology_time_series.png`.
- PASS — Figure 2 caption matches the final annual-trajectory figure and symmetric-corridor terminology.
- PASS — Supplement contains Supplementary Methods S1–S4 and Tables S1–S18.
- PASS — Supplement contains Figures S1–S3 only and no active Figure S4.
- PASS — Table S13 contains fragmented-control fire with `Sign retained = No`.
- PASS — Historical transition-year and episode-omission diagnostics are reported in Table S13 only.
- PASS — Canonical manuscript: `outputs/publication/manuscript/Chapter1_manuscript_final.docx`.
- PASS — Canonical supplement: `outputs/publication/supplement/Chapter1_Supplementary_Material_final.docx`.

## Figures and publication workflow

- PASS — Figure 1 approved map is retained as `Figure_1_study_design.png` with a matching PDF.
- PASS — Obsolete chronology-only `fig 2.png` was removed.
- PASS — Editable PowerPoint source is retained under `outputs/publication/figure_sources/Figures_1_2_editable_source.pptx`.
- PASS — Main figure directory contains only clearly named final Figure 1–4 PNG/PDF files.
- PASS — Figure 2 script is `scripts/publication/08_generate_figure2_chronology_time_series.R`.
- PASS — Script 06 regenerates canonical Figure 2 source data but does not export the obsolete design.
- PASS — Figure 2 row order is Fire, Tree-cover loss, Agricultural expansion; columns are Depression and Plateau.
- PASS — Figure 2 uses solid black outside lines, dashed black inside lines, 0.60 linewidth, required year labels, horizontal-only panel references, light dashed transition lines, difference shading, and the locked muted profile palette.
- PASS — “Agricultural expansion” is fully visible.
- PASS — Figure 2 PNG is 600 dpi.
- PASS — Figure 2 PDF is vector-based through the Cairo R graphics device.
- PASS — Locked Figure 2 event totals are fire 508,320; tree-cover loss 519; agricultural expansion 518.

## Static and dependency validation

- PASS — `final_retention_manifest.csv` contains only `retain`, `rename`, and `delete` actions.
- PASS — Every deletion is covered by `final_cleanup_actions.csv`.
- PASS — No obsolete candidate Figure 2 file remains.
- PASS — No generic `fig 1.png`, `fig 2.png`, `Manuscript.docx`, or `Supplementary_Material.docx` remains in an authoritative output location.
- PASS — No active Figure S4 reference remains; historical repository-audit records retain only explicit descriptions of already removed files.
- PASS — No old manuscript title remains in active repository text.
- PASS — README, RUN_ANALYSIS, supplement-manifest, and Table S18 path checks completed: 91 paths checked, 0 missing.
- PASS — Supplement manifest source paths are repository-relative; 0 workstation-absolute source rows remain.
- PASS — Table S18 lists current active analysis scripts and publication workflow, including script 08.
- PASS — `.gitattributes` covers required text and binary publication formats.
- PASS — Citation placeholders remain because the manuscript does not contain a complete unambiguous author/affiliation block.
- PASS — No licence was assigned; the README explicitly states that no reuse licence has yet been assigned.

## Runtime and frozen-result validation

- PASS — `Rscript --vanilla scripts/publication/06_generate_main_figures_tables.R`.
- PASS — `Rscript --vanilla scripts/publication/08_generate_figure2_chronology_time_series.R`.
- PASS — `Rscript --vanilla scripts/publication/07_generate_supplementary_material.R`.
- PASS — `tests/scripts/compare_frozen_results.R`: 0 scalar failures.
- PASS — Frozen boundary-specificity classifications: 0 failures.
- PASS — Frozen locked event totals: 0 failures.
- PASS — `tests/scripts/run_downstream_validation.R`.
- PASS — Locked profile estimates and confidence intervals remained within their encoded 0.001 tolerances.
- PASS — No model was refit or altered to satisfy publication validation.

## Clean-clone reproduction

- PASS — Local clone created from review commit `00c85d46c24451b45577b55d842a12da88a5a6d7`.
- PASS — Publication workflow completed in documented order.
- PASS — Frozen-result and downstream tests completed.
- PASS — All 12 explicitly required canonical tracked artifacts were present.
- PASS — Clean-clone run produced 0 untracked files.
- PASS — No active script relied on `config/paths.local.R` or an untracked local input.
- PASS — Regeneration changed tracked generated outputs, as expected for timestamps, source-root provenance fields, and PDF metadata.

## Document and workbook visual QA

- PASS — Packaged LibreOffice renderer was attempted and was unavailable because `soffice` is not installed.
- PASS — Microsoft Word COM rendered the manuscript to a 20-page PDF.
- PASS — Microsoft Word COM rendered the supplement to a 22-page PDF.
- PASS — Every rendered page was inspected via page renders and contact sheets.
- PASS — Figure 2 labels, legends, year labels, and “Agricultural expansion” are visible and not clipped.
- PASS — No obsolete Figure 2 or supplementary figure appears.
- PASS — Table 2 rows are marked non-splitting and render without row breaks.
- PASS — Table S13 is legible and contains the corrected values.
- PASS — No broken visible cross-reference was detected.
- PASS — Supplementary data workbook opened successfully in Microsoft Excel with 9 populated worksheets.

## Remaining publication metadata

- BLOCKED — Complete author affiliations, funding statements, declarations, journal submission metadata, DOI, and preferred citation are not available from reliable repository evidence.
- BLOCKED — Licence selection requires explicit owner authorization.
- PASS — These blockers are documented in `CITATION_PENDING.md` and `reports/publication/submission_metadata_pending.md`; no metadata or licence was invented.
