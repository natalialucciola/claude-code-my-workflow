# =============================================================================
# 12 — Medidas complementares de competitividade pelo gasto: D2 e D3 (2014–2022)
#
# D2 — dinheiro faltante (ex post): converte a margem de votos (R/03) em reais por uma
#   elasticidade voto–gasto. Com log(V+1) = a_lista + e·log(G+1), o gasto que levaria a
#   candidatura ao limiar (V* = V − margem) é
#       G* = (G + 1)·((V* + 1)/(V + 1))^(1/e) − 1,
#   e margem_d2 = G − G* (positiva = folga do eleito em reais; negativa = reais que
#   faltaram). e é estimada DENTRO da lista (EF de lista), por gênero × cargo × ano.
#   d2_qe = margem_d2 / QE de gasto (mesma escala da medida A).
#   Sensibilidade: e ± 1 EP e e comum (cargo × ano, sem separar gênero).
#   Ressalva: e observacional é endógena (quem já é forte arrecada mais); D2 é uma
#   conversão sob suposição explícita, não um efeito causal.
#
# D3 — gasto relativo ao eleito marginal da lista: d3 = G / G_âncora, com âncora = gasto
#   do último eleito da lista pelo voto; em lista sem eleitos, o menor gasto entre os
#   eleitos do distrito. Âncora com gasto 0 → NA.
#
# Entrada: data/processed/margem_gasto_resultado.rds (R/11)
# Saída:   data/processed/margem_gasto_medidas.rds; output/elasticidade_voto_gasto.csv
#
#   Rscript explorations/competitividade-eleitoral/R/12_dinheiro_faltante_d2_d3.R
# =============================================================================
library(data.table)
library(fixest)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
d <- readRDS(file.path("data", "processed", "margem_gasto_resultado.rds"))
a <- d[apta == TRUE & !is.na(genero)]

# --- Elasticidades voto–gasto dentro da lista -----------------------------------
estimar_e <- function(dd) {
  m <- feols(log(votos + 1) ~ log(gasto + 1) | sq_lista, data = dd, cluster = ~sq_lista)
  data.table(e = unname(coef(m)), ep = unname(se(m)), n = nobs(m))
}
el_grupo <- a[, estimar_e(.SD), by = .(ano, cargo, mulher)]
el_comum <- a[, estimar_e(.SD), by = .(ano, cargo)]
el <- rbind(el_grupo[, grupo := fifelse(mulher, "Mulheres", "Homens")][, mulher := NULL],
            el_comum[, grupo := "Comum"])[order(ano, cargo, grupo)]
print(el[, .(ano, cargo, grupo, e = round(e, 3), ep = round(ep, 3), n)])
fwrite(el, file.path(dir_out, "elasticidade_voto_gasto.csv"))

# --- D2 --------------------------------------------------------------------------
converter <- function(G, V, margem, e) {
  v_alvo <- pmax(V - margem, 0)
  g_alvo <- (G + 1) * ((v_alvo + 1) / (V + 1))^(1 / e) - 1
  G - g_alvo
}
a <- merge(a, el_grupo[, .(ano, cargo, mulher = grupo == "Mulheres", e, ep)],
           by = c("ano", "cargo", "mulher"))
a <- merge(a, el_comum[, .(ano, cargo, e_comum = e)], by = c("ano", "cargo"))
a[, `:=`(margem_d2       = converter(gasto, votos, margem, e),
         margem_d2_e_alto = converter(gasto, votos, margem, e + ep),
         margem_d2_e_baixo = converter(gasto, votos, margem, e - ep),
         margem_d2_comum  = converter(gasto, votos, margem, e_comum))]
for (v in c("margem_d2", "margem_d2_e_alto", "margem_d2_e_baixo", "margem_d2_comum")) {
  a[, (sub("margem_", "", paste0(v, "_qe"))) := get(v) / qe_gasto]
}

# --- D3 --------------------------------------------------------------------------
ult_lista <- a[eleito == TRUE, .(ancora_lista = gasto[which.min(votos)]),
               by = .(ano, uf, cd_cargo, sq_lista)]
min_dist  <- a[eleito == TRUE, .(ancora_dist = min(gasto)), by = .(ano, uf, cd_cargo)]
a <- merge(a, ult_lista, by = c("ano", "uf", "cd_cargo", "sq_lista"), all.x = TRUE)
a <- merge(a, min_dist, by = c("ano", "uf", "cd_cargo"), all.x = TRUE)
a[, ancora := fcoalesce(ancora_lista, ancora_dist)]
a[, d3 := fifelse(ancora > 0, gasto / ancora, NA_real_)]

message("Resumo (aptas, medianas):")
print(a[, .(n = .N, d2_qe_mediana_nao_eleitas = round(median(d2_qe[!eleito], na.rm = TRUE), 2),
            d3_mediana = round(median(d3, na.rm = TRUE), 3), d3_na = sum(is.na(d3))),
        by = .(ano, cargo, mulher)][order(ano, cargo, mulher)])
saveRDS(a, file.path("data", "processed", "margem_gasto_medidas.rds"))
