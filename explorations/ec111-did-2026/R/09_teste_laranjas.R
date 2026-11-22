# ==============================================================================
# Teste das laranjas: a EC 111 trocou candidaturas laranja por caça-níqueis?
#
# Laranja (Gatto & Wylie 2021, seguindo Wylie et al. 2019): candidatura apta com
# votos <= 1% da votação do último eleito (o eleito menos votado) da UF, no mesmo
# cargo e ano.
#
# Implicação testada: se o voto em dobro torna inútil a candidatura sem votos,
# a taxa de laranjas entre mulheres (pessoas negras, mulheres negras) deve cair
# no cargo federal depois de 2022, em relação ao estadual e ao grupo de
# comparação (homens, pessoas brancas, homens brancos).
#
# Desenho igual ao da tbl-ddd do capítulo: unidade UF x cargo (26 UFs, sem DF),
# sem ponderação, base 2018, 2014 como pré-teste, erros agrupados por UF.
#   DiD  : taxa do grupo, federal x estadual
#   DDD  : (taxa do grupo - taxa da comparação), federal x estadual
# Também reporta a faixa intermediária ("caça-níqueis"): acima do corte de
# laranja e não competitiva (fora das eleitas e a mais de 0,1 QE do limiar).
#
# Rodar da raiz:  Rscript explorations/ec111-did-2026/R/09_teste_laranjas.R
# Saída: explorations/ec111-did-2026/output/teste_laranjas.csv
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({ library(tidyverse); library(fixest) })

out_dir <- "explorations/ec111-did-2026/output"
corte   <- as.numeric(Sys.getenv("CORTE_LARANJA", "0.01"))

# margem_resultado: candidaturas 2014-2026 com a margem em QE do capítulo
# (competitiva = eleita ou a menos de 0,1 QE do limiar; script 02_painel_listas.R)
cand <- readRDS("data/processed/margem_resultado.rds") |>
  as_tibble() |>
  filter(apta, uf != "DF", cd_cargo %in% c(6L, 7L)) |>
  mutate(cargo  = if_else(cd_cargo == 6L, "Federal", "Estadual"),
         votos  = replace_na(votos, 0),
         branca = raca == "BRANCA",
         compet = eleito | (!is.na(margem_qe) & margem_qe >= -0.1))

ultimo <- cand |> filter(eleito) |>
  group_by(ano, uf, cargo) |> summarise(min_eleito = min(votos), .groups = "drop")

cand <- cand |> left_join(ultimo, by = c("ano", "uf", "cargo")) |>
  mutate(laranja    = votos <= corte * min_eleito,
         cacaniquel = !laranja & !compet)

cat("Raça não informada (excluída dos contrastes raciais):", sum(is.na(cand$raca)), "\n")
cat("Laranjas por ano/cargo/gênero (% das candidaturas):\n")
cand |> group_by(ano, cargo, mulher) |>
  summarise(n = n(), pct_laranja = round(100 * mean(laranja), 1), .groups = "drop") |>
  pivot_wider(names_from = mulher, values_from = c(n, pct_laranja)) |> print()

contrastes <- list(
  "Mulheres - homens"                  = list(g = quote(mulher),           c = quote(!mulher)),
  "Pessoas negras - brancas"           = list(g = quote(negra),            c = quote(branca)),
  "Mulheres negras - homens brancos"   = list(g = quote(mulher & negra),   c = quote(!mulher & branca))
)
desfechos <- c(laranja = "Laranja (<= 1% do último eleito)",
               cacaniquel = "Caça-níquel (acima do corte, não competitiva)")

estima <- function(df, y) {
  df <- df |> mutate(federal = cargo == "Federal", unidade = paste(uf, cargo))
  m  <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | unidade + ano")),
              data = df, cluster = ~uf)
  ct <- coeftable(m)
  tibble(termo = rownames(ct), est = ct[, 1], ep = ct[, 2]) |>
    mutate(ano = as.integer(str_extract(termo, "\\d{4}")),
           lo = est - 1.96 * ep, hi = est + 1.96 * ep) |>
    select(ano, est, lo, hi)
}

res <- list()
for (nm in names(contrastes)) {
  g <- contrastes[[nm]]$g; c0 <- contrastes[[nm]]$c
  for (y in names(desfechos)) {
    tx <- cand |> group_by(ano, uf, cargo) |>
      summarise(grupo = 100 * mean(.data[[y]][which(eval(g))]),
                comp  = 100 * mean(.data[[y]][which(eval(c0))]),
                n_g = sum(eval(g), na.rm = TRUE), .groups = "drop") |>
      mutate(dif = grupo - comp)
    res[[length(res) + 1]] <- bind_rows(
      estima(tx, "grupo") |> mutate(tipo = "DiD (taxa do grupo)"),
      estima(tx, "dif")   |> mutate(tipo = "DDD (grupo - comparação)")
    ) |> mutate(contraste = nm, desfecho = desfechos[[y]])
    # níveis brutos no federal, para leitura
    niv <- tx |> group_by(ano, cargo) |>
      summarise(grupo = mean(grupo), comp = mean(comp), .groups = "drop")
    cat("\n", nm, "|", desfechos[[y]], "| médias por UF\n"); print(niv, n = 8)
  }
}
res <- bind_rows(res) |> select(contraste, desfecho, tipo, ano, est, lo, hi)
write_csv(res, file.path(out_dir, "teste_laranjas.csv"))
res |> mutate(across(c(est, lo, hi), ~ round(.x, 1)),
              sig = if_else(lo > 0 | hi < 0, "*", "")) |> print(n = Inf)
