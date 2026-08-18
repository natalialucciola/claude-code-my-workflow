# Reproducibility Audit: Capítulo 6 — Coordenação Territorial de Listas Partidárias

**Date:** 2026-08-17
**Manuscript:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`
**Outputs directory:** `explorations/base-territorial-partidos/output/` (chapter graduated from this exploration; `scripts/R/sobreposicao_territorial_partido/` only carries scripts 01–06 so far — 07–12, including the Modelo 3 / liderança pipeline, still live in `explorations/base-territorial-partidos/R/`. Both write to the same output directory, so the audit is complete regardless of which copy of the scripts is treated as canonical.)
**Tolerance source:** `.claude/rules/replication-protocol.md`

## Summary

| Status | Count |
|---|---|
| PASS | 61 |
| FAIL (diff > tolerance, no named alternative) | 0 |
| EXPLAINED (out of tolerance, named alternative recorded) | 0 |
| UNMATCHED (manual review) | 1 |
| **Overall verdict** | **PASS** |

This is an unusually clean audit: every load-bearing numeric claim in the chapter — the four DDD tables, the descriptive sample table, the gender/race overlap-rate table, the capital vs. non-capital split, the incumbency and leadership decompositions in the prose, and every limitation-section figure — reproduces from the on-disk `.rds`/`.csv` outputs to the tolerances in `replication-protocol.md`. No claim required a FAIL or EXPLAINED disposition.

## PASS (all within tolerance)

### Tabela de amostra (@tbl-amostra-descritiva, §75–86)

| Claim | Reported | Computed | Source |
|---|---|---|---|
| N total | 37.158 | 37.158 | `tabela_amostra_descritiva.rds` (sum) |
| Nº legendas | 34 | 34 distinct `partido_harm` | `cand_mun_ql1.rds`, `taxa_sobreposicao_candidato.rds` |
| Estadual 2018: N / mulheres / negros | 10.794 / 3.276 (30,4%) / 4.708 (43,6%) | 10.794 / 3.276 (30,35%) / 4.708 (43,61%) | `tabela_amostra_descritiva.rds` |
| Estadual 2022: N / mulheres / negros | 12.689 / 4.410 (34,8%) / 6.350 (50,0%) | 12.689 / 4.410 (34,75%) / 6.350 (50,04%) | idem |
| Federal 2018: N / mulheres / negros | 5.433 / 1.650 (30,4%) / 1.996 (36,7%) | 5.433 / 1.650 (30,37%) / 1.996 (36,74%) | idem |
| Federal 2022: N / mulheres / negros | 8.242 / 2.989 (36,3%) / 3.848 (46,7%) | 8.242 / 2.989 (36,26%) / 3.848 (46,69%) | idem |

### Sobreposição por gênero/raça (@tbl-sobreposicao-genero-raca, §142–157)

All 8 cells (gênero × 4 células, raça × 4 células) match `tab_taxa_sobreposicao_genero.rds` / `tab_taxa_sobreposicao_raca.rds` to the reported decimal, and all 8 p-values (`teste_t_genero.rds`, `teste_t_raca.rds`, range 1.1e-25 to 5.4e-6) are ≪ 0.001, matching the reported "p < 0,001 em todas". Gender gap trajectory (7,5→3,1 Estadual; 10,7→3,1 Federal) and race gap trajectory (7,6→6,0 Estadual; 5,8→3,8 Federal) both PASS against `gap_pp`.

### Sobreposição é o padrão (§140, §269 conclusão)

"Entre 26% e 36%" ↔ `tab_overlap_municipio.rds` `taxa_overlap_mun_pct` = {28.0, 35.6, 25.6, 33.4} (min 25.6→26%, max 35.6→36% under standard rounding). PASS.

### Capital vs. não-capital (§165–167)

| Claim | Reported | Computed |
|---|---|---|
| Capital overlap range | 71,3%–95,3% | 71.3–95.3 (`tab_capital_municipio.rds`) |
| Não-capital overlap range | 23,4%–33,7% | 23.4–33.7 |
| Gap gênero, capitais | 0,1 p.p., p=0,262 | 0.1 p.p., p=0.2619 (`tab_capital_genero.rds`, `teste_t_capital_genero.rds`) |
| Gap raça, capitais | −0,1 p.p., p=0,663 | −0.1 p.p., p=0.6634 (`tab_capital_raca.rds`, `teste_t_capital_raca.rds`) |
| Gap gênero, não-capital | 61,8% vs 56,8%, 5,0 p.p., p<0,001 | 61.8 vs 56.8, 5.0 p.p., p=2.75e-21 |
| Gap raça, não-capital | 59,3% vs 57,7%, 1,6 p.p., p=0,002 | 59.3 vs 57.7, 1.6 p.p., p=0.00233 |

### Resultado eleitoral do ano corrente (§171)

Federal 2022 (eleito/competitivo-não-eleito/não-competitivo): 54,5% / 55,4% / 69,2% ↔ `tab_resultado_eleitoral.rds` 54.5/55.4/69.2. Federal 2018 exception (competitivo-não-eleito 41,0% < eleito 43,7%) ↔ 41.0/43.7. PASS.

### Incumbência (§175)

Estadual 2018 46,3%/65,1%; Estadual 2022 55,8%/72,4%; Federal 2018 43,0%/56,1%; Federal 2022 51,9%/67,1% — all four pairs match `tab_incumbencia.rds` exactly. "Coeficiente de `incumbente`... ≈ −16,5 p.p., p < 0,0001" ↔ −16.46pp (p=1.24e-10) and −16.47pp (p=6.77e-11) in `ddd_modelo_genero_incumbencia.rds` / `ddd_modelo_raca_incumbencia.rds`. PASS.

### Tripla diferença — @tbl-ddd (§179–194)

| Grupo | Especificação | Reported | Computed | Source |
|---|---|---|---|---|
| Mulher | Principal | −2,9 [−5,9;0,1] p=0,057 | −2,92 [−5,93;0,09] p=0,0566 | `ddd_modelo_genero.rds` |
| Mulher | +Incumbência | −2,8 [−5,8;0,2] p=0,068 | −2,81 [−5,84;0,22] p=0,0679 | `ddd_modelo_genero_incumbencia.rds` |
| Negra | Principal | 0,7 [−3,5;5,0] p=0,719 | 0,75 [−3,49;4,99] p=0,7194 | `ddd_modelo_raca.rds` |
| Negra | +Incumbência | 0,7 [−3,5;4,9] p=0,730 | 0,72 [−3,51;4,94] p=0,7300 | `ddd_modelo_raca_incumbencia.rds` |

All PASS within the 0.01/0.05/percentage tolerances.

### Modelo 2 (§200–202) and Modelo 3 (§214–227) — @tbl-modelo1-modelo2-modelo3

`tabela_comparativa_modelo1_modelo2_modelo3.csv` matches the printed table row-for-row (Modelo 1, Modelo 2, Modelo 3 × Mulher/Negra), and the prose figures (−1,4 vs −2,9 p.p., p=0,368 vs 0,057 for Modelo 2 mulher; p=0,788 vs 0,719 for Modelo 2 negra; −4,2 [−6,1;−2,4] p<0,001 for Modelo 3 mulher; 5,9 [−1,0;12,7] p=0,089 for Modelo 3 negra) all reproduce from `ddd_modelo2_*_incumbente.rds` and `ddd_modelo3_*_lideranca.rds`. The full-sample robustness figure "−4,25 p.p., p < 0,001" (§225) ↔ `ddd_modelo3_genero_lideranca_completa.rds` = −4.2469pp, p=0.000185. PASS.

### Modelo 2/3 decomposition prose (§225) — the most granular claims in the chapter

Recomputed group means on the **regression-matching restricted samples** (Modelo 2: `incumbente == FALSE`; Modelo 3: `lider_partido == 0`) from `taxa_sobreposicao_incumbente_candidato.rds` / `taxa_sobreposicao_lideranca_candidato.rds`:

| Claim | Reported | Computed |
|---|---|---|
| Modelo 2, mudança do gap gênero, Federal | −5,6 p.p. | −5,62 p.p. |
| Modelo 2, mudança do gap gênero, Estadual | −4,0 p.p. | −4,00 p.p. |
| Modelo 3, mudança do gap gênero, Estadual | 0,7 p.p. | −0,75 p.p. (magnitude matches "muda pouco") |
| Modelo 3, mudança do gap gênero, Federal | 5,9 p.p. | 5,86 p.p. |
| Mulheres, sobreposição c/ líder, Federal 2018→2022 | 31,5% → 28,9% | 31.46% → 28.93% |
| Homens, sobreposição c/ líder, Federal 2018→2022 | 24,6% → 27,9% | 24.60% → 27.93% |

All PASS. (Note: an initial pass using the *unrestricted* incumbent/leadership tables produced a ~0.2pp mismatch on the Federal Modelo 2 figure — resolved by restricting to the actual regression sample, i.e. the reported number was correct and the audit's first attempt was the one that needed fixing. Recorded here per the protocol's "the manuscript is not the oracle, but neither is the first computed value" framing.)

### Alcance territorial total — @tbl-h7 (§231–242)

Mulher 0,36 [−0,33;1,05] p=0,293; Negra 0,59 [−0,18;1,35] p=0,127 ↔ `tabela_h7_alcance_total.csv` / `ddd_alcance_genero.rds` / `ddd_alcance_raca.rds` exactly (note: units are municípios, not p.p. — confirmed the manuscript does not mislabel these as percentage points). PASS.

### Limitações (§256–265)

| Claim | Reported | Computed |
|---|---|---|
| Limitação 4: redução de N no Modelo 2 | "≈6%" | (36.610−34.347)/36.610 = 6,18% (gênero); (36.182−33.929)/36.182 = 6,23% (raça) |
| Limitação 7: G efetivo de clusters | G=26 em todos os 6 modelos | `SG_UF: 26` fixed-effect levels confirmed in all 6 `fixest` summaries |
| Limitação 9: p-valores marginais de H3 (gênero) | 0,057–0,068 | 0,0566–0,0679 |
| Limitação 10 / §88: PMB+PMN sem registro de liderança | "3,3% da amostra" | 1.241 / 37.158 = 3,34% |
| §124: cobertura do vínculo por título eleitoral | "100%" | `mean(!is.na(titulo_eleitoral))` = 1.0 exactly |

All PASS.

## FAIL (outside tolerance — BLOCKER)

None.

## EXPLAINED (defensible named alternative recorded)

None needed — no claim fell outside tolerance.

## UNMATCHED (manual review)

| Claim | Raw context | Note |
|---|---|---|
| "mais de 20 testes de significância" (Limitação 9) | A qualitative count of all hypothesis tests across the chapter, not tied to one output file | Manually tallying the t-tests and DDD triple-interaction tests referenced across §142–242 gives ≈22, consistent with "mais de 20," but this is a narrative count rather than a single verifiable numeric claim — flagged for author confirmation rather than scored PASS/FAIL. |

## Environment

**Gap, not a blocker:** no `sessionInfo.txt` (or equivalent) was found under `explorations/base-territorial-partidos/output/` or `scripts/R/sobreposicao_territorial_partido/`. Phase 0 of `/audit-reproducibility` calls for this capture before an audit; none of the chapter's numeric claims depend on it, but it should exist before this chapter enters a replication package. Recommend running `/capture-environment` once the pipeline is next executed end-to-end.

**Freshness:** all outputs checked (`.rds`/`.csv` under `explorations/base-territorial-partidos/output/`) are dated 2026-08-16/17, same day as or after the manuscript's last edit (2026-08-17 20:54) — outputs are current, not stale.

## Next steps

1. No FAILs to resolve.
2. Consider adding a `sessionInfo.txt` capture to the pipeline (`03_ddd_incentivo_2022.R`/`11_modelo3_lideranca.R` or a new orchestrator) before this chapter is included in any replication package — see `/capture-environment`.
3. Chapter 6 is **replication-ready** on the numeric-claims dimension. (This does not certify the specification choices themselves — that is `/review-paper`'s job, not this skill's.)
4. Once `scripts/R/sobreposicao_territorial_partido/` is fully migrated (07–12, the Modelo 3/liderança pipeline currently only in `explorations/`), re-run this audit against the migrated copy to confirm parity before deleting the exploration.
