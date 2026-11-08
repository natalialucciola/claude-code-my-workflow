# =============================================================================
# 11 — Medida A: margem de gasto OLPR (competitividade pelo gasto, ex ante)
#
# Mesma pergunta da margem de votos (R/03), num contrafactual em que o gasto faz o papel
# do voto: as listas (coligação/federação) recebem cadeiras pelo gasto total das suas
# candidaturas e, dentro da lista, as candidaturas são ordenadas pelo gasto. A margem é o
# menor valor inteiro em reais que, somado (não eleita pelo gasto) ou retirado (eleita pelo
# gasto), muda o resultado, refazendo a distribuição com a regra do ano (funcoes_margem.R,
# sem alteração). As cláusulas de 10%/80%/20% do QE passam a valer sobre o "QE de gasto".
# Não há gasto de legenda por distrito: extra = 0.
#
#   margem_gasto_qe = margem_gasto / QE de gasto (gasto do distrito / cadeiras)
#
# Regra: MARGEM_GASTO_REGRA = "ano" (principal) ou "dhondt" (robustez, sem cláusulas).
# Teste de sanidade: com votos e votos de legenda no lugar do gasto, a montagem dos
# insumos reproduz a margem do R/03 num distrito pequeno.
#
# Entrada: data/processed/margem_gasto_insumos.rds (R/10), margem_{listas,distritos}.rds
# Saída:   data/processed/margem_gasto_resultado[_dhondt].rds
#          output/margem_gasto_validacao[_dhondt].csv
#
#   Rscript explorations/competitividade-eleitoral/R/11_margem_gasto.R
# =============================================================================
library(data.table)
library(parallel)

regra_modo <- Sys.getenv("MARGEM_GASTO_REGRA", "ano")
stopifnot(regra_modo %in% c("ano", "dhondt"))
sufixo    <- if (regra_modo == "dhondt") "_dhondt" else ""
n_nucleos <- as.integer(Sys.getenv("MARGEM_NUCLEOS", max(1L, min(3L, detectCores() - 2L))))
dir_out   <- file.path("explorations", "competitividade-eleitoral", "output")
dir_cache <- file.path("data", "processed", paste0("margens_gasto_por_distrito", sufixo))
dir.create(dir_cache, recursive = TRUE, showWarnings = FALSE)
src_fun   <- file.path("explorations", "competitividade-eleitoral", "R", "funcoes_margem.R")
source(src_fun)
cand      <- readRDS(file.path("data", "processed", "margem_gasto_insumos.rds"))
listas    <- readRDS(file.path("data", "processed", "margem_listas.rds"))
distritos <- readRDS(file.path("data", "processed", "margem_distritos.rds"))
distritos <- distritos[ano %in% c(2014L, 2018L, 2022L, 2026L) & cd_cargo %in% 6:7]

# Insumos de um distrito. var = "gasto" (medida A) ou "votos" (teste: soma os votos de
# legenda da lista em extra, como o R/03).
insumos_distrito <- function(a, u, cg, var = "gasto") {
  cd  <- cand[ano == a & uf == u & cd_cargo == cg]
  ls  <- listas[ano == a & uf == u & cd_cargo == cg]
  # mesma ordem de listas do R/03: empates (raros) são decididos pela ordem dos dados
  ids <- union(ls$sq_lista, cd$sq_lista)
  lst <- match(cd$sq_lista, ids)
  v   <- as.numeric(cd[[var]])
  v[!cd$apta] <- 0
  extra <- numeric(length(ids))
  if (var == "votos") {
    vl <- setNames(ls$votos_lista, ls$sq_lista)[ids]; vl[is.na(vl)] <- 0
    extra <- vl - vapply(seq_along(ids), function(l) sum(v[lst == l]), numeric(1))
  }
  list(sq = cd$sq_candidato, v = v, lst = lst, apta = cd$apta, extra = extra,
       M = distritos[ano == a & uf == u & cd_cargo == cg, cadeiras], total = sum(v) + sum(extra),
       ano = a, uf = u, cd_cargo = cg)
}

# --- Teste de sanidade: reproduzir a margem de votos do R/03 (AC, Federal, 2018) ------
x <- insumos_distrito(2018L, "AC", 6L, "votos")
r <- margens_distrito(x$v, x$lst, x$apta, x$extra, x$M, "2018")
ref <- cand[ano == 2018L & uf == "AC" & cd_cargo == 6L, margem]
stopifnot(identical(r$eleito, cand[ano == 2018L & uf == "AC" & cd_cargo == 6L, eleito]),
          isTRUE(all.equal(r$margem, ref)))
message("Teste de sanidade ok: margem de votos do R/03 reproduzida (AC, Federal, 2018).")

regra_de <- function(a) if (regra_modo == "dhondt") "dhondt" else as.character(a)
arq_cache <- function(x) file.path(dir_cache, sprintf("%d_%s_%d.rds", x$ano, x$uf, x$cd_cargo))
calcular <- function(x) {
  r <- margens_distrito(x$v, x$lst, x$apta, x$extra, x$M, regra_de(x$ano))
  saveRDS(data.table(ano = x$ano, uf = x$uf, cd_cargo = x$cd_cargo, sq_candidato = x$sq,
                     eleito_gasto = r$eleito, margem_gasto = r$margem,
                     qe_gasto = quociente_eleitoral(x$total, x$M)), arq_cache(x))
  NULL
}

lista_insumos <- lapply(seq_len(nrow(distritos)), function(k) {
  d <- distritos[k]; insumos_distrito(d$ano, d$uf, d$cd_cargo)
})
lista_insumos <- lista_insumos[order(-vapply(lista_insumos, function(x) length(x$v), 1L))]
# Distritos sem gasto registrado não têm distribuição pelo gasto. Único caso: DF 2026, que a
# base de 2026 (ec111-did-2026/R/01) não traz porque o DF não elege deputados estaduais;
# o DF fica fora da tripla diferença de qualquer forma.
sem_gasto <- Filter(function(x) x$total <= 0, lista_insumos)
if (length(sem_gasto)) {
  message("Sem gasto registrado (fora da medida A): ",
          paste(vapply(sem_gasto, function(x) sprintf("%s %d %d", x$uf, x$cd_cargo, x$ano), ""),
                collapse = ", "))
  stopifnot(all(vapply(sem_gasto, function(x) x$uf == "DF" && x$ano == 2026L, TRUE)))
}
lista_insumos <- Filter(function(x) x$total > 0, lista_insumos)
cand <- cand[!(ano == 2026L & uf == "DF")]
pendentes <- Filter(function(x) !file.exists(arq_cache(x)), lista_insumos)
message("Regra: ", regra_modo, " | distritos: ", length(lista_insumos),
        " | pendentes: ", length(pendentes))
if (length(pendentes)) {
  cl <- makeCluster(n_nucleos)
  invisible(clusterEvalQ(cl, library(data.table)))
  clusterExport(cl, c("src_fun", "dir_cache", "arq_cache", "regra_de", "regra_modo"))
  invisible(clusterEvalQ(cl, source(src_fun)))
  t0 <- Sys.time()
  invisible(parLapplyLB(cl, pendentes, calcular))
  stopCluster(cl)
  message("Tempo: ", format(round(difftime(Sys.time(), t0, units = "mins"), 1)))
}
res <- rbindlist(lapply(lista_insumos, function(x) readRDS(arq_cache(x))))
res <- merge(cand, res, by = c("ano", "uf", "cd_cargo", "sq_candidato"))
stopifnot(nrow(res) == nrow(cand))
res[, margem_gasto_qe := margem_gasto / qe_gasto]

# --- Validação: o gasto, sozinho, reproduz quanto do resultado? ------------------------
a <- res[apta == TRUE]
val <- rbind(
  a[, .(grupo = "Todas", eleitos = sum(eleito), acerto_eleitos = mean(eleito_gasto[eleito]),
        falsos_eleitos = sum(eleito_gasto & !eleito), acerto_geral = mean(eleito_gasto == eleito),
        spearman_margens = cor(margem_gasto_qe, margem_qe, method = "spearman", use = "complete.obs"),
        concord_banda_010 = mean((margem_gasto_qe >= -0.1) == (margem_qe >= -0.1), na.rm = TRUE)),
    by = .(ano, cargo)],
  a[, .(grupo = fifelse(mulher, "Mulheres", "Homens"), eleitos = sum(eleito),
        acerto_eleitos = mean(eleito_gasto[eleito]), falsos_eleitos = sum(eleito_gasto & !eleito),
        acerto_geral = mean(eleito_gasto == eleito),
        spearman_margens = cor(margem_gasto_qe, margem_qe, method = "spearman", use = "complete.obs"),
        concord_banda_010 = mean((margem_gasto_qe >= -0.1) == (margem_qe >= -0.1), na.rm = TRUE)),
    by = .(ano, cargo, mulher)][, mulher := NULL])
val <- val[order(ano, cargo, grupo)]
num <- names(val)[vapply(val, is.double, TRUE)]
val[, (num) := lapply(.SD, round, 3), .SDcols = num]
print(val)
fwrite(val, file.path(dir_out, paste0("margem_gasto_validacao", sufixo, ".csv")))
saveRDS(res, file.path("data", "processed", paste0("margem_gasto_resultado", sufixo, ".rds")))
