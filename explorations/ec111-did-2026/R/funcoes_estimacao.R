# ==============================================================================
# Funções de estimação do Cap. 4 (EC 111), extraídas do R/10 em 2026-11-24 sem
# mudança de resultado (plano 2026-11-24_cap4-cacaniquel-item1-implementacao.md, Passo 2).
# Usadas por R/10_variaveis_principais.R e R/13_cacaniquel_viabilidade.R.
#
#   estimar(dados, y, anos, nivel, wild)  Callaway–Sant'Anna federal × estadual, base
#       universal 2018, painel balanceado, EP agrupados por UF; ATT por ano, média pós
#       ("Federal × Pós"), diferença 2026 − 2022; p do wild cluster bootstrap; confere
#       contra o TWFE de estudo de evento.
#   wild_p(d, y, anos_sub)  wild cluster bootstrap restrito (pesos de Webb, por UF) do
#       termo Federal × Pós.
#
# Réplicas: BITERS (bootstrap multiplicador do did) e WILD (wild bootstrap), lidas do
# ambiente na chamada; a semente fica no script que chama.
# ==============================================================================

suppressPackageStartupMessages({library(tidyverse); library(did); library(fixest)})
source("explorations/ec111-did-2026/R/funcoes_persistencia.R")

webb <- c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5))

#' Wild cluster bootstrap restrito (WCR, pesos de Webb, cluster = UF) para o termo
#' Federal × Pós da regressão com efeitos fixos de unidade e de ano
wild_p <- function(d, y, anos_sub, n_wild = as.integer(Sys.getenv("WILD", "9999"))) {
  dd <- d |> filter(ano %in% anos_sub) |> mutate(D = as.numeric(federal & ano >= 2022L))
  f <- dd[c("id", "ano")]
  X <- fixest::demean(cbind(Y = dd[[y]], D = dd$D), f = f)
  yt <- X[, "Y"]; Dt <- X[, "D"]; sDD <- sum(Dt^2)
  idx <- match(dd$uf_id, sort(unique(dd$uf_id))); G <- max(idx)
  ep <- \(e) sqrt(G / (G - 1) * sum(rowsum(Dt * e, idx)^2)) / sDD
  b0 <- sum(Dt * yt) / sDD
  t0 <- b0 / ep(yt - b0 * Dt)
  # sob H0 (δ = 0) o resíduo restrito é o próprio Y sem os efeitos fixos (yt)
  tstar <- vapply(seq_len(n_wild), \(i) {
    ys <- fixest::demean(yt * webb[sample.int(6, G, TRUE)][idx], f = f)[, 1]
    bs <- sum(Dt * ys) / sDD
    bs / ep(ys - bs * Dt)
  }, numeric(1))
  mean(abs(tstar) >= abs(t0))
}

estimar <- function(dados, y, anos, nivel, wild = TRUE,
                    biters = as.integer(Sys.getenv("BITERS", "25000")),
                    n_wild = as.integer(Sys.getenv("WILD", "9999"))) {
  d <- dados |> filter(ano %in% anos, !is.na(.data[[y]])) |>
    filter(n() == length(anos), .by = id) |>
    mutate(t = match(ano, anos), g = if_else(federal, match(2022L, anos), 0L))
  a <- suppressMessages(att_gt(yname = y, tname = "t", idname = "id", gname = "g", data = as.data.frame(d),
              panel = TRUE, control_group = "nevertreated", base_period = "universal",
              est_method = "dr", bstrap = TRUE, cband = TRUE, biters = biters,
              clustervars = c("id", "uf_id"), print_details = FALSE))
  es <- aggte(a, type = "dynamic", bstrap = TRUE, cband = TRUE, biters = biters)
  gr <- aggte(a, type = "group", bstrap = TRUE, cband = TRUE, biters = biters)
  ano_e <- anos[match(2022L, anos) + es$egt]
  pers <- dif_att(a, t1 = match(2022L, anos), t2 = match(2026L, anos),
                  cluster = cluster_de(a, "uf_id"))
  res <- bind_rows(
    tibble(periodo = as.character(ano_e), att = es$att.egt, ep = es$se.egt,
           crit = es$crit.val.egt) |> filter(periodo != "2018"),
    tibble(periodo = "Federal × Pós", att = gr$overall.att, ep = gr$overall.se,
           crit = qnorm(.975)),
    tibble(periodo = "Dif. 2026 − 2022", att = pers$att, ep = pers$ep, crit = qnorm(.975))) |>
    mutate(ic_inf = att - qnorm(.975) * ep, ic_sup = att + qnorm(.975) * ep,
           banda_inf = att - crit * ep, banda_sup = att + crit * ep,
           # um teste por linha (case_when avaliaria wild_p com o vetor inteiro de períodos)
           p_wild = map_dbl(periodo, \(p) if (!wild) NA_real_ else switch(p,
             "Federal × Pós" = wild_p(d, y, setdiff(anos, 2014L), n_wild),
             "2022" = wild_p(d, y, c(2018L, 2022L), n_wild),
             "2026" = wild_p(d, y, c(2018L, 2026L), n_wild),
             NA_real_)))
  # TWFE (estudo de evento) reproduz o did: confere o código
  tw <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + ano")), data = d,
              cluster = ~uf_id)
  cf <- coef(tw); nm <- str_extract(names(cf), "\\d{4}")
  chk <- res |> mutate(twfe = unname(cf[match(periodo, nm)])) |> filter(!is.na(twfe))
  stopifnot(all(abs(chk$att - chk$twfe) < 1e-6))
  b <- d |> filter(federal, ano == 2018L)
  res |> mutate(variavel = y, nivel = nivel, n_unidades = n_distinct(d$id),
                n_ufs = n_distinct(d$uf_id), base_federal_2018 = mean(b[[y]]), .before = 1)
}
