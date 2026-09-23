# Code release validation — 23 September 2026

This release starts from public final-reconciliation commit 600a149eec6886aa1fec7ff47e716bc5869e27c5. Added files are code, documentation, licences and citation metadata. The current unpublished manuscript, supplement, figure files, title page and cover letter are excluded. The local commits containing those files are not ancestors of the public release branch.

The following checks passed: tests/scripts/compare_frozen_results.R (23 scalar targets, 18 classifications and three primary totals); tests/test_agriculture_followup.R (calendar follow-up, later crossing, baseline/missing observations and reversal logic); and tests/scripts/check_final_reconciliation.R (corrected counts, primary-cell/surface agreement, retained model rank, reversal denominators, bootstrap rows and rainfall coverage).

The combined contrast renderer reads the existing public CSVs and retains 99 points, with 78 interpreted intervals. Its checks compare 45 rounded legal-estimate/interval and outer-range values, and verify axes/text bounds. Output is local and ignored by Git. No model was fitted by this renderer.

Validation used Windows, R 4.6.1 and data.table 1.18.6.1, Python 3.13.13, matplotlib 3.10.8 and Pillow 12.2.0, with installed Times New Roman. These checks do not replace the original R 4.5.3 analytical environment in renv.lock. Full raw-data acquisition, clustering and model reproduction were not rerun; external inputs remain necessary.

No retained numerical expectation, interval definition or model-validity threshold was relaxed. Previously public historical outputs remain unchanged. AI assistance supported the code/documentation update; the plot uses retained numerical data rather than synthetic observational imagery.
