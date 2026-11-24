# ==============================================================================
# 10 — Variáveis principais do Cap. 4 (EC 111), plano 2026-11-22
#      (quality_reports/plans/2026-11-22_cap4-ec111-variaveis-identificacao.md)
#
# Mesmo desenho do R/03: federal (tratado a partir de 2022) × estadual (nunca tratado),
# base universal 2018, pré-teste 2014 onde há dado, painel balanceado, sem ponderação.
# Mudanças em relação ao R/03 e aos R/05 e R/14 da competitividade:
#   (1) erros agrupados por UF em TODAS as variáveis (clustervars = c("id", "uf_id"));
#   (2) grupo de comparação = complemento (homens; não negras; todas as demais
#       candidaturas), com homens brancos e pessoas brancas como linhas adicionais
#       só nas diferenças de taxas;
#   (3) variável nova: investimento relativo por candidatura (razão das médias);
#   (4) conferência por wild cluster bootstrap restrito (Webb, por UF) no termo
#       Federal × Pós e em cada ano pós, e níveis por cargo de todas as variáveis.
#
# Variáveis (g = mulher, negra, mulher_negra; c = complemento de g):
#   Lista (partido × UF × cargo):
#     cand_g         % das candidaturas aptas da lista que são de g            2014–2026
#     rec_partido_g  % das transferências do partido à lista que foram para g  2018–2026
#     gasto_g        % do gasto da lista feito por g                           2018–2026
#     voto_g         % dos votos nominais da lista dados a g                   2014–2026
#     rec_partido_ampla_g  idem rec_partido, somando o FEFC/FP repassado por outras
#                    candidaturas (robustez da H2; plano 2026-11-24)          2018–2026
#     rtp_g, rtc_pub_g, rtc_priv_g, rtpriv_g, rtres_g  parcela de g na receita total da
#                    lista vinda do partido / repassada por outras candidaturas (FEFC-FP;
#                    outros recursos) / privada (pessoas físicas, financiamento coletivo,
#                    recursos próprios) / residual; somam rec_total_g. rtpriv é o teste de
#                    falsificação (com wild bootstrap); até 23/11 era rto = total − partido,
#                    que incluía os repasses de outras candidaturas         2018–2026
#   Disputa (UF × cargo):
#     inv_g          100 × média transferida por candidatura de g ÷ média por
#                    candidatura de c (100 = igualdade)                         2018–2026
#     inv_c_g/inv_nc_g  idem só entre competitivas / não competitivas pelo voto
#     excesso_g      % das transferências da disputa para g − % das candidaturas
#                    da disputa que são g (conferência de inv_g)               2018–2026
#     pcv_g          % das competitivas pelo voto (eleitas ou a < 0,1 QE) que são g
#     pcg_g          % das competitivas pelo gasto (margem de gasto ≥ −0,1 QE) que são g
#     cadeira_g      % dos eleitos da disputa que são g                        2014–2026
#     tcv_g, tcg_g, tel_g  taxa de competitivas pelo voto / pelo gasto / de eleitas
#                    de g menos a de c (p.p.); sufixos _hb (mulheres negras − homens
#                    brancos) e _br (negras − brancas) = comparações adicionais
#
# Entradas: data/processed/painel_listas_2014_2026.rds, cand_ec111_2014_2026.rds (R/02),
#           margem_resultado.rds (competitividade-eleitoral R/03),
#           margem_gasto_medidas.rds (competitividade-eleitoral R/12)
# Saídas (output/): variaveis_principais_resultados.csv, variaveis_principais_niveis.csv,
#                   variaveis_principais_comparacao.csv (novo × antigo)
#
#   Rscript explorations/ec111-did-2026/R/10_variaveis_principais.R
#   (BITERS=200 WILD=199 para testar o código; tese: BITERS=25000 WILD=1999, decisão da
#   autora em 22/11, depois de a rodada com 9999 ser interrompida por falta de memória)
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({library(tidyverse); library(did); library(fixest)})
source("explorations/ec111-did-2026/R/funcoes_persistencia.R")

set.seed(20261122)
out_dir <- "explorations/ec111-did-2026/output"
biters  <- as.integer(Sys.getenv("BITERS", "25000"))
n_wild  <- as.integer(Sys.getenv("WILD", "9999"))
anos_longos <- c(2014L, 2018L, 2022L, 2026L)
anos_rec    <- c(2018L, 2022L, 2026L)
gs <- c("mulher", "negra", "mulher_negra")
pp <- \(num, den) if_else(den > 0, 100 * num / den, NA_real_)
razao <- \(sg, ng, sc, nc) if_else(ng > 0 & nc > 0 & sc > 0, 100 * (sg / ng) / (sc / nc), NA_real_)

# ------------------------------------------------------------------------------
# 1. Painéis
# ------------------------------------------------------------------------------
listas <- readRDS("data/processed/painel_listas_2014_2026.rds") |>
  mutate(uf_id = as.integer(factor(uf)))

cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO), rp = receita_partido)

disp_cand <- cand |>
  summarise(across(c(mulher, negra, mulher_negra), list(
              cadeira = \(g) pp(sum(g & eleito == 1L), sum(eleito == 1L)),
              pcv     = \(g) pp(sum(g & compet_m), sum(compet_m)),
              inv     = \(g) razao(sum(rp[g]), sum(g), sum(rp[!g]), sum(!g)),
              inv_c   = \(g) razao(sum(rp[g & compet_m]), sum(g & compet_m),
                               sum(rp[!g & compet_m]), sum(!g & compet_m)),
              inv_nc  = \(g) razao(sum(rp[g & !compet_m]), sum(g & !compet_m),
                               sum(rp[!g & !compet_m]), sum(!g & !compet_m)),
              excesso = \(g) pp(sum(rp[g]), sum(rp)) - 100 * mean(g)),
            .names = "{.fn}_{.col}"),
            .by = c(ano, DS_CARGO, federal, uf))

# Taxas pela margem de votos: mesma amostra do R/05 da competitividade
mr <- readRDS("data/processed/margem_resultado.rds") |> as_tibble() |>
  filter(apta, cd_cargo %in% 6:7, uf != "DF", !is.na(margem_qe), !is.na(genero)) |>
  mutate(ano = as.integer(ano), federal = cd_cargo == 6L, branca = raca == "BRANCA",
         mulher_negra = mulher & negra, cv = margem_qe >= -0.10, el = as.logical(eleito))
# Margem de gasto: mesma amostra do R/14 (2018–2026)
mg <- readRDS("data/processed/margem_gasto_medidas.rds") |> as_tibble() |>
  filter(cd_cargo %in% 6:7, uf != "DF", !is.na(margem_qe), ano >= 2018) |>
  mutate(ano = as.integer(ano), federal = cd_cargo == 6L, branca = raca == "BRANCA",
         mulher_negra = mulher & negra, cg = margem_gasto_qe >= -0.10)

dif_taxa <- \(x, g, c) if_else(sum(g) > 0 & sum(c) > 0, 100 * (mean(x[g]) - mean(x[c])), NA_real_)
disp_mr <- mr |>
  summarise(tcv_mulher = dif_taxa(cv, mulher, !mulher),
            tcv_negra = dif_taxa(cv, negra, !negra),
            tcv_mulher_negra = dif_taxa(cv, mulher_negra, !mulher_negra),
            tcv_br_negra = dif_taxa(cv, negra, branca),
            tcv_hb_mulher_negra = dif_taxa(cv, mulher_negra, !mulher & branca),
            tel_mulher = dif_taxa(el, mulher, !mulher),
            tel_negra = dif_taxa(el, negra, !negra),
            tel_mulher_negra = dif_taxa(el, mulher_negra, !mulher_negra),
            tel_br_negra = dif_taxa(el, negra, branca),
            tel_hb_mulher_negra = dif_taxa(el, mulher_negra, !mulher & branca),
            .by = c(ano, federal, uf))
disp_mg <- mg |>
  summarise(pcg_mulher = pp(sum(mulher & cg), sum(cg)),
            pcg_negra = pp(sum(negra & cg), sum(cg)),
            pcg_mulher_negra = pp(sum(mulher_negra & cg), sum(cg)),
            tcg_mulher = dif_taxa(cg, mulher, !mulher),
            tcg_negra = dif_taxa(cg, negra, !negra),
            tcg_mulher_negra = dif_taxa(cg, mulher_negra, !mulher_negra),
            tcg_br_negra = dif_taxa(cg, negra, branca),
            tcg_hb_mulher_negra = dif_taxa(cg, mulher_negra, !mulher & branca),
            .by = c(ano, federal, uf))

disputas <- disp_cand |>
  left_join(disp_mr, by = c("ano", "federal", "uf")) |>
  left_join(disp_mg, by = c("ano", "federal", "uf")) |>
  mutate(id = as.integer(factor(paste(uf, DS_CARGO))), uf_id = as.integer(factor(uf)))
stopifnot(nrow(disputas) == 26L * 2L * 4L)
# inv_* só existe a partir de 2018 (2014 sem recursos)
disputas <- disputas |> mutate(across(starts_with(c("inv_", "excesso_")),
                                      \(x) if_else(ano < 2018L, NA_real_, x)))

# ------------------------------------------------------------------------------
# 2. Estimação (CS = TWFE com um só grupo tratado; EP agrupado por UF)
# ------------------------------------------------------------------------------
webb <- c(-sqrt(1.5), -1, -sqrt(0.5), sqrt(0.5), 1, sqrt(1.5))

#' Wild cluster bootstrap restrito (WCR, pesos de Webb, cluster = UF) para o termo
#' Federal × Pós da regressão com efeitos fixos de unidade e de ano
wild_p <- function(d, y, anos_sub) {
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

estimar <- function(dados, y, anos, nivel, wild = TRUE) {
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
             "Federal × Pós" = wild_p(d, y, setdiff(anos, 2014L)),
             "2022" = wild_p(d, y, c(2018L, 2022L)),
             "2026" = wild_p(d, y, c(2018L, 2026L)),
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

grade <- bind_rows(
  expand_grid(base = "lista", v = c("cand", "voto"), g = gs, anos = list(anos_longos)),
  expand_grid(base = "lista", v = c("rec_partido", "gasto"), g = gs, anos = list(anos_rec)),
  expand_grid(base = "disputa", v = c("pcv", "cadeira", "tcv", "tel"), g = gs,
              anos = list(anos_longos)),
  expand_grid(base = "disputa", v = c("inv", "inv_c", "inv_nc", "excesso", "pcg", "tcg"),
              g = gs, anos = list(anos_rec)),
  tibble(base = "disputa", v = c("tcv_br", "tel_br", "tcv_hb", "tel_hb"),
         g = c("negra", "negra", "mulher_negra", "mulher_negra"), anos = list(anos_longos)),
  tibble(base = "disputa", v = c("tcg_br", "tcg_hb"), g = c("negra", "mulher_negra"),
         anos = list(anos_rec)),
  # mecanismo (sem wild bootstrap): partes competitivas × não competitivas e origem da receita.
  # rtpriv (receita privada: falsificação, com wild bootstrap) ocupa a posição do antigo
  # rto, e as categorias novas de 2026-11-24 vêm depois: como o set.seed é único, as
  # linhas anteriores reproduzem exatamente as réplicas da rodada de 22/11.
  expand_grid(base = "lista", v = c("voto_c", "voto_nc"), g = gs, anos = list(anos_longos)),
  expand_grid(base = "lista", v = c("gasto_c", "gasto_nc", "recp_c", "recp_nc", "rtp", "rtpriv"),
              g = gs, anos = list(anos_rec)),
  # robustez da H2 (transferências do partido + FEFC/FP repassados por outras candidaturas)
  # e as demais partes da receita total (somam rec_total com rtp e rtpriv)
  expand_grid(base = "lista", v = c("rec_partido_ampla", "rtc_pub", "rtc_priv", "rtres"),
              g = gs, anos = list(anos_rec))) |>
  mutate(wild = !str_detect(v, "_c$|_nc$|^rt(p|c_pub|c_priv|res)$") | v %in% c("inv_c", "inv_nc"))

t0 <- Sys.time()
res <- pmap(grade, function(base, v, g, anos, wild) {
  dados <- if (base == "lista") listas else disputas
  estimar(dados, paste0(v, "_", g), anos, base, wild) |> mutate(medida = v, grupo = g, .after = 1)
}) |> list_rbind()
message("Estimação: ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
write_excel_csv2(res, file.path(out_dir, "variaveis_principais_resultados.csv"))

# ------------------------------------------------------------------------------
# 3. Níveis por cargo (mesmas unidades balanceadas da estimação)
# ------------------------------------------------------------------------------
niveis <- pmap(grade, function(base, v, g, anos, wild) {
  y <- paste0(v, "_", g)
  dados <- if (base == "lista") listas else disputas
  dados |> filter(ano %in% anos, !is.na(.data[[y]])) |>
    filter(n() == length(anos), .by = id) |>
    summarise(media = mean(.data[[y]]), unidades = n(), .by = c(federal, ano)) |>
    mutate(variavel = y, medida = v, grupo = g, nivel = base, .before = 1)
}) |> list_rbind() |>
  mutate(cargo = if_else(federal, "Federal", "Estadual")) |>
  arrange(variavel, cargo, ano)
write_excel_csv2(niveis, file.path(out_dir, "variaveis_principais_niveis.csv"))

# Transferências do partido por cargo e nos dois cargos somados (totais nacionais, sem DF):
# mostra a realocação do dinheiro das mulheres entre os cargos (plano 22/11, H2)
transf <- map(gs, \(g) {
  d <- cand |> filter(ano >= 2018L) |> mutate(gr = .data[[g]])
  por_cargo <- d |> summarise(cand = 100 * mean(gr),
                              transf = 100 * sum(rp[gr]) / sum(rp),
                              transf_mi = sum(rp) / 1e6, .by = c(ano, federal)) |>
    mutate(cargo = if_else(federal, "Federal", "Estadual")) |> select(-federal)
  total <- d |> summarise(cand = 100 * mean(gr), transf = 100 * sum(rp[gr]) / sum(rp),
                         transf_mi = sum(rp) / 1e6, .by = ano) |>
    mutate(cargo = "Dois cargos")
  bind_rows(por_cargo, total) |> mutate(grupo = g, .before = 1)
}) |> list_rbind() |>
  arrange(grupo, cargo, ano)
write_excel_csv2(transf, file.path(out_dir, "transferencias_por_cargo.csv"))

# Conferência: o ATT de cada ano é a diferença das variações médias dos dois cargos
conf_niveis <- niveis |>
  select(variavel, cargo, ano, media) |>
  pivot_wider(names_from = cargo, values_from = media) |>
  mutate(dif = Federal - Estadual) |>
  mutate(att_niveis = dif - dif[ano == 2018L], .by = variavel) |>
  filter(ano != 2018L) |>
  inner_join(res |> filter(periodo %in% c("2014", "2022", "2026")) |>
               transmute(variavel, ano = as.integer(periodo), att), by = c("variavel", "ano"))
stopifnot(all(abs(conf_niveis$att_niveis - conf_niveis$att) < 1e-8))

# ------------------------------------------------------------------------------
# 4. Novo × antigo (mesmas variáveis com a construção anterior)
# ------------------------------------------------------------------------------
le <- \(f) read_csv2(f, show_col_types = FALSE, locale = locale(decimal_mark = ","))
antigo_03 <- le(file.path(out_dir, "did_2026_resultados.csv")) |>
  filter(!ponderado, balanceado,
         (nivel == "lista" & medida %in% c("cand", "voto", "rec_partido", "gasto", "voto_c", "voto_nc",
                                           "gasto_c", "gasto_nc", "recp_c", "recp_nc",
                                           "rtp")) |
         (nivel == "disputa" & medida %in% c("cmshare", "cadeira"))) |>
  mutate(medida = if_else(medida == "cmshare", "pcv", medida),
         grupo = str_extract(resultado, "(mulher_negra|mulher|negra)$"),
         periodo = if_else(periodo == "Média 2022–2026", "Federal × Pós", periodo)) |>
  transmute(medida, grupo, periodo, att_antigo = att, ep_antigo = ep)
mapa_comp <- c("Mulheres − homens" = "mulher", "Pessoas negras − brancas" = "negra",
               "Mulheres negras − homens brancos" = "mulher_negra")
ce <- "explorations/competitividade-eleitoral/output"
antigo_ddd <- bind_rows(
  read_csv(file.path(ce, "ddd_resultados.csv"), show_col_types = FALSE) |>
    filter(amostra == "Todas as UFs"),
  read_csv(file.path(ce, "ddd_gasto_resultados.csv"), show_col_types = FALSE)) |>
  filter(!ponderado, desfecho %in% c("ate_010", "eleita", "a_010")) |>
  mutate(grupo = unname(mapa_comp[comparacao]),
         base = recode(desfecho, ate_010 = "tcv", eleita = "tel", a_010 = "tcg"),
         # a comparação antiga de negras e mulheres negras corresponde às linhas _br e _hb
         medida = case_when(grupo == "negra" ~ paste0(base, "_br"),
                            grupo == "mulher_negra" ~ paste0(base, "_hb"), .default = base),
         periodo = case_when(termo == "Dif. 2026 − 2022" ~ "Dif. 2026 − 2022",
                             !is.na(ano) ~ as.character(ano), .default = termo)) |>
  filter(periodo %in% c("2014", "2022", "2026", "Dif. 2026 − 2022")) |>
  transmute(medida, grupo, periodo, att_antigo = att, ep_antigo = ep)

comparacao <- res |>
  select(medida, grupo, periodo, att, ep, ic_inf, ic_sup, p_wild, n_unidades) |>
  left_join(bind_rows(antigo_03, antigo_ddd), by = c("medida", "grupo", "periodo")) |>
  mutate(sig_novo = sign(ic_inf) == sign(ic_sup),
         sig_antigo = abs(att_antigo / ep_antigo) > qnorm(.975),
         mudou_sig = sig_novo != sig_antigo, dif_att = att - att_antigo)
write_excel_csv2(comparacao, file.path(out_dir, "variaveis_principais_comparacao.csv"))

# Pontos que devem coincidir com o antigo (mesma construção e mesma amostra)
iguais <- comparacao |> filter(!is.na(att_antigo), periodo != "Dif. 2026 − 2022")
message("ATT novo × antigo, |dif| máx.: ", signif(max(abs(iguais$dif_att)), 3),
        " em ", nrow(iguais), " comparações")
message("Mudança de significância (IC 95%):")
print(as.data.frame(comparacao |> filter(mudou_sig %in% TRUE) |>
                      select(medida, grupo, periodo, att, ep, ep_antigo, p_wild)))
