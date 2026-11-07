# =============================================================================
# 03 — Margem de votos de todas as candidaturas a Deputado (2014–2026)
#
# Margem: menor número inteiro de votos que, somado (não eleito) ou retirado (eleito)
# da candidatura, muda seu resultado, refazendo a distribuição com a regra do ano
# (funcoes_margem.R; regra validada em 100% dos eleitos pelo script 02).
# Normalizações:
#   margem_qe = margem / QE                        (principal; comparável entre cargos)
#   rv_lss    = margem / eleitorado da UF          (Luechinger, Schelker & Schmid 2024)
#   rv_abd    = margem / (V_i + V_L,j)             (Avelino, Biderman & Desposato 2022;
#                                                   a "banda de 20%" deles é |rv_abd| < 0,1)
#
# Entrada: data/processed/margem_{cand,listas,distritos}.rds
# Saída:   data/processed/margem_resultado.rds (uma linha por candidatura)
#
#   Rscript explorations/competitividade-eleitoral/R/03_margens.R
# =============================================================================
library(data.table)
library(parallel)

# Poucos núcleos para não pressionar a memória; cada distrito é salvo ao terminar
# (dir_cache), e uma nova execução pula os distritos já calculados.
n_nucleos <- as.integer(Sys.getenv("MARGEM_NUCLEOS", max(1L, min(3L, detectCores() - 2L))))
dir_cache <- file.path("data", "processed", "margens_por_distrito")
dir.create(dir_cache, recursive = TRUE, showWarnings = FALSE)
src_fun   <- file.path("explorations", "competitividade-eleitoral", "R", "funcoes_margem.R")
source(src_fun)
cand      <- readRDS(file.path("data", "processed", "margem_cand.rds"))
listas    <- readRDS(file.path("data", "processed", "margem_listas.rds"))
distritos <- readRDS(file.path("data", "processed", "margem_distritos.rds"))

# Insumos de um distrito (mesma construção do script 02)
insumos_distrito <- function(a, u, cg) {
  cd <- cand[ano == a & uf == u & cd_cargo == cg]
  ls <- listas[ano == a & uf == u & cd_cargo == cg]
  ids <- union(ls$sq_lista, cd$sq_lista)
  vl  <- setNames(ls$votos_lista, ls$sq_lista)[ids]; vl[is.na(vl)] <- 0
  lst <- match(cd$sq_lista, ids)
  v   <- as.numeric(cd$votos)
  extra <- vl - vapply(seq_along(ids), function(l) sum(v[lst == l & cd$apta]), numeric(1))
  v[!cd$apta] <- 0
  list(sq = cd$sq_candidato, v = v, lst = lst, apta = cd$apta, extra = extra,
       M = distritos[ano == a & uf == u & cd_cargo == cg, cadeiras],
       validos = sum(vl))
}
lista_insumos <- lapply(seq_len(nrow(distritos)), function(k) {
  d <- distritos[k]
  c(insumos_distrito(d$ano, d$uf, d$cd_cargo), list(ano = d$ano, uf = d$uf, cd_cargo = d$cd_cargo))
})
# maiores distritos primeiro, para equilibrar os núcleos
lista_insumos <- lista_insumos[order(-vapply(lista_insumos, function(x) length(x$v), 1L))]

arq_cache <- function(x) file.path(dir_cache, sprintf("%d_%s_%d.rds", x$ano, x$uf, x$cd_cargo))
calcular <- function(x) {
  r <- margens_distrito(x$v, x$lst, x$apta, x$extra, x$M, as.character(x$ano))
  out <- data.table(ano = x$ano, uf = x$uf, cd_cargo = x$cd_cargo, sq_candidato = x$sq,
                    eleito = r$eleito, margem = r$margem,
                    v_l = primeiro_nao_eleito(x$v, x$lst, x$apta, r$eleito),
                    qe = quociente_eleitoral(x$validos, x$M))
  saveRDS(out, arq_cache(x))
  NULL
}

pendentes <- Filter(function(x) !file.exists(arq_cache(x)), lista_insumos)
message("Distritos: ", length(lista_insumos), " | pendentes: ", length(pendentes))
if (length(pendentes)) {
  cl <- makeCluster(n_nucleos)
  invisible(clusterEvalQ(cl, library(data.table)))
  clusterExport(cl, c("src_fun", "dir_cache", "arq_cache"))
  invisible(clusterEvalQ(cl, source(src_fun)))
  t0 <- Sys.time()
  invisible(parLapplyLB(cl, pendentes, calcular))
  stopCluster(cl)
  message("Tempo: ", format(round(difftime(Sys.time(), t0, units = "mins"), 1)))
}
res <- rbindlist(lapply(lista_insumos, function(x) readRDS(arq_cache(x))))

res <- merge(cand, res, by = c("ano", "uf", "cd_cargo", "sq_candidato"))
res <- merge(res, distritos[, .(ano, uf, cd_cargo, cadeiras, eleitorado)],
             by = c("ano", "uf", "cd_cargo"))
stopifnot(nrow(res) == nrow(cand), all(res$eleito == res$eleito_tse))
res[, `:=`(margem_qe = margem / qe,
           rv_lss    = margem / eleitorado,
           rv_abd    = margem / (votos + v_l))]

message("Candidaturas sem margem (inaptas ou eleitas mesmo com zero votos): ",
        res[, sum(is.na(margem))])
print(res[apta == TRUE, .(n = .N, eleitas = sum(eleito),
                          mediana_margem_qe = round(median(margem_qe, na.rm = TRUE), 3),
                          a_10pct_qe = sum(abs(margem_qe) < 0.1, na.rm = TRUE)),
          by = .(ano, cargo)][order(ano, cargo)])
saveRDS(res, file.path("data", "processed", "margem_resultado.rds"))
