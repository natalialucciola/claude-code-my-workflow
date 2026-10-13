# ==============================================================================
# Script: 01_construir_ql_voto.R
# Purpose: Constrói as bases candidato × município com o quociente locacional
#          do VOTO (QL_voto) para Deputado Federal e Estadual em 2018, 2022 e
#          2026 — substituto do QL do gasto (QL_gasto_eleit) usado no
#          Capítulo 6, enquanto a prestação de contas de 2026 não é publicada.
#
# Definição (por cargo × UF × ano):
#   QL_voto[c, i] = (v[c, i] / V[c]) / (W[i] / W[UF])
#     v[c, i] = votos nominais válidos do candidato c no município i
#     V[c]    = votos nominais válidos do candidato c na UF
#     W[i]    = votos nominais válidos do cargo no município i
#     W[UF]   = votos nominais válidos do cargo na UF
#   QL_voto > 1: o município pesa mais na votação do candidato do que no
#   eleitorado votante do cargo — a "base" do candidato (mesmo limiar do
#   capítulo para o gasto).
#
# Inputs:  data/raw/tse/votacao_candidato_munzona_{2018,2022,2026}.zip
#          data/raw/tse/votacao_partido_munzona_{2022,2026}.zip
#          data/raw/tse/consulta_cand_2026.zip, consulta_vagas_2026.zip
#          data/raw/candidatos{2018,2022}.rds,
#          data/raw/candidatos_estadual_{2018,2022}.rds,
#          data/raw/eleitos_e_compet_{2018,2022}_df.rds,
#          data/raw/eleitos_e_compet_est_{2018,2022}_df.rds
# Outputs: explorations/ql-voto-2026/output/dados/
#            ql_voto_{federal,estadual}_{2018,2022,2026}.rds
#            candidatos_2026.rds (sq_candidato, cpf, atributos, resultado)
#            validacao_regra_qe_2022.csv
#
# Rodar a partir da raiz do repositório (após 00_baixar_dados_tse.R):
#   Rscript explorations/ql-voto-2026/R/01_construir_ql_voto.R
# ==============================================================================

library(tidyverse)
library(data.table)

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

tse_dir <- file.path("data", "raw", "tse")
out_dir <- file.path("explorations", "ql-voto-2026", "output", "dados")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

anos   <- c(2018L, 2022L, 2026L)
cargos <- c(Federal = "DEPUTADO FEDERAL", Estadual = "DEPUTADO ESTADUAL")

# Limiar de competitividade usado nas bases da autora (verificado em
# eleitos_e_compet_2022_df.rds e eleitos_e_compet_est_2018_df.rds: todo
# competitivo tem votos/QE >= 0,10 e todo não competitivo < 0,10).
limiar_competitivo <- 0.10

# ==============================================================================
# 1. FUNÇÕES DE LEITURA
# ==============================================================================

#' Lê, de um zip do TSE, os CSVs por UF (ignora BR/BRASIL e o leiame)
#'
#' @param zip_path Caminho do zip.
#' @param padrao Prefixo dos CSVs dentro do zip.
#' @param colunas Colunas a manter (economiza memória nos arquivos grandes).
#' @return data.table empilhada, com todas as colunas como character.
ler_zip_tse_por_uf <- function(zip_path, padrao, colunas) {
  nomes <- unzip(zip_path, list = TRUE)$Name
  nomes <- nomes[str_detect(nomes, paste0("^", padrao, "_[A-Z]{2}\\.csv$"))]
  nomes <- nomes[!str_detect(nomes, "_(BR|BRASIL)\\.csv$")]
  tmp <- file.path(tempdir(), "tse_unzip")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  partes <- lapply(nomes, function(n) {
    f <- unzip(zip_path, files = n, exdir = tmp)
    d <- fread(f, sep = ";", encoding = "Latin-1", colClasses = "character",
               select = colunas, showProgress = FALSE)
    unlink(f)
    d
  })
  rbindlist(partes)
}

#' Agrega votos de candidato por município (soma das zonas), só 1º turno
#'
#' @param ano Ano da eleição.
#' @return tibble ANO_ELEICAO, cargo, SG_UF, COD_MUN_TSE, sq_candidato,
#'   sg_partido, votos, ds_sit_tot_turno.
ler_votos_candidato <- function(ano) {
  cols <- c("ANO_ELEICAO", "NR_TURNO", "SG_UF", "CD_MUNICIPIO", "DS_CARGO",
            "SQ_CANDIDATO", "SG_PARTIDO", "QT_VOTOS_NOMINAIS_VALIDOS",
            "DS_SIT_TOT_TURNO")
  d <- ler_zip_tse_por_uf(
    file.path(tse_dir, sprintf("votacao_candidato_munzona_%d.zip", ano)),
    sprintf("votacao_candidato_munzona_%d", ano), cols
  )
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos]
  d[, votos := as.numeric(QT_VOTOS_NOMINAIS_VALIDOS)]
  d <- d[, .(votos = sum(votos, na.rm = TRUE)),
         by = .(ANO_ELEICAO, DS_CARGO, SG_UF, CD_MUNICIPIO, SQ_CANDIDATO,
                SG_PARTIDO, DS_SIT_TOT_TURNO)]
  as_tibble(d) |>
    transmute(
      ANO_ELEICAO,
      cargo       = names(cargos)[match(DS_CARGO, cargos)],
      SG_UF,
      COD_MUN_TSE = str_pad(CD_MUNICIPIO, 6, pad = "0"),
      sq_candidato = SQ_CANDIDATO,
      sg_partido  = SG_PARTIDO,
      votos,
      ds_sit_tot_turno = DS_SIT_TOT_TURNO
    )
}

#' Votos válidos por cargo × UF (nominais + legenda), só 1º turno
#'
#' Denominador do quociente eleitoral (QE = votos válidos / vagas).
#' @param ano Ano da eleição.
#' @return tibble ANO_ELEICAO, cargo, SG_UF, votos_validos_uf.
ler_votos_validos_uf <- function(ano) {
  cols <- c("ANO_ELEICAO", "NR_TURNO", "SG_UF", "DS_CARGO",
            "QT_VOTOS_NOMINAIS_VALIDOS", "QT_TOTAL_VOTOS_LEG_VALIDOS")
  d <- ler_zip_tse_por_uf(
    file.path(tse_dir, sprintf("votacao_partido_munzona_%d.zip", ano)),
    sprintf("votacao_partido_munzona_%d", ano), cols
  )
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos]
  d <- d[, .(votos_validos_uf = sum(as.numeric(QT_VOTOS_NOMINAIS_VALIDOS) +
                                      as.numeric(QT_TOTAL_VOTOS_LEG_VALIDOS),
                                    na.rm = TRUE)),
         by = .(ANO_ELEICAO, DS_CARGO, SG_UF)]
  as_tibble(d) |>
    transmute(ANO_ELEICAO, cargo = names(cargos)[match(DS_CARGO, cargos)],
              SG_UF, votos_validos_uf)
}

# ==============================================================================
# 2. QL DO VOTO
# ==============================================================================

#' Calcula QL_voto a partir de votos candidato × município
#'
#' Mantém só pares com votos > 0 (QL = 0 nos demais, irrelevantes para a
#' sobreposição, que usa QL > 1) e candidatos com votação total > 0.
#' @param votos Saída de ler_votos_candidato().
#' @return votos + V_cand, QL_voto.
calcular_ql_voto <- function(votos) {
  votos |>
    filter(votos > 0) |>
    mutate(V_cand = sum(votos), .by = c(ANO_ELEICAO, cargo, sq_candidato)) |>
    mutate(W_mun  = sum(votos), .by = c(ANO_ELEICAO, cargo, SG_UF, COD_MUN_TSE)) |>
    mutate(W_uf   = sum(votos), .by = c(ANO_ELEICAO, cargo, SG_UF)) |>
    # Quociente locacional: participação do município no voto do candidato
    # sobre a participação do município no voto do cargo na UF
    mutate(QL_voto = (votos / V_cand) / (W_mun / W_uf)) |>
    select(-W_mun, -W_uf)
}

# ==============================================================================
# 3. ATRIBUTOS DOS CANDIDATOS
# ==============================================================================

recodificar_raca2 <- function(raca) {
  case_when(
    raca == "BRANCA"                ~ "BRANCA",
    raca %in% c("PRETA", "PARDA")   ~ "NEGRA",
    is.na(raca)                     ~ NA_character_,
    TRUE                            ~ "OUTRA"
  )
}

# Grafia de 2026 para a única sigla que mudou só de escrita
padronizar_sigla <- function(sigla) if_else(sigla == "PC do B", "PCDOB", sigla)

# ---- 2018/2022: bases da autora (mesma fonte do capítulo) ----
atributos_antigos <- function(ano) {
  fed <- readRDS(sprintf("data/raw/candidatos%d.rds", ano)) |>
    transmute(sq_candidato, cpf = cpfCand, genero, raca, cargo = "Federal")
  est <- readRDS(sprintf("data/raw/candidatos_estadual_%d.rds", ano)) |>
    transmute(sq_candidato, cpf = cpfCand, genero, raca, cargo = "Estadual")
  bind_rows(fed, est) |>
    distinct(sq_candidato, cargo, .keep_all = TRUE) |>
    mutate(ANO_ELEICAO = as.character(ano))
}

resultado_antigo <- function(ano) {
  fed <- readRDS(sprintf("data/raw/eleitos_e_compet_%d_df.rds", ano)) |>
    ungroup() |> transmute(sq_candidato, eleito, competitivo, cargo = "Federal")
  est <- readRDS(sprintf("data/raw/eleitos_e_compet_est_%d_df.rds", ano)) |>
    ungroup() |> transmute(sq_candidato, eleito, competitivo, cargo = "Estadual")
  bind_rows(fed, est) |>
    distinct(sq_candidato, cargo, .keep_all = TRUE) |>
    mutate(ANO_ELEICAO = as.character(ano))
}

# ---- 2026: consulta_cand + vagas ----
cand_2026 <- read_delim(
  unz(file.path(tse_dir, "consulta_cand_2026.zip"), "consulta_cand_2026_BRASIL.csv"),
  delim = ";", locale = locale(encoding = "latin1"),
  col_types = cols(.default = "c"), progress = FALSE
) |>
  filter(DS_CARGO %in% cargos) |>
  transmute(
    ANO_ELEICAO = "2026",
    cargo = names(cargos)[match(DS_CARGO, cargos)],
    sq_candidato = SQ_CANDIDATO, cpf = NR_CPF_CANDIDATO,
    titulo = NR_TITULO_ELEITORAL_CANDIDATO,
    genero = DS_GENERO, raca = DS_COR_RACA, sg_partido = SG_PARTIDO,
    nr_partido = NR_PARTIDO, ds_sit_tot_turno_cand = DS_SIT_TOT_TURNO
  )

vagas_2026 <- read_delim(
  unz(file.path(tse_dir, "consulta_vagas_2026.zip"), "consulta_vagas_2026_BRASIL.csv"),
  delim = ";", locale = locale(encoding = "latin1"),
  col_types = cols(.default = "c"), progress = FALSE
) |>
  mutate(DS_CARGO = toupper(DS_CARGO)) |>
  filter(DS_CARGO %in% cargos) |>
  transmute(cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF,
            vagas = as.integer(QT_VAGA))

message("Vagas 2026: ",
        paste(names(tapply(vagas_2026$vagas, vagas_2026$cargo, sum)),
              tapply(vagas_2026$vagas, vagas_2026$cargo, sum), collapse = ", "))

# ==============================================================================
# 4. VALIDAÇÃO DA REGRA DE QE/COMPETITIVO EM 2022
#    Recalcula competitivo para 2022 com os arquivos do TSE e compara com a
#    base da autora — só aplica a regra em 2026 se reproduzir 2022.
# ==============================================================================

#' Classifica eleito/competitivo pela regra do capítulo
#'
#' @param votos_cand tibble com ANO_ELEICAO, cargo, SG_UF, sq_candidato,
#'   V_total, ds_sit_tot_turno.
#' @param validos Saída de ler_votos_validos_uf().
#' @param vagas tibble cargo, SG_UF, vagas.
classificar_resultado <- function(votos_cand, validos, vagas) {
  votos_cand |>
    left_join(validos, by = c("ANO_ELEICAO", "cargo", "SG_UF")) |>
    left_join(vagas, by = c("cargo", "SG_UF")) |>
    mutate(
      QE = votos_validos_uf / vagas,
      eleito = as.numeric(str_detect(ds_sit_tot_turno, "^ELEITO")),
      competitivo = as.numeric(eleito == 1 | V_total / QE >= limiar_competitivo)
    )
}

votos_2022 <- ler_votos_candidato(2022L)
validos_2022 <- ler_votos_validos_uf(2022L)
vagas_2022 <- bind_rows(
  readRDS("data/raw/eleitos_e_compet_2022_df.rds") |> ungroup() |>
    distinct(SG_UF, vagas = cadeiras_fed) |> mutate(cargo = "Federal"),
  readRDS("data/raw/eleitos_e_compet_est_2022_df.rds") |> ungroup() |>
    distinct(SG_UF, vagas = cadeiras_est) |> mutate(cargo = "Estadual")
)

res_2022_recalc <- votos_2022 |>
  summarise(V_total = sum(votos), .by = c(ANO_ELEICAO, cargo, SG_UF, sq_candidato,
                                          ds_sit_tot_turno)) |>
  classificar_resultado(validos_2022, vagas_2022)

validacao_qe <- res_2022_recalc |>
  inner_join(resultado_antigo(2022L), by = c("ANO_ELEICAO", "cargo", "sq_candidato"),
             suffix = c("_recalc", "_autora")) |>
  summarise(
    n = n(),
    concordancia_eleito = mean(eleito_recalc == eleito_autora, na.rm = TRUE),
    concordancia_competitivo = mean(competitivo_recalc == competitivo_autora, na.rm = TRUE),
    .by = cargo
  )
print(validacao_qe)
write_csv(validacao_qe, file.path(out_dir, "validacao_regra_qe_2022.csv"))

if (any(validacao_qe$concordancia_competitivo < 0.99)) {
  warning("Regra de competitivo recalculada concorda < 99% com a base da autora em 2022 — ",
          "revisar antes de interpretar 2026.")
}

# ==============================================================================
# 5. MONTAR AS BASES POR ANO
# ==============================================================================

montar_base <- function(ano) {
  votos <- if (ano == 2022L) votos_2022 else ler_votos_candidato(ano)
  ql <- calcular_ql_voto(votos)

  if (ano < 2026L) {
    base <- ql |>
      left_join(atributos_antigos(ano), by = c("ANO_ELEICAO", "cargo", "sq_candidato")) |>
      left_join(resultado_antigo(ano),  by = c("ANO_ELEICAO", "cargo", "sq_candidato")) |>
      mutate(partido_harm = harmonizar_partido(sg_partido))
  } else {
    resultado_26 <- ql |>
      distinct(ANO_ELEICAO, cargo, SG_UF, sq_candidato, V_total = V_cand, ds_sit_tot_turno) |>
      classificar_resultado(ler_votos_validos_uf(2026L), vagas_2026) |>
      select(ANO_ELEICAO, cargo, sq_candidato, eleito, competitivo)
    base <- ql |>
      left_join(cand_2026 |> select(ANO_ELEICAO, cargo, sq_candidato, cpf, genero, raca),
                by = c("ANO_ELEICAO", "cargo", "sq_candidato")) |>
      left_join(resultado_26, by = c("ANO_ELEICAO", "cargo", "sq_candidato")) |>
      mutate(partido_harm = sg_partido)
  }

  base |>
    mutate(
      partido_harm = padronizar_sigla(partido_harm),
      raca2 = recodificar_raca2(raca)
    ) |>
    select(ANO_ELEICAO, cargo, sq_candidato, cpf, SG_UF, COD_MUN_TSE, votos, V_cand,
           QL_voto, eleito, competitivo, genero, raca, raca2, sg_partido, partido_harm)
}

for (ano in anos) {
  base <- montar_base(ano)
  diag <- base |>
    distinct(cargo, sq_candidato, genero, raca2, eleito, partido_harm) |>
    summarise(
      candidatos = n(),
      eleitos = sum(eleito == 1, na.rm = TRUE),
      sem_genero = sum(is.na(genero)),
      sem_resultado = sum(is.na(eleito)),
      sem_partido = sum(is.na(partido_harm)),
      .by = cargo
    )
  message("\n== ", ano, " ==")
  print(diag)
  for (cg in names(cargos)) {
    arq <- file.path(out_dir, sprintf("ql_voto_%s_%d.rds", tolower(cg), ano))
    saveRDS(filter(base, cargo == cg), arq)
  }
  rm(base)
  gc()
}

saveRDS(cand_2026, file.path(out_dir, "candidatos_2026.rds"))
message("\nBases salvas em ", out_dir)
