# Compara votacao 2026 (versao 13/10) x (versao republicada 08-09/11)
# Deputado Federal, Estadual e Distrital, todas as UFs: votos nominais por candidatura,
# DS_SIT_TOT_TURNO, DS_SITUACAO_JULGAMENTO, eleitos por UF x cargo, votos validos nominais
# e de legenda por UF x cargo (arquivo de partido) e colunas novas/removidas.
# Uso (caminhos como argumentos, relativos a raiz):
#   Rscript explorations/ec111-did-2026/R/00_comparar_versoes_votacao_2026.R \
#     data/raw/tse/votacao_candidato_munzona_2026.zip data/raw/tse_20261108/votacao_candidato_munzona_2026.zip \
#     data/raw/tse/votacao_partido_munzona_2026.zip  data/raw/tse_20261108/votacao_partido_munzona_2026.zip \
#     explorations/ec111-did-2026/output/versoes_votacao_2026
# Resultado de 2026-11-09: output/versoes_votacao_2026/relatorio_diferencas.txt
suppressPackageStartupMessages(library(data.table))
a <- commandArgs(TRUE)
zc_old <- a[1]; zc_new <- a[2]; zp_old <- a[3]; zp_new <- a[4]; out <- a[5]
dir.create(out, showWarnings = FALSE, recursive = TRUE)
CARGOS <- c(6L, 7L, 8L)
`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

ler_zip <- function(zip, cols_keep = NULL) {
  ents <- unzip(zip, list = TRUE)$Name
  ents <- ents[grepl("\\.csv$", ents) & !grepl("_BR\\.csv$", ents)]
  td <- tempfile("unz"); dir.create(td)
  res <- lapply(ents, function(e) {
    unzip(zip, files = e, exdir = td)
    f <- file.path(td, e)
    hdr <- names(fread(f, nrows = 0, sep = ";", encoding = "Latin-1"))
    dt <- fread(f, sep = ";", encoding = "Latin-1", colClasses = "character",
                select = if (is.null(cols_keep)) NULL else intersect(cols_keep, hdr))
    unlink(f)
    dt <- dt[as.integer(CD_CARGO) %in% CARGOS]
    list(dt = dt, hdr = hdr, file = e)
  })
  unlink(td, recursive = TRUE)
  list(dt = rbindlist(lapply(res, `[[`, "dt"), fill = TRUE),
       hdr = unique(unlist(lapply(res, `[[`, "hdr"))),
       files = ents)
}

ccols <- c("SG_UF","CD_CARGO","DS_CARGO","SQ_CANDIDATO","NM_URNA_CANDIDATO","SG_PARTIDO",
           "QT_VOTOS_NOMINAIS","QT_VOTOS_NOMINAIS_VALIDOS","DS_SIT_TOT_TURNO",
           "DS_SITUACAO_JULGAMENTO","DS_SITUACAO_CANDIDATURA","DS_DETALHE_SITUACAO_CAND","NR_TURNO",
           "CD_MUNICIPIO","NR_ZONA")
co <- ler_zip(zc_old, ccols); cn <- ler_zip(zc_new, ccols)
cat("Arquivos UF cand old/new:", length(co$files), length(cn$files), "\n")

lines <- c()
add <- function(...) { s <- paste0(...); lines <<- c(lines, s); cat(s, "\n") }
add("# Comparacao votacao 2026: 13/10 x republicacao")
add("Colunas cand removidas: ", paste(setdiff(co$hdr, cn$hdr), collapse = ", "))
add("Colunas cand novas: ", paste(setdiff(cn$hdr, co$hdr), collapse = ", "))
add("Linhas cand (cargos 6/7/8) old/new: ", nrow(co$dt), " / ", nrow(cn$dt))

agg <- function(dt) {
  dt[, v := as.numeric(QT_VOTOS_NOMINAIS)]
  dt[, .(votos = sum(v, na.rm = TRUE), n_lin = .N,
         sit_tot = paste(sort(unique(DS_SIT_TOT_TURNO)), collapse = "|"),
         sit_jul = paste(sort(unique(DS_SITUACAO_JULGAMENTO)), collapse = "|"),
         nome = NM_URNA_CANDIDATO[1], partido = SG_PARTIDO[1]),
     by = .(SG_UF, CD_CARGO, SQ_CANDIDATO)]
}
ao <- agg(co$dt); an <- agg(cn$dt)
m <- merge(ao, an, by = c("SG_UF","CD_CARGO","SQ_CANDIDATO"), all = TRUE, suffixes = c("_old","_new"))
add("Candidaturas old/new/so-old/so-new: ", nrow(ao), " / ", nrow(an), " / ",
    sum(is.na(m$votos_new)), " / ", sum(is.na(m$votos_old)))
m[, dv := fifelse(is.na(votos_new), 0, votos_new) - fifelse(is.na(votos_old), 0, votos_old)]
mv <- m[dv != 0]
add("Candidaturas com votos alterados: ", nrow(mv), "; soma |dif| = ", sum(abs(mv$dv)),
    "; soma liquida = ", sum(mv$dv), "; max |dif| = ", if (nrow(mv)) max(abs(mv$dv)) else 0)
if (nrow(mv)) {
  add("Por UF x cargo (n candidaturas alteradas, dif liquida):")
  t <- mv[, .(n = .N, dif = sum(dv), absdif = sum(abs(dv))), by = .(SG_UF, CD_CARGO)][order(SG_UF, CD_CARGO)]
  for (i in seq_len(nrow(t))) add("  ", t$SG_UF[i], " ", t$CD_CARGO[i], ": n=", t$n[i], " liq=", t$dif[i], " abs=", t$absdif[i])
  fwrite(mv, file.path(out, "cand_votos_alterados.csv"))
}
st <- m[!is.na(sit_tot_old) & !is.na(sit_tot_new) & sit_tot_old != sit_tot_new]
add("Candidaturas com DS_SIT_TOT_TURNO alterada: ", nrow(st))
if (nrow(st)) {
  tt <- st[, .N, by = .(sit_tot_old, sit_tot_new)][order(-N)]
  for (i in seq_len(nrow(tt))) add("  ", tt$sit_tot_old[i], " -> ", tt$sit_tot_new[i], ": ", tt$N[i])
  fwrite(st, file.path(out, "cand_sit_tot_alterada.csv"))
}
sj <- m[!is.na(sit_jul_old) & !is.na(sit_jul_new) & sit_jul_old != sit_jul_new]
add("Candidaturas com DS_SITUACAO_JULGAMENTO alterada: ", nrow(sj))
if (nrow(sj)) {
  tt <- sj[, .N, by = .(sit_jul_old, sit_jul_new)][order(-N)]
  for (i in seq_len(min(30, nrow(tt)))) add("  ", tt$sit_jul_old[i], " -> ", tt$sit_jul_new[i], ": ", tt$N[i])
  fwrite(sj, file.path(out, "cand_sit_jul_alterada.csv"))
}
eleito <- function(s) grepl("^ELEITO", s)
eo <- m[eleito(sit_tot_old)]; en <- m[eleito(sit_tot_new)]
add("Eleitos old/new: ", nrow(eo), " / ", nrow(en))
sai <- m[eleito(sit_tot_old) & !eleito(sit_tot_new)]
ent <- m[!eleito(sit_tot_old) & eleito(sit_tot_new)]
add("Eleitos que sairam: ", nrow(sai), "; que entraram: ", nrow(ent))
if (nrow(sai) + nrow(ent)) {
  ch <- rbind(sai[, tipo := "saiu"], ent[, tipo := "entrou"], fill = TRUE)
  fwrite(ch, file.path(out, "eleitos_alterados.csv"))
  for (i in seq_len(nrow(ch))) add("  ", ch$tipo[i], " ", ch$SG_UF[i], " ", ch$CD_CARGO[i], " ",
                                 ch$SQ_CANDIDATO[i], " ", ch$nome_old[i] %||% ch$nome_new[i], " (", ch$partido_new[i], ") ",
                                 ch$sit_tot_old[i], " -> ", ch$sit_tot_new[i])
}
# n de eleitos por UF x cargo
ne <- merge(eo[, .(n_old = .N), by = .(SG_UF, CD_CARGO)], en[, .(n_new = .N), by = .(SG_UF, CD_CARGO)], all = TRUE)
add("UF x cargo com n de eleitos diferente: ", nrow(ne[is.na(n_old) | is.na(n_new) | n_old != n_new]))
fwrite(m, file.path(out, "cand_merge_completo.csv"))

# ---------- partido ----------
pcols <- c("SG_UF","CD_CARGO","SG_PARTIDO","NR_PARTIDO","QT_VOTOS_NOMINAIS_VALIDOS","QT_TOTAL_VOTOS_LEG_VALIDOS",
           "QT_VOTOS_LEGENDA_VALIDOS","QT_VOTOS_NOMINAIS","QT_VOTOS_LEGENDA","CD_MUNICIPIO","NR_ZONA")
po <- ler_zip(zp_old, pcols); pn <- ler_zip(zp_new, pcols)
add("Colunas partido removidas: ", paste(setdiff(po$hdr, pn$hdr), collapse = ", "))
add("Colunas partido novas: ", paste(setdiff(pn$hdr, po$hdr), collapse = ", "))
add("Linhas partido old/new: ", nrow(po$dt), " / ", nrow(pn$dt))
aggp <- function(dt, by) {
  numc <- intersect(c("QT_VOTOS_NOMINAIS_VALIDOS","QT_TOTAL_VOTOS_LEG_VALIDOS","QT_VOTOS_LEGENDA_VALIDOS"), names(dt))
  for (c in numc) set(dt, j = c, value = as.numeric(dt[[c]]))
  dt[, lapply(.SD, sum, na.rm = TRUE), by = by, .SDcols = numc]
}
for (by in list(c("SG_UF","CD_CARGO"), c("SG_UF","CD_CARGO","NR_PARTIDO"))) {
  x <- merge(aggp(copy(po$dt), by), aggp(copy(pn$dt), by), by = by, all = TRUE, suffixes = c("_old","_new"))
  x[, d_nom := QT_VOTOS_NOMINAIS_VALIDOS_new - QT_VOTOS_NOMINAIS_VALIDOS_old]
  x[, d_leg := QT_TOTAL_VOTOS_LEG_VALIDOS_new - QT_TOTAL_VOTOS_LEG_VALIDOS_old]
  xd <- x[is.na(d_nom) | is.na(d_leg) | d_nom != 0 | d_leg != 0]
  add("Partido, nivel ", paste(by, collapse = "x"), ": celulas com diferenca = ", nrow(xd), " de ", nrow(x))
  if (length(by) == 2) for (i in seq_len(nrow(xd))) add("  ", xd$SG_UF[i], " ", xd$CD_CARGO[i], ": d_nominais=", xd$d_nom[i], " d_leg=", xd$d_leg[i])
  fwrite(x, file.path(out, paste0("partido_", paste(by, collapse = "_"), ".csv")))
}
writeLines(lines, file.path(out, "relatorio_diferencas.txt"))
