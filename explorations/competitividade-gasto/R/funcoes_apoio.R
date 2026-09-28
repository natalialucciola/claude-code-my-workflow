# ==============================================================================
# Funções de apoio — cópia das usadas no projeto de análise da tese
# ("Codigo de Apoio - 2026.R"), para a exploração rodar sem depender dele.
# ==============================================================================

# Siglas de 2018 renomeadas/fundidas até 2022
partido_map_2018_2022 <- c(
  "DEM" = "UNIÃO", "PSL" = "UNIÃO", "PPS" = "CIDADANIA", "PR" = "PL",
  "PRB" = "REPUBLICANOS", "PSDC" = "DC", "PTC" = "AGIR", "PTdoB" = "AVANTE", "PTN" = "PODE"
)

# Fusões/incorporações/renomeações até 2026
partido_map_2026 <- c(
  "PTB" = "PRD", "PATRIOTA" = "PRD", "PROS" = "SOLIDARIEDADE", "PSC" = "PODE",
  "PMN" = "MOBILIZA", "PMB" = "DEMOCRATA", "PC do B" = "PCDOB"
)

#' Harmoniza siglas de 2018/2022 para a sigla vigente em 2026 (PHS, extinto, vira NA)
harmonizar_partido_2026 <- function(sigla) {
  s <- dplyr::if_else(sigla %in% names(partido_map_2018_2022), partido_map_2018_2022[sigla], sigla)
  s <- dplyr::if_else(s %in% names(partido_map_2026), partido_map_2026[s], s)
  s[sigla == "PHS"] <- NA_character_
  unname(s)
}

#' Raça agregada: PRETA + PARDA = NEGRA; BRANCA; demais = OUTRA
raca2 <- function(raca) {
  dplyr::case_when(raca %in% c("PRETA", "PARDA") ~ "NEGRA",
                   raca == "BRANCA" ~ "BRANCA",
                   TRUE ~ "OUTRA")
}
