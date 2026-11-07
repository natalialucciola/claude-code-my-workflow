# ==============================================================================
# Script: 02_sobreposicao.R
# Purpose: Sobreposição território-partido com QL do VOTO, 2018/2022/2026 —
#          versão de 01_overlap_partido.R + 02_overlap_extensoes.R do
#          Capítulo 6 (scripts/R/sobreposicao_territorial_partido/), mesmas
#          definições, trocando QL_gasto_eleit por QL_voto e somando 2026.
#
#   A. Taxa de sobreposição no nível do município (partido × cargo × ano)
#   B. Taxa no nível do candidato por gênero, raça, gênero × raça (+ teste t)
#   C. Capital vs. não capital
#   D. Resultado eleitoral (eleito / competitivo / não competitivo)
#   E. Incumbência (eleito no mesmo cargo na eleição anterior, por CPF)
#
# Inputs:  explorations/ql-voto-2026/output/dados/ql_voto_*.rds (01_...R)
#          data/raw/capitais.rds
#          data/raw/candidatos{2014,2018,2022}.rds, eleitos_2014_df.rds,
#          data/raw/candidatos_estadual_{2014,2018,2022}.rds,
#          data/raw/eleitos_e_compet_{2018,2022}_df.rds,
#          data/raw/eleitos_e_compet_est_{2014,2018,2022}_df.rds
# Outputs: explorations/ql-voto-2026/output/
#          cand_mun_ql1.rds, taxa_sobreposicao_candidato.rds,
#          overlap_municipio_partido.rds, incumbencia_completa_candidato.rds,
#          tab_*.csv / teste_t_*.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/02_sobreposicao.R
# ==============================================================================

library(tidyverse)

source("explorations/ql-voto-2026/R/config.R")  # dados_dir, out_dir, fatia_min

generos_validos <- c("FEMININO", "MASCULINO")
racas_validas   <- c("BRANCA", "NEGRA")
niveis_resultado <- c("Eleito", "Competitivo, não eleito", "Não competitivo")

salvar <- function(obj, nome) {
  saveRDS(obj, file.path(out_dir, paste0(nome, ".rds")))
  write_csv(obj, file.path(out_dir, paste0(nome, ".csv")))
}

#' Teste t de diferença de médias da taxa de sobreposição entre dois grupos
#'
#' @param df Base candidato com `taxa_sobreposicao`.
#' @param grupo Nome da coluna de grupo (2 níveis).
#' @param por Colunas de estratificação.
testar_diferenca <- function(df, grupo, por) {
  df |>
    nest(.by = all_of(por)) |>
    mutate(teste = map(data, ~ tryCatch(
      broom::tidy(t.test(reformulate(grupo, "taxa_sobreposicao"), data = .x)),
      error = function(e) NULL
    ))) |>
    select(all_of(por), teste) |>
    unnest(teste) |>
    select(all_of(por), estimate, conf.low, conf.high, p.value)
}

# ==============================================================================
# 1. CARREGAR — só a base do candidato: QL_voto > 1 e fatia >= fatia_min
#    (ver config.R). O nome cand_mun_ql1 é mantido do capítulo.
# ==============================================================================

arquivos <- list.files(dados_dir, pattern = "^ql_voto_(federal|estadual)_\\d{4}\\.rds$",
                       full.names = TRUE)

cand_mun_ql1 <- map(arquivos, \(f) readRDS(f) |>
                      filter(QL_voto > 1, votos / V_cand >= fatia_min)) |>
  list_rbind() |>
  select(sq_candidato, cpf, cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE,
         genero, raca2, eleito, competitivo, QL_voto) |>
  filter(!is.na(partido_harm))

message("Pares candidato-município com QL_voto > 1: ", nrow(cand_mun_ql1),
        " | candidatos: ", n_distinct(paste(cand_mun_ql1$sq_candidato, cand_mun_ql1$cargo)))

# ==============================================================================
# A. NÍVEL MUNICÍPIO
# ==============================================================================

mun_partido <- cand_mun_ql1 |>
  summarise(n_cand_ql1 = n_distinct(sq_candidato),
            .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)) |>
  mutate(overlap = n_cand_ql1 >= 2)

tab_overlap_mun <- mun_partido |>
  summarise(
    n_municipios_com_ql1 = n(),
    n_municipios_overlap = sum(overlap),
    taxa_overlap_mun_pct = round(100 * mean(overlap), 1),
    .by = c(cargo, ANO_ELEICAO)
  ) |>
  arrange(cargo, ANO_ELEICAO)

cand_mun_ql1 <- cand_mun_ql1 |>
  left_join(select(mun_partido, -n_cand_ql1),
            by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE"))

# ==============================================================================
# B. NÍVEL CANDIDATO
# ==============================================================================

taxa_sobreposicao <- cand_mun_ql1 |>
  summarise(
    n_mun_ql1         = n(),
    n_mun_overlap     = sum(overlap),
    taxa_sobreposicao = n_mun_overlap / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, genero, raca2)
  )

tab_genero <- taxa_sobreposicao |>
  filter(genero %in% generos_validos) |>
  summarise(taxa_media_pct = round(100 * mean(taxa_sobreposicao), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, genero)) |>
  pivot_wider(names_from = genero, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_FEMININO - taxa_media_pct_MASCULINO) |>
  arrange(cargo, ANO_ELEICAO)

tab_raca <- taxa_sobreposicao |>
  filter(raca2 %in% racas_validas) |>
  summarise(taxa_media_pct = round(100 * mean(taxa_sobreposicao), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, raca2)) |>
  pivot_wider(names_from = raca2, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_NEGRA - taxa_media_pct_BRANCA) |>
  arrange(cargo, ANO_ELEICAO)

tab_genero_raca <- taxa_sobreposicao |>
  filter(genero %in% generos_validos, raca2 %in% racas_validas) |>
  summarise(taxa_media_pct = round(100 * mean(taxa_sobreposicao), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, genero, raca2)) |>
  arrange(cargo, ANO_ELEICAO, genero, raca2)

teste_genero <- taxa_sobreposicao |>
  filter(genero %in% generos_validos) |>
  testar_diferenca("genero", c("cargo", "ANO_ELEICAO"))

teste_raca <- taxa_sobreposicao |>
  filter(raca2 %in% racas_validas) |>
  testar_diferenca("raca2", c("cargo", "ANO_ELEICAO"))

print(tab_overlap_mun)
print(tab_genero)
print(tab_raca)

# ==============================================================================
# C. CAPITAL VS. NÃO CAPITAL
# ==============================================================================

capitais <- readRDS("data/raw/capitais.rds") |>
  transmute(SG_UF, COD_MUN_TSE, tipo_mun = "Capital")

com_tipo <- function(df) {
  df |>
    left_join(capitais, by = c("SG_UF", "COD_MUN_TSE")) |>
    mutate(tipo_mun = replace_na(tipo_mun, "Não-capital"))
}

tab_capital_municipio <- mun_partido |>
  com_tipo() |>
  summarise(
    n_municipios_com_ql1 = n(),
    n_municipios_overlap = sum(overlap),
    taxa_overlap_mun_pct = round(100 * mean(overlap), 1),
    .by = c(cargo, ANO_ELEICAO, tipo_mun)
  ) |>
  arrange(cargo, ANO_ELEICAO, tipo_mun)

taxa_por_tipo <- cand_mun_ql1 |>
  com_tipo() |>
  summarise(
    taxa_sobreposicao = mean(overlap),
    .by = c(sq_candidato, cargo, ANO_ELEICAO, genero, raca2, tipo_mun)
  )

tab_capital_genero <- taxa_por_tipo |>
  filter(genero %in% generos_validos) |>
  summarise(taxa_media_pct = round(100 * mean(taxa_sobreposicao), 1), n = n(),
            .by = c(ANO_ELEICAO, tipo_mun, genero)) |>
  pivot_wider(names_from = genero, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_FEMININO - taxa_media_pct_MASCULINO) |>
  arrange(ANO_ELEICAO, tipo_mun)

tab_capital_raca <- taxa_por_tipo |>
  filter(raca2 %in% racas_validas) |>
  summarise(taxa_media_pct = round(100 * mean(taxa_sobreposicao), 1), n = n(),
            .by = c(ANO_ELEICAO, tipo_mun, raca2)) |>
  pivot_wider(names_from = raca2, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_NEGRA - taxa_media_pct_BRANCA) |>
  arrange(ANO_ELEICAO, tipo_mun)

# ==============================================================================
# D. RESULTADO ELEITORAL
# ==============================================================================

cand_mun_res <- cand_mun_ql1 |>
  mutate(resultado = case_when(
    eleito == 1                    ~ "Eleito",
    competitivo == 1 & eleito == 0 ~ "Competitivo, não eleito",
    competitivo == 0 & eleito == 0 ~ "Não competitivo",
    TRUE                           ~ NA_character_
  ))

tab_resultado <- cand_mun_res |>
  filter(!is.na(resultado)) |>
  summarise(taxa_overlap_pct = round(100 * mean(overlap), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, resultado)) |>
  arrange(cargo, ANO_ELEICAO, factor(resultado, levels = niveis_resultado))

tab_resultado_genero <- cand_mun_res |>
  filter(!is.na(resultado), genero %in% generos_validos) |>
  summarise(taxa_overlap_pct = round(100 * mean(overlap), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, resultado, genero)) |>
  pivot_wider(names_from = genero, values_from = c(taxa_overlap_pct, n)) |>
  mutate(gap_pp = taxa_overlap_pct_FEMININO - taxa_overlap_pct_MASCULINO) |>
  arrange(cargo, ANO_ELEICAO, factor(resultado, levels = niveis_resultado))

# ==============================================================================
# E. INCUMBÊNCIA — CPF eleito no mesmo cargo na eleição anterior
#    2018 ← 2014, 2022 ← 2018, 2026 ← 2022
# ==============================================================================

#' CPFs eleitos num cargo × ano, a partir das bases da autora
#'
#' @param arq_cand Base de candidaturas (sq_candidato, cpfCand).
#' @param arq_eleitos Base de resultado (sq_candidato, eleito).
cpfs_eleitos <- function(arq_cand, arq_eleitos) {
  cpf <- readRDS(arq_cand) |> select(sq_candidato, cpfCand)
  readRDS(arq_eleitos) |>
    ungroup() |>
    distinct(sq_candidato, eleito) |>
    filter(eleito == 1) |>
    left_join(cpf, by = "sq_candidato") |>
    filter(!is.na(cpfCand)) |>
    distinct(cpfCand) |>
    pull(cpfCand)
}

eleitos_anteriores <- tribble(
  ~cargo,     ~ANO_ELEICAO, ~cpfs,
  "Federal",  "2018", cpfs_eleitos("data/raw/candidatos2014.rds",
                                   "data/raw/eleitos_2014_df.rds"),
  "Federal",  "2022", cpfs_eleitos("data/raw/candidatos2018.rds",
                                   "data/raw/eleitos_e_compet_2018_df.rds"),
  "Federal",  "2026", cpfs_eleitos("data/raw/candidatos2022.rds",
                                   "data/raw/eleitos_e_compet_2022_df.rds"),
  "Estadual", "2018", cpfs_eleitos("data/raw/candidatos_estadual_2014.rds",
                                   "data/raw/eleitos_e_compet_est_2014_df.rds"),
  "Estadual", "2022", cpfs_eleitos("data/raw/candidatos_estadual_2018.rds",
                                   "data/raw/eleitos_e_compet_est_2018_df.rds"),
  "Estadual", "2026", cpfs_eleitos("data/raw/candidatos_estadual_2022.rds",
                                   "data/raw/eleitos_e_compet_est_2022_df.rds")
)

message("\nCPFs eleitos na eleição anterior (por cargo × ano de referência):")
print(mutate(eleitos_anteriores, n_cpfs = lengths(cpfs)) |> select(-cpfs))

incumbencia_completa <- map(arquivos, \(f) readRDS(f) |>
                              distinct(sq_candidato, cpf, cargo, ANO_ELEICAO)) |>
  list_rbind() |>
  left_join(eleitos_anteriores, by = c("cargo", "ANO_ELEICAO")) |>
  mutate(incumbente = if_else(is.na(cpf), NA_integer_,
                              as.integer(map2_lgl(cpf, cpfs, `%in%`)))) |>
  select(sq_candidato, cargo, ANO_ELEICAO, incumbente)

cobertura_incumbencia <- incumbencia_completa |>
  summarise(n = n(), n_incumbentes = sum(incumbente, na.rm = TRUE),
            sem_cpf = sum(is.na(incumbente)), .by = c(cargo, ANO_ELEICAO)) |>
  arrange(cargo, ANO_ELEICAO)
print(cobertura_incumbencia)

tab_incumbencia <- cand_mun_ql1 |>
  left_join(incumbencia_completa, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  filter(!is.na(incumbente)) |>
  summarise(taxa_overlap_pct = round(100 * mean(overlap), 1), n = n(),
            .by = c(cargo, ANO_ELEICAO, incumbente)) |>
  arrange(cargo, ANO_ELEICAO, desc(incumbente))

# ==============================================================================
# SALVAR
# ==============================================================================

saveRDS(cand_mun_ql1,         file.path(out_dir, "cand_mun_ql1.rds"))
saveRDS(taxa_sobreposicao,    file.path(out_dir, "taxa_sobreposicao_candidato.rds"))
saveRDS(mun_partido,          file.path(out_dir, "overlap_municipio_partido.rds"))
saveRDS(incumbencia_completa, file.path(out_dir, "incumbencia_completa_candidato.rds"))

salvar(tab_overlap_mun,       "tab_overlap_municipio")
salvar(tab_genero,            "tab_taxa_sobreposicao_genero")
salvar(tab_raca,              "tab_taxa_sobreposicao_raca")
salvar(tab_genero_raca,       "tab_taxa_sobreposicao_genero_raca")
salvar(teste_genero,          "teste_t_genero")
salvar(teste_raca,            "teste_t_raca")
salvar(tab_capital_municipio, "tab_capital_municipio")
salvar(tab_capital_genero,    "tab_capital_genero")
salvar(tab_capital_raca,      "tab_capital_raca")
salvar(tab_resultado,         "tab_resultado_eleitoral")
salvar(tab_resultado_genero,  "tab_resultado_eleitoral_genero")
salvar(tab_incumbencia,       "tab_incumbencia")
salvar(cobertura_incumbencia, "cobertura_incumbencia")

message("\n=== Sobreposição (QL do voto) concluída — tabelas em ", out_dir, " ===")
