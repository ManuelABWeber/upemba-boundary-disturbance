# Authoritative Analysis Specification

Study period: 2001-2022.

Primary spatial design: symmetric 10 km park-boundary corridor. Landscape-scale sensitivity: all cells.

Primary threshold: tau025.

Fire: harmonized 2001-2022 series, FireCCI 2001-2020, local monthly JD reconstruction 2021-2022, DOY 100-300, native seasonal binary, 500 m mean burned fraction, and BFGS_refined final 10 km optimizer.

Tree-cover loss: tau025, 2000 tree-cover eligibility >=30%, SESU-year two-stage contrast model.

Agriculture: tau025, SESU-year two-stage contrast model, support-sensitive secondary outcome.

Governance: categorical territorial-control profiles; ordinal scores deprecated.

Falsification: +20/+40/+60 km primary spaced outer, +15 through +60 km dense outer gradient, and -15/-20 km descriptive inner checks.
