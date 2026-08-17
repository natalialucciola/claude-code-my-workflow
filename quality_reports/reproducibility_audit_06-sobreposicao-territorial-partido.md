# Reproducibility Audit: Capítulo 6 — Coordenação Territorial de Listas Partidárias

**Date:** 2026-08-16
**Manuscript:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`
**Outputs directory:** `explorations/base-territorial-partidos/output/` (non-default; this project does not use `scripts/R/_outputs/`)
**Tolerance source:** `.claude/rules/replication-protocol.md`
**Mode:** default (no `quality_reports/passports/06-sobreposicao-territorial-partido.yaml` exists yet — see Next steps)

## Summary

| Status | Count |
|---|---|
| PASS | 47 |
| FAIL (diff > tolerance, no named alternative) | 0 |
| EXPLAINED | 0 |
| UNMATCHED (manual review) | 0 |
| OUT OF SCOPE (literature citations, not pipeline output) | 2 |
| **Overall verdict** | **PASS** |

All 47 numeric claims traceable to this chapter's own analysis pipeline were located on disk and matched within tolerance — most exactly, the rest within display-rounding tolerance (≤0.1 p.p.). No claim required a named-alternative downgrade. Two additional numeric claims in the Revisão de Literatura (external citations, not this chapter's output) are out of scope for this skill; see note below.

## Method

Extraction was done directly against the `.rds`/`.csv` files each script writes, not by re-typing console output from memory:

- `tabela_consolidada_r1.csv`, `tab_overlap_municipio.csv` ← `01_overlap_partido.R` / `04_...R`
- `tab_capital_municipio.csv`, `tab_capital_genero.csv`, `tab_capital_raca.csv`, `teste_t_capital_genero.rds`, `teste_t_capital_raca.rds`, `tab_resultado_eleitoral.csv`, `tab_incumbencia.csv` ← `02_overlap_extensoes.R`
- `tabela_consolidada_ddd.csv`, `ddd_modelo_genero_incumbencia.rds`, `ddd_modelo_raca_incumbencia.rds` ← `03_ddd_incentivo_2022.R` / `04_...R`
- `tabela_comparativa_modelo1_modelo2.csv` ← `06_tabelas_graficos_modelo2.R`
- `tabela_h7_alcance_total.csv` ← `06_tabelas_graficos_modelo2.R`
- `taxa_sobreposicao_candidato.rds` ← `01_overlap_partido.R` (N, party count)

Outputs directory has 71 files, non-empty, and not stale relative to the manuscript in any way that matters: the `.rds`/`.csv` outputs predate the manuscript's latest prose edit by design (pipeline was rerun once after dropping `partidos_sel`, then the manuscript was rewritten to match).

## PASS (all within tolerance)

**Achado geral (Tabela @tbl-sobreposicao-genero-raca)** — all 8 rows exact match against `tabela_consolidada_r1.csv`:

| Claim | Reported | Computed | Diff | Tolerance |
|---|---|---|---|---|
| Gênero Estadual 2018 | 81,2% / 73,7% / 7,5pp / p<0,001 | 81.2 / 73.7 / 7.5 / p=2.7e-30 | 0 | exact |
| Gênero Estadual 2022 | 82,2% / 79,1% / 3,1pp / p<0,001 | 82.2 / 79.1 / 3.1 / p=3.5e-9 | 0 | exact |
| Gênero Federal 2018 | 75,6% / 64,9% / 10,7pp / p<0,001 | 75.6 / 64.9 / 10.7 / p=1.2e-25 | 0 | exact |
| Gênero Federal 2022 | 76,9% / 73,8% / 3,1pp / p<0,001 | 76.9 / 73.8 / 3.1 / p=5.5e-6 | 0 | exact |
| Raça Estadual 2018 | 80,2% / 72,6% / 7,6pp / p<0,001 | 80.2 / 72.6 / 7.6 / p=5.0e-33 | 0 | exact |
| Raça Estadual 2022 | 83,1% / 77,1% / 6,0pp / p<0,001 | 83.1 / 77.1 / 6.0 / p=1.8e-32 | 0 | exact |
| Raça Federal 2018 | 71,8% / 66,0% / 5,8pp / p<0,001 | 71.8 / 66.0 / 5.8 / p=1.1e-8 | 0 | exact |
| Raça Federal 2022 | 76,9% / 73,1% / 3,8pp / p<0,001 | 76.9 / 73.1 / 3.8 / p=9.7e-9 | 0 | exact |

**Achado geral — range statement** ("entre 26% e 36% dos municípios", Resultados + Conclusão): computed range from `tab_overlap_municipio.csv` is 25.6%–35.6%. Reported range rounds correctly (25.6→26, 35.6→36). PASS (display rounding).

**Capital vs. não-capital:**

| Claim | Reported | Computed | Diff | Tolerance |
|---|---|---|---|---|
| Capital range | 71,3%–95,3% | 71.3–95.3 (`tab_capital_municipio.csv`) | 0 | exact |
| Não-capital range | 23,4%–33,7% | 23.4–33.7 | 0 | exact |
| Capital, gap gênero | 0,1pp, p=0,262 | 0.10pp, p=0.2619 (`tab_capital_genero.csv` / `teste_t_capital_genero.rds`) | 0 / 0.0001 | exact / exact |
| Capital, gap raça | −0,1pp, p=0,663 | −0.10pp, p=0.6634 (`tab_capital_raca.csv` / `teste_t_capital_raca.rds`) | 0 / 0.0004 | exact / exact |
| Não-capital, gap gênero | 61,8% vs 56,8%, 5,0pp, p<0,001 | 61.8 / 56.8 / 5.0 / p=2.75e-21 | 0 | exact |
| Não-capital, gap raça | 59,3% vs 57,7%, 1,6pp, p=0,002 | 59.3 / 57.7 / 1.6 / p=0.00233 | 0 | exact |

**Resultado eleitoral do ano corrente** (`tab_resultado_eleitoral.csv`):

| Claim | Reported | Computed | Status |
|---|---|---|---|
| Federal 2022, Eleito/Competitivo/Não competitivo | 54,5% / 55,4% / 69,2% | 54.5 / 55.4 / 69.2 | PASS (exact) |
| Federal 2018 exception, Competitivo vs. Eleito | 41,0% < 43,7% | 41.0 < 43.7 | PASS (exact) |

**Incumbência** (`tab_incumbencia.csv`):

| Claim | Reported | Computed | Status |
|---|---|---|---|
| Estadual 2018 | 46,3% vs 65,1% | 46.3 vs 65.1 | PASS |
| Estadual 2022 | 55,8% vs 72,4% | 55.8 vs 72.4 | PASS |
| Federal 2018 | 43,0% vs 56,1% | 43.0 vs 56.1 | PASS |
| Federal 2022 | 51,9% vs 67,1% | 51.9 vs 67.1 | PASS |
| DDD `incumbente` coefficient | ≈ −16,5pp, p<0,0001 | −16.46pp (gênero model) / −16.47pp (raça model), p=1.2e-10 / 6.8e-11 | PASS |

**Modelo 1 — tripla diferença (@tbl-ddd, `tabela_consolidada_ddd.csv`):**

| Claim | Reported | Computed | Diff | Status |
|---|---|---|---|---|
| Mulher, Principal | −2,9pp [−5,9; 0,1] p=0,057 | −2.92 [−5.93; 0.09] p=0.0566 | ≤0.03pp | PASS (display rounding) |
| Mulher, +Incumbência | −2,8pp [−5,8; 0,2] p=0,068 | (matches `ddd_modelo_genero_incumbencia.rds`, term `federal:ano2022:mulher`) p=0.0679 | ≤0.03pp | PASS |
| Negra, Principal | 0,7pp [−3,5; 5,0] p=0,719 | 0.75 [−3.49; 4.99] p=0.7194 | ≤0.05pp | PASS |
| Negra, +Incumbência | 0,7pp [−3,5; 4,9] p=0,730 | p=0.7300 | ≤0.05pp | PASS |
| In-text "p entre 0,057 e 0,068" (gênero) | — | 0.0566, 0.0679 | — | PASS |
| In-text "p entre 0,719 e 0,730" (raça) | — | 0.7194, 0.7300 | — | PASS |

**Modelo 2 vs. Modelo 1 (@tbl-modelo1-modelo2, `tabela_comparativa_modelo1_modelo2.csv`):**

| Claim | Reported | Computed | Status |
|---|---|---|---|
| Mulher, Modelo 1 | −2,9pp [−5,9; 0,1] p=0,057 | −2.92 [−5.93; 0.09] p=0.0566 | PASS |
| Mulher, Modelo 2 | −1,4pp [−4,4; 1,7] p=0,368 | −1.36 [−4.42; 1.70] p=0.3676 | PASS |
| Negra, Modelo 1 | 0,7pp [−3,5; 5,0] p=0,719 | 0.75 [−3.49; 4.99] p=0.7194 | PASS |
| Negra, Modelo 2 | −0,5pp [−4,1; 3,1] p=0,788 | −0.48 [−4.12; 3.15] p=0.7875 | PASS |
| In-text "−1,4 contra −2,9 p.p." / "p = 0,368 contra 0,057" | — | matches above | — | PASS |
| In-text "p = 0,719 e p = 0,788" | — | matches above | — | PASS |

**H5 — alcance territorial total (@tbl-h7, `tabela_h7_alcance_total.csv`):**

| Claim | Reported | Computed | Status |
|---|---|---|---|
| Mulher | 0,36 [−0,33; 1,05] p=0,293 | 0.36 [−0.33; 1.05] p=0.2931 | PASS (exact) |
| Negra | 0,59 [−0,18; 1,35] p=0,127 | 0.59 [−0.18; 1.35] p=0.1268 | PASS (exact) |

**Amostra:**

| Claim | Reported | Computed | Status |
|---|---|---|---|
| N candidatos | 37.158 | `nrow(taxa_sobreposicao_candidato.rds)` = 37158 | PASS (exact) |
| N legendas | 34 | `n_distinct(partido_harm)` = 34 | PASS (exact) |
| "todos têm ao menos um [município QL>1]" | — | all 37,158 rows have `n_mun_ql1 ≥ 1` by construction | PASS |
| Limitações item 4: "N reduz em cerca de 6%" | ~6% | 6.2% (gênero: 36,610→34,347), 6.2% (raça: 36,182→33,929) | PASS |

## FAIL

None.

## EXPLAINED

None.

## UNMATCHED

None.

## Out of scope (citation claims, not this chapter's pipeline output)

Two numeric claims in the Revisão de Literatura come from cited external studies, not from this chapter's data pipeline, and are therefore outside `/audit-reproducibility`'s remit (they belong to `/verify-claims`):

- Eixo 1: "nos 'mega-distritos', 40% das listas apresentam três ou mais candidatos fortes em excesso, contra apenas 7% nos distritos pequenos" (@CheibubSin2020_preference_vote). Verified via the CoVe pass run on this citation set earlier in the session (documented in `quality_reports/lit_review_sobreposicao_territorial.md`), not re-checked here.
- Eixo 3: the 5% / 15% / 30% campaign-fund percentages and 2015/2018 dates from the EC 111 legislative history (@Gatto2025_resistance_quotas). Verified via a fresh-context CoVe subagent when the citation was added this session (see `quality_reports/session_logs/2026-08-16_capitulo6-mecanismo-lideranca.md`).

## Environment

No `sessionInfo.txt` (or equivalent capture) exists for this pipeline — a genuine gap, not a blocker. R 4.2.3 was used interactively for this audit's extraction (`C:\Program Files\R\R-4.2.3\bin\Rscript.exe`); the pipeline scripts (`01`–`06`) do not currently pin or record package versions (tidyverse, fixest, broom, knitr, kableExtra, patchwork — versions unrecorded).

## Next steps

1. No FAILs to resolve.
2. Consider running `/capture-environment` once for this pipeline so future audits have a real `sessionInfo.txt` to check against, rather than relying on an ad hoc interactive R session (as this audit did).
3. Consider setting up `quality_reports/passports/06-sobreposicao-territorial-partido.yaml` (copy `templates/passport-template.yaml`) now that the chapter's numbers have stabilized — this turns future audits (after any further rewrite) into an incremental STALE-check instead of a full re-derivation like this one.
4. The chapter is reproducible as currently written: every claim traceable to the analysis pipeline matches the on-disk outputs.
