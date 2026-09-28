# ==============================================================================
# DiD à la Fonseca, Thomé & Guedes-Neto (2026): efeito do incentivo da EC 111/2021
# (votos em mulheres e negras/os contam em dobro na distribuição de FEFC/FP — só
# Deputado Federal) sobre (a) a alocação de recursos em candidaturas viáveis e
# (b) os votos por faixa de competitividade pelo gasto.
#
# Unidade: lista = partido (siglas de 2018 harmonizadas para 2022) × UF × cargo.
# Tratado: Deputado Federal; controle: Deputado Estadual (mesma UF). Períodos 2018 e
# 2022 → Callaway & Sant'Anna com 2 períodos = DiD 2×2 (sem teste de pré-tendência:
# 2014 não serve de referência para recursos — fim da doação empresarial em 2015).
# Painel balanceado de listas.
#
# Resultados (pontos percentuais; g = mulheres ou negras/os):
#   Recursos (f = total: todas as receitas; publico: FEFC + Fundo Partidário de
#   qualquer origem; partido: transferências do partido):
#              rec_f_g          % dos recursos f da lista destinados a g
#              rec_viavel_f_g_m % dos recursos f da lista para g viáveis pela medida m
#              cand_viavel_g_m  % das candidaturas da lista que são g e viáveis por m
#   Votos:     voto_g           % dos votos da lista obtidos por g
#              voto_g_m_b       % dos votos da lista obtidos por g na faixa b da medida m
#                               (Σ_b voto_g_m_b = voto_g → efeitos por faixa somam o total)
#
# Faixas são resultado (Y_b), não condição: o incentivo pode mover candidaturas
# entre faixas, e isso faz parte do efeito.
#
# Rodar da raiz, depois do script 05:
#   Rscript explorations/competitividade-gasto/R/06_did_recursos_votos.R
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
library(tidyverse)
library(did)
library(fixest)

set.seed(20260928)
out_dir <- "explorations/competitividade-gasto/output"
biters  <- 1000L

medidas <- c("m2", "m6", "m8")
rotulo_medida <- c(m2 = "% do limite legal", m6 = "Recursos do partido",
                   m8 = "÷ menor gasto dos eleitos")
viavel_rotulo <- c(m2 = "≥ 5% do limite", m6 = "≥ 1× a divisão igualitária",
                   m8 = "≥ 50% do menor gasto dos eleitos")

fontes <- c(total = "receita_total", publico = "receita_publica", partido = "receita_partido")
rotulo_fonte <- c(total = "Todas as receitas", publico = "Recursos públicos (FEFC + FP)",
                  partido = "Transferências do partido")

cand <- readRDS("data/processed/base_did_candidatos.rds")
faixas <- map(set_names(medidas), \(m) levels(cand[[paste0("faixa_", m)]]))

# ------------------------------------------------------------------------------
# 1. Painel de listas
# ------------------------------------------------------------------------------
pp <- \(num, den) if_else(den > 0, 100 * num / den, NA_real_)
resumir_lista <- function(d) {
  V <- sum(d$VOTOS_CAND_TOTAL); N <- nrow(d)
  out <- list(n_cand = N, votos_lista = V)
  for (g in c("mulher", "negra")) {
    gi <- d[[g]]
    out[[paste0("cand_", g)]] <- 100 * mean(gi)
    out[[paste0("voto_", g)]] <- pp(sum(d$VOTOS_CAND_TOTAL[gi]), V)
    for (f in names(fontes)) {
      x <- d[[fontes[[f]]]]
      out[[paste0("rec_", f, "_", g)]] <- pp(sum(x[gi]), sum(x))
      for (m in medidas) {
        out[[paste0("rec_viavel_", f, "_", g, "_", m)]] <- pp(sum(x[gi & d[[paste0("viavel_", m)]]]), sum(x))
      }
    }
    for (m in medidas) {
      vi <- d[[paste0("viavel_", m)]]
      out[[paste0("cand_viavel_", g, "_", m)]] <- 100 * mean(gi & vi)
      fx <- d[[paste0("faixa_", m)]]
      for (k in seq_along(faixas[[m]])) {
        out[[paste0("voto_", g, "_", m, "_b", k)]] <- pp(sum(d$VOTOS_CAND_TOTAL[gi & fx == faixas[[m]][k]]), V)
      }
    }
  }
  as_tibble(out)
}
painel <- cand |>
  nest(.by = c(ANO, DS_CARGO, uf, partido_lista)) |>
  mutate(res = map(data, resumir_lista)) |>
  select(-data) |>
  unnest(res) |>
  filter(votos_lista > 0) |>
  mutate(lista = paste(partido_lista, uf, DS_CARGO), .before = 1) |>
  filter(n_distinct(ANO) == 2, .by = lista) |>                  # painel balanceado
  mutate(id = as.integer(factor(lista)), ano = as.integer(ANO),
         federal = DS_CARGO == "Deputado Federal",
         gname = if_else(federal, 2022L, 0L),                   # nunca tratado = 0
         tratado_pos = as.integer(federal & ano == 2022L)) |>
  mutate(peso = votos_lista[ano == 2018L], .by = lista)         # peso fixo: votos da lista em 2018
saveRDS(painel, "data/processed/painel_listas_did.rds")
message("Painel: ", n_distinct(painel$id), " listas (", sum(painel$federal) / 2, " federais)")

# ------------------------------------------------------------------------------
# 2. Estimação: did::att_gt (DR; sem covariáveis = 2×2) + checagem TWFE
# ------------------------------------------------------------------------------
estimar <- function(y, ponderado = FALSE) {
  d <- painel |> filter(!is.na(.data[[y]])) |> filter(n() == 2, .by = id)
  a <- att_gt(yname = y, tname = "ano", idname = "id", gname = "gname", data = d,
              panel = TRUE, control_group = "nevertreated", est_method = "dr",
              weightsname = if (ponderado) "peso" else NULL,
              bstrap = TRUE, cband = TRUE, biters = biters, clustervars = "id",
              print_details = FALSE)
  g <- aggte(a, type = "group", bstrap = TRUE, cband = TRUE, biters = biters)
  tw <- feols(as.formula(paste(y, "~ tratado_pos | id + ano")), data = d, cluster = ~id,
              weights = if (ponderado) ~peso else NULL)
  tibble(resultado = y, ponderado = ponderado, att = g$overall.att, ep = g$overall.se,
         ic_inf = att - 1.96 * ep, ic_sup = att + 1.96 * ep,
         twfe = unname(coef(tw)["tratado_pos"]), n_listas = n_distinct(d$id),
         media_trat_2018 = mean(d[[y]][d$federal & d$ano == 2018L]))
}
ys <- names(painel) |> keep(\(n) str_detect(n, "^(rec_|cand_viavel_|voto_)"))
res <- map(c(FALSE, TRUE), \(w) map(ys, \(y) estimar(y, w)) |> list_rbind()) |> list_rbind()

# Checagens: DR sem covariáveis = TWFE 2×2; efeitos por faixa somam o efeito total
stopifnot(all(abs(res$att - res$twfe) < 1e-6))
soma <- res |>
  mutate(base = str_extract(resultado, "^voto_(mulher|negra)"),
         medida = str_extract(resultado, "m\\d(?=_b)")) |>
  filter(!is.na(medida)) |>
  summarise(soma = sum(twfe), .by = c(ponderado, base, medida)) |>
  left_join(res |> select(ponderado, base = resultado, total = twfe), by = c("ponderado", "base"))
stopifnot(all(abs(soma$soma - soma$total) < 1e-6))

res <- res |>
  mutate(grupo = if_else(str_detect(resultado, "mulher"), "Mulheres", "Negras/os"),
         medida = str_extract(resultado, "m\\d"),
         faixa_k = as.integer(str_extract(resultado, "(?<=_b)\\d")),
         faixa = map2_chr(medida, faixa_k, \(m, k) if (is.na(k)) NA_character_ else faixas[[m]][k]),
         fonte = str_match(resultado, "^rec_(?:viavel_)?(total|publico|partido)_")[, 2],
         tipo = case_when(str_detect(resultado, "^rec_viavel") ~ "Recursos para viáveis",
                          str_detect(resultado, "^rec_") ~ "Recursos (total)",
                          str_detect(resultado, "^cand_viavel") ~ "Candidaturas viáveis",
                          !is.na(faixa_k) ~ "Votos por faixa",
                          TRUE ~ "Votos (total)"))
write_excel_csv2(res, file.path(out_dir, "did_resultados.csv"))

# ------------------------------------------------------------------------------
# 3. Gráficos (não ponderado; ponderado no CSV)
# ------------------------------------------------------------------------------
cores_gr <- c("Mulheres" = "#eb6834", "Negras/os" = "#2a78d6")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
fonte <- paste0("Fonte: TSE. DiD 2×2 (Callaway & Sant'Anna, pacote did): Deputado Federal (tratado, EC 111) × ",
                "Estadual (controle), de 2018 para 2022;\nlistas partido × UF, painel balanceado, sem DF. ",
                "Barras: IC 95% (bootstrap, EP agrupados por lista).")
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}
coef_plot <- function(d, y, titulo, subtitulo, nome, h) {
  p <- ggplot(d, aes(x = att, y = .data[[y]], colour = grupo)) +
    geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
    geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), position = position_dodge(width = 0.55),
                    size = 0.35, linewidth = 0.6) +
    scale_colour_manual(values = cores_gr, name = NULL) +
    labs(title = titulo, subtitle = subtitulo, x = "Efeito estimado (pontos percentuais)", y = NULL,
         caption = fonte) + tema
  salvar(p, nome, 10, h)
}

# 3a. Efeito pretendido: parcela dos recursos (três fontes) para o grupo e para o grupo viável
d_rec <- res |>
  filter(!ponderado, tipo %in% c("Recursos (total)", "Recursos para viáveis")) |>
  mutate(rotulo = if_else(tipo == "Recursos (total)", "Para o grupo (todas as candidaturas)",
                          paste0("Para o grupo viável: ", viavel_rotulo[medida])),
         rotulo = fct_rev(fct_inorder(rotulo)),
         fonte = factor(rotulo_fonte[fonte], levels = rotulo_fonte))
p <- ggplot(d_rec, aes(x = att, y = rotulo, colour = grupo)) +
  geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), position = position_dodge(width = 0.55),
                  size = 0.35, linewidth = 0.6) +
  facet_wrap(~fonte, ncol = 1) +
  scale_colour_manual(values = cores_gr, name = NULL) +
  labs(title = "Efeito do incentivo da EC 111 sobre a parcela dos recursos da lista destinada ao grupo",
       subtitle = paste("Diferença-em-diferenças: variação de 2018 para 2022 no federal menos a variação",
                        "no estadual, por fonte de recursos."),
       x = "Efeito estimado (pontos percentuais)", y = NULL, caption = fonte) + tema
salvar(p, "did_recursos_viaveis", 10, 8)

# 3c. Candidaturas viáveis e votos (total)
d_cv <- res |>
  filter(!ponderado, tipo %in% c("Candidaturas viáveis", "Votos (total)")) |>
  mutate(rotulo = if_else(tipo == "Votos (total)", "% dos votos da lista obtidos pelo grupo",
                          paste0("% das candidaturas: grupo viável (", viavel_rotulo[medida], ")")),
         rotulo = fct_rev(fct_inorder(rotulo)))
coef_plot(d_cv, "rotulo",
          "Efeito do incentivo da EC 111 sobre candidaturas viáveis e votos",
          "Diferença-em-diferenças: variação de 2018 para 2022 no federal menos a variação no estadual.",
          "did_candidaturas_votos", 4.5)

# 3b. Votos por faixa de competitividade (análogo à Figura 3 de Fonseca et al.)
d_vot <- res |>
  filter(!ponderado, tipo == "Votos por faixa") |>
  mutate(faixa = factor(paste(medida, faixa), levels = unlist(imap(faixas, \(v, m) paste(m, v)))),
         medida = factor(rotulo_medida[medida], levels = rotulo_medida))
p <- ggplot(d_vot, aes(x = att, y = fct_rev(faixa), colour = grupo)) +
  geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), position = position_dodge(width = 0.55),
                  size = 0.35, linewidth = 0.6) +
  facet_wrap(~medida, ncol = 3, scales = "free_y") +
  scale_y_discrete(labels = \(x) sub("^m\\d ", "", x)) +
  scale_colour_manual(values = cores_gr, name = NULL) +
  labs(title = "Efeito do incentivo sobre os votos, por faixa de competitividade pelo gasto",
       subtitle = paste("Resultado: % dos votos da lista obtidos pelo grupo em cada faixa (as faixas somam o",
                        "efeito total). De baixo para cima: menos para mais competitiva."),
       x = "Efeito estimado (pontos percentuais)", y = NULL, caption = fonte) + tema
salvar(p, "did_votos_por_faixa", 11, 5.5)

message("DiD: resultados em ", out_dir)
