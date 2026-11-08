# =============================================================================
# 04 — Descritivo: quão perto do limiar de eleição estão mulheres e pessoas negras
#
# Entrada: data/processed/margem_resultado.rds (script 03)
# Saída (explorations/competitividade-eleitoral/output/):
#   descr_faixas_margem.csv       % de candidaturas por faixa de margem/QE, grupo, cargo, ano
#   descr_faixas_margem.{png,pdf} figura correspondente
#   descr_proximas_limiar.csv     % eleitas e % a menos de h do QE, por grupo, cargo, ano
#
# Amostra: candidaturas aptas a Deputado Federal e Estadual, sem DF (como no desenho
# Federal × Estadual da tese; Distrital não tem gênero/raça de 2014 a 2022 nas bases).
#
#   Rscript explorations/competitividade-eleitoral/R/04_descritivo_margens.R
# =============================================================================
library(data.table)
library(ggplot2)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
d <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d[, cargo := factor(cargo, levels = c("Federal", "Estadual"))]

# Faixas de margem em unidades de QE (negativa = falta; positiva = sobra)
cortes <- c(-Inf, -0.5, -0.25, -0.1, 0, 0.1, 0.25, 0.5, Inf)
rotulos <- c("falta > 0,5 QE", "falta 0,25–0,5", "falta 0,1–0,25", "falta < 0,1",
             "sobra < 0,1", "sobra 0,1–0,25", "sobra 0,25–0,5", "sobra > 0,5")
d[, faixa := cut(margem_qe, cortes, labels = rotulos, right = FALSE)]

grupos <- list(Mulheres = quote(mulher), Homens = quote(!mulher),
               `Pessoas negras` = quote(negra), `Pessoas brancas` = quote(raca == "BRANCA"))
por_grupo <- function(expr_fun) {
  rbindlist(lapply(names(grupos), function(g) {
    d[(eval(grupos[[g]])), expr_fun(.SD), by = .(ano, cargo)][, grupo := g][]
  }))
}

# 1. Distribuição por faixa
faixas <- por_grupo(function(x) x[, .N, by = faixa][, pct := 100 * N / sum(N)][])
fwrite(faixas[order(grupo, cargo, ano, faixa)], file.path(dir_out, "descr_faixas_margem.csv"))

# 2. Proporção eleita e próxima do limiar (bandas h do plano)
bandas <- c(0.1, 0.25, 0.5)
prox <- por_grupo(function(x) {
  data.table(n = nrow(x), pct_eleitas = 100 * mean(x$eleito),
             pct_ate_010 = 100 * mean(x$margem_qe >= -0.10),
             pct_ate_025 = 100 * mean(x$margem_qe >= -0.25),
             pct_ate_050 = 100 * mean(x$margem_qe >= -0.50),
             pct_quase_010 = 100 * mean(x$margem_qe >= -0.10 & !x$eleito),
             pct_quase_025 = 100 * mean(x$margem_qe >= -0.25 & !x$eleito),
             mediana_margem_qe = median(x$margem_qe))
})
fwrite(prox[order(grupo, cargo, ano)], file.path(dir_out, "descr_proximas_limiar.csv"))
print(prox[grupo %in% c("Mulheres", "Homens"),
           .(grupo, cargo, ano, n, pct_eleitas = round(pct_eleitas, 1),
             pct_ate_025 = round(pct_ate_025, 1), pct_quase_025 = round(pct_quase_025, 1),
             mediana = round(mediana_margem_qe, 3))][order(cargo, grupo, ano)])

# 3. Figura: % por faixa perto do limiar (exclui as duas faixas extremas)
cores <- c("Mulheres" = "#eb6834", "Homens" = "#8c8c8c",
           "Pessoas negras" = "#2a78d6", "Pessoas brancas" = "#b3b3b3")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top",
        axis.text.x = element_text(angle = 30, hjust = 1))
fig <- faixas[!faixa %in% c("falta > 0,5 QE", "sobra > 0,5")]
fig[, painel := fifelse(grupo %in% c("Mulheres", "Homens"), "Gênero", "Raça")]
p <- ggplot(fig, aes(x = faixa, y = pct, fill = grupo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  facet_grid(painel + cargo ~ ano) +
  scale_fill_manual(values = cores, name = NULL) +
  labs(title = "Candidaturas perto do limiar de eleição, por grupo, cargo e ano",
       subtitle = paste("% das candidaturas aptas do grupo em cada faixa de margem de votos,",
                        "em unidades do quociente eleitoral (QE)."),
       x = "Margem de votos (votos que faltam ou sobram para mudar o resultado ÷ QE)",
       y = "% das candidaturas do grupo",
       caption = paste0("Fonte: TSE (votação por candidato e por partido). Margem calculada refazendo a ",
                        "distribuição de cadeiras com a regra de cada ano; sem DF.\nAs faixas extremas ",
                        "(falta > 0,5 QE e sobra > 0,5 QE) não aparecem.")) + tema
# Versão da tese: sem título/subtítulo embutidos (a legenda do Quarto cumpre esse papel)
p <- p + labs(title = NULL, subtitle = NULL)
ggsave(file.path(dir_out, "descr_faixas_margem.png"), p, width = 11, height = 8.5, dpi = 300,
       bg = "white")
ggsave(file.path(dir_out, "descr_faixas_margem.pdf"), p, width = 11, height = 8.5)
