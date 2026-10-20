# Run and verify the Upemba analysis

Run commands from the repository root. The original analytical environment is recorded in renv.lock (R 4.5.3). The additional dependence calculations used R 4.6.1 and the versions recorded in docs/dependence_sensitivity/. Install their R/Python dependencies explicitly; Rscript --vanilla avoids automatically activating another environment.

The following checks use committed data and do not require the former working directory or raw rasters. The frozen-result script needs base R; the agricultural checks need data.table. The public-tree check needs Python’s standard library and Git in a checkout, or RELEASE_MANIFEST.json in an exported archive.

```sh
python tests/scripts/check_public_repository.py
Rscript --vanilla tests/scripts/compare_frozen_results.R
Rscript --vanilla tests/test_agriculture_followup.R
Rscript --vanilla tests/scripts/check_final_reconciliation.R
Rscript --vanilla tests/testthat/test-final-robustness-functions.R
python -m pip install -r analysis/dependence_sensitivity/requirements.txt
python analysis/dependence_sensitivity/verify_release.py
```

These verify repository hygiene, 23 frozen scalar targets, 18 boundary classifications, three primary event totals, agricultural follow-up rules, corrected counts/denominators and model rank, and the complete additional sensitivity package. The sensitivity audit checks every block configuration against 1,936 count/denominator pairs, all 27 accepted bootstrap runs and recomputed interval summaries. Its verification uses a temporary working directory and does not refit every fire bootstrap model. The [results index](docs/RESULTS_INDEX.md) identifies the authoritative files.

To rerun the additional spatial/temporal dependence checks, follow [analysis/dependence_sensitivity/README.md](analysis/dependence_sensitivity/README.md). It provides the complete sequence, software versions, seeds, approximate timing and optional upstream extraction. New outputs default to outputs/_validation/dependence_sensitivity/. Set UPEMBA_DEPENDENCE_OUTPUT_DIR to choose another working directory. The primary estimates and forest-only sensitivity retain separate population labels.

The following renderer uses committed legal/outer-boundary CSVs. It preserves 99 point estimates, validates nine legal estimates/intervals and 18 outer-range endpoints, and omits interpreted intervals for numerically unaccepted fire fits. It writes PDF/SVG/TIFF/PNG to the ignored outputs/_validation/current_figures/ folder. It does not fit models. Install a licensed copy of Times New Roman; the script fails rather than silently substituting a font.

```sh
python -m pip install -r requirements-publication.txt
python scripts/publication/12_generate_submission_figure3.py
```

Full upstream reconstruction requires the external inputs in data/manifests/. UPEMBA_DATA_ROOT is the parent containing both data/ and run_2026_05_27/, rather than the raw-data subdirectory. See config/paths.example.R. The original pipeline consists of acquisition script 00, preprocessing scripts 01–03 then 04, primary analysis scripts 01–03, and sensitivity scripts 01–03. Matched chronology/influence and alternative-boundary checks are analysis scripts 05 and 06. Compare regenerated results with the retained snapshots before promoting files. No historical document-editing or obsolete figure-layout generators remain in this version.

Corrected post-event analysis requires the checksum-matched AFCD annual stack (2000–2022), study-area geometry, frozen grid/covariates and landscape groups, and matching Hansen v1.12 gain/loss-year tiles. Acquisition script 01 obtains the public Hansen tiles and verifies recorded hashes. Run analysis script 09; it defaults to outputs/final_reconciliation/postevent/ and invokes script 10, which writes corrected models, spatial-bootstrap results and annual presence to outputs/final_reconciliation/.

```sh
Rscript --vanilla scripts/analysis/09_hansen_gain_and_agriculture_persistence.R
Rscript --vanilla tests/test_agriculture_followup.R
Rscript --vanilla tests/scripts/check_final_reconciliation.R
```

Correct persistence requires all three future calendar-year observations through 2022, so candidate event years end in 2019. The corrected corridor totals are 414 persistent events and 442 period-restricted first crossings; the full-period primary total remains 518. UPEMBA_POSTEVENT_OUTPUT_DIR and UPEMBA_POSTEVENT_CACHE_DIR redirect computation. Start with a fresh cache when input hashes change. Static Hansen gain/loss overlap cannot establish gain after loss; agricultural first crossing, persistence, reversal and annual presence measure different responses.

For the seasonal illustration, acquisition script 02 defaults to 2021; UPEMBA_ILLUSTRATION_YEAR=2022 selects the second audited year. Publication script 10 renders the monthly data. These upstream steps need network access, the spatial inputs and their listed dependencies. Retained monthly values, coverage audits, source URLs and hashes are under outputs/final_reconciliation/rainfall_fire/. The figure illustrates one year’s seasonal co-occurrence, not a general optimal burning-season window.

```sh
python scripts/acquisition/02_acquire_rainfall_fire_2021.py
Rscript --vanilla scripts/publication/10_rainfall_fire_appendix.R
```

Raw imagery, restricted historical/operational sources, downloaded software, caches, local paths and paper documents stay outside Git. The repository contains numerical results and analysis documentation rather than a manuscript submission bundle.
