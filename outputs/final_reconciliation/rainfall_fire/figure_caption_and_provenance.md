# Figure S3. Seasonal rainfall and mapped burning in 2021
Monthly rainfall and mapped burned area in the Depression and Plateau portions of the primary 10 km corridor on both sides of Upemba National Park's legal boundary (retained landscape groups 1 and 3). Panel A shows the area-weighted mean of CHIRPS v2.0 final monthly accumulated precipitation (mm); rainfall values are not summed across pixels. Panel B shows the area of native FireCCI51 pixels with a positive monthly detection date, weighted by their exact intersection with the same corridor (km²). WGS84 pixel areas and polygon-intersection fractions provide spatial weights. The area denominator for supplementary burned fractions is the entire group-specific corridor footprint. JD=-1 or invalid observations are missing; JD=-2 is non-burnable and is reported separately. Valid burnable pixels require JD=0 or a date in that month and confidence in 1–100; no additional confidence cutoff is imposed. A pixel contributes at most once per monthly composite; burns detected in different months can contribute repeatedly. Multiple burns within one monthly composite cannot be recovered. Detection dates may lag actual burning. All twelve months are unfiltered by seasonal DOY. The year was selected using monthly coverage among the two years with reusable official monthly inputs (2021–2022). Neither met the initial 95% every-group-month target; 2021 had higher minimum coverage (93.99% versus 71.92%) and is retained with explicit missing-area bounds. Rainfall coverage was complete; fire coverage exceeded 99.5% in every Depression month and 99.6% in Plateau months other than January (93.99%). Grey vertical ranges extend from mapped burned area to mapped burned plus missing area, bounding classification of unobserved pixels; they are not confidence intervals. Zero mapped area means no detected burning in observed pixels, not demonstrated absence in missing pixels. This single year illustrates seasonal co-occurrence, not causation, a long-term association or representative climatology. See rainfall_fire_monthly_2021.csv for monthly areas and coverage.

Products: FireCCI51 (MODIS C6; monthly pixel JD and CL, Area 5); CHIRPS v2.0 final global monthly 0.05-degree precipitation. Calendar interval: 1 January–31 December 2021. Domain derives from the canonical 500 m SESU and signed-distance rasters, EPSG:32735; polygon intersections use EPSG:4326 with geodesic pixel areas.

Sources: https://data.ceda.ac.uk/neodc/esacci/fire/data/burned_area/MODIS/pixel/v5.1/ ; https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_monthly/tifs/ ; https://www.chc.ucsb.edu/data/chirps ; FireCCI Product User Guide MODIS v1.1, 9 December 2021, sections 2.1 and 2.4.

Reproduce: python scripts/acquisition/02_acquire_rainfall_fire_2021.py; Rscript --vanilla scripts/publication/10_rainfall_fire_appendix.R. Raw downloads remain under <UPEMBA_DATA_ROOT>/data/rainfall_fire_2021; April–October FireCCI inputs are reused from data/fire. Acquisition and processing manifests record versions and SHA-256 hashes.

R version 4.5.3 (2026-03-11 ucrt)
Platform: x86_64-w64-mingw32/x64
Running under: Windows 11 x64 (build 26200)

Matrix products: default
  LAPACK version 3.12.1

locale:
[1] C
system code page: 65001

time zone: Europe/Amsterdam
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base

other attached packages:
[1] ggplot2_4.0.2     data.table_1.18.4 terra_1.9-11

loaded via a namespace (and not attached):
 [1] vctrs_0.7.2        cli_3.6.5          rlang_1.1.7        generics_0.1.4
 [5] textshaping_1.0.5  S7_0.2.1           glue_1.8.0         labeling_0.4.3
 [9] ragg_1.5.2         scales_1.4.0       grid_4.5.3         tibble_3.3.1
[13] lifecycle_1.0.5    compiler_4.5.3     dplyr_1.2.0        codetools_0.2-20
[17] RColorBrewer_1.1-3 Rcpp_1.1.1         pkgconfig_2.0.3    systemfonts_1.3.2
[21] farver_2.1.2       digest_0.6.39      R6_2.6.1           tidyselect_1.2.1
[25] pillar_1.11.1      magrittr_2.0.4     tools_4.5.3        withr_3.0.2
[29] gtable_0.3.6
