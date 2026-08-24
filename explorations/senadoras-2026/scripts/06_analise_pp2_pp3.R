# =============================================================================
# 06_analise_pp2_pp3.R
# Objetivo: responder a PP2 (oferta partidária / tamanho do partido) e PP3
#           (substituição entre cargos). Ver plano, Seção 5.
#
# Inputs:  dados/processados/candidatos_painel_bruto.rds
#          dados/processados/tamanho_partido_ano.rds
# Outputs: outputs/tabelas/pp2_modelo_logistico.csv (coeficientes)
#          outputs/tabelas/pp2_ranking_partidos.csv
#          outputs/tabelas/pp3_share_por_cargo_partido.csv
#          outputs/tabelas/pp3_modelo_efeitos_fixos.csv
# =============================================================================

library(dplyr)
library(readr)
# library(fixest) # ou plm — escolher pacote de efeitos fixos ao implementar

painel <- readRDS("dados/processados/candidatos_painel_bruto.rds")
tamanho_partido <- readRDS("dados/processados/tamanho_partido_ano.rds")

# =========================== PP2 ============================================
# TODO: juntar painel (cargo == SENADOR) com tamanho_partido por partido/ano.
# base_pp2 <- painel %>% filter(cargo == "SENADOR") %>%
#   left_join(tamanho_partido, by = c("partido", "ano"))
#
# TODO: modelo logístico
# mulher ~ tercil_tamanho + uf + ano + ano:tercil_tamanho
# (clusterizar erro-padrão por partido — ver pacote sandwich/clubSandwich
# ou fixest com cluster = ~partido)
#
# TODO: ranking descritivo de partidos por Δ do share de mulheres ao Senado
# entre 2018 e 2026, cruzado com tercil de tamanho em 2018 (mais
# interpretável para o texto do artigo do que só o coeficiente do modelo).

# =========================== PP3 ============================================
CARGOS_COMPARACAO <- c(
  "SENADOR", "DEPUTADO FEDERAL", "GOVERNADOR", "VICE-GOVERNADOR",
  "PRESIDENTE", "VICE-PRESIDENTE"
)

# TODO: construir share_mulheres_cargo_partido_ano (ver plano, Seção 4)
# painel_pp3 <- painel %>%
#   filter(cargo %in% CARGOS_COMPARACAO) %>%
#   group_by(partido, cargo, ano) %>%
#   summarise(
#     n_mulheres = sum(sexo == "FEMININO"),
#     n_total = n(),
#     share_mulheres = n_mulheres / n_total,
#     .groups = "drop"
#   )
# write_csv(painel_pp3, "outputs/tabelas/pp3_share_por_cargo_partido.csv")

# TODO: modelo de efeitos fixos de partido e ano (ou diff-in-diff) testando
# se aumento do share de mulheres no Senado, dentro do partido, correlaciona
# negativamente com o share de mulheres do mesmo partido em outros cargos no
# mesmo ciclo. LEMBRAR: discutir na interpretação que cargos proporcionais
# (Deputado Federal) têm piso legal de 30% (cota de gênero), diferente dos
# majoritários (Governador, Vice, Presidente/Vice) — a hipótese de
# substituição é estruturalmente mais plausível entre cargos majoritários.
