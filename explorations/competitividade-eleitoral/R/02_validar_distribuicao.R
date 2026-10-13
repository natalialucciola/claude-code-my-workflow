# =============================================================================
# 02 — Valida a distribuição de cadeiras: reproduzir os eleitos do TSE em cada
#      UF × cargo × ano, com a regra do ano (ver funcoes_margem.R)
#
# Entrada: data/processed/margem_{cand,listas,distritos}.rds (script 01)
# Saída:   explorations/competitividade-eleitoral/output/validacao_distribuicao.csv
#          explorations/competitividade-eleitoral/output/validacao_divergencias.csv
# Critério do plano: nenhuma margem é calculada sem 100% de acerto.
#
#   Rscript explorations/competitividade-eleitoral/R/02_validar_distribuicao.R
# =============================================================================
library(data.table)
source("explorations/competitividade-eleitoral/R/funcoes_margem.R")

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
cand      <- readRDS(file.path("data", "processed", "margem_cand.rds"))
listas    <- readRDS(file.path("data", "processed", "margem_listas.rds"))
distritos <- readRDS(file.path("data", "processed", "margem_distritos.rds"))

# Monta os insumos de um distrito: candidaturas, índice de lista e votos "extra" por lista
insumos_distrito <- function(a, u, cg) {
  cd <- cand[ano == a & uf == u & cd_cargo == cg]
  ls <- listas[ano == a & uf == u & cd_cargo == cg]
  # listas que só aparecem em um dos arquivos entram com zero no outro
  ids <- union(ls$sq_lista, cd$sq_lista)
  vl  <- setNames(ls$votos_lista, ls$sq_lista)[ids]; vl[is.na(vl)] <- 0
  lst <- match(cd$sq_lista, ids)
  v   <- as.numeric(cd$votos)
  apta <- cd$apta
  extra <- vl - vapply(seq_along(ids), function(l) sum(v[lst == l & apta]), numeric(1))
  v[!apta] <- 0                                   # votos de inaptos já estão (ou não) na lista
  list(cd = cd, ids = ids, v = v, lst = lst, apta = apta, extra = extra,
       M = distritos[ano == a & uf == u & cd_cargo == cg, cadeiras])
}

validar <- function(a, u, cg) {
  x <- insumos_distrito(a, u, cg)
  prev <- distribuir(x$v, x$lst, x$apta, x$extra, x$M, as.character(a))
  data.table(ano = a, uf = u, cd_cargo = cg, sq_candidato = x$cd$sq_candidato,
             nome_urna = x$cd$nome_urna, sq_lista = x$cd$sq_lista, votos = x$v,
             apta = x$apta, eleito_tse = x$cd$eleito_tse, eleito_prev = prev,
             extra_neg = any(x$extra < -0.5))
}

res <- rbindlist(lapply(seq_len(nrow(distritos)), function(k) {
  d <- distritos[k]
  validar(d$ano, d$uf, d$cd_cargo)
}))

tab <- res[, .(cadeiras = sum(eleito_tse), acertos = sum(eleito_tse & eleito_prev),
               divergencias = sum(eleito_tse != eleito_prev), extra_neg = any(extra_neg)),
           by = .(ano, uf, cd_cargo)]
fwrite(tab, file.path(dir_out, "validacao_distribuicao.csv"))
fwrite(res[eleito_tse != eleito_prev][order(ano, uf, cd_cargo, -votos)],
       file.path(dir_out, "validacao_divergencias.csv"))

message("Distritos com divergência, por ano e cargo:")
print(tab[, .(distritos = .N, com_divergencia = sum(divergencias > 0),
              candidaturas_divergentes = sum(divergencias), extra_neg = sum(extra_neg)),
          by = .(ano, cd_cargo)][order(ano, cd_cargo)])
