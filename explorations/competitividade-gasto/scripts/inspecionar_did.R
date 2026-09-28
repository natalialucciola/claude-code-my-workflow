# Inspeção dos resultados do script 06 (rodar da raiz do repositório)
suppressMessages(library(tidyverse))
options(width = 220)
r <- suppressMessages(read_csv2("explorations/competitividade-gasto/output/did_resultados.csv",
                                show_col_types = FALSE))
fmt <- \(d) d |> mutate(across(c(att, ep, ic_inf, ic_sup, media_trat_2018), \(x) round(x, 2)),
                        sig = if_else(ic_inf > 0 | ic_sup < 0, "*", "")) |> as.data.frame()
for (w in c(FALSE, TRUE)) {
  cat("\n==== ponderado =", w, "====\n")
  print(r |> filter(ponderado == w, tipo != "Votos por faixa") |>
    select(grupo, tipo, medida, att, ep, ic_inf, ic_sup, media_trat_2018, n_listas) |> fmt())
  print(r |> filter(ponderado == w, tipo == "Votos por faixa") |>
    select(grupo, medida, faixa, att, ep, ic_inf, ic_sup, media_trat_2018) |> fmt())
}
