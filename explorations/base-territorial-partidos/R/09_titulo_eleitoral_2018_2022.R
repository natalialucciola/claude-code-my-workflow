# ==============================================================================
# Completar a chave de vínculo com a base de liderança partidária do TSE
# (R/10_lideranca_partido.R): título eleitoral do candidato.
#
# NR_TITULO_ELEITORAL_CANDIDATO existe no download bruto de
# electionsBR::elections_tse(type = "candidate") (confirmado: 50 colunas),
# mas os scripts que já geraram data/raw/candidatos{2018,2022}*.rds
# descartaram essa coluna no select(). Em vez de re-baixar e reprocessar
# esses arquivos (risco de divergência com o que já está em uso no resto do
# pipeline), este script baixa de novo, só para extrair
# SQ_CANDIDATO + NR_TITULO_ELEITORAL_CANDIDATO, e salva como um arquivo
# separado para juntar por sq_candidato + cargo + ANO_ELEICAO.
#
# Pré-requisito: nenhum (não depende de outros scripts desta pasta).
# ==============================================================================

library(dplyr)
library(stringr)
library(electionsBR)

out_dir <- "explorations/base-territorial-partidos/output"

baixar_titulo <- function(ano, cargo_desejado, cargo_label) {
  message("Baixando candidaturas ", ano, " (electionsBR, br_archive = TRUE)...")
  raw <- elections_tse(year = ano, type = "candidate", br_archive = TRUE)

  raw |>
    filter(str_to_upper(DS_CARGO) == cargo_desejado) |>
    transmute(
      sq_candidato = as.character(SQ_CANDIDATO),
      titulo_eleitoral = as.character(NR_TITULO_ELEITORAL_CANDIDATO),
      SG_UF, SG_PARTIDO,
      cargo = cargo_label,
      ANO_ELEICAO = as.character(ano)
    )
}

titulo_fed_2018 <- baixar_titulo(2018, "DEPUTADO FEDERAL", "Federal")
titulo_fed_2022 <- baixar_titulo(2022, "DEPUTADO FEDERAL", "Federal")
titulo_est_2018 <- baixar_titulo(2018, "DEPUTADO ESTADUAL", "Estadual")
titulo_est_2022 <- baixar_titulo(2022, "DEPUTADO ESTADUAL", "Estadual")

titulo_eleitoral_candidato <- bind_rows(
  titulo_fed_2018, titulo_fed_2022, titulo_est_2018, titulo_est_2022
)

message("\nTotal de candidatos com título eleitoral baixado: ", nrow(titulo_eleitoral_candidato))
message("Títulos ausentes/vazios: ",
        sum(is.na(titulo_eleitoral_candidato$titulo_eleitoral) |
              titulo_eleitoral_candidato$titulo_eleitoral == ""))
message("Títulos duplicados (mesmo sq_candidato+cargo+ano): ",
        sum(duplicated(titulo_eleitoral_candidato[, c("sq_candidato", "cargo", "ANO_ELEICAO")])))

saveRDS(titulo_eleitoral_candidato, file.path(out_dir, "titulo_eleitoral_candidato.rds"))

# ---- Checagem de cobertura contra a amostra do capítulo ----

taxa_sobreposicao <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds"))

cobertura <- taxa_sobreposicao |>
  filter(ANO_ELEICAO %in% c("2018", "2022")) |>
  left_join(
    titulo_eleitoral_candidato |> select(sq_candidato, cargo, ANO_ELEICAO, titulo_eleitoral),
    by = c("sq_candidato", "cargo", "ANO_ELEICAO")
  )

n_total <- nrow(cobertura)
n_com_titulo <- sum(!is.na(cobertura$titulo_eleitoral) & cobertura$titulo_eleitoral != "")

message("\n=== Cobertura de título eleitoral na amostra do capítulo (2018+2022) ===")
message("Candidatos na amostra (2018+2022): ", n_total)
message("Com título eleitoral identificado: ", n_com_titulo,
        " (", round(100 * n_com_titulo / n_total, 1), "%)")

message("\n--- Cobertura por cargo x ano ---")
print(
  cobertura |>
    summarise(
      n = n(),
      com_titulo = sum(!is.na(titulo_eleitoral) & titulo_eleitoral != ""),
      pct = round(100 * com_titulo / n, 1),
      .by = c(cargo, ANO_ELEICAO)
    )
)

message("\n=== Concluído: titulo_eleitoral_candidato.rds salvo em ", out_dir, " ===")
