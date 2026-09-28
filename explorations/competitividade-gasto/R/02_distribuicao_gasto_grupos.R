# ==============================================================================
# Distribuição do gasto por gênero, raça e resultado — 2018 × 2022, Federal × Estadual
#
# Pergunta: mulheres e candidaturas negras se aproximaram, entre 2018 e 2022, do
# patamar de gasto de uma candidatura competitiva?
#
# Régua: razao_p10 = gasto da candidatura / p10 do gasto dos eleitos no mesmo
# ano × cargo × UF (01_competitividade_gasto.R). O p10 é o valor de gasto abaixo do
# qual está 1 em cada 10 eleitos da disputa (ex.: 70 eleitos → entre o 7º e o 8º menor gasto).
# razao_p10 = 1 significa que a candidatura gastou tanto quanto esse eleito.
# É comparável entre UFs, cargos e anos, ao contrário do % do limite legal.
#
# Sem médias: quantis, distribuições acumuladas e % acima de patamares.
# "Resultado" (eleito / competitivo não eleito / não competitivo) = classificação
# pelo VOTO (≥ 10% do QE), usada só para descrever — não é a medida de gasto.
#
# Rodar a partir da raiz do repositório, depois do script 01:
#   Rscript explorations/competitividade-gasto/R/02_distribuicao_gasto_grupos.R
# ==============================================================================

library(tidyverse)

out_dir <- "explorations/competitividade-gasto/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

patamares <- c(0.25, 0.5, 1)       # múltiplos do p10 dos eleitos
patamar_ref <- 0.5                 # patamar destacado nos gráficos
piso_log <- 1e-3                   # valores abaixo (inclui gasto 0) são exibidos no piso
qs <- c(p10 = .10, p25 = .25, p50 = .50, p75 = .75, p90 = .90)

base <- readRDS("data/processed/competitividade_gasto_cand.rds") |>
  filter(raca2 %in% c("BRANCA", "NEGRA"), !is.na(razao_p10)) |>
  mutate(raca     = if_else(raca2 == "NEGRA", "Negras/os", "Brancas/os"),
         grupo    = factor(paste(genero, str_to_lower(raca)),
                           levels = c("Homens brancas/os", "Homens negras/os",
                                      "Mulheres brancas/os", "Mulheres negras/os"),
                           labels = c("Homens brancos", "Homens negros",
                                      "Mulheres brancas", "Mulheres negras")),
         DS_CARGO = factor(DS_CARGO, levels = c("Deputado Federal", "Deputado Estadual")),
         x_plot   = pmax(razao_p10, piso_log))

# ------------------------------------------------------------------------------
# 1. Tabelas
# ------------------------------------------------------------------------------
quantis <- function(d, ...) {
  d |>
    reframe(n = n(), pct_sem_despesa = 100 * mean(sem_despesa),
            q = names(qs), valor = quantile(razao_p10, qs, names = FALSE), .by = c(...)) |>
    pivot_wider(names_from = q, values_from = valor)
}
tab_q_grupo <- bind_rows(
  quantis(base, ANO, DS_CARGO, genero) |> mutate(recorte = "gênero"),
  quantis(base, ANO, DS_CARGO, raca) |> mutate(recorte = "raça"),
  quantis(base, ANO, DS_CARGO, grupo) |> mutate(recorte = "gênero × raça")
) |> relocate(recorte)
write_excel_csv2(tab_q_grupo, file.path(out_dir, "quantis_razao_p10_grupo.csv"))

tab_q_resultado <- bind_rows(
  quantis(base, ANO, DS_CARGO, resultado, genero) |> mutate(recorte = "gênero"),
  quantis(base, ANO, DS_CARGO, resultado, raca) |> mutate(recorte = "raça")
) |> relocate(recorte)
write_excel_csv2(tab_q_resultado, file.path(out_dir, "quantis_razao_p10_resultado.csv"))

# % acima de cada patamar, com IC 95% de Wilson
wilson <- function(k, n, z = 1.96) {
  p <- k / n; den <- 1 + z^2 / n
  centro <- (p + z^2 / (2 * n)) / den
  meia <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  tibble(pct = 100 * p, ic_inf = 100 * (centro - meia), ic_sup = 100 * (centro + meia))
}
pct_acima <- function(d, ...) {
  map(patamares, function(pt) {
    d |>
      summarise(n = n(), k = sum(razao_p10 >= pt), .by = c(...)) |>
      mutate(patamar = pt, wilson(k, n))
  }) |> list_rbind()
}
tab_acima <- bind_rows(
  pct_acima(base, ANO, DS_CARGO, genero) |> rename(categoria = genero) |> mutate(recorte = "gênero"),
  pct_acima(base, ANO, DS_CARGO, raca) |> rename(categoria = raca) |> mutate(recorte = "raça"),
  pct_acima(base, ANO, DS_CARGO, grupo) |> rename(categoria = grupo) |>
    mutate(categoria = as.character(categoria), recorte = "gênero × raça")
) |> relocate(recorte, patamar)
write_excel_csv2(tab_acima, file.path(out_dir, "pct_acima_patamar_grupo.csv"))

# Variação 2018 → 2022 e lacuna em relação a homens / brancos (pontos percentuais)
lacunas <- tab_acima |>
  filter(recorte %in% c("gênero", "raça")) |>
  select(recorte, patamar, ANO, DS_CARGO, categoria, pct) |>
  pivot_wider(names_from = categoria, values_from = pct) |>
  mutate(lacuna_pp = if_else(recorte == "gênero", Mulheres - Homens, `Negras/os` - `Brancas/os`)) |>
  select(recorte, patamar, DS_CARGO, ANO, lacuna_pp) |>
  pivot_wider(names_from = ANO, values_from = lacuna_pp, names_prefix = "lacuna_") |>
  mutate(variacao_lacuna_pp = lacuna_2022 - lacuna_2018)
write_excel_csv2(lacunas, file.path(out_dir, "lacunas_pct_acima_patamar.csv"))

# ------------------------------------------------------------------------------
# 2. Gráficos
# ------------------------------------------------------------------------------
cores_gen  <- c("Mulheres" = "#eb6834", "Homens" = "#2a78d6")   # convenção: laranja = F, azul = M
cores_ano  <- c("2018" = "#86b6ef", "2022" = "#104281")          # mais recente = mais escuro
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")
fonte <- paste("Fonte: TSE (prestação de contas final, sem repasses; resultados). Candidaturas aptas",
               "brancas e negras.\nRégua: gasto ÷ p10 do gasto dos eleitos no mesmo ano, cargo e UF.")
lab_x <- function(x) {
  lab <- format(x, big.mark = ".", decimal.mark = ",", drop0trailing = TRUE, trim = TRUE,
                scientific = FALSE)
  lab[!is.na(x) & abs(x - piso_log) < 1e-12] <- "≤ 0,001\n(inclui 0)"
  lab
}
escala_log <- function(eixo = "x") {
  f <- if (eixo == "x") scale_x_log10 else scale_y_log10
  f(labels = lab_x, breaks = c(piso_log, .01, .1, 1, 10))
}
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}

# 2a. Distribuição acumulada: gênero (cor) × raça (tipo de linha), por cargo e ano
p <- ggplot(base, aes(x = x_plot, colour = genero, linetype = raca)) +
  stat_ecdf(linewidth = 0.6, pad = FALSE) +
  geom_vline(xintercept = c(patamar_ref, 1), colour = "grey55", linewidth = 0.3) +
  annotate("text", x = patamar_ref, y = 0.02, label = "0,5×", hjust = 1.1, size = 2.8,
           colour = "grey35") +
  annotate("text", x = 1, y = 0.02, label = "1×", hjust = -0.2, size = 2.8, colour = "grey35") +
  escala_log("x") +
  scale_y_continuous(labels = \(y) paste0(100 * y, "%")) +
  facet_grid(DS_CARGO ~ ANO) +
  scale_colour_manual(values = cores_gen, name = NULL) +
  scale_linetype_manual(values = c("Brancas/os" = "solid", "Negras/os" = "22"), name = NULL) +
  labs(title = "Distribuição do gasto relativo ao patamar dos eleitos — gênero e raça",
       subtitle = paste("Cada curva: % das candidaturas com gasto até o valor do eixo x.",
                        "Curva mais à direita/abaixo = grupo que gasta mais.\n",
                        "Linhas verticais: 0,5× e 1× o p10 do gasto dos eleitos na UF."),
       x = "Gasto ÷ p10 dos eleitos (escala log)", y = "% acumulado de candidaturas",
       caption = fonte) + tema
salvar(p, "ecdf_razao_p10_genero_raca", 10, 7.5)

# 2b. Quantis 2018 × 2022 por gênero × raça (sem médias)
#     traço fino = p10–p90; barra grossa = p25–p75; ponto = mediana
d_q <- quantis(base, ANO, DS_CARGO, grupo) |>
  mutate(across(p10:p90, \(x) pmax(x, piso_log)))
grafico_quantis <- function(d, y, titulo, subtitulo, nome, h = 6.5, facetas = DS_CARGO ~ .) {
  p <- ggplot(d, aes(y = .data[[y]], colour = ANO)) +
    geom_vline(xintercept = c(patamar_ref, 1), colour = "grey70", linewidth = 0.3) +
    geom_linerange(aes(xmin = p10, xmax = p90), linewidth = 0.4,
                   position = position_dodge(width = 0.6)) +
    geom_linerange(aes(xmin = p25, xmax = p75), linewidth = 2.2,
                   position = position_dodge(width = 0.6)) +
    geom_point(aes(x = p50), size = 2.2, shape = 21, fill = "white", stroke = 0.9,
               position = position_dodge(width = 0.6)) +
    escala_log("x") +
    facet_grid(facetas) +
    scale_colour_manual(values = cores_ano, name = NULL) +
    labs(title = titulo, subtitle = subtitulo, x = "Gasto ÷ p10 dos eleitos (escala log)",
         y = NULL, caption = fonte) + tema
  salvar(p, nome, 10, h)
}
grafico_quantis(d_q, "grupo",
  "Como a distribuição do gasto mudou de 2018 para 2022 — gênero × raça",
  "Traço fino: p10–p90. Barra: p25–p75. Círculo: mediana. Linhas verticais: 0,5× e 1× o patamar dos eleitos.",
  "quantis_razao_p10_genero_raca")

# 2c. Mesmo recorte dentro de cada resultado pelo voto
d_qr <- quantis(base, ANO, DS_CARGO, resultado, grupo) |>
  mutate(across(p10:p90, \(x) pmax(x, piso_log)))
grafico_quantis(d_qr, "grupo",
  "Distribuição do gasto por resultado eleitoral (classificação pelo voto) — 2018 × 2022",
  "Resultado: eleito/a; competitivo/a não eleito/a (≥ 10% do QE); não competitivo/a. Traço: p10–p90; barra: p25–p75; círculo: mediana.",
  "quantis_razao_p10_resultado_genero_raca", h = 9, facetas = resultado ~ DS_CARGO)

# 2d. % de candidaturas acima do patamar (0,5× o p10 dos eleitos), 2018 → 2022
d_acima <- tab_acima |>
  filter(recorte == "gênero × raça", patamar == patamar_ref) |>
  mutate(categoria = factor(categoria, levels = levels(base$grupo)),
         DS_CARGO = factor(DS_CARGO, levels = levels(base$DS_CARGO)))
p <- ggplot(d_acima, aes(x = pct, y = categoria)) +
  geom_line(aes(group = categoria), colour = "grey75", linewidth = 0.5) +
  geom_linerange(aes(xmin = ic_inf, xmax = ic_sup, colour = ANO), linewidth = 0.5) +
  geom_point(aes(colour = ANO, shape = ANO), size = 2.6, fill = "white", stroke = 1) +
  # 2018 abaixo do ponto, 2022 acima — evita sobreposição quando os valores são próximos
  geom_text(aes(label = sprintf("%.0f%%", pct), colour = ANO,
                vjust = if_else(ANO == "2018", 2.1, -1.1)), size = 2.8, show.legend = FALSE) +
  facet_wrap(~DS_CARGO, ncol = 2) +
  scale_colour_manual(values = cores_ano, name = NULL) +
  scale_shape_manual(values = c("2018" = 21, "2022" = 16), name = NULL) +
  scale_x_continuous(labels = \(x) paste0(x, "%"), limits = c(0, NA)) +
  labs(title = "Candidaturas que alcançaram o patamar de gasto competitivo — 2018 × 2022",
       subtitle = "% com gasto ≥ 0,5× o p10 do gasto dos eleitos na mesma UF, cargo e ano. Barras: IC 95% (Wilson).",
       x = "% das candidaturas do grupo", y = NULL, caption = fonte) + tema
salvar(p, "pct_acima_patamar_genero_raca", 10, 5)

message("Distribuição por grupos: resultados em ", out_dir)
