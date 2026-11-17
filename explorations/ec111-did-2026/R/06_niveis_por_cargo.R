# ==============================================================================
# Níveis por cargo dos desfechos de parcela do Cap. 3 (EC 111)
#
# Para cada desfecho de parcela e grupo: a média da parcela nas listas do painel
# balanceado, por cargo (federal, estadual) e ano. É a mesma amostra que o DiD usa
# em 03_did_event_study.R (estimar(): listas com o desfecho em todos os anos da
# janela). Recursos e gasto: 2018–2026; candidaturas e votos: 2014–2026.
#
# Serve para (i) mostrar de onde vem cada efeito (alta no federal × queda no
# estadual), usado no parágrafo de transbordamento de H2, e (ii) conferir que a
# conta 2×2 com essas médias reproduz o ATT do did (sem covariáveis, painel
# balanceado, sem peso, os dois coincidem).
#
# Rodar da raiz, depois de 02_painel_listas.R e 03_did_event_study.R:
#   Rscript explorations/ec111-did-2026/R/06_niveis_por_cargo.R
# Saída: output/niveis_por_cargo.csv (níveis) e output/niveis_conferencia_att.csv
# ==============================================================================

library(tidyverse)

out_dir <- "explorations/ec111-did-2026/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

painel <- readRDS("data/processed/painel_listas_2014_2026.rds")
did    <- read_csv2("explorations/ec111-did-2026/output/did_2026_resultados.csv",
                    show_col_types = FALSE)

anos_longos <- c(2014L, 2018L, 2022L, 2026L)
anos_rec    <- c(2018L, 2022L, 2026L)
grupos      <- c("mulher", "negra", "mulher_negra")
desfechos   <- tribble(
  ~medida,       ~anos,
  "cand",        anos_longos,
  "voto",        anos_longos,
  "rec_total",   anos_rec,
  "rec_partido", anos_rec,
  "rec_publico", anos_rec,
  "gasto",       anos_rec
)

#' Média da parcela por cargo × ano no painel balanceado do desfecho
niveis_de <- function(y, anos) {
  painel |>
    filter(ano %in% anos, !is.na(.data[[y]])) |>
    filter(n() == length(anos), .by = id) |>
    summarise(media = mean(.data[[y]], na.rm = FALSE), listas = n_distinct(id),
              .by = c(DS_CARGO, ano)) |>
    mutate(resultado = y)
}

niveis <- desfechos |>
  expand_grid(grupo = grupos) |>
  mutate(resultado = paste(medida, grupo, sep = "_")) |>
  pmap(\(medida, anos, grupo, resultado) niveis_de(resultado, anos)) |>
  list_rbind() |>
  mutate(cargo = if_else(DS_CARGO == "Deputado Federal", "federal", "estadual")) |>
  select(resultado, cargo, ano, media, listas) |>
  arrange(resultado, cargo, ano)
write_excel_csv2(niveis, file.path(out_dir, "niveis_por_cargo.csv"))

# Conferência: [F(t) − F(2018)] − [E(t) − E(2018)] contra o ATT do did
conta <- niveis |>
  select(resultado, cargo, ano, media) |>
  pivot_wider(names_from = cargo, values_from = media) |>
  mutate(var_federal  = federal  - federal[ano == 2018L],
         var_estadual = estadual - estadual[ano == 2018L],
         att_2x2 = var_federal - var_estadual, .by = resultado) |>
  filter(ano != 2018L)

conferencia <- did |>
  filter(nivel == "lista", !ponderado, balanceado,
         periodo %in% c("2014", "2022", "2026")) |>
  transmute(resultado, ano = as.integer(periodo), att_did = att) |>
  inner_join(conta, by = c("resultado", "ano")) |>
  mutate(dif = att_2x2 - att_did)
write_excel_csv2(conferencia, file.path(out_dir, "niveis_conferencia_att.csv"))

tol <- 1e-6
cat("Linhas conferidas:", nrow(conferencia),
    "| maior |dif|:", signif(max(abs(conferencia$dif)), 3), "\n")
if (any(abs(conferencia$dif) > tol)) stop("Níveis não reproduzem o ATT do did (tolerância 1e-6).")

print(as.data.frame(conta |> filter(str_detect(resultado, "^rec_partido")) |>
                      mutate(across(where(is.double), \(x) round(x, 1)))))
