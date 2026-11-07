# =============================================================================
# 04_tamanho_partido.R
# Objetivo: construir a variável de tamanho/força do partido antes de cada
#           eleição (tamanho_partido), para uso na PP2. Ver plano, Seção 4
#           e Seção 5 (PP2).
#
# Inputs:  dados eleitorais de composição partidária (party_composition() /
#          seats_fed() do electionsBR, ou base equivalente do CEPESPdata)
# Outputs: dados/processados/tamanho_partido_ano.rds
#          (uma linha por partido/ano, com o número de cadeiras na Câmara
#           e/ou Senado imediatamente antes do registro de candidaturas
#           daquele ano)
# =============================================================================

library(electionsBR)
library(dplyr)

# TODO: usar party_composition() ou seats_fed() (ou o equivalente via
# elections_tse(type = "seats"), dependendo da API confirmada em
# 00_setup.R) para obter o número de cadeiras por partido, no ano
# IMEDIATAMENTE ANTERIOR a cada eleição do escopo (ex.: para classificar
# partidos na eleição de 2026, usar a composição da Câmara/Senado vigente
# em 2026, antes do pleito — ou seja, resultado da eleição de 2022).
#
# tamanho_partido_ano <- ... %>%
#   group_by(partido, ano_eleicao_alvo) %>%
#   summarise(cadeiras = n(), .groups = "drop") %>%
#   mutate(
#     tercil_tamanho = ntile(cadeiras, 3) # 1 = pequeno, 3 = grande
#   )
#
# saveRDS(tamanho_partido_ano, "dados/processados/tamanho_partido_ano.rds")
