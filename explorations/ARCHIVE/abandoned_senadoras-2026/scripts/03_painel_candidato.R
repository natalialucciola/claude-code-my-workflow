# =============================================================================
# 03_painel_candidato.R
# Objetivo: construir o painel de candidatos por CPF através dos anos, para
#           derivar a variável de experiência política prévia (PP4). Ver
#           plano, Seção 4 (linha "candidata_experiente") e Seção 5 (PP4).
#
# Inputs:  dados/processados/candidatos_painel_bruto.rds
# Outputs: dados/processados/painel_experiencia.rds
#          (uma linha por candidatura, com as colunas adicionais:
#           ja_foi_candidata_antes, ja_foi_eleita_antes,
#           n_candidaturas_anteriores, cargos_anteriores)
# =============================================================================

library(dplyr)

painel <- readRDS("dados/processados/candidatos_painel_bruto.rds")

# --- Checagem prévia: o CPF é uma chave confiável? ------------------------
# TODO: testar manualmente antes de confiar nesta chave para o painel
# completo — o plano recomenda validar a taxa de matching entre dois
# anos-teste antes de generalizar (ex.: 2018 e 2022).
# teste <- painel %>% filter(ano %in% c(2018, 2022))
# table(duplicated(teste$cpf_candidato))

# TODO: construir, para cada candidatura (linha), se a mesma pessoa (mesmo
# cpf_candidato) aparece em anos anteriores no painel, e se em algum desses
# anos anteriores teve sit_totalizacao == "ELEITO" (ajustar valores exatos
# encontrados nos dados — variam por ano, ex. "ELEITO", "ELEITO POR QP",
# "ELEITO POR MÉDIA").
#
# painel_experiencia <- painel %>%
#   arrange(cpf_candidato, ano) %>%
#   group_by(cpf_candidato) %>%
#   mutate(
#     ja_foi_candidata_antes = row_number() > 1,
#     n_candidaturas_anteriores = row_number() - 1,
#     ja_foi_eleita_antes = cumsum(sit_totalizacao %in% c("ELEITO", "ELEITO POR QP", "ELEITO POR MÉDIA")) -
#       (sit_totalizacao %in% c("ELEITO", "ELEITO POR QP", "ELEITO POR MÉDIA")) > 0
#   ) %>%
#   ungroup()
#
# saveRDS(painel_experiencia, "dados/processados/painel_experiencia.rds")

# Nota: para 2026, sit_totalizacao ainda não existirá (eleição não ocorreu
# na data deste projeto) — a variável ja_foi_eleita_antes olha só para o
# PASSADO da candidata, então funciona normalmente mesmo para as
# candidaturas de 2026.
