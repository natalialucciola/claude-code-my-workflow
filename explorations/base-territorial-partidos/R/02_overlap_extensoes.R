# ==============================================================================
# Extensões à exploração de sobreposição territorial (ver README.md):
#   B. Capital vs. não-capital — a falta de exclusividade está concentrada
#      nas capitais estaduais?
#   C. Resultado eleitoral NO ANO DO GASTO (eleito / competitivo / não
#      competitivo) — há diferença de padrão?
#   D. Incumbência — candidatos já eleitos no MESMO cargo na eleição
#      ANTERIOR (2018→2014, 2022→2018) têm padrão diferente de
#      não-incumbentes?
#
# Pré-requisito: rodar R/01_overlap_partido.R antes (gera
# output/cand_mun_ql1.rds, usado aqui como ponto de partida).
#
# Candidaturas e eleitos de Deputado Federal 2014 (necessários para a
# incumbência 2018→2014 no cargo Federal) foram preparados via
# `electionsBR::elections_tse(2014, type = "candidate")` — ver
# scripts/08_baixar_candidatos_federal_2014.R — cobrindo as 4 células
# completas (Federal e Estadual, 2018 e 2022).
# ==============================================================================

library(tidyverse)

out_dir <- "explorations/base-territorial-partidos/output"

cand_mun_ql1 <- readRDS(file.path(out_dir, "cand_mun_ql1.rds"))

# ==============================================================================
# B. CAPITAL VS. NÃO-CAPITAL
# ==============================================================================

capitais <- readRDS("data/raw/capitais.rds") |>
  mutate(capital_flag = TRUE) |>
  select(SG_UF, COD_MUN_TSE, capital_flag)

# ---- B0: MESMA UNIDADE DA TABELA A (1 linha = 1 município), só quebrada por
#      capital/não-capital. Responde diretamente a pergunta original: "% dos
#      municípios com >=1 candidato acima do QL que têm 2+", por tipo de município.
mun_partido <- readRDS(file.path(out_dir, "overlap_municipio_partido.rds"))

mun_partido_cap <- mun_partido |>
  left_join(capitais, by = c("SG_UF", "COD_MUN_TSE")) |>
  mutate(capital_flag = replace_na(capital_flag, FALSE),
         tipo_mun = if_else(capital_flag, "Capital", "Não-capital"))

tab_capital_municipio <- mun_partido_cap |>
  summarise(
    n_municipios_com_ql1 = n(),
    n_municipios_overlap = sum(overlap),
    taxa_overlap_mun_pct = round(100 * mean(overlap), 1),
    .by = c(cargo, ANO_ELEICAO, tipo_mun)
  ) |>
  arrange(cargo, ANO_ELEICAO, tipo_mun)

message("\n--- Tabela B0: % de MUNICÍPIOS com 2+ candidatos do partido acima do QL",
        " (mesma definição da Tabela A), por tipo de município ---")
print(tab_capital_municipio, n = Inf)

n_capitais_total <- n_distinct(mun_partido_cap$COD_MUN_TSE[mun_partido_cap$capital_flag])
n_naocapitais_total <- n_distinct(mun_partido_cap$COD_MUN_TSE[!mun_partido_cap$capital_flag])
message("Nota: só ", n_capitais_total, " município(s)-capital distintos entram na conta",
        " (de 26 capitais possíveis; múltiplos partidos por capital contam separadamente),",
        " contra ", n_naocapitais_total, " não-capitais distintos.")

# ---- B1 (candidato-município, framing de EXPOSIÇÃO — não é contagem de
#      municípios). Cada candidato entra 1x por município em que concentrou
#      gasto; um município com 5 candidatos acima do QL pesa 5x aqui.
cand_mun_ql1_cap <- cand_mun_ql1 |>
  left_join(capitais, by = c("SG_UF", "COD_MUN_TSE")) |>
  mutate(capital_flag = replace_na(capital_flag, FALSE),
         tipo_mun = if_else(capital_flag, "Capital", "Não-capital"))

message("\nPares candidato-município QL>1 que são capital: ", sum(cand_mun_ql1_cap$capital_flag),
        " de ", nrow(cand_mun_ql1_cap),
        " (", round(100 * mean(cand_mun_ql1_cap$capital_flag), 1), "%)")

tab_capital <- cand_mun_ql1_cap |>
  summarise(
    n = n(),
    taxa_overlap_pct = round(100 * mean(overlap), 1),
    .by = c(cargo, ANO_ELEICAO, tipo_mun)
  ) |>
  pivot_wider(names_from = tipo_mun, values_from = c(taxa_overlap_pct, n)) |>
  arrange(cargo, ANO_ELEICAO)

message("\n--- Tabela B1: taxa de sobreposição PONDERADA POR CANDIDATO",
        " (não é % de municípios — ver B0 para isso) ---")
print(tab_capital)

# B2/B3. Dentro de cada tipo de município, o gap de gênero/raça se mantém?
# IMPORTANTE: recalculamos taxa_sobreposicao por candidato SEPARADAMENTE dentro
# de capital e de não-capital (uma linha por candidato por tipo_mun, não por
# par candidato-município) — mesma convenção de peso igual por candidato usada
# nas tabelas do 1º round (tab_genero/tab_raca), para não pesar mais quem
# concentrou gasto em mais municípios.
taxa_sobreposicao_por_tipo <- cand_mun_ql1_cap |>
  summarise(
    n_mun_ql1     = n(),
    n_mun_overlap = sum(overlap),
    taxa_sobreposicao = n_mun_overlap / n_mun_ql1,
    .by = c(sq_candidato, cargo, ANO_ELEICAO, partido_harm, genero, raca2, tipo_mun)
  )

tab_capital_genero <- taxa_sobreposicao_por_tipo |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(tipo_mun, genero)
  ) |>
  pivot_wider(names_from = genero, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_FEMININO - taxa_media_pct_MASCULINO)

message("\n--- Tabela B2: gap de gênero (taxa pessoal por candidato, mesma unidade",
        " do 1o round), por tipo de município (agregado cargo/ano) ---")
print(tab_capital_genero)

tab_capital_raca <- taxa_sobreposicao_por_tipo |>
  filter(raca2 %in% c("BRANCA", "NEGRA")) |>
  summarise(
    taxa_media_pct = round(100 * mean(taxa_sobreposicao, na.rm = TRUE), 1),
    n = n(),
    .by = c(tipo_mun, raca2)
  ) |>
  pivot_wider(names_from = raca2, values_from = c(taxa_media_pct, n)) |>
  mutate(gap_pp = taxa_media_pct_NEGRA - taxa_media_pct_BRANCA)

message("\n--- Tabela B3: gap de raça (taxa pessoal por candidato, mesma unidade",
        " do 1o round), por tipo de município (agregado cargo/ano) ---")
print(tab_capital_raca)

# Testes t para B2/B3 (a mesma correção de unidade exige re-checar significância)
teste_capital_genero <- taxa_sobreposicao_por_tipo |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  nest(.by = tipo_mun) |>
  mutate(teste = map(data, ~ tryCatch(
    broom::tidy(t.test(taxa_sobreposicao ~ genero, data = .x)),
    error = function(e) NULL
  ))) |>
  select(tipo_mun, teste) |>
  unnest(teste) |>
  select(tipo_mun, p.value)

teste_capital_raca <- taxa_sobreposicao_por_tipo |>
  filter(raca2 %in% c("BRANCA", "NEGRA")) |>
  nest(.by = tipo_mun) |>
  mutate(teste = map(data, ~ tryCatch(
    broom::tidy(t.test(taxa_sobreposicao ~ raca2, data = .x)),
    error = function(e) NULL
  ))) |>
  select(tipo_mun, teste) |>
  unnest(teste) |>
  select(tipo_mun, p.value)

message("\np-valores B2 (FEMININO vs MASCULINO, por tipo de município):")
print(teste_capital_genero)
message("p-valores B3 (NEGRA vs BRANCA, por tipo de município):")
print(teste_capital_raca)

# ==============================================================================
# C. RESULTADO ELEITORAL NO ANO DO GASTO (eleito / competitivo / não competitivo)
# ==============================================================================

cand_mun_ql1_res <- cand_mun_ql1 |>
  mutate(resultado = case_when(
    eleito == 1                       ~ "Eleito",
    competitivo == 1 & eleito == 0    ~ "Competitivo, não eleito",
    competitivo == 0 & eleito == 0    ~ "Não competitivo",
    TRUE                              ~ NA_character_
  ))

tab_resultado <- cand_mun_ql1_res |>
  filter(!is.na(resultado)) |>
  summarise(
    taxa_overlap_pct = round(100 * mean(overlap), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, resultado)
  ) |>
  arrange(cargo, ANO_ELEICAO,
          factor(resultado, levels = c("Eleito", "Competitivo, não eleito", "Não competitivo")))

message("\n--- Tabela C: taxa de sobreposição por resultado eleitoral (cargo x ano) ---")
print(tab_resultado, n = Inf)

# Gênero dentro de "Eleito" apenas — mulheres eleitas também têm mais sobreposição?
tab_resultado_genero <- cand_mun_ql1_res |>
  filter(!is.na(resultado), genero %in% c("FEMININO", "MASCULINO")) |>
  summarise(
    taxa_overlap_pct = round(100 * mean(overlap), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, resultado, genero)
  ) |>
  pivot_wider(names_from = genero, values_from = c(taxa_overlap_pct, n)) |>
  mutate(gap_pp = taxa_overlap_pct_FEMININO - taxa_overlap_pct_MASCULINO) |>
  arrange(cargo, ANO_ELEICAO,
          factor(resultado, levels = c("Eleito", "Competitivo, não eleito", "Não competitivo")))

message("\n--- Tabela C2: gap de gênero dentro de cada resultado eleitoral (cargo x ano) ---")
print(tab_resultado_genero, n = Inf)

# ==============================================================================
# D. INCUMBÊNCIA (eleito no MESMO cargo na eleição anterior)
# ==============================================================================

# ---- D1. CPFs elegíveis a incumbência ----

# Federal: eleito em 2014 (para checar incumbência de candidatos 2018)
cand_fed_2014_cpf <- readRDS("data/raw/candidatos2014.rds") |>
  select(sq_candidato, cpfCand)

eleito_fed_2014 <- readRDS("data/raw/eleitos_2014_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_fed_2014_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |>
  distinct(cpfCand) |>
  pull(cpfCand)

message("\nCPFs de deputados federais eleitos em 2014: ", length(eleito_fed_2014))

# Federal: eleito em 2018 (para checar incumbência de candidatos 2022)
cand2018_cpf <- readRDS("data/raw/candidatos2018.rds") |>
  select(sq_candidato, cpfCand)

eleito_fed_2018 <- readRDS("data/raw/ql_gasto_eleit_2018.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand2018_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |>
  distinct(cpfCand) |>
  pull(cpfCand)

message("CPFs de deputados federais eleitos em 2018: ", length(eleito_fed_2018))

# Estadual: eleito em 2014 (para checar incumbência de candidatos 2018)
cand_est_2014_cpf <- readRDS("data/raw/candidatos_estadual_2014.rds") |>
  select(sq_candidato, cpfCand)

eleito_est_2014 <- readRDS("data/raw/eleitos_e_compet_est_2014_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_est_2014_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |>
  distinct(cpfCand) |>
  pull(cpfCand)

message("CPFs de deputados estaduais eleitos em 2014: ", length(eleito_est_2014))

# Estadual: eleito em 2018 (para checar incumbência de candidatos 2022)
cand_est_2018_cpf <- readRDS("data/raw/candidatos_estadual_2018.rds") |>
  select(sq_candidato, cpfCand)

eleito_est_2018 <- readRDS("data/raw/eleitos_e_compet_est_2018_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_est_2018_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |>
  distinct(cpfCand) |>
  pull(cpfCand)

message("CPFs de deputados estaduais eleitos em 2018: ", length(eleito_est_2018))

# ---- D2. cpfCand dos candidatos na base de análise (2018 e 2022) ----

cand2022_cpf      <- readRDS("data/raw/candidatos2022.rds")        |> select(sq_candidato, cpfCand)
cand_est_2022_cpf <- readRDS("data/raw/candidatos_estadual_2022.rds") |> select(sq_candidato, cpfCand)

# ---- D3. Flag de incumbência por linha de cand_mun_ql1 — 4 células completas ----

incumbencia_map <- bind_rows(
  cand2018_cpf      |> mutate(cargo = "Federal",  ANO_ELEICAO = "2018"),
  cand2022_cpf      |> mutate(cargo = "Federal",  ANO_ELEICAO = "2022"),
  cand_est_2018_cpf |> mutate(cargo = "Estadual", ANO_ELEICAO = "2018"),
  cand_est_2022_cpf |> mutate(cargo = "Estadual", ANO_ELEICAO = "2022")
) |>
  mutate(incumbente = case_when(
    cargo == "Federal"  & ANO_ELEICAO == "2018" ~ cpfCand %in% eleito_fed_2014,
    cargo == "Federal"  & ANO_ELEICAO == "2022" ~ cpfCand %in% eleito_fed_2018,
    cargo == "Estadual" & ANO_ELEICAO == "2018" ~ cpfCand %in% eleito_est_2014,
    cargo == "Estadual" & ANO_ELEICAO == "2022" ~ cpfCand %in% eleito_est_2018,
    TRUE ~ NA
  )) |>
  select(sq_candidato, cargo, ANO_ELEICAO, incumbente)

cand_mun_ql1_inc <- cand_mun_ql1 |>
  left_join(incumbencia_map, by = c("sq_candidato", "cargo", "ANO_ELEICAO"))

tab_incumbencia <- cand_mun_ql1_inc |>
  filter(!is.na(incumbente)) |>
  summarise(
    taxa_overlap_pct = round(100 * mean(overlap), 1),
    n = n(),
    .by = c(cargo, ANO_ELEICAO, incumbente)
  ) |>
  arrange(cargo, ANO_ELEICAO, desc(incumbente))

message("\n--- Tabela D: taxa de sobreposição por incumbência (cargo x ano) — 4 células completas ---")
print(tab_incumbencia, n = Inf)

# ==============================================================================
# SALVAR
# ==============================================================================

saveRDS(tab_capital_municipio,  file.path(out_dir, "tab_capital_municipio.rds"))
saveRDS(tab_capital,           file.path(out_dir, "tab_capital.rds"))
saveRDS(teste_capital_genero,  file.path(out_dir, "teste_t_capital_genero.rds"))
saveRDS(teste_capital_raca,    file.path(out_dir, "teste_t_capital_raca.rds"))
saveRDS(tab_capital_genero,    file.path(out_dir, "tab_capital_genero.rds"))
saveRDS(tab_capital_raca,      file.path(out_dir, "tab_capital_raca.rds"))
saveRDS(tab_resultado,         file.path(out_dir, "tab_resultado_eleitoral.rds"))
saveRDS(tab_resultado_genero,  file.path(out_dir, "tab_resultado_eleitoral_genero.rds"))
saveRDS(tab_incumbencia,       file.path(out_dir, "tab_incumbencia.rds"))

write_csv(tab_capital_municipio, file.path(out_dir, "tab_capital_municipio.csv"))
write_csv(tab_capital,          file.path(out_dir, "tab_capital.csv"))
write_csv(tab_capital_genero,   file.path(out_dir, "tab_capital_genero.csv"))
write_csv(tab_capital_raca,     file.path(out_dir, "tab_capital_raca.csv"))
write_csv(tab_resultado,        file.path(out_dir, "tab_resultado_eleitoral.csv"))
write_csv(tab_resultado_genero, file.path(out_dir, "tab_resultado_eleitoral_genero.csv"))
write_csv(tab_incumbencia,      file.path(out_dir, "tab_incumbencia.csv"))

message("\n=== Extensões concluídas — tabelas salvas em ", out_dir, " ===")
