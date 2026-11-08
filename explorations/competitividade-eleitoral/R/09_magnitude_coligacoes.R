# =============================================================================
# 09 — O fim das coligações explica a expansão de candidaturas no Federal?
#
# Hipótese: com o fim das coligações proporcionais (EC 97/2017, a partir de 2020) e o
# limite de M + 1 candidaturas por partido (Lei 14.211/2021), o número de candidaturas
# por cadeira cresce mais nos distritos de magnitude (M) pequena — e o Federal tem
# magnitudes menores que o Estadual da mesma UF. Se for isso, a variação 2018 → 2022 é
# função da magnitude, igual nos dois cargos; comparando distritos de mesma magnitude, a
# diferença Federal − Estadual some.
#
# Teste, por distrito (UF × cargo, sem DF):
#   Δy = a + b·log(M) + c·Federal + ε      (Δ entre 2018 e o ano t)
#   c ≈ 0 depois de controlar log(M)  →  a magnitude explica o "excesso" do Federal.
# Também: só na faixa de magnitude comum aos dois cargos (24 ≤ M ≤ 70); 2014 → 2018 como
# placebo (havia coligações nos dois anos). EP agrupados por UF.
#
# Entrada: data/processed/margem_resultado.rds
# Saída (explorations/competitividade-eleitoral/output/):
#   magnitude_distritos.csv, magnitude_regressoes.csv, magnitude_candidaturas.{png,pdf}
#
#   Rscript explorations/competitividade-eleitoral/R/09_magnitude_coligacoes.R
# =============================================================================
library(data.table)
library(fixest)
library(ggplot2)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
d <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d[, `:=`(comp = margem_qe >= -0.10)]
d[, nc := !comp]

dist <- d[, .(M = cadeiras[1], listas = uniqueN(sq_lista),
              cand_por_cadeira = .N / cadeiras[1],
              listas_por_cadeira = uniqueN(sq_lista) / cadeiras[1],
              nc_mulheres_por_cadeira = sum(nc & mulher) / cadeiras[1],
              nc_homens_por_cadeira = sum(nc & !mulher) / cadeiras[1],
              dif_pct_comp = 100 * (mean(comp[mulher]) - mean(comp[!mulher])),
              pct_mulheres_entre_comp = 100 * mean(mulher[comp])),
          by = .(uf, cargo, ano)]
fwrite(dist[order(cargo, uf, ano)], file.path(dir_out, "magnitude_distritos.csv"))

desfechos <- c("cand_por_cadeira", "listas_por_cadeira", "nc_mulheres_por_cadeira",
               "nc_homens_por_cadeira", "dif_pct_comp", "pct_mulheres_entre_comp")
largo <- dcast(dist, uf + cargo + M ~ ano, value.var = desfechos)
largo[, `:=`(federal = as.integer(cargo == "Federal"), log_M = log(M))]

regs <- rbindlist(lapply(desfechos, function(y) {
  rbindlist(lapply(list(c(2014L, 2018L), c(2018L, 2022L), c(2018L, 2026L)), function(p) {
    largo[, dy := get(paste0(y, "_", p[2])) - get(paste0(y, "_", p[1]))]
    rbindlist(lapply(c("Todas", "Magnitude comum (24–70)"), function(am) {
      dd <- if (am == "Todas") largo else largo[M >= 24 & M <= 70]
      rbindlist(lapply(list(sem_M = dy ~ federal, com_M = dy ~ federal + log_M), function(f) {
        m <- feols(f, data = dd, cluster = ~uf)
        ct <- coeftable(m)
        data.table(desfecho = y, periodo = paste(p, collapse = "→"), amostra = am,
                   modelo = if ("log_M" %in% all.vars(f)) "com log(M)" else "sem log(M)",
                   n = nobs(m), n_federal = sum(dd$federal),
                   coef_federal = ct["federal", "Estimate"], ep_federal = ct["federal", "Std. Error"],
                   coef_logM = if ("log_M" %in% rownames(ct)) ct["log_M", "Estimate"] else NA_real_,
                   ep_logM = if ("log_M" %in% rownames(ct)) ct["log_M", "Std. Error"] else NA_real_)
      }))
    }))
  }))
}))
fwrite(regs, file.path(dir_out, "magnitude_regressoes.csv"))
regs[, fed := sprintf("%.2f (%.2f)%s", coef_federal, ep_federal,
                      fifelse(abs(coef_federal / ep_federal) > 1.96, "*", ""))]
regs[, lm := fifelse(is.na(coef_logM), "", sprintf("%.2f (%.2f)%s", coef_logM, ep_logM,
                     fifelse(abs(coef_logM / ep_logM) > 1.96, "*", "")))]
print(regs[, .(desfecho, periodo, amostra, modelo, n, n_federal, federal = fed, log_M = lm)],
      nrows = 200)

# Figura: variação 2018 → 2022 em candidaturas por cadeira × magnitude, por cargo
fig <- largo[, .(uf, cargo, M, d_cand = cand_por_cadeira_2022 - cand_por_cadeira_2018,
                 d_nc_h = nc_homens_por_cadeira_2022 - nc_homens_por_cadeira_2018,
                 d_nc_m = nc_mulheres_por_cadeira_2022 - nc_mulheres_por_cadeira_2018)]
fig <- melt(fig, id.vars = c("uf", "cargo", "M"), variable.name = "medida", value.name = "delta")
fig[, medida := factor(medida, levels = c("d_cand", "d_nc_h", "d_nc_m"),
                       labels = c("Candidaturas aptas por cadeira", "Homens não competitivos por cadeira",
                                  "Mulheres não competitivas por cadeira"))]
fig[, cargo := factor(cargo, levels = c("Federal", "Estadual"))]
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot", plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")
p <- ggplot(fig, aes(x = M, y = delta, colour = cargo)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  annotate("rect", xmin = 24, xmax = 70, ymin = -Inf, ymax = Inf, fill = "grey92", alpha = 0.6) +
  geom_point(size = 1.8, alpha = 0.85) +
  geom_smooth(method = "lm", formula = y ~ log(x), se = FALSE, linewidth = 0.7) +
  facet_wrap(~medida, ncol = 3, scales = "free_y") +
  scale_x_log10(breaks = c(8, 16, 24, 36, 50, 70, 94)) +
  scale_colour_manual(values = c("Federal" = "#eb6834", "Estadual" = "#2a78d6"), name = NULL) +
  labs(title = "Variação de 2018 para 2022 por magnitude do distrito",
       subtitle = paste("Cada ponto é um distrito (UF × cargo). Se o fim das coligações explicasse",
                        "o excesso do Federal, os dois cargos seguiriam a mesma curva."),
       x = "Magnitude (cadeiras em disputa, escala log)", y = "Variação de 2018 para 2022",
       caption = paste0("Fonte: TSE. Candidaturas aptas a Deputado Federal e Estadual, sem DF. ",
                        "Não competitiva: não eleita e a mais de 0,1 QE do limiar.\nFaixa cinza: ",
                        "magnitudes comuns aos dois cargos (24–70). Linhas: ajuste linear em log(M).")) +
  tema
# Versão da tese: sem título/subtítulo embutidos (a legenda do Quarto cumpre esse papel)
p <- p + labs(title = NULL, subtitle = NULL)
ggsave(file.path(dir_out, "magnitude_candidaturas.png"), p, width = 11, height = 4.5, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "magnitude_candidaturas.pdf"), p, width = 11, height = 4.5)
