# =============================================================================
# 07 — Candidaturas NÃO competitivas: aumentaram mais no Federal que no Estadual?
#      E os desfechos principais com peso pela magnitude do distrito (cadeiras).
#
# Medida: margem de votos / QE (script 03). A margem é o menor número de votos que muda
# o resultado da candidatura, refazendo a distribuição completa com a regra do ano; por
# isso considera ao mesmo tempo o caminho dentro da lista (passar/ser passada por colegas)
# e entre listas (a lista ganhar/perder cadeira), para qualquer número de cadeiras.
#   competitiva     = eleita ou margem/QE >= -0,10
#   não competitiva = não eleita e margem/QE < -0,10
#
# Desfechos por célula UF × cargo × ano (sem DF):
#   nc_por_cadeira_<g>  nº de candidaturas não competitivas do grupo por cadeira em disputa
#   pct_nc_<g>          % das candidaturas do grupo que são não competitivas
#   dif_pct_nc          pct_nc do grupo − pct_nc do complemento (tripla diferença)
#   pct_<g>_entre_nc    % do grupo entre as não competitivas (composição)
#   + principais: dif_pct_comp (taxa de competitivas, grupo − complemento) e
#     pct_<g>_entre_comp (composição das competitivas)
# Grupos: mulheres (complemento: homens) e pessoas negras (complemento: brancas).
# Estimação: did::att_gt como nos scripts 05/06; versões sem peso e com peso = cadeiras
# do distrito (constante no tempo em todas as UF × cargo, conferido abaixo).
#
# Entrada: data/processed/margem_resultado.rds
# Saída:   explorations/competitividade-eleitoral/output/nao_competitivas_{descritivo,did}.csv
#
#   Rscript explorations/competitividade-eleitoral/R/07_nao_competitivas_magnitude.R
# =============================================================================
library(data.table)
library(did)
set.seed(20261014)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
n_boot  <- 25000L
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
         nc_por_cadeira_grupo = sum(nc & g) / M,
         nc_por_cadeira_compl = sum(nc & cc) / M,
         pct_nc_grupo = 100 * mean(nc[g]), pct_nc_compl = 100 * mean(nc[cc]),
         pct_grupo_entre_nc = 100 * sum(nc & g) / sum(nc & (g | cc)),
         pct_comp_grupo = 100 * mean(comp[g]), pct_comp_compl = 100 * mean(comp[cc]),
         pct_grupo_entre_comp = 100 * sum(comp & g) / sum(comp & (g | cc)),
         n_grupo = sum(g))
  }, by = .(uf, cargo, federal, ano)][
    , `:=`(dif_pct_nc = pct_nc_grupo - pct_nc_compl,
           dif_nc_por_cadeira = nc_por_cadeira_grupo - nc_por_cadeira_compl,
           dif_pct_comp = pct_comp_grupo - pct_comp_compl,
           grupo = nome,
           id = as.integer(factor(paste(uf, cargo))), uf_id = as.integer(factor(uf)),
           g = fifelse(federal, 2022L, 0L))][]
}

# (a) Descritivo agregado (todas as candidaturas do cargo juntas)
descr <- rbindlist(lapply(names(grupos), function(nome) {
  gq <- grupos[[nome]]
  d[, {
    g <- eval(gq$g); cc <- eval(gq$c)
    list(n_grupo = sum(g), nc_grupo = sum(nc & g), nc_compl = sum(nc & cc),
         nc_grupo_por_cadeira = sum(nc & g) / sum(cadeiras[!duplicated(uf)]),
         pct_nc_grupo = 100 * mean(nc[g]), pct_nc_compl = 100 * mean(nc[cc]),
         pct_grupo_entre_nc = 100 * sum(nc & g) / sum(nc & (g | cc)))
  }, by = .(cargo, ano)][, grupo := nome]
}))
fwrite(descr[order(grupo, cargo, ano)], file.path(dir_out, "nao_competitivas_descritivo.csv"))
print(descr[order(grupo, cargo, ano), lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])

# (b) Tripla diferença / diferença em diferenças
desfechos <- c("nc_por_cadeira_grupo", "dif_nc_por_cadeira", "pct_nc_grupo", "dif_pct_nc",
               "pct_grupo_entre_nc", "dif_pct_comp", "pct_grupo_entre_comp")
estimar <- function(cel, y, peso) {
  att <- att_gt(yname = y, tname = "ano", idname = "id", gname = "g", data = as.data.frame(cel),
                control_group = "nevertreated", base_period = "universal", est_method = "dr",
                bstrap = TRUE, cband = TRUE, biters = n_boot, clustervars = c("id", "uf_id"),
                weightsname = if (peso) "cadeiras" else NULL, print_details = FALSE)
  din <- aggte(att, type = "dynamic", cband = TRUE, biters = n_boot, na.rm = TRUE)
  grp <- aggte(att, type = "group", cband = TRUE, biters = n_boot, na.rm = TRUE)
  rbind(data.table(ano = 2022L + din$egt, att = din$att.egt, ep = din$se.egt, crit = din$crit.val.egt),
        data.table(ano = NA_integer_, att = grp$overall.att, ep = grp$overall.se, crit = qnorm(0.975)))
}
out <- rbindlist(lapply(names(grupos), function(nome) {
  cel <- celulas(nome)
  stopifnot(cel[, .N, by = id][, all(N == 4L)], cel[, uniqueN(cadeiras), by = id][, all(V1 == 1L)])
  rbindlist(lapply(desfechos, function(y) rbindlist(lapply(c(FALSE, TRUE), function(pd)
    estimar(cel, y, pd)[, `:=`(grupo = nome, desfecho = y,
                               peso = if (pd) "magnitude" else "sem peso")]))))
}))
out[, `:=`(banda_inf = att - crit * ep, banda_sup = att + crit * ep)]
fwrite(out, file.path(dir_out, "nao_competitivas_did.csv"))

out[, cel := sprintf("%6.2f [%6.2f, %6.2f]%s", att, banda_inf, banda_sup,
                     fifelse(banda_inf > 0 | banda_sup < 0, "*", " "))]
out[, termo := fifelse(is.na(ano), "geral", as.character(ano))]
print(dcast(out[termo != "2018"], grupo + desfecho + peso ~ termo, value.var = "cel"),
      row.names = FALSE)
