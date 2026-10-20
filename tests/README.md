# Submission code verification

tests/scripts/check_public_repository.py checks the tracked/exported public tree for paper documents, retired document-layout directories, exact duplicate files, release-manifest hashes and broken local Markdown links. The frozen scalar/classification references are in tests/reference/.

tests/scripts/compare_frozen_results.R checks 23 scalar targets, 18 classifications and three primary totals. tests/test_agriculture_followup.R checks calendar follow-up, later crossing, baseline and missing-data rules. tests/scripts/check_final_reconciliation.R checks corrected agricultural inputs, model rank, denominators, resampling rows and monthly coverage. tests/testthat/test-final-robustness-functions.R checks the sparse-outcome risk-set and chronology functions with synthetic histories and retained totals.

analysis/dependence_sensitivity/verify_release.py checks all committed additional sensitivity inputs, accepted draws and interval summaries. These commands use committed research data; upstream raster refitting needs the external input manifests. Run the commands in [RUN_ANALYSIS.md](../RUN_ANALYSIS.md). No document-generation tests remain in the current package.
