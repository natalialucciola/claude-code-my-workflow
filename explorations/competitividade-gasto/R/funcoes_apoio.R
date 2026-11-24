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

#' Classifica cada receita em categorias que somam a receita total (regra de 2026-11-24).
#'
#' Antes, "outras fontes" era a receita total menos a do partido, e por isso incluía os
#' repasses de outras candidaturas, dos quais 80-86% são FEFC ou Fundo Partidário:
#' dinheiro público que o partido distribui e que passa por uma candidatura. A fonte
#' (DS_FONTE_RECEITA) é preservada no repasse, o que permite separá-lo.
#'   partido            origem "Recursos de partido político", qualquer fonte
#'   repasse_cand_pub   origem "Recursos de outros candidatos", fonte FEFC ou Fundo Partidário
#'   repasse_cand_priv  origem "Recursos de outros candidatos", outras fontes
#'   privada            pessoas físicas, internet, financiamento coletivo, recursos
#'                      próprios, comercialização de bens/eventos (decisão de doadores)
#'   residual           rendimentos de aplicações, origens não identificadas, #NULO
#' @param origem DS_ORIGEM_RECEITA; @param fonte DS_FONTE_RECEITA
#' @return vetor de caracteres com a categoria de cada receita
categorizar_receita <- function(origem, fonte) {
  o <- tolower(origem); f <- tolower(fonte)
  publica <- grepl("especial|partid", f)
  dplyr::case_when(
    grepl("partido pol", o, fixed = TRUE)                     ~ "partido",
    grepl("outros candidatos", o, fixed = TRUE) & publica     ~ "repasse_cand_pub",
    grepl("outros candidatos", o, fixed = TRUE)               ~ "repasse_cand_priv",
    grepl("pessoas f|internet|financiamento coletivo|pr[oó]prios|comercializa", o) ~ "privada",
    TRUE                                                      ~ "residual"
  )
}

#' Soma as receitas por candidatura em cada categoria de categorizar_receita().
#' @param x data.table com DS_ORIGEM_RECEITA, DS_FONTE_RECEITA e v (valor numérico)
#' @param by colunas de agrupamento
#' @return data.table com receita_total, receita_partido, receita_publica (FEFC + FP de
#'   qualquer origem), repasse_cand_pub, repasse_cand_priv, receita_privada,
#'   receita_residual; as cinco categorias somam receita_total
resumir_receitas <- function(x, by) {
  x <- data.table::copy(x)
  x[, cat := categorizar_receita(DS_ORIGEM_RECEITA, DS_FONTE_RECEITA)]
  out <- x[, .(receita_total     = sum(v, na.rm = TRUE),
               receita_partido   = sum(v[cat == "partido"], na.rm = TRUE),
               receita_publica   = sum(v[grepl("(?i)especial|partid", DS_FONTE_RECEITA, perl = TRUE)],
                                       na.rm = TRUE),
               repasse_cand_pub  = sum(v[cat == "repasse_cand_pub"], na.rm = TRUE),
               repasse_cand_priv = sum(v[cat == "repasse_cand_priv"], na.rm = TRUE),
               receita_privada   = sum(v[cat == "privada"], na.rm = TRUE),
               receita_residual  = sum(v[cat == "residual"], na.rm = TRUE)),
           by = by]
  soma <- out[, receita_partido + repasse_cand_pub + repasse_cand_priv + receita_privada +
                receita_residual]
  stopifnot(all(abs(soma - out$receita_total) < 0.01))   # partição exata (R$ 0,01)
  out
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
