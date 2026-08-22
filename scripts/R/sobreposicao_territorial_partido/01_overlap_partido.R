# ==============================================================================
# Script: 01_overlap_partido.R
# Purpose: Sobreposição território-partido — nível município e candidato
#          (pipeline do Capítulo 6, "Coordenação territorial de listas
#          partidárias")
# Inputs:  data/raw/ql_gasto_eleit_{2018,2022}.rds,
#          data/raw/ql_gasto_eleit_est_{2018,2022}.rds
# Outputs: cand_mun_ql1.rds, taxa_sobreposicao_candidato.rds,
#          overlap_municipio_partido.rds, tab_overlap_municipio.rds/.csv,
#          tab_taxa_sobreposicao_{genero,raca,genero_raca}.rds/.csv,
#          teste_t_{genero,raca}.rds
# Status: PRODUÇÃO — alimenta 06-sobreposicao-territorial-partido.qmd.
#         Histórico investigativo em
#         explorations/base-territorial-partidos/SESSION_LOG.md.
#
# Perguntas:
#   1. Há diferença na taxa de sobreposição entre Federal e Estadual?
#   2. Há diferença entre 2018 e 2022?
#   3. Mulheres estão mais/menos expostas à sobreposição do que homens?
#   4. Candidatos negros estão mais/menos expostos do que brancos?
#
# Rodar a partir da raiz do repositório:
#   Rscript scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R
#
# 0. SETUP
# ==============================================================================

library(tidyverse)

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

# NOTA (2026-08-16): a análise cobre o universo completo de partidos presentes
# nos dados. Um filtro anterior para 8 partidos (`partidos_sel`) foi removido
# por não ter justificativa teórica — era uma seleção de conveniência herdada
# de análises exploratórias anteriores do projeto (ver SESSION_LOG.md).

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

generos_validos <- c("FEMININO", "MASCULINO")
racas_validas   <- c("BRANCA", "NEGRA")

# ==============================================================================
# 1. CARREGAR E EMPILHAR AS 4 BASES (Federal/Estadual x 2018/2022)
# ==============================================================================

cols_comuns <- c("sq_candidato", "SG_UF", "COD_MUN_TSE", "GASTO",
                  "QL_gasto_eleit", "eleito", "competitivo",
                  "genero", "raca2", "partido_harm", "ANO_ELEICAO")

fed_2018 <- readRDS("data/raw/ql_gasto_eleit_2018.rds") |>
  mutate(cargo = "Federal") |>
  select(all_of(cols_comuns), cargo)

fed_2022 <- readRDS("data/raw/ql_gasto_eleit_2022.rds") |>
  mutate(cargo = "Federal") |>
  select(all_of(cols_comuns), cargo)

est_2018 <- readRDS("data/raw/ql_gasto_eleit_est_2018.rds") |>
  mutate(cargo = "Estadual",
         partido_harm = harmonizar_partido(partido)) |>
  select(all_of(cols_comuns), cargo)

est_2022 <- readRDS("data/raw/ql_gasto_eleit_est_2022.rds") |>
  mutate(cargo = "Estadual",
         partido_harm = harmonizar_partido(partido)) |>
  select(all_of(cols_comuns), cargo)

dados <- bind_rows(fed_2018, fed_2022, est_2018, est_2022)

message("Dados carregados: ", nrow(dados), " linhas (candidato-município), ",
        n_distinct(dados$sq_candidato), " candidatos distintos (universo completo de partidos).")
rm(fed_2018, fed_2022, est_2018, est_2022)

# ==============================================================================
# 2. NÍVEL MUNICÍPIO: quantos candidatos do mesmo partido/cargo/ano
#    têm QL_gasto_eleit > 1 no mesmo município?
# ==============================================================================

mun_partido <- dados |>
  filter(QL_gasto_eleit > 1) |>
  summarise(
    n_cand_ql1 = n_distinct(sq_candidato),
    .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)
  ) |>
  mutate(overlap = n_cand_ql1 >= 2)

# Tabela A: taxa de sobreposição a nível de município (entre municípios com
# pelo menos 1 candidato acima do QL, qual % tem 2+?)
tab_overlap_mun <- mun_partido |>
  summarise(
    n_municipios_com_ql1 = n(),
    n_municipios_overlap = sum(overlap, na.rm = FALSE),
    taxa_overlap_mun_pct = round(100 * mean(overlap, na.rm = FALSE), 1),
    .by = c(cargo, ANO_ELEICAO)
  ) |>
  arrange(cargo, ANO_ELEICAO)

message("Tabela A (taxa de sobreposição por município, cargo x ano) calculada: ",
        nrow(tab_overlap_mun), " linhas.")

# ==============================================================================
# 3. NÍVEL CANDIDATO: dos municípios em que o candidato tem QL_gasto_eleit > 1,
#    que fração é compartilhada com outro candidato do mesmo partido
#    (taxa_sobreposicao)?
# ==============================================================================

cand_mun_ql1 <- dados |>
  filter(QL_gasto_eleit > 1) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE,
           genero, raca2, eleito, competitivo) |>
  left_join(
    mun_partido |> select(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE, overlap),
    by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")
  )

saveRDS(cand_mun_ql1, file.path(out_dir, "cand_mun_ql1.rds"))

taxa_sobreposicao <- cand_mun_ql1 |>
  summarise(
    n_mun_ql1     = n(),
    n_mun_overlap = sum(overlap, na.rm = FALSE),
    taxa_sobreposicao = n_mun_overlap / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, genero, raca2)
  )

message("\nCandidatos com pelo menos 1 município QL_gasto_eleit > 1: ", nrow(taxa_sobreposicao))

saveRDS(taxa_sobreposicao, file.path(out_dir, "taxa_sobreposicao_candidato.rds"))
saveRDS(mun_partido, file.path(out_dir, "overlap_municipio_partido.rds"))

# ==============================================================================
# 4. COMPARAÇÕES: gênero, raça, cargo, ano
# ==============================================================================

# ---- B: por gênero, dentro de cargo x ano (+ teste t) ----
tab_genero <- taxa_sobreposicao |>
  filter(genero %in% generos_validos) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, genero)
  ) |>
  pivot_wider(names_from = genero, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_FEMININO - taxa_media_pct_MASCULINO) |>
  arrange(cargo, ANO_ELEICAO)

teste_genero <- taxa_sobreposicao |>
  filter(genero %in% generos_validos) |>
  nest(.by = c(cargo, ANO_ELEICAO)) |>
  mutate(
    teste = map(data, ~ tryCatch(
      broom::tidy(t.test(taxa_sobreposicao ~ genero, data = .x)),
      error = function(e) NULL
    ))
  ) |>
  select(cargo, ANO_ELEICAO, teste) |>
  unnest(teste) |>
  select(cargo, ANO_ELEICAO, estimate, conf.low, conf.high, p.value)

message("Tabela B (gênero, cargo x ano) e teste t (FEMININO vs MASCULINO) calculados: ",
        nrow(tab_genero), " linhas, ", nrow(teste_genero), " testes.")

# ---- C: por raça, dentro de cargo x ano (+ teste t) ----
tab_raca <- taxa_sobreposicao |>
  filter(raca2 %in% racas_validas) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, raca2)
  ) |>
  pivot_wider(names_from = raca2, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_NEGRA - taxa_media_pct_BRANCA) |>
  arrange(cargo, ANO_ELEICAO)

teste_raca <- taxa_sobreposicao |>
  filter(raca2 %in% racas_validas) |>
  nest(.by = c(cargo, ANO_ELEICAO)) |>
  mutate(
    teste = map(data, ~ tryCatch(
      broom::tidy(t.test(taxa_sobreposicao ~ raca2, data = .x)),
      error = function(e) NULL
    ))
  ) |>
  select(cargo, ANO_ELEICAO, teste) |>
  unnest(teste) |>
  select(cargo, ANO_ELEICAO, estimate, conf.low, conf.high, p.value)

message("Tabela C (raça, cargo x ano) e teste t (NEGRA vs BRANCA) calculados: ",
        nrow(tab_raca), " linhas, ", nrow(teste_raca), " testes.")

# ---- D: gênero x raça, dentro de cargo x ano (descritivo, sem teste) ----
tab_genero_raca <- taxa_sobreposicao |>
  filter(genero %in% generos_validos,
         raca2 %in% racas_validas) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, genero, raca2)
  ) |>
  arrange(cargo, ANO_ELEICAO, genero, raca2)

message("Tabela D (gênero x raça, cargo x ano) calculada: ", nrow(tab_genero_raca), " linhas.")

# ==============================================================================
# 5. SALVAR TABELAS
# ==============================================================================

saveRDS(tab_overlap_mun,  file.path(out_dir, "tab_overlap_municipio.rds"))
saveRDS(tab_genero,       file.path(out_dir, "tab_taxa_sobreposicao_genero.rds"))
saveRDS(teste_genero,     file.path(out_dir, "teste_t_genero.rds"))
saveRDS(tab_raca,         file.path(out_dir, "tab_taxa_sobreposicao_raca.rds"))
saveRDS(teste_raca,       file.path(out_dir, "teste_t_raca.rds"))
saveRDS(tab_genero_raca,  file.path(out_dir, "tab_taxa_sobreposicao_genero_raca.rds"))

write_csv(tab_overlap_mun, file.path(out_dir, "tab_overlap_municipio.csv"))
write_csv(tab_genero,      file.path(out_dir, "tab_taxa_sobreposicao_genero.csv"))
write_csv(tab_raca,        file.path(out_dir, "tab_taxa_sobreposicao_raca.csv"))
write_csv(tab_genero_raca, file.path(out_dir, "tab_taxa_sobreposicao_genero_raca.csv"))

message("\n=== Exploração concluída — tabelas salvas em ", out_dir, " ===")
