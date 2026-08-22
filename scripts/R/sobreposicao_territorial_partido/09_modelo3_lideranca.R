# ==============================================================================
# Modelo 3: sobreposição territorial especificamente com correligionários que
# são LÍDERES FORMAIS DO PARTIDO (Presidente/Vice-Presidente/Secretário de
# Finanças, nacional ou do diretório estadual/DF) — proxy direta de "poder de
# decisão sobre a alocação de recursos do partido", via TSE/SGIP
# (R/07_titulo_eleitoral_2018_2022.R, R/08_lideranca_partido.R).
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
# conta apenas na própria UF. Ver R/08_lideranca_partido.R para o
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
# Pré-requisito: rodar R/01_overlap_partido.R, R/07_titulo_eleitoral_2018_2022.R
# e R/08_lideranca_partido.R antes (usa cand_mun_ql1.rds,
# titulo_eleitoral_candidato.rds e lideranca_candidato.rds/lideranca_raw.rds,
# todos salvos em output/).
# ==============================================================================

library(tidyverse)
library(fixest)

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 1. STATUS DE LIDERANÇA POR CANDIDATO (1 / 0 / NA)
# ==============================================================================

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

#' Normaliza uma sigla de partido para comparação
#'
#' Converte para maiúsculas, remove acentuação (transliteração ASCII) e
#' remove qualquer caractere que não seja letra ou dígito. Usado para
#' comparar siglas vindas de fontes diferentes (TSE candidatos vs. arquivos
#' de órgão partidário) que podem ter formatação inconsistente.
#'
#' @param x Character vector de siglas de partido.
#' @return Character vector normalizado (maiúsculo, sem acentos/pontuação).
normalizar_sigla <- function(x) {
  x |>
    str_to_upper() |>
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |>
    str_remove_all("[^A-Z0-9]")
}

arquivos <- unzip(file.path(out_dir, "raw_tse_orgaos", "orgao_partidario.zip"), list = TRUE)$Name
arquivos <- arquivos[str_detect(arquivos, "^orgao_partidario_.*[.]csv$")]
siglas_disponiveis_norm <- normalizar_sigla(
  sub("^orgao_partidario_", "", sub("[.]csv$", "", arquivos))
)

#' Resolve a sigla de partido para a chave usada nos arquivos de órgão partidário
#'
#' Tenta casar a sigla atual do candidato diretamente contra as siglas
#' disponíveis nos arquivos de órgão partidário do TSE; se não encontrar,
#' tenta a sigla harmonizada (via `harmonizar_partido()`, que resolve
#' fusões/renomeações históricas: PR->PL, PRB->REPUBLICANOS, PPS->CIDADANIA,
#' PTC->AGIR). Depende do objeto global `siglas_disponiveis_norm`.
#'
#' @param sigla Character vector de siglas de partido (`SG_PARTIDO`).
#' @return Character vector com a sigla normalizada resolvida, ou `NA` se
#'   nem a sigla original nem a harmonizada têm arquivo de órgão partidário
#'   correspondente (ver checagem de sanidade PMB/PMN no cabeçalho).
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

# Issue 6: reafirma em tempo de execução a checagem de sanidade descrita no
# cabeçalho (PMB/PMN são os únicos partidos sem nenhum registro de órgão
# partidário no TSE). Se um novo partido cair nesse caso — por exemplo após
# um re-download do snapshot do TSE — a decisão de excluí-lo (lider_partido
# = NA) deixa de ser uma decisão verificada e precisa ser revisitada.
partidos_sem_registro_orgao <- titulo_cand |>
  filter(is.na(sigla_busca)) |>
  distinct(SG_PARTIDO) |>
  pull(SG_PARTIDO) |>
  sort()

if (!identical(partidos_sem_registro_orgao, c("PMB", "PMN"))) {
  warning(
    "Partidos sem registro de orgao partidario no TSE mudaram de c('PMB', 'PMN') para: ",
    paste(partidos_sem_registro_orgao, collapse = ", "),
    ". A decisao de exclusao (lider_partido = NA) descrita no cabecalho do ",
    "script pode nao ser mais valida — revisar."
  )
}

lideres_matched <- readRDS(file.path(out_dir, "lideranca_candidato.rds")) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO) |>
  mutate(lider_match = 1L)

# titulo_confiavel == FALSE (calculado em 07_titulo_eleitoral_2018_2022.R):
# título é o placeholder "-4" OU é compartilhado por mais de um sq_candidato
# no mesmo ano -- em ambos os casos o título não é uma chave confiável para
# buscar liderança, e o candidato é tratado como "sem dado" (NA), nunca como
# "não-líder" (0), pelo mesmo racional do tratamento de PMB/PMN acima. Ver
# quality_reports/08_lideranca_partido_r_review.md (Issue 2) para a
# investigação que motivou esta exclusão (2026-08-22).
n_titulo_nao_confiavel <- titulo_cand |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, titulo_confiavel) |>
  filter(!titulo_confiavel) |>
  nrow()
message("Candidatos excluídos por título eleitoral não confiável (sem dado): ", n_titulo_nao_confiavel)

status_lideranca <- titulo_cand |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, sigla_busca, titulo_confiavel) |>
  left_join(lideres_matched, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(lider_partido = case_when(
    is.na(sigla_busca) ~ NA_integer_,
    !titulo_confiavel ~ NA_integer_,
    !is.na(lider_match) ~ 1L,
    TRUE ~ 0L
  )) |>
  select(sq_candidato, cargo, ANO_ELEICAO, lider_partido)

status_lideranca_dist <- status_lideranca |> count(lider_partido)
saveRDS(status_lideranca_dist, file.path(out_dir, "status_lideranca_distribuicao.rds"))
message("Status de lideranca: distribuicao salva em status_lideranca_distribuicao.rds")

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

message(
  "Candidatos com status de lideranca identificado (>=1 mun QL>1): ", nrow(taxa_lideranca),
  " | nao lideres (amostra principal do Modelo 3): ", sum(taxa_lideranca$lider_partido == 0)
)

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

suporte_m3_genero <- df_m3_genero |>
  summarise(n = n(), .by = c(cargo, ANO_ELEICAO, mulher)) |>
  arrange(cargo, ANO_ELEICAO, mulher)
saveRDS(suporte_m3_genero, file.path(out_dir, "suporte_celula_modelo3_genero.rds"))

modelo3_genero <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m3_genero, cluster = ~ partido_harm + SG_UF
)
message("Modelo 3 (Genero, nao lideres): N efetivo (feols) = ", nobs(modelo3_genero))

# ---- Raça ----
df_m3_raca <- nao_lideres |> filter(raca2 %in% c("BRANCA", "NEGRA"))

suporte_m3_raca <- df_m3_raca |>
  summarise(n = n(), .by = c(cargo, ANO_ELEICAO, negra)) |>
  arrange(cargo, ANO_ELEICAO, negra)
saveRDS(suporte_m3_raca, file.path(out_dir, "suporte_celula_modelo3_raca.rds"))

modelo3_raca <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m3_raca, cluster = ~ partido_harm + SG_UF
)
message("Modelo 3 (Raca, nao lideres): N efetivo (feols) = ", nobs(modelo3_raca))

# ---- Robustez: amostra completa (líderes + não líderes) ----
df_m3_genero_full <- base_modelo3 |> filter(genero %in% c("FEMININO", "MASCULINO"))
modelo3_genero_full <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_m3_genero_full, cluster = ~ partido_harm + SG_UF
)
message(
  "Modelo 3 (Genero, amostra completa/robustez): N efetivo (feols) = ", nobs(modelo3_genero_full)
)

df_m3_raca_full <- base_modelo3 |> filter(raca2 %in% c("BRANCA", "NEGRA"))
modelo3_raca_full <- feols(
  taxa_sobreposicao_lideranca ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_m3_raca_full, cluster = ~ partido_harm + SG_UF
)
message("Modelo 3 (Raca, amostra completa/robustez): N efetivo (feols) = ", nobs(modelo3_raca_full))

# ==============================================================================
# 5. COMPARAÇÃO RÁPIDA COM MODELO 1 E MODELO 2 (console apenas — sem tabela
#    formatada ainda, decisão de como/se isso entra no capítulo fica para
#    depois de revisar os números)
# ==============================================================================

modelo1_genero <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
modelo1_raca   <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
modelo2_genero <- readRDS(file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
modelo2_raca   <- readRDS(file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))

#' Extrai a estimativa, erro-padrão e p-valor da tripla interação de um modelo feols
#'
#' @param m Objeto `fixest` (retorno de `feols()`).
#' @param termo_regex Regex para localizar o termo da tripla interação na
#'   tabela de coeficientes (default cobre `federal:ano2022:mulher` e
#'   `federal:ano2022:negra`; parametrizado para reuso com outros termos).
#' @return Uma tibble de 1 linha com colunas `estimate`, `std_error`, `p_value`.
extrair_triplo <- function(m, termo_regex = "federal:ano2022:(mulher|negra)$") {
  ct <- coeftable(m)
  linha <- grep(termo_regex, rownames(ct), value = TRUE)
  tibble(
    estimate  = ct[linha, "Estimate"],
    std_error = ct[linha, "Std. Error"],
    p_value   = ct[linha, "Pr(>|t|)"]
  )
}

# Formata uma linha de extrair_triplo() como "estimate | std_error | p_value",
# arredondado a 4 casas — mesma apresentação usada antes da migração para
# tibble nomeada (Issue 10 da revisão de código).
fmt_triplo <- function(t) paste(round(c(t$estimate, t$std_error, t$p_value), 4), collapse = " | ")

t1_genero <- extrair_triplo(modelo1_genero)
t2_genero <- extrair_triplo(modelo2_genero)
t3_genero <- extrair_triplo(modelo3_genero)
t1_raca   <- extrair_triplo(modelo1_raca)
t2_raca   <- extrair_triplo(modelo2_raca)
t3_raca   <- extrair_triplo(modelo3_raca)

message(
  "Comparacao Modelo 1 vs. Modelo 2 vs. Modelo 3 (coeficiente da tripla interacao):\n",
  "Genero:\n",
  "  Modelo 1 (qualquer correligionario):      ", fmt_triplo(t1_genero), "\n",
  "  Modelo 2 (correligionario incumbente):    ", fmt_triplo(t2_genero), "\n",
  "  Modelo 3 (correligionario lider partido): ", fmt_triplo(t3_genero), "\n",
  "Raca:\n",
  "  Modelo 1 (qualquer correligionario):      ", fmt_triplo(t1_raca), "\n",
  "  Modelo 2 (correligionario incumbente):    ", fmt_triplo(t2_raca), "\n",
  "  Modelo 3 (correligionario lider partido): ", fmt_triplo(t3_raca)
)

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
