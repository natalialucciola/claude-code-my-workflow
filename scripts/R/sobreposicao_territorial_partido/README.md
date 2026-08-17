# scripts/R/sobreposicao_territorial_partido/

Scripts que produzem os dados, tabelas e figuras do Capítulo 6
(`Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`).

Graduados de `explorations/base-territorial-partidos/` em 2026-08-15. Para o
processo investigativo completo — bugs encontrados e corrigidos, decisões
metodológicas, scripts de diagnóstico de dados (`00_inspect.R` e afins) —
ver `explorations/base-territorial-partidos/SESSION_LOG.md` e `README.md`.

## Ordem de execução

1. `harmonizar_partido.R` — função de harmonização de partidos (fonte)
2. `01_overlap_partido.R` — sobreposição território-partido, nível
   município e candidato; gera `taxa_sobreposicao_candidato.rds`,
   `cand_mun_ql1.rds`, tabelas por gênero/raça (cargo × ano)
3. `02_overlap_extensoes.R` — capital vs. não-capital, resultado eleitoral,
   incumbência (requer `capitais.rds`, `municipios_nomes.rds` em `data/raw/`)
4. `03_ddd_incentivo_2022.R` — tripla diferença (Federal × 2022 × Grupo);
   requer candidaturas/eleitos Federal 2014 (`candidatos2014.rds`,
   `eleitos_2014_df.rds`)
5. `04_tabelas_graficos_consolidacao.R` — tabelas e gráficos finais do
   Modelo 1/amplo (publication-ready, paleta Okabe-Ito)
6. `05_modelo2_incumbente.R` — Modelo 2 (sobreposição especificamente com
   correligionário incumbente, H4) e alcance territorial total (H5); requer
   `incumbencia_completa_candidato.rds` (salvo por `03_...R`)
7. `06_tabelas_graficos_modelo2.R` — tabela/gráfico comparativo Modelo 1 vs.
   Modelo 2, e tabela/gráfico de H5

A amostra cobre o universo completo de partidos presentes nos dados brutos —
um filtro anterior para 8 partidos (`partidos_sel`) foi removido de
`01_overlap_partido.R` por não ter justificativa teórica (ver
`explorations/base-territorial-partidos/SESSION_LOG.md`, 2026-08-16).

## Dados de entrada

Todos em `data/raw/` (política de migração incremental, ver `data/README.md`
na raiz do repo): `ql_gasto_eleit_{2018,2022}.rds`,
`ql_gasto_eleit_est_{2018,2022}.rds`, `candidatos{2014,2018,2022}.rds`,
`candidatos_estadual_{2014,2018,2022}.rds`,
`eleitos_e_compet_est_{2014,2018}_df.rds`, `eleitos_2014_df.rds`,
`capitais.rds`, `municipios_nomes.rds`.

## Saídas

Rodar a partir da raiz do repo — os scripts escrevem em
`explorations/base-territorial-partidos/output/` (local original). As
figuras/tabelas finais usadas no capítulo foram copiadas para
`Figures/06-sobreposicao-territorial-partido/`.
