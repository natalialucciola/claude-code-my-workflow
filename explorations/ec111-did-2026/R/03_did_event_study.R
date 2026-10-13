# ==============================================================================
# DiD da EC 111/2021 com dois períodos pós-tratamento (2022 e 2026)
#
# Desenho 2×T, adoção única: tratado = Deputado Federal a partir de 2022
# (gname = 2022); controle = Deputado Estadual (nunca tratado, gname = 0).
# did::att_gt com base_period = "universal" (2018 = referência fixa):
#   ATT(2022) = Δ(2018→2022) federal − Δ(2018→2022) estadual
#   ATT(2026) = Δ(2018→2026) federal − Δ(2018→2026) estadual  (efeito acumulado)
#   pseudo-ATT(2014) = pré-teste (só resultados com 2014)
#   aggte(type = "group") = média de ATT(2022) e ATT(2026) → efeito médio pós
# Por que não uma 2×2 de 2022 para 2026: ela mede ATT(2026) − ATT(2022) (pós contra
# pós), a mudança do efeito, não o efeito (Callaway & Sant'Anna 2021; Roth 2024).
#
# Os períodos são recodificados para 1..T (eleições a cada 4 anos).
# Checagens: TWFE com i(ano, federal, ref = 2018) reproduz cada ATT (sem
# covariáveis, um só grupo tratado, painel balanceado); diferença < 1e-6.
#
# Sensibilidade: HonestDiD não instala neste R (4.2.3; dependência CVXR). Em seu
# lugar, o CONJUNTO IDENTIFICADO sob magnitudes relativas (Rambachan & Roth 2023):
# a violação de tendência em cada intervalo de 4 anos depois de 2018 é no máximo
# M̄ × |pseudo-ATT(2014)|; logo o viés acumulado é ≤ k · M̄ · |β_2014| (k = 1 em
# 2022, 2 em 2026). IC aproximado = conjunto ± 1,96 EP (ignora a incerteza de
# β_2014 — não é a inferência de RR). M̄* = menor M̄ que faz o IC incluir 0.
#
# Rodar da raiz, depois de 02_painel_listas.R:
#   Rscript explorations/ec111-did-2026/R/03_did_event_study.R
# Saídas: output/did_2026_resultados.csv, did_2026_sensibilidade_rm.csv,
#         did_2026_*.png/pdf; data/processed/did_2026_att_gt.rds
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
library(tidyverse)
library(did)
library(fixest)

set.seed(20261013)
out_dir <- "explorations/ec111-did-2026/output"
biters  <- 1000L                      # exploração; 25000 para a versão final

painel   <- readRDS("data/processed/painel_listas_2014_2026.rds")
disputas <- readRDS("data/processed/painel_disputas_2014_2026.rds")

anos_longos <- c(2014L, 2018L, 2022L, 2026L)
anos_rec    <- c(2018L, 2022L, 2026L)      # 2014 não serve de referência para recursos
grupos <- c(mulher = "Mulheres", negra = "Pessoas negras", todos = "Todas as candidaturas")
rotulo_y <- c(cand = "1. Candidaturas (% da lista)", gasto = "2. Gasto (% do gasto da lista)",
              rec_partido = "3. Recursos do partido (% das transferências)",
              rec_publico = "3b. Recursos públicos FEFC + FP (% da lista)",
              rec_total = "3c. Todas as receitas (% da lista)",
              voto = "4a. Votos (% dos votos nominais da lista)",
              compet = "4b. Competitivas (% das candidaturas da lista)",
              compshare = "4c. Parcela do grupo entre as competitivas da lista",
              eleita = "5. Eleitas (% das candidaturas da lista)",
              cadeira = "5b. Cadeiras (% dos eleitos da UF)")

# ------------------------------------------------------------------------------
# 1. Estimação
# ------------------------------------------------------------------------------
#' DiD 2×T para um resultado: ATT dinâmico, média pós, pré-teste e checagem TWFE
#' @param dados painel longo (id, ano, federal, gname, uf, peso)
#' @param y nome do resultado; @param anos eleições usadas; @param ponderado peso = votos 2018
#' @param balanceado FALSE → allow_unbalanced_panel (estimador de cortes repetidos)
estimar <- function(dados, y, anos, ponderado = FALSE, balanceado = TRUE, nivel = "lista") {
  d <- dados |> filter(ano %in% anos, !is.na(.data[[y]]))
  if (balanceado) d <- d |> filter(n() == length(anos), .by = id)
  d <- d |> mutate(t = match(ano, anos), g = if_else(federal, match(2022L, anos), 0L))
  a <- att_gt(yname = y, tname = "t", idname = "id", gname = "g", data = d,
              panel = TRUE, allow_unbalanced_panel = !balanceado,
              control_group = "nevertreated", base_period = "universal", est_method = "dr",
              weightsname = if (ponderado) "peso" else NULL,
              bstrap = TRUE, cband = TRUE, biters = biters, clustervars = "id",
              print_details = FALSE)
  es <- aggte(a, type = "dynamic", bstrap = TRUE, cband = TRUE, biters = biters)
  gr <- aggte(a, type = "group", bstrap = TRUE, cband = TRUE, biters = biters)
  ano_e <- anos[match(2022L, anos) + es$egt]
  din <- tibble(periodo = as.character(ano_e), att = es$att.egt, ep = es$se.egt,
                crit = es$crit.val.egt) |>
    filter(periodo != "2018")                                   # referência (≡ 0)
  res <- bind_rows(din, tibble(periodo = "Média 2022–2026", att = gr$overall.att,
                               ep = gr$overall.se, crit = qnorm(.975))) |>
    mutate(ic_inf = att - qnorm(.975) * ep, ic_sup = att + qnorm(.975) * ep,
           ic_unif_inf = att - crit * ep, ic_unif_sup = att + crit * ep)
  b <- d |> filter(federal, ano == 2018L)
  base_2018 <- if (ponderado) weighted.mean(b[[y]], b$peso) else mean(b[[y]])
  wald <- if (is.null(a$Wpval)) NA_real_ else as.numeric(a$Wpval)[1]
  out <- res |>
    mutate(resultado = y, nivel = nivel, ponderado = ponderado, balanceado = balanceado,
           anos = paste(range(anos), collapse = "–"), n_unidades = n_distinct(d$id),
           base_federal_2018 = base_2018, wald_p_pre = wald, .before = 1)
  if (balanceado) {
    tw <- feols(as.formula(paste(y, "~ i(ano, federal, ref = 2018) | id + ano")), data = d,
                weights = if (ponderado) ~peso else NULL, cluster = ~id)
    tw_uf <- summary(tw, cluster = ~uf)
    cf <- coef(tw); nm <- str_extract(names(cf), "\\d{4}")
    out <- out |>
      mutate(twfe = unname(cf[match(periodo, nm)]),
             ep_twfe_uf = unname(se(tw_uf)[match(periodo, nm)]))
    chk <- out |> filter(!is.na(twfe))
    stopifnot(all(abs(chk$att - chk$twfe) < 1e-6))   # did = TWFE: sem erro de código
  }
  list(res = out, att_gt = a)
}

grade <- bind_rows(
  expand_grid(dados = "lista", y = c("cand", "voto", "compet", "eleita", "compshare"),
              g = c("mulher", "negra"), anos = list(anos_longos), ponderado = c(FALSE, TRUE),
              balanceado = TRUE),
  expand_grid(dados = "lista", y = c("cand", "voto", "compet", "eleita"), g = c("mulher", "negra"),
              anos = list(anos_longos), ponderado = FALSE, balanceado = FALSE),
  expand_grid(dados = "lista", y = c("compet", "eleita"), g = "todos", anos = list(anos_longos),
              ponderado = FALSE, balanceado = TRUE),
  expand_grid(dados = "lista", y = c("gasto", "rec_partido", "rec_publico", "rec_total"),
              g = c("mulher", "negra"), anos = list(anos_rec), ponderado = c(FALSE, TRUE),
              balanceado = TRUE),
  expand_grid(dados = "disputa", y = c("cadeira", "cand", "voto", "compet"),
              g = c("mulher", "negra"), anos = list(anos_longos), ponderado = FALSE,
              balanceado = TRUE)
)
fits <- pmap(grade, function(dados, y, g, anos, ponderado, balanceado) {
  base <- if (dados == "lista") painel else disputas
  estimar(base, paste0(y, "_", g), anos, ponderado, balanceado, nivel = dados)
})
saveRDS(map(fits, "att_gt"), "data/processed/did_2026_att_gt.rds")

res <- map(fits, "res") |> list_rbind() |>
  mutate(grupo = unname(grupos[str_extract(resultado, "(mulher|negra|todos)$")]),
         medida = str_remove(resultado, "_(mulher|negra|todos)$"),
         rotulo = rotulo_y[if_else(nivel == "disputa" & medida != "cadeira",
                                   paste0(medida), medida)],
         rotulo = if_else(nivel == "disputa" & medida != "cadeira",
                          paste0(rotulo, " — nível UF"), rotulo))
write_excel_csv2(res, file.path(out_dir, "did_2026_resultados.csv"))

# Replicação da etapa anterior (2018→2022, painel de 2 eleições): votos das mulheres
rep22 <- estimar(painel, "voto_mulher", c(2018L, 2022L))$res |> filter(periodo == "2022")
message(sprintf("Replicação 2018→2022, voto_mulher: %.2f pp (etapa anterior: +5,2; listas: %d)",
                rep22$att, rep22$n_unidades))

# ------------------------------------------------------------------------------
# 2. Sensibilidade: conjunto identificado sob magnitudes relativas (aproximação)
# ------------------------------------------------------------------------------
rm_sens <- res |>
  filter(balanceado, anos == "2014–2026") |>
  mutate(pre = att[periodo == "2014"], .by = c(resultado, nivel, ponderado)) |>
  filter(periodo %in% c("2022", "2026")) |>
  mutate(k = if_else(periodo == "2022", 1, 2)) |>
  cross_join(tibble(Mbar = c(0.5, 1, 2))) |>
  mutate(vies_max = k * Mbar * abs(pre),
         ic_rm_inf = att - vies_max - qnorm(.975) * ep,
         ic_rm_sup = att + vies_max + qnorm(.975) * ep,
         Mbar_breakdown = pmax(0, (abs(att) - qnorm(.975) * ep) / (k * abs(pre)))) |>
  select(resultado, nivel, ponderado, periodo, att, ep, pre, Mbar, vies_max, ic_rm_inf,
         ic_rm_sup, Mbar_breakdown)
write_excel_csv2(rm_sens, file.path(out_dir, "did_2026_sensibilidade_rm.csv"))

# ------------------------------------------------------------------------------
# 3. Figuras (não ponderado, painel balanceado)
# ------------------------------------------------------------------------------
cores_gr <- c("Mulheres" = "#eb6834", "Pessoas negras" = "#2a78d6")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}
fonte <- paste0("Fonte: TSE. DiD (Callaway & Sant'Anna, pacote did): Deputado Federal (EC 111) × Estadual, ",
                "base fixa 2018; listas partido × UF balanceadas, sem DF.\nBarra fina: IC 95% uniforme ",
                "(bootstrap, EP agrupados por lista); barra grossa: IC 95% pontual. ",
                "2026: recursos e gasto da prestação parcial (TSE, 13/10/2026).")

evento <- function(d, titulo, subtitulo, nome, ncol, h) {
  d <- d |>
    filter(periodo != "Média 2022–2026") |>
    bind_rows(d |> distinct(resultado, nivel, rotulo, grupo) |>
                mutate(periodo = "2018", att = 0, ic_inf = 0, ic_sup = 0, ic_unif_inf = 0,
                       ic_unif_sup = 0)) |>
    mutate(ano = as.integer(periodo))
  p <- ggplot(d, aes(x = ano, y = att, colour = grupo)) +
    annotate("rect", xmin = 2020, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
    geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
    geom_linerange(aes(ymin = ic_unif_inf, ymax = ic_unif_sup),
                   position = position_dodge(width = 1.2), linewidth = 0.4) +
    geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), position = position_dodge(width = 1.2),
                   linewidth = 1.1) +
    geom_point(position = position_dodge(width = 1.2), size = 1.8) +
    facet_wrap(~rotulo, ncol = ncol, scales = "free_y") +
    scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
    scale_colour_manual(values = cores_gr, name = NULL) +
    labs(title = titulo, subtitle = subtitulo, x = NULL,
         y = "Efeito estimado (pontos percentuais)", caption = fonte) + tema
  salvar(p, nome, 10, h)
}
base_fig <- res |> filter(!ponderado, balanceado, grupo != grupos[["todos"]])
evento(base_fig |> filter(nivel == "lista", anos == "2014–2026"),
       "EC 111: candidaturas, votos, competitividade e sucesso — federal × estadual",
       paste("Diferença em relação a 2018 no federal menos a mesma diferença no estadual.",
             "2014 = pré-teste; área cinza = depois da EC 111."),
       "did_2026_evento_candidaturas_votos", 2, 7)
evento(base_fig |> filter(nivel == "lista", anos == "2018–2026"),
       "EC 111: gasto e recursos — federal × estadual",
       paste("Diferença em relação a 2018. Sem pré-teste (2014 tinha doação empresarial).",
             "2026 PROVISÓRIO: prestação de contas parcial."),
       "did_2026_evento_recursos", 2, 7)
evento(base_fig |> filter(nivel == "disputa"),
       "EC 111 no nível da disputa (UF × cargo): cadeiras, candidaturas, votos e competitivas",
       "26 UFs × 2 cargos. Diferença em relação a 2018 no federal menos a do estadual.",
       "did_2026_evento_disputas", 2, 7)

message("DiD 2026: resultados em ", out_dir)
