# =============================================================================
# Margem de votos de cada candidatura em lista aberta (OLPR) — regra brasileira
#
# Protótipo para comparar Avelino, Biderman & Desposato (2022, BPSR 16(1)) e
# Luechinger, Schelker & Schmid (2024, Political Analysis 32). As duas medidas
# partem do mesmo experimento mental: muda-se apenas o voto do candidato i
# (que conta também para a lista dele), os demais votos ficam fixos.
#
# Em vez das fórmulas fechadas (que não cobrem as cláusulas de 10%/80%/20% do
# QE, que dependem do total de votos válidos), calculamos a margem por busca:
# o menor número inteiro de votos que, somado (não eleito) ou retirado (eleito)
# do candidato i, muda seu resultado, refazendo a distribuição completa.
#
# Empates não são modelados (decide a ordem dos dados; a lei usa a idade do
# candidato, CE art. 110). LSS definem a margem no ponto de empate; aqui ela é
# o voto que vira o resultado. Com votos reais a diferença é desprezível; nos
# exemplos de brinquedo dos artigos pode chegar a 1 voto × divisor da média.
# =============================================================================

# Quociente eleitoral (CE art. 106): fração <= 0,5 desprezada, > 0,5 arredonda
quociente_eleitoral <- function(validos, cadeiras) {
  q <- validos / cadeiras
  if (q - floor(q) > 0.5) ceiling(q) else floor(q)
}

# Distribui as cadeiras de um distrito (UF × cargo).
#   cand:    data.frame com lista, cand, votos (votos nominais)
#   legenda: vetor nomeado de votos de legenda por lista (pode faltar lista)
#   regra:   "2014" (só listas com QE disputam sobras, sem cláusula individual),
#            "2018" (todas as listas disputam sobras; candidato >= 10% QE),
#            "2022" (QP: candidato >= 10% QE; sobras: lista >= 80% QE e
#                    candidato >= 20% QE; 3ª fase: listas >= 80% QE, maiores
#                    médias, sem cláusula individual — regra aplicada em 2022,
#                    antes das ADIs 7228/7263/7325)
#            "dhondt" (D'Hondt puro, sem cláusulas — para os exemplos)
# Devolve o vetor lógico de eleitos, na ordem de cand.
distribuir <- function(cand, legenda, cadeiras, regra = c("2014", "2018", "2022", "dhondt")) {
  regra <- match.arg(regra)
  listas <- unique(cand$lista)
  v_lista <- vapply(listas, function(l) sum(cand$votos[cand$lista == l]) +
                      (if (l %in% names(legenda)) legenda[[l]] else 0), numeric(1))
  names(v_lista) <- listas
  qe <- quociente_eleitoral(sum(v_lista), cadeiras)

  # ordem de cada lista: votos decrescentes (empate: ordem de entrada)
  ordem <- lapply(listas, function(l) {
    idx <- which(cand$lista == l)
    idx[order(-cand$votos[idx])]
  })
  names(ordem) <- listas

  eleito <- rep(FALSE, nrow(cand))
  ganhas <- setNames(integer(length(listas)), listas)

  # próximo candidato da lista l com votos >= piso (NA se não houver)
  proximo <- function(l, piso) {
    idx <- ordem[[l]][!eleito[ordem[[l]]] & cand$votos[ordem[[l]]] >= piso]
    if (length(idx)) idx[1] else NA_integer_
  }

  piso_qp <- switch(regra, "2014" = 0, "dhondt" = 0, 0.1 * qe)
  if (regra != "dhondt") {
    # 1ª fase: quociente partidário
    qp <- floor(v_lista / qe)
    for (l in listas) for (k in seq_len(qp[[l]])) {
      i <- proximo(l, piso_qp)
      if (is.na(i)) break
      eleito[i] <- TRUE; ganhas[[l]] <- ganhas[[l]] + 1L
    }
  }

  # sobras por maiores médias (equivale a D'Hondt entre as listas aptas)
  apta <- switch(regra,
                 "2014"   = v_lista >= qe,
                 "2018"   = rep(TRUE, length(listas)),
                 "2022"   = v_lista >= 0.8 * qe,
                 "dhondt" = rep(TRUE, length(listas)))
  names(apta) <- listas
  piso_sobra <- switch(regra, "2014" = 0, "2018" = 0.1 * qe, "2022" = 0.2 * qe, "dhondt" = 0)

  distribuir_sobras <- function(piso) {
    while (sum(ganhas) < cadeiras) {
      cands <- vapply(listas, function(l) if (apta[[l]]) proximo(l, piso) else NA_integer_, integer(1))
      ok <- !is.na(cands)
      if (!any(ok)) return(invisible(FALSE))
      media <- ifelse(ok, v_lista / (ganhas + 1), -Inf)
      l <- listas[which.max(media)]
      eleito[cands[[l]]] <<- TRUE; ganhas[[l]] <<- ganhas[[l]] + 1L
    }
    invisible(TRUE)
  }
  completou <- distribuir_sobras(piso_sobra)
  if (!completou && regra == "2022") completou <- distribuir_sobras(0)   # 3ª fase
  if (!completou) warning("Cadeiras não preenchidas: caso não coberto pelo protótipo")
  eleito
}

# Menor número inteiro de votos que muda o resultado do candidato i
margem_candidato <- function(i, cand, legenda, cadeiras, regra, eleitos = NULL) {
  if (is.null(eleitos)) eleitos <- distribuir(cand, legenda, cadeiras, regra)
  status <- eleitos[i]
  vira <- function(d) {
    c2 <- cand
    c2$votos[i] <- c2$votos[i] + if (status) -d else d
    distribuir(c2, legenda, cadeiras, regra)[i] != status
  }
  # eleito: retirar até todos os votos; não eleito: busca exponencial do teto
  hi <- if (status) cand$votos[i] else 1
  if (!status) while (!vira(hi)) hi <- hi * 2
  if (status && !vira(hi)) return(NA_real_)   # eleito mesmo com zero votos
  lo <- 0
  while (hi - lo > 1) {                       # vira(lo) = FALSE, vira(hi) = TRUE
    mid <- (lo + hi) %/% 2
    if (vira(mid)) hi <- mid else lo <- mid
  }
  hi
}

# Margem com sinal (positivo = folga do eleito; negativo = déficit do não
# eleito), a variável de corte de ABD e a de LSS
margens <- function(cand, legenda, cadeiras, regra, eleitorado = NA_real_) {
  eleitos <- distribuir(cand, legenda, cadeiras, regra)
  delta <- vapply(seq_len(nrow(cand)), margem_candidato, numeric(1),
                  cand = cand, legenda = legenda, cadeiras = cadeiras,
                  regra = regra, eleitos = eleitos)
  margem <- ifelse(eleitos, delta, -delta)
  # V_L,j: votos do primeiro não eleito da lista j (0 se todos eleitos)
  v_l <- vapply(cand$lista, function(l) {
    v <- cand$votos[cand$lista == l & !eleitos]
    if (length(v)) max(v) else 0
  }, numeric(1))
  data.frame(cand, eleito = eleitos, margem = margem,
             tau = cand$votos - margem,                    # limiar de ABD
             rv_abd = margem / (cand$votos + v_l),         # (V - tau) / (V + V_L)
             rv_lss = margem / eleitorado)                 # margem / eleitorado
}
