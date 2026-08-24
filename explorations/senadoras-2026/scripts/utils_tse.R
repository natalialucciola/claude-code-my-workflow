# =============================================================================
# utils_tse.R
# Funcoes compartilhadas para ler dados do TSE baixados manualmente pelo
# navegador (necessario porque o download automatico via electionsBR/httr
# e bloqueado pelo WAF do TSE — ver SESSION_LOG.md, entrada 2026-08-19).
#
# Fluxo: baixar manualmente o zip do dataset em dadosabertos.tse.jus.br,
# salvar em dados/brutos/ com o nome original (ex.: consulta_cand_2022.zip
# ou consulta_cand_2022_BRASIL.zip — o padrao de nome varia por ano; a
# funcao abaixo aceita qualquer coisa que comece com o prefixo esperado),
# e chamar carregar_zip_candidatos_tse(ano).
# =============================================================================

library(dplyr)
library(readr)
library(purrr)
library(stringr)

#' Le um zip de consulta_cand do TSE ja baixado manualmente em dados/brutos/
#'
#' @param ano ano da eleicao (ex.: 2022)
#' @param dir_brutos pasta onde o zip foi salvo manualmente
#' @return tibble com todas as UFs empilhadas, ou NULL se o zip nao existir
#'   (nesse caso imprime instrucoes de onde baixar)
carregar_zip_candidatos_tse <- function(ano, dir_brutos = "dados/brutos") {
  candidatos_zip <- list.files(
    dir_brutos,
    pattern = paste0("^consulta_cand_", ano, ".*\\.zip$"),
    full.names = TRUE, ignore.case = TRUE
  )

  if (length(candidatos_zip) == 0) {
    message(
      "Zip de candidatos ", ano, " nao encontrado em ", dir_brutos, ".\n",
      "  1. Abra https://dadosabertos.tse.jus.br/dataset/candidatos-", ano, "\n",
      "  2. Baixe o recurso de candidatos para BRASIL (nao por UF individual)\n",
      "  3. Salve o arquivo .zip em ", dir_brutos, "/ sem renomear\n"
    )
    return(NULL)
  }
  if (length(candidatos_zip) > 1) {
    warning("Mais de um zip encontrado para ", ano, ", usando o primeiro: ",
            candidatos_zip[1])
  }
  zip_path <- candidatos_zip[1]

  dir_extract <- file.path(tempdir(), paste0("consulta_cand_", ano))
  if (dir.exists(dir_extract)) unlink(dir_extract, recursive = TRUE)
  dir.create(dir_extract, recursive = TRUE)

  utils::unzip(zip_path, exdir = dir_extract)

  csvs <- list.files(dir_extract, pattern = "\\.csv$", full.names = TRUE,
                      ignore.case = TRUE)
  csvs <- csvs[!str_detect(tolower(basename(csvs)), "leiame|readme")]

  if (length(csvs) == 0) {
    stop("Zip de ", ano, " extraiu sem erro mas nao contem nenhum .csv em ",
         dir_extract, " — inspecionar manualmente o conteudo do zip.")
  }

  message("Lendo ", length(csvs), " arquivo(s) CSV de ", ano, "...")

  leituras <- purrr::map(csvs, function(caminho) {
    tryCatch(
      readr::read_delim(
        caminho, delim = ";",
        locale = readr::locale(encoding = "Latin1"),
        show_col_types = FALSE, progress = FALSE
      ),
      error = function(e) {
        warning("Falha ao ler ", basename(caminho), ": ", conditionMessage(e))
        NULL
      }
    )
  })

  n_falhas <- sum(vapply(leituras, is.null, logical(1)))
  if (n_falhas > 0) {
    warning(n_falhas, " de ", length(csvs), " arquivo(s) de ", ano,
            " falharam na leitura — ver mensagens acima.")
  }

  leituras <- purrr::compact(leituras)
  n_colunas <- unique(vapply(leituras, ncol, integer(1)))
  if (length(n_colunas) > 1) {
    warning("Arquivos de ", ano, " tem numero de colunas diferente entre UFs (",
            paste(n_colunas, collapse = ", "),
            ") — checar se o layout mudou dentro do mesmo ano antes de confiar no resultado.")
  }

  banco <- dplyr::bind_rows(leituras)
  unlink(dir_extract, recursive = TRUE)

  message("OK: ", ano, " — ", nrow(banco), " linhas, ", ncol(banco), " colunas.")
  banco
}
