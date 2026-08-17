# ==============================================================================
# Liderança partidária (nacional e estadual) a partir do sistema SGIP do TSE.
#
# Fonte: https://dadosabertos.tse.jus.br/dataset/delegados-partidarios
#   -> https://cdn.tse.jus.br/estatistica/sead/odsele/orgao_partidario/orgao_partidario.zip
# Baixado em 2026-08-16. O TSE atualiza esse dado semanalmente — este é um
# snapshot carimbado, não uma fonte "viva"; se reprocessado depois, os
# resultados podem diferir marginalmente (ex. correções de cadastro).
#
# Cada CSV do zip é UM ÓRGÃO PARTIDÁRIO POR ARQUIVO (partido), delimitador
# ";", encoding Latin-1, contendo o histórico COMPLETO de membros de todos os
# órgãos (nacional/estadual/regional-DF/municipal) já registrados por aquele
# partido, com datas de início/fim de exercício de cada membro.
#
# Regra de escopo (decisão da usuária, 2026-08-16): SEM restringir a
# ESTADUAL. Um presidente/vice-presidente/secretário de finanças NACIONAL
# tem poder de decisão sobre a distribuição de recursos em qualquer UF onde
# o partido lance candidatos — não só quem preside o diretório da UF do
# próprio candidato. Por isso mantemos NACIONAL + ESTADUAL + REGIONAL (DF);
# MUNICIPAL fica de fora (sem elo teórico com alocação de recursos no nível
# Federal/Estadual, e explodiria o volume de dado em ordens de magnitude).
#
# Chave de vínculo: NR_TITULO_ELEITORAL_MEMBRO == titulo_eleitoral (candidato),
# usando o SG_PARTIDO do PRÓPRIO CANDIDATO NA ÉPOCA (não harmonizado/partido_harm)
# — decisão de design: os arquivos do TSE são organizados pelo nome do
# partido tal como registrado historicamente (ex. "DEM" continua tendo seu
# próprio arquivo mesmo após a fusão em União Brasil / "UNIÃO"), então
# comparar contra o partido_harm (que colapsa DEM -> UNIÃO para fins de
# comparação de sobreposição territorial entre ciclos) buscaria liderança no
# arquivo errado para candidatos de ciclos anteriores à fusão.
#
# Pré-requisito: R/09_titulo_eleitoral_2018_2022.R já rodado
# (titulo_eleitoral_candidato.rds, com SG_PARTIDO não-harmonizado por ciclo).
# ==============================================================================

library(dplyr)
library(readr)
library(stringr)

out_dir <- "explorations/base-territorial-partidos/output"
zip_path <- file.path(out_dir, "raw_tse_orgaos", "orgao_partidario.zip")

normalizar <- function(x) {
  x |>
    str_to_upper() |>
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |>
    str_squish()
}

classificar_cargo <- function(cargo_norm) {
  case_when(
    str_detect(cargo_norm, "VICE") & str_detect(cargo_norm, "PRESIDENTE") ~ "VICE-PRESIDENTE",
    str_detect(cargo_norm, "^PRESIDENTE$") | (str_detect(cargo_norm, "PRESIDENTE") & !str_detect(cargo_norm, "VICE")) ~ "PRESIDENTE",
    str_detect(cargo_norm, "SECRETAR") & str_detect(cargo_norm, "FINANC") ~ "SECRETARIO DE FINANCAS",
    TRUE ~ NA_character_
  )
}

arquivos <- unzip(zip_path, list = TRUE)$Name
arquivos <- arquivos[str_detect(arquivos, "^orgao_partidario_.*\\.csv$")]
message("Arquivos de partido no zip: ", length(arquivos))

col_types_orgao <- cols(
  DT_GERACAO = col_character(), HH_GERACAO = col_character(),
  SQ_ORGAO_PARTIDARIO = col_character(), SG_PARTIDO = col_character(),
  NR_PARTIDO = col_character(), NM_PARTIDO = col_character(),
  CD_TIPO_ORGAO_PARTIDARIO = col_character(), NM_TIPO_ORGAO_PARTIDARIO = col_character(),
  CD_TIPO_ABRANGENCIA = col_character(), DS_TIPO_ABRANGENCIA = col_character(),
  DT_INICIO_VIGENCIA_ORGAO = col_character(), DT_FIM_VIGENCIA_ORGAO = col_character(),
  SG_UF = col_character(), SG_UE = col_character(), NM_UE = col_character(),
  CD_MUNICIPIO = col_character(), NM_MUNICIPIO = col_character(),
  DS_ENDERECO_ORGAO = col_character(), NR_CEP_ORGAO = col_character(),
  NR_FONE_FIXO_ORGAO = col_character(), NR_FONE_CEL_ORGAO = col_character(),
  NR_FONE_COMERCIAL_ORGAO = col_character(), NR_FAX_ORGAO = col_character(),
  TX_EMAIL_ORGAO = col_character(), SQ_CARGO_MEMBRO = col_character(),
  DS_CARGO_MEMBRO = col_character(), SQ_MEMBRO = col_character(),
  NM_MEMBRO = col_character(), NR_TITULO_ELEITORAL_MEMBRO = col_character(),
  DT_INICIO_EXERCICIO_MEMBRO = col_character(), DT_FIM_EXERCICIO_MEMBRO = col_character(),
  CD_GENERO = col_character(), DS_GENERO = col_character(),
  DS_SITU_EXERC_MEMBRO = col_character(), DS_SITU_EXERC_ORGAO_PARTIDARIO = col_character()
)

processar_arquivo <- function(nome_arquivo) {
  con <- unz(zip_path, nome_arquivo)
  d <- tryCatch(
    read_delim(con, delim = ";", col_types = col_types_orgao,
               locale = locale(encoding = "Latin1"), progress = FALSE),
    error = function(e) { message("  ERRO em ", nome_arquivo, ": ", conditionMessage(e)); NULL }
  )
  if (is.null(d) || nrow(d) == 0) return(NULL)

  d <- d |>
    mutate(
      abrangencia_norm = normalizar(DS_TIPO_ABRANGENCIA),
      cargo_norm = normalizar(DS_CARGO_MEMBRO)
    ) |>
    filter(abrangencia_norm %in% c("NACIONAL", "ESTADUAL", "REGIONAL (DF)")) |>
    mutate(cargo_class = classificar_cargo(cargo_norm)) |>
    filter(!is.na(cargo_class))

  if (nrow(d) == 0) return(NULL)

  d |>
    mutate(
      dt_inicio = as.Date(DT_INICIO_EXERCICIO_MEMBRO, format = "%d/%m/%Y"),
      dt_fim_raw = DT_FIM_EXERCICIO_MEMBRO,
      dt_fim = if_else(is.na(dt_fim_raw) | dt_fim_raw == "", as.Date(NA), as.Date(dt_fim_raw, format = "%d/%m/%Y")),
      sobrepoe_2018 = dt_inicio <= as.Date("2018-12-31") & (is.na(dt_fim) | dt_fim >= as.Date("2018-01-01")),
      sobrepoe_2022 = dt_inicio <= as.Date("2022-12-31") & (is.na(dt_fim) | dt_fim >= as.Date("2022-01-01"))
    ) |>
    filter(sobrepoe_2018 | sobrepoe_2022) |>
    transmute(
      SG_PARTIDO, escopo = abrangencia_norm, SG_UF,
      cargo_lideranca = cargo_class,
      titulo_eleitoral_membro = NR_TITULO_ELEITORAL_MEMBRO,
      nome_membro = NM_MEMBRO,
      ANO_ELEICAO = case_when(
        sobrepoe_2018 & sobrepoe_2022 ~ list(c("2018", "2022")),
        sobrepoe_2018 ~ list("2018"),
        sobrepoe_2022 ~ list("2022")
      )
    ) |>
    tidyr::unnest(ANO_ELEICAO)
}

message("Processando ", length(arquivos), " arquivos de partido (um de cada vez)...")
resultados <- vector("list", length(arquivos))
for (i in seq_along(arquivos)) {
  resultados[[i]] <- processar_arquivo(arquivos[i])
  if (i %% 5 == 0 || i == length(arquivos)) {
    message("  [", i, "/", length(arquivos), "] ", arquivos[i])
  }
}

lideranca_raw <- bind_rows(resultados)

message("\nTotal de registros de liderança (nacional+estadual+DF, 2018/2022): ", nrow(lideranca_raw))
message("Distintos por escopo:")
print(lideranca_raw |> count(escopo, cargo_lideranca) |> arrange(escopo, cargo_lideranca))

saveRDS(lideranca_raw, file.path(out_dir, "lideranca_raw.rds"))

# ==============================================================================
# Vincular a candidatos via título eleitoral + SG_PARTIDO (não harmonizado)
# ==============================================================================

titulo_cand <- readRDS(file.path(out_dir, "titulo_eleitoral_candidato.rds"))

# ---- Resolver a sigla de busca por partido: SG_PARTIDO do próprio ciclo,
# com fallback para o nome harmonizado quando não há arquivo próprio no zip
# do TSE (renomeações dentro do MESMO registro partidário, ex. PR -> PL,
# PRB -> REPUBLICANOS, PPS -> CIDADANIA, PTC -> AGIR: o TSE já reindexou o
# histórico de órgãos sob o nome atual, não existe arquivo "PR" separado).
# Fusões que criaram um registro NOVO (DEM+PSL -> UNIÃO/44) mantêm arquivo
# próprio (DEM, PSL) com o histórico pré-fusão — nesses casos o SG_PARTIDO
# original já resolve sem fallback.
normalizar_sigla <- function(x) {
  x |> stringr::str_to_upper() |> iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |>
    stringr::str_remove_all("[^A-Z0-9]")
}

siglas_disponiveis_norm <- normalizar_sigla(sub("^orgao_partidario_", "", sub("[.]csv$", "", arquivos)))

resolver_sigla_busca <- function(sigla) {
  sigla_norm <- normalizar_sigla(sigla)
  sigla_harm_norm <- normalizar_sigla(harmonizar_partido(sigla))
  dplyr::case_when(
    sigla_norm %in% siglas_disponiveis_norm ~ sigla_norm,
    sigla_harm_norm %in% siglas_disponiveis_norm ~ sigla_harm_norm,
    TRUE ~ NA_character_
  )
}

source("explorations/base-territorial-partidos/R/harmonizar_partido.R")

titulo_cand <- titulo_cand |>
  mutate(sigla_busca = resolver_sigla_busca(SG_PARTIDO))

message("\n--- Resolução de sigla para busca de liderança ---")
message("Candidatos sem sigla resolvível (sem arquivo próprio nem harmonizado no zip): ",
        sum(is.na(titulo_cand$sigla_busca)),
        " (partidos: ", paste(sort(unique(titulo_cand$SG_PARTIDO[is.na(titulo_cand$sigla_busca)])), collapse = ", "), ")")

lideranca_raw <- lideranca_raw |>
  mutate(sigla_busca = normalizar_sigla(SG_PARTIDO))

lider_nacional <- lideranca_raw |>
  filter(escopo == "NACIONAL") |>
  distinct(sigla_busca, ANO_ELEICAO, titulo_eleitoral_membro, cargo_lideranca)

lider_estadual <- lideranca_raw |>
  filter(escopo %in% c("ESTADUAL", "REGIONAL (DF)")) |>
  distinct(sigla_busca, SG_UF, ANO_ELEICAO, titulo_eleitoral_membro, cargo_lideranca)

# Candidato é líder NACIONAL do próprio partido em qualquer UF, ou líder
# ESTADUAL do próprio partido na própria UF.
cand_lider_nacional <- titulo_cand |>
  filter(!is.na(sigla_busca)) |>
  inner_join(lider_nacional,
             by = c("sigla_busca", "ANO_ELEICAO", "titulo_eleitoral" = "titulo_eleitoral_membro")) |>
  mutate(escopo_lideranca = "NACIONAL")

cand_lider_estadual <- titulo_cand |>
  filter(!is.na(sigla_busca)) |>
  inner_join(lider_estadual,
             by = c("sigla_busca", "SG_UF", "ANO_ELEICAO", "titulo_eleitoral" = "titulo_eleitoral_membro")) |>
  mutate(escopo_lideranca = "ESTADUAL")

# Candidato é ALVO de sobreposição com líder do partido: qualquer
# correligionário (mesmo partido histórico, mesmo cargo/ano) que seja líder
# nacional (qualquer UF) ou líder estadual (mesma UF). Aqui construímos a
# tabela de LÍDERES do partido por (SG_PARTIDO, cargo, ano[, UF]) — o
# script 11 fará o cruzamento candidato-a-candidato dentro do mesmo
# município.

lideres_partido_ano <- bind_rows(
  cand_lider_nacional |> select(sq_candidato, cargo, ANO_ELEICAO, SG_PARTIDO, SG_UF, cargo_lideranca, escopo_lideranca),
  cand_lider_estadual |> select(sq_candidato, cargo, ANO_ELEICAO, SG_PARTIDO, SG_UF, cargo_lideranca, escopo_lideranca)
) |>
  distinct()

message("\n=== Candidatos identificados como líderes do partido (2018+2022) ===")
message("Via liderança NACIONAL: ", n_distinct(cand_lider_nacional$sq_candidato))
message("Via liderança ESTADUAL/DF: ", n_distinct(cand_lider_estadual$sq_candidato))
message("Total distinto (união): ", n_distinct(lideres_partido_ano$sq_candidato))

saveRDS(lideres_partido_ano, file.path(out_dir, "lideranca_candidato.rds"))

message("\n=== Concluído: lideranca_raw.rds e lideranca_candidato.rds salvos em ", out_dir, " ===")
