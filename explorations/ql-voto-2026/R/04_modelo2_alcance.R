# ==============================================================================
# Script: 04_modelo2_alcance.R
# Purpose: Modelo 2 (H4 — sobreposição especificamente com correligionário
#          INCUMBENTE) e H5 (alcance territorial total = nº de municípios com
#          QL > 1) com QL do VOTO, 2018/2022/2026 — versão de
#          05_modelo2_incumbente.R do Capítulo 6.
#
# Mesmas definições do capítulo: overlap_incumbente = existe OUTRO candidato
# incumbente do mesmo partido com QL > 1 no município; amostra principal do
# Modelo 2 = candidatos NÃO incumbentes; amostra completa como robustez.
# Especificações temporais iguais às de 03_ddd.R (réplica 2018–2022; três
# eleições com 2022 e 2026 contra 2018).
#
# Inputs:  explorations/ql-voto-2026/output/cand_mun_ql1.rds,
#          taxa_sobreposicao_candidato.rds, incumbencia_completa_candidato.rds
# Outputs: explorations/ql-voto-2026/output/
#          taxa_sobreposicao_incumbente_candidato.rds, alcance_total_candidato.rds,
#          modelo2_alcance_modelos.rds, modelo2_alcance_coeficientes.csv,
#          tab_modelo2_descritiva.csv, tab_alcance_descritiva.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/04_modelo2_alcance.R
# ==============================================================================

library(tidyverse)
library(fixest)

source("explorations/ql-voto-2026/R/config.R")  # out_dir da variante

cand_mun_ql1 <- readRDS(file.path(out_dir, "cand_mun_ql1.rds"))
incumbencia  <- readRDS(file.path(out_dir, "incumbencia_completa_candidato.rds"))

# ==============================================================================
# 1. MODELO 2 — sobreposição com incumbente do partido
# ==============================================================================

cand_inc <- cand_mun_ql1 |>
  left_join(incumbencia, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  filter(!is.na(incumbente))

n_inc_mun <- cand_inc |>
  filter(incumbente == 1) |>
  summarise(n_incumbentes_ql1 = n_distinct(sq_candidato),
            .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE))

taxa_incumbente <- cand_inc |>
  left_join(n_inc_mun, by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")) |>
  mutate(
    n_incumbentes_ql1  = replace_na(n_incumbentes_ql1, 0L),
    # Desconta o próprio candidato quando ele é incumbente (sem auto-sobreposição)
    overlap_incumbente = (n_incumbentes_ql1 - incumbente) >= 1L
  ) |>
  summarise(
    n_mun_ql1 = n(),
    taxa_sobreposicao_incumbente = mean(overlap_incumbente),
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, genero, raca2, incumbente)
  )

alcance <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds")) |>
  mutate(alcance_total = n_mun_ql1)

adicionar_indicadores <- function(df) {
  df |>
    mutate(
      federal = as.integer(cargo == "Federal"),
      ano2022 = as.integer(ANO_ELEICAO == "2022"),
      ano2026 = as.integer(ANO_ELEICAO == "2026"),
      mulher  = as.integer(genero == "FEMININO"),
      negra   = as.integer(raca2 == "NEGRA")
    )
}

taxa_incumbente <- adicionar_indicadores(taxa_incumbente)
alcance         <- adicionar_indicadores(alcance)

# ==============================================================================
# 2. DESCRITIVAS
# ==============================================================================

descrever <- function(df, y) {
  bind_rows(
    df |> filter(genero %in% c("FEMININO", "MASCULINO")) |> mutate(grupo = genero) |>
      summarise(media = mean(.data[[y]]), n = n(), .by = c(cargo, ANO_ELEICAO, grupo)),
    df |> filter(raca2 %in% c("BRANCA", "NEGRA")) |> mutate(grupo = raca2) |>
      summarise(media = mean(.data[[y]]), n = n(), .by = c(cargo, ANO_ELEICAO, grupo))
  ) |>
    arrange(cargo, ANO_ELEICAO, grupo)
}

tab_modelo2 <- descrever(filter(taxa_incumbente, incumbente == 0), "taxa_sobreposicao_incumbente")
tab_alcance <- descrever(alcance, "alcance_total")
print(tab_modelo2, n = 40)
print(tab_alcance, n = 40)

# ==============================================================================
# 3. ESTIMAÇÃO
# ==============================================================================

#' DDD réplica (2018–2022) e três eleições para um desfecho e um grupo
estimar <- function(df, y, v) {
  f <- function(rhs, d) feols(as.formula(paste(y, "~", rhs, "| partido_harm + SG_UF")),
                              data = d, cluster = ~ partido_harm + SG_UF)
  list(
    replica_2018_2022 = f(sprintf("federal * ano2022 * %s", v), filter(df, ANO_ELEICAO != "2026")),
    tres_eleicoes     = f(sprintf("federal * %s * ano2022 + federal * %s * ano2026", v, v), df)
  )
}

amostras <- list(
  modelo2_nao_incumbentes = list(df = filter(taxa_incumbente, incumbente == 0),
                                 y = "taxa_sobreposicao_incumbente"),
  modelo2_completa        = list(df = taxa_incumbente, y = "taxa_sobreposicao_incumbente"),
  alcance_total           = list(df = alcance, y = "alcance_total")
)

modelos <- imap(amostras, \(a, nome) list(
  genero = estimar(filter(a$df, genero %in% c("FEMININO", "MASCULINO")), a$y, "mulher"),
  raca   = estimar(filter(a$df, raca2 %in% c("BRANCA", "NEGRA")), a$y, "negra")
))

coeficientes <- imap(modelos, \(por_grupo, desfecho) {
  imap(por_grupo, \(ms, grupo) {
    imap(ms, \(m, espec) {
      broom::tidy(m, conf.int = TRUE) |>
        filter(str_detect(term, "federal") & str_detect(term, "mulher|negra") &
                 str_detect(term, "ano2022|ano2026")) |>
        mutate(desfecho = desfecho, grupo = grupo, especificacao = espec, n_obs = nobs(m))
    }) |> list_rbind()
  }) |> list_rbind()
}) |>
  list_rbind() |>
  select(desfecho, grupo, especificacao, term, estimate, std.error, conf.low, conf.high,
         p.value, n_obs)

print(coeficientes, n = 60)

# ==============================================================================
# 4. SALVAR
# ==============================================================================

saveRDS(taxa_incumbente, file.path(out_dir, "taxa_sobreposicao_incumbente_candidato.rds"))
saveRDS(alcance,         file.path(out_dir, "alcance_total_candidato.rds"))
saveRDS(modelos,         file.path(out_dir, "modelo2_alcance_modelos.rds"))
write_csv(coeficientes,  file.path(out_dir, "modelo2_alcance_coeficientes.csv"))
write_csv(tab_modelo2,   file.path(out_dir, "tab_modelo2_descritiva.csv"))
write_csv(tab_alcance,   file.path(out_dir, "tab_alcance_descritiva.csv"))

message("\n=== Modelo 2 + alcance (QL do voto) concluídos — em ", out_dir, " ===")
