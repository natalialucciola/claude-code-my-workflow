# Inspeção rápida das tabelas do script 02 (rodar da raiz do repositório)
suppressMessages(library(tidyverse))
options(width = 200)
o <- "explorations/competitividade-gasto/output"
rd <- \(f) read_csv2(file.path(o, f), show_col_types = FALSE)
cat("LACUNAS (pp, % acima do patamar; mulheres-homens / negras-brancas)\n")
print(rd("lacunas_pct_acima_patamar.csv") |> mutate(across(where(is.numeric), \(x) round(x, 1))) |>
  as.data.frame())
writeLines(""); cat("% ACIMA 0.5 e 1, gênero × raça\n")
print(rd("pct_acima_patamar_grupo.csv") |> filter(recorte == "gênero × raça", patamar %in% c(.5, 1)) |>
  select(patamar, DS_CARGO, categoria, ANO, n, pct) |> mutate(pct = round(pct, 1)) |>
  pivot_wider(names_from = ANO, values_from = c(n, pct)) |> as.data.frame())
writeLines(""); cat("QUANTIS gênero × raça\n")
print(rd("quantis_razao_p10_grupo.csv") |> filter(recorte == "gênero × raça") |>
  mutate(across(p10:p90, \(x) signif(x, 2)), pct_sem_despesa = round(pct_sem_despesa, 1)) |>
  select(-recorte) |> as.data.frame())
writeLines(""); cat("QUANTIS por resultado × gênero e raça\n")
print(rd("quantis_razao_p10_resultado.csv") |>
  select(recorte, ANO, DS_CARGO, resultado, genero, raca, n, p25, p50, p75) |>
  mutate(across(p25:p75, \(x) signif(x, 2))) |>
  arrange(recorte, DS_CARGO, resultado, genero, raca, ANO) |> as.data.frame())
