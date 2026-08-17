# ==============================================================================
# Modelo 2 (H6) + Alcance total (H7): tabelas e gráficos publication-ready
#
# Mesma convenção visual do 04_tabelas_graficos_consolidacao.R (paleta
# Okabe-Ito, coefficient plot com IC 95%, halo branco sobre marcas
# sobrepostas quando necessário — ver marks-and-anatomy da skill de dataviz).
#
# Pré-requisito: rodar R/01, R/03 e R/05 antes.
# ==============================================================================

library(tidyverse)
library(broom)
library(knitr)
library(kableExtra)

out_dir <- "explorations/base-territorial-partidos/output"

cor_feminino  <- "#E69F00"
cor_masculino <- "#0072B2"
cor_negra     <- "#009E73"
cor_branca    <- "#CC79A7"

tema_dumbbell <- theme_minimal(base_size = 12) +
  theme(
    strip.text            = element_text(face = "bold"),
    panel.grid.minor       = element_blank(),
    panel.grid.major.x     = element_blank(),
    legend.position        = "top",
    legend.justification   = "center",
    plot.caption           = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

sig_star <- function(p) case_when(
  p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "ns"
)

extrair_ddd <- function(modelo, termo, especificacao, grupo, modelo_label, scale = 100) {
  # scale = 100 para variáveis dependentes que são proporções (0-1) -> p.p.;
  # scale = 1 para variáveis já em sua unidade natural (ex.: nº de municípios,
  # em H7) -- multiplicar por 100 nesse caso produziria um número fabricado.
  tidy(modelo, conf.int = TRUE) |>
    filter(term == termo) |>
    transmute(
      modelo_label, grupo, especificacao,
      estimate_pp  = round(scale * estimate, 2),
      conf.low_pp  = round(scale * conf.low, 2),
      conf.high_pp = round(scale * conf.high, 2),
      p.value
    )
}

# ==============================================================================
# 1. TABELA COMPARATIVA — Modelo 1 (amplo) vs. Modelo 2 (incumbente)
# ==============================================================================

ddd_m1_genero <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
ddd_m1_raca   <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
ddd_m2_genero <- readRDS(file.path(out_dir, "ddd_modelo2_genero_incumbente.rds"))
ddd_m2_raca   <- readRDS(file.path(out_dir, "ddd_modelo2_raca_incumbente.rds"))

tab_comparativa <- bind_rows(
  extrair_ddd(ddd_m1_genero, "federal:ano2022:mulher", "Amostra completa", "Mulher", "Modelo 1 (amplo)"),
  extrair_ddd(ddd_m2_genero, "federal:ano2022:mulher", "Não incumbentes",  "Mulher", "Modelo 2 (incumbente)"),
  extrair_ddd(ddd_m1_raca,   "federal:ano2022:negra",  "Amostra completa", "Negra",  "Modelo 1 (amplo)"),
  extrair_ddd(ddd_m2_raca,   "federal:ano2022:negra",  "Não incumbentes",  "Negra",  "Modelo 2 (incumbente)")
) |>
  mutate(sig = sig_star(p.value))

kable(
  tab_comparativa,
  format    = "latex",
  booktabs  = TRUE,
  digits    = c(0, 0, 0, 1, 1, 1, 4, 0),
  col.names = c("Modelo", "Grupo", "Amostra", "Estimativa (p.p.)", "IC 95% inf.",
                "IC 95% sup.", "p-valor", "Sig."),
  caption   = "Tripla diferença (Federal x 2022 x Grupo) -- Modelo 1 (sobreposição com qualquer correligionário) vs. Modelo 2 (sobreposição especificamente com correligionário incumbente)",
  escape    = FALSE
) |>
  kable_styling(latex_options = c("hold_position", "striped")) |>
  save_kable(file.path(out_dir, "tabela_comparativa_modelo1_modelo2.tex"))

write_csv(tab_comparativa, file.path(out_dir, "tabela_comparativa_modelo1_modelo2.csv"))

message("Tabela comparativa Modelo 1 x Modelo 2 salva.")
print(tab_comparativa)

# ==============================================================================
# 2. GRÁFICO — coefficient plot comparativo
# ==============================================================================

plot_df <- tab_comparativa |>
  mutate(
    modelo_label = factor(modelo_label, levels = c("Modelo 2 (incumbente)", "Modelo 1 (amplo)")),
    grupo        = factor(grupo, levels = c("Negra", "Mulher"))
  )

g_comparativo <- ggplot(plot_df, aes(x = estimate_pp, y = modelo_label, color = grupo, shape = grupo)) +
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
    title = "Modelo 1 (amplo) vs. Modelo 2 (sobreposição com incumbente)",
    caption = "Barras: IC 95%. Linha tracejada: efeito nulo. Modelo 2 restrito a candidatos não\nincumbentes; Modelo 1 usa a amostra completa (ver Dados e Métodos)."
  ) +
  tema_dumbbell +
  theme(legend.position = "top")

ggsave(file.path(out_dir, "grafico_comparativo_modelo1_modelo2.pdf"), g_comparativo, width = 7.5, height = 4)
ggsave(file.path(out_dir, "grafico_comparativo_modelo1_modelo2.png"), g_comparativo, width = 7.5, height = 4, dpi = 300)

# ==============================================================================
# 3. H7 — ALCANCE TOTAL: tabela + gráfico
# ==============================================================================

ddd_alcance_genero <- readRDS(file.path(out_dir, "ddd_alcance_genero.rds"))
ddd_alcance_raca   <- readRDS(file.path(out_dir, "ddd_alcance_raca.rds"))

tab_alcance <- bind_rows(
  extrair_ddd(ddd_alcance_genero, "federal:ano2022:mulher", "Amostra completa", "Mulher", "Alcance total (H7)", scale = 1),
  extrair_ddd(ddd_alcance_raca,   "federal:ano2022:negra",  "Amostra completa", "Negra",  "Alcance total (H7)", scale = 1)
) |>
  mutate(sig = sig_star(p.value))

kable(
  tab_alcance,
  format    = "latex",
  booktabs  = TRUE,
  digits    = c(0, 0, 0, 2, 2, 2, 4, 0),
  col.names = c("Modelo", "Grupo", "Amostra", "Estimativa (nº municípios)", "IC 95% inf.",
                "IC 95% sup.", "p-valor", "Sig."),
  caption   = "Tripla diferença (Federal x 2022 x Grupo) sobre alcance territorial total (H7)",
  escape    = FALSE
) |>
  kable_styling(latex_options = c("hold_position", "striped")) |>
  save_kable(file.path(out_dir, "tabela_h7_alcance_total.tex"))

write_csv(tab_alcance, file.path(out_dir, "tabela_h7_alcance_total.csv"))
print(tab_alcance)

g_alcance <- ggplot(tab_alcance, aes(x = estimate_pp, y = grupo, color = grupo, shape = grupo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(xmin = conf.low_pp, xmax = conf.high_pp), width = 0.15, linewidth = 0.7) +
  geom_point(size = 3.5, stroke = 1.3) +
  scale_color_manual(values = c("Mulher" = cor_feminino, "Negra" = cor_negra), name = NULL, guide = "none") +
  scale_shape_manual(values = c("Mulher" = 16, "Negra" = 17), name = NULL, guide = "none") +
  labs(
    x = "Efeito da tripla interação (Federal x 2022 x Grupo), nº de municípios QL>1",
    y = NULL,
    title = "H7 -- Crescimento federal-específico\ndo alcance territorial total",
    caption = "Barras: IC 95%. Linha tracejada: efeito nulo."
  ) +
  tema_dumbbell

ggsave(file.path(out_dir, "grafico_h7_alcance_total.pdf"), g_alcance, width = 7, height = 3.6)
ggsave(file.path(out_dir, "grafico_h7_alcance_total.png"), g_alcance, width = 7, height = 3.6, dpi = 300)

message("\n=== Tabelas e gráficos do Modelo 2 (H6) + H7 salvos em ", out_dir, " ===")
