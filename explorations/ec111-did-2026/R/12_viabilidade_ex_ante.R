# ==============================================================================
# 12 — Viabilidade ex ante das candidaturas (item 1 do plano caça-níquel)
#      quality_reports/plans/2026-11-24_cap4-cacaniquel-item1-implementacao.md
#
# A candidatura i em t é VIÁVEL EX ANTE se, em t − 4 (só cargos de deputado):
#   V1  foi eleita no mesmo cargo (incumbente)
#   V2  foi eleita no outro cargo de deputado (estadual → federal ou o inverso)
#   V3  não foi eleita, mas terminou a menos de 0,1 QE do limiar, em qualquer um dos
#       dois cargos (decisão D3 da autora, 24/11); V3_mc = só no mesmo cargo (robustez)
#   viavel = V1 | V2 | V3 (principal); viavel_v1 = V1; viavel_mc = V1 | V2 | V3_mc
# 2018 usa 2014, 2022 usa 2018 e 2026 usa 2022 (2026 é medido como os demais anos,
# decisão D2). A pessoa é ligada entre eleições pelo CPF do consulta_cand do TSE e,
# quando o CPF falta ou está mascarado (-4), pelo título eleitoral.
#
# Entradas: data/raw/tse/consulta_cand_{2014,2018,2022,2026}.zip,
#           data/processed/margem_resultado.rds, cand_ec111_2014_2026.rds (R/02),
#           data/raw/candidatos{,_estadual_}{2014,2018,2022}.rds (só conferência)
# Saídas:   data/processed/viabilidade_ex_ante.rds
#           output/viabilidade_tamanhos.csv   (viáveis por ano × cargo × grupo, fatias
#                                              das transferências, razão por candidatura)
#           output/viabilidade_matriz_2x2.csv (viável ex ante × competitiva ex post)
#
#   Rscript explorations/ec111-did-2026/R/12_viabilidade_ex_ante.R
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({library(tidyverse); library(data.table)})

out_dir <- "explorations/ec111-did-2026/output"
anos <- c(2014L, 2018L, 2022L, 2026L)
gs <- c("mulher", "negra", "mulher_negra")

# ------------------------------------------------------------------------------
# 1. Identificador da pessoa: CPF (11 dígitos) ou, na falta, título eleitoral
# ------------------------------------------------------------------------------
limpa <- function(x, n) {
  x <- gsub("\\D", "", x)
  if_else(nchar(x) >= n - 3 & nchar(x) <= n & !grepl("^0+$", x),
          formatC(x, width = n, flag = "0"), NA_character_)
}
ler_ids <- function(a) {
  td <- tempfile(); dir.create(td)
  arq <- sprintf("consulta_cand_%d_BRASIL.csv", a)
  unzip(sprintf("data/raw/tse/consulta_cand_%d.zip", a), arq, exdir = td)
  fread(file.path(td, arq), encoding = "Latin-1", colClasses = "character",
        select = c("CD_CARGO", "SQ_CANDIDATO", "NR_CPF_CANDIDATO",
                   "NR_TITULO_ELEITORAL_CANDIDATO")) |>
    as_tibble() |>
    filter(CD_CARGO %in% c("6", "7")) |>
    transmute(ano = a, sq_candidato = SQ_CANDIDATO,
              cpf = limpa(NR_CPF_CANDIDATO, 11), titulo = limpa(NR_TITULO_ELEITORAL_CANDIDATO, 12))
}
ids <- map(anos, ler_ids) |> list_rbind() |>
  distinct(ano, sq_candidato, .keep_all = TRUE)

# O título só substitui o CPF quando a mesma pessoa não tem CPF em nenhum ano: o título
# de quem tem CPF em algum ano é ligado a esse CPF, para que as duas chaves não separem
# a mesma pessoa entre eleições
tit_cpf <- ids |> filter(!is.na(cpf), !is.na(titulo)) |> distinct(titulo, cpf) |>
  filter(n() == 1L, .by = titulo)                       # títulos com um só CPF
ids <- ids |>
  left_join(tit_cpf |> rename(cpf_via_titulo = cpf), by = "titulo") |>
  mutate(pessoa = case_when(!is.na(cpf) ~ cpf,
                            !is.na(cpf_via_titulo) ~ cpf_via_titulo,
                            !is.na(titulo) ~ paste0("T", titulo)))

cobertura <- ids |> summarise(n = n(), cpf = mean(!is.na(cpf)), titulo = mean(!is.na(titulo)),
                              pessoa = mean(!is.na(pessoa)), .by = ano)
message("Cobertura dos identificadores (cargos 6 e 7, todas as situações):")
print(as.data.frame(cobertura |> mutate(across(cpf:pessoa, \(x) round(100 * x, 2)))))

# Conferência 1: CPF e título apontam para a mesma pessoa (os dois presentes)
par <- ids |> filter(!is.na(cpf), !is.na(titulo)) |> distinct(cpf, titulo)
disc_cpf <- par |> filter(n() > 1L, .by = cpf) |> distinct(cpf) |> nrow()
disc_tit <- par |> filter(n() > 1L, .by = titulo) |> distinct(titulo) |> nrow()
message(sprintf("CPF com mais de um título: %d de %d; título com mais de um CPF: %d de %d",
                disc_cpf, n_distinct(par$cpf), disc_tit, n_distinct(par$titulo)))
stopifnot(disc_cpf / n_distinct(par$cpf) < 0.01, disc_tit / n_distinct(par$titulo) < 0.01)

# Conferência 2: CPF do consulta_cand × CPF das bases da tese (mapa do R/05 da
# competitividade-eleitoral), 2014–2022
cpf_tese <- map(c(2014L, 2018L, 2022L), \(a) {
  bind_rows(readRDS(sprintf("data/raw/candidatos%d.rds", a)) |> as_tibble(),
            readRDS(sprintf("data/raw/candidatos_estadual_%d.rds", a)) |> as_tibble()) |>
    transmute(ano = a, sq_candidato = as.character(sq_candidato),
              cpf_tese = limpa(as.character(cpfCand), 11))
}) |> list_rbind() |> distinct(ano, sq_candidato, .keep_all = TRUE)
conf_cpf <- ids |> inner_join(cpf_tese, by = c("ano", "sq_candidato")) |>
  filter(!is.na(cpf), !is.na(cpf_tese)) |>
  summarise(n = n(), concorda = 100 * mean(cpf == cpf_tese), .by = ano)
message("CPF consulta_cand × bases da tese (% de concordância):")
print(as.data.frame(conf_cpf))
stopifnot(all(conf_cpf$concorda >= 99))

# ------------------------------------------------------------------------------
# 2. Resultado de cada pessoa em t − 4 (margem de votos; todas as candidaturas)
# ------------------------------------------------------------------------------
ant <- readRDS("data/processed/margem_resultado.rds") |> as_tibble() |>
  filter(cd_cargo %in% 6:7) |>
  transmute(ano = as.integer(ano), sq_candidato = as.character(sq_candidato), cd_cargo,
            el = as.logical(eleito), perto = !el & !is.na(margem_qe) & margem_qe >= -0.1) |>
  inner_join(ids |> select(ano, sq_candidato, pessoa), by = c("ano", "sq_candidato")) |>
  filter(!is.na(pessoa)) |>
  summarise(el_fed = any(el & cd_cargo == 6L), el_est = any(el & cd_cargo == 7L),
            perto_fed = any(perto & cd_cargo == 6L), perto_est = any(perto & cd_cargo == 7L),
            .by = c(ano, pessoa)) |>
  mutate(ano = ano + 4L)
stopifnot(!anyDuplicated(ant[c("ano", "pessoa")]))

# ------------------------------------------------------------------------------
# 3. Classificação das candidaturas aptas de 2018–2026
# ------------------------------------------------------------------------------
cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO), sq_candidato = as.character(sq_candidato)) |>
  filter(ano >= 2018L)
viab <- cand |>
  select(ANO, ano, DS_CARGO, federal, sq_candidato) |>
  left_join(ids |> select(ano, sq_candidato, pessoa), by = c("ano", "sq_candidato")) |>
  left_join(ant, by = c("ano", "pessoa")) |>
  mutate(across(c(el_fed, el_est, perto_fed, perto_est), \(x) replace_na(x, FALSE)),
         V1 = if_else(federal, el_fed, el_est),
         V2 = if_else(federal, el_est, el_fed),
         V3 = perto_fed | perto_est,
         V3_mc = if_else(federal, perto_fed, perto_est),
         viavel = V1 | V2 | V3, viavel_v1 = V1, viavel_mc = V1 | V2 | V3_mc) |>
  select(ANO, DS_CARGO, sq_candidato, pessoa, V1, V2, V3, V3_mc, viavel, viavel_v1, viavel_mc)
stopifnot(nrow(viab) == nrow(cand), !anyDuplicated(viab[c("ANO", "DS_CARGO", "sq_candidato")]),
          !any(is.na(viab$pessoa)))
# eleita em t − 4 não pode ser, no mesmo cargo, "perto do limiar sem ser eleita"
# (só ocorreria com duas candidaturas da mesma pessoa no mesmo cargo e ano)
stopifnot(!any(viab$V1 & viab$V3_mc))
saveRDS(viab, "data/processed/viabilidade_ex_ante.rds")

# ------------------------------------------------------------------------------
# 4. Conferências e descritivos
# ------------------------------------------------------------------------------
cv <- cand |> left_join(viab, by = c("ANO", "DS_CARGO", "sq_candidato"))

inc <- cv |> filter(federal) |>
  summarise(incumbentes = sum(V1), reeleitos = sum(V1 & eleito == 1L),
            eleitos = sum(eleito == 1L), .by = ano)
message("Federal: incumbentes que concorrem e reeleitos (sem DF):")
print(as.data.frame(inc))
stopifnot(all(between(inc$incumbentes, 330, 460)), all(between(inc$reeleitos, 200, 330)))

tamanhos <- map(c("todas", gs), \(g) {
  d <- if (g == "todas") cv else cv |> filter(.data[[g]])
  d |> summarise(
    candidaturas = n(), viaveis = sum(viavel), V2_sem_V1 = sum(V2 & !V1),
    V3_so = sum(V3 & !V1 & !V2), V1_n = sum(V1), viaveis_v1 = sum(viavel_v1),
    viaveis_mc = sum(viavel_mc),
    pct_viaveis = 100 * mean(viavel),
    viaveis_por_disputa = viaveis / 26, ufs_sem_viavel = 26L - n_distinct(uf[viavel]),
    pct_transf_viaveis = 100 * sum(receita_partido[viavel]) / sum(receita_partido),
    pct_transf_compet_expost = 100 * sum(receita_partido[compet_m]) / sum(receita_partido),
    # razão por candidatura: transferência média das viáveis ÷ média das não viáveis
    razao_v_nv = (sum(receita_partido[viavel]) / sum(viavel)) /
                 (sum(receita_partido[!viavel]) / sum(!viavel)),
    .by = c(ano, federal)) |>
    mutate(grupo = g, cargo = if_else(federal, "Federal", "Estadual"), .before = 1) |>
    select(-federal)
}) |> list_rbind() |> arrange(grupo, cargo, ano)
write_excel_csv2(tamanhos, file.path(out_dir, "viabilidade_tamanhos.csv"))
message("Viáveis ex ante por grupo:")
print(as.data.frame(tamanhos |> select(grupo, cargo, ano, candidaturas, viaveis, V1_n, V2_sem_V1,
                                       V3_so, viaveis_por_disputa, ufs_sem_viavel,
                                       pct_transf_viaveis, razao_v_nv) |>
                      mutate(across(where(is.double), \(x) round(x, 1)))))

matriz <- map(gs, \(g) {
  cv |> filter(.data[[g]]) |>
    summarise(transf = sum(receita_partido), gasto = sum(gasto), votos = sum(VOTOS_CAND_TOTAL),
              candidaturas = n(), .by = c(ano, federal, viavel, compet_m)) |>
    mutate(across(c(transf, gasto, votos, candidaturas), \(x) 100 * x / sum(x)),
           .by = c(ano, federal)) |>
    mutate(grupo = g, .before = 1)
}) |> list_rbind() |>
  mutate(cargo = if_else(federal, "Federal", "Estadual"),
         celula = case_when(viavel & compet_m ~ "Viável → competitiva",
                            viavel ~ "Viável → não competitiva",
                            compet_m ~ "Não viável → competitiva",
                            .default = "Não viável → não competitiva")) |>
  select(grupo, cargo, ano, celula, viavel, compet_m, transf, gasto, votos, candidaturas) |>
  arrange(grupo, cargo, ano, desc(viavel), desc(compet_m))
stopifnot(all(abs(summarise(matriz, s = sum(transf), .by = c(grupo, cargo, ano))$s - 100) < 1e-8))
write_excel_csv2(matriz, file.path(out_dir, "viabilidade_matriz_2x2.csv"))
message("Matriz 2 × 2, mulheres, % das transferências:")
print(as.data.frame(matriz |> filter(grupo == "mulher") |>
                      select(cargo, ano, celula, transf) |>
                      pivot_wider(names_from = c(cargo, ano), values_from = transf) |>
                      mutate(across(where(is.double), \(x) round(x, 1)))))
