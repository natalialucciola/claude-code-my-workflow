# ==============================================================================
# Tabela de amostra do Cap. 3: candidaturas e cobertura dos dados por ano × cargo
#
# Para cada ano (2014–2026) e cargo (federal, estadual; sem DF):
#   candidaturas aptas e % de mulheres, pessoas negras e mulheres negras;
#   candidaturas com receita > 0 e com gasto > 0 (n e % das aptas), no total e
#   por grupo (% das candidaturas do grupo);
#   listas partido × UF (todas e as do painel balanceado) e disputas UF × cargo.
# Recursos e gasto de 2014 não entram (doação empresarial; fora da análise).
#
# Mesma base de candidaturas de 02_painel_listas.R (seção 1), reconstruída aqui
# para não depender de objetos intermediários.
#
# Rodar da raiz, depois de 01_bases_2026.R e 02_painel_listas.R:
#   Rscript explorations/ec111-did-2026/R/05_tabela_amostra.R
# Saída: output/tabela_amostra.csv e Quarto/thesis/chapters/_tabelas-cap3/amostra.md
# (depende de output/cobertura_painel.csv, gerado pelo R/14)
# ==============================================================================

library(tidyverse)

source("explorations/competitividade-gasto/R/funcoes_apoio.R")   # raca2()
out_dir <- "explorations/ec111-did-2026/output"
tab_dir <- "Quarto/thesis/chapters/_tabelas-cap3"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)
rd <- \(f) readRDS(file.path("data/raw", f)) |> as_tibble() |> ungroup()

cols <- c("ANO", "DS_CARGO", "sq_candidato", "uf", "mulher", "negra", "gasto", "receita_total")

# 2014: candidaturas aptas com votação (como em 02_painel_listas.R)
fed_14 <- rd("votos_mun_2014_df.rds") |> distinct(sq_candidato) |>
  mutate(DS_CARGO = "Deputado Federal")
est_14 <- rd("eleitos_e_compet_est_2014_df.rds") |> distinct(sq_candidato) |>
  mutate(DS_CARGO = "Deputado Estadual")
c14 <- bind_rows(rd("candidatos2014.rds") |> mutate(DS_CARGO = "Deputado Federal"),
                 rd("candidatos_estadual_2014.rds") |> mutate(DS_CARGO = "Deputado Estadual")) |>
  filter(situacao_candidatura == "APTO", genero %in% c("FEMININO", "MASCULINO")) |>
  inner_join(bind_rows(fed_14, est_14), by = c("sq_candidato", "DS_CARGO")) |>
  mutate(ANO = "2014", mulher = genero == "FEMININO", negra = raca2(raca) == "NEGRA",
         gasto = NA_real_, receita_total = NA_real_) |>
  select(all_of(cols))

c1822 <- readRDS("data/processed/base_did_candidatos.rds") |> select(all_of(cols))

c26 <- readRDS("data/processed/cand_dep_2026.rds") |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  mutate(mulher = genero == "FEMININO", negra = raca2(raca) == "NEGRA") |>
  select(all_of(cols))

cand <- bind_rows(c14, c1822, c26) |>
  filter(uf != "DF") |>
  mutate(ANO = as.character(ANO), mulher_negra = mulher & negra,
         cargo = if_else(DS_CARGO == "Deputado Federal", "Federal", "Estadual"),
         tem_rec = !is.na(receita_total) & receita_total > 0,
         tem_gasto = !is.na(gasto) & gasto > 0,
         com_dados = ANO != "2014")
stopifnot(!anyDuplicated(cand[c("ANO", "DS_CARGO", "sq_candidato")]))

pct <- \(x) 100 * mean(x)
pct_se <- \(x, ok) if (all(!ok)) NA_real_ else 100 * mean(x)

tab <- cand |>
  summarise(
    candidaturas = n(),
    pct_mulheres = pct(mulher), pct_negras = pct(negra), pct_mulheres_negras = pct(mulher_negra),
    n_receita = if (all(com_dados)) sum(tem_rec) else NA_integer_,
    pct_receita = pct_se(tem_rec, com_dados),
    n_gasto = if (all(com_dados)) sum(tem_gasto) else NA_integer_,
    pct_gasto = pct_se(tem_gasto, com_dados),
    pct_receita_mulheres = pct_se(tem_rec[mulher], com_dados),
    pct_receita_negras = pct_se(tem_rec[negra], com_dados),
    pct_receita_mulheres_negras = pct_se(tem_rec[mulher_negra], com_dados),
    pct_gasto_mulheres = pct_se(tem_gasto[mulher], com_dados),
    pct_gasto_negras = pct_se(tem_gasto[negra], com_dados),
    pct_gasto_mulheres_negras = pct_se(tem_gasto[mulher_negra], com_dados),
    disputas = n_distinct(uf),
    .by = c(ANO, cargo))

# Listas: do painel de 02_painel_listas.R (todas e balanceado = presentes nas 4 eleições)
painel <- readRDS("data/processed/painel_listas_2014_2026.rds") |> as_tibble()
listas <- painel |>
  mutate(ANO = as.character(ANO),
         cargo = if_else(DS_CARGO == "Deputado Federal", "Federal", "Estadual"),
         balanceado = anos_presente == "2014-2018-2022-2026") |>
  summarise(listas = n(), listas_balanceado = sum(balanceado), .by = c(ANO, cargo))

tab <- tab |>
  left_join(listas, by = c("ANO", "cargo")) |>
  mutate(cargo = factor(cargo, c("Federal", "Estadual"))) |>
  arrange(cargo, ANO)

# Conferência com o descritivo de 02_painel_listas.R
desc <- read_csv2(file.path(out_dir, "descritivo_grupos_ano_cargo.csv"), show_col_types = FALSE) |>
  transmute(ANO = as.character(ANO),
            cargo = if_else(DS_CARGO == "Deputado Federal", "Federal", "Estadual"),
            cand_desc = candidaturas, mulh_desc = pct_cand_mulheres)
conf <- tab |> mutate(cargo = as.character(cargo)) |> inner_join(desc, by = c("ANO", "cargo"))
stopifnot(nrow(conf) == 8, all(conf$candidaturas == conf$cand_desc),
          all(abs(conf$pct_mulheres - conf$mulh_desc) < 1e-6))

write_excel_csv2(tab, file.path(out_dir, "tabela_amostra.csv"))

# ------------------------------------------------------------------------------
# Tabela Markdown para o capítulo (incluída com {{< include >}})
# ------------------------------------------------------------------------------
f1 <- \(x) if_else(is.na(x), "—", formatC(x, format = "f", digits = 1, decimal.mark = ","))
f0 <- \(x) if_else(is.na(x), "—", formatC(x, format = "d", big.mark = "."))
# Uma só tabela (plano 2026-11-25, item 2): composição da amostra, listas, cobertura do
# painel balanceado (de output/cobertura_painel.csv, R/14) e cobertura financeira. A cobertura
# financeira por grupo fica no CSV e numa frase do texto.
cob_painel <- read_csv2(file.path(out_dir, "cobertura_painel.csv"), show_col_types = FALSE,
                        locale = locale(decimal_mark = ",")) |>
  transmute(ANO = as.character(ano), cargo, pct_cand_painel, pct_votos_painel)
tab <- tab |> mutate(cargo = as.character(cargo)) |>
  left_join(cob_painel, by = c("ANO", "cargo")) |>
  mutate(cargo = factor(cargo, c("Federal", "Estadual"))) |> arrange(cargo, ANO)
stopifnot(!anyNA(tab$pct_cand_painel))
linhas_comp <- tab |>
  mutate(cg = if_else(ANO == min(ANO), as.character(cargo), ""), .by = cargo) |>
  transmute(l = paste("|", cg, "|", ANO, "|", f0(candidaturas), "|", f1(pct_mulheres), "|",
                      f1(pct_negras), "|", f1(pct_mulheres_negras), "|",
                      f0(listas), "|", f0(listas_balanceado), "|", f1(pct_votos_painel), "|",
                      f1(pct_receita), "|", f1(pct_gasto), "|")) |>
  pull(l)
md_comp <- c(
  paste("| Cargo | Ano | Candidaturas aptas | % mulheres | % pessoas negras | % mulheres negras |",
        "Listas | Listas no painel | % dos votos no painel | % com receita | % com gasto |"),
  "|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
  linhas_comp,
  "",
  # legenda revisada em 25/11; marca .revisao retirada em 26/11
  paste0(": Amostra por cargo e eleição, com as candidaturas aptas a deputado federal e estadual ",
         "nas 26 UFs, sem o DF. A lista reúne as candidaturas de um partido, pela sigla vigente em ",
         "2026, a um cargo numa UF, e as listas no painel são as presentes nas quatro eleições, que ",
         "formam o painel balanceado das candidaturas e dos votos. A coluna % dos votos no painel ",
         "indica a parte dos votos nominais do cargo obtida pelas candidaturas dessas listas, e as ",
         "colunas % com receita e % com gasto, as candidaturas com receita e com gasto maiores que ",
         "zero na prestação de contas, que ficam fora da análise em 2014, ano de doação empresarial. ",
         "Fonte: TSE; elaboração própria (explorations/ec111-did-2026/R/05 e R/14). {#tbl-amostra-ec111}")
)
# UTF-8 explícito: no Windows, writeLines grava na codificação local e corrompe "—" e acentos
gravar_md <- function(linhas, arquivo) {
  con <- file(file.path(tab_dir, arquivo), open = "w", encoding = "UTF-8")
  writeLines(enc2utf8(linhas), con)
  close(con)
}
gravar_md(md_comp, "amostra.md")
# cobertura.md deixou de existir (fundida em amostra.md em 25/11)
if (file.exists(file.path(tab_dir, "cobertura.md"))) file.remove(file.path(tab_dir, "cobertura.md"))
print(tab, width = 200)
