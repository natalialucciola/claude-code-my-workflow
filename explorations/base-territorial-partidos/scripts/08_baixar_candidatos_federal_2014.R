# ==============================================================================
# Preencher a lacuna: candidaturas de Deputado Federal 2014 (com CPF), para
# poder calcular incumbência 2018 -> 2014 (não existia neste projeto; só as
# candidaturas estaduais de 2014 tinham sido preparadas).
#
# Segue exatamente o mesmo padrão usado para 2018/2022 em
# "Código - Preparando dados - Bases 2018 e 2022.qmd" (seção "Coletando
# informações sobre candidaturas de 2018 e 2022 - ElectionsBR"):
#   elections_tse(year, type = "candidate", br_archive = TRUE) |>
#     filter(DS_CARGO == "DEPUTADO FEDERAL") |>
#     select/rename para o padrão do projeto
#
# Status eleitoral (eleito): já disponível em Votacao/2014/votos_mun_2014_df.rds
# via DS_SIT_TOT_TURNO (verificado: 1 status por candidato, sem conflito,
# 6.178 candidatos distintos) — não precisa rebaixar nada para isso.
#
# NOTA DE ESCOPO: só "eleito" é preparado aqui (suficiente para a variável de
# incumbência usada na exploração base-territorial-partidos). "competitivo"
# não é calculado porque exigiria os votos de legenda de 2014 (não baixados
# nesta etapa) para computar o quociente eleitoral corretamente — por isso o
# arquivo de saída se chama "eleitos_2014_df.rds", não
# "eleitos_e_compet_2014_df.rds", para não sugerir paridade de conteúdo com
# os arquivos de 2018/2022/estaduais.
#
# Salva no projeto de análise original (OneDrive), na mesma convenção de
# pastas já usada para 2018/2022 federal e para 2014 estadual — não apenas
# nesta exploração — para que fique disponível para o resto da tese.
# ==============================================================================

library(dplyr)
library(stringr)
library(electionsBR)

tese_path <- "C:/Users/natlu/OneDrive - FINANCIADORA DE ESTUDOS E PROJETOS - FINEP/Tese"

dir.create(file.path(tese_path, "Candidaturas/2014"), showWarnings = FALSE, recursive = TRUE)

# ---- 1. Candidaturas Federal 2014 (electionsBR) ----

message("Baixando candidaturas 2014 (electionsBR)...")
candidatos_2014_raw <- elections_tse(
  year = 2014,
  type = "candidate",
  br_archive = TRUE
)

message("DS_CARGO distintos no download bruto:")
print(unique(candidatos_2014_raw$DS_CARGO))

candidatos_2014 <- candidatos_2014_raw |>
  filter(str_to_upper(DS_CARGO) == "DEPUTADO FEDERAL") |>
  select(
    SQ_CANDIDATO, NR_CPF_CANDIDATO, DS_GENERO, DS_COR_RACA,
    SG_UF, SG_PARTIDO, DS_SITUACAO_CANDIDATURA
  ) |>
  rename(
    sq_candidato         = SQ_CANDIDATO,
    cpfCand              = NR_CPF_CANDIDATO,
    genero               = DS_GENERO,
    raca                 = DS_COR_RACA,
    uf                   = SG_UF,
    partido              = SG_PARTIDO,
    situacao_candidatura = DS_SITUACAO_CANDIDATURA
  ) |>
  mutate(
    sq_candidato = as.character(sq_candidato),
    cpfCand      = as.character(cpfCand)
  )

message("Candidatos Federal 2014 (após filtro de cargo): ", nrow(candidatos_2014))
message("APTO: ", sum(candidatos_2014$situacao_candidatura == "APTO"))

saveRDS(candidatos_2014, file.path(tese_path, "Candidaturas/2014/candidatos2014.rds"))

# ---- 2. Status eleitoral (eleito), a partir dos dados já existentes ----

votos_2014 <- readRDS(file.path(tese_path, "Votacao/2014/votos_mun_2014_df.rds"))

eleitos_2014 <- votos_2014 |>
  distinct(sq_candidato, SG_UF, DS_SIT_TOT_TURNO) |>
  mutate(eleito = as.integer(DS_SIT_TOT_TURNO %in% c(
    "ELEITO", "ELEITO POR QP", "ELEITO POR MÉDIA"
  )))

message("Candidatos com status eleitoral (Votacao/2014): ", nrow(eleitos_2014),
        " (", sum(eleitos_2014$eleito), " eleitos)")

saveRDS(eleitos_2014, file.path(tese_path, "Votacao/2014/eleitos_2014_df.rds"))

# ---- 3. Checagem de cobertura: quantos eleitos 2014 têm CPF em candidatos2014 ----

cpfs_eleitos_2014 <- eleitos_2014 |>
  filter(eleito == 1) |>
  left_join(candidatos_2014 |> select(sq_candidato, cpfCand), by = "sq_candidato")

message("Eleitos 2014 com CPF identificado: ", sum(!is.na(cpfs_eleitos_2014$cpfCand)),
        " de ", nrow(cpfs_eleitos_2014))

message("\n=== Concluído: Candidaturas/2014/candidatos2014.rds e",
        " Votacao/2014/eleitos_2014_df.rds salvos no projeto de análise ===")
