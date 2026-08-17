# Claim Verification (CoVe): Capítulo 6 — Coordenação Territorial de Listas Partidárias

**Date:** 2026-08-16
**Draft:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`
**Method:** Two independent, fresh-context verifiers (never saw the draft — only the extracted claim↔citation pairs and the source PDFs), covering every citation-attribution pair in the Revisão de Literatura, Discussão, and Limitações. Verifier A: Eixo 1–2 sources. Verifier B: Eixo 3 sources (including Gatto 2025, which had already passed an earlier CoVe round before the chapter's prose was rewritten twice since).

**Claims reviewed:** 20 (A1–A8, including A6a/A6b; B1–B6d, including B5a/B5b/B5c)

**Outcome: FAIL at first pass (2 HIGH-WARN) → corrected → PASS.**

## Tier counts (first pass, before correction)

| Tier | Count |
|---|---|
| HIGH-WARN | 2 |
| MED-WARN | 1 |
| LOW-WARN | 2 |
| Clean (no discrepancy) | 15 |

## HIGH-WARN — corrected in the chapter

- **B5c** — the chapter claimed @FonsecaThomeGuedesNeto2026_money_talks find a significant effect of the EC 111 incentive on both **votes and seats** for women. The paper's own Table 1 shows a significant effect on votes only (β=0.044, p<0.05); the effect on seats/elected share is not significant (β=−0.014, ns) — the paper's own discussion states this explicitly ("received more votes, but not enough to increase their seat share"). **Fixed**: Discussão now says "aumento significativo de votos para mulheres, sem efeito significativo sobre cadeiras conquistadas por elas."
- **B5b** — the chapter claimed parties increased both votes and campaign funds for Afro-Brazilian candidates. The paper finds neither effect significant for that group (votes: β=0.029, ns; funding: ns) — only the **share of Afro-Brazilian candidacies nominated** rose significantly (+5.3%, p<0.05). **Fixed**: Eixo 3 now attributes the votes/funding increase to women specifically, and the nomination-share increase to Afro-Brazilian candidates, while keeping the "both groups nominated non-competitively" mechanism (independently confirmed true for both groups).

## MED-WARN — corrected

- **A2** — the chapter attributed to @Ames2012_estrategia_eleitoral both halves of a claim: (1) leaders discourage poaching allied parties' redutos to protect the coalition's D'Hondt seat share — confirmed in the source; and (2) leaders lack the same incentive to coordinate their *own* party's candidates because any personal vote adds to the party total — not found asserted anywhere in Ames (2012); this is vote-pooling logic that belongs to Nemoto & Shugart (2013), already cited in the next sentence and independently confirmed there. **Fixed**: reattributed the second half to @NemotoShugart2013_localism / @Shugart2005_looking_locals, where it's actually supported.

## LOW-WARN — one corrected, one left as-is

- **A5** — "com forte heterogeneidade partidária" overstates @Gelape2024_padroes_espaciais's finding: only PSOL stands out as more dispersed; PSDB, PT, and DEM do not differ statistically from each other. **Fixed**: softened to "um padrão mais acentuado em alguns partidos do que em outros."
- **A8** — @SilvaSilotto2018_preparing_terrain's abstract-level framing (regionalization as structural consequence, not strategic choice) is accurately represented; the verifier's nuance is that the paper's own Discussion section also allows for a strategic reading. Left as-is — the chapter's sentence matches the paper's central, abstract-level thesis, and the softer nuance doesn't change what's asserted.

## Clean (no discrepancy)

A1, A3, A4, A6a, A6b, A7 (Eixo 1–2); B1, B2, B3, B4, B6a, B6b, B6c, B6d (Eixo 3, including all four Gatto 2025 sub-claims — re-confirms the earlier CoVe round survived two rounds of prose rewriting intact).

## Post-correction status

All edits applied directly to `06-sobreposicao-territorial-partido.qmd`. `quarto render` confirmed clean (0 citation/reference errors) after the fixes. No further HIGH-WARN outstanding — chapter is CoVe-clean as of this audit.

## Next steps

- None blocking. If the chapter's prose is substantially rewritten again, re-run `/verify-claims` — this session's two rounds of "de-AI-ification" editing are exactly what let the B5b/B5c errors drift in (a paraphrase simplified "votes only" into "votes and seats" during a rewrite pass, not at initial drafting).
