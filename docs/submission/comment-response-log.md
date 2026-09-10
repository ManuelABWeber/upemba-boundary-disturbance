# Chapter 1 comment response log

Scope: 43 comments recovered from `C:/0_Documents/Chapter_1/chapter 1 manuscript.docx` (IDs 0–43; no ID 19). Available later editorial sources contain no Word comments and no S7. Responses below link those older requests to the new review manuscript/supplement; they do not claim to resolve unseen current comments. Edits are recorded verbatim in [manuscript_replacements.json](manuscript_replacements.json). Locations refer to `outputs/submission_review/`.

| Word ID | Request | Response / evidence / remaining requirement |
|---:|---|---|
| 0 | Avoid overselling prediction of territorial control | Abstract and Discussion distinguish association, attribution and prediction; no claim that satellite outcomes recover control without labelled evidence. |
| 1 | Explain “favourable disturbance” | Removed that terminology; abstract identifies outcome-specific contrasts. |
| 2 | Explain static inside/outside remote-sensing comparisons | Introduction moves from legal jurisdiction to practical authority and temporal control profiles. |
| 3 | Give park size | Study-area section gives approximately 10,000 km². |
| 4 | Check study area/data/methods order | Retained numbered Study area, data and analytical Methods subsections; official guide does not mandate a separate Data heading. |
| 5 | Shorten main Methods / extended methods | Consolidated sensitivities; detailed follow-up, dependence and seasonal processing in S5–S7. |
| 6 | Make abstract concrete | Rewritten 203-word abstract names fire and tree-loss comparisons and limits attribution. |
| 7 | Improve workflow figure | Old workflow graphic is absent from the later editorial source. Retained its concise methodological progression rather than reinstating a deprecated diagram; author preference remains optional. |
| 8 | Dense workflow is acceptable | Same disposition as ID 7; no obsolete graphic restored. |
| 9 | Add settlement/population numbers | No verified comparable population count located. Retained sourced historical settlement context; numerical population addition requires a dated, geographically matched source. |
| 10 | Add location figure | Main Figure 1 retained. |
| 11 | Split data tables | Baseline covariates and disturbance products appear separately (S1 and S16). |
| 12 | Prefer combined data table | Adopted the separation by analytical purpose requested in ID 14; no scientific content removed. |
| 13 | No strong table preference | Same disposition as IDs 11–14. |
| 14 | Separate covariates and disturbance indicators | Tables S1 and S16 serve these purposes. |
| 15 | Why CHIRPS rather than TerraClimate rainfall? | Preserved original CHIRPS rainfall and TerraClimate water-flux inputs. S6 identifies CHIRPS version and monthly accumulation. No unsupported comparative-accuracy claim added; original product-selection rationale beyond consistency remains an author query. |
| 16 | Explain processing terminology | Supplement S1 describes preprocessing; no undocumented new imputation introduced. Exact intended phrase should be checked in the current commented version. |
| 17 | Supply resolution | Main grid is 500 m; product resolutions and processing are in S1/S16 and seasonal S6. |
| 18 | Supply R version | Reconciliation metadata records R 4.5.3 and package versions; main text updated. |
| 20 | Avoid redundant location/landscape maps | One combined main Figure 1 retained from later editorial source. |
| 21 | Retain map | Figure 1 retained. |
| 22 | Clarify polygon versus map extent | Main text distinguishes full study domain from symmetric 10 km analytical corridor. Seasonal domain is the exact union of retained canonical cells, not a display rectangle. |
| 23 | Define side at first mention | Methods define inside/outside the legal park boundary before modelling side. |
| 24 | Justify 25% threshold | Methods identify a common mapped cell-fraction threshold and 10/50% checks; no claim that equal fractions are ecologically equivalent across outcomes. |
| 25 | Cross-reference threshold explanation | Threshold and outcome definitions brought together in Methods; S16 details source products. |
| 26 | Tense consistency | Methods describe completed operations in past tense; definitions/equations retain present tense where appropriate. |
| 27 | Clarify statistical contrast and citations | Methods distinguish paired log odds, 0.5 correction, weighted model and HC3; Figure 3 caption supplies covariance-based linear-contrast equation. |
| 28 | Why not random forest/XGBoost? | Estimand is a specified boundary contrast conditional on group/year and profile, not predictive classification. No unrelated prediction programme added. |
| 29 | Explain beta-binomial | Fire Methods identify overdispersion and fixed group-year effects; explicitly state dispersion does not model spatial/serial dependence. |
| 30 | Explain park side early | Same correction as ID 23. |
| 31 | Add conceptual diagram | Later source uses Figure 2 chronology plus explicit Methods estimands. No new schematic was needed to preserve its layout; author may request one after current comments are available. |
| 32 | Equation brackets | Figure 3 covariance expression clarified; editable manuscript equations retained and rendered. |
| 33 | Positive feedback on matched design | Matched landscape-year design preserved. |
| 34 | Back abstract inference with falsification | Abstract no longer claims recovery of territorial control. Offset diagnostics are described with their overlapping bands and limited inferential scope. |
| 35 | Map coordinate frame / overview country labels | Existing map retained, pending final artwork decision under the current journal instruction to focus maps on the study domain. No unverified place labels added. |
| 36 | Timeline start/end symbology and “regime” | Figure 2 retains dated profile bands; stable territorial-control profile terminology used. Existing chronology preserved. |
| 37 | Explain overall disturbance versus boundary contrast | Discussion distinguishes prevalence/overall disturbance from inside/outside contrasts; annual agricultural presence now directly answers a separate prevalence question. |
| 38 | List all fixed effects | Fire formula now explicitly has landscape-group/year fixed intercepts. All retained optimizer coefficients are in `analysis_fire_optimizer_refinement_dev/tables/fire_10km_optimizer_parameter_comparison.csv`; corrected agricultural coefficients and covariances are exported. |
| 39 | Include year coefficients in old placebo analysis | Old random-side placebo is not reinstated. Retained fire coefficients include group-year terms; current offset diagnostic and Figure 4 are the relevant comparison. |
| 40 | Bring governance evidence into main text | Main historical reconstruction section and Figure 2 retained, with detailed source audit in supplement. |
| 41 | Main timeline figure | Figure 2 retained in main manuscript. |
| 42 | Main historical explanation | Main text describes practical authority and changing territorial control; detailed evidence remains in supplement. |
| 43 | Clarify ordinal scores and captions | Current analysis uses categorical profiles, not a normative governance-quality scale; chronology and evidence tables are captioned. |

## Current reconciliation requirements supplied in the task

| Requirement | Disposition |
|---|---|
| Strict persistence follow-up / historical 431-event result | Corrected 414-event fit; historical estimate labelled superseded. S7 and Tables S18/S20. |
| 518-event inside/outside discrepancy | Exhaustive canonical comparison proves 254/264; old narrative arithmetic corrected. |
| Reversal / annual presence / recovery | Separate responses, valid denominators, one bounded repeated-presence analysis and whole-trajectory spatial bootstrap. |
| Hansen any gain versus native overlap | Reproduced full and corridor counts; removed temporal-recovery inference. |
| Rainfall–fire appendix | New S3 with full-cycle monthly products, coverage-based choice and explicit missing-area bounds. |
| Figure 3B / separate sign interpretations | Retained panel B, explicit first-minus-second signs and covariance-based intervals. |
| Pseudo-boundary overlap | +5–15 km park-facing band and overlap now stated. |
| Fire 10% convergence / missing interval | Reused retained valid BFGS result; updated publication table and sensitivity graphic. 50% independent-gradient caveat retained. |
| Autocorrelation | Existing influence/lag checks are not dependence corrections. Added bounded agriculture spatial uncertainty check; fire/tree intervals remain explicitly conditional. |
| Mechanisms / hunting / charcoal | Discussion treats proposed mechanisms as hypotheses or attributed reports, not demonstrated causes, intent or legitimacy. |
| de Maret year / Weber “in press” | Neither entry exists in the available selected Chapter 1 documents. Need exact current entries and evidence of acceptance; no year/status invented. |
| Radio Okapi suffixes | Four 2014 stories retained as a–d consistently; unused single-year suffixes removed. March story title/date corrected against its live article. |
| McNicol 2023 reference | Article number corrected to 392 using DOI metadata. |
| Asmani report year | Underlying PDF title page explicitly says May 2015 and identifies the Katanga Protection Cluster as producer; Asmani is the photograph credit. Corrected author and all associated citations, retaining the verified title-page year despite the filename. [Source](https://www.ecoi.net/en/file/local/1095206/1930_1401096604_kantaga-report-2014-final-english-22052014-001.pdf). |
| Author details/declarations | Draft only: confirmed author order, affiliations, CRediT, funding, conflicts, ethics/permissions, exclusive submission and reviewer access still required. |
| Clean submission files | Withheld while current S7/comments and declarations are unavailable. Review versions and exact replacements supplied instead. |

Reference checks used underlying DOI records where available and original Radio Okapi reports, including [14 March 2014](https://www.radiookapi.net/environnement/2014/03/14/parc-upemba-liccn-denonce-le-braconnage-des-habitants-dun-village-disperse/), [4 November](https://www.radiookapi.net/regions/katanga/2014/11/04/deux-attaques-des-miliciens-bakata-katanga-enregistrees-mitwaba), [5 November](https://www.radiookapi.net/actualite/2014/11/05/katanga-les-fardc-delogent-les-mai-mai-bakata-katanga-de-musumari), and [12 November](https://www.radiookapi.net/environnement/2014/11/12/katanga-les-fardc-se-deploient-dans-le-parc-de-lupemba-pour-traquer-des-miliciens). Reports of allegations were not treated as independent proof of their mechanisms.
