# Eleitos com gasto < 1% do limite legal, por forma de eleição (rodar da raiz do repositório)
suppressMessages(library(tidyverse))
options(width = 200)
ler <- function(f) readRDS(file.path("data/raw", f)) |> as_tibble()
res <- bind_rows(
  ler("eleitos_e_compet_2018_df.rds") |> mutate(ANO = "2018", DS_CARGO = "Deputado Federal"),
  ler("eleitos_e_compet_2022_df.rds") |> mutate(ANO = "2022", DS_CARGO = "Deputado Federal"),
  ler("eleitos_e_compet_est_2018_df.rds") |> mutate(ANO = "2018", DS_CARGO = "Deputado Estadual"),
  ler("eleitos_e_compet_est_2022_df.rds") |> mutate(ANO = "2022", DS_CARGO = "Deputado Estadual")
) |> select(ANO, DS_CARGO, sq_candidato, uf = SG_UF, DS_SIT_TOT_TURNO)

b <- readRDS("data/processed/competitividade_gasto_cand.rds") |>
  filter(eleito == 1) |>
  left_join(res, by = c("ANO", "DS_CARGO", "sq_candidato", "uf"))

cat("Situações entre eleitos:\n")
print(count(b, DS_CARGO, ANO, DS_SIT_TOT_TURNO) |> as.data.frame())

b <- b |> mutate(forma = if_else(str_detect(DS_SIT_TOT_TURNO, "QP"), "Eleito por QP", "Eleito por média"),
                 votos_proprios = if_else(VOTOS_CAND_TOTAL >= QE, "Votos >= QE", "Votos < QE"))
cat("\nA) Por forma de eleição (TSE):\n")
print(b |> summarise(eleitos = n(), abaixo_1pct = sum(pct_teto < 1), .by = c(DS_CARGO, ANO, forma)) |>
  arrange(DS_CARGO, ANO, forma) |> as.data.frame())
cat("\nB) Por votos próprios vs. quociente eleitoral:\n")
print(b |> summarise(eleitos = n(), abaixo_1pct = sum(pct_teto < 1), .by = c(DS_CARGO, ANO, votos_proprios)) |>
  arrange(DS_CARGO, ANO, votos_proprios) |> as.data.frame())
cat("\nCasos abaixo de 1% do limite:\n")
print(b |> filter(pct_teto < 1) |>
  transmute(ANO, DS_CARGO, uf, partido, forma, gasto = round(gasto), votos = VOTOS_CAND_TOTAL,
            QE = round(QE), votos_sobre_QE = round(VOTOS_CAND_TOTAL / QE, 2)) |>
  arrange(DS_CARGO, ANO, desc(votos_sobre_QE)) |> as.data.frame())
