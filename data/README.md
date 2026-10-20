# Analysis inputs

This directory contains coded chronology, input manifests and compact derived environmental data for the supplementary dependence checks. data/dependence_sensitivity/ includes the public cell histories and geographic-block counts needed to reproduce those additional statistical analyses. Its README defines every field and records source-raster hashes.

data/governance_profiles/upemba_sesu_year_profiles.csv is the canonical wide-form chronology. The long-form chronology in data/dependence_sensitivity/ supplies year/landscape labels for the supplemental computations. evidence/ contains coded source metadata without original historical documents or operational records.

Full upstream reconstruction requires the external raster/spatial inputs listed in data/manifests/. Configure them with UPEMBA_DATA_ROOT or ignored config/paths.local.R. Satellite products must be obtained from their providers under their own terms. Original raw imagery, restricted historical or operational documents, software libraries, credentials and local configuration are excluded. Do not commit raw/external downloads or paper documents.
