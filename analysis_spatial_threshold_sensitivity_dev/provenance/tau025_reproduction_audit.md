# Tau025 Reproduction Audit

Generated: 2026-06-23 23:33:31 CEST

## Resolution

The final Phase 3 tau025 reference analysis uses the exact canonical embedded layers in `run_2026_05_27/SESU_covariates_500m.tif`: `fireDOY_2001` through `fireDOY_2022`, `year_deforest_masked`, and `year_agri`.

The threshold-specific tau025 products remain inventoried and audited, but are treated as revised tau025 products rather than the canonical reference when they differ from the embedded run stack.

## Canonical Versus Threshold-Product Summary

           outcome differing_cells n_cells_compared percent_differing_cells
            <char>           <int>            <int>                   <num>
1:            fire           28196          4497042               0.6269899
2: tree_cover_loss             881           204411               0.4309944
3:     agriculture               0           204411               0.0000000
   canonical_events phase3_threshold_events event_count_difference
              <int>                   <int>                  <int>
1:          2468094                 2496290                  28196
2:             6268                    5533                   -735
3:             2685                    2685                      0

## Files

            outcome year_start year_end
             <char>      <int>    <int>
 1:            fire       2001     2001
 2:            fire       2002     2002
 3:            fire       2003     2003
 4:            fire       2004     2004
 5:            fire       2005     2005
 6:            fire       2006     2006
 7:            fire       2007     2007
 8:            fire       2008     2008
 9:            fire       2009     2009
10:            fire       2010     2010
11:            fire       2011     2011
12:            fire       2012     2012
13:            fire       2013     2013
14:            fire       2014     2014
15:            fire       2015     2015
16:            fire       2016     2016
17:            fire       2017     2017
18:            fire       2018     2018
19:            fire       2019     2019
20:            fire       2020     2020
21:            fire       2021     2021
22:            fire       2022     2022
23: tree_cover_loss       2001     2022
24:     agriculture       2001     2022
            outcome year_start year_end
             <char>      <int>    <int>
                                                 canonical_file_path
                                                              <char>
 1: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 2: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 3: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 4: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 5: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 6: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 7: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 8: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
 9: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
10: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
11: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
12: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
13: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
14: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
15: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
16: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
17: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
18: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
19: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
20: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
21: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
22: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
23: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
24: C:/0_Documents/Chapter_1/run_2026_05_27/SESU_covariates_500m.tif
                                                 canonical_file_path
                                                              <char>
        canonical_object
                  <char>
 1:         fireDOY_2001
 2:         fireDOY_2002
 3:         fireDOY_2003
 4:         fireDOY_2004
 5:         fireDOY_2005
 6:         fireDOY_2006
 7:         fireDOY_2007
 8:         fireDOY_2008
 9:         fireDOY_2009
10:         fireDOY_2010
11:         fireDOY_2011
12:         fireDOY_2012
13:         fireDOY_2013
14:         fireDOY_2014
15:         fireDOY_2015
16:         fireDOY_2016
17:         fireDOY_2017
18:         fireDOY_2018
19:         fireDOY_2019
20:         fireDOY_2020
21:         fireDOY_2021
22:         fireDOY_2022
23: year_deforest_masked
24:            year_agri
        canonical_object
                  <char>
                                                                                      phase3_threshold_file_path
                                                                                                          <char>
 1: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 2: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 3: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 4: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 5: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 6: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 7: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 8: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
 9: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
10: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
11: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
12: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
13: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
14: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
15: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
16: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
17: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
18: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
19: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
20: C:/0_Documents/Chapter_1/data/tau_var/FireCCI51_season_DOYmin_tau025_and_binary_2001_2020_500m_epsg32735.tif
21:                   C:/0_Documents/Chapter_1/data/fire_precomputed_500m/fireBurned_AprOct_2021_500m_tau025.tif
22:                   C:/0_Documents/Chapter_1/data/fire_precomputed_500m/fireBurned_AprOct_2022_500m_tau025.tif
23:                   C:/0_Documents/Chapter_1/data/tau_var/gfc_year_deforest_majority_tau025_500m_epsg32735.tif
24:                      C:/0_Documents/Chapter_1/data/agri_precomputed_500m/year_agri_500m_tau025_2001_2022.tif
                                                                                      phase3_threshold_file_path
                                                                                                          <char>
       phase3_threshold_object
                        <char>
 1:      2001_fire_season_2001
 2:      2002_fire_season_2002
 3:      2003_fire_season_2003
 4:      2004_fire_season_2004
 5:      2005_fire_season_2005
 6:      2006_fire_season_2006
 7:      2007_fire_season_2007
 8:      2008_fire_season_2008
 9:      2009_fire_season_2009
10:      2010_fire_season_2010
11:      2011_fire_season_2011
12:      2012_fire_season_2012
13:      2013_fire_season_2013
14:      2014_fire_season_2014
15:      2015_fire_season_2015
16:      2016_fire_season_2016
17:      2017_fire_season_2017
18:      2018_fire_season_2018
19:      2019_fire_season_2019
20:      2020_fire_season_2020
21:         fireDOY_max_native
22:         fireDOY_max_native
23: year_deforest_majority_tau
24:                  year_agri
       phase3_threshold_object
                        <char>

See `tau025_input_comparison.csv`, `tau025_cell_value_discrepancies_summary.csv`, and `tau025_allcell_reproduction_check.csv` for machine-readable details.
