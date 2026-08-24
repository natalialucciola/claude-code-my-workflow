# Manuscript Review: Coordenação Territorial de Listas Partidárias: Sobreposição de Gasto entre Candidatos do Mesmo Partido

**Date:** 2026-08-16
**Reviewer:** independent substance review (fresh-context agent)
**File:** Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd

## Summary Assessment

**Overall recommendation:** Accept (ready to stand as a dissertation chapter, pending minor-to-moderate revisions — mostly additional paragraphs of discussion, not new analysis)

This chapter asks a sharp, well-motivated question — whether Brazilian parties coordinate the territorial allocation of campaign spending among their own co-partisans, and whether that coordination is selectively protective of "traditional" (incumbent) candidates at the expense of women and Black candidates newly incentivized by EC 111/2021. The three-axis literature review (selective coordination → its geographic signature → partisan gatekeeping of affirmative-action incentives) is genuinely well constructed: each axis motivates the next, and the chapter earns its hypotheses rather than asserting them. Most impressively, the chapter is honest to a fault about its own results — the descriptive finding (H1/H2: women and Black candidates face systematically higher territorial overlap, p<0.001 in all eight cargo×year cells) is robust and clearly the strongest result, while the causal machinery built to explain *why* (H3–H5, the triple-difference tests tied to EC 111) comes back weak-to-null, and the chapter says so plainly, in the Discussion and Conclusion, without hedging into overselling. The comparison to Fonseca, Thomé & Guedes-Neto (2026) is well handled: same identification strategy, congruent direction of null-for-race/marginal-for-gender findings, and the chapter offers two non-exclusive interpretations rather than forcing a single story.

The central weakness is that the causal apparatus is more ambitious than the data can currently support, and several standard threats to that apparatus go unaddressed even though the chapter is otherwise careful about limitations. Two periods with no pre-trend test is flagged, but SUTVA/spillover across cargo within the same party (a party's response to a *federal*-specific fund incentive could still reallocate resources or campaign infrastructure to its state ticket) is never raised, and it would bias the DiD toward the null the chapter actually finds. The cluster-robust inference (party × UF, two-way) is used throughout without ever reporting how many clusters underlie a given model — material given how few distinct parties or UFs are informative in some subsamples. And "incumbência" as a proxy for "candidato tradicional do partido" has a specific, checkable construct-validity gap: a candidate elected under a *different* party in the prior cycle and now running under a new party (legenda-switching, "janela partidária," is common in Brazil) is coded as an incumbent of the *new* party in Model 2, despite having no built-up territorial base there — which could mechanically dilute exactly the effect Model 2 is designed to detect.

None of these are fatal. They're the kind of thing a sharp committee member raises in a defense, and the chapter's own honesty about its null results actually makes them easier to address (a paragraph of discussion per issue would likely suffice, not a redesign). The writing is clear, the tables/figures are polished and self-contained (Okabe-Ito palette, proper CI bars, captions readable without the body text), and the chapter's length is appropriate to its contribution.

## Strengths

1. **Unusual honesty about null/weak causal results.** The Discussion and Conclusion state plainly that H3–H5 do not confirm the leadership-protection mechanism, that the H4/H5 signals actually move in the *wrong* direction relative to what the mechanism predicts (Modelo 2 weaker than Modelo 1 for women), and that the strong result is purely descriptive (H1/H2). This is exactly the right epistemic posture and is rare enough to call out explicitly as a strength.
2. **Literature review that builds toward the hypotheses rather than decorating them.** Eixo 1→2→3 is a genuine argument chain: selective coordination (Cheibub & Sin) → it has a spatial mechanism (Silotto; Silva & Silotto) → parties have used exactly this kind of selective protection before, including in the legislative history of EC 111 itself (Gatto 2025). The chapter is honest that Eixo 2's two competing accounts of *why* territorial allocation is non-random don't need to be resolved for its purposes — a mature move.
3. **Methodological correction visible in the pipeline, not swept under the rug.** The session log (`explorations/base-territorial-partidos/SESSION_LOG.md`, 2026-08-16) shows the author caught an unjustified 8-party filter, removed it, and reran the full pipeline on the 34-party universe — which *flipped* the sign of the race coefficient in Modelo 1 (from significant −5.4pp to null +0.7pp). The chapter reports only the corrected, more defensible specification. That's the right call, and doing it before finalizing the chapter (rather than after review flagged it) is a good sign about the rest of the pipeline's integrity.
4. **Deliberate, well-argued choice of spending (QL) over votes as the overlap metric** (Dados e Métodos, "A escolha de medir concentração via gasto de campanha..."): spending is a decision variable, votes are an outcome contaminated by things outside campaign control. This is a genuinely useful methodological point, argued rather than asserted.
5. **Tables and figures are self-contained and publication-quality.** Verified `grafico_ddd_coeficientes.png` directly: clean coefficient plot, Okabe-Ito colors, 95% CI bars, a caption that states the p-value range without requiring the reader to cross-reference the text. All five referenced figures exist on disk and match the chapter's cross-references.

## Major Concerns

### MC1: SUTVA/spillover across cargo within the same party is never addressed
- **Dimension:** Identification Strategy
- **Issue:** The DiD treats Deputado Estadual as a clean, unaffected control group because EC 111's vote-doubling rule applies only to Deputado Federal. But party treasuries, coalition structures, and campaign infrastructure (consultants, digital operations, joint rallies) are frequently shared across a party's federal and state tickets in the same election cycle. If a party's aggregate financial position improves because of the federal-specific incentive, that could plausibly loosen resource constraints or shift *coordination effort* for the state ticket too — contaminating the "control" group with a diluted version of treatment. This would bias the estimated triple-difference toward zero, which is directionally exactly what the chapter finds. The chapter never raises this as a candidate explanation for its null results, alongside "the mechanism doesn't operate" and "the dependent variable is too noisy" — leaving out a third, identification-level explanation for the same pattern.
- **Suggestion:** Add a paragraph to Limitations (or Discussion) naming this threat explicitly and, if feasible, offering an indirect check — e.g., whether the raw (non-triple-differenced) overlap trend for Estadual candidates changed differentially in parties that also fielded strong Federal candidates in 2022 vs. parties that did not.
- **Location:** Dados e Métodos (Modelo 1 spec), Limitações

### MC2: Number of clusters is never reported, and is likely too small for reliable cluster-robust SEs in some subsamples
- **Dimension:** Econometric Specification
- **Issue:** All models cluster two-way on `partido_harm` + `SG_UF` (confirmed in `03_ddd_incentivo_2022.R`, `05_modelo2_incumbente.R`). The chapter states the full sample has 34 legendas and implicitly ~27 UFs, but for two-way clustering the *effective* number of clusters is bounded by the smaller dimension, and no model-specific cluster count is ever reported in text or tables. With the historical 8-party filter, this was a much sharper problem (confirmed by the session log — that specification flipped sign entirely on removal); the 34-party universe is better, but is still in the range where cluster-robust SE asymptotics are commonly considered fragile (conventional rules of thumb suggest ≥40–50 clusters for comfort), especially once a subsample like Modelo 2 (non-incumbents only, restricted further) is considered.
- **Suggestion:** Report the number of distinct partido/UF clusters actually entering each estimation sample (a one-line addendum per table would do), and run at least one specification with a wild cluster bootstrap (e.g., `fwildclusterboot`) as a robustness check on the H3/H4 p-values that sit near conventional significance thresholds (p=0.057–0.068), since that's precisely where small-cluster bias in coverage would matter most for the reader's inference.
- **Location:** Modelo 1 spec, Tabela @tbl-ddd, Tabela @tbl-modelo1-modelo2

### MC3: "Incumbência" ignores party-switching, which may bias Modelo 2 toward the null it reports
- **Dimension:** Identification Strategy / Construct Validity
- **Issue:** Confirmed in `03_ddd_incentivo_2022.R` (lines 178–184): incumbency is defined purely by whether a candidate's CPF appears among the prior cycle's winners for the same cargo, with no check on whether that candidate is running under the *same* party this cycle. Since `05_modelo2_incumbente.R` then computes overlap against "correligionário incumbente" using the *current* party (`partido_harm`), a candidate who switched parties between cycles is coded as an "incumbente" of their *new* party in Modelo 2 — despite having no accumulated territorial base there, which is precisely the construct the proxy is meant to capture ("candidato tradicional do partido"). Party-switching ("janela partidária") is common enough in Brazilian politics that this is not a corner case. This matters because it offers a competing, purely measurement-driven explanation for Modelo 2's attenuated/null result (H4) that the Discussion doesn't consider.
- **Suggestion:** At minimum, note this as an explicit limitation alongside the existing "Amostra do Modelo 2" limitation. If time allows, a robustness run restricting "incumbente" to candidates who are incumbents *and* stayed in the same party across cycles would directly test whether this measurement issue is driving the attenuation.
- **Location:** Modelo 2 spec, Modelo 2 results discussion

### MC4: Multiple hypothesis tests across the chapter are never acknowledged as a family
- **Dimension:** Econometric Specification
- **Issue:** The chapter reports roughly two dozen significance tests across H1/H2 (8 cells), capital/non-capital (4+ tests), resultado eleitoral, incumbência, Modelo 1 (4), Modelo 2 (4, plus 4 robustness), and H5 (2) — with no discussion of the multiple-comparison landscape. This matters most for the chapter's single most consequential "positive" causal claim: the marginal H3 gender result (p=0.057–0.068). Read in isolation it looks like a near-miss; read against ~20 tests conducted across the chapter, a borderline p-value in that neighborhood is not obviously distinguishable from a look-elsewhere artifact.
- **Suggestion:** Doesn't require a full FDR correction across every descriptive test, but the chapter should explicitly flag, in Limitations or the H3 results paragraph, that the marginal gender signal sits inside a large family of tests — consistent with, and would strengthen, the chapter's already-cautious "sugestivo, mas não conclusivo" framing.
- **Location:** A tripla diferença (§sec-ddd), Limitações

## Minor Concerns

### mc1: Hypothesis numbering drifted between the R pipeline and the chapter
- **Issue:** The chapter's H4/H5 are labeled H6/H7 in `05_modelo2_incumbente.R`'s comments. The chapter text itself is internally consistent (H1–H5), so this doesn't affect a reader of the .qmd, but will confuse anyone tracing a claim back into the replication code.
- **Suggestion:** Update the comment headers in `05_modelo2_incumbente.R` to match the chapter's final H1–H5 scheme.

### mc2: Threshold sensitivity (QL>1) is flagged as a limitation but never even spot-checked
- **Issue:** Limitations correctly flags the QL>1 threshold as arbitrary and untested at alternative values. Since `QL_gasto_eleit` is already computed, a single alternative-threshold robustness run is a low-cost addition.
- **Suggestion:** If time allows, add one robustness row (QL>1.5); if not, note in the limitation why QL>1 was chosen rather than leaving it unmotivated.

### mc3: Some redundancy between Tabela @tbl-ddd and Tabela @tbl-modelo1-modelo2
- **Issue:** The "Principal (sem controles)" rows of @tbl-ddd are numerically identical to the "Modelo 1 (amplo)" rows of @tbl-modelo1-modelo2 — presumably intentional for self-containment, but a reader sees the same four numbers twice within a few paragraphs.
- **Suggestion:** Either merge with a footnote, or add a one-line note that the repetition is purposeful (direct comparison), not redundant.

### mc4: The causal chain from "territorial spending overlap" to "threatened personal vote share" is asserted, not fully unpacked
- **Issue:** The mechanism implicitly relies on Brazil's open-list rule (individual vote rank determines who wins a party's seats) — correct and plausible given Eixo 1's discussion of Cheibub & Sin's threshold discontinuity, but never spelled out in one place.
- **Suggestion:** One or two sentences in Hipóteses or Dados e Métodos connecting "spending overlap in the same município" explicitly to "risk to individual vote rank within the list, not to the party's total seat count."

## Referee Objections

### RO1: If a party's federal and state campaigns share resources, doesn't the "control group" (Estadual) absorb some of the treatment, biasing your triple-difference toward the null you found?
**Why it matters:** This is the single most direct alternative explanation for the chapter's central puzzle — strong descriptive gaps (H1/H2) but weak-to-null causal signal (H3–H5).
**How to address it:** Add explicit discussion of this threat (MC1). If any proxy for shared campaign infrastructure exists, a falsification check could partially address it; otherwise acknowledge it as an untestable but real threat.

### RO2: With ~34 party clusters and ~27 UF clusters (likely fewer effective clusters in restricted subsamples), how much of the p=0.057 "marginal" gender signal survives a wild cluster bootstrap?
**Why it matters:** The chapter's one near-positive causal finding sits exactly at the p-value range where small-cluster bias in cluster-robust SEs is most likely to matter.
**How to address it:** Run `fwildclusterboot` (or equivalent) on the H3/H4 gender specifications and report the bootstrapped p-value alongside the analytic one.

### RO3: If you excluded party-switching incumbents from your "correligionário incumbente" definition in Modelo 2, would the result change?
**Why it matters:** The chapter interprets Modelo 2's weaker-than-Modelo-1 result as evidence *against* the leadership-protection mechanism, but this could be a measurement artifact (MC3) rather than a real absence of the mechanism.
**How to address it:** A robustness run restricting incumbency to same-party-across-cycles candidates would directly test this alternative explanation.

### RO4: Given only two periods, how would you distinguish "no pre-trend violation" from "we simply cannot test it"? Is there any indirect evidence that Federal and Estadual overlap were on parallel trajectories before 2018?
**Why it matters:** The entire causal architecture rests on Federal-vs-Estadual comparability absent EC 111, and the chapter offers no basis, even indirect, for judging how plausible that is.
**How to address it:** If any proxy exists for pre-2018 territorial behavior (e.g., 2014 candidacy/vote data, already partly used for incumbency), even a crude placebo would be informative context, clearly labeled as an imperfect substitute. If infeasible, say explicitly why.

### RO5: Eixo 1 argues vote-pooling makes territorial overlap essentially costless at the party level — doesn't that create tension with the idea that parties would bother steering incentivized candidates away from incumbents' territory at all?
**Why it matters:** If overlap is genuinely low-cost collectively, the ex ante case for why leadership would invest effort in protecting incumbents geographically (rather than just tolerating overlap, per Ames/Nemoto & Shugart's baseline) needs to be sharper. The chapter's own null H3–H5 results are also consistent with this being a non-issue for parties in the first place.
**How to address it:** Strengthen the explicit link (mc4) between geographic overlap and *individual* vote-rank risk, distinguishing it clearly from the aggregate vote-pooling logic that governs the party's total seat count.

## Summary Statistics

| Dimension | Rating (1-5) |
|---|---|
| Argument Structure | 4 |
| Identification | 3 |
| Econometrics | 3 |
| Literature | 4 |
| Writing | 5 |
| Presentation | 4 |
| **Overall** | 4 |
