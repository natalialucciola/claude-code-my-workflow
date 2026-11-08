# =============================================================================
# 13 — Descritivo: competitividade pelo gasto (A, D2, D3) × pelo voto, 2014–2026 (2026 parcial)
#
# Entrada: data/processed/margem_gasto_medidas.rds (R/12),
#          data/processed/competitividade_gasto_cand.rds (razao_p10, 2018 e 2022)
# Saída (explorations/competitividade-eleitoral/output/):
#   gasto_descr_competitivas.csv  % competitivas por medida, grupo, cargo e ano
#   gasto_cruzamento_voto.csv     competitiva pelo voto × pelo gasto (A), por gênero
#   gasto_concordancia_p10.csv    medida A × razao_p10 ≥ 0,5 (2018, 2022)
#   gasto_margem_ecdf.{png,pdf}   distribuição acumulada da margem de gasto (A)
#   gasto_competitivas.{png,pdf}  % competitivas pelo voto e pelas três medidas de gasto
#
# Competitiva = eleita ou a menos de 0,1 QE do limiar (voto: margem_qe; A: margem_gasto_qe;
# D2: d2_qe); D3 ≥ 0,5. Sem DF, como no desenho Federal × Estadual.
#
#   Rscript explorations/competitividade-eleitoral/R/13_descritivo_gasto.R
# =============================================================================
library(data.table)
library(ggplot2)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
d <- readRDS(file.path("data", "processed", "margem_gasto_medidas.rds"))
d <- d[uf != "DF" & !is.na(margem_qe)]
d[, cargo := factor(cargo, levels = c("Federal", "Estadual"))]
d[, `:=`(comp_voto = margem_qe >= -0.1, comp_a = margem_gasto_qe >= -0.1,
         comp_a_025 = margem_gasto_qe >= -0.25, comp_d2 = d2_qe >= -0.1, comp_d3 = d3 >= 0.5)]

grupos <- list(Mulheres = quote(mulher), Homens = quote(!mulher),
               `Pessoas negras` = quote(negra), `Pessoas brancas` = quote(raca == "BRANCA"),
               `Mulheres negras` = quote(mulher & negra))
por_grupo <- function(f) {
  rbindlist(lapply(names(grupos), function(g) d[(eval(grupos[[g]])), f(.SD), by = .(ano, cargo)][
    , grupo := g][]))
}

# 1. % competitivas por medida -------------------------------------------------------
comp <- por_grupo(function(x) data.table(
  n = nrow(x), voto = 100 * mean(x$comp_voto), eleita = 100 * mean(x$eleito),
  a_eleita_gasto = 100 * mean(x$eleito_gasto), a_010 = 100 * mean(x$comp_a),
  a_025 = 100 * mean(x$comp_a_025), d2_010 = 100 * mean(x$comp_d2, na.rm = TRUE),
  d3_050 = 100 * mean(x$comp_d3, na.rm = TRUE),
  mediana_a = median(x$margem_gasto_qe), mediana_d3 = median(x$d3, na.rm = TRUE)))
num <- names(comp)[vapply(comp, is.double, TRUE)]
comp[, (num) := lapply(.SD, round, 2), .SDcols = num]
fwrite(comp[order(grupo, cargo, ano)], file.path(dir_out, "gasto_descr_competitivas.csv"))
print(comp[grupo %in% c("Mulheres", "Homens"),
           .(grupo, cargo, ano, voto, a_010, d2_010, d3_050, mediana_a)][order(cargo, grupo, ano)])

# 2. Cruzamento voto × gasto (A), por gênero ----------------------------------------------
cruz <- d[, .N, by = .(ano, cargo, grupo = fifelse(mulher, "Mulheres", "Homens"),
                        comp_voto, comp_a)]
cruz[, pct := round(100 * N / sum(N), 2), by = .(ano, cargo, grupo)]
cruz[, celula := fcase(comp_voto & comp_a, "competitiva nos dois",
                       !comp_voto & comp_a, "só pelo gasto",
                       comp_voto & !comp_a, "só pelo voto",
                       default = "em nenhum")]
fwrite(cruz[order(ano, cargo, grupo, celula)], file.path(dir_out, "gasto_cruzamento_voto.csv"))
message("Competitivas só pelo gasto (dinheiro sem voto) e só pelo voto, % do grupo:")
print(dcast(cruz[celula %in% c("só pelo gasto", "só pelo voto")],
            cargo + ano ~ grupo + celula, value.var = "pct")[order(cargo, ano)])

# 3. Concordância com razao_p10 ≥ 0,5 (2018, 2022) ----------------------------------------
p10 <- as.data.table(readRDS(file.path("data", "processed", "competitividade_gasto_cand.rds")))[
  , .(ano = as.integer(ANO), sq_candidato = as.character(sq_candidato), razao_p10)]
cp <- merge(d[ano %in% c(2018L, 2022L)], p10, by = c("ano", "sq_candidato"))
conc <- cp[!is.na(razao_p10), .(n = .N, concordancia = round(100 * mean(comp_a == (razao_p10 >= 0.5)), 1),
                                 a_e_p10 = sum(comp_a & razao_p10 >= 0.5),
                                 so_a = sum(comp_a & razao_p10 < 0.5),
                                 so_p10 = sum(!comp_a & razao_p10 >= 0.5),
                                 spearman = round(cor(margem_gasto_qe, razao_p10, method = "spearman"), 3)),
           by = .(ano, cargo)][order(ano, cargo)]
print(conc)
fwrite(conc, file.path(dir_out, "gasto_concordancia_p10.csv"))

# 4. Figuras ---------------------------------------------------------------------------
cores <- c("Mulheres" = "#eb6834", "Homens" = "#8c8c8c",
           "Pessoas negras" = "#2a78d6", "Pessoas brancas" = "#b3b3b3", "Mulheres negras" = "#7a3e9d")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot", plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")

fe <- d[, .(ano, cargo, grupo = fifelse(mulher, "Mulheres", "Homens"),
            x = pmin(pmax(margem_gasto_qe, -1.5), 1.5))]
p1 <- ggplot(fe, aes(x = x, colour = grupo)) +
  geom_vline(xintercept = -0.1, colour = "grey70", linetype = "dashed", linewidth = 0.4) +
  geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.4) +
  stat_ecdf(linewidth = 0.7) +
  facet_grid(cargo ~ ano) +
  scale_colour_manual(values = cores, name = NULL) +
  scale_y_continuous(labels = function(x) paste0(100 * x, "%")) +
  labs(title = "Margem de gasto OLPR por gênero, cargo e ano",
       subtitle = paste("Distribuição acumulada dos reais que faltam (< 0) ou sobram (> 0) para",
                        "mudar o resultado numa distribuição feita pelo gasto, ÷ QE de gasto."),
       x = "Margem de gasto ÷ QE de gasto (valores truncados em ±1,5)",
       y = "% acumulado das candidaturas",
       caption = paste0("Fonte: TSE (prestação de contas final e votação). Margem pela regra de cada ano, ",
                        "com o gasto no lugar do voto; QE de gasto = gasto do distrito ÷ cadeiras.\n",
                        "Linha tracejada: −0,1 QE (banda de competitividade); sem DF.")) + tema
ggsave(file.path(dir_out, "gasto_margem_ecdf.png"), p1, width = 10, height = 6.5, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "gasto_margem_ecdf.pdf"), p1, width = 10, height = 6.5)

rot <- c(voto = "Voto (margem < 0,1 QE)", a_010 = "A: margem de gasto < 0,1 QE",
         d2_010 = "D2: dinheiro faltante < 0,1 QE", d3_050 = "D3: ≥ 0,5 do gasto do eleito marginal")
fc <- melt(comp[grupo %in% c("Mulheres", "Homens", "Pessoas negras", "Pessoas brancas")],
           id.vars = c("ano", "cargo", "grupo"), measure.vars = names(rot), variable.name = "medida")
fc[, medida := factor(rot[as.character(medida)], levels = rot)]
p2 <- ggplot(fc, aes(x = ano, y = value, colour = grupo)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.6) +
  facet_grid(cargo ~ medida, labeller = label_wrap_gen(24)) +
  scale_colour_manual(values = cores, name = NULL) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  labs(title = NULL,
       subtitle = "% das candidaturas aptas do grupo classificadas como competitivas em cada medida.",
       x = NULL, y = "% do grupo",
       caption = paste0("Fonte: TSE. Competitiva = eleita ou a menos de 0,1 QE do limiar (voto, A, D2); ",
                        "D3 = gasto ≥ 0,5 do último eleito da lista. Sem DF.\nEm 2014, 15–17% das aptas não ",
                        "têm registro de despesa e entram com gasto 0.")) + tema
ggsave(file.path(dir_out, "gasto_competitivas.png"), p2, width = 11, height = 6.5, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "gasto_competitivas.pdf"), p2, width = 11, height = 6.5)
