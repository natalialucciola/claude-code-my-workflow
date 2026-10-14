# ==============================================================================
# Script: 05_figuras_tabelas.R
# Purpose: Figuras e tabela principal do DiD da EC 111 com QL por município.
#   Fig. 1 — médias brutas de entrada em território novo, Federal × Estadual
#   Fig. 2 — event study da decomposição: total × entradas por g (bandas
#            uniformes e pontuais)
#   Fig. 3 — parcela do avanço que veio de g, contra a parcela federal de 2018
#   Fig. 4 — robustez (ATT de 2022 e 2026 por variante)
#   Tabela — resultados principais (csv pronto para o capítulo)
# Paleta: Okabe-Ito, a mesma de explorations/ql-voto-2026/R/06_tabelas_graficos.R;
#   pares checados para daltonismo (ΔE2000 ≥ 30 em deutan/protan/tritan). Laranja e
#   azul-claro têm contraste baixo com o branco → forma de ponto como 2ª codificação.
# Inputs:  output/{resultados_did,parcela_g,robustez}.csv, output/dados/painel_municipio.rds
# Outputs: output/figuras/*.{pdf,png}, output/tabela_principal.csv
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ec111-did-ql-municipio/R/05_figuras_tabelas.R
# ==============================================================================

library(tidyverse)

out_dir <- file.path("explorations", "ec111-did-ql-municipio", "output")
fig_dir <- file.path(out_dir, "figuras")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

cor_total    <- "#3D3D3D"
cor_mulher   <- "#E69F00"
cor_negra    <- "#009E73"
cor_federal  <- "#D55E00"
cor_estadual <- "#56B4E9"
tinta_sec    <- "#595959"

tema <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "#E5E5E5", linewidth = 0.3),
        axis.text = element_text(colour = tinta_sec),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title.position = "plot",
        plot.caption = element_text(colour = tinta_sec, hjust = 0, size = 8),
        legend.position = "top", legend.justification = "left")

salvar <- function(g, nome, largura = 8, altura = 4.5) {
  ggsave(file.path(fig_dir, paste0(nome, ".pdf")), g, width = largura, height = altura)
  ggsave(file.path(fig_dir, paste0(nome, ".png")), g, width = largura, height = altura,
         dpi = 300, bg = "white")
}

rotulo_grupo <- c(mulher = "Mulheres", negra = "Pessoas negras")
fonte <- "Fonte: TSE (votação por município, 2010–2026). Base = QL do voto > 1 e fatia ≥ 2,5% dos votos do candidato."

# ---- Fig. 1: médias brutas ----
painel <- readRDS(file.path(out_dir, "dados", "painel_municipio.rds"))
brutas <- painel |>
  summarise(across(c(nova_base, nova_base_mulher, nova_base_negra), \(x) 100 * mean(x)),
            .by = c(cargo, ano)) |>
  pivot_longer(-c(cargo, ano), names_to = "resultado", values_to = "media") |>
  mutate(resultado = factor(resultado, c("nova_base", "nova_base_mulher", "nova_base_negra"),
                            c("Qualquer candidatura", "Candidatura de mulher",
                              "Candidatura de pessoa negra")))
g1 <- ggplot(brutas, aes(ano, media, colour = cargo, shape = cargo)) +
  annotate("rect", xmin = 2020, xmax = 2027.5, ymin = -Inf, ymax = Inf, fill = "#F2F2F2") +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.4) +
  facet_wrap(~resultado, scales = "free_y") +
  scale_colour_manual(values = c(Federal = cor_federal, Estadual = cor_estadual), name = NULL) +
  scale_shape_manual(values = c(Federal = 16, Estadual = 17), name = NULL) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  scale_y_continuous(limits = c(0, NA), labels = \(x) paste0(x, "%")) +
  labs(x = NULL, y = "Pares partido × município com base nova",
       title = "Entrada do partido em município onde não tinha base",
       subtitle = "Média dos pares partido × município; área cinza = eleições sob a EC 111/2021",
       caption = fonte) +
  tema
salvar(g1, "fig1_medias_brutas", largura = 9, altura = 3.8)

# ---- Fig. 2: event study da decomposição ----
res <- read_csv(file.path(out_dir, "resultados_did.csv"), show_col_types = FALSE) |>
  filter(especificacao == "principal", !str_detect(termo, "média")) |>
  mutate(ano = as.integer(str_extract(termo, "\\d{4}")),
         ic_pt_inf = att - 1.96 * ep, ic_pt_sup = att + 1.96 * ep)
# 2018 é a referência (ATT = 0 por construção)
ref <- distinct(res, resultado) |> mutate(ano = 2018L, att = 0, ic_inf = 0, ic_sup = 0,
                                         ic_pt_inf = 0, ic_pt_sup = 0)
es <- bind_rows(res, ref) |>
  filter(resultado %in% c("nova_base", "nova_base_mulher", "nova_base_negra"))
es <- bind_rows(
  es |> filter(resultado %in% c("nova_base", "nova_base_mulher")) |> mutate(painel = "mulher"),
  es |> filter(resultado %in% c("nova_base", "nova_base_negra")) |> mutate(painel = "negra")
) |>
  mutate(serie = if_else(resultado == "nova_base", "Total de entradas",
                         "Entradas por candidaturas do grupo"),
         serie = factor(serie, c("Total de entradas", "Entradas por candidaturas do grupo")),
         painel = rotulo_grupo[painel],
         cor = case_when(serie == "Total de entradas" ~ "total",
                         painel == "Mulheres" ~ "mulher", TRUE ~ "negra"),
         x = ano + if_else(serie == "Total de entradas", -0.45, 0.45))

g2 <- ggplot(es, aes(x, att, colour = cor, shape = serie)) +
  geom_hline(yintercept = 0, colour = tinta_sec, linewidth = 0.4) +
  geom_vline(xintercept = 2020, colour = "#BDBDBD", linetype = "dashed", linewidth = 0.4) +
  geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 0.5, alpha = 0.45) +
  geom_linerange(aes(ymin = ic_pt_inf, ymax = ic_pt_sup), linewidth = 1.3) +
  geom_point(size = 2.6, fill = "white", stroke = 1) +
  facet_wrap(~painel) +
  scale_colour_manual(values = c(total = cor_total, mulher = cor_mulher, negra = cor_negra),
                      guide = "none") +
  scale_shape_manual(values = c(16, 21), name = NULL) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  labs(x = NULL, y = "ATT (pontos percentuais)",
       title = "EC 111: entrada em território novo, total e por candidaturas do grupo",
       subtitle = paste("DiD Federal × Estadual, mesmo partido e município; 2018 = referência.",
                        "Barra grossa: IC 95% pontual; fina: banda uniforme"),
       caption = paste(fonte, "Total = entradas do grupo + entradas dos demais.")) +
  tema
salvar(g2, "fig2_event_study_decomposicao", largura = 9, altura = 4.2)

# ---- Fig. 3: parcela do avanço que veio de g ----
parc <- read_csv(file.path(out_dir, "parcela_g.csv"), show_col_types = FALSE) |>
  mutate(termo = factor(termo, c("2022", "2026", "média 2022–2026")),
         grupo = str_replace(grupo, "^m", "M") |> str_replace("^p", "P"))
g3 <- ggplot(parc, aes(termo, 100 * parcela, colour = grupo, shape = grupo)) +
  geom_hline(aes(yintercept = 100 * parcela_federal_2018, colour = grupo), linetype = "dotted",
             linewidth = 0.6) +
  geom_pointrange(aes(ymin = 100 * ic_inf, ymax = 100 * ic_sup), linewidth = 0.7, size = 0.5,
                  position = position_dodge(width = 0.4)) +
  scale_colour_manual(values = c(Mulheres = cor_mulher, `Pessoas negras` = cor_negra),
                      name = NULL) +
  scale_shape_manual(values = c(Mulheres = 16, `Pessoas negras` = 17), name = NULL) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(x = NULL, y = "ATT(grupo) ÷ ATT(total)",
       title = "Quanto do avanço territorial causado pela EC 111 veio de cada grupo",
       subtitle = "Pontilhado: parcela das entradas federais que já era do grupo em 2018 (referência)",
       caption = paste(fonte, "IC 95% pelo método delta, cluster na lista.")) +
  tema
salvar(g3, "fig3_parcela_grupo", largura = 7, altura = 4.2)

# ---- Fig. 4: robustez ----
arq_rob <- file.path(out_dir, "robustez.csv")
if (file.exists(arq_rob)) {
  rob <- read_csv(arq_rob, show_col_types = FALSE) |>
    filter(termo %in% c("2022", "2026")) |>
    mutate(resultado = factor(resultado, c("nova_base", "nova_base_mulher", "nova_base_negra"),
                              c("Total", "Mulheres", "Pessoas negras")),
           variante = fct_rev(fct_inorder(variante)))
  g4 <- ggplot(rob, aes(att, variante, colour = resultado, shape = resultado)) +
    geom_vline(xintercept = 0, colour = tinta_sec, linewidth = 0.4) +
    geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), linewidth = 0.5, size = 0.35,
                    position = position_dodge(width = 0.6)) +
    facet_wrap(~termo) +
    scale_colour_manual(values = c(Total = cor_total, Mulheres = cor_mulher,
                                   `Pessoas negras` = cor_negra), name = NULL) +
    scale_shape_manual(values = c(Total = 15, Mulheres = 16, `Pessoas negras` = 17),
                       name = NULL) +
    labs(x = "ATT (pontos percentuais), IC 95%", y = NULL,
         title = "Robustez: entrada em território novo por variante de medida e amostra",
         caption = "TWFE (id + ano), igual ao att_gt neste desenho; cluster na lista.") +
    tema + theme(panel.grid.major.y = element_blank(),
                 panel.grid.major.x = element_line(colour = "#E5E5E5", linewidth = 0.3))
  salvar(g4, "fig4_robustez", largura = 9, altura = 5.5)
}

# ---- Tabela principal ----
tab <- read_csv(file.path(out_dir, "resultados_did.csv"), show_col_types = FALSE) |>
  filter(especificacao %in% c("principal", "ponderado")) |>
  mutate(estimativa = sprintf("%.2f [%.2f; %.2f]", att, ic_inf, ic_sup)) |>
  select(especificacao, resultado, termo, estimativa, media_federal_2018, unidades, listas) |>
  pivot_wider(names_from = termo, values_from = estimativa)
write_csv(tab, file.path(out_dir, "tabela_principal.csv"))
message("Figuras em ", fig_dir)
