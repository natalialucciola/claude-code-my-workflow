# Humanize Audit: 06-sobreposicao-territorial-partido.qmd

**Date:** 2026-08-16
**Word count:** ~5,976
**Findings:** 3 (0 HIGH, 1 MED, 2 LOW)

## Per-category summary

| Category | HIGH | MED | LOW |
|---|---:|---:|---:|
| 1. Boilerplate transitions | 0 | 1 | 0 |
| 2. AI-cliché lexicon | 0 | 0 | 0 |
| 3. Em-dash / punctuation | 0 | 0 | 1 |
| 4. Symmetric paragraph shapes | 0 | 0 | 0 |
| 5. Tricolon abuse | 0 | 0 | 0 |
| 6. Hedging stacking | 0 | 0 | 0 |
| 7. "Não apenas X mas também Y" | 0 | 0 | 0 |
| 8. Formulaic openers | 0 | 0 | 1 |
| 9. Hyphenation excess | 0 | 0 | 0 |
| 10. Sycophancy | 0 | 0 | 0 |
| 11. Residual bold-for-emphasis (project-specific) | 0 | 0 | 0 |

## Findings

| Line | Cat | Sev | Current text | Suggested |
|---:|---|---|---|---|
| 55, 126, 151, 189, 195 | 1 | MED | Five instances of the identical "X, **portanto**, Y" slot — e.g. "Não há, portanto, evidência de que...", "H5 não encontra, portanto, evidência de que...", "é, portanto, fraca" | Not a tell individually; the repeated identical syntactic slot 5× in ~6,000 words is a mild machine-cadence signature. Vary 2–3 of the 5 (reposition "portanto", reword, or drop where the causal link is already clear). |
| 17, 71, 81, 95, 130 | 3 | LOW | Five paragraphs use the identical "clause — parenthetical aside —," double-em-dash bracket | Sub-threshold (no paragraph exceeds 3 em-dashes), but the identical bracket shape recurring 5× is a mild repeated tic. Optional: convert 1–2 to parentheses or a subordinate clause. |
| 95 | 8 | LOW | "Esta seção apresenta os resultados em duas partes." — Resultados opens by restating its own structure | Only 1 of 8 sections does this. Optional: open with the empirical claim directly and fold the roadmap into a trailing clause, or drop it (subsection headers already make the structure legible). |

## Concentration

No paragraph accumulates 3+ findings; density is low and scattered. Line 95 (Resultados opener) is the closest concentration point, with one instance each of categories 3 and 8.

## Recommendation

**0 HIGH findings per 1,000 words → cosmetic cleanup only, arguably optional.** No boilerplate connectors, no AI-cliché lexicon, no hedging stacks, no sycophantic framing, no symmetric topic→examples→summary paragraph architecture. Zero residual mid-paragraph bold — all five `**bold**` instances found are legitimate Limitações list-item labels, the one convention explicitly kept. The prior de-AI-ification pass (this session) held.

## Disposition

Both optional fixes applied directly (2026-08-16): varied 3 of 5 "portanto" instances, converted 2 of 5 double-em-dash brackets to parenthetical/subordinate form, and trimmed the line-95 formulaic opener. See chapter diff.
