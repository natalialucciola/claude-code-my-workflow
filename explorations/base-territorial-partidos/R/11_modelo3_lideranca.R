# ==============================================================================
# Modelo 3: sobreposição territorial especificamente com correligionários que
# são LÍDERES FORMAIS DO PARTIDO (Presidente/Vice-Presidente/Secretário de
# Finanças, nacional ou do diretório estadual/DF) — proxy direta de "poder de
# decisão sobre a alocação de recursos do partido", via TSE/SGIP
# (R/09_titulo_eleitoral_2018_2022.R, R/10_lideranca_partido.R).
#
# Resolve a mesma lacuna de medição do Modelo 2 (incumbência ignora troca de
# partido — Limitação 8/MC3 do capítulo): liderança formal é definida sobre
# o PARTIDO ATUAL do candidato em cada ciclo, não sobre um cargo ocupado no
# passado independente do partido. Mesmo mecanismo teórico do Modelo 2
# (H4/proteção de lideranças), medido de forma mais direta.
#
# Escopo de liderança (decisão da usuária, 2026-08-16): NACIONAL conta em
# qualquer UF (fisicamente só importa na UF onde o próprio líder concorre,
# já que sobreposição exige QL>1 no MESMO município); ESTADUAL/REGIONAL(DF)
# conta apenas na própria UF. Ver R/10_lideranca_partido.R para o
# detalhamento e a correção do fallback de sigla histórica (PR->PL,
# PRB->REPUBLICANOS, PPS->CIDADANIA, PTC->AGIR).
#
# lider_partido é NA (não 0) para candidatos de PMB/PMN — únicos dois
# partidos da amostra sem NENHUM registro de órgão partidário no TSE, sob
# nenhum nome (checagem de sanidade, 2026-08-16): "sem dado", não
# "não-líder". Esses candidatos são excluídos da análise (mesmo tratamento
# de incumbência ausente no Modelo 2).
#
# Amostra principal: candidatos que NÃO são eles mesmos líderes do partido
# (mesmo racional do Modelo 2 — a pergunta é sobre desafiantes evitando o
# território de quem já tem poder formal). Amostra completa como robustez.
#
# Pré-requisito: rodar R/01_overlap_partido.R, R/09_titulo_eleitoral_2018_2022.R
# e R/10_lideranca_partido.R antes (usa cand_mun_ql1.rds,
# titulo_eleitoral_candidato.rds e lideranca_candidato.rds/lideranca_raw.rds,
# todos salvos em output/).
# ==============================================================================

library(tidyverse)
library(fixest)

out_dir <- "explorations/base-territorial-partidos/output"

# ==============================================================================
# 1. STATUS DE LIDERANÇA POR CANDIDATO (1 / 0 / NA)
# ==============================================================================

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

normalizar_sigla <- function(x) {
  x |> str_to_upper() |> iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |> str_remove_all("[^A-Z0-9]")
}

arquivos <- unzip(file.path(out_dir, "raw_tse_orgaos", "orgao_partidario.zip"), list = TRUE)$Name
arquivos <- arquivos[str_detect(arquivos, "^orgao_partidario_.*[.]csv$")]
siglas_disponiveis_norm <- normalizar_sigla(sub("^orgao_partidario_", "", sub("[.]csv$", "", arquivos)))

resolver_sigla_busca <- function(sigla) {
  sn <- normalizar_sigla(sigla)
  shn <- normalizar_sigla(harmonizar_partido(sigla))
  case_when(
    sn %in% siglas_disponiveis_norm ~ sn,
    shn %in% siglas_disponiveis_norm ~ shn,
    TRUE ~ NA_character_
  )
}

titulo_cand <- readRDS(file.path(out_dir, "titulo_eleitoral_candidato.rds")) |>
  mutate(sigla_busca = resolver_sigla_busca(SG_PARTIDO))

lideres_matched <- readRDS(file.path(out_dir, "lideranca_candidato.rds")) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO) |>
  mutate(lider_match = 1L)

status_lideranca <- titulo_cand |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, sigla_busca) |>
  left_join(lideres_matched, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(lider_partido = case_when(
    is.na(sigla_busca) ~ NA_integer_,
    !is.na(lider_match) ~ 1L,
    TRUE ~ 0L
  )) |>
  select(sq_candidato, cargo, ANO_ELEICAO, lider_partido)

message("Status de liderança — distribuição: ")
print(status_lideranca |> count(lider_partido))

# ==============================================================================
# 2. BASE — candidato-município (QL>1) com status de liderança do correligionário
# ==============================================================================

cand_mun_ql1 <- readRDS(file.path(out_dir, "cand_mun_ql1.rds"))

cand_lid <- cand_mun_ql1 |>
  left_join(status_lideranca, by = c("sq_candidato", "cargo", "ANO_ELEICAO"))

message("Linhas candidato-município (QL>1): ", nrow(cand_lid),
        " | sem status de liderança identificado (PMB/PMN): ", sum(is.na(cand_lid$lider_partido)))

cand_lid <- cand_lid |> filter(!is.na(lider_partido))

# Para cada (partido, cargo, ano, UF, município), quantos candidatos LÍDERES
# distintos do partido têm QL > 1 ali?
mun_lider_count <- cand_lid |>
  filter(lider_partido == 1) |>
  summarise(
    n_lideres_ql1 = n_distinct(sq_candidato),
    .by = c(cargo, ANO_ELEICAO, partido_harm, SG_UF, COD_MUN_TSE)
  )

# overlap_lideranca = existe ALGUM OUTRO candidato líder do partido
# (diferente de si mesmo) com QL>1 no mesmo município.
cand_mun_lideranca <- cand_lid |>
  left_join(mun_lider_count,
            by = c("cargo", "ANO_ELEICAO", "partido_harm", "SG_UF", "COD_MUN_TSE")) |>
  mutate(
    n_lideres_ql1      = replace_na(n_lideres_ql1, 0L),
    n_outros_lideres    = n_lideres_ql1 - lider_partido,
    overlap_lideranca   = n_outros_lideres >= 1
  )

# ==============================================================================
# 3. NÍVEL CANDIDATO — taxa_sobreposicao_lideranca
# ==============================================================================

taxa_lideranca <- cand_mun_lideranca |>
  summarise(
    n_mun_ql1                  = n(),
    n_mun_overlap_lideranca    = sum(overlap_lideranca),
    taxa_sobreposicao_lideranca = n_mun_overlap_lideranca / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, SG_UF, genero, raca2, lider_partido)
  )

message("\nCandidatos com status de liderança identificado e >=1 município QL>1: ", nrow(taxa_lideranca))
message("  dos quais NÃO líderes (amostra principal do Modelo 3): ",
        sum(taxa_lideranca$lider_partido == 0))

saveRDS(taxa_lideranca, file.path(out_dir, "taxa_sobreposicao_lideranca_candidato.rds"))

# ==============================================================================
# 4. MODELO 3 — DDD sobre taxa_sobreposicao_lideranca
#    Amostra principal: candidatos que NÃO são eles mesmos líderes
# ==============================================================================

base_modelo3 <- taxa_lideranca |>
  mutate(
    federal = as.integer(cargo == "Federal"),
    ano2022 = as.integer(ANO_ELEICAO == "2022"),
    mulher  = as.integer(genero == "FEMININO"),
    negra   = as.integer(raca2 == "NEGRA")
  )

nao_lideres <- base_modelo3 |> filter(lider_partido == 0)

# ---- Gênero ----
df_m3_genero <- nao_lideres |> filter(genero %in% c("FEMININO", "MASCULINO"))

message("\n--- Suporte por célula (Modelo 3, gênero, não líderes) ---")
print(df_m3_genero |> summarise(n = n(), .by = c(cargo, ANO_ELEICAO, mulher)) |>
        arrange(cargo, ANO_ELEICAO, mulher))

modelo3_genero <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m3_genero, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 3 — Gênero, não líderes ===")
print(summary(modelo3_genero))

# ---- Raça ----
df_m3_raca <- nao_lideres |> filter(raca2 %in% c("BRANCA", "NEGRA"))

message("\n--- Suporte por célula (Modelo 3, raça, não líderes) ---")
print(df_m3_raca |> summarise(n = n(), .by = c(cargo, ANO_ELEICAO, negra)) |>
        arrange(cargo, ANO_ELEICAO, negra))

modelo3_raca <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m3_raca, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 3 — Raça, não líderes ===")
print(summary(modelo3_raca))

# ---- Robustez: amostra completa (líderes + não líderes) ----
df_m3_genero_full <- base_modelo3 |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo3_genero_full <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m3_genero_full, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 3 — Gênero, amostra completa (robustez) ===")
print(summary(modelo3_genero_full))

df_m3_raca_full <- base_modelo3 |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo3_raca_full <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m3_raca_full, cluster = ~ partido_harm + SG_UF
)
message("\n=== Modelo 3 — Raça, amostra completa (robustez) ===")
print(summary(modelo3_raca_full))

# ==============================================================================
# 5. COMPARAÇÃO RÁPIDA COM MODELO 1 E MODELO 2 (console apenas — sem tabela
#    formatada ainda, decisão de como/se isso entra no capítulo fica para
#    depois de revisar os números)
# ==============================================================================

modelo1_genero <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
modelo1_raca   <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
modelo2_genero <- readRDS(file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
modelo2_raca   <- readRDS(file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))

extrair_triplo <- function(m) {
  ct <- coeftable(m)
  linha <- grep("federal:ano2022:(mulher|negra)$", rownames(ct), value = TRUE)
  ct[linha, c("Estimate", "Std. Error", "Pr(>|t|)")]
}

message("\n=== Comparação Modelo 1 vs. Modelo 2 vs. Modelo 3 (coeficiente da tripla interação) ===")
message("Gênero:")
message("  Modelo 1 (qualquer correligionário):     ", paste(round(extrair_triplo(modelo1_genero), 4), collapse = " | "))
message("  Modelo 2 (correligionário incumbente):   ", paste(round(extrair_triplo(modelo2_genero), 4), collapse = " | "))
message("  Modelo 3 (correligionário líder partido): ", paste(round(extrair_triplo(modelo3_genero), 4), collapse = " | "))
message("Raça:")
message("  Modelo 1 (qualquer correligionário):     ", paste(round(extrair_triplo(modelo1_raca), 4), collapse = " | "))
message("  Modelo 2 (correligionário incumbente):   ", paste(round(extrair_triplo(modelo2_raca), 4), collapse = " | "))
message("  Modelo 3 (correligionário líder partido): ", paste(round(extrair_triplo(modelo3_raca), 4), collapse = " | "))

# ==============================================================================
# 6. SALVAR
# ==============================================================================

saveRDS(modelo3_genero,      file.path(out_dir, "ddd_modelo3_genero_lideranca.rds"))
saveRDS(modelo3_raca,        file.path(out_dir, "ddd_modelo3_raca_lideranca.rds"))
saveRDS(modelo3_genero_full, file.path(out_dir, "ddd_modelo3_genero_lideranca_completa.rds"))
saveRDS(modelo3_raca_full,   file.path(out_dir, "ddd_modelo3_raca_lideranca_completa.rds"))

etable(modelo3_genero, modelo3_genero_full,
       file = file.path(out_dir, "ddd_modelo3_genero_especificacoes.tex"), replace = TRUE)
etable(modelo3_raca, modelo3_raca_full,
       file = file.path(out_dir, "ddd_modelo3_raca_especificacoes.tex"), replace = TRUE)

message("\n=== Modelo 3 concluído — modelos salvos em ", out_dir, " ===")
