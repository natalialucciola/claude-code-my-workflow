# Plano: Capítulo — Emendas parlamentares, gênero, raça e retorno eleitoral

**Status:** DRAFT
**Spec:** [`quality_reports/specs/2026-11-25_emendas-genero-raca.md`](../specs/2026-11-25_emendas-genero-raca.md)

---

## Estrutura de arquivos proposta

```
data/                         # (gitignored) brutos e intermediários
  raw/{transparencia,transferegov,fns,tse,ibge,camara}/
  derived/
scripts/R/emendas/
  00_download.R               # coleta automatizada (APIs/CSV oficiais)
  01_clean_emendas.R          # padroniza autor, RP, função, valores pagos, deflator
  02_locate_municipio.R       # imputação de localidade (Transferegov/FNS) + log de perdas
  03_clean_tse.R              # candidatos (gênero, raça, ID entre ciclos), votação por município
  04_build_panels.R           # painéis A (dep×ano×função), B/C (dep×mun×legislatura)
  10_A_composicao.R
  20_B_geografia.R
  25_B_rdd_prefeito.R
  30_C_retorno_fe.R
  31_C_timing_pagamento.R
  32_C_shiftshare.R
  40_robustez.R
  _outputs/{tables,figures}/
Chapter/
  capitulo_emendas.tex        # \input{} das tabelas em scripts/R/emendas/_outputs/
```

## Esqueleto do capítulo

1. **Introdução** — o paradoxo: mais acesso a recursos discricionários (orçamento impositivo, emendas Pix) e persistente sub-representação de mulheres e negros(as). Contribuição em três frentes (o quê / onde / retorno).
2. **Emendas no Brasil: instituições e mudanças 2015–2026** — EC 86/2015, EC 100/2019, transferências especiais (EC 105/2019), RP9 e STF (2022), regras de rastreabilidade recentes.
3. **Teoria** — representação substantiva × conexão eleitoral; redes de intermediação local; atribuição de crédito com viés de gênero/raça. Hipóteses A, B, C.
4. **Dados e medidas** — fontes, localização, raça autodeclarada, valores pagos.
5. **Com o quê** — resultados Bloco A.
6. **Onde** — resultados Bloco B (+ RDD prefeito).
7. **Retorno eleitoral** — Bloco C, estratégias 1–3, heterogeneidade.
8. **Discussão** — desigualdade no retorno do *pork* como mecanismo de reprodução da sub-representação; implicações para regras de emendas.
9. **Conclusão** + apêndice de robustez e dados.

## Etapas (ordem de execução)

| # | Etapa | Saída | Skill útil |
|---|---|---|---|
| 1 | Resolver os 3 itens BLOCKED da spec | spec APPROVED | `/interview-me` |
| 2 | Revisão de literatura dirigida | `quality_reports/lit_review_emendas.md` + `.bib` | `/lit-review`, `/verify-claims` |
| 3 | Pré-registro leve das hipóteses C | `quality_reports/preregistrations/` | `/preregister` |
| 4 | Coleta e limpeza (00–04) | painéis em `data/derived/` | `/data-analysis` |
| 5 | Descritivos A e B | figuras-âncora 1 e 2 | `/data-analysis`, `dataviz` |
| 6 | Identificação C | tabelas principais | `/data-analysis`, `/diagnose` |
| 7 | Redação | `Chapter/capitulo_emendas.tex` | — |
| 8 | Revisão | relatório de revisão | `/review-paper --peer`, `/audit-reproducibility`, `/humanize` |

## Verificação

- Toda tabela do capítulo gerada por script (nenhum número digitado à mão).
- `/audit-reproducibility` PASS antes de circular o texto.
- Log de perdas de localização por grupo reportado no apêndice.
