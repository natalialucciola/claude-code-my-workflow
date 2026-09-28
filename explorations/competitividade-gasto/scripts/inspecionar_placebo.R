# Inspeção do placebo 2014 (rodar da raiz do repositório)
suppressMessages(library(tidyverse))
options(width = 200)
r <- suppressMessages(read_csv2("explorations/competitividade-gasto/output/did_placebo_2014.csv",
                                show_col_types = FALSE))
r |>
  mutate(txt = sprintf("%6.2f [%6.2f; %6.2f]%s", att, ic_inf, ic_sup, if_else(ic_inf > 0 | ic_sup < 0, "*", " "))) |>
  select(grupo, rotulo, e, txt, n_listas) |>
  mutate(e = if_else(e < 0, "placebo_14_18", "efeito_18_22")) |> pivot_wider(names_from = e, values_from = txt) |>

  as.data.frame() |> print(right = FALSE)
