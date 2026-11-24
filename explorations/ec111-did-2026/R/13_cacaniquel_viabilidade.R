# ==============================================================================
# 13 — Teste caça-níquel, item 1: para quem foi o acréscimo das transferências?
#      quality_reports/plans/2026-11-24_cap4-cacaniquel-item1-implementacao.md
#
# Decomposição, no nível da LISTA (decisão D1 da autora), da proporção das
# transferências do partido à lista que vai para o grupo g:
#   rec_partido_g = recp_v_g + recp_nv_g   (viáveis / não viáveis EX ANTE, R/12)
#                 = recp_c_g + recp_nc_g   (competitivas / não competitivas EX POST, R/02)
# Idem para o gasto (gasto_v/nv) e os votos (voto_v/nv). Robustez da classificação:
# só incumbentes (recp_v1/nv1) e V3 só no mesmo cargo (recp_vmc/nvmc).
#
# Coluna "esperado" (D4): quanto do efeito total a parte viável (ou competitiva)
# teria recebido se o acréscimo seguisse a divisão do federal em 2018:
#   s_2018   = média federal de 2018 de recp_v_g ÷ média federal de 2018 de rec_partido_g
#              (mesmas listas balanceadas da estimação)
#   esperado = s_2018 × ATT(rec_partido_g)
# Contrafactual contábil, sem erro-padrão.
#
# Mesmo estimador do R/10 (funcoes_estimacao.R): CS federal × estadual, base 2018,
# 2018–2026 (sem pré-teste: 2014 não tem recursos e a viabilidade de 2014 exigiria 2010),
# painel balanceado, EP por UF; wild bootstrap só em recp_v_g e recp_nv_g.
#
# Entradas: data/processed/painel_listas_2014_2026.rds, cand_ec111_2014_2026.rds (R/02),
#           viabilidade_ex_ante.rds (R/12); output/variaveis_principais_resultados.csv (R/10,
#           só conferência)
# Saídas (output/): cacaniquel_viabilidade.csv (ATTs), cacaniquel_viabilidade_esperado.csv,
#                   cacaniquel_viabilidade_niveis.csv
#
#   Rscript explorations/ec111-did-2026/R/13_cacaniquel_viabilidade.R
#   (BITERS=200 WILD=199 para testar; tese: BITERS=25000 WILD=1999, como o R/10)
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({library(tidyverse); library(did); library(fixest)})
source("explorations/ec111-did-2026/R/funcoes_estimacao.R")

set.seed(20261124)
out_dir <- "explorations/ec111-did-2026/output"
anos_rec <- c(2018L, 2022L, 2026L)
gs <- c("mulher", "negra", "mulher_negra")
pp <- \(num, den) if_else(den > 0, 100 * num / den, NA_real_)
tol <- 1e-8

# ------------------------------------------------------------------------------
# 1. Partes viáveis × não viáveis por lista (mesmas chaves e filtro do R/02)
# ------------------------------------------------------------------------------
viab <- readRDS("data/processed/viabilidade_ex_ante.rds")
cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO), sq_candidato = as.character(sq_candidato)) |>
  filter(ano >= 2018L) |>
  left_join(viab |> select(-pessoa), by = c("ANO", "DS_CARGO", "sq_candidato"))
stopifnot(!any(is.na(cand$viavel)))

partes <- function(d, v, sufixo) {
  # v: coluna lógica de viabilidade; sufixo: "" (principal), "1" (só V1), "mc"
  d |> mutate(.v = .data[[v]]) |>
    summarise(votos_lista = sum(VOTOS_CAND_TOTAL),
              across(c(mulher, negra, mulher_negra), list(
                recp_v  = \(g) pp(sum(receita_partido[g & .v]), sum(receita_partido)),
                recp_nv = \(g) pp(sum(receita_partido[g & !.v]), sum(receita_partido)),
                gasto_v  = \(g) pp(sum(gasto[g & .v]), sum(gasto)),
                gasto_nv = \(g) pp(sum(gasto[g & !.v]), sum(gasto)),
                voto_v  = \(g) pp(sum(VOTOS_CAND_TOTAL[g & .v]), sum(VOTOS_CAND_TOTAL)),
                voto_nv = \(g) pp(sum(VOTOS_CAND_TOTAL[g & !.v]), sum(VOTOS_CAND_TOTAL))),
                .names = "{.fn}_{.col}"),
              .by = c(ano, DS_CARGO, uf, partido_h)) |>
    filter(votos_lista > 0, !is.na(partido_h)) |>
    mutate(lista = paste(partido_h, uf, DS_CARGO)) |>
    select(ano, lista, matches("^(recp|gasto|voto)_n?v_")) |>
    rename_with(\(x) sub("^(recp|gasto|voto)_(n?v)_", paste0("\\1_\\2", sufixo, "_"), x),
                -c(ano, lista))
}
novas <- partes(cand, "viavel", "") |>
  left_join(partes(cand, "viavel_v1", "1") |> select(ano, lista, starts_with("recp_")),
            by = c("ano", "lista")) |>
  left_join(partes(cand, "viavel_mc", "mc") |> select(ano, lista, starts_with("recp_")),
            by = c("ano", "lista"))

listas <- readRDS("data/processed/painel_listas_2014_2026.rds") |>
  mutate(uf_id = as.integer(factor(uf))) |>
  select(ano, lista, id, uf, uf_id, federal, DS_CARGO,
         matches(paste0("^(rec_partido|recp_c|recp_nc|gasto|gasto_c|gasto_nc|voto)_(",
                        paste(gs, collapse = "|"), ")$")))
n_antes <- nrow(listas)
listas <- listas |> left_join(novas, by = c("ano", "lista"))
pos <- listas$ano >= 2018L
# toda lista de 2018–2026 recebe as partes novas (ausentes só onde o total é ausente)
stopifnot(nrow(listas) == n_antes,
          identical(is.na(listas$recp_v_mulher[pos]), is.na(listas$rec_partido_mulher[pos])))

# As partes somam o total em cada lista e ano
for (g in gs) for (v in c("", "1", "mc")) {
  tot <- listas[[paste0("rec_partido_", g)]]
  s <- listas[[paste0("recp_v", v, "_", g)]] + listas[[paste0("recp_nv", v, "_", g)]]
  stopifnot(identical(is.na(tot[pos]), is.na(s[pos])), all(abs(s - tot)[pos] < tol, na.rm = TRUE))
}
for (g in gs) for (m in c("gasto", "voto")) {
  tot <- listas[[paste0(m, "_", g)]][listas$ano >= 2018L]
  s <- (listas[[paste0(m, "_v_", g)]] + listas[[paste0(m, "_nv_", g)]])[listas$ano >= 2018L]
  stopifnot(all(is.na(tot) | abs(s - tot) < tol))
}

# ------------------------------------------------------------------------------
# 2. Estimação
# ------------------------------------------------------------------------------
grade <- bind_rows(
  # testes principais do item 1 (com wild bootstrap)
  expand_grid(v = c("recp_v", "recp_nv"), g = gs, wild = TRUE),
  # totais e partição ex post: conferência e base do 1a
  expand_grid(v = c("rec_partido", "recp_c", "recp_nc", "gasto", "voto"), g = gs, wild = FALSE),
  # mecanismo e robustez
  expand_grid(v = c("gasto_v", "gasto_nv", "voto_v", "voto_nv",
                    "recp_v1", "recp_nv1", "recp_vmc", "recp_nvmc"), g = gs, wild = FALSE))

t0 <- Sys.time()
res <- pmap(grade, function(v, g, wild) {
  estimar(listas, paste0(v, "_", g), anos_rec, "lista", wild) |>
    mutate(medida = v, grupo = g, .after = 1)
}) |> list_rbind()
message("Estimação: ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")

# Conferência 1: as partes somam o efeito total (ATT é linear na variável)
soma <- res |>
  mutate(total = case_when(str_starts(medida, "recp_") ~ "rec_partido",
                           str_starts(medida, "gasto_") ~ "gasto",
                           str_starts(medida, "voto_") ~ "voto"),
         particao = str_remove(medida, "^(recp|gasto|voto)_n?")) |>
  filter(!is.na(total)) |>
  summarise(att_soma = sum(att), n = n(), .by = c(total, particao, grupo, periodo)) |>
  inner_join(res |> select(total = medida, grupo, periodo, att_total = att),
             by = c("total", "grupo", "periodo"))
stopifnot(all(soma$n == 2L), all(abs(soma$att_soma - soma$att_total) < 1e-6))

# Conferência 2: rec_partido e recp_c/nc reproduzem o R/10 (mesma amostra)
r10 <- read_csv2(file.path(out_dir, "variaveis_principais_resultados.csv"), show_col_types = FALSE,
                 locale = locale(decimal_mark = ",")) |>
  # voto fica de fora: no R/10 usa o painel balanceado de 2014–2026 (outra amostra)
  filter(nivel == "lista", medida %in% c("rec_partido", "recp_c", "recp_nc", "gasto")) |>
  select(medida, grupo, periodo, att_r10 = att)
conf_r10 <- res |> inner_join(r10, by = c("medida", "grupo", "periodo"))
stopifnot(nrow(conf_r10) > 0, all(abs(conf_r10$att - conf_r10$att_r10) < 1e-6))
message("ATTs que reproduzem o R/10: ", nrow(conf_r10))

write_excel_csv2(res, file.path(out_dir, "cacaniquel_viabilidade.csv"))

# ------------------------------------------------------------------------------
# 3. Níveis por cargo e "esperado se o acréscimo seguisse a divisão de 2018"
# ------------------------------------------------------------------------------
niveis <- pmap(grade, function(v, g, wild) {
  y <- paste0(v, "_", g)
  listas |> filter(ano %in% anos_rec, !is.na(.data[[y]])) |>
    filter(n() == length(anos_rec), .by = id) |>
    summarise(media = mean(.data[[y]]), unidades = n(), .by = c(federal, ano)) |>
    mutate(variavel = y, medida = v, grupo = g, .before = 1)
}) |> list_rbind() |>
  mutate(cargo = if_else(federal, "Federal", "Estadual")) |>
  arrange(variavel, cargo, ano)
write_excel_csv2(niveis, file.path(out_dir, "cacaniquel_viabilidade_niveis.csv"))

# Conferência 3: ATT de cada ano = diferença das variações médias dos dois cargos
conf_niveis <- niveis |>
  select(variavel, cargo, ano, media) |>
  pivot_wider(names_from = cargo, values_from = media) |>
  mutate(dif = Federal - Estadual) |>
  mutate(att_niveis = dif - dif[ano == 2018L], .by = variavel) |>
  filter(ano != 2018L) |>
  inner_join(res |> filter(periodo %in% c("2022", "2026")) |>
               transmute(variavel, ano = as.integer(periodo), att), by = c("variavel", "ano"))
stopifnot(all(abs(conf_niveis$att_niveis - conf_niveis$att) < tol))

nivel_fed18 <- niveis |> filter(federal, ano == 2018L) |> select(medida, grupo, media)
particoes <- tibble(parte = c("recp_c", "recp_v", "recp_v1", "recp_vmc"),
                    particao = c("Competitivas ex post", "Viáveis ex ante",
                                 "Viáveis ex ante: só incumbentes",
                                 "Viáveis ex ante: V3 no mesmo cargo"))
esperado <- particoes |>
  cross_join(tibble(grupo = gs)) |>
  left_join(nivel_fed18 |> rename(parte = medida, nivel_parte_2018 = media), by = c("parte", "grupo")) |>
  left_join(nivel_fed18 |> filter(medida == "rec_partido") |>
              select(grupo, nivel_total_2018 = media), by = "grupo") |>
  mutate(s_2018 = nivel_parte_2018 / nivel_total_2018) |>
  inner_join(res |> filter(medida == "rec_partido") |>
               select(grupo, periodo, att_total = att), by = "grupo",
             relationship = "many-to-many") |>
  left_join(res |> select(parte = medida, grupo, periodo, att_parte = att, ic_inf, ic_sup, p_wild),
            by = c("parte", "grupo", "periodo")) |>
  mutate(esperado = s_2018 * att_total, observado_menos_esperado = att_parte - esperado) |>
  select(particao, parte, grupo, periodo, nivel_total_2018, nivel_parte_2018, s_2018,
         att_total, esperado, att_parte, ic_inf, ic_sup, p_wild, observado_menos_esperado) |>
  arrange(particao, grupo, periodo)
write_excel_csv2(esperado, file.path(out_dir, "cacaniquel_viabilidade_esperado.csv"))

message("Parte viável / competitiva: observado × esperado pela divisão de 2018 (p.p.):")
print(as.data.frame(esperado |> filter(periodo %in% c("2022", "2026")) |>
                      select(particao, grupo, periodo, s_2018, att_total, esperado, att_parte,
                             ic_inf, ic_sup, p_wild) |>
                      mutate(across(where(is.double), \(x) round(x, 2)))))
