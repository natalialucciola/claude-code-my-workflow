# ==============================================================================
# Script: 01_ql_2010_2014.R
# Purpose: Constrói as bases candidato × município com o quociente locacional do
#          VOTO (QL_voto) para Deputado Federal e Estadual em 2010 e 2014, no
#          mesmo formato e com a mesma regra das bases 2018/2022/2026 de
#          explorations/ql-voto-2026/ (01_construir_ql_voto.R):
#            QL_voto[c, i] = (v[c, i] / V[c]) / (W[i] / W[UF])
#          2014 é pré-período do DiD; 2010 só serve para saber onde cada partido
#          tinha base e quem foi eleito em 2010 (transição 2010 → 2014).
# Inputs:  data/raw/tse/{votacao_candidato_munzona,votacao_partido_munzona,
#            consulta_cand,consulta_vagas}_{2010,2014}.zip
#          data/raw/candidatos2014.rds, candidatos_estadual_2014.rds,
#          eleitos_2014_df.rds, eleitos_e_compet_est_2014_df.rds (validação)
# Outputs: explorations/ec111-did-ql-municipio/output/dados/
#            ql_voto_{federal,estadual}_{2010,2014}.rds
#            validacao_regra_2014.csv
# Rodar a partir da raiz do repositório (após 00_dados.R):
#   Rscript explorations/ec111-did-ql-municipio/R/01_ql_2010_2014.R
# ==============================================================================

library(tidyverse)
library(data.table)

tse_dir <- file.path("data", "raw", "tse")
out_dir <- file.path("explorations", "ec111-did-ql-municipio", "output", "dados")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cargos <- c(Federal = "DEPUTADO FEDERAL", Estadual = "DEPUTADO ESTADUAL")
limiar_competitivo <- 0.10   # votos/QE, mesma regra das bases da autora

# Em 2010 o TSE grava "ELEITO" e "MÉDIA"; a partir de 2014, "ELEITO POR QP/MÉDIA"
situacoes_eleito <- c("ELEITO", "MÉDIA", "ELEITO POR QP", "ELEITO POR MÉDIA")

# ==============================================================================
# 1. LEITURA
# ==============================================================================

#' Lê, de um zip do TSE, os CSVs por UF (ignora BR/BRASIL)
#'
#' @param zip_path Caminho do zip.
#' @param padrao Prefixo dos CSVs dentro do zip.
#' @param colunas Colunas a manter.
#' @return data.table empilhada.
ler_zip_tse_por_uf <- function(zip_path, padrao, colunas) {
  nomes <- unzip(zip_path, list = TRUE)$Name
  nomes <- nomes[str_detect(nomes, paste0("^", padrao, "_[A-Z]{2}\\.csv$"))]
  nomes <- nomes[!str_detect(nomes, "_(BR|BRASIL)\\.csv$")]
  tmp <- file.path(tempdir(), "tse_unzip")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  rbindlist(lapply(nomes, function(n) {
    f <- unzip(zip_path, files = n, exdir = tmp)
    d <- fread(f, sep = ";", encoding = "Latin-1", colClasses = "character",
               select = colunas, showProgress = FALSE)
    unlink(f)
    d
  }))
}

#' Votos de candidato por município (soma das zonas), 1º turno, só candidaturas aptas
#'
#' Em 2010/2014 o arquivo só tem QT_VOTOS_NOMINAIS; restringir a APTO reproduz o
#' voto nominal válido (os votos de candidaturas inaptas vêm zerados).
#' @param ano 2010 ou 2014.
#' @return tibble ANO_ELEICAO, cargo, SG_UF, COD_MUN_TSE, sq_candidato, sg_partido,
#'   votos, ds_sit_tot_turno.
ler_votos_candidato <- function(ano) {
  cols <- c("ANO_ELEICAO", "NR_TURNO", "SG_UF", "CD_MUNICIPIO", "DS_CARGO", "SQ_CANDIDATO",
            "SG_PARTIDO", "DS_SITUACAO_CANDIDATURA", "QT_VOTOS_NOMINAIS", "DS_SIT_TOT_TURNO")
  d <- ler_zip_tse_por_uf(file.path(tse_dir, sprintf("votacao_candidato_munzona_%d.zip", ano)),
                          sprintf("votacao_candidato_munzona_%d", ano), cols)
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos & DS_SITUACAO_CANDIDATURA == "APTO"]
  d <- d[, .(votos = sum(as.numeric(QT_VOTOS_NOMINAIS), na.rm = TRUE)),
         by = .(ANO_ELEICAO, DS_CARGO, SG_UF, CD_MUNICIPIO, SQ_CANDIDATO, SG_PARTIDO,
                DS_SIT_TOT_TURNO)]
  as_tibble(d) |>
    transmute(ANO_ELEICAO, cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF,
              COD_MUN_TSE = str_pad(CD_MUNICIPIO, 6, pad = "0"), sq_candidato = SQ_CANDIDATO,
              sg_partido = SG_PARTIDO, votos, ds_sit_tot_turno = DS_SIT_TOT_TURNO)
}

#' Votos válidos (nominais + legenda) por cargo × UF — denominador do QE
ler_votos_validos_uf <- function(ano) {
  cols <- c("ANO_ELEICAO", "NR_TURNO", "SG_UF", "DS_CARGO", "QT_VOTOS_NOMINAIS",
            "QT_VOTOS_LEGENDA")
  d <- ler_zip_tse_por_uf(file.path(tse_dir, sprintf("votacao_partido_munzona_%d.zip", ano)),
                          sprintf("votacao_partido_munzona_%d", ano), cols)
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos]
  d <- d[, .(votos_validos_uf = sum(as.numeric(QT_VOTOS_NOMINAIS) +
                                      as.numeric(QT_VOTOS_LEGENDA), na.rm = TRUE)),
         by = .(ANO_ELEICAO, DS_CARGO, SG_UF)]
  as_tibble(d) |>
    transmute(ANO_ELEICAO, cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF,
              votos_validos_uf)
}

#' Vagas por cargo × UF (a coluna é QT_VAGAS em 2010 e QT_VAGA a partir de 2014)
ler_vagas <- function(ano) {
  col_vaga <- if (ano == 2010L) "QT_VAGAS" else "QT_VAGA"
  d <- ler_zip_tse_por_uf(file.path(tse_dir, sprintf("consulta_vagas_%d.zip", ano)),
                          sprintf("consulta_vagas_%d", ano), c("SG_UF", "DS_CARGO", col_vaga))
  setnames(d, col_vaga, "vagas")
  d[, DS_CARGO := toupper(DS_CARGO)]
  v <- as_tibble(d[DS_CARGO %in% cargos]) |>
    transmute(cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF, vagas = as.integer(vagas)) |>
    distinct()
  stopifnot(!anyDuplicated(v[c("cargo", "SG_UF")]))
  message("Vagas ", ano, ": ", paste(names(tapply(v$vagas, v$cargo, sum)),
                                    tapply(v$vagas, v$cargo, sum), collapse = ", "))
  v
}

#' CPF, gênero e raça das candidaturas (consulta_cand do TSE)
ler_candidaturas <- function(ano) {
  cols <- c("SQ_CANDIDATO", "DS_CARGO", "NR_CPF_CANDIDATO", "DS_GENERO", "DS_COR_RACA")
  d <- ler_zip_tse_por_uf(file.path(tse_dir, sprintf("consulta_cand_%d.zip", ano)),
                          sprintf("consulta_cand_%d", ano), cols)
  d[, DS_CARGO := toupper(DS_CARGO)]
  as_tibble(unique(d[DS_CARGO %in% cargos], by = "SQ_CANDIDATO")) |>
    transmute(sq_candidato = SQ_CANDIDATO, cpf_tse = NR_CPF_CANDIDATO,
              genero_tse = DS_GENERO, raca_tse = na_if(DS_COR_RACA, "#NULO#"))
}

# ==============================================================================
# 2. QL E RESULTADO
# ==============================================================================

#' QL_voto (idêntico a calcular_ql_voto() de ql-voto-2026)
calcular_ql_voto <- function(votos) {
  votos |>
    filter(votos > 0) |>
    mutate(V_cand = sum(votos), .by = c(ANO_ELEICAO, cargo, sq_candidato)) |>
    mutate(W_mun  = sum(votos), .by = c(ANO_ELEICAO, cargo, SG_UF, COD_MUN_TSE)) |>
    mutate(W_uf   = sum(votos), .by = c(ANO_ELEICAO, cargo, SG_UF)) |>
    # participação do município no voto do candidato ÷ participação no voto do cargo na UF
    mutate(QL_voto = (votos / V_cand) / (W_mun / W_uf)) |>
    select(-W_mun, -W_uf)
}

#' Eleito e competitivo (votos ≥ 10% do QE ou eleito)
classificar_resultado <- function(ql, validos, vagas) {
  ql |>
    distinct(ANO_ELEICAO, cargo, SG_UF, sq_candidato, V_cand, ds_sit_tot_turno) |>
    left_join(validos, by = c("ANO_ELEICAO", "cargo", "SG_UF")) |>
    left_join(vagas, by = c("cargo", "SG_UF")) |>
    mutate(QE = votos_validos_uf / vagas,
           eleito = as.numeric(ds_sit_tot_turno %in% situacoes_eleito),
           competitivo = as.numeric(eleito == 1 | V_cand / QE >= limiar_competitivo)) |>
    select(ANO_ELEICAO, cargo, sq_candidato, eleito, competitivo)
}

recodificar_raca2 <- function(raca) {
  case_when(raca == "BRANCA" ~ "BRANCA", raca %in% c("PRETA", "PARDA") ~ "NEGRA",
            is.na(raca) ~ NA_character_, TRUE ~ "OUTRA")
}

# ==============================================================================
# 3. MONTAR 2010 E 2014
# ==============================================================================

montar_base <- function(ano) {
  ql <- calcular_ql_voto(ler_votos_candidato(ano))
  res <- classificar_resultado(ql, ler_votos_validos_uf(ano), ler_vagas(ano))
  cand <- ler_candidaturas(ano)

  base <- ql |>
    left_join(res, by = c("ANO_ELEICAO", "cargo", "sq_candidato")) |>
    left_join(cand, by = "sq_candidato")

  if (ano == 2014L) {
    # Gênero/raça/CPF das bases da autora (mesma fonte de 2018/2022); TSE se faltar
    autora <- bind_rows(readRDS("data/raw/candidatos2014.rds"),
                        readRDS("data/raw/candidatos_estadual_2014.rds")) |>
      distinct(sq_candidato, .keep_all = TRUE) |>
      transmute(sq_candidato, cpf_a = cpfCand, genero_a = genero, raca_a = raca)
    base <- base |>
      left_join(autora, by = "sq_candidato") |>
      mutate(cpf = coalesce(cpf_a, cpf_tse), genero = coalesce(genero_a, genero_tse),
             raca = coalesce(raca_a, raca_tse))
  } else {
    # 2010: o TSE não coletava cor/raça
    base <- base |> mutate(cpf = cpf_tse, genero = genero_tse, raca = NA_character_)
  }

  base |>
    mutate(raca2 = recodificar_raca2(raca)) |>
    select(ANO_ELEICAO, cargo, sq_candidato, cpf, SG_UF, COD_MUN_TSE, votos, V_cand,
           QL_voto, eleito, competitivo, genero, raca, raca2, sg_partido)
}

bases <- map(c(2010L, 2014L), montar_base) |> set_names(c("2010", "2014"))

# ==============================================================================
# 4. VALIDAÇÃO 2014 CONTRA AS BASES DA AUTORA
# ==============================================================================

cand14 <- bases[["2014"]] |> distinct(cargo, sq_candidato, eleito, competitivo)
autora14 <- bind_rows(
  readRDS("data/raw/eleitos_2014_df.rds") |> ungroup() |>
    transmute(sq_candidato, eleito_a = eleito, competitivo_a = NA_real_, cargo = "Federal"),
  readRDS("data/raw/eleitos_e_compet_est_2014_df.rds") |> ungroup() |>
    transmute(sq_candidato, eleito_a = eleito, competitivo_a = competitivo, cargo = "Estadual")
)
validacao <- cand14 |>
  inner_join(autora14, by = c("cargo", "sq_candidato")) |>
  summarise(n = n(), eleitos_recalc = sum(eleito), eleitos_autora = sum(eleito_a),
            concord_eleito = mean(eleito == eleito_a),
            concord_competitivo = mean(competitivo == competitivo_a), .by = cargo)
print(validacao)
write_csv(validacao, file.path(out_dir, "validacao_regra_2014.csv"))
if (any(validacao$concord_eleito < 0.99) ||
    any(validacao$concord_competitivo < 0.99, na.rm = TRUE)) {
  warning("Regra de eleito/competitivo de 2014 concorda < 99% com a base da autora.")
}

# ==============================================================================
# 5. SALVAR + DIAGNÓSTICO
# ==============================================================================

for (a in names(bases)) {
  d <- bases[[a]]
  diag <- d |>
    distinct(cargo, sq_candidato, genero, raca2, eleito, cpf) |>
    summarise(candidatos = n(), eleitos = sum(eleito, na.rm = TRUE),
              sem_genero = sum(is.na(genero)), sem_raca = sum(is.na(raca2)),
              sem_cpf = sum(is.na(cpf)), .by = cargo)
  message("\n== ", a, " ==")
  print(diag)
  for (cg in names(cargos)) {
    saveRDS(filter(d, cargo == cg),
            file.path(out_dir, sprintf("ql_voto_%s_%s.rds", tolower(cg), a)))
  }
}
message("Bases salvas em ", out_dir)
