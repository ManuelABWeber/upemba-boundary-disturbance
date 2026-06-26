# Final Repository Validation

Overall status: passed with render-QA limitation.

- PASS: No active supplementary Figure S4 or obsolete historical Figure S3 references
- PASS: Exactly three supplementary PNG figure outputs - Figure_S1_clustering_diagnostics.png, Figure_S2_threshold_spatial_sensitivities.png, Figure_S3_pairwise_pseudo_boundary_diagnostic.png
- PASS: Exactly three supplementary PDF figure outputs - Figure_S1_clustering_diagnostics.pdf, Figure_S2_threshold_spatial_sensitivities.pdf, Figure_S3_pairwise_pseudo_boundary_diagnostic.pdf
- PASS: Pairwise pseudo-boundary diagnostic is Figure S3
- PASS: Former historical Figure S3 output absent
- PASS: Table S13 present with locked columns
- PASS: Fragmented-control fire Sign retained is No
- PASS: Locked event total Fire - events=['508320']
- PASS: Locked event total Tree-cover loss - events=['519']
- PASS: Locked event total Agricultural expansion - events=['518']
- PASS: Supplement manifest paths exist
- PASS: Locked title present in Chapter1_manuscript_final.docx
- PASS: No Figure S4 in Chapter1_manuscript_final.docx
- PASS: Locked title present in Chapter1_Supplementary_Material_final.docx
- PASS: No Figure S4 in Chapter1_Supplementary_Material_final.docx
- FAIL: DOCX visual render QA completed - LibreOffice/soffice unavailable to render_docx.py; structural DOCX checks completed instead.
- PASS: No candidate staged/untracked file >= 50 MiB
- PASS: Credential pattern scan reviewed - No credential values found; hits are ignore patterns, documentation, or renv bootstrap token variable names.

## Notes

- The development repository was not modified or cleaned; it remains the private provenance archive.
- DOCX render/page-image inspection could not be completed because no LibreOffice/soffice executable was found.
- Historical transition-year and episode-omission diagnostics are retained in Table S13 only.
