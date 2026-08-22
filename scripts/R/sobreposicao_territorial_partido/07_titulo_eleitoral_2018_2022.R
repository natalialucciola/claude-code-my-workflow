# ==============================================================================
# Completar a chave de vínculo com a base de liderança partidária do TSE
# (R/08_lideranca_partido.R): título eleitoral do candidato.
#
# NR_TITULO_ELEITORAL_CANDIDATO existe no download bruto de
# electionsBR::elections_tse(type = "candidate") (confirmado: 50 colunas),
# mas os scripts que já geraram data/raw/candidatos{2018,2022}*.rds
# descartaram essa coluna no select(). Em vez de re-baixar e reprocessar
# esses arquivos (risco de divergência com o que já está em uso no resto do
# pipeline), este script baixa de novo, só para extrair
# SQ_CANDIDATO + NR_TITULO_ELEITORAL_CANDIDATO, e salva como um arquivo
# separado para juntar por sq_candidato + cargo + ANO_ELEICAO.
#
# Pré-requisito:
#   - Parte 1 (download): nenhum -- pode rodar isoladamente.
#   - Parte 2 (checagem de cobertura): requer que 01_overlap_partido.R já
#     tenha rodado e gerado taxa_sobreposicao_candidato.rds em out_dir.
# ==============================================================================

library(dplyr)
library(stringr)
library(tibble)
library(purrr)
library(electionsBR)

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

#' Baixa candidaturas de um ano/cargo do TSE e extrai a chave de título eleitoral
#'
#' Baixa (ou lê do cache local em `out_dir`) o arquivo bruto de candidaturas do
#' TSE via \code{electionsBR::elections_tse()}, filtra pelo cargo desejado e
#' extrai a chave de vínculo (sq_candidato + titulo_eleitoral) usada para
#' juntar com a base de liderança partidária (\code{08_lideranca_partido.R}).
#' O download bruto é cacheado por ano em disco, já que Federal e Estadual do
#' mesmo ano vêm do mesmo arquivo nacional -- evita baixar duas vezes.
#'
#' @param ano Ano da eleição (integer), 2018L ou 2022L.
#' @param cargo_desejado Valor de DS_CARGO no arquivo bruto do TSE (ex.:
#'   "DEPUTADO FEDERAL").
#' @param cargo_label Rótulo padronizado do cargo usado no pipeline (ex.:
#'   "Federal").
#' @return Um tibble com colunas sq_candidato, titulo_eleitoral, SG_UF,
#'   SG_PARTIDO, cargo, ANO_ELEICAO -- um registro por candidato do
#'   cargo/ano solicitados.
baixar_titulo <- function(ano, cargo_desejado, cargo_label) {
  cache_file <- file.path(out_dir, paste0("raw_candidatos_", ano, ".rds"))

  if (file.exists(cache_file)) {
    raw <- readRDS(cache_file)
  } else {
    message("Baixando candidaturas ", ano, " (electionsBR, br_archive = TRUE)...")
    raw <- tryCatch(
      elections_tse(year = ano, type = "candidate", br_archive = TRUE),
      error = function(e) {
        stop("Falha ao baixar candidaturas de ", ano, " via elections_tse(): ",
             conditionMessage(e), call. = FALSE)
      }
    )
    saveRDS(raw, cache_file)
  }

  resultado <- raw |>
    filter(str_to_upper(DS_CARGO) == cargo_desejado) |>
    transmute(
      sq_candidato = as.character(SQ_CANDIDATO),
      titulo_eleitoral = as.character(NR_TITULO_ELEITORAL_CANDIDATO),
      SG_UF, SG_PARTIDO,
      cargo = cargo_label,
      ANO_ELEICAO = as.character(ano)
    )

  if (nrow(resultado) == 0L) {
    stop("baixar_titulo(): 0 linhas para ano = ", ano, ", cargo_desejado = '",
         cargo_desejado, "'. Verifique se DS_CARGO mudou de valor no TSE.",
         call. = FALSE)
  }

  titulo_presente <- resultado$titulo_eleitoral
  titulo_presente <- titulo_presente[!is.na(titulo_presente) & titulo_presente != ""]
  formato_invalido <- !grepl("^[0-9]{8,12}$", titulo_presente)
  if (any(formato_invalido)) {
    stop("baixar_titulo(): ", sum(formato_invalido),
         " título(s) eleitoral(is) fora do formato esperado (^[0-9]{8,12}$) para ",
         "ano = ", ano, ", cargo = '", cargo_label, "'.", call. = FALSE)
  }

  resultado
}

# ==============================================================================
# 1. DOWNLOAD DAS CANDIDATURAS E EXTRAÇÃO DO TÍTULO ELEITORAL
# ==============================================================================

combinacoes <- tribble(
  ~ano,  ~cargo_desejado,     ~cargo_label,
  2018L, "DEPUTADO FEDERAL",  "Federal",
  2022L, "DEPUTADO FEDERAL",  "Federal",
  2018L, "DEPUTADO ESTADUAL", "Estadual",
  2022L, "DEPUTADO ESTADUAL", "Estadual"
)

titulo_eleitoral_candidato <- pmap(combinacoes, baixar_titulo) |>
  bind_rows()

n_dup <- sum(duplicated(
  select(titulo_eleitoral_candidato, sq_candidato, cargo, ANO_ELEICAO)
))
if (n_dup > 0L) {
  stop("Chave de vínculo (sq_candidato + cargo + ANO_ELEICAO) tem ", n_dup,
       " duplicata(s). Corrija antes de salvar -- 08_lideranca_partido.R e ",
       "09_modelo3_lideranca.R assumem chave única.", call. = FALSE)
}

n_ausente <- sum(is.na(titulo_eleitoral_candidato$titulo_eleitoral) |
                    titulo_eleitoral_candidato$titulo_eleitoral == "")

# ---- Confiabilidade do título como chave de vínculo -------------------------
# Título eleitoral é um identificador pessoal e não deveria se repetir entre
# sq_candidato distintos. Na prática, dois problemas de qualidade de dado do
# TSE/electionsBR foram encontrados por investigação manual (2026-08-22,
# ver quality_reports/08_lideranca_partido_r_review.md, Issue 2):
#   (a) "-4" é usado como valor sentinela para título ausente/não informado
#       (72 candidatos na base atual) -- não é um valor NA nem "", mas
#       também não é um título real.
#   (b) Em 278 casos (9 pares, na base atual), o MESMO título eleitoral
#       aparece em DOIS sq_candidato diferentes no mesmo ano -- confirmado
#       por busca pública que, nesses pares, o título pertence de fato a uma
#       liderança partidária real que também foi candidata; o segundo
#       sq_candidato herda o título por erro de vinculação na base bruta do
#       TSE, não por coincidência (título tem ~12 dígitos).
# Ambos os casos tornam o título uma chave não confiável para buscar
# liderança em 09_modelo3_lideranca.R -- marcado aqui como
# titulo_confiavel = FALSE, tratado como "sem dado" (NA), nunca como
# "não-líder" (0), no mesmo espírito do tratamento de PMB/PMN.
titulos_duplicados <- titulo_eleitoral_candidato |>
  filter(titulo_eleitoral != "-4") |>
  count(ANO_ELEICAO, titulo_eleitoral) |>
  filter(n > 1L) |>
  mutate(titulo_e_duplicado = TRUE) |>
  select(ANO_ELEICAO, titulo_eleitoral, titulo_e_duplicado)

titulo_eleitoral_candidato <- titulo_eleitoral_candidato |>
  left_join(titulos_duplicados, by = c("ANO_ELEICAO", "titulo_eleitoral")) |>
  mutate(
    titulo_confiavel = titulo_eleitoral != "-4" & is.na(titulo_e_duplicado)
  ) |>
  select(-titulo_e_duplicado)

n_nao_confiavel <- sum(!titulo_eleitoral_candidato$titulo_confiavel)

message("Download concluído: ", nrow(titulo_eleitoral_candidato),
        " candidatos, ", n_ausente, " sem título eleitoral, 0 duplicatas, ",
        n_nao_confiavel, " com título não confiável (placeholder '-4' ou ",
        "duplicado entre candidatos distintos).")

saveRDS(titulo_eleitoral_candidato, file.path(out_dir, "titulo_eleitoral_candidato.rds"))

# ==============================================================================
# 2. CHECAGEM DE COBERTURA CONTRA A AMOSTRA DO CAPÍTULO
# ==============================================================================

taxa_sobreposicao <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds"))

cobertura <- taxa_sobreposicao |>
  filter(ANO_ELEICAO %in% c("2018", "2022")) |>
  left_join(
    select(titulo_eleitoral_candidato, sq_candidato, cargo, ANO_ELEICAO, titulo_eleitoral),
    by = c("sq_candidato", "cargo", "ANO_ELEICAO")
  )

n_total <- nrow(cobertura)
n_com_titulo <- sum(!is.na(cobertura$titulo_eleitoral) & cobertura$titulo_eleitoral != "")

cobertura_por_cargo_ano <- cobertura |>
  summarise(
    n = n(),
    com_titulo = sum(!is.na(titulo_eleitoral) & titulo_eleitoral != ""),
    pct = round(100 * com_titulo / n, 1),
    .by = c(cargo, ANO_ELEICAO)
  )

saveRDS(cobertura_por_cargo_ano, file.path(out_dir, "cobertura_titulo_eleitoral_cargo_ano.rds"))

message("Cobertura na amostra do capítulo (2018+2022): ", n_com_titulo, "/", n_total,
        " (", round(100 * n_com_titulo / n_total, 1), "%) -- detalhe por cargo x ano em ",
        "cobertura_titulo_eleitoral_cargo_ano.rds")

message("Concluído: titulo_eleitoral_candidato.rds salvo em ", out_dir)
