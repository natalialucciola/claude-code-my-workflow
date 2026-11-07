# ==============================================================================
# Script: 05_validacao_gasto_voto.R
# Purpose: Valida o QL do VOTO como substituto do QL do GASTO em 2018/2022,
#          onde as duas medidas existem. Responde: os achados do Capítulo 6
#          (feitos com gasto) se reproduzem com voto? Só então 2026 (só voto)
#          é interpretável como continuação da série.
#
#   1. Concordância candidato a candidato: correlação da taxa de
#      sobreposição; cobertura dos municípios QL_gasto > 1 pelo QL_voto > 1.
#   2. Tamanho dos conjuntos QL > 1 (nº de municípios por candidato).
#   3. Lacunas de gênero e raça lado a lado (gasto × voto).
#   4. Coeficientes da DDD réplica 2018–2022 lado a lado.
#
# Inputs:  explorations/base-territorial-partidos/output/ (versão gasto, do
#            capítulo): cand_mun_ql1.rds, taxa_sobreposicao_candidato.rds,
#            tab_taxa_sobreposicao_{genero,raca}.rds,
#            ddd_modelo_{genero,raca}.rds
#          explorations/ql-voto-2026/output/ (versão voto): idem + ddd_modelos.rds
# Outputs: explorations/ql-voto-2026/output/validacao_*.csv
#
# Rodar a partir da raiz do repositório (após 02 e 03):
#   Rscript explorations/ql-voto-2026/R/05_validacao_gasto_voto.R
# ==============================================================================

library(tidyverse)

source("explorations/ql-voto-2026/R/config.R")  # out_dir da variante
gasto_dir <- file.path("explorations", "base-territorial-partidos", "output")
voto_dir  <- out_dir

chave <- c("sq_candidato", "cargo", "ANO_ELEICAO")

ler <- function(dir, arq) {
  readRDS(file.path(dir, arq)) |> mutate(ANO_ELEICAO = as.character(ANO_ELEICAO))
}

# ==============================================================================
# 1. CONCORDÂNCIA CANDIDATO A CANDIDATO
# ==============================================================================

taxa_gasto <- ler(gasto_dir, "taxa_sobreposicao_candidato.rds") |>
  select(all_of(chave), genero, raca2, n_mun_gasto = n_mun_ql1, taxa_gasto = taxa_sobreposicao)
taxa_voto <- ler(voto_dir, "taxa_sobreposicao_candidato.rds") |>
  filter(ANO_ELEICAO != "2026") |>
  select(all_of(chave), n_mun_voto = n_mun_ql1, taxa_voto = taxa_sobreposicao)

pares <- inner_join(taxa_gasto, taxa_voto, by = chave)

mun_gasto <- ler(gasto_dir, "cand_mun_ql1.rds") |> distinct(across(all_of(chave)), COD_MUN_TSE)
mun_voto  <- ler(voto_dir, "cand_mun_ql1.rds") |>
  filter(ANO_ELEICAO != "2026") |>
  distinct(across(all_of(chave)), COD_MUN_TSE) |>
  mutate(em_voto = TRUE)

# Fração dos municípios onde o candidato concentra GASTO que também são base
# de VOTO (QL > 1 nas duas medidas)
cobertura <- mun_gasto |>
  left_join(mun_voto, by = c(chave, "COD_MUN_TSE")) |>
  summarise(cobertura_gasto_por_voto = mean(!is.na(em_voto)), .by = all_of(chave))

concordancia <- pares |>
  left_join(cobertura, by = chave) |>
  summarise(
    candidatos_em_ambas = n(),
    cor_pearson_taxa = cor(taxa_gasto, taxa_voto),
    cor_spearman_taxa = cor(taxa_gasto, taxa_voto, method = "spearman"),
    media_taxa_gasto = mean(taxa_gasto),
    media_taxa_voto = mean(taxa_voto),
    mediana_n_mun_gasto = median(n_mun_gasto),
    mediana_n_mun_voto = median(n_mun_voto),
    cobertura_media = mean(cobertura_gasto_por_voto, na.rm = TRUE),
    .by = c(cargo, ANO_ELEICAO)
  ) |>
  left_join(count(taxa_gasto, cargo, ANO_ELEICAO, name = "candidatos_gasto"),
            by = c("cargo", "ANO_ELEICAO")) |>
  arrange(cargo, ANO_ELEICAO)

print(concordancia)

# ==============================================================================
# 2–3. LACUNAS DE GÊNERO E RAÇA LADO A LADO
# ==============================================================================

lado_a_lado <- function(arq, medida_col) {
  bind_rows(
    ler(gasto_dir, paste0(arq, ".rds")) |> mutate(medida = "Gasto"),
    ler(voto_dir,  paste0(arq, ".rds")) |> mutate(medida = "Voto")
  ) |>
    select(medida, cargo, ANO_ELEICAO, starts_with("taxa_media_pct"), gap_pp) |>
    arrange(cargo, ANO_ELEICAO, medida)
}

lacuna_genero <- lado_a_lado("tab_taxa_sobreposicao_genero")
lacuna_raca   <- lado_a_lado("tab_taxa_sobreposicao_raca")
print(lacuna_genero)
print(lacuna_raca)

# ==============================================================================
# 4. DDD RÉPLICA — GASTO × VOTO
# ==============================================================================

termo_ddd <- function(m) {
  broom::tidy(m, conf.int = TRUE) |>
    filter(str_detect(term, "federal") & str_detect(term, "ano2022") &
             str_detect(term, "mulher|negra")) |>
    mutate(n_obs = nobs(m))
}

modelos_voto <- readRDS(file.path(voto_dir, "ddd_modelos.rds"))
ddd_comparacao <- bind_rows(
  termo_ddd(readRDS(file.path(gasto_dir, "ddd_modelo_genero.rds"))) |>
    mutate(medida = "Gasto", grupo = "genero"),
  termo_ddd(readRDS(file.path(gasto_dir, "ddd_modelo_raca.rds"))) |>
    mutate(medida = "Gasto", grupo = "raca"),
  termo_ddd(modelos_voto$genero$replica_2018_2022) |> mutate(medida = "Voto", grupo = "genero"),
  termo_ddd(modelos_voto$raca$replica_2018_2022)   |> mutate(medida = "Voto", grupo = "raca")
) |>
  select(grupo, medida, term, estimate, std.error, conf.low, conf.high, p.value, n_obs) |>
  arrange(grupo, medida)
print(ddd_comparacao)

write_csv(concordancia,   file.path(voto_dir, "validacao_concordancia.csv"))
write_csv(lacuna_genero,  file.path(voto_dir, "validacao_lacuna_genero.csv"))
write_csv(lacuna_raca,    file.path(voto_dir, "validacao_lacuna_raca.csv"))
write_csv(ddd_comparacao, file.path(voto_dir, "validacao_ddd_replica.csv"))

message("\n=== Validação gasto × voto concluída — em ", voto_dir, " ===")
