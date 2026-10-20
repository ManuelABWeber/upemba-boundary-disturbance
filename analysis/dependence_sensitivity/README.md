# Supplementary spatial and temporal dependence checks

This module reproduces the additional fire and tree-cover-loss sensitivity analyses completed on 20 October 2026. It retains the primary model definitions, chronology, event definitions and point estimates. The forest-only tree-loss denominator is a separately labelled sensitivity. These analyses assess uncertainty; they do not identify a causal effect of protection or rank the conservation performance of the governance regimes.

The code, compact environmental histories, eight geographic-block count arrays and all accepted bootstrap draws are committed. A fresh clone contains the inputs needed for these additional statistical checks. Reconstructing the original satellite processing still requires external rasters; their checksums and the optional extraction path are documented in ../../data/dependence_sensitivity/README.md. The manuscript, supplementary Word document, submission forms and historical source documents are held separately.

Run commands from the repository root. Python 3.12.14, NumPy 2.5.4 and SciPy 1.18.1 were used for the new computations. R 4.6.1 used data.table 1.18.6.1, glmmTMB 1.1.15.2, sandwich 3.1-3 and clubSandwich 0.7.0. The retained sessionInfo files record transitive R dependencies. The historical top-level renv.lock remains unchanged because it describes the earlier analytical environment. Install the R packages explicitly before running the R drivers; the scripts do not install software implicitly. UPEMBA_R_LIBRARY can select an existing R library.

```sh
python -m pip install -r analysis/dependence_sensitivity/requirements.txt
python analysis/dependence_sensitivity/verify_release.py
```

The verification command checks the release hashes, compares every block configuration against all 1,936 retained count/denominator pairs, verifies all accepted bootstrap identities and fit diagnostics, and independently recomputes interval summaries from the committed draws. It works in a temporary folder and does not overwrite committed results. It does not refit every fire bootstrap model.

The following sequence rebuilds block histories and reruns the statistical checks. The three fire commands collectively reproduce 18,981 accepted bootstrap model fits. The tree-loss command reproduces 359,962 model calculations, including the forest-only sensitivity. Their recorded random seeds are in the drivers. On the original machine the 999-draw outer fire run took about 40 minutes; the eight main/long-range configurations took about 5 minutes each. Allow longer on slower hardware.

```sh
python analysis/dependence_sensitivity/prepare_inputs.py
python analysis/dependence_sensitivity/tree_checks.py
Rscript --vanilla analysis/dependence_sensitivity/run_fire.R main 999
Rscript --vanilla analysis/dependence_sensitivity/run_fire.R longrange 999
Rscript --vanilla analysis/dependence_sensitivity/run_fire.R outer 999
Rscript --vanilla analysis/dependence_sensitivity/fire_temporal.R
Rscript --vanilla analysis/dependence_sensitivity/small_sample_temporal.R
python analysis/dependence_sensitivity/residual_diagnostics.py
Rscript --vanilla analysis/dependence_sensitivity/validate_estimators.R
Rscript --vanilla analysis/dependence_sensitivity/validate_fire_optimizer.R
python analysis/dependence_sensitivity/summarize_results.py
python analysis/dependence_sensitivity/audit_results.py
python analysis/dependence_sensitivity/render_figures.py
```

Outputs default to the ignored outputs/_validation/dependence_sensitivity/ directory. Set UPEMBA_DEPENDENCE_OUTPUT_DIR to use another working directory. Running analysis code never promotes its outputs into the committed results. OPENBLAS_NUM_THREADS=1 avoids contention during tree-loss matrix calculations. A 50-draw pilot is available with run_fire.R pilot 50; pilot output is excluded from the published assessment and must not replace the complete runs.

To inspect or redraw retained results without refitting, first run stage_retained.py, then summarize_results.py and render_figures.py. This copies the retained data and numerical outputs into the ignored working folder. The renderer creates the spatial-interval figure corresponding to Figure S5 and a companion legal-versus-outer-boundary diagnostic. The table-to-file map and interpretation limits are in ../../docs/dependence_sensitivity/methods_and_results.md.
