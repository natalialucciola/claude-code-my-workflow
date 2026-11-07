# =============================================================================
# 05_analise_pp1_descritiva.R
# Objetivo: responder a PP1 (descritiva) — ver plano, Seção 5, "PP1 —
#           Descritiva". Produz as séries históricas nacional, por UF e por
#           partido, e os testes de proporção comparando 2026 com anos
#           anteriores.
#
# Inputs:  dados/processados/candidatos_painel_bruto.rds (filtrado para
#          cargo == "SENADOR")
# Outputs: outputs/tabelas/pp1_serie_nacional.csv
#          outputs/tabelas/pp1_serie_uf.csv
#          outputs/tabelas/pp1_serie_partido.csv
#          outputs/tabelas/pp1_testes_proporcao.csv
#          outputs/figuras/pp1_serie_nacional.png
#          outputs/figuras/pp1_heatmap_uf.png
# =============================================================================

library(dplyr)
library(ggplot2)
library(readr)

painel <- readRDS("dados/processados/candidatos_painel_bruto.rds") %>%
  filter(cargo == "SENADOR")

# --- 1. Série histórica nacional ------------------------------------------
# TODO: nº e % de candidatas por ano; anotar visualmente quais anos são de
# renovação 1/3 vs. 2/3 (2014=1/3, 2018=2/3, 2022=1/3, 2026=2/3 — ver plano,
# Seção 3, nota sobre desenho de renovação). Comparação "maçã com maçã"
# central: 2026 vs. 2018 (ambos 2/3).
#
# serie_nacional <- painel %>%
#   group_by(ano) %>%
#   summarise(
#     n_candidatas = sum(sexo == "FEMININO"),
#     n_total = n(),
#     pct_candidatas = n_candidatas / n_total,
#     renovacao = if_else(ano %in% c(2014, 2022), "1/3", "2/3") # ajustar
#                                                                # conforme
#                                                                # anos < 2014
#   )
# write_csv(serie_nacional, "outputs/tabelas/pp1_serie_nacional.csv")

# --- 2. Série por UF ---------------------------------------------------
# TODO: nº e % de candidatas por UF e ano — heatmap.

# --- 3. Série por partido -----------------------------------------------
# TODO: nº e % de candidatas por partido e ano, ranqueado por Δ 2018→2026.

# --- 4. Testes de proporção ----------------------------------------------
# TODO: prop.test() ou chisq.test() comparando 2026 vs. cada ano anterior,
# nacional e por UF (atenção a N pequeno por UF — considerar teste exato de
# Fisher como alternativa/robustez).

# --- 5. Checagem contra números já apurados manualmente -------------------
# 2026: 69 candidatas mulheres, 22% de 315 candidaturas totais ao Senado.
# RN, SC, SP: 5 candidatas cada (máximo). AC, AL, AM, BA, MS, PB, SE, TO:
# 1 candidata cada (mínimo). Todos os 27 estados/DF com pelo menos 1
# candidata pela primeira vez desde 2014.
