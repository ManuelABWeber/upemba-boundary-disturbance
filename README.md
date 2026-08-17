# A protected-area boundary separates tree-cover loss but not fire across changing territorial control

This private repository contains the publication-facing analysis and output package for the Chapter 1 Upemba boundary disturbance study. The study asks whether protected-area boundary contrasts in remotely sensed fire, tree-cover loss, and agricultural expansion recover interpretable signals of fragmented territorial control in and around Upemba National Park, Democratic Republic of the Congo.

The primary spatial estimand is the symmetric 10 km park-boundary corridor. Fire uses the harmonized 2001-2022 seasonal burned-fraction series; tree-cover loss and agricultural expansion use tau025 SESU-year sparse-outcome contrasts. Locked event totals are fire 508,320, tree-cover loss 519, and agricultural expansion 518.

## Repository Structure

- `config/`: public configuration and measurement manifests.
- `scripts/`: preprocessing, analysis, sensitivity, and publication-generation scripts.
- `data/`: sanitized public inputs and manifests for restricted local inputs.
- `evidence/`: sanitized evidence ledger metadata; restricted source evidence is excluded.
- `outputs/publication/`: final manuscript, supplement, figures, tables, and source data.
- `reports/`: publication, supplement, repository-audit, and validation reports.
- `tests/`: frozen-result comparison scripts and reference checks.

## Reproduction Workflow

1. Review `data/manifests/required_external_inputs.csv` and configure local restricted inputs through `UPEMBA_DATA_ROOT` or `config/paths.local.R`.
2. Restore the R environment from `renv.lock`.
3. Run the staged analysis scripts in `scripts/preprocessing/`, `scripts/analysis/`, and `scripts/sensitivity/` as data access permits.
4. Regenerate the publication package, from the repository root, in this order:
   1. `Rscript --vanilla scripts/publication/06_generate_main_figures_tables.R`
   2. `Rscript --vanilla scripts/publication/08_generate_figure2_chronology_time_series.R`
   3. `Rscript --vanilla scripts/publication/07_generate_supplementary_material.R`

To reproduce the post-event diagnostics added to the final robustness suite:

1. Restore the checksum-matched annual AFCD stack listed in `data/manifests/postevent_diagnostic_inputs.csv` as `<UPEMBA_DATA_ROOT>/data/AFCD_stack.tif`.
2. Download and checksum-verify the public Hansen v1.12 gain/loss-year tiles with `Rscript --vanilla scripts/acquisition/01_acquire_hansen_gain_loss_tiles.R`.
3. Run `Rscript --vanilla scripts/analysis/09_hansen_gain_and_agriculture_persistence.R`.
4. Refresh the integrated claims and methods summary with `Rscript --vanilla scripts/analysis/08_finalize_robustness_outputs.R`.

The Hansen analysis is a 2000-2012 loss-gain overlap diagnostic, not a temporally ordered regrowth analysis. The agricultural analysis reconstructs annual 500 m cropland fractions and must reproduce the canonical 25% first-crossing raster exactly before reporting persistence or fitting the persistent-first-establishment model.

Script 06 regenerates the authoritative Figure 2 source-data CSVs but deliberately does not export Figure 2. Script 08 is the single final Figure 2 renderer. Script 07 regenerates supplementary tables, figures, HTML, and data delivery files while retaining the verified final supplementary DOCX.

`--vanilla` keeps publication-only clean-clone validation independent of an unrestored project library. The full upstream analytical workflow should use the package versions in `renv.lock` after `renv::restore()`.

Restricted raw rasters, private operational evidence, patrol/security material, and large intermediate geospatial products are not included. Authorized researchers should obtain those inputs through the project owner and place them at the configured local data root.

## Final Outputs

- Manuscript: `outputs/publication/manuscript/Chapter1_manuscript_final.docx`
- Supplement: `outputs/publication/supplement/Chapter1_Supplementary_Material_final.docx`
- Main figures: `outputs/publication/main_figures/`
- Supplementary figures: `outputs/publication/supplement/figures/`
- Supplementary tables: `outputs/publication/supplement/tables/`
- Source data: `outputs/publication/figure_source_data/`, `outputs/publication/table_source_data/`, and `outputs/publication/supplement/source_data/`

The final supplementary figure sequence is Figures S1-S3 only. Historical transition-year and episode-omission diagnostics are reported in Table S13 only.

## Availability And Status

This repository is intended to be private. It includes code, sanitized tabular inputs, final outputs, and provenance reports needed to inspect the study and reproduce outputs where data access permits. It does not include confidential evidence, restricted operational data, or large raw remote-sensing/geospatial inputs.

No reuse licence has yet been assigned. Contact the repository owner before reuse.
