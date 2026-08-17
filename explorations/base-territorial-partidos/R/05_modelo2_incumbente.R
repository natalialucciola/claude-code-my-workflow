# ==============================================================================
# Modelo 2: sobreposição territorial especificamente com correligionários
# INCUMBENTES (proxy de "candidato tradicional/estabelecido" do partido) — e
# alcance territorial total (H5).
#
# Mecanismo testado (H4): lideranças partidárias aproveitam o incentivo
# financeiro de 2022 (EC 111/2021, art. 2º) para fazer candidatas mulheres e
# candidatos negros buscarem mais votos SEM deixá-los competir com os
# candidatos tradicionais/consolidados do partido. Se isso for verdade, a
# queda federal-específica na sobreposição territorial em 2022 deveria ser
# MAIOR quando medida especificamente contra correligionários incumbentes
# (Modelo 2, aqui) do que contra qualquer correligionário (Modelo 1, em
# 03_ddd_incentivo_2022.R) — a queda é direcionada, não difusa.
#
# H5 (secundária, "cresce sem confrontar"): ao mesmo tempo, o alcance
# territorial total de mulheres/negros (nº de municípios QL>1) deveria CRESCER
# de forma federal-específica em 2022 — a assinatura conjunta de "expandir sem
# ameaçar" que H4 e H5 testam em conjunto.
#
# Amostra principal do Modelo 2 (H4): candidatos NÃO incumbentes — a pergunta
# é sobre desafiantes evitando o território de líderes já estabelecidos; um
# incumbente sobrepor-se a outro incumbente é uma pergunta diferente, fora do
# escopo do mecanismo. Amostra completa entra como robustez.
#
# H5 usa a amostra completa (o sujeito de interesse é o crescimento do próprio
# candidato incentivado, incumbente ou não).
#
# Pré-requisito: rodar R/01_overlap_partido.R e R/03_ddd_incentivo_2022.R antes
# (usa cand_mun_ql1.rds, incumbencia_completa_candidato.rds e
# taxa_sobreposicao_candidato.rds, todos salvos em output/ por esses scripts).
# ==============================================================================

library(tidyverse)
library(fixest)

out_dir <- "explorations/base-territorial-partidos/output"

# ==============================================================================
# 1. BASE — candidato-município (QL>1) com incumbência do correligionário
# ==============================================================================

cand_mun_ql1 <- readRDS(file.path(out_dir, "cand_mun_ql1.rds"))
incumbencia  <- readRDS(file.path(out_dir, "incumbencia_completa_candidato.rds"))

cand_inc <- cand_mun_ql1 |>
  left_join(incumbencia, by = c("sq_candidato", "cargo", "ANO_ELEICAO"))

message("Linhas candidato-município (QL>1): ", nrow(cand_inc),
        " | sem incumbência identificada: ", sum(is.na(cand_inc$incumbente)))

cand_inc <- cand_inc |> filter(!is.na(incumbente))

# Para cada (partido, cargo, ano, UF, município), quantos candidatos
# INCUMBENTES distintos do partido têm QL > 1 ali?
mun_incumbente_count <- cand_inc |>
  filter(incumbente == 1) |>
  summarise(
    n_incumbentes_ql1 = n_distinct(sq_candidato),
    .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)
  )

# overlap_incumbente = existe ALGUM OUTRO candidato incumbente do partido
# (diferente de si mesmo) com QL>1 no mesmo município. Subtrair o próprio
# candidato do contador quando ele mesmo é incumbente evita contar
# auto-sobreposição.
cand_mun_incumbente <- cand_inc |>
  left_join(mun_incumbente_count,
            by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")) |>
  mutate(
    n_incumbentes_ql1     = replace_na(n_incumbentes_ql1, 0L),
    n_outros_incumbentes  = n_incumbentes_ql1 - incumbente,
    overlap_incumbente    = n_outros_incumbentes >= 1
  )

# ==============================================================================
# 2. NÍVEL CANDIDATO — taxa_sobreposicao_incumbente
# ==============================================================================

taxa_incumbente <- cand_mun_incumbente |>
  summarise(
    n_mun_ql1                    = n(),
    n_mun_overlap_incumbente     = sum(overlap_incumbente),
    taxa_sobreposicao_incumbente = n_mun_overlap_incumbente / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, genero, raca2, incumbente)
  )

message("\nCandidatos com incumbência identificada e >=1 município QL>1: ", nrow(taxa_incumbente))
message("  dos quais NÃO incumbentes (amostra principal do Modelo 2): ",
        sum(taxa_incumbente$incumbente == 0))

saveRDS(taxa_incumbente, file.path(out_dir, "taxa_sobreposicao_incumbente_candidato.rds"))

# ==============================================================================
# 3. MODELO 2 (H4) — DDD sobre taxa_sobreposicao_incumbente
#    Amostra principal: candidatos NÃO incumbentes
# ==============================================================================

base_modelo2 <- taxa_incumbente |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA")
  )

nao_incumbentes <- base_modelo2 |> filter(incumbente == 0)

# ---- Gênero ----
df_m2_genero <- nao_incumbentes |> filter(genero %in% c("FEMININO", "MASCULINO"))

message("\n--- Suporte por célula (Modelo 2, gênero, não incumbentes) ---")
print(df_m2_genero |> summarise(n = n(), .by = c(cargo, ANO_ELEICAO, mulher)) |>
        arrange(cargo, ANO_ELEICAO, mulher))

modelo2_genero <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m2_genero, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 2 (H4) — Gênero, não incumbentes ===")
print(summary(modelo2_genero))

# ---- Raça ----
df_m2_raca <- nao_incumbentes |> filter(raca2 %in% c("BRANCA", "NEGRA"))

message("\n--- Suporte por célula (Modelo 2, raça, não incumbentes) ---")
print(df_m2_raca |> summarise(n = n(), .by = c(cargo, ANO_ELEICAO, negra)) |>
        arrange(cargo, ANO_ELEICAO, negra))

modelo2_raca <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m2_raca, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 2 (H4) — Raça, não incumbentes ===")
print(summary(modelo2_raca))

# ---- Robustez: amostra completa (incumbentes + não incumbentes) ----
df_m2_genero_full <- base_modelo2 |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo2_genero_full <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m2_genero_full, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 2 (H4) — Gênero, amostra completa (robustez) ===")
print(summary(modelo2_genero_full))

df_m2_raca_full <- base_modelo2 |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo2_raca_full <- feols(
  taxa_sobreposicao_incumbente ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m2_raca_full, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 2 (H4) — Raça, amostra completa (robustez) ===")
print(summary(modelo2_raca_full))

# ==============================================================================
# 4. H5 — ALCANCE TERRITORIAL TOTAL (amostra completa)
#    alcance_total_i = nº de municípios com QL>1 (já computado como n_mun_ql1
#    em taxa_sobreposicao_candidato.rds, gerado por 01_overlap_partido.R)
# ==============================================================================

taxa_geral <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds"))

uf_por_candidato <- cand_mun_ql1 |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, SG_UF)

alcance_total <- taxa_geral |>
  left_join(uf_por_candidato, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA"),
    alcance_total = n_mun_ql1
  )

saveRDS(alcance_total, file.path(out_dir, "alcance_total_candidato.rds"))

df_alcance_genero <- alcance_total |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo_alcance_genero <- feols(
  alcance_total ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_alcance_genero, cluster = ~ partido_harm + SG_UF
)
message("\n=== H5 — Alcance territorial total, Gênero ===")
print(summary(modelo_alcance_genero))

df_alcance_raca <- alcance_total |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo_alcance_raca <- feols(
  alcance_total ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_alcance_raca, cluster = ~ partido_harm + SG_UF
)
message("\n=== H5 — Alcance territorial total, Raça ===")
print(summary(modelo_alcance_raca))

# ==============================================================================
# 5. SALVAR
# ==============================================================================

saveRDS(modelo2_genero,        file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
saveRDS(modelo2_raca,          file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))
saveRDS(modelo2_genero_full,   file.path(out_dir, "ddd_modelo2_genero_incumbente_completa.rds"))
saveRDS(modelo2_raca_full,     file.path(out_dir, "ddd_modelo2_raca_incumbente_completa.rds"))
saveRDS(modelo_alcance_genero, file.path(out_dir, "ddd_alcance_genero.rds"))
saveRDS(modelo_alcance_raca,   file.path(out_dir, "ddd_alcance_raca.rds"))

etable(modelo2_genero, modelo2_genero_full,
       file = file.path(out_dir, "ddd_modelo2_genero_especificacoes.tex"), replace = TRUE)
etable(modelo2_raca, modelo2_raca_full,
       file = file.path(out_dir, "ddd_modelo2_raca_especificacoes.tex"), replace = TRUE)

message("\n=== Modelo 2 (H4) + Alcance total (H5) concluído — modelos salvos em ", out_dir, " ===")
