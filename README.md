# Upemba boundary disturbance: code and retained results

This public repository contains code and retained analytical results for comparisons of fire, tree-cover loss and agricultural expansion across Upemba National Park's legal boundary during 2001–2022. An independently reconstructed chronology distinguishes fragmented, militia-centred and park-centred territorial control. Outer pseudo-boundaries assess whether comparable contrasts occur elsewhere in the sampled landscape; these comparisons do not establish a causal effect of protection.

## Current code release

The [code-2026-09-23 release](https://github.com/ManuelABWeber/upemba-boundary-disturbance/releases/tag/code-2026-09-23) brings the already-public final-reconciliation analyses onto the default branch, clarifies reproduction instructions, adds reuse licences and supplies a renderer for the combined legal/outer-boundary contrast plot.

This update publishes code and results already present on the public final-reconciliation branch. It does not add the current unpublished manuscript, supplement, newly rendered figure files, title page or cover letter. Older document and figure snapshots already in the public repository remain historical records, not the current submission version.

The primary 10 km corridor contains 42,554 cells. Retained totals are 508,320 burned cell-years, 519 tree-cover-loss events and 518 agricultural first crossings. Corrected persistence uses candidate years 2001–2019 and retains 414 events; the older 431-event result is superseded. Agricultural spatial-bootstrap intervals, annual presence and follow-up diagnostics are under outputs/final_reconciliation/. First crossing, persistent establishment and annual presence measure different responses.

## Finding the files

| Location | Role |
|---|---|
| scripts/, config/, renv.lock | Analysis/publication code, specifications and original R environment |
| data/manifests/ | Required external inputs, recorded checksums and restoration instructions |
| data/governance_profiles/, evidence/ | Coded chronology and documentary-evidence metadata |
| Four top-level analysis_*_dev/ directories | Retained analytical snapshots used by publication code; the suffix does not mean disposable files |
| outputs/final_reconciliation/ | Corrected agricultural analyses, bootstrap results, post-event diagnostics and rainfall/fire data |
| tests/ | Frozen-result and agricultural follow-up/reconciliation checks |
| outputs/publication/, outputs/submission_review/ | Previously public historical layouts and review copies; not a current submission bundle |

## Reproduce and inspect

Start with [RUN_ANALYSIS.md](RUN_ANALYSIS.md) and the [release validation record](docs/submission/validation/code-release-2026-09-23.md). Retained-result checks and the combined contrast renderer use committed data. A complete analysis rerun additionally requires the external raster/spatial inputs in the manifests and the original environment in renv.lock. A fresh clone alone does not reproduce every upstream analysis.

Original historical documents, private operational evidence, raw imagery and local configuration are not distributed. Older handovers describe the state at their dates; their former private-repository statements and historical figure/table numbering do not describe this code release.

## Reuse and citation

Original code is under the [MIT licence](LICENSE). Original research data, figures and documentation already distributed here are under [CC BY 4.0](LICENSE_CONTENT.md). Third-party materials retain their own terms; see [third-party notices](THIRD_PARTY_NOTICES.md). Cite the code release using [CITATION.cff](CITATION.cff). No DOI or journal acceptance is claimed.
