# ==============================================================================
# Bases de 2026 — Deputado Federal e Estadual: candidaturas aptas, votos,
# resultado (eleita/o, competitiva/o), gasto e receitas
#
# Mesmas regras usadas para 2018/2022 no projeto de análise da tese
# ("Código - Preparando dados - Bases 2018 e 2022.qmd"):
#   votos da candidatura = soma de QT_VOTOS_NOMINAIS das candidaturas aptas
#   QE = (votos nominais válidos + votos de legenda válidos) ÷ cadeiras da UF
#   competitiva = votos ≥ 10% do QE;  eleita = "ELEITO POR QP" ou "ELEITO POR MÉDIA"
#   gasto = despesas contratadas, sem "Doações financeiras a outros candidatos/partidos"
#   receitas: total; do partido ("Recursos de partido político"); públicas (FEFC + FP)
#
# Particularidades de 2026:
#   - APTO: DS_SITUACAO_CANDIDATURA vem "#NE"; usa a situação de julgamento do
#     arquivo de votação (deferido, pendente ou com recurso em curso = permanece
#     na urna), como em "Código - Preparando dados - Bases 2026.R".
#   - Cadeiras: contadas a partir dos eleitos de cada UF × cargo.
#   - Prestação de contas PARCIAL (arquivo do TSE de 13/10/2026: relatórios
#     financeiros de 72 h + prestação parcial; a final vence em novembro).
#     Deduplicação por SQ_DESPESA / SQ_RECEITA, priorizando final > parcial > relatório.
#
# Rodar da raiz do repositório:
#   Rscript explorations/ec111-did-2026/R/01_bases_2026.R
# Entradas (data/raw/, TSE, não versionadas): votacao_candidato_munzona_2026.zip,
#   votacao_partido_munzona_2026.zip, consulta_cand_2026.zip,
#   prestacao_de_contas_eleitorais_candidatos_2026.zip
# Saída: data/processed/cand_dep_2026.rds (uma linha por candidatura apta, sem CPF)
#        explorations/ec111-did-2026/output/conferencia_2026.csv
# ==============================================================================

library(data.table)
library(tidyverse)

raw_dir <- "data/raw"
out_dir <- "explorations/ec111-did-2026/output"
tmp_dir <- file.path(tempdir(), "bases2026")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tmp_dir, showWarnings = FALSE, recursive = TRUE)

cargos <- c("Deputado Federal", "Deputado Estadual")
ufs <- c("AC", "AL", "AM", "AP", "BA", "CE", "ES", "GO", "MA", "MG", "MS", "MT", "PA", "PB",
         "PE", "PI", "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO")   # sem DF
num <- function(x) as.numeric(sub(",", ".", x, fixed = TRUE))

#' Lê um CSV de dentro de um zip do TSE (Latin-1, ";"), só com as colunas pedidas
ler_zip <- function(zip, arquivo, cols) {
  unzip(file.path(raw_dir, zip), files = arquivo, exdir = tmp_dir, overwrite = TRUE)
  x <- fread(file.path(tmp_dir, arquivo), sep = ";", encoding = "Latin-1",
             colClasses = "character", select = cols)
  file.remove(file.path(tmp_dir, arquivo))
  x
}

# ------------------------------------------------------------------------------
# 1. Votos por candidatura (UF a UF; o arquivo BRASIL tem 3 GB)
# ------------------------------------------------------------------------------
aptos_julg <- "^DEFERIDO|PRAZO RECURSAL OU COM RECURSO|^PENDENTE"
votos_cand <- map(ufs, function(u) {
  ler_zip("votacao_candidato_munzona_2026.zip", paste0("votacao_candidato_munzona_2026_", u, ".csv"),
          c("SG_UF", "DS_CARGO", "SQ_CANDIDATO", "SG_PARTIDO", "DS_SITUACAO_JULGAMENTO",
            "QT_VOTOS_NOMINAIS", "DS_SIT_TOT_TURNO"))[DS_CARGO %in% cargos][
    , .(VOTOS_CAND_TOTAL = sum(num(QT_VOTOS_NOMINAIS))),
    by = .(SG_UF, DS_CARGO, SQ_CANDIDATO, SG_PARTIDO, DS_SITUACAO_JULGAMENTO, DS_SIT_TOT_TURNO)]
}) |> rbindlist()
stopifnot(!anyDuplicated(votos_cand[, .(DS_CARGO, SQ_CANDIDATO)]))

# Votos válidos (nominais + legenda) por UF × cargo → QE
votos_uf <- map(ufs, function(u) {
  ler_zip("votacao_partido_munzona_2026.zip", paste0("votacao_partido_munzona_2026_", u, ".csv"),
          c("SG_UF", "DS_CARGO", "QT_VOTOS_NOMINAIS_VALIDOS", "QT_TOTAL_VOTOS_LEG_VALIDOS"))[
    DS_CARGO %in% cargos][
    , .(VOTOS_UF = sum(num(QT_VOTOS_NOMINAIS_VALIDOS)) + sum(num(QT_TOTAL_VOTOS_LEG_VALIDOS))),
    by = .(SG_UF, DS_CARGO)]
}) |> rbindlist()

eleito_re <- "^ELEITO POR (QP|MÉDIA)$"
cadeiras <- votos_cand[, .(cadeiras = sum(grepl(eleito_re, DS_SIT_TOT_TURNO))), by = .(SG_UF, DS_CARGO)]

# ------------------------------------------------------------------------------
# 2. Perfil (gênero e cor/raça autodeclarados) — consulta_cand de 13/10/2026
# ------------------------------------------------------------------------------
perfil <- ler_zip("consulta_cand_2026.zip", "consulta_cand_2026_BRASIL.csv",
                  c("SQ_CANDIDATO", "DS_CARGO", "DS_GENERO", "DS_COR_RACA"))[
  DS_CARGO %in% toupper(cargos), .(SQ_CANDIDATO, genero = DS_GENERO, raca = DS_COR_RACA)]

cand <- as_tibble(votos_cand) |>
  filter(str_detect(DS_SITUACAO_JULGAMENTO, aptos_julg)) |>
  left_join(as_tibble(perfil), by = "SQ_CANDIDATO") |>
  left_join(as_tibble(votos_uf), by = c("SG_UF", "DS_CARGO")) |>
  left_join(as_tibble(cadeiras), by = c("SG_UF", "DS_CARGO")) |>
  mutate(QE = VOTOS_UF / cadeiras,
         competitivo = as.integer(VOTOS_CAND_TOTAL >= 0.1 * QE),
         eleito = as.integer(str_detect(DS_SIT_TOT_TURNO, eleito_re))) |>
  transmute(ANO = "2026", DS_CARGO, sq_candidato = SQ_CANDIDATO, uf = SG_UF, partido = SG_PARTIDO,
            genero, raca, VOTOS_CAND_TOTAL, QE, competitivo, eleito)
stopifnot(!anyNA(cand$genero), !anyNA(cand$QE))

# ------------------------------------------------------------------------------
# 3. Gasto e receitas (prestação parcial)
# ------------------------------------------------------------------------------
zip_pc <- "prestacao_de_contas_eleitorais_candidatos_2026.zip"
prioridade <- \(tp) -(toupper(tp) == "FINAL") * 2 - (toupper(tp) == "PARCIAL")

desp <- ler_zip(zip_pc, "despesas_contratadas_candidatos_2026_BRASIL.csv",
                c("TP_PRESTACAO_CONTAS", "DS_CARGO", "SQ_CANDIDATO", "DS_ORIGEM_DESPESA",
                  "SQ_DESPESA", "VR_DESPESA_CONTRATADA"))[DS_CARGO %in% cargos]
desp <- desp[order(prioridade(TP_PRESTACAO_CONTAS))][!duplicated(SQ_DESPESA)][
  , v := num(VR_DESPESA_CONTRATADA)][
  , .(gasto_bruto = sum(v, na.rm = TRUE),
      repasse = sum(v[DS_ORIGEM_DESPESA == "Doações financeiras a outros candidatos/partidos"],
                    na.rm = TRUE)),
  by = .(DS_CARGO, SQ_CANDIDATO)][, gasto := gasto_bruto - repasse]

rec <- ler_zip(zip_pc, "receitas_candidatos_2026_BRASIL.csv",
               c("TP_PRESTACAO_CONTAS", "DS_CARGO", "SQ_CANDIDATO", "DS_ORIGEM_RECEITA",
                 "DS_FONTE_RECEITA", "SQ_RECEITA", "VR_RECEITA"))[DS_CARGO %in% cargos]
rec <- rec[order(prioridade(TP_PRESTACAO_CONTAS))][!duplicated(SQ_RECEITA)][, v := num(VR_RECEITA)]
eh_partido <- \(o) grepl("partido pol", tolower(o), fixed = TRUE)
rec <- rec[, .(receita_total   = sum(v, na.rm = TRUE),
               receita_partido = sum(v[eh_partido(DS_ORIGEM_RECEITA)], na.rm = TRUE),
               receita_publica = sum(v[grepl("(?i)especial|partid", DS_FONTE_RECEITA, perl = TRUE)],
                                     na.rm = TRUE)),
           by = .(DS_CARGO, SQ_CANDIDATO)]

cand <- cand |>
  left_join(as_tibble(desp), by = c("DS_CARGO", "sq_candidato" = "SQ_CANDIDATO")) |>
  left_join(as_tibble(rec), by = c("DS_CARGO", "sq_candidato" = "SQ_CANDIDATO")) |>
  mutate(across(c(gasto_bruto, repasse, gasto, receita_total, receita_partido, receita_publica),
                \(x) replace_na(x, 0)))
stopifnot(!anyDuplicated(cand[c("DS_CARGO", "sq_candidato")]))
saveRDS(cand, "data/processed/cand_dep_2026.rds")

# ------------------------------------------------------------------------------
# 4. Conferência
# ------------------------------------------------------------------------------
conf <- cand |>
  summarise(candidaturas_aptas = n(), eleitos = sum(eleito), competitivas = sum(competitivo),
            pct_mulheres = 100 * mean(genero == "FEMININO"),
            pct_negras = 100 * mean(raca %in% c("PRETA", "PARDA")),
            pct_eleitas_mulheres = 100 * mean(genero[eleito == 1] == "FEMININO"),
            votos_nominais_mi = sum(VOTOS_CAND_TOTAL) / 1e6,
            pct_com_despesa = 100 * mean(gasto_bruto > 0),
            pct_com_receita = 100 * mean(receita_total > 0),
            gasto_mi = sum(gasto) / 1e6, receita_partido_mi = sum(receita_partido) / 1e6,
            .by = DS_CARGO)
write_excel_csv2(conf, file.path(out_dir, "conferencia_2026.csv"))
print(as.data.frame(conf))
