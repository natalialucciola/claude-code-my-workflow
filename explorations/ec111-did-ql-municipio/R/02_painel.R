# ==============================================================================
# Script: 02_painel.R
# Purpose: Empilha 2010–2026 e monta o painel partido × município × cargo × ano
#          (especificação principal: QL > 1, fatia ≥ 0,025, painel balanceado) e
#          o painel de listas para o benchmark mecânico (bases novas de g por
#          candidatura de g).
# Inputs:  ql_voto_{federal,estadual}_{2010,2014}.rds (01_ql_2010_2014.R)
#          explorations/ql-voto-2026/output/dados/ql_voto_*_{2018,2022,2026}.rds
#          data/raw/ids_municipios_ibge.rds, data/raw/ibge_municipio_rgi.csv
# Outputs: output/dados/cand_territorio_{municipio,rgi}.rds (insumo da robustez)
#          output/dados/painel_municipio.rds, painel_listas.rds
#          output/diagnostico_painel.csv
# Rodar a partir da raiz do repositório:
#   Rscript explorations/ec111-did-ql-municipio/R/02_painel.R
# ==============================================================================

library(tidyverse)

source("explorations/ec111-did-ql-municipio/R/funcoes.R")
out_dir   <- file.path("explorations", "ec111-did-ql-municipio", "output")
dados_dir <- file.path(out_dir, "dados")

# ---- 1. Candidatos × município, 2010–2026 ----
cand <- bind_rows(ler_bases_candidato("federal"), ler_bases_candidato("estadual")) |>
  marcar_incumbentes()

message("Candidaturas por cargo × ano (com ≥ 1 voto):")
cand |> distinct(ano, cargo, sq_candidato, eleito, incumbente) |>
  summarise(n = n(), eleitos = sum(eleito, na.rm = TRUE),
            incumbentes = sum(incumbente, na.rm = TRUE), .by = c(cargo, ano)) |>
  arrange(cargo, ano) |> print()

# ---- 2. Território: município (principal) e RGI (robustez) ----
ct_mun <- agregar_territorio(cand, "municipio")
ct_rgi <- agregar_territorio(cand, "rgi")

# Verificação: o QL municipal recalculado reproduz o QL_voto do ql-voto-2026 (2018)
orig <- readRDS(file.path(dir_ql_novo, "ql_voto_federal_2018.rds")) |>
  transmute(sq_candidato, terr = str_pad(as.integer(COD_MUN_TSE), 5, pad = "0"), QL_voto)
dif <- ct_mun |> filter(ano == 2018L, cargo == "Federal") |>
  inner_join(orig, by = c("sq_candidato", "terr")) |>
  summarise(n = n(), max_dif = max(abs(QL - QL_voto)))
print(dif)
stopifnot(dif$max_dif < 1e-8)

saveRDS(ct_mun, file.path(dados_dir, "cand_territorio_municipio.rds"))
saveRDS(ct_rgi, file.path(dados_dir, "cand_territorio_rgi.rds"))

# ---- 3. Painel principal ----
painel <- montar_painel(ct_mun, ql_min = 1, fatia_min = 0.025)

stopifnot(!anyDuplicated(painel[c("id", "ano")]),
          all(count(painel, id)$n == length(anos_did)),
          !anyNA(painel$nova_base),
          # a decomposição fecha por construção
          all(painel$nova_base == painel$nova_base_mulher + painel$nova_base_nao_mulher),
          all(painel$nova_base == painel$nova_base_negra + painel$nova_base_nao_negra))
saveRDS(painel, file.path(dados_dir, "painel_municipio.rds"))

diag <- painel |>
  summarise(unidades = n_distinct(id), listas = n_distinct(lista),
            partidos = n_distinct(partido),
            tem_base = mean(tem_base), nova_base = mean(nova_base),
            nova_base_mulher = mean(nova_base_mulher), nova_base_negra = mean(nova_base_negra),
            base_mulher = mean(base_mulher), base_negra = mean(base_negra),
            .by = c(cargo, ano)) |>
  arrange(cargo, ano)
print(diag, width = Inf)
write_csv(diag, file.path(out_dir, "diagnostico_painel.csv"))
message("Partidos no painel balanceado: ", paste(sort(unique(painel$partido)), collapse = " "))

# ---- 4. Painel de listas: benchmark mecânico ----
# Se a EC 111 só aumentou o nº de candidaturas de g, as bases novas de g crescem
# mecanicamente; a razão bases novas de g ÷ candidaturas de g separa as duas coisas.
cand_lista <- cand |>
  filter(!is.na(partido)) |>
  distinct(ano, cargo, SG_UF, partido, sq_candidato, mulher, negra) |>
  summarise(n_cand = n(), n_cand_mulher = sum(mulher, na.rm = TRUE),
            n_cand_negra = sum(negra, na.rm = TRUE), .by = c(ano, cargo, SG_UF, partido))

painel_listas <- painel |>
  summarise(n_nova_base = sum(nova_base), n_nova_base_mulher = sum(nova_base_mulher),
            n_nova_base_negra = sum(nova_base_negra),
            .by = c(ano, cargo, SG_UF, partido, lista, federal, gname)) |>
  left_join(cand_lista, by = c("ano", "cargo", "SG_UF", "partido")) |>
  mutate(nova_por_cand_mulher = if_else(n_cand_mulher > 0,
                                        n_nova_base_mulher / n_cand_mulher, NA_real_),
         nova_por_cand_negra = if_else(n_cand_negra > 0,
                                       n_nova_base_negra / n_cand_negra, NA_real_),
         lista_id = as.integer(factor(lista)))
saveRDS(painel_listas, file.path(dados_dir, "painel_listas.rds"))
message("Painéis salvos em ", dados_dir)
