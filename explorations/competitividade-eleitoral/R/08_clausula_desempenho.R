# =============================================================================
# 08 — Separar a EC 111 do incentivo da cláusula de desempenho (EC 97/2017)
#
# A cláusula de desempenho é aferida pelos votos para a CÂMARA, com patamar crescente
# (1,5% em 2018, 2% em 2022, 2,5% em 2026 — a conferir no texto da EC 97/2017), e a
# federação conta como um partido. Ela dá aos partidos perto do patamar um incentivo
# exclusivo do Federal para lançar muitas candidaturas e somar votos, para homens e
# mulheres. Se esse incentivo explica a expansão de candidaturas fracas no Federal, ela
# deve se concentrar nos partidos pressionados; nos partidos com folga, a diferença
# mulheres − homens fica mais atribuível à EC 111.
#
# Entidade: sigla harmonizada para 2026 (fusões/renomeações) e agrupada na federação de
# 2022 (partidos que dividem a mesma lista em 2022). Classificação fixa no tempo, pela
# votação nacional da entidade para Deputado Federal em 2018 (antes da EC 111):
#   pressionada = participação < corte (4%, o dobro do patamar de 2022; robustez: 3%)
# Mesmo desenho do 07 (did::att_gt, UF × cargo, sem DF), separado por grupo de partidos;
# sem peso e com peso = cadeiras do distrito.
#
# Entrada: data/processed/margem_resultado.rds; data/raw/tse/votacao_partido_munzona_2018.zip
# Saída:   explorations/competitividade-eleitoral/output/clausula_{entidades,descritivo,did}.csv
#
#   Rscript explorations/competitividade-eleitoral/R/08_clausula_desempenho.R
# =============================================================================
library(data.table)
library(did)
set.seed(20261014)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
n_boot  <- 25000L
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))

# --- 1. Harmonização das siglas para o partido que disputou 2022 ---------------
# A cláusula que importa para o teste é a de 2022 (1ª eleição sob a EC 111). Partidos que
# concorreram separados em 2022 e se fundiram depois (PTB, PATRIOTA, PROS, PSC) ficam
# separados. O teste usa 2014, 2018 e 2022; em 2026 as fusões misturam grupos.
mapa <- c("PMDB" = "MDB", "PEN" = "PATRIOTA", "PATRI" = "PATRIOTA", "PRP" = "PATRIOTA",
          "PSDC" = "DC", "PT do B" = "AVANTE", "PTN" = "PODE", "PHS" = "PODE",
          "SD" = "SOLIDARIEDADE", "PPS" = "CIDADANIA", "PR" = "PL", "PRB" = "REPUBLICANOS",
          "PPL" = "PC do B", "PTC" = "AGIR", "PSL" = "UNIÃO", "DEM" = "UNIÃO")
harm <- function(s) ifelse(s %in% names(mapa), mapa[s], s)
res <- res[ano <= 2022L]
res[, partido_h := harm(sg_partido)]

# --- 2. Federações de 2022: partidos que dividem a mesma lista em alguma UF ----
fed22 <- unique(res[ano == 2022L & cd_cargo %in% 6:7, .(uf, cd_cargo, sq_lista, partido_h)])
pares <- fed22[, if (.N > 1L) CJ(a = partido_h, b = partido_h)[a < b], by = .(uf, cd_cargo, sq_lista)]
entidade <- setNames(unique(res$partido_h), unique(res$partido_h))
repeat {                                           # componentes conexos (união simples)
  mudou <- FALSE
  for (k in seq_len(nrow(pares))) {
    ea <- entidade[[pares$a[k]]]; eb <- entidade[[pares$b[k]]]
    if (ea != eb) { m <- min(ea, eb); entidade[entidade %in% c(ea, eb)] <- m; mudou <- TRUE }
  }
  if (!mudou) break
}
res[, entidade := entidade[partido_h]]
membros <- res[ano == 2022L, .(membros = paste(sort(unique(partido_h)), collapse = "/")), by = entidade]

# --- 3. Votação nacional para Deputado Federal em 2018, por entidade ----------
ufs <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT",
         "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO")
zip18 <- file.path("data", "raw", "tse", "votacao_partido_munzona_2018.zip")
v18 <- rbindlist(lapply(ufs, function(u) {
  td <- tempfile(); dir.create(td); on.exit(unlink(td, recursive = TRUE))
  f <- sprintf("votacao_partido_munzona_2018_%s.csv", u)
  unzip(zip18, f, exdir = td)
  x <- fread(file.path(td, f), encoding = "Latin-1", colClasses = "character",
             select = c("CD_CARGO", "SG_PARTIDO", "QT_VOTOS_NOMINAIS_VALIDOS", "QT_TOTAL_VOTOS_LEG_VALIDOS"))
  x[CD_CARGO == "6", .(votos = sum(as.numeric(QT_VOTOS_NOMINAIS_VALIDOS)) +
                         sum(as.numeric(QT_TOTAL_VOTOS_LEG_VALIDOS))), by = .(sg_partido = SG_PARTIDO)]
}))
v18[, entidade := {e <- entidade[harm(sg_partido)]; ifelse(is.na(e), harm(sg_partido), e)}]
ent <- v18[, .(votos_2018 = sum(votos)), by = entidade][, pct_2018 := 100 * votos_2018 / sum(votos_2018)]
ent <- merge(ent, membros, by = "entidade", all = TRUE)
fwrite(ent[order(-pct_2018)], file.path(dir_out, "clausula_entidades.csv"))
print(ent[order(-pct_2018), .(entidade, membros, pct_2018 = round(pct_2018, 2))])

# --- 4. Células UF × cargo × ano × grupo de partidos e estimação ---------------
d0 <- res[apta & cd_cargo %in% 6:7 & uf != "DF" & !is.na(margem_qe) & !is.na(genero)]
d0 <- merge(d0, ent[, .(entidade, pct_2018)], by = "entidade", all.x = TRUE)
message("Candidaturas sem votação de 2018 na entidade (partidos novos): ",
        d0[is.na(pct_2018), .N], " — ficam no grupo pressionado (sem base em 2018)")
d0[is.na(pct_2018), pct_2018 := 0]
d0[, `:=`(federal = cd_cargo == 6L, comp = margem_qe >= -0.10)]
d0[, nc := !comp]

celulas <- function(dd) {
  dd[, {
    M <- cadeiras[1]
    list(cadeiras = M,
         nc_por_cadeira_mulheres = sum(nc & mulher) / M,
         nc_por_cadeira_homens   = sum(nc & !mulher) / M,
         nc_por_cadeira_negras   = sum(nc & negra) / M,
         dif_pct_comp = 100 * (mean(comp[mulher]) - mean(comp[!mulher])),
         pct_mulheres_entre_comp = 100 * mean(mulher[comp]),
         n = .N)
  }, by = .(uf, cargo, federal, ano)][
    , `:=`(dif_nc_por_cadeira = nc_por_cadeira_mulheres - nc_por_cadeira_homens,
           id = as.integer(factor(paste(uf, cargo))), uf_id = as.integer(factor(uf)),
           g = fifelse(federal, 2022L, 0L))][]
}
desfechos <- c("nc_por_cadeira_mulheres", "nc_por_cadeira_homens", "dif_nc_por_cadeira",
               "nc_por_cadeira_negras", "dif_pct_comp", "pct_mulheres_entre_comp")
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

descr <- list(); out <- list()
for (corte in c(4, 3)) for (grp in c("pressionados", "com folga")) {
  dd <- if (grp == "pressionados") d0[pct_2018 < corte] else d0[pct_2018 >= corte]
  descr[[length(descr) + 1L]] <- dd[, .(n = .N, mulheres_nc = sum(nc & mulher), homens_nc = sum(nc & !mulher),
                                        pct_mulheres_comp = 100 * mean(mulher[comp])),
                                    by = .(cargo, ano)][, `:=`(grupo = grp, corte = corte)]
  cel <- celulas(dd)
  stopifnot(cel[, .N, by = id][, all(N == 3L)])            # 2014, 2018, 2022
  for (y in desfechos) for (pd in c(FALSE, TRUE)) {
    out[[length(out) + 1L]] <- estimar(cel, y, pd)[, `:=`(grupo = grp, corte = corte, desfecho = y,
                                                          peso = if (pd) "magnitude" else "sem peso")]
  }
}
descr <- rbindlist(descr); out <- rbindlist(out)
out[, `:=`(banda_inf = att - crit * ep, banda_sup = att + crit * ep)]
fwrite(descr[order(corte, grupo, cargo, ano)], file.path(dir_out, "clausula_descritivo.csv"))
fwrite(out, file.path(dir_out, "clausula_did.csv"))
print(descr[corte == 4][order(grupo, cargo, ano)])
