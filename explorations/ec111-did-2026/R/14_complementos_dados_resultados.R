# ==============================================================================
# 14 — Complementos de Dados e Resultados do Cap. 4 (EC 111)
#      plano quality_reports/plans/2026-11-25_cap4-ec111-dados-resultados.md
#
# Não altera o R/10 (as réplicas dele ficam como estão). Acrescenta:
#   (a) recursos públicos: DiD da proporção do FEFC + Fundo Partidário da lista recebida
#       pelo grupo, por qualquer via (do partido ou repassado por outra candidatura),
#       mesmo estimador do R/10 (estimar(), EP por UF, wild bootstrap). Substitui a
#       "versão ampla" das transferências como conferência da H2 (item 7 do plano).
#   (b) cobertura do painel balanceado: % das candidaturas e dos votos nominais de cada
#       cargo × ano que estão nas listas presentes nas quatro eleições, e % das
#       transferências do partido nas listas do painel das transferências (item 1).
#   (c) descritivo de competitividade e viabilidade: % das candidaturas do grupo e do
#       complemento competitivas pelo voto, pelo gasto, eleitas e viáveis antes da eleição,
#       por cargo × ano, totais nacionais sem DF (item 5).
#
# Entradas: data/processed/painel_listas_2014_2026.rds, cand_ec111_2014_2026.rds (R/02),
#           margem_resultado.rds, margem_gasto_medidas.rds, viabilidade_ex_ante.rds (R/12)
# Saídas (output/): recursos_publicos_resultados.csv, cobertura_painel.csv,
#                   descritivo_competitividade_viabilidade.csv
#
#   BITERS=25000 WILD=1999 Rscript explorations/ec111-did-2026/R/14_complementos_dados_resultados.R
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({library(tidyverse); library(did); library(fixest)})
source("explorations/ec111-did-2026/R/funcoes_estimacao.R")

set.seed(20261125)
out_dir <- "explorations/ec111-did-2026/output"
anos_longos <- c(2014L, 2018L, 2022L, 2026L)
anos_rec    <- c(2018L, 2022L, 2026L)
gs <- c("mulher", "negra", "mulher_negra")

listas <- readRDS("data/processed/painel_listas_2014_2026.rds") |>
  mutate(uf_id = as.integer(factor(uf)))
cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO), lista = paste(partido_h, uf, DS_CARGO),
         cargo = if_else(federal, "Federal", "Estadual"))

# ------------------------------------------------------------------------------
# (a) Recursos públicos (FEFC + FP, por qualquer via)
# ------------------------------------------------------------------------------
t0 <- Sys.time()
rec_pub <- map(gs, \(g) {
  estimar(listas, paste0("rec_publico_", g), anos_rec, "lista", wild = TRUE) |>
    mutate(medida = "rec_publico", grupo = g, .after = 1)
}) |> list_rbind()
message("Recursos públicos: ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
write_excel_csv2(rec_pub, file.path(out_dir, "recursos_publicos_resultados.csv"))

# Níveis por cargo (média das listas do painel), para a conferência no texto
niv_pub <- map(gs, \(g) {
  y <- paste0("rec_publico_", g)
  listas |> filter(ano %in% anos_rec, !is.na(.data[[y]])) |>
    filter(n() == length(anos_rec), .by = id) |>
    summarise(media = mean(.data[[y]]), listas = n(), .by = c(federal, ano)) |>
    mutate(grupo = g)
}) |> list_rbind()
print(niv_pub |> arrange(grupo, federal, ano), n = Inf)

# ------------------------------------------------------------------------------
# (b) Cobertura do painel balanceado
# ------------------------------------------------------------------------------
pres <- listas |> distinct(lista, anos_presente)
bal_rec <- listas |>
  filter(ano %in% anos_rec, !is.na(rec_partido_mulher)) |>
  filter(n() == length(anos_rec), .by = id) |> distinct(lista) |> mutate(no_painel_rec = TRUE)
cob <- cand |>
  left_join(pres, by = "lista") |>
  left_join(bal_rec, by = "lista") |>
  mutate(no_painel = anos_presente %in% "2014-2018-2022-2026",
         no_painel_rec = no_painel_rec %in% TRUE) |>
  summarise(pct_cand_painel = 100 * mean(no_painel),
            pct_votos_painel = 100 * sum(VOTOS_CAND_TOTAL[no_painel], na.rm = TRUE) /
              sum(VOTOS_CAND_TOTAL, na.rm = TRUE),
            pct_transf_painel_rec = if_else(ano[1] >= 2018L,
              100 * sum(receita_partido[no_painel_rec], na.rm = TRUE) /
                sum(receita_partido, na.rm = TRUE), NA_real_),
            sem_lista = sum(is.na(anos_presente)),
            .by = c(cargo, ano)) |>
  arrange(cargo, ano)
# candidaturas cuja lista não está no painel de listas (contam como fora do painel)
message("Candidaturas sem lista no painel: ", sum(cob$sem_lista))
print(cob)
write_excel_csv2(cob, file.path(out_dir, "cobertura_painel.csv"))

# ------------------------------------------------------------------------------
# (c) Competitividade e viabilidade: grupo × complemento, cargo × ano
# ------------------------------------------------------------------------------
grp <- cand |> transmute(ano, sq_candidato = as.character(sq_candidato), cargo,
                         mulher, negra, mulher_negra)
mr <- readRDS("data/processed/margem_resultado.rds") |> as_tibble() |>
  filter(apta, cd_cargo %in% 6:7, uf != "DF", !is.na(margem_qe)) |>
  transmute(ano = as.integer(ano), sq_candidato = as.character(sq_candidato),
            cv = margem_qe >= -0.10, el = as.logical(eleito))
mg <- readRDS("data/processed/margem_gasto_medidas.rds") |> as_tibble() |>
  filter(cd_cargo %in% 6:7, uf != "DF", !is.na(margem_qe), ano >= 2018) |>
  transmute(ano = as.integer(ano), sq_candidato = as.character(sq_candidato),
            cg = margem_gasto_qe >= -0.10)
vi <- readRDS("data/processed/viabilidade_ex_ante.rds") |>
  transmute(ano = as.integer(ANO), sq_candidato = as.character(sq_candidato), viavel)

base <- grp |>
  left_join(mr, by = c("ano", "sq_candidato")) |>
  left_join(mg, by = c("ano", "sq_candidato")) |>
  left_join(vi, by = c("ano", "sq_candidato"))
message("Ligação (% das candidaturas): margem de votos ",
        round(100 * mean(!is.na(base$cv)), 2), "; margem de gasto (2018+) ",
        round(100 * mean(!is.na(base$cg[base$ano >= 2018L])), 2), "; viabilidade (2018+) ",
        round(100 * mean(!is.na(base$viavel[base$ano >= 2018L])), 2))

pct_na <- \(x) if (all(is.na(x))) NA_real_ else 100 * mean(x, na.rm = TRUE)
desc <- map(gs, \(g) {
  base |> mutate(lado = if_else(.data[[g]], "grupo", "complemento")) |>
    summarise(candidaturas = n(), pct_cv = pct_na(cv), pct_cg = pct_na(cg),
              pct_el = pct_na(el), pct_viavel = pct_na(viavel), n_viavel = sum(viavel, na.rm = TRUE),
              .by = c(cargo, ano, lado)) |>
    mutate(grupo = g, .before = 1)
}) |> list_rbind() |> arrange(grupo, lado, cargo, ano)
print(desc |> filter(grupo == "mulher"), n = Inf)
write_excel_csv2(desc, file.path(out_dir, "descritivo_competitividade_viabilidade.csv"))
