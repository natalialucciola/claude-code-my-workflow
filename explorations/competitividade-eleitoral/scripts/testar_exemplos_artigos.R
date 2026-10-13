# Confere as funções de margem nos exemplos numéricos dos dois artigos
# Rodar da raiz do repositório:
#   Rscript explorations/competitividade-eleitoral/scripts/testar_exemplos_artigos.R
source("explorations/competitividade-eleitoral/R/funcoes_margem.R")

# --- ABD (2022), Tabela 02: 4 listas, 4 cadeiras, 100 eleitores -------------
cand <- c("Lara", "Rosa", "Julia", "Alice",
          "Miriam", "Joao", "Angelica", "Darcy", "Carlos",
          "Ruy", "Antonio", "Jorge", "Udson", "Patricia",
          "Cesar", "Marta", "Nelson", "Ze", "Walter")
lst   <- rep(1:4, c(4, 5, 5, 5))                    # W, X, Y, Z
v     <- c(3, 2, 1, 1, 6, 5, 4, 3, 1, 11, 8, 7, 2, 0, 23, 5, 4, 3, 2)
extra <- c(0, 1, 8, 0)                              # votos de legenda
apta  <- rep(TRUE, length(v))

# O resultado da tabela (Z 2, Y 1, X 1) é o de D'Hondt entre todas as listas;
# com a regra de 2014 (só listas com QE = 25 disputam sobras) Y levaria 2.
r <- margens_distrito(v, lst, apta, extra, 4, "dhondt")
v_l <- primeiro_nao_eleito(v, lst, apta, r$eleito)
print(data.frame(cand, v, eleito = r$eleito, margem = r$margem,
                 rv_abd = round(r$margem / (v + v_l), 3)))
stopifnot(identical(cand[r$eleito], c("Miriam", "Ruy", "Cesar", "Marta")))
# Antonio: limiar interpartidário. ABD dizem 1 voto (p. 12, empate em 18,5) e
# 2 votos (p. 15, vitória estrita: 38/2 = 19 > 18,5); aceitamos as duas
stopifnot(r$margem[cand == "Antonio"] %in% c(-1, -2))
cat("\nRegra 2014 no mesmo exemplo (eleitos):",
    cand[distribuir(v, lst, apta, extra, 4, "2014")], "\n")

# --- LSS (2024), exemplo D'Hondt: P1 45, P2 35, P3 20; 3 cadeiras ------------
cand2 <- paste0(rep(c("P1", "P2", "P3"), each = 3), "_C", 1:3)
v2    <- c(25, 15, 5, 22, 8, 5, 8, 7, 5)
lst2  <- rep(1:3, each = 3)
r2 <- margens_distrito(v2, lst2, rep(TRUE, 9), c(0, 0, 0), 3, "dhondt")
print(data.frame(cand2, v2, eleito = r2$eleito, margem = r2$margem))
# LSS: margem de C2 de P2 = -10 no ponto de empate (45/2 = 22,5); estrita = -11
stopifnot(r2$margem[cand2 == "P2_C2"] %in% c(-10, -11))
# P2_C1: margem de partido +15 (P2 cai a 20 e empata com P3) e de candidato +14
# (empata com P2_C2 em 8); com -15 perde pelos dois lados
stopifnot(r2$margem[cand2 == "P2_C1"] %in% c(14, 15))
cat("Todos os testes passaram.\n")
