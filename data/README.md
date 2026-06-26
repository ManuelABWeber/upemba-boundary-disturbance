# Data

This directory contains sanitized tabular inputs and manifests. Raw rasters, proprietary products, restricted operational evidence, and large intermediate geospatial products are excluded from Git.

Expected restricted local inputs are listed in `data/manifests/required_external_inputs.csv`. Configure their location with `UPEMBA_DATA_ROOT` or `config/paths.local.R`. Authorized researchers should obtain restricted inputs from the project owner; they are not redistributed in this repository.

Do not commit local raw, external, derived, fire, private, restricted, or confidential data directories.
