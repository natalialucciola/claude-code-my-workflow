# scripts/R/sobreposicao_territorial_partido/

Scripts que produzem os dados, tabelas e figuras do Capítulo 6
(`Quarto/thesis/chapters/05-sobreposicao-territorial-partido.qmd`).

Graduados de `explorations/base-territorial-partidos/` em 2026-08-15 (01–06)
e 2026-08-17 (09–12, pipeline do Modelo 3). Para o processo investigativo
completo — bugs encontrados e corrigidos, decisões metodológicas, scripts de
diagnóstico de dados (`00_inspect.R` e afins) — ver
`explorations/base-territorial-partidos/SESSION_LOG.md` e `README.md`.

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
8. `07_titulo_eleitoral_2018_2022.R` — baixa `NR_TITULO_ELEITORAL_CANDIDATO`
   via `electionsBR` (não estava em `data/raw/candidatos*.rds`); chave de
   vínculo necessária para o Modelo 3
9. `08_lideranca_partido.R` — liderança formal do partido (presidente,
   vice-presidente, secretário de finanças; nacional/estadual/DF) a partir
   do SGIP/TSE (`raw_tse_orgaos/orgao_partidario.zip`); vincula a
   candidatos via título eleitoral
10. `09_modelo3_lideranca.R` — Modelo 3 (sobreposição especificamente com
    correligionário líder formal do partido, H4 medido de forma mais
    precisa que a incumbência do Modelo 2 — imune a troca de partido entre
    ciclos)
11. `10_tabelas_graficos_modelo3.R` — tabela/gráfico comparativo Modelo 1 vs.
    Modelo 2 vs. Modelo 3

A amostra cobre o universo completo de partidos presentes nos dados brutos —
um filtro anterior para 8 partidos (`partidos_sel`) foi removido de
`01_overlap_partido.R` por não ter justificativa teórica (ver
`explorations/base-territorial-partidos/SESSION_LOG.md`, 2026-08-16).

## Scripts intencionalmente NÃO migrados

`explorations/base-territorial-partidos/R/07_versao_b_universo_completo.R` e
`08_grafico_versaoB.R` calculavam uma "Versão B" (robustez de seleção de
partidos) que, desde a sessão de 2026-08-16, passou a ser a única versão do
capítulo (01–06 já rodam sobre o universo completo) — marcados SUPERSEDED no
`SESSION_LOG.md` da exploração e mantidos apenas lá, como registro histórico
da checagem de robustez, não como parte do pipeline ativo.

## Dados de entrada

Todos em `data/raw/` (política de migração incremental, ver `data/README.md`
na raiz do repo): `ql_gasto_eleit_{2018,2022}.rds`,
`ql_gasto_eleit_est_{2018,2022}.rds`, `candidatos{2014,2018,2022}.rds`,
`candidatos_estadual_{2014,2018,2022}.rds`,
`eleitos_e_compet_est_{2014,2018}_df.rds`, `eleitos_2014_df.rds`,
`capitais.rds`, `municipios_nomes.rds`.

Exceção: o snapshot bruto do SGIP/TSE usado por `08_lideranca_partido.R`
(`orgao_partidario.zip`, ~209 MB, baixado em 2026-08-16) permanece em
`explorations/base-territorial-partidos/output/raw_tse_orgaos/` — grande
demais para `data/raw/` sob a mesma disciplina de arquivos leves usada pelos
`.rds` acima, e já `.gitignore`d nesse local. Ver cabeçalho de
`08_lideranca_partido.R` para a URL de origem e a data do snapshot.

## Saídas

Rodar a partir da raiz do repo — os scripts escrevem em
`explorations/base-territorial-partidos/output/` (local original). As
figuras/tabelas finais usadas no capítulo foram copiadas para
`Figures/05-sobreposicao-territorial-partido/`.
