# =============================================================================
# Margem de votos de cada candidatura em lista aberta (OLPR) — regra brasileira
#
# Compara Avelino, Biderman & Desposato (2022, BPSR 16(1)) e Luechinger, Schelker &
# Schmid (2024, Political Analysis 32). As duas medidas partem do mesmo experimento
# mental: muda-se apenas o voto do candidato i (que conta também para a lista dele),
# os demais votos ficam fixos.
#
# Em vez das fórmulas fechadas (que não cobrem as cláusulas de 10%/80%/20% do QE, que
# dependem do total de votos válidos), a margem é calculada por busca: o menor número
# inteiro de votos que, somado (não eleito) ou retirado (eleito) do candidato i, muda
# seu resultado, refazendo a distribuição completa.
#
# Empates não são modelados (decide a ordem dos dados; a lei usa a idade do
# candidato, CE art. 110). LSS definem a margem no ponto de empate; aqui ela é o voto
# que vira o resultado. Com votos reais a diferença é desprezível.
# =============================================================================

# Quociente eleitoral (CE art. 106): fração <= 0,5 desprezada, > 0,5 arredonda
quociente_eleitoral <- function(validos, cadeiras) {
  q <- validos / cadeiras
  if (q - floor(q) > 0.5) ceiling(q) else floor(q)
}

# Distribui as cadeiras de um distrito (UF × cargo × ano).
#   v      votos nominais válidos de cada candidatura
#   lst    índice inteiro da lista de cada candidatura (1..L)
#   apta   candidatura pode receber cadeira (votos com destinação "Válido")
#   extra  votos de cada lista que não são de candidaturas aptas (legenda etc.), tamanho L
#   M      número de cadeiras
#   regra  "2014": QP sem cláusula individual; sobras só para listas com QE.
#          "2018": candidato >= 10% QE em todas as fases; sobras para todas as listas;
#                  sem candidato apto, maiores médias entre todas as listas, sem cláusula.
#          "2022" e "2026": QP com candidato >= 10% QE; sobras para listas >= 80% QE e
#                  candidatos >= 20% QE; 3ª fase aberta a todas as listas, sem cláusula
#                  individual (ADIs 7228/7263/7325). Em 2022 é o resultado vigente após o
#                  recálculo: a base do TSE (gerada em 2026) traz os eleitos recalculados,
#                  e esta regra reproduz 100% deles (AP, DF, RO e TO mudam no Federal).
#          "2022_original": 3ª fase só entre listas >= 80% QE, como o TSE aplicou na
#                  totalização de 2022 (robustez).
#          "dhondt": D'Hondt puro, sem cláusulas (para os exemplos dos artigos).
#   Devolve um vetor lógico de eleitos, na ordem de v.
distribuir <- function(v, lst, apta, extra, M, regra) {
  L  <- length(extra)
  vl <- extra + vapply(seq_len(L), function(l) sum(v[lst == l]), numeric(1))
  qe <- quociente_eleitoral(sum(vl), M)
  # ranking de cada lista: votos decrescentes (empate: ordem dos dados)
  ord <- order(lst, -v)
  ini <- match(seq_len(L), lst[ord])          # posição inicial de cada lista em ord
  pos <- ini                                   # próximo candidato ainda não eleito
  eleito <- logical(length(v))
  ganhas <- integer(L)

  # próximo candidato elegível da lista l com votos >= piso (NA se não houver)
  proximo <- function(l, piso) {
    p <- pos[l]
    if (is.na(p)) return(NA_integer_)
    n <- length(ord)
    while (p <= n && lst[ord[p]] == l) {
      i <- ord[p]
      if (!eleito[i] && apta[i]) return(if (v[i] >= piso) i else NA_integer_)
      p <- p + 1L
    }
    NA_integer_
  }
  eleger <- function(i, l) {
    eleito[i] <<- TRUE; ganhas[l] <<- ganhas[l] + 1L
    # avança o ponteiro da lista até o próximo não eleito
    p <- pos[l]; n <- length(ord)
    while (p <= n && lst[ord[p]] == l && eleito[ord[p]]) p <- p + 1L
    pos[l] <<- p
  }

  # Sem lista com QE (CE art. 111): eleitos os mais votados
  if (regra != "dhondt" && all(vl < qe)) {
    cand_ok <- which(apta)
    eleito[cand_ok[order(-v[cand_ok])][seq_len(min(M, length(cand_ok)))]] <- TRUE
    return(eleito)
  }

  piso_qp <- if (regra %in% c("2014", "dhondt")) 0 else 0.1 * qe
  if (regra != "dhondt") {
    qp <- floor(vl / qe)
    for (l in seq_len(L)) for (k in seq_len(qp[l])) {
      i <- proximo(l, piso_qp)
      if (is.na(i)) break
      eleger(i, l)
    }
  }

  # sobras por maiores médias (equivale a D'Hondt entre as listas aptas)
  sobras <- function(apta_l, piso) {
    while (sum(ganhas) < M) {
      cands <- vapply(seq_len(L), function(l) if (apta_l[l]) proximo(l, piso) else NA_integer_,
                      integer(1))
      ok <- !is.na(cands)
      if (!any(ok)) return(FALSE)
      media <- ifelse(ok, vl / (ganhas + 1), -Inf)
      l <- which.max(media)
      eleger(cands[l], l)
    }
    TRUE
  }
  todas <- rep(TRUE, L)
  ok <- switch(regra,
    "dhondt" = sobras(todas, 0),
    "2014"   = sobras(vl >= qe, 0) || sobras(todas, 0),
    "2018"   = sobras(todas, 0.1 * qe) || sobras(todas, 0),
    "2022"   = ,
    "2026"   = sobras(vl >= 0.8 * qe, 0.2 * qe) || sobras(todas, 0),
    "2022_original" = sobras(vl >= 0.8 * qe, 0.2 * qe) || sobras(vl >= 0.8 * qe, 0))
  if (!ok) warning("Cadeiras não preenchidas: caso não coberto")
  eleito
}

# Menor número inteiro de votos que muda o resultado do candidato i.
# Devolve NA se o candidato não é apto (não pode ser eleito) ou se segue eleito com 0 votos.
margem_candidato <- function(i, v, lst, apta, extra, M, regra, eleitos) {
  if (!apta[i]) return(NA_real_)
  status <- eleitos[i]
  vira <- function(d) {
    v2 <- v; v2[i] <- v2[i] + if (status) -d else d
    distribuir(v2, lst, apta, extra, M, regra)[i] != status
  }
  if (status) {
    hi <- v[i]
    if (!vira(hi)) return(NA_real_)
  } else {
    hi <- 1
    while (!vira(hi)) hi <- hi * 2
  }
  lo <- 0
  while (hi - lo > 1) {                       # vira(lo) = FALSE, vira(hi) = TRUE
    mid <- (lo + hi) %/% 2
    if (vira(mid)) hi <- mid else lo <- mid
  }
  hi
}

# Margens de todas as candidaturas de um distrito.
# Positivo = folga do eleito; negativo = déficit do não eleito.
margens_distrito <- function(v, lst, apta, extra, M, regra) {
  eleitos <- distribuir(v, lst, apta, extra, M, regra)
  delta <- vapply(seq_along(v), margem_candidato, numeric(1), v = v, lst = lst, apta = apta,
                  extra = extra, M = M, regra = regra, eleitos = eleitos)
  list(eleito = eleitos, margem = ifelse(eleitos, delta, -delta))
}

# V_L,j de ABD: votos do primeiro não eleito (apto) de cada lista (0 se não houver)
primeiro_nao_eleito <- function(v, lst, apta, eleito) {
  vl <- tapply(ifelse(apta & !eleito, v, -Inf), lst, max)
  out <- as.numeric(vl[as.character(lst)])
  ifelse(is.finite(out), out, 0)
}
