# Run and verify the Upemba analysis

Run from the repository root. The original analytical environment is recorded in renv.lock (R 4.5.3). The current code release contains the already-public corrected analyses; current unpublished submission documents are held separately.

## Check retained results

The frozen-result script needs base R. The agricultural checks also need data.table.

    Rscript --vanilla tests/scripts/compare_frozen_results.R
    Rscript --vanilla tests/test_agriculture_followup.R
    Rscript --vanilla tests/scripts/check_final_reconciliation.R

These check 23 frozen scalar targets, 18 classifications, three primary totals, follow-up logic, corrected counts/denominators, retained model rank, bootstrap rows and rainfall coverage. They do not refit models from raw data. See docs/submission/validation/code-release-2026-09-23.md.

## Render combined legal/outer-boundary contrasts

    python -m pip install -r requirements-publication.txt
    python scripts/publication/12_generate_submission_figure3.py

The renderer reads committed CSVs in analysis_spatial_falsification_revised_dev/tables/. It writes PDF, SVG, TIFF and PNG to the ignored local folder outputs/_validation/current_figures/. Set UPEMBA_FIGURE_OUTPUT_DIR to choose another output directory. Generated artwork is not published by running this script.

An installed, licensed copy of Times New Roman is required; the script fails rather than substituting another font. It preserves 99 estimates, checks nine legal estimates/intervals and 18 outer-range endpoints against retained values, and omits interpreted intervals for 21 numerically unaccepted fire fits. It does not fit models. Conditional model-based intervals are retained; agricultural spatial-bootstrap sensitivity is separately available in outputs/final_reconciliation/agriculture_spatial_bootstrap_intervals.csv.

## Reproduce corrected post-event analyses

Restore packages with renv::restore() and configure UPEMBA_DATA_ROOT or ignored config/paths.local.R. UPEMBA_DATA_ROOT is the parent containing **both** data/ and run_2026_05_27/, not the raw-data subdirectory. See config/paths.example.R and the manifests under data/manifests/.

Required inputs include the checksum-matched AFCD annual stack (2000–2022), study-area geometry, frozen grid/covariates and landscape groups, and matching Hansen v1.12 gain/loss-year tiles. Acquisition script scripts/acquisition/01_acquire_hansen_gain_loss_tiles.R obtains the public Hansen tiles and verifies recorded hashes.

    Rscript --vanilla scripts/analysis/09_hansen_gain_and_agriculture_persistence.R
    Rscript --vanilla tests/test_agriculture_followup.R
    Rscript --vanilla tests/scripts/check_final_reconciliation.R

Without a historical-rule override, analysis script 09 defaults to outputs/final_reconciliation/postevent/ and invokes script 10, which writes corrected models, spatial-bootstrap results and annual presence to its parent outputs/final_reconciliation/. Correct persistence requires all three future calendar-year observations through 2022; candidate years end in 2019. Corrected corridor totals are 414 persistent events and 442 period-restricted first crossings; the full-period primary total remains 518.

UPEMBA_POSTEVENT_OUTPUT_DIR and UPEMBA_POSTEVENT_CACHE_DIR redirect outputs/cache. Geometry equality alone does not prove cached inputs are unchanged; start with a fresh cache when input hashes change. tests/scripts/audit_submission_reproduction.R deliberately selects the superseded historical rule in isolation. Use it only to reproduce the historical 431-event result.

Static Hansen gain/loss overlap cannot establish gain after loss. Agricultural first crossing, persistence, reversal and annual presence are not interchangeable measures of ecological recovery or net change.

## Rainfall/fire illustration

    python scripts/acquisition/02_acquire_rainfall_fire_2021.py
    Rscript --vanilla scripts/publication/10_rainfall_fire_appendix.R

The acquisition script defaults to 2021; UPEMBA_ILLUSTRATION_YEAR=2022 selects the second audited year. These need network access and the dependencies listed in their headers. Retained monthly values, coverage audits, source URLs and hashes are under outputs/final_reconciliation/rainfall_fire/. Figure numbering in the retained generator is historical. The plot illustrates one year's seasonal co-occurrence, not a general optimal burning-season window.

## Full workflow and historical layouts

Restore all manifest-listed inputs first. The staged workflow is acquisition script 00 (manual Earth Engine exports), preprocessing scripts 01–03 then 04 for harmonised 2021–2022 fire; primary analysis scripts 01–03; sensitivity scripts 01–03; and matched robustness scripts 04, 05, 06, 09, then 08. See script headers and config/analysis_config.R / config/final_robustness_config.R for inputs. Upstream outputs use UPEMBA_OUTPUT_ROOT (default outputs/); publication code reads retained top-level snapshots. Compare specifications, diagnostics and results before promoting regenerated files.

Publication scripts 06, 08 and 07, in that order, regenerate the older four-main-figure layout and its former supplementary numbering. Script 09 renders an earlier alternative design; script 11 creates September 10 annotated review documents from external sources. These remain for provenance and do not build the current unpublished Word files. tests/scripts/run_downstream_validation.R validates the historical layout.

Raw imagery, restricted historical/operational sources, downloaded software, caches and local paths stay outside Git.
