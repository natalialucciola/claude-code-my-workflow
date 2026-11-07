# =============================================================================
# 14 — A EC 111 aproximou mulheres e pessoas negras do limiar pelo GASTO?
#
# Mesmo desenho do R/05: Deputado Federal (tratado a partir de 2022) × Estadual (controle),
# mesma UF, sem DF; did::att_gt com unidade UF × cargo (52), tratamento em 2022, nunca
# tratado = 0, base universal 2018; desfecho = diferença entre grupos (p.p.) na % de
# candidaturas competitivas. Bootstrap multiplicador, bandas uniformes, agrupado por UF;
# sem peso e com peso pelo número de candidaturas da célula.
#
# Eleições 2014, 2018 e 2022 (a prestação final de 2026 ainda não saiu).
# ATENÇÃO — 2014 (e = −8): decisão da autora (2026-09-28) de que 2014 não serve de
# referência de tendência para recursos (fim da doação empresarial em 2015). O coeficiente
# é reportado com pre_teste_valido = FALSE; a leitura principal é 2018 → 2022.
#
# Desfechos (competitiva = eleita ou a menos de 0,1 QE do limiar):
#   a_010, a_025, a_eleita : medida A (margem de gasto OLPR), principal
#   d2_010, d2c_010        : D2 (dinheiro faltante; e por gênero e e comum)
#   d3_050                 : D3 ≥ 0,5 do gasto do eleito marginal da lista
#   so_gasto               : competitiva pelo gasto (A) e não pelo voto (dinheiro sem voto)
#   voto_010               : margem de votos, na mesma amostra (referência)
#
# Entrada: data/processed/margem_gasto_medidas.rds (R/12)
# Saída:   output/ddd_gasto_resultados.csv, output/ddd_gasto_estudo_evento.{png,pdf}
#
#   Rscript explorations/competitividade-eleitoral/R/14_ddd_gasto.R
# =============================================================================
library(data.table)
library(did)
library(ggplot2)
set.seed(20261014)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
n_boot  <- 25000L
d <- readRDS(file.path("data", "processed", "margem_gasto_medidas.rds"))
d <- d[cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe)]
d[, federal := cd_cargo == 6L]
d[, branca := raca == "BRANCA"]

desfechos <- list(
  a_010    = quote(margem_gasto_qe >= -0.10),
  a_025    = quote(margem_gasto_qe >= -0.25),
  a_eleita = quote(eleito_gasto),
  d2_010   = quote(!is.na(d2_qe) & d2_qe >= -0.10),
  d2c_010  = quote(!is.na(d2_comum_qe) & d2_comum_qe >= -0.10),
  d3_050   = quote(!is.na(d3) & d3 >= 0.5),
  so_gasto = quote(margem_gasto_qe >= -0.10 & margem_qe < -0.10),
  voto_010 = quote(margem_qe >= -0.10))
for (y in names(desfechos)) d[, (y) := as.numeric(eval(desfechos[[y]]))]

comparacoes <- list(
  "Mulheres − homens"                = list(g = quote(mulher), c = quote(!mulher)),
  "Pessoas negras − brancas"         = list(g = quote(negra), c = quote(branca)),
  "Mulheres negras − homens brancos" = list(g = quote(mulher & negra), c = quote(!mulher & branca)))

celulas <- function(dd, comp) {
  gq <- comparacoes[[comp]]
  a <- dd[(eval(gq$g)), c(lapply(.SD, mean), list(n_g = .N)), by = .(uf, cargo, federal, ano),
          .SDcols = names(desfechos)]
  b <- dd[(eval(gq$c)), c(lapply(.SD, mean), list(n_c = .N)), by = .(uf, cargo, federal, ano),
          .SDcols = names(desfechos)]
  m <- merge(a, b, by = c("uf", "cargo", "federal", "ano"), suffixes = c("_g", "_c"))
  for (y in names(desfechos)) m[, (y) := 100 * (get(paste0(y, "_g")) - get(paste0(y, "_c")))]
  m[, `:=`(id = as.integer(factor(paste(uf, cargo))), uf_id = as.integer(factor(uf)),
           g = fifelse(federal, 2022L, 0L), peso = n_g + n_c)]
  m[]
}

estimar_did <- function(cel, y, ponderado) {
  att <- att_gt(yname = y, tname = "ano", idname = "id", gname = "g", data = as.data.frame(cel),
                control_group = "nevertreated", base_period = "universal", est_method = "dr",
                bstrap = TRUE, cband = TRUE, biters = n_boot, clustervars = c("id", "uf_id"),
                weightsname = if (ponderado) "peso" else NULL, print_details = FALSE)
  din <- aggte(att, type = "dynamic", cband = TRUE, biters = n_boot, na.rm = TRUE)
  grp <- aggte(att, type = "group", cband = TRUE, biters = n_boot, na.rm = TRUE)
  rbind(
    data.table(termo = paste0("e", din$egt), ano = 2022L + din$egt, att = din$att.egt,
               ep = din$se.egt, crit = din$crit.val.egt),
    data.table(termo = "ATT geral (2022)", ano = NA_integer_, att = grp$overall.att,
               ep = grp$overall.se, crit = qnorm(0.975)))
}

out <- rbindlist(lapply(names(comparacoes), function(comp) {
  cel <- celulas(d, comp)
  stopifnot(cel[, .N, by = id][, all(N == 3L)])            # painel balanceado: 3 eleições
  rbindlist(lapply(names(desfechos), function(y) {
    rbindlist(lapply(c(FALSE, TRUE), function(pd) {
      estimar_did(cel, y, pd)[, `:=`(desfecho = y, comparacao = comp, ponderado = pd)]
    }))
  }))
}))
out[, `:=`(ic_inf = att - 1.96 * ep, ic_sup = att + 1.96 * ep,
           banda_inf = att - crit * ep, banda_sup = att + crit * ep,
           pre_teste_valido = fifelse(ano %in% 2014L, FALSE, NA))]
fwrite(out, file.path(dir_out, "ddd_gasto_resultados.csv"))

message("Efeito 2018 → 2022 e coeficiente de 2014 (sinalizado), sem peso, em p.p.:")
print(dcast(out[!ponderado & !is.na(ano) & ano != 2018L],
            comparacao + desfecho ~ ano,
            value.var = c("att", "ep"), fun.aggregate = function(x) round(x, 2))[
  order(comparacao, desfecho)])

# --- Figura: estudo de evento (sem peso), medidas de gasto + voto de referência -----------
rot_y <- c(voto_010 = "Voto: eleita ou < 0,1 QE (referência)", a_010 = "A: margem de gasto < 0,1 QE",
           d2_010 = "D2: dinheiro faltante < 0,1 QE", d3_050 = "D3: ≥ 0,5 do eleito marginal",
           so_gasto = "Competitiva só pelo gasto")
fig <- out[!ponderado & desfecho %in% names(rot_y) & !is.na(ano)]
fig[, desfecho := factor(rot_y[desfecho], levels = rot_y)]
fig[, comparacao := factor(comparacao, levels = names(comparacoes))]
fig[, periodo := fifelse(ano == 2014L, "2014 (sem leitura de pré-teste)", "2018 (base) e 2022")]
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot", plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")
cor_p <- c("2014 (sem leitura de pré-teste)" = "#9a9890", "2018 (base) e 2022" = "#eb6834")
p <- ggplot(fig, aes(x = ano, y = att, colour = periodo)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_vline(xintercept = 2020, colour = "grey70", linetype = "dashed", linewidth = 0.4) +
  geom_errorbar(aes(ymin = banda_inf, ymax = banda_sup), width = 0, alpha = 0.35, linewidth = 2.2) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.6, linewidth = 0.6) +
  geom_point(size = 1.8) +
  facet_grid(comparacao ~ desfecho, labeller = label_wrap_gen(22)) +
  scale_colour_manual(values = cor_p, name = NULL) +
  scale_x_continuous(breaks = c(2014, 2018, 2022)) +
  labs(title = "EC 111 e a competitividade pelo gasto: estudo de evento",
       subtitle = paste("Tripla diferença: diferença entre grupos (p.p.), federal menos estadual,",
                        "relativa a 2018. 2022 é a eleição sob a EC."),
       x = NULL, y = "Efeito estimado (pontos percentuais)",
       caption = paste0("Fonte: TSE. did::att_gt (Callaway & Sant'Anna), unidade UF × cargo, sem DF, ",
                        "sem peso; base universal 2018. Traço fino: IC 95% pontual; faixa larga: banda\n",
                        "uniforme 95% (bootstrap multiplicador, ", n_boot, " repetições, agrupado por UF). ",
                        "2014 não é lido como pré-teste para recursos (fim da doação empresarial em 2015).")) +
  tema
ggsave(file.path(dir_out, "ddd_gasto_estudo_evento.png"), p, width = 12, height = 7, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "ddd_gasto_estudo_evento.pdf"), p, width = 12, height = 7)
