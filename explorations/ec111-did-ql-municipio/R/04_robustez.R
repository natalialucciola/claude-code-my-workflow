# ==============================================================================
# Script: 04_robustez.R
# Purpose: Robustez do resultado principal (entrada em território novo, decomposta)
#          a: território (RGI, unidade de Calzavara), fatia mínima (0; 0,05),
#          limiar do QL (2; 3, como Calzavara), só candidaturas competitivas, painel
#          desbalanceado (inclui PSD, Solidariedade, Novo etc.) e sensibilidade de
#          Rambachan & Roth (HonestDiD, magnitudes relativas).
#          As variantes usam o TWFE (id + ano), numericamente igual ao att_gt neste
#          desenho (um grupo tratado, sem covariáveis — checado em 03_did.R).
# Inputs:  output/dados/cand_territorio_{municipio,rgi}.rds (02_painel.R)
# Outputs: output/robustez.csv, output/honestdid.csv
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ec111-did-ql-municipio/R/04_robustez.R
# ==============================================================================

library(tidyverse)
library(fixest)
library(HonestDiD)

source("explorations/ec111-did-ql-municipio/R/funcoes.R")
set.seed(20261014)
out_dir   <- file.path("explorations", "ec111-did-ql-municipio", "output")
dados_dir <- file.path(out_dir, "dados")

resultados <- c("nova_base", "nova_base_mulher", "nova_base_negra")

#' Estima o event study TWFE para os resultados principais de um painel
#'
#' @param painel Saída de montar_painel().
#' @param variante Rótulo da variante.
#' @return tibble resultado × termo com estimativa, EP, média federal de 2018 e a
#'   parcela de g (razão das estimativas pontuais).
estimar_variante <- function(painel, variante) {
  painel <- painel |>
    filter(!is.na(nova_base)) |>
    mutate(across(all_of(resultados), \(x) 100 * x))
  est <- map(resultados, function(y) {
    f <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + ano")),
               data = painel, cluster = ~lista_id)
    broom::tidy(f) |>
      transmute(resultado = y, termo = str_extract(term, "20\\d\\d"), att = estimate,
                ep = std.error, ic_inf = att - 1.96 * ep, ic_sup = att + 1.96 * ep)
  }) |> list_rbind()
  tot <- est |> filter(resultado == "nova_base") |> select(termo, att_total = att)
  est |>
    left_join(tot, by = "termo") |>
    mutate(parcela_g = if_else(resultado == "nova_base" | termo == "2014", NA_real_,
                               att / att_total),
           variante = variante, unidades = n_distinct(painel$id),
           listas = n_distinct(painel$lista_id), .before = 1) |>
    select(-att_total)
}

#' Lê a base candidato × território só com as colunas que montar_painel() usa
#' (a base inteira ocupa vários GB na memória; a máquina de trabalho tem 8 GB)
ler_ct_enxuta <- function(arq) {
  readRDS(arq) |>
    select(ano, cargo, SG_UF, terr, partido, votos, QL, fatia, competitivo, mulher, negra,
           incumbente) |>
    mutate(across(c(cargo, SG_UF, partido), as.factor))
}

ct_mun <- ler_ct_enxuta(file.path(dados_dir, "cand_territorio_municipio.rds"))
gc()

variantes <- list(
  list(rotulo = "principal (município, QL>1, fatia≥0,025)", ct = "mun"),
  list(rotulo = "fatia ≥ 0 (só QL>1)", ct = "mun", fatia_min = 0),
  list(rotulo = "fatia ≥ 0,05", ct = "mun", fatia_min = 0.05),
  list(rotulo = "QL > 2", ct = "mun", ql_min = 2),
  list(rotulo = "QL > 3", ct = "mun", ql_min = 3),
  list(rotulo = "só candidaturas competitivas", ct = "mun", so_competitivas = TRUE),
  list(rotulo = "painel desbalanceado", ct = "mun", balanceado = FALSE)
)

rob <- map(variantes, function(v) {
  message("Variante: ", v$rotulo)
  p <- montar_painel(ct_mun, ql_min = v$ql_min %||% 1, fatia_min = v$fatia_min %||% 0.025,
                     so_competitivas = v$so_competitivas %||% FALSE,
                     balanceado = v$balanceado %||% TRUE)
  r <- estimar_variante(p, v$rotulo)
  rm(p); gc()
  r
}) |> list_rbind()
rm(ct_mun); gc()

# RGI (Calzavara): QL recalculado com os votos somados na RGI
ct_rgi <- ler_ct_enxuta(file.path(dados_dir, "cand_territorio_rgi.rds"))
rob <- bind_rows(rob, estimar_variante(montar_painel(ct_rgi), "RGI (unidade de Calzavara)"))
rm(ct_rgi); gc()

write_csv(rob, file.path(out_dir, "robustez.csv"))
print(rob |> filter(termo != "2014") |>
        select(variante, resultado, termo, att, ep, parcela_g), n = Inf)

# ==============================================================================
# HonestDiD — magnitudes relativas (Rambachan & Roth 2023)
# Um só pré-período (2014 contra 2018): M̄ limita a violação pós-tratamento a M̄
# vezes a maior violação observada no pré-período.
# ==============================================================================

painel <- readRDS(file.path(dados_dir, "painel_municipio.rds")) |>
  mutate(across(all_of(resultados), \(x) 100 * x))
mbar <- c(0, 0.5, 1, 1.5, 2)

honest <- map(resultados, function(y) {
  f <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + ano")),
             data = painel, cluster = ~lista_id)
  b <- coef(f); V <- vcov(f)   # ordem: 2014, 2022, 2026
  stopifnot(identical(str_extract(names(b), "20\\d\\d"), c("2014", "2022", "2026")))
  map(list(`2022` = c(1, 0), `2026` = c(0, 1)), function(l) {
    orig <- constructOriginalCS(betahat = b, sigma = V, numPrePeriods = 1,
                                numPostPeriods = 2, l_vec = l)
    sens <- createSensitivityResults_relativeMagnitudes(
      betahat = b, sigma = V, numPrePeriods = 1, numPostPeriods = 2, l_vec = l,
      Mbarvec = mbar)
    bind_rows(mutate(orig, Mbar = NA_real_), sens)
  }) |> list_rbind(names_to = "termo") |> mutate(resultado = y, .before = 1)
}) |> list_rbind()

# Valor de quebra: maior M̄ da grade cujo IC robusto ainda exclui zero
quebra <- honest |> filter(!is.na(Mbar)) |>
  summarise(Mbar_quebra = suppressWarnings(max(Mbar[lb > 0 | ub < 0])),
            .by = c(resultado, termo))
honest <- left_join(honest, quebra, by = c("resultado", "termo"))
write_csv(honest, file.path(out_dir, "honestdid.csv"))
print(honest, n = Inf)
