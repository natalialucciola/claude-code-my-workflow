# ==============================================================================
# Script: 03_geografia_gasto.R
# Purpose: Geografia do gasto por candidatura, 2018 e 2022, a partir das bases de
#          QL do gasto usadas no Capítulo 6 (ql_gasto_eleit*.rds). Em 2014 as
#          despesas não identificam o município; 2026 aguarda a prestação de contas.
#   - n_mun_com_gasto:   municípios com gasto > 0
#   - n_mun_base_gasto:  municípios com QL do gasto > 1 (base, como no Cap. 6)
#   - pct_gasto_capital: fatia do gasto feita na capital da UF
#   - pct_gasto_maior_mun: fatia do gasto no município de maior gasto
#
# Inputs:  data/raw/ql_gasto_eleit_{2018,2022}.rds, ql_gasto_eleit_est_{2018,2022}.rds,
#          data/raw/capitais.rds
# Outputs: explorations/cap2-descritivo/output/dados/geografia_gasto_candidaturas.rds
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/cap2-descritivo/R/03_geografia_gasto.R
# ==============================================================================

library(tidyverse)

dados_out <- file.path("explorations", "cap2-descritivo", "output", "dados")
dir.create(dados_out, showWarnings = FALSE, recursive = TRUE)

capitais <- readRDS("data/raw/capitais.rds") |> transmute(SG_UF, COD_MUN_TSE, capital = TRUE)

arquivos <- tribble(
  ~arquivo,                          ~cargo,     ~ANO_ELEICAO,
  "ql_gasto_eleit_2018.rds",         "Federal",  2018L,
  "ql_gasto_eleit_2022.rds",         "Federal",  2022L,
  "ql_gasto_eleit_est_2018.rds",     "Estadual", 2018L,
  "ql_gasto_eleit_est_2022.rds",     "Estadual", 2022L
)

geo_gasto <- pmap(arquivos, function(arquivo, cargo, ANO_ELEICAO) {
  readRDS(file.path("data", "raw", arquivo)) |>
    filter(GASTO > 0) |>
    left_join(capitais, by = c("SG_UF", "COD_MUN_TSE")) |>
    summarise(
      gasto_geo = sum(GASTO),
      n_mun_com_gasto = n(),
      n_mun_base_gasto = sum(QL_gasto_eleit > 1),
      pct_gasto_capital = sum(GASTO[coalesce(capital, FALSE)]) / sum(GASTO),
      pct_gasto_maior_mun = max(GASTO) / sum(GASTO),
      .by = sq_candidato
    ) |>
    mutate(cargo = cargo, ANO_ELEICAO = ANO_ELEICAO)
}) |>
  list_rbind() |>
  rename(SQ_CANDIDATO = sq_candidato)

print(geo_gasto |> summarise(n = n(), med_base = median(n_mun_base_gasto),
                             med_capital = median(pct_gasto_capital), .by = c(cargo, ANO_ELEICAO)))
saveRDS(geo_gasto, file.path(dados_out, "geografia_gasto_candidaturas.rds"))
