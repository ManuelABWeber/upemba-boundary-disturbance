# Figure Layout Revision V2

This revision preserves the validated scientific values and authoritative inputs from the first publication render and changes only figure layout, display wording, legends, dimensions, table wording, and output validation.

## Display Changes

- Preserved the first-render outputs under `outputs/publication/review_v1/` and `reports/publication_outputs/review_v1/`.
- Applied the shared profile palette: Fragmented control `#777777`, Militia-centred control `#D55E00`, Park-centred control `#0072B2`.
- Applied shared profile shapes across Figures 2-4.
- Rebuilt Figure 1 in longitude/latitude display coordinates, removed easting/northing labels, simplified the corridor legend, and added direct landscape labels.
- Rebuilt Figure 2 as a four-row by two-column chronology and trajectory layout, with one shared profile legend and one park-side legend.
- Rebuilt Figure 3 as two vertically stacked panels with shorter panel labels and supported horizontal interval geometry.
- Rebuilt Figure 4 to distinguish inner checks, the legal boundary, and outer pseudo-boundaries with restrained background regions and shorter classification labels.
- Replaced Table 2 with a six-column evidence-synthesis table.
- Replaced the deprecated horizontal error-bar layer with `geom_errorbar(orientation = "y")`.
- Contact sheet generated: no; `magick` was not available.
