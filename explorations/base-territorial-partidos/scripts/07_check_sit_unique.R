library(dplyr)
df <- readRDS("C:/Users/natlu/OneDrive - FINANCIADORA DE ESTUDOS E PROJETOS - FINEP/Tese/Votacao/2014/votos_mun_2014_df.rds")

check <- df |> distinct(sq_candidato, DS_SIT_TOT_TURNO) |> count(sq_candidato) |> filter(n > 1)
cat("Candidatos com mais de um DS_SIT_TOT_TURNO distinto:", nrow(check), "\n")
cat("Total de candidatos distintos:", n_distinct(df$sq_candidato), "\n")
