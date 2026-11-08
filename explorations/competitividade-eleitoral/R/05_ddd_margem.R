# =============================================================================
# 05 — A EC 111 aproximou mulheres e pessoas negras do limiar de eleição?
#
# Desenho: Deputado Federal (tratado a partir de 2022: votos em mulheres e pessoas negras
# contam em dobro na divisão do Fundo Partidário e do FEFC) × Deputado Estadual (controle),
# mesma UF; eleições 2014, 2018 (antes), 2022 e 2026 (depois). Sem DF.
#
# Principal (did::att_gt, padrão do projeto, .claude/rules/did-conventions.md):
#   unidade = UF × cargo (52), tratamento único em 2022 (não escalonado), nunca tratado = 0;
#   desfecho = DIFERENÇA entre grupos na % de candidaturas eleitas ou a menos de h QE do
#   limiar (mulheres − homens; negras − brancas). DiD da diferença = tripla diferença com
#   efeitos fixos de célula. Base universal (2018); e = −8 (2014) é pré-teste.
#   Bootstrap multiplicador, bandas uniformes, agrupamento por UF; sem peso e com peso
#   pelo número de candidaturas da célula.
# Conferência: tripla diferença por candidatura (fixest), EF UF×cargo×ano,
#   grupo×UF×cargo e grupo×ano, EP agrupados por UF.
#
# Entrada: data/processed/margem_resultado.rds
# Saída (explorations/competitividade-eleitoral/output/):
#   ddd_resultados.csv, ddd_twfe_candidatura.csv, ddd_estudo_evento.{png,pdf}
#
#   Rscript explorations/competitividade-eleitoral/R/05_ddd_margem.R
# =============================================================================
library(data.table)
library(did)
library(fixest)
library(ggplot2)
source(file.path("explorations", "ec111-did-2026", "R", "funcoes_persistencia.R"))
set.seed(20261013)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
n_boot  <- as.integer(Sys.getenv("BITERS", "25000"))   # 25000 na tese
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
d <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d[, federal := cd_cargo == 6L]
d[, branca := raca == "BRANCA"]

# Desfechos por candidatura: 1[eleita ou a menos de h do limiar] e 1[quase eleita]
desfechos <- list(
  ate_010   = quote(margem_qe >= -0.10),
  ate_025   = quote(margem_qe >= -0.25),
  ate_050   = quote(margem_qe >= -0.50),
  quase_025 = quote(margem_qe >= -0.25 & !eleito),
  eleita    = quote(eleito),
  # robustez: outras normalizações
  lss_0001  = quote(rv_lss >= -0.001),
  abd_010   = quote(rv_abd >= -0.10))
for (y in names(desfechos)) d[, (y) := as.numeric(eval(desfechos[[y]]))]

comparacoes <- list(
  "Mulheres − homens"           = list(g = quote(mulher), c = quote(!mulher)),
  "Pessoas negras − brancas"    = list(g = quote(negra), c = quote(branca)),
  "Mulheres negras − homens brancos" = list(g = quote(mulher & negra), c = quote(!mulher & branca)))

# Painel de células UF × cargo × ano com a diferença entre grupos (em pontos percentuais)
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
  # Persistência: ATT(2026) − ATT(2022), EP pela função de influência agregada por UF
  pr <- if (all(c(2022L, 2026L) %in% att$t)) {
    dif_att(att, 2022L, 2026L, cluster = cluster_de(att, "uf_id"))
  } else list(att = NA_real_, ep = NA_real_, ep_formula_t1 = NA_real_, ep_did_t1 = NA_real_)
  rbind(
    data.table(termo = paste0("e", din$egt), ano = 2022L + din$egt, att = din$att.egt,
               ep = din$se.egt, crit = din$crit.val.egt),
    data.table(termo = "ATT geral (2022 e 2026)", ano = NA_integer_, att = grp$overall.att,
               ep = grp$overall.se, crit = qnorm(0.975)),
    data.table(termo = "Dif. 2026 − 2022", ano = NA_integer_, att = pr$att, ep = pr$ep,
               crit = qnorm(0.975)),
    fill = TRUE)[, `:=`(ep_formula_2022 = pr$ep_formula_t1, ep_did_2022 = pr$ep_did_t1)][]
}

# --- Principal + robustez de amostra (sem UFs com 8 cadeiras federais) --------
pequenas <- res[cd_cargo == 6L & ano == 2022L, .(m = cadeiras[1]), by = uf][m == 8L, uf]
amostras <- list("Todas as UFs" = d, "Sem UFs com 8 cadeiras" = d[!uf %in% pequenas])

out <- rbindlist(lapply(names(amostras), function(am) {
  rbindlist(lapply(names(comparacoes), function(comp) {
    cel <- celulas(amostras[[am]], comp)
    stopifnot(cel[, .N, by = id][, all(N == 4L)])          # painel balanceado: 4 eleições
    rbindlist(lapply(names(desfechos), function(y) {
      rbindlist(lapply(c(FALSE, TRUE), function(pd) {
        estimar_did(cel, y, pd)[, `:=`(desfecho = y, comparacao = comp, ponderado = pd,
                                       amostra = am)]
      }))
    }))
  }))
}))
# --- Robustez: sem incumbentes (eleitas/os no mesmo cargo na eleição anterior) -----
# Só identificável de 2018 em diante (não há os eleitos de 2010), então esta versão usa
# 2018–2026, sem pré-teste. O CPF liga a pessoa entre eleições.
cpf11 <- function(x) {
  x <- gsub("\\D", "", as.character(x))
  ifelse(nchar(x) >= 9 & nchar(x) <= 11, formatC(x, width = 11, flag = "0"), NA_character_)
}
mapa_cpf <- rbindlist(c(
  lapply(c(2014L, 2018L, 2022L), function(a) {
    rbind(as.data.table(readRDS(file.path("data", "raw", sprintf("candidatos%d.rds", a)))),
          as.data.table(readRDS(file.path("data", "raw", sprintf("candidatos_estadual_%d.rds", a)))),
          fill = TRUE)[, .(ano = a, sq_candidato = as.character(sq_candidato), cpf = cpf11(cpfCand))]
  }),
  list(local({
    td <- tempfile(); dir.create(td)
    unzip(file.path("data", "raw", "tse", "consulta_cand_2026.zip"), "consulta_cand_2026_BRASIL.csv",
          exdir = td)
    fread(file.path(td, "consulta_cand_2026_BRASIL.csv"), encoding = "Latin-1",
          select = c("SQ_CANDIDATO", "NR_CPF_CANDIDATO"), colClasses = "character")[
      , .(ano = 2026L, sq_candidato = SQ_CANDIDATO, cpf = cpf11(NR_CPF_CANDIDATO))]
  }))))
mapa_cpf <- unique(mapa_cpf[!is.na(cpf)], by = c("ano", "sq_candidato"))
d <- merge(d, mapa_cpf, by = c("ano", "sq_candidato"), all.x = TRUE)
eleitos_cpf <- merge(res[eleito == TRUE, .(ano, sq_candidato, cd_cargo)], mapa_cpf,
                     by = c("ano", "sq_candidato"))[, .(ano = ano + 4L, cd_cargo, cpf, incumbente = TRUE)]
d <- merge(d, unique(eleitos_cpf), by = c("ano", "cd_cargo", "cpf"), all.x = TRUE)
d[is.na(incumbente), incumbente := FALSE]
message("Incumbentes identificados por ano e cargo:")
print(d[, .(incumbentes = sum(incumbente)), by = .(ano, cargo)][order(ano, cargo)])

out_inc <- rbindlist(lapply(names(comparacoes), function(comp) {
  cel <- celulas(d[ano >= 2018L & !incumbente], comp)
  rbindlist(lapply(c("ate_010", "ate_025", "ate_050", "quase_025", "eleita"), function(y) {
    estimar_did(cel, y, FALSE)[, `:=`(desfecho = y, comparacao = comp, ponderado = FALSE,
                                      amostra = "Sem incumbentes, 2018–2026")]
  }))
}))
out <- rbind(out, out_inc)

out[, `:=`(ic_inf = att - 1.96 * ep, ic_sup = att + 1.96 * ep,
           banda_inf = att - crit * ep, banda_sup = att + crit * ep)]
fwrite(out, file.path(dir_out, "ddd_resultados.csv"))

message("Principal (todas as UFs, sem peso), efeitos em pontos percentuais:")
print(out[amostra == "Todas as UFs" & !ponderado & desfecho %in% c("ate_010", "ate_025", "ate_050",
                                                                    "quase_025", "eleita"),
          .(comparacao, desfecho, termo, att = round(att, 2), ep = round(ep, 2),
            banda = sprintf("[%.2f, %.2f]", banda_inf, banda_sup))])

# --- Conferência: tripla diferença por candidatura (TWFE) --------------------
twfe <- rbindlist(lapply(c("ate_010", "ate_025", "ate_050", "quase_025", "eleita"), function(y) {
  f <- as.formula(paste0("I(100 * ", y, ") ~ i(ano, mulher_fed, ref = 2018) | ",
                         "uf^cargo^ano + mulher^uf^cargo + mulher^ano"))
  dd <- copy(d)[, mulher_fed := as.numeric(mulher & federal)]
  m <- feols(f, data = dd, cluster = ~uf)
  ct <- as.data.table(coeftable(m), keep.rownames = "termo")
  ct[, desfecho := y][]
}))
fwrite(twfe, file.path(dir_out, "ddd_twfe_candidatura.csv"))
message("Conferência TWFE por candidatura (mulheres):")
print(twfe[, .(desfecho, termo, est = round(Estimate, 2), ep = round(`Std. Error`, 2))])

# --- Figura: estudo de evento, principal -------------------------------------
rot_y <- c(ate_010 = "Eleita ou a < 0,1 QE do limiar", ate_025 = "Eleita ou a < 0,25 QE",
           ate_050 = "Eleita ou a < 0,5 QE", quase_025 = "Quase eleita (falta < 0,25 QE)",
           eleita = "Eleita")
fig <- out[amostra == "Todas as UFs" & !ponderado & desfecho %in% names(rot_y) & !is.na(ano)]
fig[, desfecho := factor(rot_y[desfecho], levels = rot_y)]
fig[, comparacao := factor(comparacao, levels = names(comparacoes))]
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot", plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")
p <- ggplot(fig, aes(x = ano, y = att)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_vline(xintercept = 2020, colour = "grey70", linetype = "dashed", linewidth = 0.4) +
  geom_errorbar(aes(ymin = banda_inf, ymax = banda_sup), width = 0, colour = "#eb6834",
                alpha = 0.35, linewidth = 2.2) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.6, colour = "#eb6834",
                linewidth = 0.6) +
  geom_point(colour = "#eb6834", size = 1.8) +
  facet_grid(comparacao ~ desfecho, labeller = label_wrap_gen(22)) +
  scale_x_continuous(breaks = c(2014, 2018, 2022, 2026)) +
  labs(title = NULL, subtitle = NULL,
       x = NULL, y = "Efeito estimado (pontos percentuais)",
       caption = paste0("Fonte: TSE. did::att_gt (Callaway & Sant'Anna), unidade UF × cargo, sem DF, ",
                        "sem peso; base universal 2018.\nTraço fino: IC 95% pontual; faixa larga: ",
                        "banda uniforme 95% (bootstrap multiplicador, ", n_boot,
                        " repetições, agrupado por UF).")) + tema
ggsave(file.path(dir_out, "ddd_estudo_evento.png"), p, width = 11, height = 7, dpi = 300, bg = "white")
ggsave(file.path(dir_out, "ddd_estudo_evento.pdf"), p, width = 11, height = 7)
