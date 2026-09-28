# Inspeção do formato da prestação de contas de 2014 (rodar da raiz do repositório)
suppressMessages({library(data.table); library(tidyverse)})
options(width = 200)
tmp <- file.path(tempdir(), "i2014"); dir.create(tmp, showWarnings = FALSE)
zip <- "data/raw/prestacao_final_2014.zip"
ler <- function(csv, cols) {
  unzip(zip, files = csv, exdir = tmp, overwrite = TRUE)
  x <- fread(file.path(tmp, csv), sep = ";", encoding = "Latin-1", colClasses = "character", select = cols)
  file.remove(file.path(tmp, csv)); x[Cargo %in% c("Deputado Federal", "Deputado Estadual")]
}
d <- ler("despesas_candidatos_2014_brasil.txt", c("Cargo", "Tipo despesa", "Valor despesa"))
d[, v := as.numeric(sub(",", ".", `Valor despesa`, fixed = TRUE))]
cat("DESPESAS por tipo (R$ mi):\n")
print(d[, .(n = .N, mi = round(sum(v, na.rm = TRUE) / 1e6, 1)), by = `Tipo despesa`][order(-mi)], nrows = 80)
r <- ler("receitas_candidatos_2014_brasil.txt", c("Cargo", "Tipo receita", "Fonte recurso", "Valor receita"))
r[, v := as.numeric(sub(",", ".", `Valor receita`, fixed = TRUE))]
writeLines(""); cat("RECEITAS por tipo e fonte (R$ mi):\n")
print(r[, .(n = .N, mi = round(sum(v, na.rm = TRUE) / 1e6, 1)), by = .(`Tipo receita`, `Fonte recurso`)][order(-mi)])
writeLines(""); cat("Siglas por ano:\n")
for (f in c("candidatos2014.rds", "candidatos2018.rds", "candidatos2022.rds")) {
  cat(f, ":", paste(sort(unique(readRDS(file.path("data/raw", f))$partido)), collapse = " | ")); writeLines("")
}
