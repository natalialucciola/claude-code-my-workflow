# ==============================================================================
# Cap. 3 (EC 111) como regressão linear de diferenças em diferenças
#
# Plano: quality_reports/plans/2026-11-17_cap4-ec111-regressao-did.md
#
# Para cada desfecho e grupo, nas mesmas unidades e amostras do capítulo:
#   (1) estudo de evento:  Y_ut = mu_u + lambda_t + sum_k delta_k (Federal_u x 1[t = k]),
#       k em {2014, 2022, 2026}, referência 2018 (2014 = pré-teste);
#   (2) termo único:       Y_ut = mu_u + lambda_t + delta (Federal_u x Pós_t), t em {2018, 2022, 2026};
#   (3) robustez (CSV à parte): termo único com 2014 e 2018 no "antes"; ponderado; desbalanceado;
#   (4) inferência por randomização: sob a hipótese nula de nenhum efeito, os rótulos federal e
#       estadual são intercambiáveis dentro de cada UF; sorteia-se a troca por UF e recalcula-se delta.
# Erros agrupados por lista (parcelas) e por UF (disputas). Sem covariáveis.
#
# Conferências (o script para se falharem):
#   - estudo de evento = ATT do did (Callaway & Sant'Anna) dos CSVs atuais, |dif| < 1e-6;
#   - termo único (antes = 2018) = média dos ATT de 2022 e 2026 do did, |dif| < 1e-6;
#   - fórmula fechada usada na randomização = coeficiente da regressão, |dif| < 1e-8.
#
# Rodar da raiz, depois de 02/03 (ec111-did-2026) e 05/14 (competitividade-eleitoral):
#   Rscript explorations/ec111-did-2026/R/08_regressao_did.R
# Saída (output/): regressao_did.csv, regressao_did_robustez.csv, randomizacao_did.csv
# ==============================================================================

library(tidyverse)
library(data.table)
library(fixest)

set.seed(20261117)
n_rand <- 10000L
tol    <- 1e-6
out_dir <- "explorations/ec111-did-2026/output"
ce_out  <- "explorations/competitividade-eleitoral/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

anos_longos <- c(2014L, 2018L, 2022L, 2026L)
anos_rec    <- c(2018L, 2022L, 2026L)
grupos <- c(mulher = "Mulheres", negra = "Pessoas negras", mulher_negra = "Mulheres negras")

# ------------------------------------------------------------------------------
# 1. Painéis
# ------------------------------------------------------------------------------
listas <- readRDS("data/processed/painel_listas_2014_2026.rds") |>
  mutate(unidade = id, uf = as.character(uf))
disputas <- readRDS("data/processed/painel_disputas_2014_2026.rds") |>
  mutate(unidade = id, uf = as.character(uf))

comparacoes <- list(
  "Mulheres − homens"                = list(g = quote(mulher), c = quote(!mulher), grupo = "Mulheres"),
  "Pessoas negras − brancas"         = list(g = quote(negra), c = quote(branca), grupo = "Pessoas negras"),
  "Mulheres negras − homens brancos" = list(g = quote(mulher & negra), c = quote(!mulher & branca),
                                            grupo = "Mulheres negras"))

#' Painel UF × cargo × ano da diferença (em p.p.) entre a taxa do grupo e a do grupo de comparação,
#' com a mesma construção de 05_ddd_margem.R e 14_ddd_gasto.R
celulas_taxa <- function(cand, y, comp) {
  gq <- comparacoes[[comp]]
  a <- cand[(eval(gq$g)), .(tg = mean(get(y)), n_g = .N), by = .(uf, cargo, federal, ano)]
  b <- cand[(eval(gq$c)), .(tc = mean(get(y)), n_c = .N), by = .(uf, cargo, federal, ano)]
  m <- merge(a, b, by = c("uf", "cargo", "federal", "ano"))
  m[, `:=`(y = 100 * (tg - tc), unidade = as.integer(factor(paste(uf, cargo))), peso = n_g + n_c)]
  stopifnot(m[, .N, by = unidade][, all(N == 4L)])
  as_tibble(m)
}

voto <- readRDS("data/processed/margem_resultado.rds")
voto <- voto[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
voto[, `:=`(federal = cd_cargo == 6L, branca = raca == "BRANCA",
            compet_voto = as.numeric(margem_qe >= -0.10), eleita = as.numeric(eleito))]
gasto <- readRDS("data/processed/margem_gasto_medidas.rds")
gasto <- gasto[cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe)]
gasto[, `:=`(federal = cd_cargo == 6L, branca = raca == "BRANCA",
             compet_gasto = as.numeric(margem_gasto_qe >= -0.10))]

# ------------------------------------------------------------------------------
# 2. Estimação
# ------------------------------------------------------------------------------
#' Estudo de evento e termo único para um painel longo (unidade, ano, federal, uf, y, peso)
estimar <- function(d, anos, cluster_var, ponderado = FALSE, balanceado = TRUE) {
  d <- d |> filter(ano %in% anos, !is.na(y))
  if (balanceado) d <- d |> filter(n() == length(anos), .by = unidade)
  d <- d |> mutate(fed_pos = as.numeric(federal & ano >= 2022L))
  w <- if (ponderado) ~peso else NULL
  cl <- as.formula(paste0("~", cluster_var))
  ev <- feols(y ~ i(ano, federal, ref = 2018) | unidade + ano, data = d, weights = w, cluster = cl)
  ct <- coeftable(ev)
  evento <- tibble(termo = str_extract(rownames(ct), "\\d{4}"), est = ct[, 1], ep = ct[, 2])
  pos <- feols(y ~ fed_pos | unidade + ano, data = d |> filter(ano >= 2018L), weights = w,
               cluster = cl)
  linhas <- bind_rows(evento,
                      tibble(termo = "Federal × Pós", est = unname(coef(pos)), ep = unname(se(pos))))
  if (2014L %in% anos) {
    pos14 <- feols(y ~ fed_pos | unidade + ano, data = d, weights = w, cluster = cl)
    linhas <- bind_rows(linhas, tibble(termo = "Federal × Pós (antes = 2014 e 2018)",
                                       est = unname(coef(pos14)), ep = unname(se(pos14))))
  }
  list(tab = linhas |> mutate(n_unidades = n_distinct(d$unidade), n_clusters = n_distinct(d[[cluster_var]])),
       dados = d)
}

#' Diferenças por unidade (pós − 2018) usadas na randomização; com painel balanceado e efeitos
#' fixos de unidade e ano, o coeficiente da regressão é a diferença de médias dessas diferenças
dif_unidade <- function(d) {
  d |>
    filter(ano %in% c(2018L, 2022L, 2026L)) |>
    summarise(federal = first(federal), uf = first(uf),
              d22 = y[ano == 2022L] - y[ano == 2018L], d26 = y[ano == 2026L] - y[ano == 2018L],
              .by = unidade) |>
    mutate(dpos = (d22 + d26) / 2)
}
contraste <- function(D, fed) {
  c(dpos = mean(D$dpos[fed]) - mean(D$dpos[!fed]),
    d22 = mean(D$d22[fed]) - mean(D$d22[!fed]), d26 = mean(D$d26[fed]) - mean(D$d26[!fed]))
}

#' Inferência por randomização: troca dos rótulos federal/estadual dentro de cada UF sorteada
randomizar <- function(d, delta_reg) {
  D <- dif_unidade(d)
  obs <- contraste(D, D$federal)
  stopifnot(abs(obs[["dpos"]] - delta_reg) < 1e-8)        # fórmula fechada = regressão
  ufs <- unique(D$uf); idx <- match(D$uf, ufs)
  sim <- matrix(NA_real_, n_rand, 3L, dimnames = list(NULL, names(obs)))
  for (r in seq_len(n_rand)) {
    troca <- sample(c(TRUE, FALSE), length(ufs), replace = TRUE)[idx]
    sim[r, ] <- contraste(D, xor(D$federal, troca))
  }
  p <- vapply(names(obs), \(k) (1 + sum(abs(sim[, k]) >= abs(obs[[k]]) - 1e-12)) / (n_rand + 1),
              numeric(1))
  tibble(termo = c("Federal × Pós", "2022", "2026"), est_obs = unname(obs), p_rand = unname(p),
         n_ufs = length(ufs))
}

# ------------------------------------------------------------------------------
# 3. Especificações do capítulo
# ------------------------------------------------------------------------------
especs <- bind_rows(
  expand_grid(medida = c("cand", "voto"), anos = list(anos_longos)),
  expand_grid(medida = c("rec_total", "rec_partido", "rec_publico", "gasto"), anos = list(anos_rec))) |>
  expand_grid(g = names(grupos))

principal <- list(); robustez <- list(); rand <- list()

for (i in seq_len(nrow(especs))) {
  e <- especs[i, ]; y <- paste(e$medida, e$g, sep = "_")
  d <- listas |> transmute(unidade, ano, federal, uf, y = .data[[y]], peso)
  r <- estimar(d, e$anos[[1]], "unidade")
  r_uf <- estimar(d, e$anos[[1]], "uf")
  chave <- tibble(nivel = "lista", resultado = y, grupo = grupos[[e$g]], medida = e$medida)
  principal[[y]] <- bind_cols(chave, r$tab |> mutate(ep_uf = r_uf$tab$ep))
  robustez[[paste(y, "pond")]] <- bind_cols(chave, especificacao = "ponderado (votos da lista em 2018)",
                                            estimar(d, e$anos[[1]], "unidade", ponderado = TRUE)$tab)
  robustez[[paste(y, "desb")]] <- bind_cols(chave, especificacao = "painel desbalanceado",
                                            estimar(d, e$anos[[1]], "unidade", balanceado = FALSE)$tab)
  delta <- r$tab$est[r$tab$termo == "Federal × Pós"]
  rand[[y]] <- bind_cols(chave, randomizar(r$dados, delta))
}

for (g in names(grupos)) {                          # cadeiras: disputa UF × cargo
  y <- paste0("cadeira_", g)
  d <- disputas |> transmute(unidade, ano, federal, uf, y = .data[[y]], peso = n_cadeiras)
  r <- estimar(d, anos_longos, "uf")
  chave <- tibble(nivel = "disputa", resultado = y, grupo = grupos[[g]], medida = "cadeira")
  principal[[y]] <- bind_cols(chave, r$tab |> mutate(ep_uf = ep))
  rand[[y]] <- bind_cols(chave, randomizar(r$dados, r$tab$est[r$tab$termo == "Federal × Pós"]))
}

taxas <- list(compet_voto = list(cand = voto, rotulo = "ate_010", arq = "ddd_resultados.csv"),
              eleita      = list(cand = voto, rotulo = "eleita", arq = "ddd_resultados.csv"),
              compet_gasto = list(cand = gasto, rotulo = "a_010", arq = "ddd_gasto_resultados.csv"))
for (y in names(taxas)) for (comp in names(comparacoes)) {
  cel <- celulas_taxa(taxas[[y]]$cand, y, comp)
  d <- cel |> transmute(unidade, ano, federal, uf, y, peso)
  r <- estimar(d, anos_longos, "uf")
  chave <- tibble(nivel = "disputa (tripla diferença)", resultado = y,
                  grupo = comparacoes[[comp]]$grupo, medida = y, comparacao = comp)
  k <- paste(y, comp)
  principal[[k]] <- bind_cols(chave, r$tab |> mutate(ep_uf = ep))
  robustez[[paste(k, "pond")]] <- bind_cols(chave, especificacao = "ponderado (candidaturas da disputa)",
                                            estimar(d, anos_longos, "uf", ponderado = TRUE)$tab)
  rand[[k]] <- bind_cols(chave, randomizar(r$dados, r$tab$est[r$tab$termo == "Federal × Pós"]))
}

principal <- bind_rows(principal) |>
  mutate(ic_inf = est - qnorm(.975) * ep, ic_sup = est + qnorm(.975) * ep)
robustez  <- bind_rows(robustez) |>
  mutate(ic_inf = est - qnorm(.975) * ep, ic_sup = est + qnorm(.975) * ep)
rand      <- bind_rows(rand)

# ------------------------------------------------------------------------------
# 4. Conferências contra os resultados atuais do capítulo
# ------------------------------------------------------------------------------
did <- read_csv2(file.path(out_dir, "did_2026_resultados.csv"), show_col_types = FALSE) |>
  filter(!ponderado, balanceado, nivel %in% c("lista", "disputa")) |>
  mutate(termo = recode(periodo, "Média 2022–2026" = "Federal × Pós")) |>
  select(resultado, nivel, termo, att)
conf_did <- principal |> filter(nivel %in% c("lista", "disputa"), termo != "Federal × Pós (antes = 2014 e 2018)") |>
  inner_join(did, by = c("resultado", "nivel", "termo")) |> mutate(dif = est - att)

ddd <- bind_rows(
  read_csv(file.path(ce_out, "ddd_resultados.csv"), show_col_types = FALSE) |>
    filter(!ponderado, amostra == "Todas as UFs", desfecho %in% c("ate_010", "eleita")),
  read_csv(file.path(ce_out, "ddd_gasto_resultados.csv"), show_col_types = FALSE) |>
    filter(!ponderado, desfecho == "a_010")) |>
  mutate(resultado = recode(desfecho, ate_010 = "compet_voto", a_010 = "compet_gasto"),
         termo = case_when(termo == "ATT geral (2022 e 2026)" ~ "Federal × Pós",
                           !is.na(ano) ~ as.character(ano))) |>
  filter(!is.na(termo), termo != "2018") |>
  select(resultado, comparacao, termo, att)
conf_ddd <- principal |> filter(nivel == "disputa (tripla diferença)") |>
  inner_join(ddd, by = c("resultado", "comparacao", "termo")) |> mutate(dif = est - att)

conf <- bind_rows(conf_did, conf_ddd)
cat("Conferências:", nrow(conf_did), "(funil) +", nrow(conf_ddd), "(tripla diferença);",
    "maior |dif| =", signif(max(abs(conf$dif)), 3), "\n")
stopifnot(nrow(conf_did) == 3 * (2 * 4 + 4 * 3 + 4),   # cand, voto: 4 termos; recursos: 3; cadeiras: 4
          nrow(conf_ddd) == 3 * 3 * 4, all(abs(conf$dif) < tol))

# ------------------------------------------------------------------------------
# 5. Saída
# ------------------------------------------------------------------------------
principal <- principal |> left_join(rand |> select(nivel, resultado, grupo, termo, p_rand, n_ufs),
                                    by = c("nivel", "resultado", "grupo", "termo"))
write_excel_csv2(principal, file.path(out_dir, "regressao_did.csv"))
write_excel_csv2(robustez, file.path(out_dir, "regressao_did_robustez.csv"))
write_excel_csv2(rand, file.path(out_dir, "randomizacao_did.csv"))

principal |>
  filter(termo %in% c("2014", "Federal × Pós", "Federal × Pós (antes = 2014 e 2018)")) |>
  transmute(nivel = str_sub(nivel, 1, 7), resultado, grupo, termo = str_sub(termo, 1, 16),
            est = round(est, 2), ic = sprintf("[%.1f; %.1f]", ic_inf, ic_sup), p_rand = round(p_rand, 3)) |>
  as.data.frame() |> print(right = FALSE)
