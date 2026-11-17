# ==============================================================================
# Figuras do Cap. 3 (EC 111), refeitas a partir dos resultados já estimados
#
# Não reestima nada: lê os CSVs de output/ das duas explorações e grava as
# figuras diretamente em Quarto/thesis/Figures/03-ec111-competitividade/.
# Decisões da autora (17/11):
#   - faixas de margem divididas em gênero e raça, com rótulos legíveis;
#   - estudo de evento da tripla diferença só com "a menos de 0,1 QE" e "eleita",
#     nas cores de cada grupo;
#   - HonestDiD com vírgula decimal, M̄ correto e as duas ponderações;
#   - estudos de evento do funil sem numeração interna nos títulos de painel e com
#     "transferências do partido" no lugar de "recursos do partido";
#   - uma só convenção de barras em todas as figuras: barra fina = banda uniforme
#     de 95%; barra grossa = IC pontual de 95%;
#   - dados brutos por cargo (níveis), a partir de 06_niveis_por_cargo.R.
#
# Rodar da raiz, depois de 03_did_event_study.R (ec111-did-2026) e de 04, 05 e
# 10_honestdid.R (competitividade-eleitoral):
#   Rscript explorations/ec111-did-2026/R/07_figuras_capitulo.R
# ==============================================================================

library(tidyverse)

fig_dir <- "Quarto/thesis/Figures/03-ec111-competitividade"
ce_out  <- "explorations/competitividade-eleitoral/output"
ec_out  <- "explorations/ec111-did-2026/output"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

virgula <- scales::label_number(decimal.mark = ",", big.mark = ".")
cores_gr <- c("Mulheres" = "#eb6834", "Pessoas negras" = "#2a78d6", "Mulheres negras" = "#7b3f99")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
nota_barras <- "Barra fina: banda uniforme de 95%; barra grossa: IC pontual de 95%."

salvar <- function(p, nome, w, h) {
  ggsave(file.path(fig_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(fig_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}

# ------------------------------------------------------------------------------
# 1. Faixas de margem de votos: uma figura para gênero, outra para raça
# ------------------------------------------------------------------------------
ordem_faixas <- c("falta 0,25–0,5", "falta 0,1–0,25", "falta < 0,1",
                  "sobra < 0,1", "sobra 0,1–0,25", "sobra 0,25–0,5")
faixas <- read_csv(file.path(ce_out, "descr_faixas_margem.csv"), show_col_types = FALSE) |>
  filter(faixa %in% ordem_faixas) |>
  mutate(faixa = factor(faixa, rev(ordem_faixas)),
         cargo = factor(cargo, c("Federal", "Estadual")))
stopifnot(n_distinct(faixas$faixa) == length(ordem_faixas))

figura_faixas <- function(grupos, cores, nome) {
  p <- faixas |>
    filter(grupo %in% grupos) |>
    mutate(grupo = factor(grupo, grupos)) |>
    ggplot(aes(x = pct, y = faixa, fill = grupo)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.75) +
    facet_grid(cargo ~ ano) +
    scale_fill_manual(values = cores, name = NULL, breaks = grupos) +
    scale_x_continuous(labels = virgula) +
    labs(x = "% das candidaturas do grupo", y = "Margem de votos, em QE",
         caption = paste0("Fonte: TSE. Margem calculada refazendo a distribuição de cadeiras com a ",
                          "regra de cada ano; sem DF. As faixas extremas (falta ou sobra > 0,5 QE) ",
                          "não aparecem.")) +
    tema + theme(panel.grid.major.y = element_blank())
  salvar(p, nome, 10, 5.5)
}
figura_faixas(c("Mulheres", "Homens"), c("Mulheres" = "#eb6834", "Homens" = "#8c8c8c"),
              "faixas_margem_genero")
figura_faixas(c("Pessoas negras", "Pessoas brancas"),
              c("Pessoas negras" = "#2a78d6", "Pessoas brancas" = "#b3b3b3"),
              "faixas_margem_raca")

# ------------------------------------------------------------------------------
# 2. Estudo de evento da tripla diferença: competitiva (< 0,1 QE) e eleita
# ------------------------------------------------------------------------------
comp_para_grupo <- c("Mulheres − homens" = "Mulheres", "Pessoas negras − brancas" = "Pessoas negras",
                     "Mulheres negras − homens brancos" = "Mulheres negras")
ddd <- read_csv(file.path(ce_out, "ddd_resultados.csv"), show_col_types = FALSE) |>
  filter(desfecho %in% c("ate_010", "eleita"), !ponderado, amostra == "Todas as UFs",
         !is.na(ano)) |>
  mutate(ic_inf = if_else(ano == 2018, 0, ic_inf), ic_sup = if_else(ano == 2018, 0, ic_sup),
         banda_inf = if_else(ano == 2018, 0, banda_inf),
         banda_sup = if_else(ano == 2018, 0, banda_sup),
         desfecho = factor(desfecho, c("ate_010", "eleita"),
                           c("Competitiva (eleita ou a menos de 0,1 QE do limiar)", "Eleita")),
         comparacao = factor(comparacao, names(comp_para_grupo)),
         grupo = comp_para_grupo[as.character(comparacao)])
stopifnot(nrow(ddd) == 3 * 2 * 4)

p_ddd <- ggplot(ddd, aes(x = ano, y = att, colour = grupo)) +
  annotate("rect", xmin = 2020, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_linerange(aes(ymin = banda_inf, ymax = banda_sup), linewidth = 0.4) +
  geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 1.1) +
  geom_point(size = 1.8) +
  facet_grid(comparacao ~ desfecho, labeller = label_wrap_gen(width = 30)) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  scale_y_continuous(labels = virgula) +
  scale_colour_manual(values = cores_gr, guide = "none") +
  labs(x = NULL, y = "Efeito estimado (pontos percentuais)",
       caption = paste0("Fonte: TSE. Tripla diferença (Callaway & Sant'Anna, pacote did), unidade UF × ",
                        "cargo, sem DF, sem ponderação, base 2018; área cinza = depois da EC 111.\n",
                        nota_barras, " Bootstrap multiplicador com 25.000 repetições, agrupado por UF.")) +
  tema
salvar(p_ddd, "ddd_estudo_evento", 9, 7)

# ------------------------------------------------------------------------------
# 3. HonestDiD: efeito médio de 2022 e 2026 sob magnitudes relativas
# ------------------------------------------------------------------------------
rotulo_hd <- c(dif_pct_comp = "Taxa de competitivas (grupo − comparação)",
               pct_grupo_entre_comp = "% do grupo entre as competitivas",
               nc_por_cadeira_grupo = "Não competitivas do grupo por cadeira")
hd <- read_csv(file.path(ce_out, "honestdid_sensibilidade.csv"), show_col_types = FALSE) |>
  filter(alvo == "média 2022 e 2026", restricao %in% c("Original", "RM (M̄)"),
         desfecho %in% names(rotulo_hd)) |>
  mutate(x = if_else(restricao == "Original", -0.25, M),
         grupo = if_else(grupo == "mulheres", "Mulheres (× homens)", "Pessoas negras (× brancas)"),
         desfecho = factor(rotulo_hd[desfecho], rotulo_hd),
         peso = factor(peso, c("sem peso", "magnitude"),
                       c("Sem peso", "Peso pela magnitude do distrito")))
stopifnot(all(c("Sem peso", "Peso pela magnitude do distrito") %in% hd$peso))

p_hd <- ggplot(hd, aes(x = x, ymin = lb, ymax = ub, colour = peso)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_vline(xintercept = -0.125, colour = "grey85") +
  geom_errorbar(position = position_dodge(width = 0.18), width = 0.12, linewidth = 0.6) +
  facet_grid(desfecho ~ grupo, scales = "free_y", labeller = label_wrap_gen(width = 28)) +
  scale_x_continuous(breaks = c(-0.25, seq(0, 2, 0.5)),
                     labels = c("Original", virgula(seq(0, 2, 0.5)))) +
  scale_y_continuous(labels = virgula) +
  scale_colour_manual(values = c("Sem peso" = "#333333", "Peso pela magnitude do distrito" = "#9a9a9a"),
                      name = NULL) +
  labs(x = expression(bar(M) ~ "(múltiplo da violação de 2014–2018)"),
       y = "IC robusto de 95% (pontos percentuais)",
       caption = paste0("Fonte: TSE. Efeito médio de 2022 e 2026; unidade UF × cargo, sem DF; variância ",
                        "agrupada por UF. Rambachan & Roth (2023), restrição de magnitudes relativas.\n",
                        "\"Original\" = IC sem violação de tendências paralelas.")) +
  tema
salvar(p_hd, "honestdid_sensibilidade", 9, 8)

# ------------------------------------------------------------------------------
# 4. Estudos de evento do funil: receita e decomposição competitivas × não
# ------------------------------------------------------------------------------
res <- read_csv2(file.path(ec_out, "did_2026_resultados.csv"), show_col_types = FALSE) |>
  filter(!ponderado, balanceado, nivel == "lista", grupo %in% names(cores_gr))
rotulos <- c(
  rec_total   = "Receita total (% da receita da lista)",
  rec_partido = "Transferências do partido (% das transferências da lista)",
  rtp         = "Receita vinda do partido (% da receita da lista)",
  rto         = "Receita de outras fontes (% da receita da lista)",
  voto_c      = "Votos de competitivas do grupo (% dos votos da lista)",
  voto_nc     = "Votos de não competitivas do grupo (% dos votos da lista)",
  gasto_c     = "Gasto de competitivas do grupo (% do gasto da lista)",
  gasto_nc    = "Gasto de não competitivas do grupo (% do gasto da lista)",
  recp_c      = "Transferências a competitivas do grupo (% das transferências da lista)",
  recp_nc     = "Transferências a não competitivas do grupo (% das transferências da lista)")

evento <- function(medidas, nome, h, nota = "") {
  d <- res |>
    filter(medida %in% medidas, periodo %in% c("2014", "2022", "2026")) |>
    distinct(medida, grupo, periodo, .keep_all = TRUE)
  d <- d |>
    bind_rows(d |> distinct(medida, grupo) |>
                mutate(periodo = "2018", att = 0, ic_inf = 0, ic_sup = 0, ic_unif_inf = 0,
                       ic_unif_sup = 0)) |>
    mutate(ano = as.integer(periodo), painel = factor(rotulos[medida], rotulos[medidas]),
           grupo = factor(grupo, names(cores_gr)))
  stopifnot(!anyNA(d$painel))
  p <- ggplot(d, aes(x = ano, y = att, colour = grupo)) +
    annotate("rect", xmin = 2020, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
    geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
    geom_linerange(aes(ymin = ic_unif_inf, ymax = ic_unif_sup),
                   position = position_dodge(width = 1.2), linewidth = 0.4) +
    geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), position = position_dodge(width = 1.2),
                   linewidth = 1.1) +
    geom_point(position = position_dodge(width = 1.2), size = 1.8) +
    facet_wrap(~painel, ncol = 2, scales = "free_y", labeller = label_wrap_gen(width = 45)) +
    scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
    scale_y_continuous(labels = virgula) +
    scale_colour_manual(values = cores_gr, name = NULL) +
    labs(x = NULL, y = "Efeito estimado (pontos percentuais)",
         caption = paste0("Fonte: TSE. DiD (Callaway & Sant'Anna, pacote did), federal × estadual, base ",
                          "2018; listas partido × UF balanceadas, sem DF; área cinza = depois da EC 111.\n",
                          nota_barras, " Erros agrupados por lista.", nota)) +
    tema
  salvar(p, nome, 10, h)
}
evento(c("rec_total", "rec_partido", "rtp", "rto"), "did_2026_evento_receita_origem", 7,
       " Recursos sem pré-teste (doação empresarial em 2014).")
evento(c("voto_c", "voto_nc", "gasto_c", "gasto_nc", "recp_c", "recp_nc"),
       "did_2026_evento_margem_decomposicao", 9.5,
       paste0("\nCompetitiva = eleita ou a menos de 0,1 QE do limiar pela margem de votos. ",
              "Gasto e transferências sem pré-teste."))
# ------------------------------------------------------------------------------
# 5. Dados brutos: parcela média de cada grupo por cargo e ano (Cunningham 2021, cap. 9)
# ------------------------------------------------------------------------------
rot_niveis <- c(cand = "Candidaturas (% da lista)", voto = "Votos nominais (% da lista)",
                rec_total = "Receita total (% da lista)",
                rec_partido = "Transferências do partido (% das transferências da lista)",
                rec_publico = "Recursos públicos (% dos recursos públicos da lista)", gasto = "Gasto (% da lista)")
niv <- read_csv2(file.path(ec_out, "niveis_por_cargo.csv"), show_col_types = FALSE) |>
  mutate(medida = str_remove(resultado, "_(mulher_negra|mulher|negra)$"),
         g = str_extract(resultado, "(mulher_negra|mulher|negra)$"),
         grupo = factor(c(mulher = "Mulheres", negra = "Pessoas negras",
                          mulher_negra = "Mulheres negras")[g], names(cores_gr)),
         painel = factor(rot_niveis[medida], rot_niveis),
         cargo = factor(cargo, c("federal", "estadual"), c("Federal", "Estadual")))
stopifnot(!anyNA(niv$painel), !anyNA(niv$grupo))
p_niv <- ggplot(niv, aes(x = ano, y = media, colour = grupo, linetype = cargo, shape = cargo)) +
  annotate("rect", xmin = 2020, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
  geom_line(linewidth = 0.6) + geom_point(size = 1.8) +
  facet_wrap(~painel, ncol = 3, scales = "free_y", labeller = label_wrap_gen(width = 32)) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  scale_y_continuous(labels = virgula) +
  scale_colour_manual(values = cores_gr, name = NULL) +
  scale_linetype_manual(values = c(Federal = "solid", Estadual = "22"), name = NULL) +
  scale_shape_manual(values = c(Federal = 16, Estadual = 1), name = NULL) +
  labs(x = NULL, y = "Parcela média do grupo nas listas (%)",
       caption = paste0("Fonte: TSE. Média das listas partido × UF do painel balanceado de cada desfecho, ",
                        "sem DF; área cinza = depois da EC 111. Recursos e gasto: 2018–2026 ",
                        "(doação empresarial em 2014).")) +
  tema
salvar(p_niv, "niveis_por_cargo", 10, 6.5)

cat("Figuras gravadas em", fig_dir, "\n")
