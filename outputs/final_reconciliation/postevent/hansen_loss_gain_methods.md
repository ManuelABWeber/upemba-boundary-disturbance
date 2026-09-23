# Hansen loss-gain overlap diagnostic

## Scope

This is a measurement diagnostic, not an estimate of post-loss regrowth. Hansen Global Forest Change v1.12 supplies a static gain flag for 2000-2012 and annual loss-year coding. The gain flag has no year, so pixels carrying both flags cannot be temporally ordered.

## Implementation

- Matching v1.12 gain and loss-year tiles were used on their common native grid.
- Native overlap is `gain == 1` and `lossyear` in 1-12 (loss in 2001-2012).
- Native binary loss, gain, and overlap indicators were averaged onto the canonical 500 m grid.
- Cell summaries are restricted to the manuscript's baseline-forest eligibility mask and separately identify cells whose cumulative loss crossed 25% by 2012.
- Any overlap means at least one native Hansen pixel in the 500 m cell carried both flags; threshold summaries at 10%, 25%, and 50% are also retained.

## Interpretation constraint

A loss-gain overlap pixel may represent gain before loss, loss before gain, classification discordance, or multiple changes within the period. It must not be described as confirmed regrowth or recovery, and it does not alter the manuscript estimand of first cumulative mapped-loss threshold crossing.
