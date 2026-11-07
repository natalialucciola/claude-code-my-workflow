# =============================================================================
# 00_setup.R
# Objetivo: preparar o ambiente e checar pré-condições antes de baixar qualquer
#           dado, conforme o plano (docs/plano-pesquisa.md, Seção 2.2 e
#           checklist item 1).
#
# Inputs:  nenhum
# Outputs: nenhum arquivo — só checagens impressas no console. Se alguma
#          checagem falhar, PARE e ajuste o pipeline antes de seguir para
#          01_download_candidatos.R.
# =============================================================================

pacotes_necessarios <- c(
  "electionsBR", "dplyr", "tidyr", "readr", "purrr", "stringr",
  "ggplot2", "janitor" # janitor ajuda a padronizar nomes de coluna entre anos
)

faltando <- pacotes_necessarios[!pacotes_necessarios %in% rownames(installed.packages())]
if (length(faltando) > 0) {
  message("Pacotes faltando, instale antes de continuar: ", paste(faltando, collapse = ", "))
}

library(electionsBR)

# --- Checagem 1: versão do electionsBR e API disponível -----------------
# O plano alerta que a API do pacote mudou ao longo do tempo (funções
# "clássicas" por domínio, ex. candidate_fed(), vs. a função unificada mais
# recente elections_tse(year, uf, type)). Descubra qual está disponível na
# instalação atual antes de escrever o restante do pipeline.
cat("Versão instalada do electionsBR:\n")
print(packageVersion("electionsBR"))

cat("\nFunções exportadas disponíveis (procure candidate_fed e/ou elections_tse):\n")
print(ls("package:electionsBR"))

# TODO: rodar ?electionsBR e vignette("introduction", package = "electionsBR")
# manualmente e confirmar:
#   (a) se o ano 2026 é suportado nativamente pela função de candidatos;
#   (b) os nomes exatos de colunas (sexo costuma variar entre DS_GENERO,
#       CD_GENERO, SG_GENERO dependendo da base/ano) — validar com
#       names(df) e str(df) num teste pequeno (ex.: um único UF, um único ano)
#       antes de baixar a base completa.

# --- Checagem 2: teste pequeno de download -------------------------------
# TODO: rodar um teste mínimo (ex.: candidate_fed(year = 2022, uf = "DF"),
# ou o equivalente via elections_tse(), dependendo do resultado da checagem
# acima) e inspecionar o resultado antes de baixar todos os anos/UFs.
# Se 2026 não estiver disponível via pacote, terá de baixar manualmente do
# portal de dados abertos do TSE (https://dadosabertos.tse.jus.br) — ver
# plano, Seção 2.1 e 2.2, para o nome esperado dos arquivos
# (consulta_cand_2026_BRASIL.csv ou um arquivo por UF).

cat("\nSetup concluído. Revise o console acima antes de rodar 01_download_candidatos.R.\n")
