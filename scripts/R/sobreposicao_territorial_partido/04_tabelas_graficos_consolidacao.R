# ==============================================================================
# Consolidação: tabela final + gráficos publication-ready
#
# Autora: Natalia Lucciola
#
# Convenção visual seguida (mesma do resto da tese, ver
# explorations/base-territorial-partidos/SESSION_LOG.md do projeto de análise
# original): dumbbell por categoria, círculo aberto = 2018, círculo
# preenchido = 2022, cor por grupo. Aqui a forma (não só a cor) também
# distingue o grupo (Feminino/Masculino, Negra/Branca), para o gráfico
# continuar legível em preto e branco / impressão.
#
# Paleta: Okabe-Ito (Wong, Nature Methods 2011) — padrão revisado por pares
# para segurança a daltonismo. Não foi possível rodar o validador da skill de
# dataviz (Node.js ausente nesta máquina); Okabe-Ito é a referência mais usada
# em publicações científicas, então optei por ela em vez de arriscar cores
# não verificadas.
#
# Pré-requisito: rodar R/01, R/02 e R/03 antes (usa os .rds salvos em output/).
#
# Inputs:
#   1. tab_taxa_sobreposicao_genero.rds
#   2. tab_taxa_sobreposicao_raca.rds
#   3. teste_t_genero.rds
#   4. teste_t_raca.rds
#   5. ddd_modelo_genero.rds
#   6. ddd_modelo_genero_incumbencia.rds
#   7. ddd_modelo_raca.rds
#   8. ddd_modelo_raca_incumbencia.rds
#
# Outputs:
#   1. tabela_consolidada_r1.tex
#   2. tabela_consolidada_r1.csv
#   3. tabela_consolidada_r1.rds
#   4. tabela_consolidada_ddd.tex
#   5. tabela_consolidada_ddd.csv
#   6. tabela_consolidada_ddd.rds
#   7. grafico_sobreposicao_genero.{pdf,png}
#   8. grafico_sobreposicao_raca.{pdf,png}
#   9. grafico_ddd_coeficientes.{pdf,png}
# ==============================================================================

# 0. SETUP
# ------------------------------------------------------------------------------

library(tidyverse)
library(broom)
library(fixest)
library(knitr)
library(kableExtra)

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Okabe-Ito
cor_feminino  <- "#E69F00"  # laranja
cor_masculino <- "#0072B2"  # azul
cor_negra     <- "#009E73"  # verde-azulado
cor_branca    <- "#CC79A7"  # roxo-avermelhado

tema_dumbbell <- theme_minimal(base_size = 12) +
  theme(
    strip.text            = element_text(face = "bold"),
    panel.grid.minor       = element_blank(),
    panel.grid.major.x     = element_blank(),
    legend.position        = "top",
    legend.justification   = "center",
    plot.caption           = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

# ==============================================================================
# 1. TABELA CONSOLIDADA — 1o round (cargo x ano) + DDD (principal e +incumbência)
# ==============================================================================

tab_genero_r1 <- readRDS(file.path(out_dir, "tab_taxa_sobreposicao_genero.rds"))
tab_raca_r1   <- readRDS(file.path(out_dir, "tab_taxa_sobreposicao_raca.rds"))
teste_genero  <- readRDS(file.path(out_dir, "teste_t_genero.rds"))
teste_raca    <- readRDS(file.path(out_dir, "teste_t_raca.rds"))

#' Rotula um p-valor com estrelas de significância convencionais
#'
#' @param p Vetor numérico de p-valores.
#' @return Vetor character com "***" (p<0.001), "**" (p<0.01), "*" (p<0.05)
#'   ou "ns" (não significante).
sig_star <- function(p) case_when(
  p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "ns"
)

tab_r1_consolidada <- bind_rows(
  tab_genero_r1 |>
    left_join(teste_genero, by = c("cargo", "ANO_ELEICAO"), relationship = "one-to-one") |>
    mutate(
      grupo    = "Gênero",
      cat_alta = "Feminino",
      cat_ref  = "Masculino",
      taxa_alta = taxa_media_pct_FEMININO,
      taxa_ref  = taxa_media_pct_MASCULINO
    ),
  tab_raca_r1 |>
    left_join(teste_raca, by = c("cargo", "ANO_ELEICAO"), relationship = "one-to-one") |>
    mutate(
      grupo    = "Raça",
      cat_alta = "Negra",
      cat_ref  = "Branca",
      taxa_alta = taxa_media_pct_NEGRA,
      taxa_ref  = taxa_media_pct_BRANCA
    )
) |>
  mutate(sig = sig_star(p.value)) |>
  select(grupo, cargo, ANO_ELEICAO, taxa_alta, taxa_ref, gap_pp, p.value, sig) |>
  arrange(grupo, cargo, ANO_ELEICAO)

kable(
  tab_r1_consolidada,
  format    = "latex",
  booktabs  = TRUE,
  digits    = c(0, 0, 0, 1, 1, 1, 4, 0),
  col.names = c("Grupo", "Cargo", "Ano", "Taxa (grupo)", "Taxa (ref.)",
                "Gap (p.p.)", "p-valor", "Sig."),
  caption   = "Taxa de sobreposição territorial por cargo, ano, gênero e raça",
  escape    = FALSE
) |>
  kable_styling(latex_options = c("hold_position", "striped")) |>
  save_kable(file.path(out_dir, "tabela_consolidada_r1.tex"))

write_csv(tab_r1_consolidada, file.path(out_dir, "tabela_consolidada_r1.csv"))
saveRDS(tab_r1_consolidada, file.path(out_dir, "tabela_consolidada_r1.rds"))

# ---- DDD ----

#' Extrai a estimativa da tripla interação de um modelo fixest
#'
#' @param modelo Objeto `fixest` (via `feols()`/`feglm()`) já estimado.
#' @param termo Nome exato do termo de interação a extrair (ex.:
#'   "federal:ano2022:mulher").
#' @param especificacao Rótulo da especificação, usado só para identificar
#'   a linha na tabela final (ex. "Principal (sem controles)").
#' @param grupo Rótulo do grupo, usado só para identificar a linha na
#'   tabela final (ex. "Mulher", "Negra").
#' @return Uma tibble de 1 linha com estimativa, IC 95% (em pontos
#'   percentuais) e p-valor do termo solicitado.
#' @details Verifica via `stopifnot()` que `termo` casa com exatamente uma
#'   linha — evita que um termo mal escrito derrube silenciosamente uma
#'   linha inteira da tabela consolidada.
extrair_ddd <- function(modelo, termo, especificacao, grupo) {
  resultado <- tidy(modelo, conf.int = TRUE) |>
    filter(term == termo)

  stopifnot(nrow(resultado) == 1)

  resultado |>
    transmute(
      grupo, especificacao,
      estimate_pp = round(100 * estimate, 1),
      conf.low_pp = round(100 * conf.low, 1),
      conf.high_pp = round(100 * conf.high, 1),
      p.value
    )
}

ddd_genero_principal    <- readRDS(file.path(out_dir, "ddd_modelo_genero.rds"))
ddd_genero_incumbencia  <- readRDS(file.path(out_dir, "ddd_modelo_genero_incumbencia.rds"))
ddd_raca_principal      <- readRDS(file.path(out_dir, "ddd_modelo_raca.rds"))
ddd_raca_incumbencia    <- readRDS(file.path(out_dir, "ddd_modelo_raca_incumbencia.rds"))

tab_ddd_consolidada <- bind_rows(
  extrair_ddd(
    ddd_genero_principal, "federal:ano2022:mulher",
    "Principal (sem controles)", "Mulher"
  ),
  extrair_ddd(
    ddd_genero_incumbencia, "federal:ano2022:mulher",
    "+ Incumbência", "Mulher"
  ),
  extrair_ddd(
    ddd_raca_principal, "federal:ano2022:negra",
    "Principal (sem controles)", "Negra"
  ),
  extrair_ddd(
    ddd_raca_incumbencia, "federal:ano2022:negra",
    "+ Incumbência", "Negra"
  )
) |>
  mutate(sig = sig_star(p.value))

kable(
  tab_ddd_consolidada,
  format    = "latex",
  booktabs  = TRUE,
  digits    = c(0, 0, 1, 1, 1, 4, 0),
  col.names = c("Grupo", "Especificação", "Estimativa (p.p.)", "IC 95% inf.",
                "IC 95% sup.", "p-valor", "Sig."),
  caption   = paste0(
    "Tripla diferença (Federal x 2022 x Grupo) — efeito federal-específico ",
    "na queda de sobreposição territorial"
  ),
  escape    = FALSE
) |>
  kable_styling(latex_options = c("hold_position", "striped")) |>
  save_kable(file.path(out_dir, "tabela_consolidada_ddd.tex"))

write_csv(tab_ddd_consolidada, file.path(out_dir, "tabela_consolidada_ddd.csv"))
saveRDS(tab_ddd_consolidada, file.path(out_dir, "tabela_consolidada_ddd.rds"))

message(
  "Tabelas consolidadas salvas: tabela_consolidada_r1.{tex,csv,rds}, ",
  "tabela_consolidada_ddd.{tex,csv,rds}"
)

# ==============================================================================
# 2. GRÁFICO — dumbbell, taxa de sobreposição por cargo x gênero x ano
# ==============================================================================

plot_genero_df <- tab_genero_r1 |>
  select(cargo, ANO_ELEICAO, taxa_media_pct_FEMININO, taxa_media_pct_MASCULINO) |>
  pivot_longer(
    cols = starts_with("taxa_media_pct_"),
    names_to = "genero", values_to = "taxa_pct",
    names_prefix = "taxa_media_pct_"
  ) |>
  mutate(
    genero = str_to_title(genero),
    ano_shape = factor(ANO_ELEICAO, levels = c("2018", "2022"))
  ) |>
  # garante que 2022 (preenchido) desenhe por cima de 2018 quando os
  # valores quase coincidem
  arrange(cargo, genero, ano_shape)

dodge_w <- position_dodge(0.35)

g_genero <- ggplot(
  plot_genero_df,
  aes(x = cargo, y = taxa_pct, color = genero, group = interaction(cargo, genero))
) +
  geom_line(position = dodge_w, linewidth = 0.6, alpha = 0.6) +
  # Camada 1: círculo aberto de 2018.
  geom_point(
    data = \(d) filter(d, ano_shape == "2018"),
    aes(shape = ano_shape, size = ano_shape),
    stroke = 1.1, position = dodge_w
  ) +
  # Camada 2: halo branco na posição de 2022 — quando 2018/2022 quase
  # coincidem (ex. Federal/Negra: 77,4% vs 77,7%), "apaga" a parte do círculo
  # de 2018 que ficaria colada ao de 2022, criando um anel de vazio limpo
  # entre as duas marcas (ver skill de dataviz, marks-and-anatomy: "surface
  # gap/ring sobre marcas sobrepostas") em vez de deixá-las se fundir.
  geom_point(
    data = \(d) filter(d, ano_shape == "2022"),
    size = 5.4, shape = 16, color = "white", position = dodge_w
  ) +
  # Camada 3: círculo preenchido de 2022, por cima do halo.
  geom_point(
    data = \(d) filter(d, ano_shape == "2022"),
    aes(shape = ano_shape, size = ano_shape),
    stroke = 1.1, position = dodge_w
  ) +
  scale_color_manual(
    values = c("Feminino" = cor_feminino, "Masculino" = cor_masculino), name = "Gênero"
  ) +
  scale_shape_manual(values = c("2018" = 1, "2022" = 16), name = "Ano") +
  scale_size_manual(values = c("2018" = 3.5, "2022" = 4.2), guide = "none") +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(
    x = NULL, y = "Taxa de sobreposição territorial",
    title = "Sobreposição territorial por gênero, cargo e ano",
    caption = paste0(
      "Círculo aberto = 2018; círculo preenchido = 2022.\n",
      "Cor: laranja = Feminino, azul = Masculino (paleta Okabe-Ito)."
    )
  ) +
  tema_dumbbell

ggsave(file.path(out_dir, "grafico_sobreposicao_genero.pdf"), g_genero, width = 6, height = 4.5)
ggsave(
  file.path(out_dir, "grafico_sobreposicao_genero.png"), g_genero,
  width = 6, height = 4.5, dpi = 300
)

# ==============================================================================
# 3. GRÁFICO — dumbbell, taxa de sobreposição por cargo x raça x ano
# ==============================================================================

plot_raca_df <- tab_raca_r1 |>
  select(cargo, ANO_ELEICAO, taxa_media_pct_NEGRA, taxa_media_pct_BRANCA) |>
  pivot_longer(
    cols = starts_with("taxa_media_pct_"),
    names_to = "raca2", values_to = "taxa_pct",
    names_prefix = "taxa_media_pct_"
  ) |>
  mutate(
    raca2 = str_to_title(raca2),
    ano_shape = factor(ANO_ELEICAO, levels = c("2018", "2022"))
  ) |>
  # garante que 2022 (preenchido) desenhe por cima de 2018 quando os
  # valores quase coincidem (ex.: Federal/Negra: 77,4% vs 77,7%)
  arrange(cargo, raca2, ano_shape)

g_raca <- ggplot(
  plot_raca_df,
  aes(x = cargo, y = taxa_pct, color = raca2, group = interaction(cargo, raca2))
) +
  geom_line(position = dodge_w, linewidth = 0.6, alpha = 0.6) +
  geom_point(
    data = \(d) filter(d, ano_shape == "2018"),
    aes(shape = ano_shape, size = ano_shape),
    stroke = 1.1, position = dodge_w
  ) +
  geom_point(
    data = \(d) filter(d, ano_shape == "2022"),
    size = 5.4, shape = 16, color = "white", position = dodge_w
  ) +
  geom_point(
    data = \(d) filter(d, ano_shape == "2022"),
    aes(shape = ano_shape, size = ano_shape),
    stroke = 1.1, position = dodge_w
  ) +
  scale_color_manual(values = c("Negra" = cor_negra, "Branca" = cor_branca), name = "Raça") +
  scale_size_manual(values = c("2018" = 3.5, "2022" = 4.2), guide = "none") +
  scale_shape_manual(values = c("2018" = 1, "2022" = 16), name = "Ano") +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(
    x = NULL, y = "Taxa de sobreposição territorial",
    title = "Sobreposição territorial por raça, cargo e ano",
    caption = paste0(
      "Círculo aberto = 2018; círculo preenchido = 2022.\n",
      "Cor: verde = Negra, roxo = Branca (paleta Okabe-Ito)."
    )
  ) +
  tema_dumbbell

ggsave(file.path(out_dir, "grafico_sobreposicao_raca.pdf"), g_raca, width = 6, height = 4.5)
ggsave(
  file.path(out_dir, "grafico_sobreposicao_raca.png"), g_raca,
  width = 6, height = 4.5, dpi = 300
)

# ==============================================================================
# 3b. GRÁFICO — lacuna (gap) de sobreposição por ano, gênero e raça em separado
#
# A pedido da autora: em vez de mostrar o nível de cada subgrupo (gráficos
# dumbbell acima), mostrar diretamente a lacuna (gap_pp, já calculada em
# tab_r1_consolidada) por ano, com Federal e Estadual como duas linhas. Um
# gráfico por grupo (gênero, raça), não um único gráfico combinado.
# ==============================================================================

cor_federal  <- "#D55E00"  # vermelhão (Okabe-Ito)
cor_estadual <- "#56B4E9"  # azul-céu (Okabe-Ito)

tema_lacuna <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor      = element_blank(),
    panel.grid.major.x    = element_blank(),
    legend.position        = "top",
    legend.justification   = "center",
    plot.caption           = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

plot_lacuna_genero_df <- tab_r1_consolidada |>
  filter(grupo == "Gênero") |>
  mutate(ano_fct = factor(ANO_ELEICAO, levels = c("2018", "2022")))

g_lacuna_genero <- ggplot(
  plot_lacuna_genero_df,
  aes(x = ano_fct, y = gap_pp, color = cargo, group = cargo)
) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3.5, stroke = 1.2) +
  scale_color_manual(values = c("Federal" = cor_federal, "Estadual" = cor_estadual), name = "Cargo") +
  scale_y_continuous(labels = \(x) paste0(x, " p.p.")) +
  labs(
    x = NULL, y = NULL,
    caption = "Lacuna = taxa de sobreposição de mulheres menos a de homens, em pontos percentuais."
  ) +
  tema_lacuna

ggsave(file.path(out_dir, "grafico_lacuna_genero.pdf"), g_lacuna_genero, width = 5.5, height = 4)
ggsave(
  file.path(out_dir, "grafico_lacuna_genero.png"), g_lacuna_genero,
  width = 5.5, height = 4, dpi = 300
)

plot_lacuna_raca_df <- tab_r1_consolidada |>
  filter(grupo == "Raça") |>
  mutate(ano_fct = factor(ANO_ELEICAO, levels = c("2018", "2022")))

g_lacuna_raca <- ggplot(
  plot_lacuna_raca_df,
  aes(x = ano_fct, y = gap_pp, color = cargo, group = cargo)
) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3.5, stroke = 1.2) +
  scale_color_manual(values = c("Federal" = cor_federal, "Estadual" = cor_estadual), name = "Cargo") +
  scale_y_continuous(labels = \(x) paste0(x, " p.p.")) +
  labs(
    x = NULL, y = NULL,
    caption = "Lacuna = taxa de sobreposição de candidatos negros menos a de brancos, em pontos percentuais."
  ) +
  tema_lacuna

ggsave(file.path(out_dir, "grafico_lacuna_raca.pdf"), g_lacuna_raca, width = 5.5, height = 4)
ggsave(
  file.path(out_dir, "grafico_lacuna_raca.png"), g_lacuna_raca,
  width = 5.5, height = 4, dpi = 300
)

message("Gráficos de lacuna por ano salvos: grafico_lacuna_{genero,raca}.{pdf,png}")

# ==============================================================================
# 4. GRÁFICO — coefficient plot, tripla interação DDD (gênero e raça)
# ==============================================================================

plot_ddd_df <- tab_ddd_consolidada |>
  mutate(
    especificacao = factor(
      especificacao, levels = c("+ Incumbência", "Principal (sem controles)")
    ),
    grupo = factor(grupo, levels = c("Negra", "Mulher"))
  )

g_ddd <- ggplot(
  plot_ddd_df,
  aes(x = estimate_pp, y = especificacao, color = grupo, shape = grupo)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(
    aes(xmin = conf.low_pp, xmax = conf.high_pp),
    orientation = "y", width = 0.15, position = position_dodge(width = 0.4), linewidth = 0.7
  ) +
  geom_point(size = 3.5, position = position_dodge(width = 0.4), stroke = 1.3) +
  scale_color_manual(values = c("Mulher" = cor_feminino, "Negra" = cor_negra), name = NULL) +
  scale_shape_manual(values = c("Mulher" = 16, "Negra" = 17), name = NULL) +
  labs(
    x = "Efeito da tripla interação (Federal x 2022 x Grupo), pontos percentuais",
    y = NULL,
    title = "Queda federal-específica na sobreposição territorial (DDD)",
    caption = paste0(
      "Barras: IC 95%. Linha tracejada: efeito nulo. Efeito de Mulher é ",
      "marginal (p ~0,06-0,07) nas duas\n",
      "especificações; efeito de Negra não é estatisticamente distinguível ",
      "de zero em nenhuma."
    )
  ) +
  tema_dumbbell +
  theme(legend.position = "top")

ggsave(file.path(out_dir, "grafico_ddd_coeficientes.pdf"), g_ddd, width = 7, height = 3.8)
ggsave(
  file.path(out_dir, "grafico_ddd_coeficientes.png"), g_ddd,
  width = 7, height = 3.8, dpi = 300
)

message("Gráficos salvos (PDF + PNG) em ", out_dir)
