# =============================================================================
# 01_download_candidatos.R
# Objetivo: carregar os dados de candidatos (consulta_cand) para todos os
#           anos/cargos definidos no escopo do plano (docs/plano-pesquisa.md,
#           Secao 3).
#
# ATENCAO — mudanca de metodo (ver SESSION_LOG.md, 2026-08-19): o download
# automatico via electionsBR (candidate_fed()/elections_tse()) e bloqueado
# pelo WAF do TSE (Akamai) — a requisicao via httr/curl recebe HTTP 403 e o
# pacote salva a pagina de erro como se fosse um .zip, o que quebra na hora
# de descompactar. O download manual pelo navegador funciona normalmente.
# Por isso este script NAO baixa nada sozinho: ele le zips que voce baixou
# manualmente e colocou em dados/brutos/ (ver instrucoes impressas no console
# quando um zip estiver faltando).
#
# Inputs:  dados/brutos/consulta_cand_<ano>*.zip (baixados manualmente)
# Outputs: dados/brutos/candidatos_<ano>.rds  (um arquivo por ano, todos os
#          cargos juntos — filtragem por cargo acontece em
#          02_harmoniza_schema.R)
# =============================================================================

source("scripts/utils_tse.R")

# Escopo temporal — ver plano, Secao 3. Ajustar aqui se decidir por
# 2002-2026 em vez de 1994-2026 (registrar a decisao em docs/plano-pesquisa.md
# ou num docs/notas-execucao.md complementar).
anos <- c(1994, 1998, 2002, 2006, 2010, 2014, 2018, 2022, 2026)

dir.create("dados/brutos", showWarnings = FALSE, recursive = TRUE)

resumo <- data.frame(ano = anos, status = NA_character_, linhas = NA_integer_)

for (i in seq_along(anos)) {
  ano <- anos[i]
  destino <- file.path("dados/brutos", paste0("candidatos_", ano, ".rds"))

  if (file.exists(destino)) {
    message("Ja existe, pulando: ", destino)
    resumo$status[i] <- "ja_existia"
    resumo$linhas[i] <- nrow(readRDS(destino))
    next
  }

  banco <- carregar_zip_candidatos_tse(ano)

  if (!is.null(banco)) {
    saveRDS(banco, destino)
    message("Salvo: ", destino, " (", nrow(banco), " linhas)")
    resumo$status[i] <- "ok"
    resumo$linhas[i] <- nrow(banco)
  } else {
    resumo$status[i] <- "falta_zip_manual"
    resumo$linhas[i] <- NA_integer_
  }
}

cat("\n=== Resumo ===\n")
print(resumo)

if (any(resumo$status == "falta_zip_manual")) {
  cat("\nAnos pendentes de download manual: ",
      paste(resumo$ano[resumo$status == "falta_zip_manual"], collapse = ", "),
      "\nBaixe cada zip em https://dadosabertos.tse.jus.br/dataset/candidatos-<ano> ",
      "e salve em dados/brutos/, depois rode este script de novo — anos ja",
      " processados sao pulados automaticamente.\n")
}
