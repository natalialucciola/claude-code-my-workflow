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

#' Lê despesas contratadas ou receitas da prestação de contas do TSE (deputados) e
#' remove apenas as linhas idênticas em TODAS as colunas.
#'
#' Regra decidida pela autora em 2026-11-09. O SQ_DESPESA / SQ_RECEITA identifica o
#' documento (nota, contrato, recibo), não o item: um mesmo código reúne itens
#' distintos (ex.: santinhos, adesivos e banners da mesma nota; duas quinzenas de
#' pessoal), que diferem em valor e descrição. Manter "uma linha por código", como
#' na base anterior, descartava ~19-20% do gasto (2018: 1.792 contra 2.148 R$ mi;
#' 2022: 3.999 contra 4.748; 2026: 4.287 contra 5.110) e ~0,4% da receita. Nenhuma
#' candidatura tem mais de um tipo de prestação (final/parcial) no arquivo do TSE,
#' então não há risco de somar prestações sucessivas.
#' @param zip caminho do zip da prestação de contas do ano
#' @param arquivo nome do CSV dentro do zip (ex.: "despesas_contratadas_candidatos_2022_BRASIL.csv")
#' @param cargos valores de DS_CARGO a manter
#' @return data.table com todas as colunas (texto); atributo "copias_exatas" = linhas removidas
ler_prestacao <- function(zip, arquivo, cargos = c("Deputado Federal", "Deputado Estadual")) {
  td <- tempfile("prestacao_"); dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)
  utils::unzip(zip, files = arquivo, exdir = td, overwrite = TRUE)
  x <- data.table::fread(file.path(td, arquivo), sep = ";", encoding = "Latin-1",
                         colClasses = "character")
  x <- x[x$DS_CARGO %in% cargos]
  n0 <- nrow(x)
  x <- unique(x)
  attr(x, "copias_exatas") <- n0 - nrow(x)
  x
}
