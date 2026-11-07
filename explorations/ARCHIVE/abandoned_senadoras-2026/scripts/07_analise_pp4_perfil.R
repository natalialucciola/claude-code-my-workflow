# =============================================================================
# 07_analise_pp4_perfil.R
# Objetivo: responder a PP4 (perfil e experiência das candidatas). Ver
#           plano, Seção 5, "PP4 — Perfil e experiência".
#
# Inputs:  dados/processados/painel_experiencia.rds
# Outputs: outputs/tabelas/pp4_comparacao_2026_vs_anteriores.csv
#          outputs/tabelas/pp4_comparacao_mulheres_vs_homens_2026.csv
# =============================================================================

library(dplyr)
library(readr)

painel_exp <- readRDS("dados/processados/painel_experiencia.rds") %>%
  filter(cargo == "SENADOR")

# --- 1. Candidatas 2026 vs. candidatas de eleições anteriores -------------
# Comparação central sugerida no plano: 2026 vs. 2018 (mesmo desenho de
# vagas, 2/3). Demais anos como contexto de série longa.
#
# TODO:
# comparacao_temporal <- painel_exp %>%
#   filter(sexo == "FEMININO", ano %in% c(2018, 2026)) %>%
#   group_by(ano) %>%
#   summarise(
#     pct_ja_foi_candidata = mean(ja_foi_candidata_antes, na.rm = TRUE),
#     pct_ja_foi_eleita = mean(ja_foi_eleita_antes, na.rm = TRUE),
#     idade_media = mean(idade, na.rm = TRUE),
#     # escolaridade, ocupação, raça/cor: usar as categorias exatas
#     # encontradas nos dados (registrar no dicionário de colunas)
#     .groups = "drop"
#   )
# write_csv(comparacao_temporal, "outputs/tabelas/pp4_comparacao_2026_vs_anteriores.csv")

# --- 2. Candidatas 2026 vs. candidatos homens 2026 -------------------------
# TODO: mesma lógica acima, mas comparando sexo dentro do ano de 2026, para
# isolar se o diferencial de experiência é específico do sexo ou reflexo
# geral do perfil de quem concorre ao Senado.

# --- 3. Nota qualitativa (não estatística) ---------------------------------
# Cruzar as candidatas líderes nas pesquisas eleitorais (dado já levantado
# manualmente: Marina Silva e Simone Tebet em SP; Gracinha Caiado em GO;
# Marília Arraes em PE; Marília Campos em MG; Benedita da Silva no RJ;
# Manuela D'Ávila no RS) com painel_experiencia para verificar se são todas
# "nomes fortes" (ex-ministras, senadoras em exercício, deputadas federais)
# — relevante para discutir a hipótese H3 (vitrine/tokenismo) na seção de
# discussão do artigo.
