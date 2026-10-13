# ==============================================================================
# Script: 00_baixar_dados_tse.R
# Purpose: Baixa do Portal de Dados Abertos do TSE os arquivos brutos usados
#          pela versão "QL de votos" do Capítulo 6 (2018, 2022, 2026).
# Inputs:  nenhum (rede)
# Outputs: data/raw/tse/*.zip (gitignored, ver data/README.md)
#
# Snapshot usado na primeira execução: 2026-10-13 (arquivos de 2026 gerados
# pelo TSE em 13/10/2026, 9 dias após o 1º turno). O TSE regera os arquivos de
# 2026 enquanto houver recursos/totalização pendentes — registrar a data de
# download ao rodar de novo.
#
# Nota de acesso: em 08/2026 o CDN do TSE devolvia HTTP 403 a clientes não
# navegador (ver explorations/senadoras-2026/SESSION_LOG.md). Em 2026-10-13 o
# download direto voltou a funcionar. Se voltar a falhar, baixar cada URL
# abaixo pelo navegador e salvar em data/raw/tse/ com o mesmo nome.
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/00_baixar_dados_tse.R
# ==============================================================================

dest_dir <- file.path("data", "raw", "tse")
dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

base_url <- "https://cdn.tse.jus.br/estatistica/sead/odsele"

arquivos <- c(
  sprintf("votacao_candidato_munzona/votacao_candidato_munzona_%d.zip", c(2018, 2022, 2026)),
  sprintf("votacao_partido_munzona/votacao_partido_munzona_%d.zip",     c(2018, 2022, 2026)),
  "consulta_cand/consulta_cand_2026.zip",
  "consulta_vagas/consulta_vagas_2026.zip"
)

options(timeout = 3600)

for (a in arquivos) {
  destino <- file.path(dest_dir, basename(a))
  if (file.exists(destino)) {
    message("Já existe, pulando: ", destino)
    next
  }
  message("Baixando ", a)
  status <- tryCatch(
    download.file(file.path(base_url, a), destino, mode = "wb", quiet = TRUE),
    error = function(e) {
      message("  FALHOU: ", conditionMessage(e))
      1L
    }
  )
  # O CDN do TSE pode devolver uma página de erro com status 200 aparente;
  # um zip válido sempre lista arquivos.
  ok <- status == 0 && tryCatch(nrow(unzip(destino, list = TRUE)) > 0,
                                error = function(e) FALSE)
  if (!ok) {
    unlink(destino)
    warning("Download inválido para ", a, " — baixar manualmente: ",
            file.path(base_url, a))
  }
}

message("Arquivos em ", dest_dir, ":")
print(file.info(list.files(dest_dir, full.names = TRUE))[, c("size", "mtime")])
