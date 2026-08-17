# Agricultural persistence methods

The annual AFCD binary stack for 2000-2022 was aggregated to the canonical 500 m grid by averaging native binary cropland presence. The reconstructed first transition from below 25% to at least 25% was required to reproduce the canonical event-year raster exactly before any persistence result was accepted.

The primary post-event classification uses the predeclared rule: persistent means at least 25% cropland in at least two of the next three observed years, including at least one of years +1 or +2. Transient/reversed means below 25% in both +1 and +2. Other threshold alternation is intermittent. Events after 2020 are right-censored because fewer than two post-event years remain.

Persistent first establishment is the first below-to-at-least-25% transition satisfying that same future-persistence rule. Its boundary model uses the final primary 10 km risk set, Haldane-Anscombe correction, inverse-variance weighting, and HC3 covariance. The model is fitted only if there are at least 30 events overall and at least five events under every governance profile.

A decline below the mapped cropland threshold is a classification reversal, not proof of agricultural abandonment, ecological recovery, or forest regrowth.
