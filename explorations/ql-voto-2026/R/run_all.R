# ==============================================================================
# run_all.R — roda 02–06 para as três variantes da base de voto
#   fatia 0,025 (principal), 0,05 (robustez), 0 (QL > 1 puro, referência)
# Pré-requisito: 00_baixar_dados_tse.R e 01_construir_ql_voto.R já rodados.
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/run_all.R
# ==============================================================================

scripts <- file.path("explorations", "ql-voto-2026", "R",
                     c("02_sobreposicao.R", "03_ddd.R", "04_modelo2_alcance.R",
                       "05_validacao_gasto_voto.R", "06_tabelas_graficos.R"))

for (fatia in c("0.025", "0.05", "0")) {
  # Processo-filho herda a variável (o argumento `env` de system2() não
  # funciona no Windows)
  Sys.setenv(QLV_FATIA_MIN = fatia)
  for (s in scripts) {
    message("\n##### fatia = ", fatia, " | ", basename(s))
    # Processo separado por script: cada um começa de ambiente limpo e lê
    # QLV_FATIA_MIN via config.R
    status <- system2("Rscript", s)
    if (status != 0) stop("Falhou: ", s, " (fatia = ", fatia, ")")
  }
}

source("explorations/ql-voto-2026/R/05b_calibracao_base_voto.R")
writeLines(capture.output(sessionInfo()),
           file.path("explorations", "ql-voto-2026", "output", "sessionInfo.txt"))
