# ==============================================================================
# config.R — parâmetro da base territorial de voto, comum a 02–06
#
# Base do candidato = municípios com QL_voto > 1 E fatia do município nos votos
# do candidato >= fatia_min. Sem a segunda condição (fatia_min = 0), a base de
# voto é ~10x maior que a de gasto e a sobreposição satura (ver
# 05_validacao_gasto_voto.R). fatia_min = 0,025 foi escolhido em
# 05b_calibracao_base_voto.R — menor erro absoluto médio contra as lacunas de
# gênero/raça do capítulo em 2018/2022 (grade 0; 0,025; 0,05; 0,10) — e
# congelado antes de olhar 2026.
#
# Variantes: definir QLV_FATIA_MIN antes de rodar, ex. (PowerShell)
#   $env:QLV_FATIA_MIN = "0.05"; Rscript explorations/ql-voto-2026/R/02_sobreposicao.R
# Cada variante escreve em output/fatia_<valor>/.
# ==============================================================================

fatia_min <- as.numeric(Sys.getenv("QLV_FATIA_MIN", "0.025"))
stopifnot(!is.na(fatia_min), fatia_min >= 0, fatia_min < 1)

dados_dir <- file.path("explorations", "ql-voto-2026", "output", "dados")
out_dir   <- file.path("explorations", "ql-voto-2026", "output",
                       sprintf("fatia_%03d", round(1000 * fatia_min)))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

message("Base de voto: QL_voto > 1 e fatia >= ", fatia_min, " | saídas em ", out_dir)
