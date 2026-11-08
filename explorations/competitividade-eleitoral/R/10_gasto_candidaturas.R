# =============================================================================
# 10 — Gasto de campanha por candidatura, junto à margem de votos (2014–2022)
#
# Insumo das medidas de competitividade pelo gasto derivadas da margem OLPR
# (plano: quality_reports/plans/2026-10-14_competitividade-margem-gasto.md).
#
# Gasto = despesas da prestação final do TSE, excluindo repasses a outras candidaturas
# ou partidos (mesma definição de explorations/competitividade-gasto/):
#   2014: "Doações financeiras a outros..." e "Baixa de Estimaveis" excluídas
#         (regra de competitividade-gasto/R/07_placebo_2014.R);
#   2018, 2022: competitividade_gasto_cand.rds (coluna gasto, já sem repasses).
# Candidatura apta sem registro de despesa entra com gasto 0 (marcada em sem_registro).
# 2026: data/processed/cand_dep_2026.rds (explorations/ec111-did-2026/R/01), mesma regra
#       (despesas contratadas sem repasses); arquivo do TSE de 08/11/2026, já com a
#       prestação final (>99% dos registros) — extensão de 2026-11-08.
#
# Entrada: data/processed/margem_resultado.rds, data/processed/competitividade_gasto_cand.rds,
#          data/raw/prestacao_final_2014.zip
# Saída:   data/processed/margem_gasto_insumos.rds (Federal e Estadual, 2014–2022)
#          explorations/competitividade-eleitoral/output/gasto_cobertura.csv
#
#   Rscript explorations/competitividade-eleitoral/R/10_gasto_candidaturas.R
# =============================================================================
library(data.table)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
res <- res[ano %in% c(2014L, 2018L, 2022L, 2026L) & cd_cargo %in% 6:7]
res[, sq_candidato := as.character(sq_candidato)]

# --- 2014: despesas da prestação final ---------------------------------------
td <- tempfile(); dir.create(td)
arq <- "despesas_candidatos_2014_brasil.txt"
unzip(file.path("data", "raw", "prestacao_final_2014.zip"), files = arq, exdir = td)
d14 <- fread(file.path(td, arq), sep = ";", encoding = "Latin-1", colClasses = "character",
             select = c("Sequencial Candidato", "Cargo", "Tipo despesa", "Valor despesa"))
unlink(td, recursive = TRUE)
d14 <- d14[Cargo %in% c("Deputado Federal", "Deputado Estadual")]
d14[, v := as.numeric(sub(",", ".", `Valor despesa`, fixed = TRUE))]
d14[, excluir := grepl("^Doações financeiras a outros|^Baixa de Estimaveis", `Tipo despesa`)]
g14 <- d14[, .(gasto = sum(v[!excluir], na.rm = TRUE)), by = .(sq_candidato = `Sequencial Candidato`)]
g14[, ano := 2014L]

# --- 2018 e 2022 ---------------------------------------------------------------
g1822 <- as.data.table(readRDS(file.path("data", "processed", "competitividade_gasto_cand.rds")))
g1822 <- g1822[, .(ano = as.integer(ANO), sq_candidato = as.character(sq_candidato), gasto)]

# --- 2026 (prestação parcial) ----------------------------------------------------
g26 <- as.data.table(readRDS(file.path("data", "processed", "cand_dep_2026.rds")))
g26 <- g26[, .(ano = 2026L, sq_candidato = as.character(sq_candidato), gasto)]

gasto <- rbind(g14[, .(ano, sq_candidato, gasto)], g1822, g26)
stopifnot(!anyDuplicated(gasto, by = c("ano", "sq_candidato")))

d <- merge(res, gasto, by = c("ano", "sq_candidato"), all.x = TRUE)
d[, sem_registro := is.na(gasto)]
d[is.na(gasto) | !apta, gasto := 0]
d[, gasto := round(pmax(gasto, 0))]                    # a busca da margem é em reais inteiros
stopifnot(nrow(d) == nrow(res))

cob <- d[apta == TRUE, .(aptas = .N, com_registro = sum(!sem_registro),
                         pct_com_registro = round(100 * mean(!sem_registro), 2),
                         gasto_zero = sum(gasto == 0),
                         eleitos_gasto_zero = sum(eleito & gasto == 0),
                         gasto_total_mi = round(sum(gasto) / 1e6, 1)),
         by = .(ano, cargo)][order(ano, cargo)]
print(cob)
fwrite(cob, file.path(dir_out, "gasto_cobertura.csv"))
saveRDS(d, file.path("data", "processed", "margem_gasto_insumos.rds"))
