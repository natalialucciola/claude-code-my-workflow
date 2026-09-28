# Inspeção dos resultados do script 06 (rodar da raiz do repositório)
suppressMessages(library(tidyverse))
options(width = 220)
r <- suppressMessages(read_csv2("explorations/competitividade-gasto/output/did_resultados.csv",
                                show_col_types = FALSE))
txt <- \(d) d |> mutate(txt = sprintf("%6.2f [%6.2f; %6.2f]%s (base %5.1f)", att, ic_inf, ic_sup,
                                      if_else(ic_inf > 0 | ic_sup < 0, "*", " "), media_trat_2018))
cat("RECURSOS por fonte (não ponderado | ponderado)\n")
r |> filter(str_detect(tipo, "^Recursos")) |> txt() |>
  mutate(item = if_else(is.na(medida), "grupo", paste("viável", medida)), pond = if_else(ponderado, "pond", "nao_pond")) |>
  select(grupo, fonte, item, pond, txt) |> pivot_wider(names_from = pond, values_from = txt) |>
  arrange(grupo, fonte, item) |> as.data.frame() |> print(right = FALSE)
cat("\nCANDIDATURAS VIÁVEIS e VOTOS\n")
r |> filter(tipo %in% c("Candidaturas viáveis", "Votos (total)"), !ponderado) |> txt() |>
  select(grupo, tipo, medida, txt, n_listas) |> as.data.frame() |> print(right = FALSE)
