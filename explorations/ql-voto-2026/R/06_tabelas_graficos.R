# ==============================================================================
# Script: 06_tabelas_graficos.R
# Purpose: Tabelas e figuras da versão "QL do voto" do Capítulo 6, 2018–2026.
#          Mesmo padrão visual de 04_tabelas_graficos_consolidacao.R (paleta
#          Okabe-Ito, theme_minimal, PDF + PNG 300 dpi).
#
#   1. tabela_lacunas_voto.{csv,tex}: lacunas de gênero e raça por cargo × ano,
#      com p-valor do teste t
#   2. grafico_lacuna_{genero,raca}.{pdf,png}: lacuna por ano, Federal ×
#      Estadual; QL do voto (linha cheia, 2018–2026) e QL do gasto (tracejada,
#      2018–2022) para leitura direta da validação
#   3. grafico_ddd_coeficientes.{pdf,png}: tripla interação contra 2018 —
#      réplica 2018–2022 (gasto e voto) e modelo de três eleições (voto)
#
# Inputs:  explorations/ql-voto-2026/output/ (02, 03, 05)
#          explorations/base-territorial-partidos/output/ (versão gasto)
# Outputs: explorations/ql-voto-2026/output/figuras/
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ql-voto-2026/R/06_tabelas_graficos.R
# ==============================================================================

library(tidyverse)

source("explorations/ql-voto-2026/R/config.R")  # out_dir da variante
voto_dir <- out_dir
fig_dir  <- file.path(voto_dir, "figuras")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Okabe-Ito — mesmas cores do capítulo
cor_feminino <- "#E69F00"
cor_negra    <- "#009E73"
cor_federal  <- "#D55E00"
cor_estadual <- "#56B4E9"

tema <- theme_minimal(base_size = 12) +
  theme(
    strip.text           = element_text(face = "bold"),
    panel.grid.minor     = element_blank(),
    panel.grid.major.x   = element_blank(),
    legend.position      = "top",
    legend.justification = "center",
    plot.caption         = element_text(hjust = 0, size = 8, margin = margin(t = 10))
  )

salvar_grafico <- function(g, nome, largura, altura) {
  ggsave(file.path(fig_dir, paste0(nome, ".pdf")), g, width = largura, height = altura)
  ggsave(file.path(fig_dir, paste0(nome, ".png")), g, width = largura, height = altura,
         dpi = 300, bg = "white")
}

# ==============================================================================
# 1. TABELA DE LACUNAS
# ==============================================================================

ler_lacuna <- function(arq_tab, arq_teste, grupo) {
  read_csv(file.path(voto_dir, arq_tab), col_types = cols(ANO_ELEICAO = "c")) |>
    left_join(read_csv(file.path(voto_dir, arq_teste), col_types = cols(ANO_ELEICAO = "c")) |>
                select(cargo, ANO_ELEICAO, p.value),
              by = c("cargo", "ANO_ELEICAO")) |>
    mutate(grupo = grupo)
}

lac_g <- ler_lacuna("tab_taxa_sobreposicao_genero.csv", "teste_t_genero.csv", "Gênero") |>
  transmute(grupo, cargo, ANO_ELEICAO, taxa_grupo = taxa_media_pct_FEMININO,
            taxa_ref = taxa_media_pct_MASCULINO, n_grupo = n_FEMININO, n_ref = n_MASCULINO,
            gap_pp, p.value)
lac_r <- ler_lacuna("tab_taxa_sobreposicao_raca.csv", "teste_t_raca.csv", "Raça") |>
  transmute(grupo, cargo, ANO_ELEICAO, taxa_grupo = taxa_media_pct_NEGRA,
            taxa_ref = taxa_media_pct_BRANCA, n_grupo = n_NEGRA, n_ref = n_BRANCA,
            gap_pp, p.value)

tabela_lacunas <- bind_rows(lac_g, lac_r) |>
  mutate(cargo = factor(cargo, levels = c("Federal", "Estadual"))) |>
  arrange(grupo, cargo, ANO_ELEICAO)

write_csv(tabela_lacunas, file.path(voto_dir, "tabela_lacunas_voto.csv"))

fmt_p <- function(p) if_else(p < 0.001, "< 0,001", formatC(p, format = "f", digits = 3,
                                                           decimal.mark = ","))
linhas_tex <- tabela_lacunas |>
  mutate(across(c(taxa_grupo, taxa_ref, gap_pp),
                \(x) formatC(x, format = "f", digits = 1, decimal.mark = ",")),
         linha = sprintf("%s & %s & %s & %s (%s) & %s (%s) & %s & %s \\\\",
                         grupo, cargo, ANO_ELEICAO, taxa_grupo,
                         formatC(n_grupo, format = "d", big.mark = ".", decimal.mark = ","),
                         taxa_ref,
                         formatC(n_ref, format = "d", big.mark = ".", decimal.mark = ","),
                         gap_pp,
                         fmt_p(p.value))) |>
  pull(linha)
writeLines(c(
  "\\begin{tabular}{lllrrrr}",
  "\\toprule",
  "Grupo & Cargo & Ano & Grupo-alvo (n) & Referência (n) & Lacuna (p.p.) & p \\\\",
  "\\midrule", linhas_tex, "\\bottomrule", "\\end{tabular}"
), file.path(voto_dir, "tabela_lacunas_voto.tex"))

# ==============================================================================
# 2. LACUNA POR ANO — VOTO (2018–2026) E GASTO (2018–2022)
# ==============================================================================

lacunas_validacao <- bind_rows(
  read_csv(file.path(voto_dir, "validacao_lacuna_genero.csv"), col_types = cols(ANO_ELEICAO = "c")) |>
    mutate(grupo = "Gênero"),
  read_csv(file.path(voto_dir, "validacao_lacuna_raca.csv"), col_types = cols(ANO_ELEICAO = "c")) |>
    mutate(grupo = "Raça")
) |>
  filter(medida == "Gasto") |>
  select(grupo, medida, cargo, ANO_ELEICAO, gap_pp)

plot_lacuna <- bind_rows(
  tabela_lacunas |> transmute(grupo, medida = "Voto", cargo = as.character(cargo),
                              ANO_ELEICAO, gap_pp),
  lacunas_validacao
) |>
  mutate(medida = factor(medida, levels = c("Voto", "Gasto"),
                         labels = c("QL do voto", "QL do gasto (capítulo)")))

grafico_lacuna <- function(g, legenda) {
  ggplot(filter(plot_lacuna, grupo == g),
         aes(x = ANO_ELEICAO, y = gap_pp, color = cargo, linetype = medida,
             shape = medida, group = interaction(cargo, medida))) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
    # Dodge leve: Federal e Estadual coincidem em algumas células (ex. gasto 2022)
    geom_line(linewidth = 0.8, position = position_dodge(width = 0.12)) +
    geom_point(size = 3, stroke = 1.1, position = position_dodge(width = 0.12)) +
    scale_color_manual(values = c(Federal = cor_federal, Estadual = cor_estadual),
                       name = "Cargo") +
    scale_linetype_manual(values = c("solid", "22"), name = NULL) +
    scale_shape_manual(values = c(16, 1), name = NULL) +
    scale_y_continuous(labels = \(x) paste0(x, " p.p.")) +
    labs(x = NULL, y = NULL, caption = legenda) +
    tema +
    theme(legend.box = "vertical", legend.spacing.y = unit(0, "pt"))
}

salvar_grafico(
  grafico_lacuna("Gênero", paste0(
    "Lacuna = taxa de sobreposição de mulheres menos a de homens, em pontos percentuais.\n",
    "QL do gasto indisponível para 2026 (prestação de contas ainda não publicada pelo TSE).")),
  "grafico_lacuna_genero", 6, 4.5)
salvar_grafico(
  grafico_lacuna("Raça", paste0(
    "Lacuna = taxa de sobreposição de candidatos negros menos a de brancos, em pontos percentuais.\n",
    "QL do gasto indisponível para 2026 (prestação de contas ainda não publicada pelo TSE).")),
  "grafico_lacuna_raca", 6, 4.5)

# ==============================================================================
# 3. COEFICIENTES DA DDD
# ==============================================================================

ddd_voto <- read_csv(file.path(voto_dir, "ddd_coeficientes.csv"), show_col_types = FALSE) |>
  filter(especificacao %in% c("replica_2018_2022", "tres_eleicoes"))
ddd_gasto <- read_csv(file.path(voto_dir, "validacao_ddd_replica.csv"), show_col_types = FALSE) |>
  filter(medida == "Gasto") |>
  mutate(especificacao = "replica_gasto")

plot_ddd <- bind_rows(ddd_voto, ddd_gasto) |>
  mutate(
    ano = if_else(str_detect(term, "2026"), "2026", "2022"),
    grupo = if_else(grupo == "genero", "Mulher", "Negra"),
    rotulo = case_when(
      especificacao == "replica_gasto"     ~ "Réplica 2018–22, QL do gasto (capítulo)",
      especificacao == "replica_2018_2022" ~ "Réplica 2018–22, QL do voto",
      especificacao == "tres_eleicoes" & ano == "2022" ~ "2018–26, QL do voto: 2022 vs. 2018",
      especificacao == "tres_eleicoes" & ano == "2026" ~ "2018–26, QL do voto: 2026 vs. 2018"
    ),
    rotulo = factor(rotulo, levels = rev(c(
      "Réplica 2018–22, QL do gasto (capítulo)", "Réplica 2018–22, QL do voto",
      "2018–26, QL do voto: 2022 vs. 2018", "2018–26, QL do voto: 2026 vs. 2018"))),
    across(c(estimate, conf.low, conf.high), \(x) 100 * x)
  )

g_ddd <- ggplot(plot_ddd, aes(x = estimate, y = rotulo, color = grupo, shape = grupo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.15,
                position = position_dodge(width = 0.5), linewidth = 0.7) +
  geom_point(size = 3.2, position = position_dodge(width = 0.5), stroke = 1.2) +
  scale_color_manual(values = c(Mulher = cor_feminino, Negra = cor_negra), name = NULL) +
  scale_shape_manual(values = c(Mulher = 16, Negra = 17), name = NULL) +
  labs(
    x = "Tripla interação (Federal × ano × grupo), pontos percentuais",
    y = NULL,
    caption = paste0(
      "Barras: IC 95%, erros agrupados por partido e UF; EF de partido e UF. ",
      "Base: 2018.\nO modelo 2018–26 estima as interações de 2022 e de 2026 conjuntamente."
    )
  ) +
  tema

salvar_grafico(g_ddd, "grafico_ddd_coeficientes", 7.5, 4.5)

message("Tabelas e figuras salvas em ", voto_dir, " e ", fig_dir)
