# Governance Episode Evidence Audit

## Scope

This audit extracts the approved episode-level evidence needed to repair Supplementary Table S6. It uses only the governance chronology, episode descriptions, dated historical events, citations, transition rationales, and uncertainty statements in:

- `evidence/chapter_1_historical_evidence.docx`
- `evidence/Weber_Upemba_History_Manuscript.docx`

It does not import old model results, ordinal governance scores, old placebo analyses, year-block bootstrap inference, or earlier result interpretation from those manuscripts. The frozen annual profile assignments remain unchanged.

## Output

Created:

- `evidence/governance_episode_evidence_ledger.csv`

The ledger contains exactly 11 rows, one for each frozen contiguous episode:

- Depression: `D-F1`, `D-M1`, `D-F2`, `D-M2`, `D-P1`
- Plateau: `P-F1`, `P-M1`, `P-F2`, `P-P1`, `P-M2`, `P-P2`

## Annual Coverage Check

Every retained annual landscape-group assignment is covered by exactly one ledger episode.

| Landscape group | Covered years | Episodes | Expected rows |
|---|---:|---:|---:|
| Depression | 2001-2022 | 5 | 22 |
| Plateau | 2001-2022 | 6 | 22 |
| Total | 44 landscape-group years | 11 | 44 |

The ledger preserves the frozen assignments:

- Depression: 2001-2003 fragmented control; 2004-2006 militia-centred control; 2007-2012 fragmented control; 2013-2016 militia-centred control; 2017-2022 park-centred control.
- Plateau: 2001-2003 fragmented control; 2004-2006 militia-centred control; 2007-2010 fragmented control; 2011-2012 park-centred control; 2013-2015 militia-centred control; 2016-2022 park-centred control.

## Evidence Completeness

Each episode row includes:

- at least one dated or period-specific event;
- multiple author-year citations where available;
- an explicit rationale for the start and end years;
- a confidence classification using only `High`, `Moderate`, or `Low`;
- plausible one-year alternatives or an explanation where the transition is fixed by the study window or a dated rupture;
- source manuscript locations for review.

No row uses generic boilerplate placeholders such as "detailed evidence ledger retained separately" or "profile assigned from frozen chronology."

## Researcher Decisions Applied

The researcher decisions have been applied to the evidence ledger before Supplementary Table S6 is regenerated.

- Citations to `Hasson 2016` were normalized to `Hasson 2015`. The older analytical manuscript contained a miscitation, and no distinct Hasson 2016 source was identified in the available evidence files.
- `Unknown author 2010` was first normalized and then corrected after researcher review to `Chief Kayumba 2010`, using the citation: Chief Kayumba. 2010. [Declaration recognizing the 1975 boundaries of Upemba National Park]. Unpublished correspondence. The square-bracketed title is descriptive.
- Personal communications are excluded from the public `Primary evidence sources` field. They are not used to support the public coding assignment.
- Source manuscript locations now use stable chapter and subsection labels rather than page numbers or extracted line references.
- Frozen transition dates are retained: Plateau park-centred control begins in 2016, with 2017 as the principal alternative; Depression park-centred control begins in 2017, with 2016 as the principal alternative.
- The different Plateau and Depression park-centred transition dates reflect spatially uneven operational recovery: strengthening around the Plateau core preceded clearly documented patrol penetration into the Depression.
- Confidence classifications are preserved: `High` for `D-M1`, `P-M1`, and `P-P2`; `Moderate` for all remaining episodes; `Low` for none.
- Researcher review completed. All eleven episode summaries are approved after targeted citation and wording corrections. The ledger is approved for Supplementary Table S6B.

## Episodes With Direct Dated Evidence

Direct dated evidence is strongest for:

- `D-M1` and `P-M1`: 28 May 2004 Lusinga attack; roughly two-year FARDC deployment; Gedeon's 16 May 2006 surrender.
- `P-P1`: EU-supported FZS technical assistance began across 2010-2011; July/October 2012 Lusinga raids; 18 December 2012 killing of the park manager.
- `P-M2`: 2013-2014 renewed insecurity; April 2013 Mbwe reporting; 14 March, 4 November, 5 November, and 12 November 2014 Radio Okapi reports.
- `P-P2`: October 2016 Gedeon surrender; late-2016 elephant-protection operation; June 2016 Upemba-Kundelungu Complex; July 2017 formal public-private partnership.
- `D-P1`: late-2016 and early-2017 elephant-protection operations penetrating the Kamalondo Depression; July 2017 formal public-private partnership.

## Boundaries That Rely On Inference

The following boundaries rely on inference from multiple lines of evidence rather than a single dated event:

- 2001 start: imposed by the remote-sensing study window.
- 2007 transition after the first militia-centred episode: follows demobilization, Gedeon's surrender, partial reopening, salary restoration, and residual negotiated coexistence; it does not imply full restoration of park control.
- 2011 Plateau park-centred transition: tied to the start of the FZS technical-assistance phase, but operational strengthening appears gradual across 2010-2011.
- 2013 renewed militia-centred control: supported by 2012-2013 deterioration, Gedeon's escape, Mbwe reporting, and Bakata Katanga activity; the deterioration may have developed across 2012-2013.
- 2016 Plateau park-centred transition: reflects operational strengthening, Gedeon's October 2016 surrender, and complex-level management; 2017 remains a plausible alternative because the formal PPP began then.
- 2017 Depression park-centred transition: reflects spatially delayed operational reach into the Kamalondo Depression after late-2016/early-2017 operations; 2016 remains a plausible alternative.

## Least Certain Transition Years

The least certain transition years are:

- Plateau 2011 start (`P-P1`): technical assistance and operational strengthening began gradually during 2010-2011.
- Depression and Plateau 2013 renewed militia-centred episodes (`D-M2`, `P-M2`): insecurity intensified across 2012-2013.
- Plateau 2016 versus 2017 park-centred transition (`P-P2`): operational strengthening preceded the formal public-private partnership.
- Depression 2017 versus 2016 park-centred transition (`D-P1`): the evidence indicates late-2016 operations, but sustained Depression reach is clearer in early 2017.

These uncertainties are already addressed by the transition-year sensitivity diagnostics and should not change the frozen coding without researcher instruction.

## Different Plateau And Depression Transition Dates

The evidence supports different Plateau and Depression park-centred transition dates:

- The Plateau contains Lusinga and the accessible operational core. FZS technical assistance from 2011 and later 2016 operational strengthening were concentrated first around this core.
- The Depression had weaker and later operational penetration. Evidence for systematic patrol reach into the Kamalondo Depression becomes explicit only in late 2016 and early 2017, especially along the Bukama-Lake Kabwe-Kasale axis and toward Manono and Malemba-Nkulu.

This supports coding the Plateau as park-centred in 2016-2022 and the Depression as park-centred in 2017-2022 while retaining uncertainty notes.

## Source Use By Episode

- `D-F1`, `P-F1`: Hasson 2003; Nouvelles Approches 2002-2004; OKA Kanyundu 2018; Van Leeuwe et al. 2009; Hasson 2015.
- `D-M1`, `P-M1`: Van Leeuwe et al. 2009; Hasson 2015; Nouvelles Approches 2002-2004; Hecht 2006; Human Rights Watch 2006.
- `D-F2`, `P-F2`: Van Leeuwe et al. 2009; Hasson 2015; FZS 2009; OKA Kanyundu 2018; Chief Kayumba 2010.
- `P-P1`: Hasson 2015; Aerden 2012; Hance 2012a; Hance 2012b; Radio Okapi 2012b.
- `D-M2`: OCHA 2013; MONUSCO 2013; Radio Okapi 2013a; Asmani 2015; Ngoy 2015; Huisman 2017; Katembo 2016; Katembo 2017.
- `P-M2`: OCHA 2013; Asmani 2015; MONUSCO 2013; Radio Okapi 2013a; Radio Okapi 2014a-d; Huisman 2017.
- `D-P1`, `P-P2`: Katembo 2016; Katembo 2017; Huisman 2017; d'Huart 2017; Brugiere 2020; Villaespesa 2020; IUCN NL 2021; MONUSCO 2022a-b.

## Researcher Review Status

Researcher review is complete. The frozen annual assignments, episode boundaries, confidence classifications, and corrected evidence summaries are approved.

The ledger is approved for Supplementary Table S6B. No remaining citation issue blocks supplement regeneration.

## Decision

The evidence ledger is approved for Supplementary Table S6B and can be used in the repaired Supplementary Material.
