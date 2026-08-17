# ==============================================================================
# SUPERSEDED (2026-08-16) — ver nota em 07_versao_b_universo_completo.R.
# Não rodar como parte do pipeline atual.
# ==============================================================================

# ==============================================================================
# Gráfico: Versão A (partidos_sel) vs. Versão B (universo completo de partidos)
#
# Mesma convenção visual dos gráficos anteriores desta análise (Okabe-Ito,
# coefficient plot com IC 95%).
#
# Pré-requisito: rodar R/07_versao_b_universo_completo.R antes.
# ==============================================================================

library(tidyverse)
library(patchwork)

out_dir <- "explorations/base-territorial-partidos/output"

cor_feminino <- "#E69F00"
cor_negra    <- "#009E73"

tema_dumbbell <- theme_minimal(base_size = 12) +
  theme(
    strip.text            = element_text(face = "bold"),
    panel.grid.minor       = element_blank(),
    panel.grid.major.x     = element_blank(),
    legend.position        = "top",
    legend.justification   = "center",
    plot.caption           = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

tab <- read_csv(file.path(out_dir, "tabela_versaoA_vs_versaoB.csv"), show_col_types = FALSE) |>
  mutate(
    versao = factor(versao, levels = c("B (universo completo)", "A (partidos_sel)")),
    grupo  = factor(grupo, levels = c("Negra", "Mulher")),
    modelo_label = factor(modelo_label, levels = c("H5 (alcance)", "Modelo 2 (H4)", "Modelo 1 (H3)"))
  )

# ---- Painel 1: Modelo 1 (H3) e Modelo 2 (H4) — escala de pontos percentuais ----

tab_pp <- tab |> filter(modelo_label != "H5 (alcance)") |> droplevels() |>
  mutate(modelo_label = factor(modelo_label, levels = c("Modelo 2 (H4)", "Modelo 1 (H3)")))

g_pp <- ggplot(tab_pp, aes(x = estimate, y = versao, color = grupo, shape = grupo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high),
                width = 0.15, position = position_dodge(width = 0.4), linewidth = 0.7) +
  geom_point(size = 3.2, position = position_dodge(width = 0.4), stroke = 1.2) +
  facet_wrap(~ modelo_label, ncol = 1) +
  scale_color_manual(values = c("Mulher" = cor_feminino, "Negra" = cor_negra), name = NULL) +
  scale_shape_manual(values = c("Mulher" = 16, "Negra" = 17), name = NULL) +
  labs(x = "Tripla interação (Federal x 2022 x Grupo), pontos percentuais", y = NULL) +
  tema_dumbbell

# ---- Painel 2: H5 (alcance total) — escala de nº de municípios ----

tab_h5 <- tab |> filter(modelo_label == "H5 (alcance)") |> droplevels()

g_h5 <- ggplot(tab_h5, aes(x = estimate, y = versao, color = grupo, shape = grupo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high),
                width = 0.15, position = position_dodge(width = 0.4), linewidth = 0.7) +
  geom_point(size = 3.2, position = position_dodge(width = 0.4), stroke = 1.2) +
  facet_wrap(~ modelo_label, ncol = 1) +
  scale_color_manual(values = c("Mulher" = cor_feminino, "Negra" = cor_negra), name = NULL, guide = "none") +
  scale_shape_manual(values = c("Mulher" = 16, "Negra" = 17), name = NULL, guide = "none") +
  labs(x = "Tripla interação (Federal x 2022 x Grupo), nº de municípios", y = NULL) +
  tema_dumbbell

# NOTA: plot_annotation(theme=...) emite um warning benigno de incompatibilidade
# patchwork/ggplot2 4.0 (S7) nesta versão do pacote, mas title/caption renderizam
# corretamente (verificado visualmente) — por isso não usamos o operador `&`.
g_combinado <- (g_pp / g_h5) +
  plot_layout(heights = c(2, 1)) +
  plot_annotation(
    title = "Versão A (partidos_sel, N=8) vs. Versão B (universo completo, N=34 partidos)",
    caption = "Barras: IC 95%. Linha tracejada: efeito nulo. O efeito de raça no Modelo 1 (H3), robusto\nem partidos_sel, não se sustenta no universo completo de partidos.",
    theme = theme(plot.caption = element_text(hjust = 0, size = 8))
  )

ggsave(file.path(out_dir, "grafico_versaoA_vs_versaoB.pdf"), g_combinado, width = 7.5, height = 7.5)
ggsave(file.path(out_dir, "grafico_versaoA_vs_versaoB.png"), g_combinado, width = 7.5, height = 7.5, dpi = 300)

message("Gráfico Versão A vs. Versão B salvo em ", out_dir)
