Supplementary Material
Separating environmental outcomes from conservation attribution under changing territorial control
Supplementary Methods
Supplementary Methods S1. Spatial design and landscape comparison groups
The Upemba landscape domain extended from 25.48 to 27.50°E and from 10.4 to 7.8°S. We excluded the Copperbelt mining districts and Kundelungu Plateau because their environmental conditions and land-use histories differed substantially from the focal landscape. All layers were projected to UTM Zone 35S (EPSG:32735), aligned to the canonical 500 m grid, assigned to park side from signed distance to the legal boundary, and masked to exclude perennial water. Before examining profile-specific estimates, we screened symmetric corridors of 5, 10, and 20 km and the full eligible domain. The 10 km corridor was a design-stage compromise between measured covariate similarity and sparse-event support: median and maximum absolute standardised mean differences were 0.187 and 0.733, compared with 0.119 and 0.371 at 5 km, while the 10 km corridor retained 519 tree-cover-loss and 518 agricultural-expansion events (Table S4). The resulting comparison is neither matched nor randomised.
Reference-period covariates are listed in Table S1. Cells lacking elevation or slope were excluded. Missing accessibility, distance-to-settlement, and distance-to-water values were replaced with their observed maxima; missing values in other covariates were replaced with their medians. Accessibility and distance variables were transformed using log(1+x), and all clustering features were standardised. We evaluated k = 2–15 on a fixed 20,000-cell silhouette sample (seed 42), fitted k = 3 with 25 random starts (seed 123), and reassigned isolated labels by the eight-neighbour modal class. The selected k = 3 solution had a mean silhouette width of 0.270, only modestly above the next-highest value of 0.261 at k = 7, indicating weak separation rather than discrete landscape classes. The Depression and Plateau clusters therefore serve as coarse inferential comparison groups. Their labels were assigned after clustering from dominant geography and do not define complete socio-ecological systems. A no-accessibility sensitivity reproduced 96.8% of primary-corridor assignments (Tables S2–S3).
Supplementary Methods S2. Territorial-control reconstruction
We reconstructed annual territorial-control profiles separately for the Depression and Plateau before inspecting any remotely sensed outcome. The evidence base comprised dated archival records, park and NGO documentation, technical assessments, humanitarian reporting, media coverage, and historical synthesis. This evidence is uneven and institutionally situated. We prioritised sources assignable to a landscape group, year, or transition; when sources conflicted, contemporaneous records with direct spatial or institutional relevance received greater weight, and the disagreement remained visible in the chronology. The coding focused on Upemba National Park institutions and armed groups described as Mai-Mai; the latter label aggregates formations that differed across episodes. State forces, customary authorities, local administrations, communities, and conservation partners informed interpretation without becoming separate statistical categories.
Fragmented control denotes periods in which neither park institutions nor militia exercised consolidated practical authority. Militia-centred control denotes periods in which armed-group presence materially structured access while park enforcement had collapsed or remained severely constrained. Park-centred control denotes expanded park operational reach despite persistent insecurity and incomplete coverage. Episodes carrying the same profile label were not assumed to involve identical actors, mechanisms, intensity, or spatial reach. These profiles describe broad configurations of practical territorial control, not governance quality, conservation intent, legitimacy, exclusive sovereignty, or causal treatments. Table S6 records episode-level interpretation, evidence, transition rationale, and sources; Table S7 summarises temporal support.
Supplementary Methods S3. Disturbance processing and risk sets
Fire used ESA FireCCI v5.1 for 2001–2020 and official monthly continental files for 2021–2022. We retained burns detected during day of year 100–300, converted qualifying source pixels to seasonal binary status, and area-averaged them to the 500 m grid. A 500 m cell was burned when at least 25% of its area was detected; 10% and 50% thresholds were sensitivities. The seasonal restriction does not distinguish anthropogenic from natural ignition or identify purpose. Fire remained recurrent, so all eligible cells re-entered every annual risk set. The 2021–2022 audit reproduced the authoritative classifications and found no completely unobserved seasonal source pixels capable of altering the primary classification.
Tree-cover loss used Hansen Global Forest Change v1.12. Eligibility required at least 30% mean tree cover in 2000, and the event year was the first year cumulative mapped loss reached the cell threshold. Agricultural expansion used the Annual Cropland Extent Dataset for Africa and the first annual transition from below to at least the cell threshold. Cells left the tree-cover-loss and agricultural-expansion risk sets after their first event. These operational first-event definitions prevent repeated counting but do not measure annual loss rates, subsequent regrowth, reclearing, crop abandonment, or shifting cultivation. At the 50% tree-cover-loss threshold, only 79 events remained and profile estimates attenuated towards zero. The analysis therefore concerns initial threshold crossings, not state persistence or all canopy change.
Supplementary Methods S4. Statistical estimation and diagnostics
Fire used an aggregated beta-binomial regression with landscape-group × year fixed effects and pooled profile-specific inside–outside contrasts. Strict-valid fits required convergence code 0, finite estimates, full rank, a positive-definite Hessian, and maximum framework and independently calculated gradients below 0.001. The beta-binomial accommodates extra-binomial count variation but does not explicitly model spatial or serial autocorrelation. Sparse tree-cover-loss and agricultural-expansion outcomes used annual Haldane–Anscombe-corrected inside–outside log-odds differences, inverse-variance weighting, landscape-group fixed effects, and HC3 covariance. The 0.5 correction prevented infinite log odds in zero-event strata; unweighted models assessed dependence on the weighting scheme.
For landscape group s and year t, the sparse-outcome contrast was D_st = log[(y_in + 0.5)/(n_in − y_in + 0.5)] − log[(y_out + 0.5)/(n_out − y_out + 0.5)]. Its approximate variance was V_st = 1/(y_in + 0.5) + 1/(n_in − y_in + 0.5) + 1/(y_out + 0.5) + 1/(n_out − y_out + 0.5). Group-years without cells at risk on both sides were omitted. We fitted D_st as a function of territorial-control profile and landscape group using weight 1/V_st. The first-stage variance and weights use a working cell-independence approximation; HC3 addresses leverage and heteroskedasticity among annual contrasts but not spatial dependence, serial dependence within episodes, or dependence between groups in the same year. Confidence intervals are therefore conditional model-based summaries.
Table S12 retains earlier exploratory chronology diagnostics, whose sparse-outcome domain and implementation differed from the primary model. Recovered matched primary-corridor lag and transition-exclusion analyses are now reported in Supplementary Methods S5 and Table S21. Neither estimates a causal response delay.
The boundary-location diagnostic compared the legal boundary with ten outward pseudo-boundaries centred from +15 to +60 km in 5 km increments. At each location, the park-facing side was compared with the side facing away, within the corresponding landscape group and historical period. The dense outer 80% envelope is the interval between the 10th and 90th percentiles of the ten outer point estimates, calculated separately for each outcome and profile using R type-7 quantiles. The envelope is descriptive: the one-sided, deterministic, spatially overlapping offsets are not independent observations, confidence intervals, randomised null distributions, or causal counterfactuals, and they do not establish uniqueness in all directions. Finite outer fire fits that failed strict numerical-validity criteria contributed point estimates only; their intervals are not interpreted. The +15 km park-facing band is +5–15 km and overlaps the primary outside band over +5–10 km.
Supplementary Methods S5. Temporal alignment and dependence
The recovered lag-0, lag-1, lag-2 and transition-exclusion runs retain the primary 10 km corridor and outcome-specific specification. Lagging profile labels changes which outcome years can be linked to history; eligible years, cell-years and event support are recorded in Table S21 and temporal_lag_support.csv. These are checks of temporal alignment, not estimates of delayed causal effects. Existing episode-omission and landscape-specific analyses assess influence rather than remove dependence. No spatial or temporal independence test was located in the retained workflow. We retained conditional primary intervals and added a bounded spatial bootstrap for agriculture. It preserves whole cell histories and dependence within fixed 5 km tiles, conditional on the observed chronology. Dependence across tiles and shared historical uncertainty remain limitations.
Supplementary Methods S6. Seasonal rainfall and fire
Figure S3 uses CHIRPS v2.0 final monthly precipitation and FireCCI51 monthly JD and confidence rasters over the identical primary corridor and retained landscape groups. Native WGS84 pixel areas multiplied by exact polygon-intersection fractions provide spatial weights. Rainfall is the spatially weighted mean of monthly accumulated mm. Fire is mapped monthly burned area; a native pixel contributes at most once per month and can contribute again for a distinct later-month detection. JD=-1 and invalid observations are missing; JD=-2 is non-burnable. Valid observations require JD=0 or a date in that month and confidence 1–100, without an additional confidence cutoff. Monthly dates are unfiltered by DOY 100–300.
We evaluated the two years with reusable official monthly inputs, 2021 and 2022, by observation coverage. Neither met the initial 95% target in every group-month: their minimum coverage was 93.99% and 71.92%, respectively. We retained the better-covered 2021 and display mapped burned to mapped-plus-missing area bounds, rather than recode missing pixels as unburned. CHIRPS coverage was complete. These ranges are missing-data bounds, not confidence intervals. This one-year comparison illustrates seasonal co-occurrence; it cannot establish an optimal seasonal window, causation or representative climatology. Codex (OpenAI) assisted with the reproducible data-processing and plotting code; no synthetic observational imagery was generated.
Supplementary Methods S7. Agricultural persistence, reversal, annual presence and Hansen overlap
We reconstructed 2000–2022 annual AFCD fractions on the canonical 500 m grid and reproduced all 2,685 full-domain first-crossing dates exactly. All 42,554 corridor cells and all 204,411 retained full-domain cells had finite annual fractions. Finite 2000 observations establish baseline eligibility. The original analysis retained cells already agricultural in 2000 (378 corridor cells). A qualifying event is consequently the first detected below-to-at-least-25% crossing within this window, potentially after an earlier baseline agricultural state, not first-ever cultivation. Baseline agricultural cells remain included in every comparison.
For persistence, the crossing year must reach 25%, and at least two of years +1, +2 and +3 must also reach 25%, including +1 or +2. All three following observations must be finite. Candidate event years are 2001–2019, with follow-up through 2022. We inspect every below-to-above crossing and select the first satisfying this rule. Seven corridor events qualify at a later crossing than the original first crossing. Cells enter in 2001, remain at risk through the qualifying event year and exit the following year; no qualifying event means remaining at risk through 2019. Invalid baseline observations exclude a cell. Missing required annual history or follow-up censors it before the first unassessable year; neither is counted as absence or persistence. No such exclusions occurred in these data. Earlier transient crossings do not remove cells from the persistent-establishment risk set.
We fitted original first crossing over 2001–2022, original first crossing over 2001–2019, and corrected persistent establishment over 2001–2019, preserving the corridor, groups, inverse-variance-weighted paired log-odds model, 0.5 correction and HC3 intervals (Tables S18 and S20). The shortened models have 38 landscape-years instead of 44; all are full-rank linear fits. Corrected persistence retained 414 corridor events and 1,994 full-domain events. The historical 431-event fit allowed 2020 events only two follow-ups and retained 2021–2022 as zero-event risk years. Its park-centred estimate −0.237 [−0.642, 0.168] is superseded. The corrected value is −0.235 [−0.753, 0.284]. Counts by side, group, profile and year, every coefficient, saved models and covariance matrices accompany the analysis.
Descriptive reversal concerns the original crossing, independently of persistent establishment. Both +1 and +2 must be valid; reversal means both are below 25%. Events after 2020 are insufficient-follow-up cases, and earlier missing values form a separate category. Full-domain reversal numerators remain 10 inside and 193 outside, but valid-follow-up denominators are 237 and 2,092, not all-event denominators 255 and 2,430. Corridor counts are 10/236 inside and 13/227 outside, with 18 and 37 insufficient-follow-up cases and no missing-data cases (Table S19A). The handover’s 252/266 split was an arithmetic error: its class counts actually sum to 254/264. Exact cell-level and group-year comparisons reproduce the primary input. No primary-model correction was required. Threshold decline is not evidence of ecological recovery.
Annual agricultural presence is the repeated binary response that a cell’s annual fraction is at least 25%. We retained all finite annual classifications during 2001–2022, including baseline agricultural cells and observations after establishment; changes in either direction were allowed. We used the same paired landscape-year log-odds regression with profile and landscape-group effects. HC3 intervals are reported for comparison, but uncertainty for this supplementary response uses 499 resamples of entire cell trajectories within fixed 5 km UTM tiles (seed 20260910), stratified by landscape group: 263 Depression and 355 Plateau blocks. A block crossing the boundary retains both sides. Percentile intervals preserve serial dependence within cells and spatial dependence within tiles, conditional on the observed groups and chronology. Dependence beyond 5 km and historical uncertainty are not resolved. Plateau agricultural support is very sparse, so the 0.5 correction and equal-group standardisation matter. Annual presence measures prevalence; first expansion measures entry into the mapped class. Neither is net agricultural change.
Hansen v1.12 static 2000–2012 gain was compared with native loss-year codes 1–12. Among 2,801 retained full-domain cells whose cumulative loss crossed 25% by 2012, 754 contained any gain and 599 contained at least one native pixel with both loss and gain. Corridor counts were 364 crossings, 58 with any gain, and 46 with native overlap (Table S19B). These differ from the 2001–2022 loss-event totals of 5,460 full-domain and 519 corridor cells. Gain elsewhere within a 500 m cell is not native-pixel overlap. Neither metric establishes gain after a dated loss event, because gain has no event year. These diagnostics do not demonstrate post-loss recovery.
Supplementary Tables
Table S1. Landscape comparison covariates. All variables were standardized before clustering unless otherwise indicated.

Table S2. Clustering solution selection. Mean silhouette width was calculated from the same 20,000-cell sample (seed 42) for every candidate k. The selected k = 3 value (0.270) only modestly exceeded alternatives, so the groups are interpreted as coarse comparison strata rather than discrete landscape classes.

Table S3. Clustering stability and accessibility sensitivity.

Table S4. Measured spatial-design balance and event support for the primary 25% definition. Cell counts are shown as inside / outside. Fire values are burned cell-years, not discrete fire perimeters. The 10 km design retained residual imbalance and was selected as a balance–support compromise, not as a matched design.

Table S5. Landscape-group and park-side support. Counts are inside / outside. The primary totals equal the sum of the Depression and Plateau rows; the Lufira Plain cluster is shown separately and was excluded from the primary inferential scope.

Table S6. Historical episode evidence supporting the frozen chronology. Each row records the operational interpretation, documented evidence, transition rationale, and sources. Episodes sharing a profile label are not assumed homogeneous. The profiles describe broad practical authority rather than governance quality, conservation intent, legitimacy, or exclusive sovereignty.

Table S7. Profile and episode support.

Table S8. Primary pooled profile-specific inside–outside log-odds contrasts. All estimates use the 25% event definition within the symmetric 10 km corridor and summarise landscape-group years assigned to each broad profile.

Table S9. Primary pairwise differences between pooled profile-specific contrasts. All estimates use the 25% event definition within the symmetric 10 km corridor. The intervals are conditional model-based summaries rather than uncertainty from independent historical replications.

Table S10. Weighted primary and unweighted sparse-outcome estimates. Cells contain estimate [95% CI].
Panel A. Profile-specific contrasts.

Panel B. Pairwise differences.

Table S11. Measurement-threshold and spatial-domain sensitivity of pooled profile-specific contrasts and pairwise profile differences. Cells contain estimate [95% CI] where available. The 25% / 10 km specification is primary. At the 50% tree-cover-loss threshold, only 79 events remained and all three profile estimates attenuated towards zero.
Panel A. Measurement-threshold sensitivity within the 10 km corridor.

Panel B. Spatial-domain sensitivity at the 25% threshold.

Table S12. Exploratory transition-year and episode-omission diagnostics; these are not matched reruns of the primary 10 km models. Sparse-outcome diagnostics used the complete eligible domain and an earlier implementation. The reference estimate comes from that exploratory implementation; the minimum and maximum summarise alternative chronology scenarios and need not contain the reference value. Only sign retention is interpreted.

Table S13. Final refined fire-model optimizer diagnostics for the 10 km corridor. The 25% BFGS-refined fit is the selected primary fire model.

Table S14. Pooled profile-specific outward boundary-location results. Panel A summarises descriptive spatial interpretations; Panels B–D report the legal boundary and the three spaced outer locations. The dense outer envelope uses all ten outward offsets from +15 to +60 km. “Legal-boundary-aligned” means more extreme than the evaluated outward sequence; it does not imply uniqueness in all directions or a causal legal-protection effect.
Panel A. Outward boundary-location comparison summary. The dense outer 80% envelope is the interval between the 10th and 90th percentiles of the ten outward point estimates and is descriptive rather than a confidence interval or randomised null distribution.

Panel B. Tree-cover-loss estimates.

Panel C. Fire estimates.

Panel D. Agricultural-expansion estimates.

Table S15. Reproducibility environment and authoritative inputs. Paths are repository-relative and become externally usable when the analytical repository is archived; they are not public links in the present document.

Table S16. Remote-sensing products and annual disturbance-event definitions, 2001–2022. The 25% threshold was primary; 10% and 50% thresholds were measurement sensitivities.
Table S17. Synthesis of primary results for the 25% event definition within the symmetric 10 km boundary corridor. Full numerical estimates are reported in Tables S8–S9.
Table S18. Agricultural inside-minus-outside log odds. HC3 intervals retain the established comparison; the final column reports 499 whole-trajectory 5 km spatial-bootstrap percentile intervals. Annual presence is prevalence, a different response from first establishment.
Table S19A. Reversal after the original crossing. Denominators require both follow-ups. No missing-data cases occurred.
Table S19B. Static gain among loss-threshold crossings through 2012. Neither gain measure establishes post-loss recovery.
Table S20. Response support by profile and side. Annual-presence numerators count agricultural cell-years; first-event numerators count events. Denominators are at-risk or observed cell-years. Group-by-year counts and all coefficients accompany the analysis.
Table S21. Matched primary-corridor temporal-alignment checks. Intervals retain conditional model covariance. Lags change eligible years; transition exclusions remove specified years. These are not causal-delay estimates. Detailed support and diagnostics accompany the CSV outputs.
Supplementary Figures

Figure S1. Threshold and spatial-domain sensitivities. Points show pooled profile-specific inside–outside log-odds contrasts. The primary 25% / 10 km estimates are emphasised; muted or open fire symbols denote non-strict fits for which interval-based inference is not used. These checks assess specification sensitivity but do not resolve spatial or serial dependence.

Figure S2. Annual disturbance trajectories inside and outside Upemba National Park, 2001–2022. Panels show the percentage of eligible 500 m cells affected by recurrent fire, first crossing of the cumulative tree-cover-loss threshold, and first agricultural expansion in the Depression and Plateau comparison groups. Dashed lines denote cells inside and solid lines cells outside the symmetric 10 km corridor. Shading shows the direction of the annual contrast; vertical lines and the lower strip show the independently reconstructed territorial-control chronology. Trajectories are descriptive; formal inference uses the outcome-specific models.

Figure S3. Seasonal rainfall and mapped burning in 2021. Monthly rainfall and mapped burned area in the Depression and Plateau portions of the primary 10 km corridor on both sides of Upemba National Park's legal boundary (retained landscape groups 1 and 3). Panel A shows the area-weighted mean of CHIRPS v2.0 final monthly accumulated precipitation (mm); rainfall values are not summed across pixels. Panel B shows the area of native FireCCI51 pixels with a positive monthly detection date, weighted by their exact intersection with the same corridor (km²). WGS84 pixel areas and polygon-intersection fractions provide spatial weights. The area denominator for supplementary burned fractions is the entire group-specific corridor footprint. JD=-1 or invalid observations are missing; JD=-2 is non-burnable and is reported separately. Valid burnable pixels require JD=0 or a date in that month and confidence in 1–100; no additional confidence cutoff is imposed. A pixel contributes at most once per monthly composite; burns detected in different months can contribute repeatedly. Multiple burns within one monthly composite cannot be recovered. Detection dates may lag actual burning. All twelve months are unfiltered by seasonal DOY. The year was selected using monthly coverage among the two years with reusable official monthly inputs (2021–2022). Neither met the initial 95% every-group-month target; 2021 had higher minimum coverage (93.99% versus 71.92%) and is retained with explicit missing-area bounds. Rainfall coverage was complete; fire coverage exceeded 99.5% in every Depression month and 99.6% in Plateau months other than January (93.99%). Grey vertical ranges extend from mapped burned area to mapped burned plus missing area, bounding classification of unobserved pixels; they are not confidence intervals. Zero mapped area means no detected burning in observed pixels, not demonstrated absence in missing pixels. This single year illustrates seasonal co-occurrence, not causation, a long-term association or representative climatology. See rainfall_fire_monthly_2021.csv for monthly areas and coverage. Codex assisted the reproducible plotting code; the plotted values derive from the stated satellite products.
Data and code availability. Satellite products and acquisition links are public. The analytical repository is currently private; authors must confirm anonymised reviewer access and a persistent deposit before submission. Restricted historical evidence is not included in the public-data deliverables. Compact numerical outputs and acquisition/processing manifests accompany this review.
Supplementary References
Aerden, L. (2012). Rapport d’information n°26/2012. Organisation Kanyundu pour le Développement Intégral (OKA).
Brugière, D., 2020. Public-private partnership for protected areas: current situation and prospects in French-speaking Africa. IUCN-papaco.
Chief Kayumba. (2010). Letter recognising the 1975 boundaries of Upemba National Park. Unpublished correspondence.
Cunningham, H.K. (2024). The rangers turning the DRC’s ‘triangle of death’ back into a thriving wildlife reserve. The Guardian. URL https://www.theguardian.com/environment/article/2024/aug/20/drc-wildlife-reserve-upemba (accessed 2.6.26).
d’Huart, J.-P. (2017). Plan d’aménagement et de gestion (PAG). Internal report.
FZS. (2009). Projet 10e FED - Narrative Report. Internal project document, Frankfurt Zoological Society, Kinshasa.
Hance, J. (2012a). Gang raids remote National Park in the Democratic Republic of the Congo. Mongabay. URL https://news.mongabay.com/2012/07/gang-raids-remote-national-park-in-the-democratic-republic-of-the-congo/ (accessed 1.19.26).
Hance, J. (2012b). Conflict and perseverance: rehabilitating a forgotten park in the Congo. Mongabay. URL https://news.mongabay.com/2012/09/conflict-and-perseverance-rehabilitating-a-forgotten-park-in-the-congo/ (accessed 1.19.26).
Hasson, M. (2003). Upemba, le parc oublié. Brussels: Nouvelles Approches.
Hasson, M. (2015). Katanga. Des animaux et des hommes. Vol. 1: Les animaux et la société. Tervuren: Musée royal de l’Afrique centrale (MRAC).
Hecht, D. (2006). The peculiar terror that is northern Katanga. IRIN News, 13 February 2006. Archived at The New Humanitarian. Available at: https://www.thenewhumanitarian.org/report/58122/drc-peculiar-terror-northern-katanga (accessed 1.19.26).
Huisman, R. (2017). “Ik ben al drie keer op de loop moeten gaan” [WWW Document]. HBVL. URL https://www.hbvl.be/regio/limburg/ik-ben-al-drie-keer-op-de-loop-moeten-gaan/31994038.html (accessed 1.19.26).
Human Rights Watch. (2006). RD Congo: Les élections approchent, l’impunité perdure au Katanga. URL https://www.hrw.org/fr/news/2006/07/21/rd-congo-les-elections-approchent-limpunite-perdure-au-katanga (accessed 8.10.25).
IPIS. (2007). Mapping interests in conflict areas: Katanga (August 2007). IPIS. URL https://ipisresearch.be/publication/mapping-interests-conflict-areas-katanga/ (accessed 1.19.26).
IUCN NL. (2021). Exemplary conviction for the slaughter of elephants in the National Park of Upemba (DRC) [WWW Document]. URL https://www.iucn.nl/en/news/exemplary-conviction-for-the-slaughter-of-elephants-in-the-national-park-of-upemba-drc/ (accessed 7.19.26).
Katanga Protection Cluster. (2015). Violence, displacement and humanitarian action in Katanga: A report on the protection of civilians in the south-eastern DR Congo province of Katanga. Produced with the support of OCHA, May 2015. https://www.ecoi.net/en/file/local/1095206/1930_1401096604_kantaga-report-2014-final-english-22052014-001.pdf
Katembo, R. (2016). Rapport technique sur l’opération de gardiennage et protection des derniers éléphants du Katanga. Lusinga/Upemba National Park: ICCN.
Katembo, R. (2017). Rapport technique sur l’opération de gardiennage et protection des derniers éléphants du Katanga. Lusinga/Upemba National Park: ICCN.
Livingstone, E. (2024). A rainforest in Africa aims to reverse damage after years of conflict and neglect. NPR. URL https://www.npr.org/2024/11/12/nx-s1-5110010-e1/a-rainforest-in-africa-aims-to-reverse-damage-after-years-of-conflict-and-neglect (accessed 1.19.26).
MONUSCO. (2013). MONUSCO welcomes the separation of 82 children from Mayi Mayi Bakata Katanga. URL https://monusco.unmissions.org/en/news/monusco-welcomes-separation-82-children-mayi-mayi-bakata-katanga-0 (accessed 1.19.26).
Mululwa, K.J. (2008). Rapport sur les éléphants: Mission effectuée par le conservateur Mululwa dans la Zone Annexe du PNU-N du 16 Juillet au 9 Septembre 2008. ICCN.
Ngoy, K.P. (2015). A critical assessment of the security sector reforms in Central Africa: The case study of the Democratic Republic of Congo, Northern Katanga Province, 2011-2014. Master’s dissertation, Africa University, Institute of Peace, Leadership and Governance.
Nouvelles Approches. (2002-2004). Le Rhino Fantôme.
OCHA. (2013). D.R. Congo’s neglected “Triangle of Death”: The challenges of the protection of civilians in Katanga. URL https://www.unocha.org/publications/report/democratic-republic-congo/dr-congo%E2%80%99s-neglected-%E2%80%9Ctriangle-death%E2%80%9D-challenges-protection (accessed 1.19.26).
OKA Kanyundu. (2018). Realisations [WWW Document]. URL https://kanyundu.jouwweb.be/realisations (accessed 1.19.26).
Radio Okapi. (2010). Katanga: les FARDC ripostent à une attaque des Maï Maï à Luena, 5 morts [WWW Document]. Publié le sam, 27/11/2010 - 16:44. URL https://www.radiookapi.net/actualite/2010/11/27/katanga-les-fardc-ripostent-a-une-attaque-des-mai-mai-a-luena-5-morts (accessed 1.20.26).
Radio Okapi. (2012a). Katanga: 12 miliciens de Mitwaba se rendent aux autorités provinciales [WWW Document]. Publié le dim, 05/08/2012 - 11:23. URL https://www.radiookapi.net/actualite/2012/08/05/katanga-12-miliciens-de-mitwaba-se-rendent-aux-autorites-provinciales (accessed 1.20.26).
Radio Okapi. (2012b). Mitwaba: des hommes armés tuent le conservateur du parc de l’Upemba [WWW Document]. Publié le mar, 18/12/2012 - 13:55. URL https://www.radiookapi.net/environnement/2012/12/18/mitwaba-des-hommes-armes-tuent-le-conservateur-du-parc-de-lupemba (accessed 1.20.26).
Radio Okapi. (2013). Parc Upemba: l’ICCN veut refouler des éléphants et rapatrier 2 gardes retenus en otage par des Maï-Maï [WWW Document]. Publié le lun, 22/04/2013 - 16:46. URL https://www.radiookapi.net/actualite/2013/04/22/parc-upemba-liccn-veut-refouler-des-elephants-rapatrier-2-gardes-retenus-en-otage-par-des-mai-mai (accessed 1.20.26).
Radio Okapi. (2014a). Parc Upemba: l’ICCN accuse des villageois de se livrer au braconnage [WWW Document]. Published 14 March 2014; updated 8 August 2015. URL https://www.radiookapi.net/environnement/2014/03/14/parc-upemba-liccn-denonce-le-braconnage-des-habitants-dun-village-disperse/ (accessed 1.20.26).
Radio Okapi. (2014b). Deux attaques des miliciens Bakata Katanga enregistrées à Mitwaba [WWW Document]. Publié le mar, 04/11/2014 - 17:45. URL https://www.radiookapi.net/regions/katanga/2014/11/04/deux-attaques-des-miliciens-bakata-katanga-enregistrees-mitwaba (accessed 1.20.26).
Radio Okapi. (2014c). Katanga: les FARDC délogent les Maï-Maï Bakata Katanga de Musumari [WWW Document]. Publié le mer, 05/11/2014 - 14:22. URL https://www.radiookapi.net/actualite/2014/11/05/katanga-les-fardc-delogent-les-mai-mai-bakata-katanga-de-musumari (accessed 1.20.26).
Radio Okapi. (2014d). Katanga: les FARDC se déploient dans le parc de l’Upemba pour traquer des miliciens [WWW Document]. Publié le mer, 12/11/2014 - 16:56. URL https://www.radiookapi.net/environnement/2014/11/12/katanga-les-fardc-se-deploient-dans-le-parc-de-lupemba-pour-traquer-des-miliciens (accessed 1.20.26).
Radio Okapi. (2021). Construction d’un barrage dans le parc Upemba: 185 ONG saisissent Félix Tshisekedi [WWW Document]. Publié le lun, 11/10/2021 - 12:41. URL https://www.radiookapi.net/2021/10/11/actualite/societe/construction-dun-barrage-dans-le-parc-upemba-185-ong-saisissent-felix (accessed 1.20.26).
Radio Okapi. (2022a). Les FARDC annoncent avoir désarmé des miliciens Bakata Katanga à Mitwaba [WWW Document]. Publié le mar, 01/02/2022 - 16:03. URL https://www.radiookapi.net/2022/02/01/actualite/securite/les-fardc-annoncent-avoir-desarme-des-miliciens-bakata-katanga-mitwaba (accessed 7.19.26).
Radio Okapi. (2022b). Des tirs à Mitwaba à la suite du refus des Bakata Katanga de se rendre à Lubumbashi [WWW Document]. Publié le mer, 02/02/2022 - 13:07. URL https://www.radiookapi.net/2022/02/02/actualite/securite/des-tirs-mitwaba-la-suite-du-refus-des-bakata-katanga-de-se-rendre (accessed 7.19.26).
Radio Okapi. (2024). RDC: le parc national d’Upemba célèbre ses 85 ans sous le signe de résilience en conservation [WWW Document]. Publié le mer, 15/05/2024 - 18:02. URL https://www.radiookapi.net/2024/05/15/actualite/societe/rdc-le-parc-national-dupemba-celebre-ses-85-ans-sous-le-signe-de (accessed 1.20.26).
Spittaels, S., & Meynen, N. (2007). Cartographie des intérêts dans les zones de conflit: le cas du Katanga. Antwerp: IPIS.
Unknown author. (2010). Lettre du chef de Kilenge à Kasenga-Mondwe. Unpublished correspondence.
Upemba National Park. (2024). The High Cost of Conservation in the DRC [WWW Document]. Upemba National Park. URL https://www.upemba.org/post/the-high-cost-of-conservation-in-the-drc (accessed 1.19.26).
Van Acker, F., & Vlassenroot, K. (2001). Les «maï-maï» et les fonctions de la violence milicienne dans l’est du Congo. Politique africaine, 84, 103-116. https://doi.org/10.3917/polaf.084.0103
Van Leeuwe, H., Henschel, P., Pélissier, C., & Moyer, D. (2009). Recensement des grands mammifères et impacts humains: Parcs Nationaux de l’Upemba et de Kundelungu, RDC. Kinshasa: ICCN/WCS/USFWS/Panthera.
Villaespesa, P. (2020). Underprivileged youth become proud park rangers. IUCN NL. URL https://www.iucn.nl/en/story/underprivileged-youth-become-proud-park-rangers/ (accessed 1.19.26).
Covariate
Source and reference period
Native resolution
500 m processing / transformation
Elevation
Copernicus DEM GLO-30 (static)
30 m
mean elevation on canonical grid; standardized
Slope
Derived from Copernicus DEM GLO-30 in R (static)
derived 30 m
terrain slope derived then aggregated to canonical grid; standardized
Baseline forest indicator
Hansen Global Forest Change v1.12 tree cover in 2000 (2000). Hansen, M. C., et al. 2013. High-resolution global maps of 21st-century forest cover change. Science 342:850-853.
30 m
binary ≥30% baseline-forest indicator on canonical grid; binary indicator
Distance to permanent water
JRC Global Surface Water v1.4 (permanent water from seasonality = 12 or occurrence ≥90%). JRC. 2021. Global Surface Water v1.4. European Commission Joint Research Centre.
30 m
distance to permanent-water mask on canonical grid; distance transformed where skewed, then standardized
Mean annual precipitation
CHIRPS daily precipitation (1981-2010 annual mean). UCSB CHG. 2023. CHIRPS daily precipitation data. Climate Hazards Center, University of California Santa Barbara.
approximately 5 km
annual means aggregated to canonical grid; standardized
Potential evapotranspiration
TerraClimate (1981-2010 annual mean). TerraClimate. 2023. Monthly climate and climatic water balance data for global terrestrial surfaces. University of Idaho.
approximately 4 km
annual means aggregated to canonical grid; standardized
Actual evapotranspiration
TerraClimate (1981-2010 annual mean)
approximately 4 km
annual means aggregated to canonical grid; standardized
Water balance
CHIRPS precipitation minus TerraClimate PET (1981-2010 annual mean)
derived
derived after climate processing on canonical grid; standardized
Aridity
P / (PET + 1), using CHIRPS precipitation and TerraClimate PET (1981-2010 annual mean)
derived
derived after climate processing on canonical grid; standardized
Soil organic carbon
SoilGrids 0-30 cm depth-weighted SOC (static). SoilGrids. 2020. SoilGrids 250 m global soil information layers. ISRIC - World Soil Information.
250 m
depth-weighted mean aggregated to canonical grid; standardized
Soil pH
SoilGrids 0-30 cm depth-weighted pH (static)
250 m
depth-weighted mean aggregated to canonical grid; standardized
Clay
SoilGrids 0-30 cm depth-weighted clay (static)
250 m
depth-weighted mean aggregated to canonical grid; standardized
Sand
SoilGrids 0-30 cm depth-weighted sand (static)
250 m
depth-weighted mean aggregated to canonical grid; standardized
Distance to baseline built-up areas
GHSL P2023A built-up surface (baseline 2000-or-earlier), GHSL. 2023. Global Human Settlement Layer P2023A built-up surface. European Commission Joint Research Centre.
100 m
distance to baseline built-up surface on canonical grid; distance transformed where skewed, then standardized
Travel time to cities
Oxford/MAP accessibility_to_cities_2015_v1_0 (2015). Weiss, D. J., et al. 2018. A global map of travel time to cities to assess inequalities in accessibility in 2015. Nature 553:333-336.
approximately 1 km
travel-time surface aggregated to canonical grid; transformed where skewed, then standardized
k
Mean silhouette width
Selected
2
0.251
No
3
0.270
Yes
4
0.228
No
5
0.234
No
6
0.241
No
7
0.261
No
8
0.251
No
9
0.238
No
10
0.223
No
11
0.241
No
12
0.232
No
13
0.229
No
14
0.219
No
15
0.218
No
Metric
Value
Authoritative near-reproduction ARI
0.99723575428417
Full label-matched agreement
99.9074%
10 km agreement
99.8820%
Differing cells
230
Differing cells (%)
0.0927%
No-accessibility selected k
3
No-accessibility k = 3 ARI
0.916026767359794
No-accessibility full agreement
0.973904643065591
No-accessibility 10 km agreement
0.967904314319442
Retained group identity
Depression and Plateau retained
Outcome-model rerun triggered
No
Seed-stability rows
25
Design
Cells (inside / outside)
Median |SMD|
Max |SMD|
Burned cell-years
Tree-cover-loss events
Agricultural-expansion events
Role
All cells
37,963 / 166,448
0.429
1.704
2,468,094
5,460
2,685
sensitivity
5 km
11,187 / 11,418
0.119
0.371
252,143
313
392
sensitivity
10 km
20,548 / 22,006
0.187
0.733
508,320
519
518
primary estimand
20 km
33,130 / 42,022
0.299
1.254
928,993
876
587
sensitivity
Landscape group
Cells
Burned cell-years
Tree-cover-loss events
Agricultural-expansion events
Included
Depression
7,612 / 10,019
75,745 / 89,396
142 / 262
254 / 261
Yes
Lufira Plain (outside inferential scope)
786 / 1,557
12,396 / 25,735
0 / 12
2 / 9
No
Plateau
12,936 / 11,987
177,455 / 165,724
4 / 111
0 / 3
Yes
Historical episode evidence
Depression, 2001-2003 (Fragmented control)
Interpretation: Weak, spatially limited park authority in the Kamalondo Depression with locally negotiated access and no consolidated militia territorial control.
Evidence: Armed actors were reported using Upemba as refuge from 2002. Emergency assistance and follow-up provisioning during 2000-2002 enabled only a limited resumption of patrol activity, concentrated principally around the Plateau core, while ICCN leadership continued to rely heavily on negotiation and contact with armed actors. OKA convened a November 2003 table ronde involving customary authorities and ICCN, showing negotiated conservation rather than consolidated enforcement.
Transition: The study window imposes the 2001 start. The episode ends in 2003 because the 28 May 2004 Lusinga attack marks a dated rupture from weak negotiated authority to open militia-centred coercion and park withdrawal.
Sources: Hasson 2003; Nouvelles Approches 2002-2004; OKA Kanyundu 2018; Van Leeuwe et al. 2009; Hasson 2015
Depression, 2004-2006 (Militia-centred control)
Interpretation: Militia and military coercion dominated practical access conditions after the Lusinga attack; lawful park authority retreated from the Depression and routine enforcement collapsed.
Evidence: On 28 May 2004, around forty Mai-Mai fighters attacked Lusinga, killing park staff and family members, taking hostages, burning tourist rondavels, looting archives and possessions, and precipitating withdrawal from the Kamalondo Depression. The government then deployed roughly 85-100 FARDC soldiers to Lusinga for about two years, while reports describe military-linked poaching and constrained ranger authority. The broader Mitwaba-Pweto-Manono conflict displaced villages and disrupted access routes; Gédéon surrendered at Mitwaba on 16 May 2006.
Transition: The 2004 start is anchored by the dated Lusinga attack. The 2006 end follows Gédéon's surrender and demobilization dynamics, but the following period is coded as fragmented rather than park-centred because reopening and ranger salary restoration did not restore consolidated park control.
Sources: Van Leeuwe et al. 2009; Hasson 2015; Nouvelles Approches 2002-2004; Hecht 2006; Human Rights Watch 2006
Depression, 2007-2012 (Fragmented control)
Interpretation: Post-demobilization conditions combined residual armed presence, negotiated conservation through customary authorities, and limited conservation re-entry without dominant park control in the Depression.
Evidence: From 2007 BAK lobbied for renewed support, and BAK-ICCN formalized a contract in April 2008. FZS scouting and the WCS survey in 2008 documented catastrophic governance conditions, rent-seeking allegations, and residual Mai-Mai presence around Mbwe along the Lufira. OKA and BAK activity, including the 2010 Chief Kayumba declaration recognizing the 1975 boundary, indicate negotiated recognition of park space. FZS technical support from 2011 remained concentrated around Lusinga and the plateaus; the Depression stayed beyond effective operational reach.
Transition: The 2007 start follows Gédéon's 2006 surrender and partial re-entry. The Depression episode continues through 2012 because donor-supported operations strengthened primarily around Lusinga and the Plateau, while evidence for systematic Depression penetration appears only in late 2016 and early 2017.
Sources: Van Leeuwe et al. 2009; Hasson 2015; FZS 2009; OKA Kanyundu 2018; Chief Kayumba 2010
Depression, 2013-2016 (Militia-centred control)
Interpretation: Renewed armed insecurity and weak state or park access made militia-linked control and coercive access constraints more important than park-centred authority in the Depression.
Evidence: After Gedeon's 2011 escape, Bakata Katanga activity intensified across 2013-2016. OCHA described renewed insecurity with large-scale displacement and more than 1,000 houses burned in 70 villages between October 2013 and mid-January 2014. MONUSCO reported separation of 82 children from Mai-Mai in August 2013, Radio Okapi linked the Mbwe corridor inside Upemba to armed territorial and extractive control in April 2013, and later reporting described displacement, weak state access, elephant-poaching networks, and constrained park penetration. Katembo's appointment in 2015 strengthened leadership, but systematic Depression penetration is documented only in late 2016 and early 2017.
Transition: The 2013 start follows renewed armed mobilization and 2012-2013 incidents around Mbwe. The episode ends in 2016 because late-2016 operations begin to penetrate the Depression, but the Depression transition to park-centred control is coded in 2017 because operational reach becomes clear only then.
Sources: OCHA 2013; MONUSCO 2013; Radio Okapi 2013; Katanga Protection Cluster 2015; Ngoy 2015; Huisman 2017; Katembo 2016; Katembo 2017
Depression, 2017-2022 (Park-centred control)
Interpretation: Expanded park operational reach, public-private management capacity, and renewed patrol penetration made park authority the central practical control actor in the Depression, though control remained incomplete and insecurity persisted.
Evidence: Late-2016 and early-2017 elephant-protection operations under Rodrigue Katembo deployed ranger teams along the Bukama-Lake Kabwe-Kasale axis and toward Manono and Malemba-Nkulu, documenting renewed patrol penetration beyond the Plateau core into the Kamalondo Depression. The formal public-private partnership began in July 2017 after creation of the Upemba-Kundelungu Complex in June 2016 and appointment of Robert Muir as chief park warden. Later professionalization included ranger training in 2019-2020 and disruption of elephant-poaching networks, while the Bakata Katanga incursion and disarmament crisis in Mitwaba in early 2022 showed that control remained partial rather than exclusive.
Transition: The Depression transition is one year later than the Plateau because the evidence for systematic reach into the Depression becomes clear only in late 2016 and early 2017, whereas Plateau strengthening began earlier around the operational core.
Sources: Katembo 2016; Katembo 2017; Brugière 2020; d'Huart 2017; Villaespesa 2020; IUCN NL 2021; Radio Okapi 2022a; Radio Okapi 2022b
Plateau, 2001-2003 (Fragmented control)
Interpretation: Weak but not absent park authority persisted around the Plateau core, supported by modest relief and negotiation, while no actor consolidated territorial control.
Evidence: Armed actors were reported using Upemba as refuge from 2002. Emergency assistance and follow-up provisioning during 2000-2002 enabled only a limited resumption of patrol activity, concentrated principally around the Plateau core, while ICCN leadership continued to rely heavily on negotiation and contact with armed actors rather than consolidated coercive capacity. OKA convened a November 2003 table ronde involving customary authorities and ICCN, showing fragmented, negotiated conservation rather than dominant enforcement.
Transition: The 2001 start is imposed by the remote-sensing study period. The episode ends in 2003 because the May 2004 Lusinga attack produced a dated collapse of the Plateau headquarters and shifted access conditions toward militia-centred coercion.
Sources: Hasson 2003; Nouvelles Approches 2002-2004; OKA Kanyundu 2018; Van Leeuwe et al. 2009; Hasson 2015
Plateau, 2004-2006 (Militia-centred control)
Interpretation: Militia attack and regional armed conflict directly undermined the Plateau headquarters and made militia-centred coercion the dominant practical condition around Lusinga and Mitwaba.
Evidence: The 28 May 2004 attack on Lusinga killed staff and family members, destroyed infrastructure, looted archives, and forced staff families to flee. FARDC soldiers were deployed to Lusinga for about two years, and reports describe heavy military-linked poaching. The same period coincided with peak Mai-Mai strength in the Mitwaba zone and the wider Triangle of Death, with village burnings, displacement, and disrupted road access. Gédéon's May 2006 surrender ended the first conflict episode.
Transition: The 2004 start is the dated attack on the Plateau headquarters. The 2006 end follows Gédéon's surrender and demobilization, but 2007 is fragmented rather than park-centred because residual Mai-Mai presence and weak institutional capacity persisted.
Sources: Van Leeuwe et al. 2009; Hasson 2015; Nouvelles Approches 2002-2004; Hecht 2006; Human Rights Watch 2006
Plateau, 2007-2010 (Fragmented control)
Interpretation: Residual militia presence, negotiated coexistence, and externally supported but still weak conservation activity produced fragmented access rather than militia-centred or park-centred dominance.
Evidence: From 2007 BAK lobbied for EU support, a BAK-ICCN contract was signed in April 2008, FZS scouted in 2008, and WCS surveyed in 2008. Reports still described catastrophic governance, rent-seeking, and residual Mai-Mai in the park, with ICCN maintaining contact with a quiet Mbwe group. In 2010 Chief Kayumba recognized the 1975 boundary, indicating negotiated recognition. The Plateau episode ends in 2010 because the FZS technical-assistance phase began in 2010-2011 and materially strengthened operations around Lusinga and the Plateau core.
Transition: The 2007 start follows demobilization after Gédéon's surrender. The 2010 end is justified by the transition to donor-supported technical assistance around Lusinga and the plateaus beginning in 2010-2011.
Sources: Van Leeuwe et al. 2009; Hasson 2015; FZS 2009; OKA Kanyundu 2018; Chief Kayumba 2010
Plateau, 2011-2012 (Park-centred control)
Interpretation: Relative park-centred configuration around Lusinga and the accessible Plateau core, with strengthened management and operational presence but not uniform or uncontested control across the wider park.
Evidence: The EU-supported FZS technical-assistance phase began across 2010-2011 and strengthened infrastructure, management capacity, and operational presence around Lusinga and the accessible Plateau core. Hance reported renewed activity and raids around Lusinga in 2012, and Radio Okapi reported the killing of the park manager on 18 December 2012, indicating that park-centred control remained relative rather than uniform or uncontested.
Transition: The frozen 2011 start reflects the beginning of the EU-supported technical-assistance phase across 2010-2011 and a relative strengthening around the Plateau core. The episode ends in 2012 because renewed attacks and abandonment of positions in 2013 mark a return to militia-centred coercive conditions on the Plateau.
Sources: Hasson 2015; Aerden 2012; Hance 2012a; Hance 2012b; Radio Okapi 2012b
Plateau, 2013-2015 (Militia-centred control)
Interpretation: Renewed Bakata Katanga and related armed activity contracted park reach around Plateau positions and made militia-centred coercive control the dominant practical condition.
Evidence: After Gédéon's 2011 escape, Bakata Katanga activity increased and Mbwe was repeatedly linked to armed actors. In 2014 Radio Okapi reported attacks around park positions, ambushes, hostage-taking, theft of firearms, burning or destruction of guard posts, abandonment of posts, and retreat of guards and families to Lusinga. FARDC deployed in response, and reporting described hunting in zones escaping managerial control. Interview-based chronology indicates declining militia activity from 2015.
Transition: The 2013 start follows renewed attacks and reported armed control around Mbwe and Mitwaba after 2012. The 2015 end reflects declining militia activity and precedes Gédéon's October 2016 surrender and renewed systematic park operations on the Plateau.
Sources: OCHA 2013; Katanga Protection Cluster 2015; MONUSCO 2013; Radio Okapi 2013; Radio Okapi 2014a; Radio Okapi 2014b; Radio Okapi 2014c; Radio Okapi 2014d; Huisman 2017
Plateau, 2016-2022 (Park-centred control)
Interpretation: Operational strengthening, renewed systematic patrols, and public-private management made park authority the central practical control actor around the Plateau core, while insecurity persisted.
Evidence: Rodrigue Katembo's 2015 appointment and field leadership coincided with declining Mai-Mai activity and Gédéon's surrender in October 2016. A late-2016 elephant-protection operation reportedly deployed 60 rangers, with follow-up operations in early 2017. ICCN created the Upemba-Kundelungu Complex in June 2016 and appointed Robert Muir as chief park warden; a formal public-private management arrangement followed in July 2017. Ranger training and professionalization occurred in 2019-2020, while attacks in 2021 and 2022 show partial rather than exclusive control.
Transition: The Plateau transition is coded in 2016 rather than 2017 because operational strengthening, Gédéon's surrender, and complex-level management preceded the formal PPP contract. The episode continues through 2022 because no later evidence supports a different frozen profile before the study endpoint.
Sources: Katembo 2016; Katembo 2017; Huisman 2017; d'Huart 2017; Brugière 2020; Villaespesa 2020; IUCN NL 2021; Radio Okapi 2022a; Radio Okapi 2022b
Profile
Landscape-group years
Calendar years
Episodes
Depression years
Plateau years
Militia-centred control
13
7
4
7
6
Fragmented control
16
9
4
9
7
Park-centred control
15
9
3
6
9
Outcome
Profile
Estimate
SE
95% CI
Model
Support
Fire
Militia-centred control
0.011
0.033
−0.054, 0.075
Beta-binomial
508,320 burned cell-years
Fire
Fragmented control
0.170
0.030
0.112, 0.229
Beta-binomial
508,320 burned cell-years
Fire
Park-centred control
0.068
0.031
0.008, 0.128
Beta-binomial
508,320 burned cell-years
Tree-cover loss
Fragmented control
−0.846
0.228
−1.293, −0.399
Two-stage HC3
519 first events
Tree-cover loss
Militia-centred control
−0.898
0.312
−1.509, −0.287
Two-stage HC3
519 first events
Tree-cover loss
Park-centred control
−1.430
0.261
−1.941, −0.919
Two-stage HC3
519 first events
Agricultural expansion
Fragmented control
0.286
0.230
−0.164, 0.737
Two-stage HC3
518 first events
Agricultural expansion
Militia-centred control
0.222
0.138
−0.048, 0.492
Two-stage HC3
518 first events
Agricultural expansion
Park-centred control
−0.347
0.158
−0.657, −0.037
Two-stage HC3
518 first events
Outcome
Comparison
Estimate
SE
95% CI
Model
Fire
Militia-centred minus Fragmented
−0.160
0.044
−0.247, −0.072
Beta-binomial
Fire
Park-centred minus Militia-centred
0.057
0.045
−0.031, 0.145
Beta-binomial
Fire
Park-centred minus Fragmented
−0.102
0.043
−0.186, −0.019
Beta-binomial
Tree-cover loss
Park-centred minus Fragmented
−0.584
0.342
−1.255, 0.087
Two-stage HC3
Tree-cover loss
Militia-centred minus Fragmented
−0.052
0.389
−0.814, 0.711
Two-stage HC3
Tree-cover loss
Park-centred minus Militia-centred
−0.532
0.402
−1.321, 0.256
Two-stage HC3
Agricultural expansion
Park-centred minus Fragmented
−0.633
0.311
−1.244, −0.023
Two-stage HC3
Agricultural expansion
Militia-centred minus Fragmented
−0.065
0.291
−0.634, 0.505
Two-stage HC3
Agricultural expansion
Park-centred minus Militia-centred
−0.569
0.221
−1.001, −0.137
Two-stage HC3
Outcome
Profile
Weighted primary
Unweighted sensitivity
Tree-cover loss
Fragmented control
-0.846 [-1.293, -0.399]
-0.881 [-1.357, -0.405]
Tree-cover loss
Militia-centred control
-0.898 [-1.509, -0.287]
-0.881 [-1.591, -0.170]
Tree-cover loss
Park-centred control
-1.430 [-1.941, -0.919]
-1.762 [-2.370, -1.153]
Agricultural expansion
Fragmented control
0.286 [-0.164, 0.737]
0.241 [-0.060, 0.542]
Agricultural expansion
Militia-centred control
0.222 [-0.048, 0.492]
-0.053 [-0.599, 0.492]
Agricultural expansion
Park-centred control
-0.347 [-0.657, -0.037]
-0.285 [-0.557, -0.013]
Outcome
Comparison
Weighted primary
Unweighted sensitivity
Tree-cover loss
Militia-centred minus Fragmented
-0.052 [-0.814, 0.711]
0.001 [-0.852, 0.853]
Tree-cover loss
Park-centred minus Fragmented
-0.584 [-1.255, 0.087]
-0.880 [-1.664, -0.096]
Tree-cover loss
Park-centred minus Militia-centred
-0.532 [-1.321, 0.256]
-0.881 [-1.814, 0.052]
Agricultural expansion
Militia-centred minus Fragmented
-0.065 [-0.634, 0.505]
-0.294 [-0.937, 0.348]
Agricultural expansion
Park-centred minus Fragmented
-0.633 [-1.244, -0.023]
-0.526 [-0.916, -0.135]
Agricultural expansion
Park-centred minus Militia-centred
-0.569 [-1.001, -0.137]
-0.232 [-0.812, 0.349]
Outcome
Contrast type
Profile / pairwise difference
10%
25% (primary)
50%
Tree-cover loss
Profile-specific
Fragmented control
-0.883 [-1.204, -0.561]
-0.846 [-1.293, -0.399]
0.054 [-0.332, 0.440]
Tree-cover loss
Profile-specific
Militia-centred control
-1.170 [-1.714, -0.626]
-0.898 [-1.509, -0.287]
-0.334 [-0.816, 0.147]
Tree-cover loss
Profile-specific
Park-centred control
-1.443 [-1.889, -0.997]
-1.430 [-1.941, -0.919]
-0.018 [-0.521, 0.484]
Tree-cover loss
Pairwise difference
Militia-centred minus Fragmented
-0.287 [-0.920, 0.345]
-0.052 [-0.814, 0.711]
-0.389 [-1.023, 0.246]
Tree-cover loss
Pairwise difference
Park-centred minus Fragmented
-0.560 [-1.084, -0.036]
-0.584 [-1.255, 0.087]
-0.072 [-0.716, 0.572]
Tree-cover loss
Pairwise difference
Park-centred minus Militia-centred
-0.273 [-0.954, 0.408]
-0.532 [-1.321, 0.256]
0.316 [-0.380, 1.013]
Fire
Profile-specific
Fragmented control
0.156 [0.095, 0.217]
0.170 [0.112, 0.229]
0.179 [non-strict fit]
Fire
Profile-specific
Militia-centred control
-0.011 [-0.079, 0.057]
0.011 [-0.054, 0.075]
0.020 [non-strict fit]
Fire
Profile-specific
Park-centred control
0.044 [-0.019, 0.106]
0.068 [0.008, 0.128]
0.089 [non-strict fit]
Fire
Pairwise difference
Militia-centred minus Fragmented
-0.167 [-0.258, -0.075]
-0.160 [-0.247, -0.072]
-0.159 [non-strict fit]
Fire
Pairwise difference
Park-centred minus Fragmented
-0.112 [-0.200, -0.025]
-0.102 [-0.186, -0.019]
-0.091 [non-strict fit]
Fire
Pairwise difference
Park-centred minus Militia-centred
0.054 [-0.038, 0.147]
0.057 [-0.031, 0.145]
0.069 [non-strict fit]
Agricultural expansion
Profile-specific
Fragmented control
0.113 [-0.336, 0.562]
0.286 [-0.164, 0.737]
-0.214 [-0.525, 0.097]
Agricultural expansion
Profile-specific
Militia-centred control
-0.318 [-0.595, -0.041]
0.222 [-0.048, 0.492]
0.117 [-0.192, 0.426]
Agricultural expansion
Profile-specific
Park-centred control
-1.125 [-1.321, -0.928]
-0.347 [-0.657, -0.037]
0.181 [-0.194, 0.556]
Agricultural expansion
Pairwise difference
Militia-centred minus Fragmented
-0.431 [-0.987, 0.124]
-0.065 [-0.634, 0.505]
0.331 [-0.129, 0.791]
Agricultural expansion
Pairwise difference
Park-centred minus Fragmented
-1.238 [-1.755, -0.720]
-0.633 [-1.244, -0.023]
0.395 [-0.156, 0.945]
Agricultural expansion
Pairwise difference
Park-centred minus Militia-centred
-0.806 [-1.110, -0.503]
-0.569 [-1.001, -0.137]
0.064 [-0.483, 0.611]
Outcome
Contrast type
Profile / pairwise difference
5 km
10 km (primary)
20 km
All cells
Tree-cover loss
Profile-specific
Fragmented control
-0.269 [-0.716, 0.177]
-0.846 [-1.293, -0.399]
-0.986 [-1.437, -0.535]
-1.172 [-1.727, -0.616]
Tree-cover loss
Profile-specific
Militia-centred control
-0.382 [-0.945, 0.182]
-0.898 [-1.509, -0.287]
-1.400 [-2.104, -0.697]
-1.787 [-2.496, -1.078]
Tree-cover loss
Profile-specific
Park-centred control
-0.874 [-1.451, -0.298]
-1.430 [-1.941, -0.919]
-1.932 [-2.595, -1.270]
-2.604 [-3.400, -1.808]
Tree-cover loss
Pairwise difference
Militia-centred minus Fragmented
-0.113 [-0.820, 0.595]
-0.052 [-0.814, 0.711]
-0.414 [-1.228, 0.400]
-0.616 [-1.463, 0.231]
Tree-cover loss
Pairwise difference
Park-centred minus Fragmented
-0.605 [-1.263, 0.052]
-0.584 [-1.255, 0.087]
-0.946 [-1.654, -0.239]
-1.432 [-2.157, -0.708]
Tree-cover loss
Pairwise difference
Park-centred minus Militia-centred
-0.493 [-1.259, 0.274]
-0.532 [-1.321, 0.256]
-0.532 [-1.448, 0.383]
-0.817 [-1.720, 0.087]
Fire
Profile-specific
Fragmented control
0.092
0.170 [0.112, 0.229]
0.194
0.193 [0.090, 0.296]
Fire
Profile-specific
Militia-centred control
0.022
0.011 [-0.054, 0.075]
0.032
0.055 [-0.060, 0.169]
Fire
Profile-specific
Park-centred control
0.007
0.068 [0.008, 0.128]
0.144
0.119 [0.013, 0.224]
Fire
Pairwise difference
Militia-centred minus Fragmented
-0.070
-0.160 [-0.247, -0.072]
-0.162
-0.138 [-0.292, 0.016]
Fire
Pairwise difference
Park-centred minus Fragmented
-0.085
-0.102 [-0.186, -0.019]
-0.050
-0.074 [-0.222, 0.073]
Fire
Pairwise difference
Park-centred minus Militia-centred
-0.014
0.057 [-0.031, 0.145]
0.112
0.064 [-0.092, 0.219]
Agricultural expansion
Profile-specific
Fragmented control
0.316 [-0.119, 0.752]
0.286 [-0.164, 0.737]
0.225 [-0.223, 0.673]
0.563 [0.069, 1.057]
Agricultural expansion
Profile-specific
Militia-centred control
0.449 [0.084, 0.814]
0.222 [-0.048, 0.492]
0.201 [-0.088, 0.491]
0.164 [-0.140, 0.468]
Agricultural expansion
Profile-specific
Park-centred control
-0.128 [-0.445, 0.189]
-0.347 [-0.657, -0.037]
-0.529 [-0.874, -0.184]
-0.573 [-0.890, -0.256]
Agricultural expansion
Pairwise difference
Militia-centred minus Fragmented
0.132 [-0.505, 0.770]
-0.065 [-0.634, 0.505]
-0.024 [-0.565, 0.517]
-0.399 [-0.998, 0.201]
Agricultural expansion
Pairwise difference
Park-centred minus Fragmented
-0.445 [-1.064, 0.174]
-0.633 [-1.244, -0.023]
-0.755 [-1.358, -0.151]
-1.136 [-1.765, -0.507]
Agricultural expansion
Pairwise difference
Park-centred minus Militia-centred
-0.577 [-1.119, -0.035]
-0.569 [-1.001, -0.137]
-0.730 [-1.181, -0.280]
-0.737 [-1.158, -0.316]
Outcome
Profile
Valid scenarios
Earlier-implementation reference
Alternative-scenario minimum
Alternative-scenario maximum
All alternatives retained reference sign
Tree-cover loss
Fragmented control
38
-0.743
-1.456
-0.775
Yes
Tree-cover loss
Militia-centred control
38
-1.771
-2.474
-1.053
Yes
Tree-cover loss
Park-centred control
38
-2.591
-4.500
-2.545
Yes
Fire
Fragmented control
38
-0.031
0.104
0.341
No
Fire
Militia-centred control
38
-0.168
-0.039
0.196
No
Fire
Park-centred control
38
-0.216
-0.096
0.348
No
Agricultural expansion
Fragmented control
38
0.501
-0.093
0.588
No
Agricultural expansion
Militia-centred control
38
0.122
-0.516
0.353
No
Agricultural expansion
Park-centred control
38
-0.521
-16.275
-0.414
Yes
Threshold
Optimizer
Convergence code
Positive-definite Hessian
Maximum framework gradient
Maximum independent gradient
Strict-valid
Selected
10%
BFGS refined
0
Yes
0.000844
0.000841
Yes
No
25%
BFGS refined
0
Yes
0.000954
0.000947
Yes
Yes
50%
BFGS refined
0
Yes
0.000829
0.001957
No
No
Outcome
Profile
Legal boundary
Spaced-outer range
Dense outer 10th–90th percentile result
Descriptive interpretation
Tree-cover loss
Fragmented control
-0.846 [-1.293, -0.399]
-0.393 to 0.378
Legal estimate below outer 10th percentile
legal-boundary-aligned among evaluated outward offsets
Tree-cover loss
Militia-centred control
-0.898 [-1.509, -0.287]
0.132 to 0.309
Legal estimate below outer 10th percentile
legal-boundary-aligned among evaluated outward offsets
Tree-cover loss
Park-centred control
-1.430 [-1.941, -0.919]
-0.417 to 0.504
Legal estimate below outer 10th percentile
legal-boundary-aligned among evaluated outward offsets
Fire
Fragmented control
0.170 [0.112, 0.229]
-0.314 to 0.422
Legal estimate within outer 10th–90th percentile interval
comparable contrasts recur at outward offsets
Fire
Militia-centred control
0.011 [-0.054, 0.075]
-0.350 to 0.513
Legal estimate within outer 10th–90th percentile interval
comparable contrasts recur at outward offsets
Fire
Park-centred control
0.068 [0.008, 0.128]
-0.484 to 0.478
Legal estimate within outer 10th–90th percentile interval
comparable contrasts recur at outward offsets
Agricultural expansion
Fragmented control
0.286 [-0.164, 0.737]
-0.304 to 0.270
Legal estimate above outer 90th percentile
inconclusive
Agricultural expansion
Militia-centred control
0.222 [-0.048, 0.492]
-0.268 to 0.134
Legal estimate within outer 10th–90th percentile interval
inconclusive
Agricultural expansion
Park-centred control
-0.347 [-0.657, -0.037]
-0.201 to -0.049
Legal estimate within outer 10th–90th percentile interval
inconclusive
Profile / support
Legal boundary
+20 km
+40 km
+60 km
Fragmented control
-0.846 [-1.293, -0.399]
-0.393 [-0.703, -0.083]
0.378 [0.111, 0.644]
-0.098 [-0.415, 0.219]
Militia-centred control
-0.898 [-1.509, -0.287]
0.132 [-0.334, 0.598]
0.177 [-0.291, 0.646]
0.309 [-0.143, 0.762]
Park-centred control
-1.430 [-1.941, -0.919]
-0.417 [-0.665, -0.170]
0.504 [0.223, 0.784]
-0.070 [-0.394, 0.254]
Event support
519
813
1,666
1,525
Profile / support
Legal boundary
+20 km
+40 km
+60 km
Fragmented control
0.170 [0.112, 0.229]
0.422 (finite non-strict fit)
-0.314 (finite non-strict fit)
-0.148 [-0.221, -0.075]
Militia-centred control
0.011 [-0.054, 0.075]
0.513 (finite non-strict fit)
-0.350 (finite non-strict fit)
-0.208 [-0.289, -0.127]
Park-centred control
0.068 [0.008, 0.128]
0.478 (finite non-strict fit)
-0.484 (finite non-strict fit)
-0.130 [-0.205, -0.055]
Event support
508,320
426,962
404,121
446,426
Profile / support
Legal boundary
+20 km
+40 km
+60 km
Fragmented control
0.286 [-0.164, 0.737]
-0.002 [-0.446, 0.442]
0.270 [-0.018, 0.558]
-0.304 [-0.573, -0.036]
Militia-centred control
0.222 [-0.048, 0.492]
-0.268 [-0.655, 0.119]
0.134 [-0.139, 0.407]
-0.017 [-0.304, 0.270]
Park-centred control
-0.347 [-0.657, -0.037]
-0.201 [-0.553, 0.152]
-0.104 [-0.484, 0.276]
-0.049 [-0.267, 0.169]
Event support
518
156
1,214
625
Component
Software or file
Version
Role
Authoritative path
R
R
R version 4.5.3 (2026-03-11 ucrt)
execution environment
system R
glmmTMB
glmmTMB
1.1.14
beta-binomial fitting
installed package
terra
terra
1.9.11
raster processing
installed package
sf
sf
1.1.0
vector spatial processing
installed package
sandwich or covariance implementation
sandwich
3.1.1
HC3 covariance support
installed package
analysis configuration
config/analysis_config.R
frozen repository version
configuration
config/analysis_config.R
primary model scripts
scripts/05_models_governance_profiles.R; scripts/06_governance_profile_robustness.R; scripts/07_spatial_threshold_sensitivity.R;
scripts/08_generate_figure2_chronology_time_series.R;
scripts/09_fire_2021_2022_harmonization.R; scripts/10_fire_10km_optimizer_refinement.R; scripts/12_spatial_boundary_falsification_revised.R
frozen repository version
analysis execution
scripts/05_models_governance_profiles.R; scripts/06_governance_profile_robustness.R; scripts/07_spatial_threshold_sensitivity.R; scripts/09_fire_2021_2022_harmonization.R; scripts/10_fire_10km_optimizer_refinement.R; scripts/12_spatial_boundary_falsification_revised.R
publication scripts
scripts/publication/06_generate_main_figures_tables.R; scripts/publication/07_generate_supplementary_material.R
frozen repository version
publication output generation
scripts/publication/06_generate_main_figures_tables.R; scripts/publication/07_generate_supplementary_material.R
final result tables
outputs/publication/figure_source_data/Figure_3_profile_contrasts.csv; outputs/publication/figure_source_data/Figure_3_pairwise_differences.csv; outputs/publication/figure_source_data/Figure_4_profile_boundary_estimates.csv; analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv
frozen authoritative outputs
authoritative inputs
outputs/publication/figure_source_data/Figure_3_profile_contrasts.csv; outputs/publication/figure_source_data/Figure_3_pairwise_differences.csv; outputs/publication/figure_source_data/Figure_4_profile_boundary_estimates.csv; analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv
Outcome
Source (native resolution)
Primary 500 m event definition
Risk-set rule
Process represented
Fire
ESA FireCCI v5.1 (250 m)
≥25% of a cell burned during day of year 100–300
All eligible cells remain at risk annually
Recurrent, mobile burning; ignition cause not identified
Tree-cover loss
Hansen Global Forest Change v1.12 (30 m)
First year cumulative mapped loss reaches ≥25% of a cell
Cells with ≥30% tree cover in 2000; removed after first event
First crossing of a spatially fixed canopy-removal threshold; permanence and cause not identified
Agricultural expansion
Annual Cropland Extent Dataset for Africa (30 m)
First annual transition from <25% to ≥25% cropland
Cells removed after first detected transition
Site-specific land-use establishment; persistence not identified
Outcome and support
Legal-boundary result
Profile comparison
Outer pseudo-boundaries
Robustness and inference
Tree-cover loss
519 first 25% cumulative-loss threshold events
Pooled odds lower inside under fragmented, militia-centred, and park-centred control (57%, 59%, and 76% reductions).
Park-centred point estimate most negative; all pairwise 95% CIs included zero. Broad profiles pool non-identical episodes.
Legal estimate more negative than all ten evaluated outward estimates under every profile; one-sided descriptive comparison.
Direction retained in several sensitivities, but weaker at better-balanced 5 km and attenuated/imprecise at sparse 50% threshold. Legal-boundary-aligned land-surface pattern, not actor or biodiversity attribution.
Fire
508,320 burned of 936,188 eligible cell-years
Contrast positive under fragmented and park-centred control and near zero under militia-centred control.
Militia-centred and park-centred contrasts lower than fragmented in primary model; park-centred and militia-centred uncertain.
Every legal estimate within outward-offset range; comparable contrasts and sign reversals elsewhere. Some outer fits non-strict.
Primary profile differences are conditional model results; exploratory chronology signs were unstable. No exceptional legal-boundary alignment among evaluated offsets.
Agricultural expansion
518 first events
Primary park-centred contrast negative; fragmented and militia-centred estimates weakly positive.
Primary pairwise differences depended on specification.
Sparse and unstable estimates prevented classification.
Sensitive to weighting, threshold, and domain; no reliable location-specific or institutional inference.
Response / period
Profile
Estimate [HC3 CI]
Spatial-bootstrap CI
First crossing, 2001–2022
Fragmented
0.286 [-0.164, 0.737]
[-0.246, 0.770]
First crossing, 2001–2022
Militia-centred
0.222 [-0.048, 0.492]
[-0.265, 0.671]
First crossing, 2001–2022
Park-centred
-0.347 [-0.657, -0.037]
[-0.807, 0.102]
First crossing, 2001–2019
Fragmented
0.222 [-0.220, 0.663]
[-0.288, 0.689]
First crossing, 2001–2019
Militia-centred
0.153 [-0.119, 0.425]
[-0.295, 0.588]
First crossing, 2001–2019
Park-centred
-0.240 [-0.611, 0.131]
[-0.726, 0.265]
Persistent establishment, 2001–2019
Fragmented
0.257 [-0.169, 0.683]
[-0.241, 0.756]
Persistent establishment, 2001–2019
Militia-centred
0.139 [-0.191, 0.468]
[-0.350, 0.593]
Persistent establishment, 2001–2019
Park-centred
-0.235 [-0.753, 0.284]
[-0.683, 0.236]
Annual presence, 2001–2022
Fragmented
-1.549 [-1.651, -1.448]
[-2.311, -0.098]
Annual presence, 2001–2022
Militia-centred
-1.356 [-1.504, -1.208]
[-2.074, 0.061]
Annual presence, 2001–2022
Park-centred
-1.175 [-1.259, -1.092]
[-1.900, 0.233]
Domain
Side
All events
Reversed / eligible
Insufficient follow-up
full
outside
2430
193 / 2092
338
full
inside
255
10 / 237
18
10km
inside
254
10 / 236
18
10km
outside
264
13 / 227
37
Domain
Crossings
Any gain in cell
Native overlap
Full retained domain
2801
754
599
10 km corridor
364
58
46
Response / period
Profile
Inside
Outside
Cell-years
First crossing, 2001–2022
Fragmented
70
52
332331
First crossing, 2001–2022
Militia-centred
110
98
271770
First crossing, 2001–2022
Park-centred
74
114
327556
First crossing, 2001–2019
Fragmented
70
52
332331
First crossing, 2001–2019
Militia-centred
110
98
271770
First crossing, 2001–2019
Park-centred
49
63
201290
Persistent establishment, 2001–2019
Fragmented
73
51
332397
Persistent establishment, 2001–2019
Militia-centred
101
91
271846
Persistent establishment, 2001–2019
Park-centred
43
55
201349
Annual presence, 2001–2022
Fragmented
1314
2678
333140
Annual presence, 2001–2022
Militia-centred
1375
2321
272955
Annual presence, 2001–2022
Park-centred
1793
2550
330093
Outcome
Alignment
Profile
Estimate [95% CI]
Events
fire
lag0
Fragmented
0.170 [0.112, 0.229]
508320
fire
lag0
Militia-centred
0.011 [-0.054, 0.075]
508320
fire
lag0
Park-centred
0.068 [0.008, 0.128]
508320
tree cover loss
lag0
Fragmented
-0.846 [-1.293, -0.399]
519
tree cover loss
lag0
Militia-centred
-0.898 [-1.509, -0.287]
519
tree cover loss
lag0
Park-centred
-1.430 [-1.941, -0.919]
519
agriculture
lag0
Fragmented
0.286 [-0.164, 0.737]
518
agriculture
lag0
Militia-centred
0.222 [-0.048, 0.492]
518
agriculture
lag0
Park-centred
-0.347 [-0.657, -0.037]
518
fire
lag1
Fragmented
0.095 [0.035, 0.155]
494511
fire
lag1
Militia-centred
0.058 [-0.008, 0.125]
494511
fire
lag1
Park-centred
0.071 [0.004, 0.138]
494511
tree cover loss
lag1
Fragmented
-0.787 [-1.271, -0.304]
518
tree cover loss
lag1
Militia-centred
-1.272 [-1.924, -0.620]
518
tree cover loss
lag1
Park-centred
-1.395 [-1.934, -0.857]
518
agriculture
lag1
Fragmented
0.252 [-0.070, 0.575]
510
agriculture
lag1
Militia-centred
0.130 [-0.287, 0.548]
510
agriculture
lag1
Park-centred
-0.382 [-0.841, 0.078]
510
fire
lag2
Fragmented
0.060 [-0.001, 0.121]
472870
fire
lag2
Militia-centred
0.111 [0.044, 0.177]
472870
fire
lag2
Park-centred
0.058 [-0.015, 0.132]
472870
tree cover loss
lag2
Fragmented
-0.925 [-1.276, -0.575]
484
tree cover loss
lag2
Militia-centred
-1.346 [-1.868, -0.825]
484
tree cover loss
lag2
Park-centred
-1.456 [-2.088, -0.823]
484
agriculture
lag2
Fragmented
0.310 [0.028, 0.592]
491
agriculture
lag2
Militia-centred
0.125 [-0.292, 0.543]
491
agriculture
lag2
Park-centred
-0.594 [-0.861, -0.326]
491
fire
exclude_first_posttransition
Fragmented
0.173 [0.113, 0.233]
394145
fire
exclude_first_posttransition
Militia-centred
0.021 [-0.054, 0.095]
394145
fire
exclude_first_posttransition
Park-centred
0.074 [0.010, 0.139]
394145
tree cover loss
exclude_first_posttransition
Fragmented
-0.883 [-1.394, -0.372]
456
tree cover loss
exclude_first_posttransition
Militia-centred
-0.990 [-1.725, -0.254]
456
tree cover loss
exclude_first_posttransition
Park-centred
-1.516 [-2.118, -0.914]
456
agriculture
exclude_first_posttransition
Fragmented
0.339 [-0.145, 0.823]
412
agriculture
exclude_first_posttransition
Militia-centred
0.311 [-0.057, 0.680]
412
agriculture
exclude_first_posttransition
Park-centred
-0.413 [-0.725, -0.100]
412
fire
exclude_first_two_posttransition
Fragmented
0.196 [0.129, 0.262]
295325
fire
exclude_first_two_posttransition
Militia-centred
0.009 [-0.095, 0.112]
295325
fire
exclude_first_two_posttransition
Park-centred
0.098 [0.026, 0.170]
295325
tree cover loss
exclude_first_two_posttransition
Fragmented
-0.758 [-1.372, -0.144]
362
tree cover loss
exclude_first_two_posttransition
Militia-centred
-0.848 [-1.869, 0.173]
362
tree cover loss
exclude_first_two_posttransition
Park-centred
-1.462 [-2.403, -0.521]
362
agriculture
exclude_first_two_posttransition
Fragmented
0.309 [-0.288, 0.906]
343
agriculture
exclude_first_two_posttransition
Militia-centred
0.315 [-0.149, 0.780]
343
agriculture
exclude_first_two_posttransition
Park-centred
-0.377 [-0.721, -0.033]
343
