# Spatial Boundary Falsification Design Revision

## Original Pre-Outcome Design

The first spatial pseudo-boundary falsification design generated symmetric 10 km offset corridors at candidate centers from -60 km to +60 km, excluding pseudo-boundary corridors that crossed the actual park boundary. Candidate validity was evaluated before reading disturbance outcomes. The predeclared rules required representation of both pseudo-sides, both SESUs, every SESU-by-side cell group, adequate total sample size, acceptable side-count balance, spatial continuity, and no obvious truncation by the analysis-area edge.

The original workflow stopped before fitting any outcome model because fewer than three valid inner pseudo-boundaries remained. The completed candidate registry is retained under `analysis_spatial_falsification_dev/` and the validation report records the stop condition.

## Stop Condition

Only two inner candidates passed the pre-outcome support rules: -15 km and -20 km. Deeper park-interior corridors rapidly lost sample size, side balance, SESU coverage, and spatial continuity. The shortage was caused by park-interior geometry and support loss, not by disturbance outcomes.

No pseudo-boundary fire, tree-cover-loss, or agriculture outcome models were fitted under the stopped design.

## Researcher-Approved Revision

The revised design was approved before any pseudo-boundary outcomes were fitted. It keeps the actual 10 km boundary estimand fixed and interprets inner and outer pseudo-boundaries separately:

- Actual boundary: center 0 km, corridor -10 km to +10 km.
- Primary spaced outer falsification set: +20 km, +40 km, +60 km.
- Dense outer sensitivity set: all ten valid outer pseudo-boundaries from +15 km through +60 km.
- Limited inner descriptive checks: -15 km and -20 km.

The primary outer set is evenly spaced, spatially coherent, wholly outside the legal park, and selected without reference to outcomes. The dense outer set describes the outer spatial-gradient curve. The two inner corridors overlap substantially and are not treated as a reference distribution.

## Interpretation

For every offset boundary, the side labels are interior-facing and exterior-facing relative to the offset center. Pseudo-boundary sides are not legal inside/outside park labels. Ranks and percentiles from the pseudo-boundary summaries are descriptive diagnostics, not p-values or permutation tests.
