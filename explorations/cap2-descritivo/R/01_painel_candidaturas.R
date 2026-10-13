# ==============================================================================
# Script: 01_painel_candidaturas.R
# Purpose: Painel candidato × ano (2014, 2018, 2022, 2026) para Deputado Federal
#          e Estadual, base do Capítulo 2 (análise descritiva). Uma regra única
#          para os quatro pleitos:
#   - universo: candidaturas com >= 1 voto nominal válido no 1º turno
#   - votos válidos: QT_VOTOS_NOMINAIS_VALIDOS (2018+); em 2014 o arquivo só
#     traz QT_VOTOS_NOMINAIS, e são válidos os votos de candidaturas DEFERIDAS
#     (com ou sem recurso)
#   - eleito: DS_SIT_TOT_TURNO "ELEITO POR QP" / "ELEITO POR MÉDIA"
#   - competitivo: eleito ou votos >= 10% do quociente eleitoral da UF
#     (QE = votos válidos nominais + de legenda / vagas) — regra das bases da
#     autora, validada contra elas ao final do script
#   - geografia do voto: base = municípios com QL_voto > 1 e >= 2,5% dos votos
#     do candidato (explorations/ql-voto-2026, R/05b_calibracao_base_voto.R)
#
# Inputs:  data/raw/tse/consulta_cand_{2014,2018,2022,2026}.zip
#          data/raw/tse/votacao_candidato_munzona_{2014,...,2026}.zip
#          data/raw/tse/votacao_partido_munzona_{2014,...,2026}.zip
#          data/raw/tse/consulta_vagas_{2014,...,2026}.zip
#          data/raw/capitais.rds
#          data/raw/eleitos_e_compet_est_{2014,2018,2022}_df.rds,
#          data/raw/eleitos_e_compet_{2018,2022}_df.rds (só validação)
#          explorations/cap2-descritivo/dados/classificacao_ideologica.csv
# Outputs: explorations/cap2-descritivo/output/dados/painel_candidaturas.rds
#          explorations/cap2-descritivo/output/validacao_resultado.csv
#          explorations/cap2-descritivo/output/registros_consulta_cand.csv
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/cap2-descritivo/R/01_painel_candidaturas.R
# ==============================================================================

library(tidyverse)
library(data.table)

tse_dir  <- file.path("data", "raw", "tse")
base_dir <- file.path("explorations", "cap2-descritivo")
out_dir  <- file.path(base_dir, "output")
dados_out <- file.path(out_dir, "dados")
dir.create(dados_out, showWarnings = FALSE, recursive = TRUE)

anos   <- c(2014L, 2018L, 2022L, 2026L)
cargos <- c(Federal = "DEPUTADO FEDERAL", Estadual = "DEPUTADO ESTADUAL")

limiar_competitivo <- 0.10   # fração do QE (regra das bases da autora)
fatia_base_voto    <- 0.025  # piso da base territorial do voto (ql-voto-2026)

regioes <- c(
  AC = "Norte", AM = "Norte", AP = "Norte", PA = "Norte", RO = "Norte", RR = "Norte",
  TO = "Norte", AL = "Nordeste", BA = "Nordeste", CE = "Nordeste", MA = "Nordeste",
  PB = "Nordeste", PE = "Nordeste", PI = "Nordeste", RN = "Nordeste", SE = "Nordeste",
  DF = "Centro-Oeste", GO = "Centro-Oeste", MS = "Centro-Oeste", MT = "Centro-Oeste",
  ES = "Sudeste", MG = "Sudeste", RJ = "Sudeste", SP = "Sudeste",
  PR = "Sul", RS = "Sul", SC = "Sul"
)

# ==============================================================================
# 1. PARTIDOS — renomeações (mesma legenda) e sucessão até 2026 (fusões)
# ==============================================================================

# Mudança só de nome: a posição ideológica é a da sigla atual
renomeacoes <- c(
  "PMDB" = "MDB", "PT do B" = "AVANTE", "SD" = "SOLIDARIEDADE", "PPS" = "CIDADANIA",
  "PR" = "PL", "PRB" = "REPUBLICANOS", "PTN" = "PODE", "PTC" = "AGIR", "PSDC" = "DC",
  "PEN" = "PATRIOTA", "PC do B" = "PCDOB", "PCdoB" = "PCDOB"
)
# Fusões/incorporações: identidade do partido em 2026, para séries por partido
sucessao_2026 <- c(
  "DEM" = "UNIÃO", "PSL" = "UNIÃO", "PHS" = "PODE", "PSC" = "PODE", "PPL" = "PCDOB",
  "PRP" = "PRD", "PATRIOTA" = "PRD", "PTB" = "PRD", "PROS" = "SOLIDARIEDADE",
  "PMN" = "MOBILIZA", "PMB" = "DEMOCRATA"
)
recodificar <- function(x, mapa) if_else(x %in% names(mapa), unname(mapa[x]), x)

ideologia <- read_csv(file.path(base_dir, "dados", "classificacao_ideologica.csv"),
                      show_col_types = FALSE) |>
  select(sigla, posicao)

# Cortes de Bolognesi, Ribeiro, Codato & Silva (2025), agregados em três blocos
# (o centro, 4,5–5,5, está vazio na rodada de 2022)
bloco_ideologico <- function(p) {
  case_when(
    is.na(p)  ~ NA_character_,
    p <= 4.49 ~ "Esquerda",
    p <= 5.50 ~ "Centro",
    p <= 7.00 ~ "Centro-direita",
    TRUE      ~ "Direita"
  )
}

# ==============================================================================
# 2. LEITURA DOS ARQUIVOS DO TSE
# ==============================================================================

#' Lê CSVs de um zip do TSE (por UF, ou o arquivo BRASIL), só colunas pedidas
ler_zip <- function(zip_path, padrao, colunas, brasil = FALSE) {
  nomes <- unzip(zip_path, list = TRUE)$Name
  alvo <- if (brasil) {
    nomes[str_detect(nomes, paste0(padrao, "_BRASIL\\.csv$"))]
  } else {
    nomes[str_detect(nomes, paste0("^", padrao, "_[A-Z]{2}\\.csv$")) &
            !str_detect(nomes, "_(BR|BRASIL)\\.csv$")]
  }
  tmp <- file.path(tempdir(), "cap2_unzip")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  rbindlist(lapply(alvo, function(n) {
    f <- unzip(zip_path, files = n, exdir = tmp)
    cols_ok <- intersect(colunas, names(fread(f, nrows = 0, encoding = "Latin-1")))
    d <- fread(f, sep = ";", encoding = "Latin-1", colClasses = "character",
               select = cols_ok, showProgress = FALSE)
    unlink(f)
    d
  }), fill = TRUE)
}

#' Candidaturas a deputado de um ano (arquivo BRASIL do consulta_cand)
ler_candidatos <- function(ano) {
  d <- ler_zip(file.path(tse_dir, sprintf("consulta_cand_%d.zip", ano)),
               sprintf("consulta_cand_%d", ano),
               c("SG_UF", "DS_CARGO", "SQ_CANDIDATO", "NR_CPF_CANDIDATO", "SG_PARTIDO",
                 "NR_PARTIDO", "DS_GENERO", "DS_COR_RACA", "DS_SITUACAO_CANDIDATURA",
                 "DT_NASCIMENTO"), brasil = TRUE)
  d[, DS_CARGO := toupper(DS_CARGO)]
  as_tibble(d[DS_CARGO %in% cargos]) |>
    distinct(SQ_CANDIDATO, .keep_all = TRUE) |>
    mutate(ANO_ELEICAO = ano)
}

#' Votos válidos por candidato e município, 1º turno
ler_votos <- function(ano) {
  cols <- c("NR_TURNO", "SG_UF", "CD_MUNICIPIO", "DS_CARGO", "SQ_CANDIDATO",
            "DS_DETALHE_SITUACAO_CAND", "QT_VOTOS_NOMINAIS", "QT_VOTOS_NOMINAIS_VALIDOS",
            "DS_SIT_TOT_TURNO")
  d <- ler_zip(file.path(tse_dir, sprintf("votacao_candidato_munzona_%d.zip", ano)),
               sprintf("votacao_candidato_munzona_%d", ano), cols)
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos]
  if ("QT_VOTOS_NOMINAIS_VALIDOS" %in% names(d)) {
    d[, votos := as.numeric(QT_VOTOS_NOMINAIS_VALIDOS)]
  } else {
    # 2014: só votos nominais; válidos = candidaturas deferidas
    d[, votos := fifelse(str_detect(DS_DETALHE_SITUACAO_CAND, "^DEFERIDO"),
                         as.numeric(QT_VOTOS_NOMINAIS), 0)]
  }
  d[, .(votos = sum(votos, na.rm = TRUE)),
    by = .(DS_CARGO, SG_UF, CD_MUNICIPIO, SQ_CANDIDATO, DS_SIT_TOT_TURNO)] |>
    as_tibble() |>
    transmute(cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF,
              COD_MUN_TSE = str_pad(CD_MUNICIPIO, 6, pad = "0"),
              SQ_CANDIDATO, ds_sit_tot_turno = DS_SIT_TOT_TURNO, votos)
}

#' Votos de legenda válidos por cargo × UF, 1º turno
ler_legenda <- function(ano) {
  cols <- c("NR_TURNO", "SG_UF", "DS_CARGO", "QT_VOTOS_LEGENDA", "QT_TOTAL_VOTOS_LEG_VALIDOS")
  d <- ler_zip(file.path(tse_dir, sprintf("votacao_partido_munzona_%d.zip", ano)),
               sprintf("votacao_partido_munzona_%d", ano), cols)
  d[, DS_CARGO := toupper(DS_CARGO)]
  d <- d[NR_TURNO == "1" & DS_CARGO %in% cargos]
  # 2018+: total de legenda válido (inclui nominais de indeferidos convertidos);
  # 2014: só QT_VOTOS_LEGENDA
  col <- if ("QT_TOTAL_VOTOS_LEG_VALIDOS" %in% names(d)) "QT_TOTAL_VOTOS_LEG_VALIDOS" else "QT_VOTOS_LEGENDA"
  d[, leg := as.numeric(get(col))]
  d[, .(votos_legenda_uf = sum(leg, na.rm = TRUE)), by = .(DS_CARGO, SG_UF)] |>
    as_tibble() |>
    transmute(cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF, votos_legenda_uf)
}

ler_vagas <- function(ano) {
  d <- ler_zip(file.path(tse_dir, sprintf("consulta_vagas_%d.zip", ano)),
               sprintf("consulta_vagas_%d", ano), c("SG_UF", "DS_CARGO", "QT_VAGA"), brasil = TRUE)
  d[, DS_CARGO := toupper(DS_CARGO)]
  as_tibble(d[DS_CARGO %in% cargos]) |>
    transmute(cargo = names(cargos)[match(DS_CARGO, cargos)], SG_UF, vagas = as.integer(QT_VAGA))
}

capitais <- readRDS("data/raw/capitais.rds") |> transmute(SG_UF, COD_MUN_TSE, capital = TRUE)

# ==============================================================================
# 3. MONTAGEM POR ANO
# ==============================================================================

montar_ano <- function(ano) {
  message("== ", ano)
  votos_mun <- ler_votos(ano) |> filter(votos > 0)

  # Geografia do voto por candidato
  geo <- votos_mun |>
    mutate(V_cand = sum(votos), .by = c(cargo, SQ_CANDIDATO)) |>
    mutate(W_mun  = sum(votos), .by = c(cargo, SG_UF, COD_MUN_TSE)) |>
    mutate(W_uf   = sum(votos), .by = c(cargo, SG_UF)) |>
    # Quociente locacional: fatia do município no voto do candidato / no voto do cargo
    mutate(fatia = votos / V_cand, QL_voto = fatia / (W_mun / W_uf),
           base = QL_voto > 1 & fatia >= fatia_base_voto) |>
    left_join(capitais, by = c("SG_UF", "COD_MUN_TSE")) |>
    # `votos` (por município) só é resumido por último: summarise() é sequencial
    # e reatribuir antes faria as fatias usarem o total no lugar do vetor
    summarise(
      n_mun_com_voto = n(),
      n_mun_base = sum(base),
      pct_voto_base = sum(votos[base]) / sum(votos),
      pct_voto_maior_mun = max(fatia),
      pct_voto_capital = sum(votos[coalesce(capital, FALSE)]) / sum(votos),
      ds_sit_tot_turno = first(ds_sit_tot_turno),
      votos = sum(votos),
      .by = c(cargo, SG_UF, SQ_CANDIDATO)
    )

  qe <- votos_mun |>
    summarise(votos_nominais_uf = sum(votos), .by = c(cargo, SG_UF)) |>
    left_join(ler_legenda(ano), by = c("cargo", "SG_UF")) |>
    left_join(ler_vagas(ano), by = c("cargo", "SG_UF")) |>
    mutate(votos_validos_uf = votos_nominais_uf + votos_legenda_uf,
           QE = votos_validos_uf / vagas)

  ler_candidatos(ano) |>
    transmute(ANO_ELEICAO, cargo = names(cargos)[match(DS_CARGO, cargos)],
              SQ_CANDIDATO, cpf = NR_CPF_CANDIDATO, sigla = SG_PARTIDO,
              nr_partido = NR_PARTIDO, genero = DS_GENERO, raca = DS_COR_RACA,
              dt_nascimento = DT_NASCIMENTO) |>
    inner_join(geo, by = c("cargo", "SQ_CANDIDATO")) |>
    left_join(select(qe, cargo, SG_UF, QE, vagas, votos_validos_uf), by = c("cargo", "SG_UF")) |>
    mutate(
      eleito = as.integer(str_detect(ds_sit_tot_turno, "^ELEITO")),
      competitivo = as.integer(eleito == 1 | votos / QE >= limiar_competitivo)
    )
}

painel <- map(anos, montar_ano) |> list_rbind()

# ==============================================================================
# 4. VARIÁVEIS DERIVADAS
# ==============================================================================

painel <- painel |>
  mutate(
    sigla_atual   = recodificar(sigla, renomeacoes),
    partido_2026  = recodificar(sigla_atual, sucessao_2026),
    raca2 = case_when(raca %in% c("PRETA", "PARDA") ~ "NEGRA",
                      raca == "BRANCA" ~ "BRANCA",
                      raca %in% c("AMARELA", "INDÍGENA") ~ "OUTRA",
                      TRUE ~ NA_character_),
    mulher = as.integer(genero == "FEMININO"),
    negra  = as.integer(raca2 == "NEGRA"),
    grupo_genero_raca = case_when(
      is.na(raca2) | raca2 == "OUTRA" | !genero %in% c("FEMININO", "MASCULINO") ~ NA_character_,
      genero == "FEMININO" & raca2 == "NEGRA"  ~ "Mulher negra",
      genero == "FEMININO" & raca2 == "BRANCA" ~ "Mulher branca",
      genero == "MASCULINO" & raca2 == "NEGRA" ~ "Homem negro",
      TRUE ~ "Homem branco"
    ),
    regiao = unname(regioes[SG_UF]),
    faixa_magnitude = case_when(
      cargo == "Federal"  & vagas <= 8  ~ "Pequena",
      cargo == "Federal"  & vagas <= 20 ~ "Média",
      cargo == "Federal"                ~ "Grande",
      cargo == "Estadual" & vagas <= 24 ~ "Pequena",
      cargo == "Estadual" & vagas <= 50 ~ "Média",
      TRUE                              ~ "Grande"
    ),
    faixa_magnitude = factor(faixa_magnitude, levels = c("Pequena", "Média", "Grande"))
  ) |>
  left_join(ideologia, by = c("sigla_atual" = "sigla")) |>
  mutate(bloco = bloco_ideologico(posicao))

saveRDS(painel, file.path(dados_out, "painel_candidaturas.rds"))

# ==============================================================================
# 5. DIAGNÓSTICOS E VALIDAÇÃO
# ==============================================================================

diag <- painel |>
  summarise(candidaturas = n(), eleitos = sum(eleito), competitivas = sum(competitivo),
            sem_genero = sum(!genero %in% c("FEMININO", "MASCULINO")),
            sem_raca = sum(is.na(raca2)), sem_bloco = sum(is.na(bloco)),
            .by = c(ANO_ELEICAO, cargo)) |>
  arrange(cargo, ANO_ELEICAO)
print(diag)
print(painel |> filter(is.na(bloco)) |> count(ANO_ELEICAO, sigla_atual))

# Contexto: registros no consulta_cand (inclui indeferidos e renúncias)
registros <- map(anos, ler_candidatos) |> list_rbind() |>
  count(ANO_ELEICAO, DS_CARGO, DS_SITUACAO_CANDIDATURA, name = "registros")
write_csv(registros, file.path(out_dir, "registros_consulta_cand.csv"))

# Eleito/competitivo vs. bases da autora (Estadual 2014–2022, Federal 2018–2022)
autora <- bind_rows(
  readRDS("data/raw/eleitos_e_compet_est_2014_df.rds") |> ungroup() |>
    transmute(ANO_ELEICAO = 2014L, cargo = "Estadual", SQ_CANDIDATO = sq_candidato,
              eleito_a = eleito, competitivo_a = competitivo),
  readRDS("data/raw/eleitos_e_compet_est_2018_df.rds") |> ungroup() |>
    transmute(ANO_ELEICAO = 2018L, cargo = "Estadual", SQ_CANDIDATO = sq_candidato,
              eleito_a = eleito, competitivo_a = competitivo),
  readRDS("data/raw/eleitos_e_compet_est_2022_df.rds") |> ungroup() |>
    transmute(ANO_ELEICAO = 2022L, cargo = "Estadual", SQ_CANDIDATO = sq_candidato,
              eleito_a = eleito, competitivo_a = competitivo),
  readRDS("data/raw/eleitos_e_compet_2018_df.rds") |> ungroup() |>
    transmute(ANO_ELEICAO = 2018L, cargo = "Federal", SQ_CANDIDATO = sq_candidato,
              eleito_a = eleito, competitivo_a = competitivo),
  readRDS("data/raw/eleitos_e_compet_2022_df.rds") |> ungroup() |>
    transmute(ANO_ELEICAO = 2022L, cargo = "Federal", SQ_CANDIDATO = sq_candidato,
              eleito_a = eleito, competitivo_a = competitivo)
)

validacao <- painel |>
  inner_join(autora, by = c("ANO_ELEICAO", "cargo", "SQ_CANDIDATO")) |>
  summarise(n = n(), concord_eleito = mean(eleito == eleito_a, na.rm = TRUE),
            concord_competitivo = mean(competitivo == competitivo_a, na.rm = TRUE),
            .by = c(ANO_ELEICAO, cargo))
print(validacao)
write_csv(validacao, file.path(out_dir, "validacao_resultado.csv"))
write_csv(diag, file.path(out_dir, "diagnostico_painel.csv"))

message("Painel salvo: ", nrow(painel), " candidaturas em ", dados_out)
