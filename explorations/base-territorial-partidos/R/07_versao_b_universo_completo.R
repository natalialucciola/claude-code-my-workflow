# ==============================================================================
# SUPERSEDED (2026-08-16): este script investigou se `partidos_sel` (8
# partidos) tinha justificativa teórica. Não tinha — por isso o filtro foi
# removido diretamente de 01_overlap_partido.R, que agora usa o universo
# completo de partidos por padrão. O que este script chamava "Versão B" é,
# desde então, a única versão (01-06). Mantido apenas como registro do
# processo de investigação — ver SESSION_LOG.md. Não rodar como parte do
# pipeline atual (duplica 01-06 desnecessariamente).
# ==============================================================================

# ==============================================================================
# Versão B: robustez ao universo completo de partidos (sem o filtro `partidos_sel`)
#
# Motivação: a restrição aos 8 maiores partidos (`partidos_sel`) usada em 01-06
# foi herdada de uma escolha de conveniência de análises exploratórias
# anteriores do projeto (ver AGENTS.md do projeto de análise original) — não
# tem justificativa teórica documentada. Este script recalcula os modelos já
# gerados (achado geral, Modelo 1, Modelo 2, alcance total/H5) usando TODOS os
# partidos presentes nos dados brutos, como checagem de robustez.
#
# Reaproveita `incumbencia_completa_candidato.rds` (salvo por 03) sem
# modificação — essa base já é construída a partir dos arquivos brutos de
# candidatura (`candidatos*.rds`), não filtrados por partido, então já cobre
# o universo completo.
#
# Pré-requisito: rodar R/03_ddd_incentivo_2022.R antes (gera
# incumbencia_completa_candidato.rds).
# ==============================================================================

library(tidyverse)
library(fixest)

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

out_dir <- "explorations/base-territorial-partidos/output"

# ==============================================================================
# 1. BASE — universo completo de partidos (sem partidos_sel)
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

dados_b <- bind_rows(fed_2018, fed_2022, est_2018, est_2022)

message("Versão B — universo completo: ", n_distinct(dados_b$partido_harm),
        " partidos, ", n_distinct(dados_b$sq_candidato), " candidatos distintos")
message("Versão A (partidos_sel), para referência: 8 partidos, 14.752 candidatos")
rm(fed_2018, fed_2022, est_2018, est_2022)

# ==============================================================================
# 2. MODELO 1 (universo completo) — overlap e taxa_sobreposicao
# ==============================================================================

mun_partido_b <- dados_b |>
  filter(QL_gasto_eleit > 1) |>
  summarise(
    n_cand_ql1 = n_distinct(sq_candidato),
    .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)
  ) |>
  mutate(overlap = n_cand_ql1 >= 2)

cand_mun_ql1_b <- dados_b |>
  filter(QL_gasto_eleit > 1) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE,
           genero, raca2, eleito, competitivo) |>
  left_join(
    mun_partido_b |> select(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE, overlap),
    by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")
  )

taxa_sobreposicao_b <- cand_mun_ql1_b |>
  summarise(
    n_mun_ql1     = n(),
    n_mun_overlap = sum(overlap),
    taxa_sobreposicao = n_mun_overlap / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, genero, raca2)
  )

message("\nCandidatos com >=1 município QL>1 (universo completo): ", nrow(taxa_sobreposicao_b))

saveRDS(cand_mun_ql1_b, file.path(out_dir, "versaoB_cand_mun_ql1.rds"))
saveRDS(taxa_sobreposicao_b, file.path(out_dir, "versaoB_taxa_sobreposicao_candidato.rds"))

# ---- Achado geral (descritivo), universo completo ----

tab_genero_b <- taxa_sobreposicao_b |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, genero)
  ) |>
  pivot_wider(names_from = genero, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_FEMININO - taxa_media_pct_MASCULINO) |>
  arrange(cargo, ANO_ELEICAO)

tab_raca_b <- taxa_sobreposicao_b |>
  filter(raca2 %in% c("BRANCA", "NEGRA")) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, raca2)
  ) |>
  pivot_wider(names_from = raca2, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_NEGRA - taxa_media_pct_BRANCA) |>
  arrange(cargo, ANO_ELEICAO)

message("\n--- Versão B: taxa de sobreposição por gênero (cargo x ano) ---")
print(tab_genero_b)
message("\n--- Versão B: taxa de sobreposição por raça (cargo x ano) ---")
print(tab_raca_b)

saveRDS(tab_genero_b, file.path(out_dir, "versaoB_tab_genero.rds"))
saveRDS(tab_raca_b,   file.path(out_dir, "versaoB_tab_raca.rds"))

# ==============================================================================
# 3. MODELO 1 (H3) — DDD, universo completo
# ==============================================================================

uf_por_candidato_b <- cand_mun_ql1_b |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, SG_UF)

ddd_base_b <- taxa_sobreposicao_b |>
  left_join(uf_por_candidato_b, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA")
  )

df_genero_b <- ddd_base_b |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo1_genero_b <- feols(
  taxa_sobreposicao ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_genero_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — Modelo 1 (H3), Gênero ===")
print(summary(modelo1_genero_b))

df_raca_b <- ddd_base_b |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo1_raca_b <- feols(
  taxa_sobreposicao ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_raca_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — Modelo 1 (H3), Raça ===")
print(summary(modelo1_raca_b))

# ==============================================================================
# 4. MODELO 2 (H4) e ALCANCE TOTAL (H5) — universo completo
#    Reaproveita incumbencia_completa_candidato.rds (já é universo completo,
#    construída a partir dos arquivos brutos de candidatura, não de `dados`).
# ==============================================================================

incumbencia <- readRDS(file.path(out_dir, "incumbencia_completa_candidato.rds"))

cand_inc_b <- cand_mun_ql1_b |>
  left_join(incumbencia, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  filter(!is.na(incumbente))

mun_incumbente_count_b <- cand_inc_b |>
  filter(incumbente == 1) |>
  summarise(
    n_incumbentes_ql1 = n_distinct(sq_candidato),
    .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)
  )

cand_mun_incumbente_b <- cand_inc_b |>
  left_join(mun_incumbente_count_b,
            by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")) |>
  mutate(
    n_incumbentes_ql1    = replace_na(n_incumbentes_ql1, 0L),
    n_outros_incumbentes = n_incumbentes_ql1 - incumbente,
    overlap_incumbente   = n_outros_incumbentes >= 1
  )

taxa_incumbente_b <- cand_mun_incumbente_b |>
  summarise(
    n_mun_ql1                     = n(),
    n_mun_overlap_incumbente      = sum(overlap_incumbente),
    taxa_sobreposicao_incumbente  = n_mun_overlap_incumbente / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, genero, raca2, incumbente)
  )

base_modelo2_b <- taxa_incumbente_b |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA")
  )

nao_incumbentes_b <- base_modelo2_b |> filter(incumbente == 0)

df_m2_genero_b <- nao_incumbentes_b |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo2_genero_b <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m2_genero_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — Modelo 2 (H4), Gênero, não incumbentes ===")
print(summary(modelo2_genero_b))

df_m2_raca_b <- nao_incumbentes_b |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo2_raca_b <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m2_raca_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — Modelo 2 (H4), Raça, não incumbentes ===")
print(summary(modelo2_raca_b))

# ---- H5: alcance territorial total, universo completo ----

alcance_total_b <- taxa_sobreposicao_b |>
  left_join(uf_por_candidato_b, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA"),
    alcance_total = n_mun_ql1
  )

df_alcance_genero_b <- alcance_total_b |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo_alcance_genero_b <- feols(
  alcance_total ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_alcance_genero_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — H5, Alcance total, Gênero ===")
print(summary(modelo_alcance_genero_b))

df_alcance_raca_b <- alcance_total_b |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo_alcance_raca_b <- feols(
  alcance_total ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_alcance_raca_b, cluster = ~ partido_harm + SG_UF
)
message("\n=== Versão B — H5, Alcance total, Raça ===")
print(summary(modelo_alcance_raca_b))

# ==============================================================================
# 5. TABELA COMPARATIVA — partidos_sel (Versão A) vs. universo completo (Versão B)
# ==============================================================================

extrair_coef <- function(modelo, termo, versao, modelo_label, grupo, scale = 100) {
  broom::tidy(modelo, conf.int = TRUE) |>
    filter(term == termo) |>
    transmute(
      versao, modelo_label, grupo,
      estimate = round(scale * estimate, 2),
      conf.low = round(scale * conf.low, 2),
      conf.high = round(scale * conf.high, 2),
      p.value
    )
}

# Estimativas da Versão A (partidos_sel), lidas dos modelos já salvos por 03/05
ddd_a_genero <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
ddd_a_raca   <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
ddd2_a_genero <- readRDS(file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
ddd2_a_raca   <- readRDS(file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))
alc_a_genero  <- readRDS(file.path(out_dir, "ddd_alcance_genero.rds"))
alc_a_raca    <- readRDS(file.path(out_dir, "ddd_alcance_raca.rds"))

tab_versao_a_b <- bind_rows(
  extrair_coef(ddd_a_genero,      "federal:ano2022:mulher", "A (partidos_sel)", "Modelo 1 (H3)", "Mulher"),
  extrair_coef(modelo1_genero_b,  "federal:ano2022:mulher", "B (universo completo)", "Modelo 1 (H3)", "Mulher"),
  extrair_coef(ddd_a_raca,        "federal:ano2022:negra",  "A (partidos_sel)", "Modelo 1 (H3)", "Negra"),
  extrair_coef(modelo1_raca_b,    "federal:ano2022:negra",  "B (universo completo)", "Modelo 1 (H3)", "Negra"),
  extrair_coef(ddd2_a_genero,     "federal:ano2022:mulher", "A (partidos_sel)", "Modelo 2 (H4)", "Mulher"),
  extrair_coef(modelo2_genero_b,  "federal:ano2022:mulher", "B (universo completo)", "Modelo 2 (H4)", "Mulher"),
  extrair_coef(ddd2_a_raca,       "federal:ano2022:negra",  "A (partidos_sel)", "Modelo 2 (H4)", "Negra"),
  extrair_coef(modelo2_raca_b,    "federal:ano2022:negra",  "B (universo completo)", "Modelo 2 (H4)", "Negra"),
  extrair_coef(alc_a_genero,             "federal:ano2022:mulher", "A (partidos_sel)", "H5 (alcance)", "Mulher", scale = 1),
  extrair_coef(modelo_alcance_genero_b,  "federal:ano2022:mulher", "B (universo completo)", "H5 (alcance)", "Mulher", scale = 1),
  extrair_coef(alc_a_raca,               "federal:ano2022:negra",  "A (partidos_sel)", "H5 (alcance)", "Negra", scale = 1),
  extrair_coef(modelo_alcance_raca_b,    "federal:ano2022:negra",  "B (universo completo)", "H5 (alcance)", "Negra", scale = 1)
)

print(tab_versao_a_b, n = Inf)

write_csv(tab_versao_a_b, file.path(out_dir, "tabela_versaoA_vs_versaoB.csv"))

saveRDS(modelo1_genero_b, file.path(out_dir, "versaoB_ddd_modelo1_genero.rds"))
saveRDS(modelo1_raca_b,   file.path(out_dir, "versaoB_ddd_modelo1_raca.rds"))
saveRDS(modelo2_genero_b, file.path(out_dir, "versaoB_ddd_modelo2_genero.rds"))
saveRDS(modelo2_raca_b,   file.path(out_dir, "versaoB_ddd_modelo2_raca.rds"))
saveRDS(modelo_alcance_genero_b, file.path(out_dir, "versaoB_ddd_alcance_genero.rds"))
saveRDS(modelo_alcance_raca_b,   file.path(out_dir, "versaoB_ddd_alcance_raca.rds"))

message("\n=== Versão B (universo completo de partidos) concluída — modelos e tabela comparativa salvos em ", out_dir, " ===")
