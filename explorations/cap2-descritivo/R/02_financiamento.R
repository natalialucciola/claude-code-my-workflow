# ==============================================================================
# Script: 02_financiamento.R
# Purpose: Receitas por origem/fonte e gasto por candidatura, 2014, 2018 e 2022
#          (a prestação de contas de 2026 ainda não foi publicada pelo TSE).
#          Regras iguais às de explorations/competitividade-gasto:
#   - receitas 2018/2022: prestação final > parcial; um registro por SQ_RECEITA
#   - gasto 2018/2022: despesas contratadas (despesas_categorizadas_dep_*.rds)
#     menos repasses ("Doações financeiras a outros candidatos/partidos")
#   - gasto 2014: despesas menos doações a outros candidatos/comitês e lançamentos
#     "Baixa de Estimaveis"
#   - recursos públicos: fonte FEFC ("Fundo Especial") ou Fundo Partidário
#
# Inputs:  data/raw/prestacao_final_2014.zip
#          data/raw/prestacao_de_contas_eleitorais_candidatos_{2018,2022}.zip
#          data/raw/despesas_categorizadas_dep_{2018,2022}.rds
# Outputs: explorations/cap2-descritivo/output/dados/financiamento_candidaturas.rds
#          explorations/cap2-descritivo/output/receitas_origem_ano.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/cap2-descritivo/R/02_financiamento.R
# ==============================================================================

library(tidyverse)
library(data.table)

raw_dir   <- file.path("data", "raw")
out_dir   <- file.path("explorations", "cap2-descritivo", "output")
dados_out <- file.path(out_dir, "dados")
dir.create(dados_out, showWarnings = FALSE, recursive = TRUE)
tmp_dir <- file.path(tempdir(), "cap2_fin")
dir.create(tmp_dir, showWarnings = FALSE)

cargos <- c("Deputado Federal", "Deputado Estadual")
num <- \(x) as.numeric(sub(",", ".", x, fixed = TRUE))

#' Agrupa a origem declarada da receita em categorias comparáveis entre anos
categorizar_origem <- function(o) {
  o <- str_to_lower(o)
  case_when(
    str_detect(o, "partido pol")                       ~ "Partido",
    str_detect(o, "outros candidatos")                 ~ "Outros candidatos",
    str_detect(o, "pessoas f|internet|financiamento coletivo") ~ "Pessoas físicas",
    str_detect(o, "próprios|proprios")                 ~ "Recursos próprios",
    str_detect(o, "pessoas jur")                       ~ "Pessoas jurídicas",
    TRUE                                               ~ "Outros"
  )
}

# ==============================================================================
# 1. 2014
# ==============================================================================

ler_2014 <- function(arquivo, cols) {
  unzip(file.path(raw_dir, "prestacao_final_2014.zip"), files = arquivo,
        exdir = tmp_dir, overwrite = TRUE)
  # fread resolve as aspas internas de alguns registros (avisa, sem perder linhas)
  x <- suppressWarnings(fread(file.path(tmp_dir, arquivo), sep = ";", encoding = "Latin-1",
                              colClasses = "character", select = cols))
  file.remove(file.path(tmp_dir, arquivo))
  as_tibble(x[Cargo %in% cargos])
}

rec_2014 <- ler_2014("receitas_candidatos_2014_brasil.txt",
                     c("Sequencial Candidato", "Cargo", "Tipo receita", "Fonte recurso",
                       "Valor receita")) |>
  transmute(ANO_ELEICAO = 2014L, SQ_CANDIDATO = `Sequencial Candidato`,
            origem = categorizar_origem(`Tipo receita`),
            publico = str_detect(`Fonte recurso`, "(?i)fundo partid"),
            valor = num(`Valor receita`))

gasto_2014 <- ler_2014("despesas_candidatos_2014_brasil.txt",
                       c("Sequencial Candidato", "Cargo", "Tipo despesa", "Valor despesa")) |>
  mutate(v = num(`Valor despesa`),
         excluir = str_detect(`Tipo despesa`, "^Doações financeiras a outros|^Baixa de Estimaveis")) |>
  summarise(gasto = sum(v[!excluir], na.rm = TRUE), .by = `Sequencial Candidato`) |>
  transmute(ANO_ELEICAO = 2014L, SQ_CANDIDATO = `Sequencial Candidato`, gasto)

# ==============================================================================
# 2. 2018 e 2022
# ==============================================================================

ler_receitas <- function(ano) {
  zip <- file.path(raw_dir, sprintf("prestacao_de_contas_eleitorais_candidatos_%d.zip", ano))
  csv <- sprintf("receitas_candidatos_%d_BRASIL.csv", ano)
  unzip(zip, files = csv, exdir = tmp_dir, overwrite = TRUE)
  x <- fread(file.path(tmp_dir, csv), sep = ";", encoding = "Latin-1", colClasses = "character",
             select = c("TP_PRESTACAO_CONTAS", "DS_CARGO", "SQ_CANDIDATO", "DS_FONTE_RECEITA",
                        "DS_ORIGEM_RECEITA", "SQ_RECEITA", "VR_RECEITA"))
  file.remove(file.path(tmp_dir, csv))
  x <- x[DS_CARGO %in% cargos]
  tp <- toupper(x$TP_PRESTACAO_CONTAS)
  x <- x[order(-(tp == "FINAL"), -(tp == "PARCIAL"))][!duplicated(SQ_RECEITA)]
  as_tibble(x) |>
    transmute(ANO_ELEICAO = ano, SQ_CANDIDATO, origem = categorizar_origem(DS_ORIGEM_RECEITA),
              publico = str_detect(DS_FONTE_RECEITA, "(?i)especial|partid"),
              valor = num(VR_RECEITA))
}

origem_repasse <- "Doações financeiras a outros candidatos/partidos"
gasto_recentes <- map(c(2018L, 2022L), \(a) {
  readRDS(file.path(raw_dir, sprintf("despesas_categorizadas_dep_%d.rds", a))) |>
    as_tibble() |>
    summarise(gasto = sum(VR_DESPESA_CONTRATADA[DS_ORIGEM_DESPESA != origem_repasse], na.rm = TRUE),
              .by = SQ_CANDIDATO) |>
    mutate(ANO_ELEICAO = a)
}) |> list_rbind()

receitas <- bind_rows(rec_2014, map(c(2018L, 2022L), ler_receitas) |> list_rbind())

# ==============================================================================
# 3. POR CANDIDATURA
# ==============================================================================

por_cand <- receitas |>
  summarise(
    receita_total      = sum(valor, na.rm = TRUE),
    receita_publica    = sum(valor[publico], na.rm = TRUE),
    receita_partido    = sum(valor[origem == "Partido"], na.rm = TRUE),
    receita_pf         = sum(valor[origem == "Pessoas físicas"], na.rm = TRUE),
    receita_propria    = sum(valor[origem == "Recursos próprios"], na.rm = TRUE),
    receita_pj         = sum(valor[origem == "Pessoas jurídicas"], na.rm = TRUE),
    receita_outros_cand = sum(valor[origem == "Outros candidatos"], na.rm = TRUE),
    .by = c(ANO_ELEICAO, SQ_CANDIDATO)
  ) |>
  full_join(bind_rows(gasto_2014, gasto_recentes), by = c("ANO_ELEICAO", "SQ_CANDIDATO")) |>
  mutate(across(starts_with("receita"), \(x) replace_na(x, 0)),
         gasto = replace_na(gasto, 0))

origens_ano <- receitas |>
  summarise(valor_mi = round(sum(valor, na.rm = TRUE) / 1e6, 1),
            valor_publico_mi = round(sum(valor[publico], na.rm = TRUE) / 1e6, 1),
            .by = c(ANO_ELEICAO, origem)) |>
  arrange(ANO_ELEICAO, desc(valor_mi))
print(origens_ano, n = 30)

saveRDS(por_cand, file.path(dados_out, "financiamento_candidaturas.rds"))
write_csv(origens_ano, file.path(out_dir, "receitas_origem_ano.csv"))
message("Financiamento: ", nrow(por_cand), " candidaturas (2014/2018/2022)")
