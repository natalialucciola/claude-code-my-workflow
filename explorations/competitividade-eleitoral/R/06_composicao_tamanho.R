# =============================================================================
# 06 — (a) Composição das candidaturas competitivas: que parte é feminina (negra)?
#      (b) Tamanho do distrito como controle (tendências paralelas condicionais ao
#          eleitorado da UF) em vez de peso
#
# Competitiva = eleita ou a menos de 0,1 QE do limiar (desfecho principal do script 05).
# Desfecho por célula UF × cargo × ano: % de mulheres (pessoas negras) entre as
# competitivas. Mesmo desenho do 05: did::att_gt, Federal tratado em 2022, Estadual
# nunca tratado, base universal 2018, sem DF, bandas uniformes, agrupado por UF.
# Versões: sem peso; peso = nº de competitivas na célula; controle log(eleitorado da UF)
# (xformla, doubly robust). O eleitorado é o mesmo nos dois cargos da UF, então o
# controle compara Federal e Estadual de UFs de tamanho parecido, com sobreposição total.
#
# Entrada: data/processed/margem_resultado.rds
# Saída:   explorations/competitividade-eleitoral/output/composicao_{descritivo,did}.csv
#
#   Rscript explorations/competitividade-eleitoral/R/06_composicao_tamanho.R
# =============================================================================
library(data.table)
library(did)
set.seed(20261014)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
n_boot  <- 25000L
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
d <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d[, `:=`(federal = cd_cargo == 6L, competitiva = margem_qe >= -0.10)]

# (a) Descritivo: participação dos grupos entre todas as candidaturas e entre as competitivas
descr <- d[, .(pct_mulheres_cand = 100 * mean(mulher), pct_mulheres_comp = 100 * mean(mulher[competitiva]),
               pct_negras_cand = 100 * mean(negra), pct_negras_comp = 100 * mean(negra[competitiva]),
               n_comp = sum(competitiva)), by = .(cargo, ano)][order(cargo, ano)]
fwrite(descr, file.path(dir_out, "composicao_descritivo.csv"))
print(descr[, lapply(.SD, function(x) round(x, 1)), by = .(cargo, ano)])

# (b) Painel de células
cel <- d[(competitiva), .(pct_mulheres_comp = 100 * mean(mulher), pct_negras_comp = 100 * mean(negra),
                          n_comp = .N), by = .(uf, cargo, federal, ano)]
cel <- merge(cel, res[cd_cargo == 6L, .(log_eleitorado = log(eleitorado[1])), by = .(uf, ano)][
  ano == 2018L, .(uf, log_eleitorado)], by = "uf")              # tamanho no período-base
cel[, `:=`(id = as.integer(factor(paste(uf, cargo))), uf_id = as.integer(factor(uf)),
           g = fifelse(federal, 2022L, 0L))]
stopifnot(cel[, .N, by = id][, all(N == 4L)])

estimar <- function(y, versao) {
  att <- att_gt(yname = y, tname = "ano", idname = "id", gname = "g", data = as.data.frame(cel),
                xformla = if (versao == "controle tamanho") ~ log_eleitorado else ~1,
                control_group = "nevertreated", base_period = "universal", est_method = "dr",
                bstrap = TRUE, cband = TRUE, biters = n_boot, clustervars = c("id", "uf_id"),
                weightsname = if (versao == "peso") "n_comp" else NULL, print_details = FALSE)
  din <- aggte(att, type = "dynamic", cband = TRUE, biters = n_boot, na.rm = TRUE)
  grp <- aggte(att, type = "group", cband = TRUE, biters = n_boot, na.rm = TRUE)
  rbind(data.table(ano = 2022L + din$egt, att = din$att.egt, ep = din$se.egt, crit = din$crit.val.egt),
        data.table(ano = NA_integer_, att = grp$overall.att, ep = grp$overall.se, crit = qnorm(0.975)))[
    , `:=`(desfecho = y, versao = versao)][]
}
out <- rbindlist(lapply(c("pct_mulheres_comp", "pct_negras_comp"), function(y)
  rbindlist(lapply(c("sem peso", "peso", "controle tamanho"), function(v) estimar(y, v)))))
out[, `:=`(banda_inf = att - crit * ep, banda_sup = att + crit * ep)]
fwrite(out, file.path(dir_out, "composicao_did.csv"))
out[, cel := sprintf("%5.1f [%5.1f, %5.1f]", att, banda_inf, banda_sup)]
out[, termo := fifelse(is.na(ano), "geral", as.character(ano))]
print(dcast(out[termo != "2018"], desfecho + versao ~ termo, value.var = "cel"), row.names = FALSE)
