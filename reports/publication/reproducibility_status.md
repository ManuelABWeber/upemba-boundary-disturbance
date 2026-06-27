# Reproducibility Status

Status: partially reproducible from this private publication repository.

The repository contains the active scripts, sanitized configuration, authoritative tabular outputs, final manuscript and supplement files, figures, source data, and repository-audit reports. Reproduction of all outputs requires restricted local inputs that are not redistributed in Git.

The documented publication workflow is:

1. `Rscript --vanilla scripts/publication/06_generate_main_figures_tables.R`
2. `Rscript --vanilla scripts/publication/08_generate_figure2_chronology_time_series.R`
3. `Rscript --vanilla scripts/publication/07_generate_supplementary_material.R`

Script 06 prepares the canonical Figure 2 source data; script 08 is the only final Figure 2 renderer; script 07 regenerates supplementary tables, figures, HTML, and data delivery files without replacing the verified final supplementary DOCX.

Final runtime, frozen-result, clean-clone, and document-render validation results are recorded in `reports/repository/final_repository_validation.md`.
