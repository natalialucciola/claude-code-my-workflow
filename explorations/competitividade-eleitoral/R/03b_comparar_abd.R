# =============================================================================
# 03b — Compara a margem calculada aqui com a variável de corte publicada por
#       Avelino, Biderman & Desposato (2022), Deputado Federal 2014
#
# Entrada: data/processed/margem_resultado.rds (script 03)
#          data/raw/abd/ReplicationAvelinoBidermanDesposato.tab
#            (Harvard Dataverse doi:10.7910/DVN/5GVHTE; o código que gera `rv` não foi
#             publicado, então esta é a única checagem externa possível)
# Saída:   explorations/competitividade-eleitoral/output/comparacao_abd_2014.csv
#
#   Rscript explorations/competitividade-eleitoral/R/03b_comparar_abd.R
# =============================================================================
library(data.table)

dir_out <- file.path("explorations", "competitividade-eleitoral", "output")
res <- readRDS(file.path("data", "processed", "margem_resultado.rds"))
abd <- fread(file.path("data", "raw", "abd", "ReplicationAvelinoBidermanDesposato.tab"))
# na base de ABD, `uf` é a posição alfabética; a sigla vem do código IBGE (uf_cod)
ibge <- c("11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR", "15" = "PA", "16" = "AP",
          "17" = "TO", "21" = "MA", "22" = "PI", "23" = "CE", "24" = "RN", "25" = "PB",
          "26" = "PE", "27" = "AL", "28" = "SE", "29" = "BA", "31" = "MG", "32" = "ES",
          "33" = "RJ", "35" = "SP", "41" = "PR", "42" = "SC", "43" = "RS", "50" = "MS",
          "51" = "MT", "52" = "GO", "53" = "DF")
abd[, uf := unname(ibge[as.character(uf_cod)])]
abd <- abd[ano == 2014L, .(uf, numero_partido = as.character(numero_partido), votos_abd = votos,
                           eleito_abd = eleito, rv)]

nosso <- res[ano == 2014L & cd_cargo == 6L & apta,
             .(uf, numero_partido = as.character(nr_partido), votos_nosso = votos, eleito,
               rv_abd, nome)]

# Chave: UF + partido + votos (os nomes da CEPESP e do TSE têm grafias diferentes).
# Votos repetidos dentro de UF × partido são raros; esses casos ficam de fora.
abd[, k := .N, by = .(uf, numero_partido, votos_abd)]
nosso[, k := .N, by = .(uf, numero_partido, votos_nosso)]
m <- merge(abd[k == 1L], nosso[k == 1L],
           by.x = c("uf", "numero_partido", "votos_abd"),
           by.y = c("uf", "numero_partido", "votos_nosso"))

cat("Candidatos ABD 2014:", nrow(abd), "| pareados:", nrow(m), "\n")
cat("Mesmo resultado (eleito):", mean(m$eleito_abd == m$eleito), "\n")
cat("Correlação rv × rv_abd:", round(cor(m$rv, m$rv_abd, use = "complete.obs"), 4), "\n")
cat("Iguais ao centésimo:", round(mean(abs(m$rv - m$rv_abd) < 0.005, na.rm = TRUE), 4), "\n")
cat("Iguais ao centésimo, |rv| < 0,1:",
    round(m[abs(rv) < 0.1, mean(abs(rv - rv_abd) < 0.005, na.rm = TRUE)], 4), "\n")
m[, dif := rv_abd - rv]
print(m[, .(n = .N, dif_mediana = median(dif, na.rm = TRUE),
            dif_p90_abs = quantile(abs(dif), 0.9, na.rm = TRUE)), by = eleito])
fwrite(m[order(-abs(dif))], file.path(dir_out, "comparacao_abd_2014.csv"))
