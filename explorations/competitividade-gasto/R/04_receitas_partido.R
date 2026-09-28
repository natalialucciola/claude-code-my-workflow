# ==============================================================================
# Receitas das candidaturas a deputado (federal e estadual), 2018 e 2022
#
# Extrai de data/raw/prestacao_de_contas_eleitorais_candidatos_{ano}.zip (TSE) as
# receitas de Deputado Federal e Estadual e resume, por candidatura:
#   receita_total, receita_partido (origem "Recursos de partido político"),
#   e, dentro dela, FEFC e Fundo Partidário.
# A medida 6 (parcela dos recursos do partido na lista) é calculada no script 05.
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/competitividade-gasto/R/04_receitas_partido.R
# Saída: data/processed/receitas_cand_dep.rds (não versionado)
#        explorations/competitividade-gasto/output/receitas_origem_fonte.csv
# ==============================================================================

library(data.table)
library(tidyverse)

raw_dir  <- "data/raw"
proc_dir <- "data/processed"
out_dir  <- "explorations/competitividade-gasto/output"
tmp_dir  <- file.path(tempdir(), "receitas")
dir.create(tmp_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(proc_dir, showWarnings = FALSE, recursive = TRUE)

cargos <- c("Deputado Federal", "Deputado Estadual")
cols <- c("TP_PRESTACAO_CONTAS", "SG_UF", "DS_CARGO", "SQ_CANDIDATO", "DS_FONTE_RECEITA",
          "DS_ORIGEM_RECEITA", "DS_NATUREZA_RECEITA", "SQ_RECEITA", "VR_RECEITA")

ler_receitas <- function(ano) {
  zip <- file.path(raw_dir, paste0("prestacao_de_contas_eleitorais_candidatos_", ano, ".zip"))
  csv <- paste0("receitas_candidatos_", ano, "_BRASIL.csv")
  unzip(zip, files = csv, exdir = tmp_dir, overwrite = TRUE)
  x <- fread(file.path(tmp_dir, csv), sep = ";", encoding = "Latin-1", colClasses = "character",
             select = cols)
  file.remove(file.path(tmp_dir, csv))
  x <- x[DS_CARGO %in% cargos]
  x[, VR_RECEITA := as.numeric(sub(",", ".", VR_RECEITA, fixed = TRUE))]
  # mesma regra das despesas: prestação final > parcial > demais; um registro por SQ_RECEITA
  tp <- toupper(x$TP_PRESTACAO_CONTAS)
  x <- x[order(-(tp == "FINAL"), -(tp == "PARCIAL"))][!duplicated(SQ_RECEITA)]
  as_tibble(x) |> mutate(ANO = ano)
}
rec <- map(c("2018", "2022"), ler_receitas) |> list_rbind()

# Tabela de origens e fontes (para conferir a definição de "recurso do partido")
origens <- rec |>
  summarise(n = n(), valor_mi = sum(VR_RECEITA, na.rm = TRUE) / 1e6,
            .by = c(ANO, DS_ORIGEM_RECEITA, DS_FONTE_RECEITA, DS_NATUREZA_RECEITA)) |>
  arrange(ANO, desc(valor_mi))
write_excel_csv2(origens, file.path(out_dir, "receitas_origem_fonte.csv"))

eh_partido <- \(o) str_detect(str_to_lower(o), "partido pol")
por_cand <- rec |>
  summarise(receita_total   = sum(VR_RECEITA, na.rm = TRUE),
            receita_partido = sum(VR_RECEITA[eh_partido(DS_ORIGEM_RECEITA)], na.rm = TRUE),
            partido_fefc    = sum(VR_RECEITA[eh_partido(DS_ORIGEM_RECEITA) &
                                               str_detect(DS_FONTE_RECEITA, "(?i)especial")], na.rm = TRUE),
            partido_fp      = sum(VR_RECEITA[eh_partido(DS_ORIGEM_RECEITA) &
                                               str_detect(DS_FONTE_RECEITA, "(?i)partid")], na.rm = TRUE),
            .by = c(ANO, DS_CARGO, SG_UF, SQ_CANDIDATO))
saveRDS(por_cand, file.path(proc_dir, "receitas_cand_dep.rds"))

print(origens |> mutate(valor_mi = round(valor_mi, 1)) |> as.data.frame(), right = FALSE)
message("Receitas: ", nrow(por_cand), " candidaturas com receita")
