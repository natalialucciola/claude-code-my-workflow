# ==============================================================================
# Script: 00_dados.R
# Purpose: Baixa os insumos que faltam para o DiD da EC 111 com QL por município:
#          (a) TSE 2010 — votação por candidato × município, votação por partido,
#              candidaturas e vagas (só para saber onde cada partido tinha base em
#              2010 e quem foi eleito em 2010, para a transição 2010 → 2014);
#          (b) TSE 2014 — candidaturas e vagas, se ainda não estiverem em disco;
#          (c) IBGE — composição municipal das Regiões Geográficas Imediatas
#              (RGI, divisão de 2017), unidade usada por Calzavara (robustez).
# Inputs:  nenhum (downloads)
# Outputs: data/raw/tse/{votacao_candidato_munzona,votacao_partido_munzona,
#            consulta_cand,consulta_vagas}_2010.zip
#          data/raw/ibge_municipio_rgi.csv
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ec111-did-ql-municipio/R/00_dados.R
# ==============================================================================

library(tidyverse)
library(jsonlite)

tse_dir <- file.path("data", "raw", "tse")
dir.create(tse_dir, showWarnings = FALSE, recursive = TRUE)
options(timeout = 3600)

url_tse <- "https://cdn.tse.jus.br/estatistica/sead/odsele"

#' Baixa um zip do repositório de dados abertos do TSE, se ainda não existe
#'
#' @param base Nome do conjunto (ex.: "votacao_candidato_munzona").
#' @param ano Ano da eleição.
#' @return Caminho do arquivo local (invisível).
baixar_tse <- function(base, ano) {
  destino <- file.path(tse_dir, sprintf("%s_%d.zip", base, ano))
  if (!file.exists(destino)) {
    message("Baixando ", basename(destino))
    download.file(sprintf("%s/%s/%s_%d.zip", url_tse, base, base, ano), destino, mode = "wb")
  }
  invisible(destino)
}

walk(c("votacao_candidato_munzona", "votacao_partido_munzona", "consulta_cand",
       "consulta_vagas"), baixar_tse, ano = 2010L)
walk(c("consulta_cand", "consulta_vagas"), baixar_tse, ano = 2014L)

# ---- IBGE: município → Região Geográfica Imediata ----
arq_rgi <- file.path("data", "raw", "ibge_municipio_rgi.csv")
if (!file.exists(arq_rgi)) {
  mun <- fromJSON("https://servicodados.ibge.gov.br/api/v1/localidades/municipios",
                  flatten = TRUE)
  rgi <- tibble(
    COD_MUN_IBGE = as.character(mun$id),
    nome_municipio = mun$nome,
    cod_rgi = as.character(mun$`regiao-imediata.id`),
    nome_rgi = mun$`regiao-imediata.nome`,
    SG_UF = mun$`regiao-imediata.regiao-intermediaria.UF.sigla`
  )
  stopifnot(!anyNA(rgi$cod_rgi))
  write_csv(rgi, arq_rgi)
}
rgi <- read_csv(arq_rgi, col_types = cols(.default = "c"))
message("Municípios: ", nrow(rgi), " | RGIs: ", n_distinct(rgi$cod_rgi))
