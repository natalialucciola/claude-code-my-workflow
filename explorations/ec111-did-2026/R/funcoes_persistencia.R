# ==============================================================================
# Persistência do efeito: ATT(t2) − ATT(t1) a partir de um objeto did::att_gt
#
# Com adoção única (um grupo tratado) e base universal, ATT(2026) − ATT(2022) é a
# mudança do efeito entre as duas eleições pós-tratamento (Roth 2024). O EP vem da
# função de influência das duas ATT(g,t), somada dentro de cada cluster:
#   EP = sqrt( Σ_c (Σ_{i∈c} ψ_i)² ) / n,   ψ_i = ψ_i(t2) − ψ_i(t1)
# Sem cluster além da unidade, a soma é por unidade (EP analítico do did).
# Validação: a mesma fórmula aplicada a cada ATT isolada deve ficar próxima do EP
# (bootstrap) que o próprio att_gt reporta; dif_att devolve as duas para conferência.
# Usado por explorations/ec111-did-2026/R/03 e competitividade-eleitoral/R/05 e R/14.
# ==============================================================================

#' Diferença entre duas ATT(g,t) do mesmo grupo tratado, com EP por cluster
#' @param a objeto MP de did::att_gt (um só grupo tratado)
#' @param t1,t2 períodos (na escala de tname usada na estimação)
#' @param cluster vetor de cluster na ordem das linhas de a$inffunc; NULL = unidade
#' @return lista: att, ep, e a conferência (ep_formula e ep_did de t1 e t2)
dif_att <- function(a, t1, t2, cluster = NULL) {
  j1 <- which(a$t == t1)
  j2 <- which(a$t == t2)
  stopifnot(length(j1) == 1L, length(j2) == 1L)
  inf <- as.matrix(a$inffunc)
  n <- nrow(inf)
  if (!is.null(cluster)) stopifnot(length(cluster) == n)
  # Com poucos clusters (26 UFs), a fórmula ficou ~3% abaixo do EP bootstrap do did
  # (mediana 0,967 com 25.000 réplicas); a correção G/(G − 1) leva a ~0,99.
  ajuste <- if (is.null(cluster)) 1 else {
    G <- length(unique(cluster)); sqrt(G / (G - 1))
  }
  ep_de <- function(psi) {
    s <- if (is.null(cluster)) psi else rowsum(psi, cluster)[, 1]
    ajuste * sqrt(sum(s^2)) / n
  }
  list(att = a$att[j2] - a$att[j1],
       ep = ep_de(inf[, j2] - inf[, j1]),
       ep_formula_t1 = ep_de(inf[, j1]), ep_did_t1 = a$se[j1],
       ep_formula_t2 = ep_de(inf[, j2]), ep_did_t2 = a$se[j2])
}

#' Vetor de cluster (2º nível de clustervars) na ordem das linhas da função de influência
#' @param a objeto de did::att_gt estimado com clustervars = c(idname, cluster)
#' @param var nome da variável de cluster nos dados
cluster_de <- function(a, var) {
  dp <- a$DIDparams
  d <- as.data.frame(dp$data)
  primeiro <- d[d[[dp$tname]] == min(d[[dp$tname]]), ]
  stopifnot(nrow(primeiro) == nrow(a$inffunc))
  primeiro[[var]]
}
