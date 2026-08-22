# ==============================================================================
# Harmonização de partidos entre 2018 e 2022 (fusões/renomeações)
#
# Purpose: Recodifica siglas partidárias pré-fusão/renomeação (ciclo 2018)
#   para a sigla vigente em 2022, permitindo empilhar bases eleitorais dos
#   dois ciclos sob uma identidade de partido consistente.
# Inputs: nenhum arquivo — expõe `partido_map` (lookup table) e a função
#   `harmonizar_partido()` para uso por outros scripts via source().
# Outputs: nenhum arquivo — efeito é in-memory (a função retorna um vetor;
#   `partido_map` fica disponível no ambiente do chamador via source()).
#
# Copiado de Codigo de Apoio.R (projeto de análise original) — sem dependências
# de caminho absoluto. Necessário aqui porque as bases estaduais de QL do
# gasto (ql_gasto_eleit_est_*.rds) não trazem partido_harm pré-calculado,
# ao contrário das bases federais.
# ==============================================================================

# WHY: cada linha abaixo corresponde a uma fusão/incorporação/renomeação de
# legenda entre os ciclos eleitorais de 2018 e 2022, per histórico de
# resoluções do TSE (needs citation — resolução e data específicas de cada
# mudança não foram verificadas nesta revisão; confirmar antes de citar em
# texto submetido):
#   DEM + PSL   -> UNIÃO        (fusão, 2021/2022)
#   PPS         -> CIDADANIA    (renomeação)
#   PR          -> PL           (renomeação)
#   PRB         -> REPUBLICANOS (renomeação)
#   PSDC        -> DC           (renomeação)
#   PTC         -> AGIR         (renomeação)
#   PTdoB       -> AVANTE       (renomeação)
#   PTN         -> PODE         (renomeação)
partido_map <- c(
  "DEM"    = "UNIÃO",
  "PSL"    = "UNIÃO",
  "PPS"    = "CIDADANIA",
  "PR"     = "PL",
  "PRB"    = "REPUBLICANOS",
  "PSDC"   = "DC",
  "PTC"    = "AGIR",
  "PTdoB"  = "AVANTE",
  "PTN"    = "PODE"
)

#' Harmoniza sigla partidária entre os ciclos de 2018 e 2022
#'
#' Recodifica siglas de partidos extintos/renomeados (`partido_map`) para a
#' sigla vigente em 2022. PHS é tratado como caso especial e mapeado para
#' `NA` (ver Issue 4/7 em `quality_reports/harmonizar_partido_r_review.md`
#' — disposição do PHS ainda não verificada contra fonte primária). Siglas
#' não presentes em `partido_map` e diferentes de "PHS" passam inalteradas.
#'
#' @param sigla Character vector de siglas partidárias brutas (como
#'   registradas pelo TSE), possivelmente do ciclo 2018.
#' @return Character vector do mesmo comprimento de `sigla`, com siglas
#'   pré-fusão recodificadas para a sigla vigente em 2022, `NA_character_`
#'   para "PHS", e demais valores retornados sem alteração.
harmonizar_partido <- function(sigla) {
  harm <- dplyr::if_else(
    sigla %in% names(partido_map),
    partido_map[sigla],
    sigla
  )
  harm[sigla == "PHS"] <- NA_character_
  unname(harm)
}
