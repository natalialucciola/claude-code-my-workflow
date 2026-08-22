# ==============================================================================
# Modelo 3 (liderança formal do partido): tabela e gráfico comparativos de 3
# modelos (Modelo 1 amplo / Modelo 2 incumbente / Modelo 3 líder do partido).
#
# Mesma convenção visual de R/06_tabelas_graficos_modelo2.R (paleta Okabe-Ito,
# coefficient plot com IC 95%).
#
# Modelos 1/2/3 são triangulação de um único estimando (efeito da tripla
# interação Federal x 2022 x Grupo) sob amostras/definições de proteção de
# liderança cada vez mais restritas — não uma família de hipóteses
# independentes testadas simultaneamente (ver Issue 17 da revisão de código).
#
# Autora: Natália Lucciola
# Entradas: ddd_modelo_genero.rds, ddd_modelo_raca.rds,
#   ddd_modelo2_genero_incumbente.rds, ddd_modelo2_raca_incumbente.rds,
#   ddd_modelo3_genero_lideranca.rds, ddd_modelo3_raca_lideranca.rds
#   (todos em output/; produzidos por R/01_overlap_partido.R,
#   R/03_ddd_incentivo_2022.R, R/05_modelo2_incumbente.R,
#   R/07_titulo_eleitoral_2018_2022.R, R/08_lideranca_partido.R e
#   R/09_modelo3_lideranca.R).
# Saídas: tabela_comparativa_modelo1_modelo2_modelo3.tex/.csv/.rds,
#   grafico_comparativo_modelo1_modelo2_modelo3.pdf/.png/.rds (em output/).
#
# Pré-requisito: rodar R/01_overlap_partido.R, R/03_ddd_incentivo_2022.R,
# R/05_modelo2_incumbente.R, R/07_titulo_eleitoral_2018_2022.R,
# R/08_lideranca_partido.R e R/09_modelo3_lideranca.R antes.
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Setup
# ------------------------------------------------------------------------------

library(tidyverse)
library(broom)
library(knitr)
library(kableExtra)
library(fixest)

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# cor_masculino/cor_branca mantidas por consistência de paleta com
# R/06_tabelas_graficos_modelo2.R (mesmo conjunto Okabe-Ito), embora só
# "Mulher"/"Negra" apareçam no gráfico deste script (scale_*_manual abaixo).
cor_feminino  <- "#E69F00"
cor_masculino <- "#0072B2"
cor_negra     <- "#009E73"
cor_branca    <- "#CC79A7"

# base_size = 12 (não o default de 14 do projeto, ver r-code-conventions.md):
# figura de contexto exclusivamente do livro Quarto (não reutilizada em
# Beamer), com legenda + eixo compartilhando espaço horizontal reduzido.
tema_dumbbell <- theme_minimal(base_size = 12) +
  theme(
    strip.text            = element_text(face = "bold"),
    panel.grid.minor       = element_blank(),
    panel.grid.major.x     = element_blank(),
    legend.position        = "top",
    legend.justification   = "center",
    plot.caption           = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

#' Converte um p-valor em asteriscos de significância convencionais
#'
#' @param p Numeric vector de p-valores.
#' @return Character vector: "***" (p<0.001), "**" (p<0.01), "*" (p<0.05),
#'   "ns" caso contrário.
sig_star <- function(p) case_when(
  p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "ns"
)

#' Extrai a linha de um termo de um modelo `fixest`/`lm` para a tabela comparativa
#'
#' Usa `broom::tidy()` para obter estimativa e IC 95%, filtra pelo termo de
#' interesse e reescala (por padrão, x100 -> pontos percentuais).
#'
#' @param modelo Objeto de modelo suportado por `broom::tidy()` (aqui, um
#'   `fixest` retornado por `feols()`).
#' @param termo Character: nome exato do termo na tabela de coeficientes
#'   (ex.: `"federal:ano2022:mulher"`).
#' @param especificacao Character: rótulo da amostra/especificação (ex.:
#'   "Não líderes").
#' @param grupo Character: rótulo do grupo comparado (ex.: "Mulher").
#' @param modelo_label Character: rótulo do modelo (ex.: "Modelo 3 (líder
#'   do partido)").
#' @param scale Numeric: fator de escala aplicado à estimativa e ao IC
#'   (default 100, converte para pontos percentuais).
#' @return Uma tibble de 1 linha com `modelo_label`, `grupo`, `especificacao`,
#'   `estimate_pp`, `conf.low_pp`, `conf.high_pp`, `p.value`.
extrair_ddd <- function(modelo, termo, especificacao, grupo, modelo_label, scale = 100) {
  resultado <- tidy(modelo, conf.int = TRUE) |>
    filter(term == termo)

  # Falha alto e claro em vez de silenciosamente descartar a linha em
  # bind_rows() — um termo com 0 ou >1 matches produziria uma tabela de tese
  # incompleta sem qualquer aviso (Issue 4 da revisão de código).
  stopifnot(
    "extrair_ddd(): termo nao encontrado (ou duplicado) na tabela de coeficientes" =
      nrow(resultado) == 1L
  )

  resultado |>
    transmute(
      modelo_label, grupo, especificacao,
      estimate_pp  = round(scale * estimate, 2),
      conf.low_pp  = round(scale * conf.low, 2),
      conf.high_pp = round(scale * conf.high, 2),
      p.value
    )
}

# ==============================================================================
# 1. TABELA COMPARATIVA — Modelo 1 (amplo) vs. Modelo 2 (incumbente) vs.
#    Modelo 3 (líder do partido)
# ==============================================================================

ddd_m1_genero <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
ddd_m1_raca   <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
ddd_m2_genero <- readRDS(file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
ddd_m2_raca   <- readRDS(file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))
ddd_m3_genero <- readRDS(file.path(out_dir, "ddd_modelo3_genero_lideranca.rds"))
ddd_m3_raca   <- readRDS(file.path(out_dir, "ddd_modelo3_raca_lideranca.rds"))

tab_comparativa <- bind_rows(
  extrair_ddd(
    ddd_m1_genero, "federal:ano2022:mulher", "Amostra completa", "Mulher", "Modelo 1 (amplo)"
  ),
  extrair_ddd(
    ddd_m2_genero, "federal:ano2022:mulher", "Não incumbentes", "Mulher", "Modelo 2 (incumbente)"
  ),
  extrair_ddd(
    ddd_m3_genero, "federal:ano2022:mulher", "Não líderes", "Mulher", "Modelo 3 (líder do partido)"
  ),
  extrair_ddd(
    ddd_m1_raca, "federal:ano2022:negra", "Amostra completa", "Negra", "Modelo 1 (amplo)"
  ),
  extrair_ddd(
    ddd_m2_raca, "federal:ano2022:negra", "Não incumbentes", "Negra", "Modelo 2 (incumbente)"
  ),
  extrair_ddd(
    ddd_m3_raca, "federal:ano2022:negra", "Não líderes", "Negra", "Modelo 3 (líder do partido)"
  )
) |>
  mutate(sig = sig_star(p.value))

kable(
  tab_comparativa,
  format    = "latex",
  booktabs  = TRUE,
  digits    = c(0, 0, 0, 1, 1, 1, 4, 0),
  col.names = c("Modelo", "Grupo", "Amostra", "Estimativa (p.p.)", "IC 95% inf.",
                "IC 95% sup.", "p-valor", "Sig."),
  caption   = paste0(
    "Tripla diferença (Federal x 2022 x Grupo) -- Modelo 1 (qualquer correligionário) vs. ",
    "Modelo 2 (correligionário incumbente) vs. Modelo 3 (correligionário líder formal do partido)"
  ),
  escape    = FALSE
) |>
  kable_styling(latex_options = c("hold_position", "striped")) |>
  save_kable(file.path(out_dir, "tabela_comparativa_modelo1_modelo2_modelo3.tex"))

write_csv(tab_comparativa, file.path(out_dir, "tabela_comparativa_modelo1_modelo2_modelo3.csv"))
saveRDS(tab_comparativa, file.path(out_dir, "tabela_comparativa_modelo1_modelo2_modelo3.rds"))

message(
  "Tabela comparativa Modelo 1 x Modelo 2 x Modelo 3 salva (", nrow(tab_comparativa), " linhas)."
)

# ==============================================================================
# 2. GRÁFICO — coefficient plot comparativo, 3 modelos
# ==============================================================================

plot_df <- tab_comparativa |>
  mutate(
    modelo_label = factor(modelo_label, levels = c(
      "Modelo 3 (líder do partido)", "Modelo 2 (incumbente)", "Modelo 1 (amplo)"
    )),
    grupo        = factor(grupo, levels = c("Negra", "Mulher"))
  )

g_comparativo <- ggplot(
  plot_df,
  aes(x = estimate_pp, y = modelo_label, color = grupo, shape = grupo)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(
    aes(xmin = conf.low_pp, xmax = conf.high_pp),
    width = 0.15, position = position_dodge(width = 0.4), linewidth = 0.7
  ) +
  geom_point(size = 3.5, position = position_dodge(width = 0.4), stroke = 1.3) +
  scale_color_manual(values = c("Mulher" = cor_feminino, "Negra" = cor_negra), name = NULL) +
  scale_shape_manual(values = c("Mulher" = 16, "Negra" = 17), name = NULL) +
  labs(
    x = "Efeito da tripla interação (Federal x 2022 x Grupo), pontos percentuais",
    y = NULL,
    title = "Modelo 1 (amplo) vs. Modelo 2 (incumbente) vs. Modelo 3 (líder do partido)",
    caption = paste0(
      "Barras: IC 95%. Linha tracejada: efeito nulo. Modelos 2 e 3 restritos a candidatos\n",
      "não incumbentes / não líderes, respectivamente; Modelo 1 usa a amostra completa\n",
      "(ver Dados e Métodos)."
    )
  ) +
  tema_dumbbell +
  theme(legend.position = "top")

# Fundo branco explícito: figura de uso exclusivo do livro Quarto (não
# reaproveitada em Beamer, onde bg = "transparent" seria necessário — ver
# INV-11).
ggsave(
  file.path(out_dir, "grafico_comparativo_modelo1_modelo2_modelo3.pdf"),
  g_comparativo, width = 7.5, height = 4.6, bg = "white"
)
ggsave(
  file.path(out_dir, "grafico_comparativo_modelo1_modelo2_modelo3.png"),
  g_comparativo, width = 7.5, height = 4.6, dpi = 300, bg = "white"
)
saveRDS(g_comparativo, file.path(out_dir, "grafico_comparativo_modelo1_modelo2_modelo3_ggplot.rds"))

message("Tabela e grafico comparativos (3 modelos) salvos em ", out_dir)
