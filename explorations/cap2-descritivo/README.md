# cap2-descritivo — Capítulo 2: panorama descritivo, 2014–2026

**Objetivo.** Produzir os dados, tabelas e figuras do Capítulo 2
(`Quarto/thesis/chapters/02-analise-descritiva.qmd`): análise descritiva, sem hipóteses, da
participação de mulheres e negros nas eleições para Deputado Federal e Estadual de 2014, 2018,
2022 e 2026 — candidaturas, eleitos, sucesso e competitividade, financiamento e gasto, votos,
geografia (região/UF, magnitude, base de voto e de gasto) e partidos (maiores partidos e blocos
ideológicos).

**Status:** primeira versão completa (2026-10-13). Financiamento e geografia do gasto vão até
2022 — a prestação de contas de 2026 ainda não foi publicada pelo TSE.

## Ordem de execução (a partir da raiz do repo)

| Script | Faz |
|---|---|
| `R/01_painel_candidaturas.R` | Painel candidato × ano 2014–2026: atributos, votos válidos, eleito/competitivo (regra única, validada contra as bases da autora), geografia do voto, região, magnitude, partido e bloco |
| `R/02_financiamento.R` | Receitas por origem/fonte e gasto por candidatura, 2014–2022 |
| `R/03_geografia_gasto.R` | Base de gasto e gasto na capital, 2018–2022 (QL do gasto do Cap. 6) |
| `R/04_tabelas_figuras.R` | Indicadores (`output/*.csv`), figuras (`Quarto/thesis/Figures/02-analise-descritiva/`) e tabelas Markdown incluídas no capítulo (`Quarto/thesis/chapters/_tabelas-cap2/`) |

Entradas: zips do TSE em `data/raw/tse/` (consulta_cand, votacao_candidato_munzona,
votacao_partido_munzona, consulta_vagas, 2014–2026; ver
`explorations/ql-voto-2026/R/00_baixar_dados_tse.R` para as URLs), prestação de contas em
`data/raw/` e as bases da autora já usadas no Cap. 6. `dados/classificacao_ideologica.csv`
traz a posição de cada partido e a fonte de cada valor.

## Definições principais

- Universo: candidaturas com ≥ 1 voto nominal válido no 1º turno (DF fora no cargo estadual).
- Negros = pretos + pardos; competitiva = eleita ou ≥ 10% do quociente eleitoral da UF.
- Base de voto: QL do voto > 1 e ≥ 2,5% dos votos do candidato (de `explorations/ql-voto-2026`).
- Blocos: posição média 2022 de Bolognesi, Ribeiro, Codato & Silva (2025); esquerda ≤ 4,49,
  centro-direita 5,51–7,0, direita > 7,0; extintos antes de 2022 com a posição de 2018 (2023).
- Magnitude: Federal 8 / 9–18 / 22–70 vagas; Estadual 24 / 27–49 / 54–94 vagas.
