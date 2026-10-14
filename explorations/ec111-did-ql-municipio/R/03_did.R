# ==============================================================================
# Script: 03_did.R
# Purpose: DiD da EC 111/2021 na geografia do voto — tratado: Dep. Federal a partir
#          de 2022; controle: Dep. Estadual do mesmo partido no mesmo município.
#          Resultado principal: entrada em território novo, decomposta por grupo:
#            ATT(nova_base) = ATT(nova_base_g) + ATT(nova_base_nao_g)
#          e a parcela do avanço que veio de g = ATT(nova_base_g) / ATT(nova_base).
# Estimadores: did::att_gt (base universal 2018, nunca tratados, bootstrap
#          multiplicador com bandas uniformes, cluster na lista partido × UF × cargo);
#          TWFE equivalente; TWFE com efeitos fixos partido × município × ano.
# Inputs:  output/dados/painel_municipio.rds, painel_listas.rds (02_painel.R)
# Outputs: output/resultados_did.csv, output/parcela_g.csv,
#          output/resultados_twfe.csv, output/heterogeneidade.csv,
#          output/benchmark_listas.csv, output/dados/did_objetos.rds
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ec111-did-ql-municipio/R/03_did.R
# ==============================================================================

library(tidyverse)
library(did)
library(fixest)

source("explorations/ec111-did-ql-municipio/R/funcoes.R")   # anos_did
set.seed(20261014)
out_dir   <- file.path("explorations", "ec111-did-ql-municipio", "output")
dados_dir <- file.path(out_dir, "dados")
biters    <- as.integer(Sys.getenv("EC111_BITERS", "1000"))   # 25.000 na versão final

painel <- readRDS(file.path(dados_dir, "painel_municipio.rds"))

# Resultados em pontos percentuais (probabilidade × 100)
res_principais <- c("nova_base", "nova_base_mulher", "nova_base_nao_mulher",
                    "nova_base_negra", "nova_base_nao_negra")
res_secundarios <- c("base_mulher", "base_negra", "base_mulher_livre", "base_mulher_sobrep",
                     "base_negra_livre", "base_negra_sobrep")
painel <- painel |>
  mutate(across(all_of(c(res_principais, res_secundarios)), \(x) 100 * x))

# ==============================================================================
# 1. ESTIMAÇÃO
# ==============================================================================

#' Estima att_gt e agregações para um resultado
#'
#' @param dados Painel (uma linha por unidade × ano).
#' @param y Nome do resultado.
#' @param peso Nome da variável de peso (ou NULL).
#' @return lista com att_gt, aggte dinâmico e de grupo.
estimar_did <- function(dados, y, peso = NULL) {
  dados <- dados |> filter(!is.na(.data[[y]]))
  # did exige painel balanceado na variável de resultado
  dados <- dados |> filter(n() == length(anos_did), .by = id)
  gt <- att_gt(yname = y, tname = "ano", idname = "id", gname = "gname",
               data = dados, control_group = "nevertreated", base_period = "universal",
               panel = TRUE, weightsname = peso, clustervars = "lista_id",
               bstrap = TRUE, cband = TRUE, biters = biters, est_method = "reg",
               print_details = FALSE)
  list(gt = gt,
       din = aggte(gt, type = "dynamic", bstrap = TRUE, cband = TRUE, biters = biters,
                   na.rm = TRUE),
       grp = aggte(gt, type = "group", bstrap = TRUE, cband = TRUE, biters = biters,
                   na.rm = TRUE),
       n_unid = n_distinct(dados$id), n_listas = n_distinct(dados$lista_id),
       media_pre = mean(dados[[y]][dados$federal == 1L & dados$ano == 2018L]))
}

#' Tabela arrumada de um objeto de estimar_did()
arrumar <- function(est, y, espec) {
  d <- est$din
  # e = ano − 2022: −8 = 2014 (pré-teste), −4 = 2018 (referência, ATT ≡ 0)
  ano_e <- c(`-8` = "2014 (pré)", `0` = "2022", `4` = "2026")
  bind_rows(
    tibble(termo = unname(ano_e[as.character(d$egt)]), att = d$att.egt, ep = d$se.egt,
           crit = d$crit.val.egt),
    tibble(termo = "média 2022–2026", att = est$grp$overall.att, ep = est$grp$overall.se,
           crit = qnorm(0.975))
  ) |>
    filter(!is.na(termo), termo != "2018") |>
    mutate(resultado = y, especificacao = espec,
           ic_inf = att - crit * ep, ic_sup = att + crit * ep,
           media_federal_2018 = est$media_pre, unidades = est$n_unid, listas = est$n_listas,
           .before = 1)
}

# EC111_REUSAR=1 reaproveita os att_gt já estimados (o bootstrap é a parte lenta)
arq_ests <- file.path(dados_dir, "did_objetos.rds")
if (Sys.getenv("EC111_REUSAR") == "1" && file.exists(arq_ests)) {
  ests <- readRDS(arq_ests)
} else {
  ests <- list()
  for (y in c(res_principais, res_secundarios)) {
    message("att_gt: ", y)
    ests[[paste0(y, "|principal")]] <- estimar_did(painel, y)
  }
  # Ponderado pelos votos do partido no município em 2018 (efeito "por eleitor")
  painel_peso <- painel |> filter(peso_2018 > 0)
  for (y in res_principais) {
    message("att_gt ponderado: ", y)
    ests[[paste0(y, "|ponderado")]] <- estimar_did(painel_peso, y, peso = "peso_2018")
  }
  saveRDS(ests, arq_ests)
}

resultados <- imap(ests, \(e, k) arrumar(e, str_remove(k, "\\|.*"), str_remove(k, ".*\\|"))) |>
  list_rbind()
write_csv(resultados, file.path(out_dir, "resultados_did.csv"))
print(resultados |> filter(especificacao == "principal", resultado %in% res_principais) |>
        select(resultado, termo, att, ep, ic_inf, ic_sup), n = Inf)

# ==============================================================================
# 2. PARCELA DO AVANÇO QUE VEIO DE g — regressão empilhada + método delta
#    Os dois resultados (g e total) entram num só modelo, com efeitos fixos e
#    coeficientes próprios por resultado; o cluster na lista dá a covariância
#    conjunta das estimativas, necessária para o EP da razão. Os coeficientes são
#    idênticos aos de cada TWFE separado, e portanto ao att_gt (checado abaixo).
#    (As funções de influência do did não foram usadas: o did guarda as unidades
#    numa ordem interna diferente da do id, o que desalinha o cluster.)
# ==============================================================================

#' Parcela ATT(g) / ATT(total) por termo, com EP pelo método delta
#'
#' @param y_g Resultado do grupo (ex.: "nova_base_mulher").
#' @param rotulo Nome do grupo.
#' @return tibble termo × parcela, EP e IC 95%.
parcela_g <- function(y_g, rotulo) {
  emp <- bind_rows(painel |> transmute(id, ano, lista_id, federal, k = "g", y = .data[[y_g]]),
                   painel |> transmute(id, ano, lista_id, federal, k = "t", y = nova_base)) |>
    mutate(fed_g = federal * (k == "g"), fed_t = federal * (k == "t"))
  f <- feols(y ~ i(ano, fed_g, ref = 2018) + i(ano, fed_t, ref = 2018) | id^k + ano^k,
             data = emp, cluster = ~lista_id)
  b <- coef(f); V <- vcov(f)
  nm <- \(a, s) sprintf("ano::%d:fed_%s", a, s)
  termos <- list(`2022` = 2022L, `2026` = 2026L, `média 2022–2026` = c(2022L, 2026L))
  imap(termos, function(anos, rot) {
    w <- rep(1 / length(anos), length(anos))
    ig <- nm(anos, "g"); it <- nm(anos, "t")
    a <- sum(w * b[ig]); t <- sum(w * b[it]); s <- a / t
    # gradiente da razão a/t: ∂s/∂b_g = w/t ; ∂s/∂b_t = −a·w/t²
    grad <- setNames(c(w / t, -a * w / t^2), c(ig, it))
    ep <- sqrt(drop(t(grad) %*% V[names(grad), names(grad)] %*% grad))
    tibble(grupo = rotulo, termo = rot, att_g = a, att_total = t, parcela = s, ep = ep,
           ic_inf = s - 1.96 * ep, ic_sup = s + 1.96 * ep)
  }) |> list_rbind()
}

parcelas <- bind_rows(parcela_g("nova_base_mulher", "mulheres"),
                      parcela_g("nova_base_negra", "pessoas negras"))
# Os ATTs da regressão empilhada têm de coincidir com os do att_gt
chk_emp <- parcelas |>
  filter(termo != "média 2022–2026") |>
  left_join(resultados |> filter(especificacao == "principal", resultado == "nova_base") |>
              select(termo, att_did = att), by = "termo")
stopifnot(max(abs(chk_emp$att_total - chk_emp$att_did)) < 1e-6)
# Referência descritiva: parcela das bases novas que já era de g no federal em 2018
ref <- painel |> filter(federal == 1L, ano == 2018L) |>
  summarise(mulheres = sum(nova_base_mulher) / sum(nova_base),
            `pessoas negras` = sum(nova_base_negra) / sum(nova_base)) |>
  pivot_longer(everything(), names_to = "grupo", values_to = "parcela_federal_2018")
parcelas <- left_join(parcelas, ref, by = "grupo")
write_csv(parcelas, file.path(out_dir, "parcela_g.csv"))
print(parcelas)

# ==============================================================================
# 3. TWFE: equivalência e efeitos fixos partido × município × ano
# ==============================================================================

twfe <- map(res_principais, function(y) {
  f1 <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + ano")),
              data = painel, cluster = ~lista_id)
  f2 <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + pt^ano")),
              data = painel, cluster = ~lista_id)
  bind_rows(
    broom::tidy(f1) |> mutate(especificacao = "TWFE (id + ano)"),
    broom::tidy(f2) |> mutate(especificacao = "TWFE (id + partido×município×ano)")
  ) |> mutate(resultado = y, .before = 1)
}) |> list_rbind() |>
  mutate(termo = str_extract(term, "20\\d\\d"))
write_csv(twfe, file.path(out_dir, "resultados_twfe.csv"))

# Sem covariáveis e com um grupo tratado, att_gt = TWFE (id + ano)
cmp <- twfe |> filter(especificacao == "TWFE (id + ano)") |>
  inner_join(resultados |> filter(especificacao == "principal", !str_detect(termo, "média")) |>
               mutate(termo = str_extract(termo, "20\\d\\d")),
             by = c("resultado", "termo"))
message("Máx. |att_gt − TWFE| = ", signif(max(abs(cmp$estimate - cmp$att)), 3))
stopifnot(max(abs(cmp$estimate - cmp$att)) < 1e-6)
print(twfe |> select(resultado, especificacao, termo, estimate, std.error), n = Inf)

# ==============================================================================
# 4. HETEROGENEIDADE POR PORTE DO MUNICÍPIO
#    Tercis dos votos nominais para Dep. Federal no município em 2010 — anterior a
#    toda a janela do DiD e fora da série do resultado. (Um corte por "o partido
#    tinha base em 2018" foi descartado: 2018 é o período de referência e o
#    subgrupo fica mecanicamente ligado ao resultado — reversão à média, com
#    pré-testes de −3,9 e +9,3 p.p.) Pergunta: o avanço se concentra em municípios
#    pequenos, onde formar base é "barato" (a crítica de Calzavara ao município)?
# ==============================================================================

porte <- readRDS(file.path(dados_dir, "cand_territorio_municipio.rds")) |>
  filter(ano == 2010L, cargo == "Federal") |>
  distinct(SG_UF, terr, W_terr) |>
  mutate(porte = cut(W_terr, quantile(W_terr, c(0, 1/3, 2/3, 1)), include.lowest = TRUE,
                     labels = c("pequeno (1º tercil)", "médio (2º tercil)",
                                "grande (3º tercil)")))
painel_h <- painel |> left_join(select(porte, SG_UF, terr, porte), by = c("SG_UF", "terr"))
stopifnot(!anyNA(painel_h$porte))
heter <- map(levels(porte$porte), function(h) {
  sub <- filter(painel_h, porte == h)
  map(c("nova_base", "nova_base_mulher", "nova_base_negra"), \(y) arrumar(estimar_did(sub, y), y, h)) |>
    list_rbind()
}) |> list_rbind()
write_csv(heter, file.path(out_dir, "heterogeneidade.csv"))

# ==============================================================================
# 5. BENCHMARK MECÂNICO (nível da lista): bases novas de g por candidatura de g
# ==============================================================================

listas <- readRDS(file.path(dados_dir, "painel_listas.rds")) |>
  filter(ano %in% anos_did)
bench <- map(c("n_cand_mulher", "n_cand_negra", "n_nova_base_mulher", "n_nova_base_negra",
               "nova_por_cand_mulher", "nova_por_cand_negra"), function(y) {
  d <- listas |> filter(!is.na(.data[[y]])) |> filter(n() == length(anos_did), .by = lista_id)
  f <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | lista_id + ano")),
             data = d, cluster = ~lista_id)
  broom::tidy(f) |> mutate(resultado = y, listas = n_distinct(d$lista_id),
                           media_federal_2018 = mean(d[[y]][d$federal == 1L & d$ano == 2018L]),
                           .before = 1)
}) |> list_rbind() |> mutate(termo = str_extract(term, "20\\d\\d"))
write_csv(bench, file.path(out_dir, "benchmark_listas.csv"))
print(bench |> select(resultado, termo, estimate, std.error, media_federal_2018), n = Inf)

saveRDS(ests, file.path(dados_dir, "did_objetos.rds"))
message("Resultados em ", out_dir)
