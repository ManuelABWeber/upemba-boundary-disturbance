# Run and verify the Chapter 1 analysis

Run commands from the repository root. Read [the submission handover](docs/submission/ch1-analysis-handover.md) before reconciling a manuscript. No new outcome definitions or corrected persistence sensitivity were introduced by this audit.

## Checks using retained repository results

An installed R environment with the packages in `renv.lock` is required. `--vanilla` avoids bootstrapping an empty project library; it does not install dependencies. Restore `renv` before full upstream reproduction, and retain session information. The audit environment is recorded in `docs/submission/validation/reproduction_session.txt`.

```powershell
Rscript --vanilla tests/scripts/compare_frozen_results.R
Rscript --vanilla tests/test_postevent_diagnostics.R
Rscript --vanilla tests/testthat/test-final-robustness-functions.R
Rscript --vanilla tests/scripts/run_downstream_validation.R
```

The first command checks 23 scalar results, 18 classifications, and the locked totals: 508,320 burned cell-years, 519 tree-cover-loss events and 518 agricultural-expansion events. It compares retained exports; it is not a raw-data model refit. The post-event check likewise checks retained outputs and numerical fit status, not scientific adequacy of censoring.

Downstream validation runs publication scripts 06, 08, 07, then frozen comparisons. It regenerates figures, tables, HTML and source data; review the diff. It preserves manuscript and supplementary DOCX files. Logs remain ignored under `outputs/_validation/downstream_logs/`; stage and dependency checks are retained under `reports/repository/`.

Publication script 06 reads the retained top-level analytical directories, writes main tables, Figures 3–4 and Figure 2 source data. Script 08 renders the canonical Figure 2 annual trajectories. Script 07 regenerates supplement tables/figures/HTML while retaining its existing DOCX. Figure 1 remains a retained asset whose restricted geospatial inputs are not distributed. Publication script 09 regenerates the preserved alternative figure revisions only; its chronology-only Figure 2 is a different editorial design.

## Reproduce existing post-event analyses from external inputs

`UPEMBA_DATA_ROOT` is the parent containing **both** `data/` and `run_2026_05_27/`, not the raw-data subdirectory itself. Configure it in the environment or ignored `config/paths.local.R`; see `config/paths.example.R` and `data/manifests/required_external_inputs.csv`. The original local `Chapter_1` checkout supplies these inputs and must remain available.

Required for post-event reproduction:

- `<UPEMBA_DATA_ROOT>/data/AFCD_stack.tif`: 23 annual binary layers, 2000–2022, checksum in `data/manifests/postevent_diagnostic_inputs.csv`.
- `<UPEMBA_DATA_ROOT>/data/studyarea_chapter1.geojson`.
- `<UPEMBA_DATA_ROOT>/run_2026_05_27/SESU_covariates_500m.tif` and `SESU_ID_500m.tif`.
- Four matching Hansen v1.12 gain/loss-year tiles under ignored `data/external/hansen_gfc_2024_v1_12/`. Acquire missing tiles with `Rscript --vanilla scripts/acquisition/01_acquire_hansen_gain_loss_tiles.R` and verify the manifest checksums.
- The tracked territorial-control chronology in `data/governance_profiles/`.

```powershell
$env:UPEMBA_DATA_ROOT = 'D:/authorized/ch1-inputs' # replace with your local input parent
Rscript --vanilla tests/scripts/audit_submission_reproduction.R
```

The audit wrapper executes the existing generator in isolated `outputs/_validation/submission-postevent/`, compares ten post-event CSVs with retained results, reconstructs the same sparse model object, and writes aggregate evidence to `docs/submission/validation/`. It also refits the two primary sparse models from retained legal-boundary surfaces. It does not replace authoritative analytical outputs. Raw-input projection occurs when the isolated cache is absent; subsequent runs reuse it. Start with a fresh isolated cache when input checksums change. Generator caches validate geometry only, so a same-geometry cache must not be assumed to match changed inputs.

For intentional regeneration after review, run analysis script 09 and then 08. `UPEMBA_POSTEVENT_OUTPUT_DIR` redirects script 09 and its cache; its default is `outputs/final_robustness/`. The deprecated analysis script 07 was deleted because it overwrote completed results with missing-input placeholders. Do not substitute a corrected follow-up policy without an explicit scientific decision and separately labelled analysis.

## Full upstream workflow

One-time acquisition/preparation: acquisition script 00 (manual GEE exports), preprocessing scripts 01–03, followed by 04 for harmonized 2021–2022 fire. Historical source-preparation code is not authoritative for the final fire reconstruction. Restore all manifest-listed external inputs first.

Primary models: analysis scripts 01–03. Spatial/threshold/measurement and revised boundary sensitivities: sensitivity scripts 01–03. Matched final robustness: analysis scripts 04, 05, 06, 09, then 08. Scientific specifications are `config/analysis_config.R` and `config/final_robustness_config.R`; shared risk sets, HC3 covariance and model validity are in `scripts/lib/final_robustness_functions.R`.

Upstream scripts use `UPEMBA_OUTPUT_ROOT` (default `outputs/`) for analytical outputs, whereas publication scripts consume retained top-level `analysis_*_dev/` snapshots. Reproduce upstream into a separate output root, compare against retained results, and resolve discrepancies before promoting outputs. Never infer authority from the `_dev` suffix or copy a fresh fit over a frozen result without checking its specification and diagnostics.

Raw rasters, caches, private evidence, operational records and local path configuration stay outside Git. Repository checks do not reproduce acquisition, frozen spatial clustering, every optimizer/robustness run, or manuscript editorial reconciliation.
