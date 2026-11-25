# ==============================================================================
# Receitas das candidaturas a deputado (federal e estadual), 2018 e 2022
#
# Extrai de data/raw/prestacao_de_contas_eleitorais_candidatos_{ano}.zip (TSE) as
# receitas de Deputado Federal e Estadual e resume, por candidatura:
#   receita_total (todas as fontes), receita_partido (origem "Recursos de partido
#   político"; dentro dela, FEFC e Fundo Partidário) e receita_publica (FEFC + Fundo
#   Partidário de qualquer origem).
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

source("explorations/competitividade-gasto/R/funcoes_apoio.R")

ler_receitas <- function(ano) {
  zip <- file.path(raw_dir, paste0("prestacao_de_contas_eleitorais_candidatos_", ano, ".zip"))
  csv <- paste0("receitas_candidatos_", ano, "_BRASIL.csv")
  # Regra de 2026-11-09 (decisão da autora): só as linhas idênticas em todas as colunas
  # saem. Antes ficava um registro por SQ_RECEITA, o que descartava itens distintos do
  # mesmo recibo (~0,4% da receita). Ver ler_prestacao em funcoes_apoio.R.
  x <- ler_prestacao(zip, csv, cargos)
  message(ano, ": ", attr(x, "copias_exatas"), " cópias exatas removidas (receitas)")
  x <- x[, ..cols]
  x[, VR_RECEITA := as.numeric(sub(",", ".", VR_RECEITA, fixed = TRUE))]
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
            # recursos públicos: FEFC + Fundo Partidário de qualquer origem (partido ou outros candidatos)
            receita_publica = sum(VR_RECEITA[str_detect(DS_FONTE_RECEITA, "(?i)especial|partid")], na.rm = TRUE),
            .by = c(ANO, DS_CARGO, SG_UF, SQ_CANDIDATO))

# Categorias que somam a receita total (regra de 2026-11-24, categorizar_receita em
# funcoes_apoio.R): separa os repasses de outras candidaturas em públicos (FEFC/FP) e
# privados, e isola a receita privada (decisão de doadores), usada na falsificação.
chaves <- c("ANO", "DS_CARGO", "SG_UF", "SQ_CANDIDATO")
cats <- resumir_receitas(as.data.table(rec)[, v := VR_RECEITA], by = chaves)
conf <- as_tibble(cats) |> inner_join(por_cand, by = chaves, suffix = c("", ".antiga"))
stopifnot(nrow(conf) == nrow(por_cand),
          isTRUE(all.equal(conf$receita_total, conf$receita_total.antiga)),
          isTRUE(all.equal(conf$receita_partido, conf$receita_partido.antiga)),
          isTRUE(all.equal(conf$receita_publica, conf$receita_publica.antiga)))
por_cand <- por_cand |>
  left_join(as_tibble(cats) |> select(all_of(chaves), repasse_cand_pub, repasse_cand_priv,
                                      receita_privada, receita_residual), by = chaves)
saveRDS(por_cand, file.path(proc_dir, "receitas_cand_dep.rds"))
print(por_cand |>
        summarise(across(c(receita_total, receita_partido, repasse_cand_pub, repasse_cand_priv,
                           receita_privada, receita_residual), \(x) round(sum(x) / 1e6, 1)),
                  .by = c(ANO, DS_CARGO)) |> as.data.frame())

print(origens |> mutate(valor_mi = round(valor_mi, 1)) |> as.data.frame(), right = FALSE)
message("Receitas: ", nrow(por_cand), " candidaturas com receita")
