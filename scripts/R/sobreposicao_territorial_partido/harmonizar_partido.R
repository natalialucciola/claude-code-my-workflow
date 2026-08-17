# Harmonização de partidos entre 2018 e 2022 (fusões/renomeações).
# Copiado de Codigo de Apoio.R (projeto de análise original) — sem dependências
# de caminho absoluto. Necessário aqui porque as bases estaduais de QL do
# gasto (ql_gasto_eleit_est_*.rds) não trazem partido_harm pré-calculado,
# ao contrário das bases federais.

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

harmonizar_partido <- function(sigla) {
  harm <- dplyr::if_else(
    sigla %in% names(partido_map),
    partido_map[sigla],
    sigla
  )
  harm[sigla == "PHS"] <- NA_character_
  unname(harm)
}
