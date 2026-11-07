# ==============================================================================
# Script: 03_ddd.R
# Purpose: Tripla diferença (Federal × período pós-EC 111 × grupo) sobre a taxa
#          de sobreposição com QL do VOTO — versão de 03_ddd_incentivo_2022.R
#          do Capítulo 6, estendida a 2026.
#
# Especificações (todas com EF de partido e UF, cluster partido + UF, como no
# capítulo; sem controle por incumbência/resultado na principal — "bad
# control", ver cabeçalho do script original):
#   (1) Réplica 2018–2022:  taxa ~ federal * ano2022 * grupo
#   (2) Três eleições:      taxa ~ federal * grupo * (ano2022 + ano2026)
#       → federal:grupo:ano2022 e federal:grupo:ano2026, ambos contra 2018.
#       2026 é o segundo ciclo sob o incentivo da EC 111/2021 (contagem em
#       dobro de votos de mulheres e negros para a distribuição do FEFC e do
#       Fundo Partidário, 2022–2030).
#   (3) Pós agrupado:       taxa ~ federal * pos * grupo   (pos = 2022 ou 2026)
#   (4)–(5) Decomposições de (2) controlando por incumbência e por resultado.
#
# Inputs:  explorations/ql-voto-2026/output/taxa_sobreposicao_candidato.rds,
#          cand_mun_ql1.rds, incumbencia_completa_candidato.rds (02_...R)
# Outputs: explorations/ql-voto-2026/output/
#          ddd_modelos.rds (lista de modelos fixest), ddd_coeficientes.csv,
#          ddd_genero.tex, ddd_raca.tex, ddd_suporte_celula.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/03_ddd.R
# ==============================================================================

library(tidyverse)
library(fixest)

source("explorations/ql-voto-2026/R/config.R")  # out_dir da variante

# ==============================================================================
# 1. BASE
# ==============================================================================

resultado_por_candidato <- readRDS(file.path(out_dir, "cand_mun_ql1.rds")) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, eleito, competitivo) |>
  mutate(resultado = case_when(
    eleito == 1                    ~ "Eleito",
    competitivo == 1 & eleito == 0 ~ "Competitivo",
    competitivo == 0 & eleito == 0 ~ "Nao_competitivo",
    TRUE ~ NA_character_
  )) |>
  select(sq_candidato, cargo, ANO_ELEICAO, resultado)

base <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds")) |>
  left_join(readRDS(file.path(out_dir, "incumbencia_completa_candidato.rds")),
            by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  left_join(resultado_por_candidato, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    ano2026 = as.integer(ANO_ELEICAO == "2026"),
    pos     = as.integer(ANO_ELEICAO %in% c("2022", "2026")),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA")
  )

grupos <- list(
  genero = list(var = "mulher", filtro = quote(genero %in% c("FEMININO", "MASCULINO"))),
  raca   = list(var = "negra",  filtro = quote(raca2 %in% c("BRANCA", "NEGRA")))
)

# ==============================================================================
# 2. ESTIMAÇÃO
# ==============================================================================

#' Estima as cinco especificações para um grupo (gênero ou raça)
#'
#' @param g Elemento de `grupos`.
#' @return Lista nomeada de modelos fixest + tabela de suporte por célula.
estimar_grupo <- function(g) {
  df <- filter(base, !!g$filtro)
  v  <- g$var
  est <- function(rhs, dados) {
    m <- feols(as.formula(paste("taxa_sobreposicao ~", rhs, "| partido_harm + SG_UF")),
               data = dados, cluster = ~ partido_harm + SG_UF)
    if (length(m$collin.var) > 0) {
      warning(v, ": colinear absorvida pelos EF — ", paste(m$collin.var, collapse = ", "))
    }
    m
  }
  tres <- sprintf("federal * %s * ano2022 + federal * %s * ano2026", v, v)
  list(
    modelos = list(
      replica_2018_2022 = est(sprintf("federal * ano2022 * %s", v),
                              filter(df, ANO_ELEICAO != "2026")),
      tres_eleicoes     = est(tres, df),
      pos_agrupado      = est(sprintf("federal * pos * %s", v), df),
      tres_incumbencia  = est(paste(tres, "+ incumbente"), filter(df, !is.na(incumbente))),
      tres_resultado    = est(paste(tres, "+ resultado"), filter(df, !is.na(resultado)))
    ),
    suporte = df |>
      summarise(n = n(), .by = c(cargo, ANO_ELEICAO, all_of(v))) |>
      rename(grupo = all_of(v)) |>
      arrange(cargo, ANO_ELEICAO, grupo)
  )
}

resultados <- map(grupos, estimar_grupo)
modelos <- map(resultados, "modelos")

# ==============================================================================
# 3. COEFICIENTES DE INTERESSE
# ==============================================================================

coeficientes <- imap(modelos, \(ms, grupo) {
  imap(ms, \(m, espec) {
    broom::tidy(m, conf.int = TRUE) |>
      filter(str_detect(term, "federal") & str_detect(term, "mulher|negra") &
               str_detect(term, "ano2022|ano2026|pos")) |>
      mutate(especificacao = espec, n_obs = nobs(m))
  }) |> list_rbind() |> mutate(grupo = grupo)
}) |>
  list_rbind() |>
  select(grupo, especificacao, term, estimate, std.error, conf.low, conf.high, p.value, n_obs)

print(coeficientes, n = 50)

suporte <- imap(resultados, \(r, grupo) mutate(r$suporte, dimensao = grupo)) |> list_rbind()

# ==============================================================================
# 4. SALVAR
# ==============================================================================

saveRDS(modelos, file.path(out_dir, "ddd_modelos.rds"))
write_csv(coeficientes, file.path(out_dir, "ddd_coeficientes.csv"))
write_csv(suporte, file.path(out_dir, "ddd_suporte_celula.csv"))

for (grupo in names(modelos)) {
  etable(modelos[[grupo]], tex = TRUE, replace = TRUE,
         file = file.path(out_dir, sprintf("ddd_%s.tex", grupo)),
         headers = names(modelos[[grupo]]))
}

message("\n=== DDD (QL do voto) concluída — modelos e coeficientes em ", out_dir, " ===")
