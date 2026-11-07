# =============================================================================
# 10 — Sensibilidade a violações de tendências paralelas (Rambachan & Roth 2023, HonestDiD)
#
# Estudo de evento por célula UF × cargo (como nos scripts 05/07): Federal tratado em 2022,
# Estadual nunca tratado, base universal 2018, sem DF. Coeficientes: e = −8 (2014, único
# período anterior), e = 0 (2022), e = 4 (2026). A variância vem das funções de influência
# do did::aggte, agregadas por UF (agrupamento por UF, 27 grupos).
#
# Restrições:
#   Magnitudes relativas (RM): a violação de tendências paralelas depois de 2018 é no máximo
#     M̄ vezes a violação observada entre 2014 e 2018. M̄ = 1: tão grande quanto a pré.
#   Suavidade (SD): a tendência diferencial muda de inclinação no máximo M p.p. por eleição.
# Valor de quebra: o maior M̄ (ou M) em que o IC robusto de 95% ainda exclui o zero.
# Alvo: média de 2022 e 2026 (l_vec = (½, ½)) e cada ano separadamente.
#
# Ressalva: 2014–2018 é outro regime de financiamento (doações empresariais até 2014; FEFC e
# reserva de 30% para mulheres a partir de 2018). Em RM, a violação de 2014 é só a régua de
# tamanho; a pergunta é "quão maior que aquela a violação pós-2018 precisaria ser".
#
# Entrada: data/processed/margem_resultado.rds
# Saída (explorations/competitividade-eleitoral/output/):
#   honestdid_estudo_evento.csv, honestdid_sensibilidade.csv, honestdid_quebra.csv,
#   honestdid_sensibilidade.{png,pdf}
#
#   Rscript explorations/competitividade-eleitoral/R/10_honestdid.R
# =============================================================================
library(data.table)
library(did)
library(HonestDiD)
library(ggplot2)
set.seed(20261014)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
d <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d[, `:=`(federal = cd_cargo == 6L, comp = margem_qe >= -0.10, branca = raca == "BRANCA")]
d[, nc := !comp]

grupos <- list(mulheres = list(g = quote(mulher), c = quote(!mulher)),
               negras   = list(g = quote(negra),  c = quote(branca)))
celulas <- function(nome) {
  gq <- grupos[[nome]]
  d[, {
    g <- eval(gq$g); cc <- eval(gq$c); M <- cadeiras[1]
    list(cadeiras = M,
         dif_pct_comp = 100 * (mean(comp[g]) - mean(comp[cc])),
         dif_pct_eleita = 100 * (mean(eleito[g]) - mean(eleito[cc])),
         pct_grupo_entre_comp = 100 * sum(comp & g) / sum(comp & (g | cc)),
         nc_por_cadeira_grupo = sum(nc & g) / M,
         dif_nc_por_cadeira = (sum(nc & g) - sum(nc & cc)) / M)
  }, by = .(uf, cargo, federal, ano)][
    , `:=`(id = as.integer(factor(paste(uf, cargo))), uf_id = as.integer(factor(uf)),
           g = fifelse(federal, 2022L, 0L))][]
}
rotulos <- c(dif_pct_comp = "Taxa de competitivas (grupo − complemento, p.p.)",
             dif_pct_eleita = "Taxa de eleitas (grupo − complemento, p.p.)",
             pct_grupo_entre_comp = "% do grupo entre as competitivas",
             nc_por_cadeira_grupo = "Não competitivas do grupo por cadeira",
             dif_nc_por_cadeira = "Não competitivas por cadeira (grupo − complemento)")

# Estudo de evento + matriz de variância agrupada por UF a partir das funções de influência
estudo_evento <- function(cel, y, peso) {
  att <- att_gt(yname = y, tname = "ano", idname = "id", gname = "g", data = as.data.frame(cel),
                control_group = "nevertreated", base_period = "universal", est_method = "dr",
                bstrap = FALSE, weightsname = if (peso) "cadeiras" else NULL, print_details = FALSE)
  es <- aggte(att, type = "dynamic", bstrap = FALSE, na.rm = TRUE)
  manter <- es$egt != -4L                                   # 2018 = referência (fixa em 0)
  psi <- es$inf.function$dynamic.inf.func.e[, manter, drop = FALSE]
  ids <- sort(unique(cel$id))
  clus <- cel[match(ids, id), uf_id]
  n <- length(ids)
  V <- crossprod(rowsum(psi, clus)) / n^2                   # agrupado por UF
  list(e = es$egt[manter], beta = es$att.egt[manter], V = V)
}

# Valor de quebra: maior M em que o IC robusto exclui o zero (NA se nem o original exclui)
quebra <- function(s) {
  if (all(is.na(s$lb))) return(NA_real_)
  ok <- s$lb > 0 | s$ub < 0
  if (!ok[1]) return(NA_real_)
  if (all(ok)) return(Inf)
  s$M[which(!ok)[1] - 1L]
}

alvos <- list("média 2022 e 2026" = c(0.5, 0.5), "2022" = c(1, 0), "2026" = c(0, 1))
Mbar <- seq(0, 2, by = 0.25)
Msd  <- seq(0, 4, by = 0.5)

ee <- list(); sens <- list(); qb <- list()
for (nome in names(grupos)) {
  cel <- celulas(nome)
  stopifnot(cel[, .N, by = id][, all(N == 4L)])
  for (y in names(rotulos)) for (peso in c(TRUE, FALSE)) {
    r <- estudo_evento(cel, y, peso)
    stopifnot(length(r$e) == 3L, all(r$e == c(-8, 0, 4)))
    pr <- if (peso) "magnitude" else "sem peso"
    ee[[length(ee) + 1L]] <- data.table(grupo = nome, desfecho = y, peso = pr, ano = 2022L + r$e,
                                        att = r$beta, ep = sqrt(diag(r$V)))
    for (a in names(alvos)) {
      l <- alvos[[a]]
      orig <- as.data.frame(constructOriginalCS(betahat = r$beta, sigma = r$V, numPrePeriods = 1,
                                                numPostPeriods = 2, l_vec = l))
      # grade explícita: a padrão pode ficar estreita ("CI is open at one of the endpoints")
      est_l <- sum(l * r$beta[2:3]); se_l <- sqrt(drop(t(l) %*% r$V[2:3, 2:3] %*% l))
      larg <- 10 * se_l + 3 * abs(r$beta[1]) * max(Mbar)
      rm <- suppressWarnings(createSensitivityResults_relativeMagnitudes(
        betahat = r$beta, sigma = r$V, numPrePeriods = 1, numPostPeriods = 2, Mbarvec = Mbar,
        l_vec = l, grid.lb = est_l - larg, grid.ub = est_l + larg, gridPoints = 2000))
      # método C-LF (condicional híbrido): o FLCI padrão exige CVXR >= 1.0-12, indisponível
      # para o R 4.2 desta máquina sem atualizar o Matrix
      # Com um único período anterior a restrição de suavidade é degenerada e o método
      # condicional pode não ter solução numérica; nesse caso fica registrada como NA.
      sd <- tryCatch(createSensitivityResults(betahat = r$beta, sigma = r$V, numPrePeriods = 1,
                                              numPostPeriods = 2, Mvec = Msd, l_vec = l,
                                              method = "C-LF", grid.lb = est_l - larg - 10 * max(Msd),
                                              grid.ub = est_l + larg + 10 * max(Msd), gridPoints = 2000),
                     error = function(e) data.frame(M = Msd, lb = NA_real_, ub = NA_real_))
      rm <- as.data.table(rm)[, .(M = Mbar, lb, ub, restricao = "RM (M̄)")]
      sd <- as.data.table(sd)[, .(M, lb, ub, restricao = "Suavidade (M, p.p.)")]
      s <- rbindlist(list(data.table(M = NA_real_, lb = orig$lb[1], ub = orig$ub[1],
                                     restricao = "Original"), rm, sd), use.names = TRUE, fill = TRUE)
      s[, `:=`(grupo = nome, desfecho = y, peso = pr, alvo = a)]
      sens[[length(sens) + 1L]] <- s
      qb[[length(qb) + 1L]] <- data.table(
        grupo = nome, desfecho = y, peso = pr, alvo = a,
        est = sum(l * r$beta[2:3]),
        ic_original = sprintf("[%.2f; %.2f]", orig$lb, orig$ub),
        quebra_RM = quebra(rm), quebra_SD = quebra(sd))
    }
  }
}
ee <- rbindlist(ee); sens <- rbindlist(sens); qb <- rbindlist(qb)
fwrite(ee, file.path(dir_out, "honestdid_estudo_evento.csv"))
fwrite(sens, file.path(dir_out, "honestdid_sensibilidade.csv"))
fwrite(qb, file.path(dir_out, "honestdid_quebra.csv"))
print(qb[alvo == "média 2022 e 2026", .(grupo, desfecho, peso, est = round(est, 2), ic_original,
                                         quebra_RM, quebra_SD)], nrows = 100)

# Figura: IC robusto (RM) para a média de 2022 e 2026, peso pela magnitude
fig <- sens[alvo == "média 2022 e 2026" & peso == "magnitude" & restricao %in% c("Original", "RM (M̄)") &
              desfecho %in% c("dif_pct_comp", "pct_grupo_entre_comp", "nc_por_cadeira_grupo")]
fig[restricao == "Original", M := -0.25]
fig[, desfecho := factor(rotulos[desfecho], levels = rotulos)]
fig[, grupo := factor(grupo, levels = c("mulheres", "negras"),
                      labels = c("Mulheres (vs. homens)", "Pessoas negras (vs. brancas)"))]
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot", plot.caption = element_text(colour = "grey40", hjust = 0))
p <- ggplot(fig, aes(x = M, ymin = lb, ymax = ub, colour = restricao == "Original")) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(width = 0.12, linewidth = 0.7) +
  facet_grid(desfecho ~ grupo, scales = "free_y", labeller = label_wrap_gen(28)) +
  scale_colour_manual(values = c(`TRUE` = "#8c8c8c", `FALSE` = "#eb6834"), guide = "none") +
  scale_x_continuous(breaks = c(-0.25, seq(0, 2, 0.5)), labels = c("Orig.", seq(0, 2, 0.5))) +
  labs(title = "Sensibilidade a violações de tendências paralelas (HonestDiD, magnitudes relativas)",
       subtitle = paste("IC robusto de 95% para o efeito médio de 2022 e 2026. M̄ = quantas vezes",
                        "a violação pós-2018 pode exceder a observada de 2014 para 2018."),
       x = "M̄", y = NULL,
       caption = paste0("Fonte: TSE. Estudo de evento did::att_gt por UF × cargo, sem DF, peso = cadeiras ",
                        "do distrito; variância agrupada por UF.\nRambachan & Roth (2023). Cinza: IC ",
                        "original (sem violação). 2014–2018 é outro regime de financiamento de campanha.")) +
  tema
ggsave(file.path(dir_out, "honestdid_sensibilidade.png"), p, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "honestdid_sensibilidade.pdf"), p, width = 10, height = 8, device = cairo_pdf)
