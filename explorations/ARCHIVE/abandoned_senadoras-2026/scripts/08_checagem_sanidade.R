# =============================================================================
# 08_checagem_sanidade.R
# Objetivo: checar se os números produzidos pelo pipeline batem com os
#           números já apurados manualmente (fora do R, via reportagens e
#           checagem cruzada de fontes) antes de escrever o artigo. Ver
#           plano, Seção 7 (checklist), item 9.
#
# Inputs:  outputs/tabelas/pp1_serie_nacional.csv
#          outputs/tabelas/pp1_serie_uf.csv
# Outputs: apenas mensagens no console (PASS/FAIL por checagem). Se algo
#          falhar, o problema está upstream (provavelmente em
#          02_harmoniza_schema.R) — não prosseguir para a redação do artigo
#          até resolver.
# =============================================================================

library(dplyr)
library(readr)

serie_nacional <- read_csv("outputs/tabelas/pp1_serie_nacional.csv")
serie_uf <- read_csv("outputs/tabelas/pp1_serie_uf.csv")

checagem <- function(nome, condicao) {
  status <- if (isTRUE(condicao)) "PASS" else "FAIL"
  cat(sprintf("[%s] %s\n", status, nome))
}

linha_2026 <- serie_nacional %>% filter(ano == 2026)

checagem(
  "Nº de candidatas ao Senado em 2026 é 69",
  isTRUE(linha_2026$n_candidatas == 69)
)

checagem(
  "Total de candidaturas ao Senado em 2026 é 315",
  isTRUE(linha_2026$n_total == 315)
)

checagem(
  "% de candidatas em 2026 é ~22%",
  isTRUE(abs(linha_2026$pct_candidatas - 0.22) < 0.01)
)

# TODO: checar por UF — RN, SC, SP com 5 candidatas cada (máximo);
# AC, AL, AM, BA, MS, PB, SE, TO com 1 candidata cada (mínimo); todos os 27
# estados/DF com >= 1 candidata.
#
# top_uf <- serie_uf %>% filter(ano == 2026) %>% arrange(desc(n_candidatas))
# checagem("Estados com mais candidatas (5) são RN, SC, SP", ...)
# checagem("Todos os 27 estados/DF têm >= 1 candidata em 2026", all(...))

cat("\nSe todas as checagens acima estiverem PASS, o pipeline está\n")
cat("consistente com a apuração manual e é seguro prosseguir para a\n")
cat("redação do artigo (estrutura sugerida no plano, Seção 6).\n")
