# Software environments

renv.lock records the original R 4.5.3 analytical environment. The added dependence checks were executed with R 4.6.1, Python 3.12.14 and the package versions in docs/dependence_sensitivity/software_environment.json and R-package-versions.csv. outputs/dependence_sensitivity/sessionInfo_fire.txt records the common environment for the final fire resampling and validation runs; small_sample_sessionInfo.txt records the tree-loss small-sample environment.

The shared original spatial-analysis session record is docs/provenance/sessionInfo_spatial.txt. Runtime drivers may emit per-run software records into ignored working directories. The committed package consolidates identical records without changing any model result. Installation and execution commands are in RUN_ANALYSIS.md; local package libraries are not distributed.
