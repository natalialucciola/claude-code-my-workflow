# ==============================================================================
# Script: 05b_calibracao_base_voto.R
# Purpose: 05_validacao_gasto_voto.R mostrou que "QL_voto > 1" gera bases
#          territoriais ~10x maiores que "QL_gasto > 1" (mediana 15–26 vs. 2
#          municípios), saturando a sobreposição e não reproduzindo o capítulo.
#          Este script testa, SÓ em 2018/2022 (onde há gasto), uma grade
#          pré-definida de restrições adicionais à base de voto:
#            base = QL_voto > 1  E  votos[c, i] / V[c] >= s
#          s ∈ {0; 0,025; 0,05; 0,10}. Para cada s: tamanho da base, correlação
#          da taxa de sobreposição com a do gasto, e lacunas de gênero/raça
#          lado a lado com as do capítulo. A escolha de s (se alguma servir)
#          é feita aqui e congelada antes de olhar 2026.
#
# Inputs:  explorations/ql-voto-2026/output/dados/ql_voto_*_{2018,2022}.rds
#          explorations/base-territorial-partidos/output/taxa_sobreposicao_candidato.rds,
#          tab_taxa_sobreposicao_{genero,raca}.rds
# Outputs: explorations/ql-voto-2026/output/calibracao_base_voto.csv,
#          calibracao_lacunas.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/05b_calibracao_base_voto.R
# ==============================================================================

library(tidyverse)

dados_dir <- file.path("explorations", "ql-voto-2026", "output", "dados")
gasto_dir <- file.path("explorations", "base-territorial-partidos", "output")
out_dir   <- file.path("explorations", "ql-voto-2026", "output")

limiares <- c(0, 0.025, 0.05, 0.10)
chave <- c("sq_candidato", "cargo", "ANO_ELEICAO")

arquivos <- list.files(dados_dir, pattern = "^ql_voto_(federal|estadual)_(2018|2022)\\.rds$",
                       full.names = TRUE)
pares <- map(arquivos, \(f) readRDS(f) |> filter(QL_voto > 1)) |>
  list_rbind() |>
  filter(!is.na(partido_harm)) |>
  mutate(fatia = votos / V_cand) |>
  select(all_of(chave), partido_harm, SG_UF, COD_MUN_TSE, genero, raca2, fatia)

taxa_gasto <- readRDS(file.path(gasto_dir, "taxa_sobreposicao_candidato.rds")) |>
  mutate(ANO_ELEICAO = as.character(ANO_ELEICAO)) |>
  select(all_of(chave), taxa_gasto = taxa_sobreposicao)

#' Taxa de sobreposição por candidato para uma base de voto com limiar s
taxa_com_limiar <- function(s) {
  base <- filter(pares, fatia >= s)
  base |>
    left_join(
      base |> summarise(n_cand = n_distinct(sq_candidato),
                        .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)),
      by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")
    ) |>
    summarise(n_mun = n(), taxa = mean(n_cand >= 2),
              .by = c(all_of(chave), genero, raca2)) |>
    mutate(limiar = s)
}

taxas <- map(limiares, taxa_com_limiar) |> list_rbind()

calibracao <- taxas |>
  left_join(taxa_gasto, by = chave) |>
  summarise(
    candidatos = n(),
    mediana_n_mun = median(n_mun),
    media_taxa = mean(taxa),
    cor_com_gasto = cor(taxa, taxa_gasto, use = "complete.obs"),
    .by = c(limiar, cargo, ANO_ELEICAO)
  ) |>
  arrange(limiar, cargo, ANO_ELEICAO)

lacuna <- function(df, var, alvo, ref) {
  df |>
    filter(.data[[var]] %in% c(alvo, ref)) |>
    mutate(g = .data[[var]]) |>
    summarise(m = 100 * mean(taxa), .by = c(limiar, cargo, ANO_ELEICAO, g)) |>
    pivot_wider(names_from = g, values_from = m) |>
    transmute(limiar, cargo, ANO_ELEICAO, gap_pp = .data[[alvo]] - .data[[ref]])
}

gasto_gap <- function(arq, dim) {
  readRDS(file.path(gasto_dir, arq)) |>
    transmute(cargo, ANO_ELEICAO = as.character(ANO_ELEICAO), dimensao = dim, gap_gasto = gap_pp)
}

lacunas <- bind_rows(
  lacuna(taxas, "genero", "FEMININO", "MASCULINO") |> mutate(dimensao = "genero"),
  lacuna(taxas, "raca2", "NEGRA", "BRANCA")        |> mutate(dimensao = "raca")
) |>
  left_join(bind_rows(gasto_gap("tab_taxa_sobreposicao_genero.rds", "genero"),
                      gasto_gap("tab_taxa_sobreposicao_raca.rds", "raca")),
            by = c("cargo", "ANO_ELEICAO", "dimensao")) |>
  mutate(across(c(gap_pp, gap_gasto), \(x) round(x, 1))) |>
  arrange(dimensao, cargo, ANO_ELEICAO, limiar)

print(calibracao, n = 40)
print(lacunas, n = 40)

write_csv(calibracao, file.path(out_dir, "calibracao_base_voto.csv"))
write_csv(lacunas,    file.path(out_dir, "calibracao_lacunas.csv"))
